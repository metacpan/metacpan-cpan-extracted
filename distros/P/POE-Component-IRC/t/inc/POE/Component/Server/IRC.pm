package POE::Component::Server::IRC;
BEGIN {
  $POE::Component::Server::IRC::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::Server::IRC::VERSION = '1.52';
}

use strict;
use warnings;
use Carp qw(croak);
use IRC::Utils qw(uc_irc parse_mode_line unparse_mode_line normalize_mask
                  matches_mask gen_mode_change is_valid_nick_name
                  is_valid_chan_name);
use List::Util qw(sum);
use POE;
use POE::Component::Server::IRC::Common qw(chkpasswd);
use POE::Component::Server::IRC::Plugin qw(:ALL);
use POSIX 'strftime';
use base qw(POE::Component::Server::IRC::Backend);

sub spawn {
    my ($package, %args) = @_;
    $args{lc $_} = delete $args{$_} for keys %args;
    my $config = delete $args{config};
    my $debug = delete $args{debug};
    my $self = $package->create(
        ($debug ? (raw_events => 1) : ()),
        %args,
        states => [
            [qw(add_spoofed_nick del_spoofed_nick)],
            {
                map { +"daemon_cmd_$_" => '_spoofed_command' }
                    qw(join part mode kick topic nick privmsg notice gline
                       kline unkline sjoin locops wallops operwall)
            },
        ],
    );

    $self->configure($config ? $config : ());
    $self->{debug} = $debug;
    $self->_state_create();
    return $self;
}

sub IRCD_connection {
    my ($self, $ircd) = splice @_, 0, 2;
    pop @_;
    my ($conn_id, $peeraddr, $peerport, $sockaddr, $sockport, $needs_auth)
        = map { ${ $_ } } @_;

    if ($self->_connection_exists($conn_id)) {
        delete $self->{state}{conns}{$conn_id};
    }

    $self->{state}{conns}{$conn_id}{registered} = 0;
    $self->{state}{conns}{$conn_id}{type}       = 'u';
    $self->{state}{conns}{$conn_id}{seen}       = time();
    $self->{state}{conns}{$conn_id}{socket}
        = [$peeraddr, $peerport, $sockaddr, $sockport];

    $self->_state_conn_stats();

    if (!$needs_auth) {
        $self->{state}{conns}{$conn_id}{auth} = {
            hostname => '',
            ident => '',
        };
        $self->_client_register($conn_id);
    }

    return PCSI_EAT_CLIENT;
}

sub IRCD_connected {
    my ($self, $ircd) = splice @_, 0, 2;
    pop @_;
    my ($conn_id, $peeraddr, $peerport, $sockaddr, $sockport, $name)
        = map { ${ $_ } } @_;

    if ($self->_connection_exists($conn_id)) {
        delete $self->{state}{conns}{$conn_id};
    }

    $self->{state}{conns}{$conn_id}{peer}       = $name;
    $self->{state}{conns}{$conn_id}{registered} = 0;
    $self->{state}{conns}{$conn_id}{cntr}       = 1;
    $self->{state}{conns}{$conn_id}{type}       = 'u';
    $self->{state}{conns}{$conn_id}{seen}       = time();
    $self->{state}{conns}{$conn_id}{socket}
        = [$peeraddr, $peerport, $sockaddr, $sockport];

    $self->_state_conn_stats();
    $self->_state_send_credentials($conn_id, $name);
    return PCSI_EAT_CLIENT;
}

sub IRCD_connection_flood {
    my ($self, $ircd) = splice @_, 0, 2;
    pop @_;
    my ($conn_id) = map { ${ $_ } } @_;
    $self->_terminate_conn_error($conn_id, 'Excess Flood');
    return PCSI_EAT_CLIENT;
}

sub IRCD_connection_idle {
    my ($self, $ircd) = splice @_, 0, 2;
    pop @_;
    my ($conn_id, $interval) = map { ${ $_ } } @_;
    return PCSI_EAT_NONE if !$self->_connection_exists($conn_id);

    my $conn = $self->{state}{conns}{$conn_id};
    if ($conn->{type} eq 'u') {
        $self->_terminate_conn_error($conn_id, 'Connection Timeout');
        return PCSI_EAT_CLIENT;
    }

    if ($conn->{pinged}) {
        my $msg = 'Ping timeout: '.(time - $conn->{seen}).' seconds';
        $self->_terminate_conn_error($conn_id, $msg);
        return PCSI_EAT_CLIENT;
    }

    $conn->{pinged} = 1;
    $self->send_output(
        {
            command => 'PING',
            params  => [$self->server_name()],
        },
        $conn_id,
    );
    return PCSI_EAT_CLIENT;
}

sub IRCD_auth_done {
    my ($self, $ircd) = splice @_, 0, 2;
    pop @_;
    my ($conn_id, $ref) = map { ${ $_ } } @_;
    return PCSI_EAT_CLIENT if !$self->_connection_exists($conn_id);

    $self->{state}{conns}{$conn_id}{auth} = $ref;
    $self->_client_register($conn_id);
    return PCSI_EAT_CLIENT;
}

sub IRCD_disconnected {
    my ($self, $ircd) = splice @_, 0, 2;
    pop @_;
    my ($conn_id, $errstr) = map { ${ $_ } } @_;
    return PCSI_EAT_CLIENT if !$self->_connection_exists($conn_id);

    if ($self->_connection_is_peer($conn_id)) {
        my $peer = $self->{state}{conns}{$conn_id}{name};
        $self->send_output(
            @{ $self->_daemon_peer_squit($conn_id, $peer, $errstr) }
        );
    }
    elsif ($self->_connection_is_client($conn_id)) {
        $self->send_output(
            @{ $self->_daemon_cmd_quit(
                $self->_client_nickname($conn_id,$errstr ),
                $errstr,
            )}
        );
    }

    delete $self->{state}{conns}{$conn_id};
    return PCSI_EAT_CLIENT;
}

sub IRCD_compressed_conn {
    my ($self, $ircd) = splice @_, 0, 2;
    pop @_;
    my ($conn_id) = map { ${ $_ } } @_;
    $self->_state_send_burst($conn_id);
    return PCSI_EAT_CLIENT;
}

sub IRCD_raw_input {
    my ($self, $ircd) = splice @_, 0, 2;
    return PCSI_EAT_CLIENT if !$self->{debug};
    my $conn_id = ${ $_[0] };
    my $input   = ${ $_[1] };
    warn "<<< $conn_id: $input\n";
    return PCSI_EAT_CLIENT;
}

sub IRCD_raw_output {
    my ($self, $ircd) = splice @_, 0, 2;
    return PCSI_EAT_CLIENT if !$self->{debug};
    my $conn_id = ${ $_[0] };
    my $output  = ${ $_[1] };
    warn ">>> $conn_id: $output\n";
    return PCSI_EAT_CLIENT;
}

sub _default {
    my ($self, $ircd, $event) = splice @_, 0, 3;
    return PCSI_EAT_NONE if $event !~ /^IRCD_cmd_/;
    pop @_;
    my ($conn_id, $input) = map { $$_ } @_;

    return PCSI_EAT_CLIENT if !$self->_connection_exists($conn_id);
    $self->{state}{conns}{$conn_id}{seen} = time;

    if (!$self->_connection_registered($conn_id)) {
        $self->_cmd_from_unknown($conn_id, $input);
    }
    elsif ($self->_connection_is_peer($conn_id)) {
        $self->_cmd_from_peer($conn_id, $input);
    }
    elsif ($self->_connection_is_client($conn_id)) {
        delete $input->{prefix};
        $self->_cmd_from_client($conn_id, $input);
    }

    return PCSI_EAT_CLIENT;
}

sub _auth_finished {
    my $self    = shift;
    my $conn_id = shift || return;
    return if !$self->_connection_exists($conn_id);
    return $self->{state}{conns}{$conn_id}{auth};
}

sub _connection_exists {
    my $self = shift;
    my $conn_id = shift || return;
    return if !defined $self->{state}{conns}{$conn_id};
    return 1;
}

sub _client_register {
    my $self    = shift;
    my $conn_id = shift || return;
    return if !$self->_connection_exists($conn_id);
    return if !$self->{state}{conns}{$conn_id}{nick};
    return if !$self->{state}{conns}{$conn_id}{user};

    my $auth = $self->_auth_finished($conn_id);
    return if !$auth;
    # pass required for link
    if (!$self->_state_auth_client_conn($conn_id)) {
        $self->_terminate_conn_error(
            $conn_id,
            'You are not authorized to use this server',
        );
        return;
    }
    if ($self->_state_user_matches_gline($conn_id)) {
        $self->_terminate_conn_error($conn_id, 'G-Lined');
        return;
    }
    if ($self->_state_user_matches_kline($conn_id)) {
        $self->_terminate_conn_error($conn_id, 'K-Lined');
        return;
    }
    if ($self->_state_user_matches_rkline($conn_id)) {
        $self->_terminate_conn_error($conn_id, 'K-Lined');
        return;
    }

    # Add new nick
    $self->_state_register_client($conn_id);
    my $server    = $self->server_name();
    my $nick      = $self->_client_nickname($conn_id);
    my $port      = $self->{state}{conns}{$conn_id}{socket}[3];
    my $version   = $self->server_version();
    my $network   = $self->server_config('NETWORK');
    my $server_is = "$server\[$server/$port]";

    $self->_send_output_to_client(
        $conn_id,
        {
            prefix  => $server,
            command => '001',
            params  => [
                $nick,
                "Welcome to the $network Internet Relay Chat network $nick"
            ],
        }
    );
    $self->_send_output_to_client(
        $conn_id,
        {
            prefix  => $server,
            command => '002',
            params  => [
                $nick,
                "Your host is $server_is, running version $version",
            ],
        },
    );
    $self->_send_output_to_client(
        $conn_id,
        {
            prefix  => $server,
            command => '003',
            params  => [$nick, $self->server_created()],
        },
    );
    $self->_send_output_to_client(
        $conn_id,
        {
            prefix   => $server,
            command  => '004',
            colonify => 0,
            params   => [
                $nick,
                $server,
                $version,
                'Dilowz',
                'biklmnopstveIh',
                'bkloveIh',
            ],
        }
    );

    for my $output (@{ $self->_daemon_cmd_isupport($nick) }) {
        $self->_send_output_to_client($conn_id, $output);
    }

    $self->{state}{conns}{$conn_id}{registered} = 1;
    $self->{state}{conns}{$conn_id}{type} = 'c';
    $self->send_event(
        'cmd_lusers',
        $conn_id,
        { command => 'LUSERS' },
    );
    $self->send_event(
        'cmd_motd',
        $conn_id,
        { command => 'MOTD' },
    );
    $self->send_event(
        'cmd_mode',
        $conn_id,
        {
            command => 'MODE',
            params  => [$nick, '+i'],
        },
    );

    return 1;
}

sub _connection_registered {
    my $self    = shift;
    my $conn_id = shift || return;
    return if !$self->_connection_exists($conn_id);
    return $self->{state}{conns}{$conn_id}{registered};
}

sub _connection_is_peer {
    my $self    = shift;
    my $conn_id = shift || return;

    return if !$self->_connection_exists($conn_id);
    return if !$self->{state}{conns}{$conn_id}{registered};
    return 1 if $self->{state}{conns}{$conn_id}{type} eq 'p';
    return;
}

sub _connection_is_client {
    my $self    = shift;
    my $conn_id = shift || return;

    return if !$self->_connection_exists($conn_id);
    return if !$self->{state}{conns}{$conn_id}{registered};
    return 1 if $self->{state}{conns}{$conn_id}{type} eq 'c';
    return;
}

sub _cmd_from_unknown {
    my ($self, $wheel_id, $input) = @_;

    my $cmd     = uc $input->{command};
    my $params  = $input->{params} || [ ];
    my $pcount  = @$params;
    my $invalid = 0;

    SWITCH: {
        if ($cmd eq 'ERROR') {
            my $peer = $self->{state}{conns}{$wheel_id}{peer};
            if (defined $peer) {
                $self->send_event_next(
                    'daemon_error',
                    $wheel_id,
                    $peer,
                    $params->[0],
                );
            }
        }
        if ($cmd eq 'QUIT') {
            $self->_terminate_conn_error($wheel_id, 'Client Quit');
            last SWITCH;
        }

        # PASS or NICK cmd but no parameters.
        if ($cmd =~ /^(PASS|NICK|SERVER)$/ && !$pcount) {
            $self->_send_output_to_client($wheel_id, '461', $cmd);
            last SWITCH;
        }

        # PASS or NICK cmd with one parameter, connection from client
        if ($cmd eq 'PASS' && $pcount) {
            $self->{state}{conns}{$wheel_id}{lc $cmd} = $params->[0];

            if ($params->[1] && $params->[1] =~ /TS$/) {
                $self->{state}{conns}{$wheel_id}{ts_server} = 1;
                $self->antiflood($wheel_id, 0);
            }
            last SWITCH;
        }

        # SERVER stuff.
        if ($cmd eq 'CAPAB' && $pcount) {
            $self->{state}{conns}{$wheel_id}{capab}
                = [split /\s+/, $params->[0]];
            last SWITCH;
        }
        if ($cmd eq 'SERVER' && $pcount < 2) {
            $self->_send_output_to_client($wheel_id, '461', $cmd);
            last SWITCH;
        }
        if ($cmd eq 'SERVER') {
            my $conn = $self->{state}{conns}{$wheel_id};
            $conn->{name} = $params->[0];
            $conn->{hops} = $params->[1] || 1;
            $conn->{desc} = $params->[2] || '';

            if (!$conn->{ts_server}) {
                $self->_terminate_conn_error($wheel_id, 'Non-TS server.');
                last SWITCH;
            }
            if (!$self->_state_auth_peer_conn($wheel_id,
                    $conn->{name}, $conn->{pass})) {
                $self->_terminate_conn_error(
                    $wheel_id,
                    'Unauthorised server.',
                );
                last SWITCH;
            }
            if ($self->state_peer_exists($conn->{name})) {
                $self->_terminate_conn_error($wheel_id, 'Server exists.');
                last SWITCH;
            }
            $self->_state_register_peer($wheel_id);

            if ($conn->{zip} && grep { $_ eq 'ZIP' } @{ $conn->{capab} }) {
                $self->compressed_link($wheel_id, 1, $conn->{cntr});
            }
            else {
                $self->_state_send_burst($wheel_id);
            }

            $self->send_event(
                "daemon_capab",
                $conn->{name},
                @{ $conn->{capab} },
            );
            last SWITCH;
        }

        if ($cmd eq 'NICK' && $pcount) {
            if (!is_valid_nick_name($params->[0])) {
                $self->_send_output_to_client(
                    $wheel_id,
                    '432',
                    $params->[0],
                );
                last SWITCH;
            }
            if ($self->state_nick_exists($params->[0])) {
                $self->_send_output_to_client(
                    $wheel_id,
                    '433',
                    $params->[0],
                );
                last SWITCH;
            }

            my $nicklen = $self->server_config('NICKLEN');
            if (length($params->[0]) > $nicklen) {
                $params->[0] = substr($params->[0], 0, $nicklen);
            }

            $self->{state}{conns}{$wheel_id}{lc $cmd} = $params->[0];
            $self->{state}{pending}{uc_irc($params->[0])} = $wheel_id;
            $self->_client_register($wheel_id);
            last SWITCH;
        }
        if ($cmd eq 'USER' && $pcount < 4) {
            $self->_send_output_to_client($wheel_id, '461', $cmd);
            last SWITCH;
        }
        if ($cmd eq 'USER') {
            $self->{state}{conns}{$wheel_id}{user} = $params->[0];
            $self->{state}{conns}{$wheel_id}{ircname} = $params->[3] || '';
            $self->_client_register($wheel_id);
            last SWITCH;
        }

        last SWITCH if $self->{state}{conns}{$wheel_id}{cntr};
        $invalid = 1;
        $self->_send_output_to_client($wheel_id, '451');
    }

    return 1 if $invalid;
    $self->_state_cmd_stat($cmd, $input->{raw_line});
    return 1;
}

sub _cmd_from_peer {
    my ($self, $conn_id, $input) = @_;

    my $cmd     = $input->{command};
    my $params  = $input->{params};
    my $prefix  = $input->{prefix};
    my $invalid = 0;

    SWITCH: {
        my $method = '_daemon_peer_' . lc $cmd;
        if ($cmd eq 'SQUIT' && !$prefix ){
            $self->_daemon_peer_squit($conn_id, @$params);
            #$self->_send_output_to_client(
            #    $conn_id,
            #    $prefix,
            #    (ref $_ eq 'ARRAY' ? @{ $_ } : $_)
            #) for $self->_daemon_cmd_squit($prefix, @$params);
            last SWITCH;
        }

        if ($cmd =~ /\d{3}/) {
            $self->send_output(
                $input,
                $self->_state_user_route($params->[0])
            );
            last SWITCH;
        }
        if ($cmd eq 'QUIT') {
            $self->send_output(
                @{ $self->_daemon_peer_quit(
                    $prefix, @$params, $conn_id
                )}
            );
            last SWITCH;
        }

        if ($cmd =~ /^(PRIVMSG|NOTICE)$/) {
            $self->_send_output_to_client(
                $conn_id,
                $prefix,
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_)
            ) for $self->_daemon_peer_message(
                $conn_id,
                $prefix,
                $cmd,
                @$params
            );
            last SWITCH;
        }

        if ($cmd =~ /^(WHOIS|VERSION|TIME|NAMES|LINKS|ADMIN|INFO|MOTD|SQUIT)$/i ) {
            my $client_method = '_daemon_cmd_' . lc $cmd;
            $self->_send_output_to_client(
                $conn_id,
                $prefix,
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_ )
            ) for $self->$client_method($prefix, @$params);
            last SWITCH;
        }

        if ($cmd =~ /^(PING|PONG)$/i && $self->can($method)) {
            $self->$method($conn_id, @{ $params });
            last SWITCH;
        }

        if ($cmd =~ /^SVINFO$/i && $self->can($method)) {
            $self->$method($conn_id, @$params);
            my $conn = $self->{state}{conns}{$conn_id};
            $self->send_event(
                "daemon_svinfo",
                $conn->{name},
                @$params,
            );
            last SWITCH;
        }

        if ($cmd eq 'MODE' && $self->state_nick_exists($params->[0])) {
            $method = '_daemon_peer_umode';
        }

        if ($self->can($method)) {
            $self->$method($conn_id, $prefix, @$params);
            last SWITCH;
        }
        $invalid = 1;
    }

    return 1 if $invalid;
    $self->_state_cmd_stat($cmd, $input->{raw_line}, 1);
    return 1;
}

sub _cmd_from_client {
    my ($self, $wheel_id, $input) = @_;

    my $cmd = uc $input->{command};
    my $params = $input->{params} || [ ];
    my $pcount = @$params;
    my $server = $self->server_name();
    my $nick = $self->_client_nickname($wheel_id);
    my $invalid = 0;

    SWITCH: {
        my $method = '_daemon_cmd_' . lc $cmd;
        if ($cmd eq 'QUIT') {
            $self->_terminate_conn_error(
                $wheel_id,
                ($pcount ? qq{"$params->[0]"} : 'Client Quit'),
            );
            last SWITCH;
        }

        if ($cmd =~ /^(USERHOST|MODE)$/ && !$pcount) {
            $self->_send_output_to_client($wheel_id, '461', $cmd);
            last SWITCH;
        }
        if ($cmd =~ /^(USERHOST)$/) {
            $self->_send_output_to_client($wheel_id, $_)
                for $self->$method(
                    $nick,
                    ($pcount <= 5
                        ? @$params
                        : @{ $params }[0..5]
                    )
                );
            last SWITCH;
        }

        if ($cmd =~ /^(PRIVMSG|NOTICE)$/) {
            $self->{state}{conns}{$wheel_id}{idle_time} = time;
            $self->_send_output_to_client(
                $wheel_id,
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_),
            ) for $self->_daemon_cmd_message($nick, $cmd, @$params);
            last SWITCH;
        }

        if ($cmd eq 'MODE' && $self->state_nick_exists($params->[0])) {
            if (uc_irc($nick) ne uc_irc($params->[0])) {
                $self->_send_output_to_client($wheel_id => '502');
                last SWITCH;
            }

            my $modestring = join('', @{ $params }[1..$#{ $params }]);
            $modestring =~ s/\s+//g;
            $modestring =~ s/[^a-zA-Z+-]+//g;
            $modestring =~ s/[^DGglwiozl+-]+//g;
            $modestring = unparse_mode_line($modestring);
            $self->_send_output_to_client($wheel_id, $_)
                for $self->_daemon_cmd_umode($nick, $modestring);
            last SWITCH;
        }

        if ($self->can($method)) {
            $self->_send_output_to_client(
                $wheel_id,
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_),
            ) for $self->$method($nick, @$params);
            last SWITCH;
        }

        $invalid = 1;
        $self->_send_output_to_client($wheel_id, '421', $cmd);
    }

    return 1 if $invalid;
    $self->_state_cmd_stat($cmd, $input->{raw_line});
    return 1;
}

sub _daemon_cmd_message {
    my $self = shift;
    my $nick = shift || return;
    my $type = shift || return;
    my $ref = [ ];
    my $args = [@_];
    my $count = @$args;

    SWITCH: {
        if (!$count) {
            push @$ref, ['461', $type];
            last SWITCH;
        }
        if ($count < 2 || !$args->[1]) {
            push @$ref, ['412'];
            last SWITCH;
        }

        my $targets     = 0;
        my $max_targets = $self->server_config('MAXTARGETS');
        my $full        = $self->state_user_full($nick);
        my $targs       = $self->_state_parse_msg_targets($args->[0]);

        LOOP: for my $target (keys %$targs) {
            my $targ_type = shift @{ $targs->{$target} };

            if ($targ_type =~ /(server|host)mask/
                    && !$self->state_user_is_operator($nick)) {
                push @$ref, ['481'];
                next LOOP;
            }

            if ($targ_type =~ /(server|host)mask/
                && $targs->{$target}[0] !~ /\./) {
                push @$ref, ['413', $target];
                next LOOP;
            }

            if ($targ_type =~ /(server|host)mask/
                    && $targs->{$target}[0] =~ /\x2E.*[\x2A\x3F]+.*$/) {
                push @$ref, ['414', $target];
                next LOOP;
            }

            if ($targ_type eq 'channel_ext'
                    && !$self->state_chan_exists($targs->{$target}[1])) {
                push @$ref, ['401', $targs->{$target}[1]];
                next LOOP;
            }

            if ($targ_type eq 'channel'
                    && !$self->state_chan_exists($target)) {
                push @$ref, ['401', $target];
                next LOOP;
            }

            if ($targ_type eq 'nick'
                    && !$self->state_nick_exists($target)) {
                push @$ref, ['401', $target];
                next LOOP;
            }

            if ($targ_type eq 'nick_ext'
                    && !$self->state_peer_exists($targs->{$target}[1])) {
                push @$ref, ['402', $targs->{$target}[1]];
                next LOOP;
            }

            $targets++;
            if ($targets > $max_targets) {
                push @$ref, ['407', $target];
                last SWITCH;
            }

            # $$whatever
            if ($targ_type eq 'servermask') {
                my $us = 0;
                my %targets;
                my $ucserver = uc $self->server_name();

                for my $peer (keys %{ $self->{state}{peers} }) {
                    if (matches_mask( $targs->{$target}[0], $peer)) {
                        if ($ucserver eq $peer) {
                            $us = 1;
                        }
                        else {
                            $targets{ $self->_state_peer_route($peer) }++;
                        }
                    }
                }

                $self->send_output(
                    {
                        prefix  => $nick,
                        command => $type,
                        params  => [$target, $args->[1]],
                    },
                    keys %targets,
                );

                if ($us) {
                    my $local
                        = $self->{state}{peers}{uc $self->server_name()}{users};
                    my @local;
                    my $spoofed = 0;

                    for my $luser (values %$local) {
                        if ($luser->{route_id} eq 'spoofed') {
                            $spoofed = 1;
                        }
                        else {
                            push @local, $luser->{route_id};
                        }
                    }

                    $self->send_output(
                        {
                            prefix  => $full,
                            command => $type,
                            params  => [$target, $args->[1]],
                        },
                        @local,
                    );

                    $self->send_event(
                        "daemon_" . lc $type,
                        $full,
                        $target,
                        $args->[1],
                    ) if $spoofed;
                }
                next LOOP;
            }

            # $#whatever
            if ($targ_type eq 'hostmask') {
                my $spoofed = 0;
                my %targets; my @local;

                HOST: for my $luser (values %{ $self->{state}{users} }) {
                    if (!matches_mask($targs->{$target}[0],
                            $luser->{auth}{hostname})) {;
                            next HOST;
                        }

                    if ($luser->{route_id} eq 'spoofed') {
                        $spoofed = 1;
                    }
                    elsif ($luser->{type} eq 'r') {
                        $targets{ $luser->{route_id} }++;
                    }
                    else {
                        push @local, $luser->{route_id};
                    }
                }

                $self->send_output(
                    {
                        prefix  => $nick,
                        command => $type,
                        params  => [$target, $args->[1]],
                    },
                    keys %targets,
                );

                $self->send_output(
                    {
                        prefix  => $full,
                        command => $type,
                        params  => [$target, $args->[1]],
                    },
                    @local,
                );

                $self->send_event(
                    "daemon_" . lc $type,
                    $full,
                    $target,
                    $args->[1],
                ) if $spoofed;

                next LOOP;
            }

            if ($targ_type eq 'nick_ext') {
                $targs->{$target}[1] = $self->_state_peer_name(
                    $targs->{$target}[1]);

                if ($targs->{$target}[2]
                        && !$self->state_user_is_operator($nick)) {
                    push @$ref, ['481'];
                    next LOOP;
                }

                if ($targs->{$target}[1] ne $self->server_name()) {
                    $self->send_output(
                        {
                            prefix  => $nick,
                            command => $type,
                            params  => [$target, $args->[1]],
                        },
                        $self->_state_peer_route($targs->{$target}[1]),
                    );
                    next LOOP;
                }

                if (uc $targs->{$target}[0] eq 'OPERS') {
                    if (!$self->state_user_is_operator($nick)) {
                        push @$ref, ['481'];
                        next LOOP;
                    }

                    $self->send_output(
                        {
                        prefix  => $full,
                        command => $type,
                        params  => [$target, $args->[1]],
                        },
                        keys %{ $self->{state}{localops} },
                    );
                    next LOOP;
                }

                my @local = $self->_state_find_user_host(
                    $targs->{$target}[0],
                    $targs->{$target}[2],
                );

                if (@local == 1) {
                    my $ref = shift @local;
                    if ($ref->[0] eq 'spoofed') {
                        $self->send_event(
                            "daemon_" . lc $type,
                            $full,
                            $ref->[1],
                            $args->[1],
                        );
                    }
                    else {
                        $self->send_output(
                            {
                                prefix  => $full,
                                command => $type,
                                params  => [$target, $args->[1]],
                            },
                            $ref->[0],
                        );
                    }
                }
                else {
                    push @$ref, ['407', $target];
                    next LOOP;
                }
            }

            my ($channel, $status_msg);
            if ($targ_type eq 'channel') {
                $channel = $self->_state_chan_name($target);
            }
            if ($targ_type eq 'channel_ext') {
                $channel = $self->_state_chan_name($targs->{target}[1]);
                $status_msg = $targs->{target}[0];
            }
            if ($channel && $status_msg
                    && !$self->state_user_chan_mode($nick, $channel)) {
                push @$ref, ['482', $target];
                next LOOP;
            }
            if ($channel && $self->state_chan_mode_set($channel, 'n')
                    && !$self->state_is_chan_member($nick, $channel)) {
                push @$ref, ['404', $channel];
                next LOOP;
            }
            if ($channel && $self->state_chan_mode_set($channel, 'm')
                    && !$self->state_user_chan_mode($nick, $channel)) {
                push @$ref, ['404', $channel];
                next LOOP;
            }
            if ($channel && $self->_state_user_banned($nick, $channel)
                    && !$self->state_user_chan_mode($nick, $channel)) {
                push @$ref, ['404', $channel];
                next LOOP;
            }
            if ($channel) {
                my $common = { };
                my $msg = {
                    command => $type,
                    params  => [
                        ($status_msg ? $target : $channel), $args->[1]
                    ],
                };
                for my $member ($self->state_chan_list($channel, $status_msg)) {
                    next if $self->_state_user_is_deaf($member);
                    $common->{ $self->_state_user_route($member) }++;
                }
                delete $common->{ $self->_state_user_route($nick) };
                for my $route_id (keys %$common) {
                    $msg->{prefix} = $nick;
                    if ($self->_connection_is_client($route_id)) {
                        $msg->{prefix} = $full;
                    }
                    if ($route_id ne 'spoofed') {
                        $self->send_output($msg, $route_id);
                    }
                    else {
                        my $tmsg = $type eq 'PRIVMSG' ? 'public' : 'notice';
                        $self->send_event(
                            "daemon_$tmsg",
                            $full,
                            $channel,
                            $args->[1],
                        );
                    }
                }
                next LOOP;
            }

            my $server = $self->server_name();
            if ($self->state_nick_exists($target)) {
                $target = $self->state_user_nick($target);

                if (my $away = $self->_state_user_away_msg($target)) {
                    push @$ref, {
                        prefix  => $server,
                        command => '301',
                        params  => [$nick, $target, $away],
                    };
                }

                my $targ_umode = $self->state_user_umode($target);

                # Target user has CALLERID on
                if ($targ_umode && $targ_umode =~ /[Gg]/) {
                    my $targ_rec = $self->{state}{users}{uc_irc($target)};
                    if (($targ_umode =~ /G/
                        && (!$self->state_users_share_chan($target, $nick)
                        || !$targ_rec->{accepts}{uc_irc($nick)}))
                        || ($targ_umode =~ /g/
                        && !$targ_rec->{accepts}{uc_irc($nick)})) {

                        push @$ref, {
                            prefix  => $server,
                            command => '716',
                            params  => [
                                $nick,
                                $target,
                                'is in +g mode (server side ignore)',
                            ],
                        };

                        if (!$targ_rec->{last_caller}
                            || time() - $targ_rec->{last_caller} >= 60) {

                            my ($n, $uh) = split /!/,
                            $self->state_user_full($nick);
                            $self->send_output(
                                {
                                    prefix  => $server,
                                    command => '718',
                                    params => [
                                        $target,
                                        "$n\[$uh\]",
                                        'is messaging you, and you are umode +g.',
                                ]
                                },
                                $targ_rec->{route_id},
                            ) if $targ_rec->{route_id} ne 'spoofed';
                            push @$ref, {
                                prefix  => $server,
                                command => '717',
                                params  => [
                                    $nick,
                                    $target,
                                    'has been informed that you messaged them.',
                                ],
                            };
                        }
                        $targ_rec->{last_caller} = time();
                        next LOOP;
                    }
                }

                my $msg = {
                    prefix  => $nick,
                    command => $type,
                    params  => [$target, $args->[1]],
                };
                my $route_id = $self->_state_user_route($target);

                if ($route_id eq 'spoofed') {
                    $msg->{prefix} = $full;
                    $self->send_event(
                        "daemon_" . lc $type,
                        $full,
                        $target,
                        $args->[1],
                    );
                }
                else {
                    if ($self->_connection_is_client($route_id)) {
                        $msg->{prefix} = $full;
                    }
                    $self->send_output($msg, $route_id);
                }
                next LOOP;
            }
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_accept {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$count || !$args->[0] || $args->[0] eq '*') {
            my $record = $self->{state}{users}{uc_irc($nick)};
            my @list;
            for my $accept (keys %{ $record->{accepts} }) {
                if (!$self->state_nick_exists($accept)) {
                    delete $record->{accepts}{$accept};
                    next;
                }
                push @list, $self->state_user_nick($accept);
            }
            push @$ref, {
                prefix  => $server,
                command => '281',
                params  => [$nick, join( ' ', @list)],
            } if @list;

            push @$ref, {
                prefix  => $server,
                command => '282',
                params  => [$nick, 'End of /ACCEPT list'],
            };
            last SWITCH;
        }
    }

    my $record = $self->{state}{users}{uc_irc($nick)};

    for (keys %{ $record->{accepts} }) {
        delete $record->{accepts}{$_} if !$self->state_nick_exists($_);
    }

    OUTER: for my $target (split /,/, $args->[0]) {
        if (my ($foo) = $target =~ /^\-(.+)$/) {
            my $dfoo = delete $record->{accepts}{uc_irc($foo)};
            if (!$dfoo) {
                push @$ref, {
                    prefix  => $server,
                    command => '458',
                    params  => [$nick, $foo, "doesn\'t exist"],
                };
            }
            delete $self->{state}{accepts}{uc_irc($foo)}{uc_irc($nick)};
            if (!keys %{ $self->{state}{accepts}{uc_irc($foo)} }) {
                delete $self->{state}{accepts}{uc_irc($foo)};
            }
            next OUTER;
        }

        if (!$self->state_nick_exists($target)) {
            push @$ref, ['401', $target];
            next OUTER;
        }
        # 457 ERR_ACCEPTEXIST
        if ($record->{accepts}{uc_irc($target)}) {
            push @$ref, {
                prefix  => $server,
                command => '457',
                params  => [
                    $nick,
                    $self->state_user_nick($target),
                    'already exists',
                ],
            };
            next OUTER;
        }

        if ($record->{umode} && $record->{umode} =~ /G/
                && $self->_state_users_share_chan($nick, $target) ) {
            push @$ref, {
                prefix  => $server,
                command => '457',
                params  => [
                    $nick,
                    $self->state_user_nick($target),
                    'already exists',
                ],
            };
            next OUTER;
        }

        $self->{state}{accepts}{uc_irc($target)}{uc_irc($nick)}
            = $record->{accepts}{uc_irc($target)} = time;
        my @list = map { $self->state_user_nick($_) } keys %{ $record->{accepts} };

        push @$ref, {
            prefix  => $server,
            command => '281',
            params  => [
                $nick,
                join(' ', @list),
            ],
        } if @list;

        push @$ref, {
            prefix  => $server,
            command => '282',
            params  => [$nick, 'End of /ACCEPT list'],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_quit {
    my $self = shift;
    my $nick = shift || return;
    my $qmsg = shift || 'Client Quit';
    my $ref  = [ ];
    my $full = $self->state_user_full($nick);

    $nick = uc_irc($nick);
    my $record = delete $self->{state}{peers}{uc $self->server_name()}{users}{$nick};
    $self->send_output(
        {
            prefix  => $record->{nick},
            command => 'QUIT',
            params  => [$qmsg],
        },
        $self->_state_connected_peers(),
    ) if !$record->{killed};

    push @$ref, {
        prefix  => $full,
        command => 'QUIT',
        params  => [$qmsg],
    };
    $self->send_event("daemon_quit", $full, $qmsg);

    # Remove for peoples accept lists
    for my $user (keys %{ $record->{accepts} }) {
        delete $self->{state}{users}{$user}{accepts}{uc_irc($nick)};
    }

    # Okay, all 'local' users who share a common channel with user.
    my $common = { };
    for my $uchan (keys %{ $record->{chans} }) {
        delete $self->{state}{chans}{$uchan}{users}{$nick};
        for my $user ($self->state_chan_list($uchan)) {
            next if !$self->_state_is_local_user($user);
            $common->{$user} = $self->_state_user_route($user);
        }

        if (!keys %{ $self->{state}{chans}{$uchan}{users} }) {
            delete $self->{state}{chans}{$uchan};
        }
    }

    push @$ref, $common->{$_} for keys %$common;
    $self->{state}{stats}{ops_online}-- if $record->{umode} =~ /o/;
    $self->{state}{stats}{invisible}-- if $record->{umode} =~ /i/;
    delete $self->{state}{users}{$nick} if !$record->{nick_collision};
    delete $self->{state}{localops}{$record->{route_id}};
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_ping {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $args   = [ @_ ];
    my $count  = @$args;
    my $ref    = [ ];

    SWITCH: {
        if (!$count) {
            push @$ref, [ '409' ];
            last SWITCH;
        }

        if ($count >= 2 && !$self->state_peer_exists($args->[1])) {
            push @$ref, ['402', $args->[1]];
            last SWITCH;
        }
        if ($count >= 2 && (uc $args->[1] ne uc $server)) {
            my $target = $self->_state_peer_name($args->[1]);
            $self->send_output(
                {
                    command => 'PING',
                    params  => [$nick, $target],
                },
                $self->_state_peer_route($args->[1]),
            );
            last SWITCH;
        }
        push @$ref, {
            prefix  => $server,
            command => 'PONG',
            params  => [$server, $args->[0]],
        };
    }
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_pong {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = uc $self->server_name();
    my $args   = [ @_ ];
    my $count  = @$args;
    my $ref    = [ ];

    SWITCH: {
        if (!$count) {
            push @$ref, ['409'];
            last SWITCH;
        }
        if ($count >= 2 && !$self->state_peer_exists($args->[1])) {
            push @$ref, ['402', $args->[1]];
            last SWITCH;
        }
        if ($count >= 2 && uc $args->[1] ne uc $server) {
            my $target = $self->_state_peer_name($args->[1]);
            $self->send_output(
                {
                    command => 'PONG',
                    params  => [$nick, $target],
                },
                $self->_state_peer_route($args->[1]),
            );
            last SWITCH;
        }
        delete $self->{state}{users}{uc_irc($nick)}{pinged};
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_pass {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = uc $self->server_name();
    my $ref    = [['462']];
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_user {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = uc $self->server_name();
    my $ref    = [['462']];
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_oper {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        last SWITCH if $self->state_user_is_operator($nick);
        if (!$count || $count < 2) {
            push @$ref, ['461', 'OPER'];
            last SWITCH;
        }

        my $result = $self->_state_o_line($nick, @$args);
        if (!$result || $result <= 0) {
            push @$ref, ['491'];
            last SWITCH;
        }

        $self->{stats}{ops}++;
        my $record = $self->{state}{users}{uc_irc($nick)};
        $record->{umode} .= 'o';
        $self->{state}{stats}{ops_online}++;
        push @$ref, {
            prefix  => $server,
            command => '381',
            params  => [$nick, 'You are now an IRC operator'],
        };

        my $reply = {
            prefix  => $nick,
            command => 'MODE',
            params  => [$nick, '+o'],
        };

        $self->send_output(
            $reply,
            $self->_state_connected_peers(),
        );
        $self->send_event(
            "daemon_umode",
            $self->state_user_full($nick),
            '+o',
        );

        my $route_id = $self->_state_user_route($nick);
        $self->{state}{localops}{$route_id} = time;
        $self->antiflood($route_id, 0);
        push @$ref, $reply;
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_die {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        $self->send_event("daemon_die", $nick);
        $self->shutdown();
    }
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_rehash {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        $self->send_event("daemon_rehash", $nick);
        push @$ref, {
            prefix  => $server,
            command => '383',
            params  => [$nick, 'ircd.conf', 'Rehashing'],
        };
    }
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_locops {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count) {
            push @$ref, ['461', 'LOCOPS'];
            last SWITCH;
        }
        my $full = $self->state_user_full($nick);
        $self->send_output(
            {
                prefix  => $full,
                command => 'WALLOPS',
                params  => ['LOCOPS - ' . $args->[0]],
            },
            keys %{ $self->{state}{locops} },
        );
        $self->send_event("daemon_locops", $full, $args->[0]);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_wallops {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count) {
            push @$ref, ['461', 'WALLOPS'];
            last SWITCH;
        }
        my $full = $self->state_user_full($nick);

        $self->send_output(
            {
                prefix  => $nick,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            $self->_state_connected_peers(),
        );

        $self->send_output(
            {
                prefix  => $full,
                command => 'WALLOPS',
                params  => ['OPERWALL - ' . $args->[0]],
            },
            keys %{ $self->{state}{operwall} },
        );

        $self->send_event("daemon_operwall", $full, $args->[0]);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_operwall {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count) {
            push @$ref, ['461', 'OPERWALL'];
            last SWITCH;
        }
        my $full = $self->state_user_full($nick);

        $self->send_output(
            {
                prefix  => $nick,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            $self->_state_connected_peers(),
        );

        $self->send_output(
            {
                prefix  => $full,
                command => 'WALLOPS',
                params  => ['OPERWALL - ' . $args->[0]],
            },
            keys %{ $self->{state}{operwall} },
        );

        $self->send_event("daemon_operwall", $full, $args->[0]);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_connect {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count) {
            push @$ref, ['461', 'CONNECT'];
            last SWITCH;
        }
        if ($count >= 3 && !$self->state_peer_exists($args->[2])) {
            push @$ref, ['402', $args->[2]];
            last SWITCH;
        }
        if ($count >= 3 && uc $server ne uc $args->[2]) {
            $args->[2] = $self->_state_peer_name($args->[2]);
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'CONNECT',
                    params  => $args,
                },
                $self->_state_peer_route($args->[2]),
            );
            last SWITCH;
        }
        if (!$self->{config}{peers}{uc $args->[0]}
            || $self->{config}{peers}{uc $args->[0]}{type} ne 'r') {
            push @$ref, {
                command => 'NOTICE',
                params  => [
                    $nick,
                    "Connect: Host $args->[0] is not listed in ircd.conf",
                ],
            };
            last SWITCH;
        }
        if (my $peer_name = $self->_state_peer_name($args->[0])) {
            push @$ref, {
                command => 'NOTICE',
                params  => [
                    $nick,
                    "Connect: Server $args->[0] already exists from $peer_name.",
                ],
            };
            last SWITCH;
        }

        my $connector = $self->{config}{peers}{uc $args->[0]};
        my $name = $connector->{name};
        my $rport = $args->[1] || $connector->{rport};
        my $raddr = $connector->{raddress};
        $self->add_connector(
            remoteaddress => $raddr,
            remoteport    => $rport,
            name          => $name,
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_squit {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count) {
            push @$ref, ['461', 'SQUIT'];
            last SWITCH;
        }
        if (!$self->state_peer_exists($args->[0])
           || uc $server eq uc $args->[0]) {
            push @$ref, ['402', $args->[0]];
            last SWITCH;
        }

        my $peer = uc $args->[0];
        my $reason = $args->[1] || 'No Reason';
        $args->[0] = $self->_state_peer_name($peer);
        $args->[1] = $reason;

        if ( !grep { $_ eq $peer }
                keys %{ $self->{state}{peers}{uc $server}{peers} }) {
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'SQUIT',
                    params  => $args,
                },
                $self->_state_peer_route($args->[0]),
            );
            last SWITCH;
        }

        my $conn_id = $self->_state_peer_route($peer);
        $self->disconnect($conn_id, $reason);
        $self->send_output(
            {
                command => 'ERROR',
                params  => [
                    join ' ', 'Closing Link:',
                    $self->_client_ip($conn_id), $args->[0], "($nick)"
                ],
            },
            $conn_id,
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_rkline {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;
    # RKLINE [time] <mask> [ON <server>] :[reason]

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count || $count < 1) {
            push @$ref, ['461', 'RKLINE'];
            last SWITCH;
        }
        my $duration = 0;
        if ($args->[0] =~ /^\d+$/) {
            $duration = shift @$args;
            $duration = 14400 if $duration > 14400;
        }
        my $mask = shift @$args;
        if (!$mask) {
            push @$ref, ['461', 'RKLINE'];
            last SWITCH;
        }
        my ($user, $host) = split /\@/, $mask;
        if (!$user || !$host) {
            last SWITCH;
        }
        my $full = $self->state_user_full($nick);
        my $us = 0;
        my $ucserver = uc $server;

        if ($args->[0] && uc $args->[0] eq 'ON' && @$args < 2) {
            push @$ref, ['461', 'RKLINE'];
            last SWITCH;
        }
        my ($target, $reason);
        if ($args->[0] && uc $args->[0] eq 'ON') {
            $target = shift @$args;
            $reason = shift @{ $args } || 'No Reason';
            my %targets;

            for my $peer (keys %{ $self->{state}{peers} }) {
                if (matches_mask($target, $peer)) {
                    if ($ucserver eq $peer) {
                        $us = 1;
                    }
                    else {
                        $targets{ $self->_state_peer_route($peer) }++;
                    }
                }
            }

            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'RKLINE',
                    params  => [$target, $duration, $user, $host, $reason],
                    colonify => 0,
                },
                grep { $self->_state_peer_capab($_, 'KLN') } keys %targets,
            );
        }
        else {
            $us = 1;
        }

        if ($us) {
            $target = $server if !$target;
                if (!$reason) {
                $reason = pop @$args || 'No Reason';
            }
            $self->send_event(
                "daemon_rkline",
                $full,
                $target,
                $duration,
                $user,
                $host,
                $reason,
            );

            push @{ $self->{state}{rklines} }, {
                setby    => $full,
                setat    => time(),
                target   => $target,
                duration => $duration,
                user     => $user,
                host     => $host,
                reason   => $reason,
            };

            for ($self->_state_local_users_match_rkline($user, $host)) {
                $self->_terminate_conn_error($_, 'K-Lined');
            }
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_kline {
    my $self = shift;
    my $nick = shift || return;
    my $server = $self->server_name();
    my $ref = [ ];
    my $args = [@_];
    my $count = @$args;
    # KLINE [time] <nick|user@host> [ ON <server> ] :[reason]

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count || $count < 1) {
            push @$ref, ['461', 'KLINE'];
            last SWITCH;
        }
        my $duration = 0;
        if ($args->[0] =~ /^\d+$/) {
            $duration = shift @$args;
            $duration = 14400 if $duration > 14400;
        }
        my $mask = shift @$args;
        if (!$mask) {
            push @$ref, ['461', 'KLINE'];
            last SWITCH;
        }
        my ($user, $host);
        if ($mask !~ /\@/) {
            if (my $rogue = $self->_state_user_full($mask)) {
                ($user, $host) = (split /[!\@]/, $rogue )[1..2];
            }
            else {
                push @$ref, ['401', $mask];
                last SWITCH;
            }
        }
        else {
            ($user, $host) = split /\@/, $mask;
        }

        my $full = $self->state_user_full($nick);
        my $us = 0;
        my $ucserver = uc $server;
        if ($args->[0] && uc $args->[0] eq 'ON'
                && scalar @$args < 2) {
            push @$ref, ['461', 'KLINE'];
            last SWITCH;
        }
        my ($target, $reason);
        if ($args->[0] && uc $args->[0] eq 'ON') {
            $target = shift @$args;
            $reason = shift @$args || 'No Reason';
            my %targets;

            for my $peer (keys %{ $self->{state}{peers} }) {
                if (matches_mask($target, $peer)) {
                    if ($ucserver eq $peer) {
                        $us = 1;
                    }
                    else {
                        $targets{ $self->_state_peer_route($peer) }++;
                    }
                }
            }

            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'KLINE',
                    params  => [
                        $target,
                        $duration,
                        $user,
                        $host,
                        $reason,
                    ],
                    colonify => 0,
                },
                grep { $self->_state_peer_capab($_, 'KLN') } keys %targets,
            );
        }
        else {
            $us = 1;
        }

        if ($us) {
            $target = $server if !$target;
            if (!$reason) {
                $reason = pop @$args || 'No Reason';
            }
            $self->send_event(
                "daemon_kline",
                $full,
                $target,
                $duration,
                $user,
                $host,
                $reason,
            );

            push @{ $self->{state}{klines} }, {
                setby    => $full,
                setat    => time,
                target   => $target,
                duration => $duration,
                user     => $user,
                host     => $host,
                reason   => $reason,
            };

            for ($self->_state_local_users_match_gline($user, $host)) {
                $self->_terminate_conn_error($_, 'K-Lined');
            }
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_unkline {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;
    # UNKLINE <user@host> [ ON <target_mask> ]

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count || $count < 1) {
            push @$ref, ['461', 'UNKLINE'];
            last SWITCH;
        }
        my ($user, $host);
        if ($args->[0] !~ /\@/) {
            if (my $rogue = $self->state_user_full($args->[0])) {
                ($user, $host) = (split /[!\@]/, $rogue)[1..2]
            }
            else {
                push @$ref, ['401', $args->[0]];
                last SWITCH;
            }
        }
        else {
            ($user, $host) = split /\@/, $args->[0];
        }

        my $full = $self->state_user_full($nick);
        my $us = 0;
        my $ucserver = uc $server;
        if ($count > 1 && uc $args->[2] eq 'ON' && $count < 3) {
            push @$ref, ['461', 'UNKLINE'];
            last SWITCH;
        }
        if ($count > 1 && $args->[2] && uc $args->[2] eq 'ON') {
            my $target = $args->[2];
            my %targets;
            for my $peer (keys %{ $self->{state}{peers} }) {
                if (matches_mask($target, $peer)) {
                    if ($ucserver eq $peer) {
                        $us = 1;
                    }
                    else {
                        $targets{ $self->_state_peer_route( $peer ) }++;
                    }
                }
            }

            $self->send_output(
                {
                    prefix   => $nick,
                    command  => 'UNKLINE',
                    params   => [$target, $user, $host],
                    colonify => 0,
                },
                grep { $self->_state_peer_capab($_, 'UNKLN') } keys %targets,
            );
        }
        else {
            $us = 1;
        }
        if ($us) {
            my $target = $args->[3] || $server;
            $self->send_event(
                "daemon_unkline", $full, $target, $user, $host,
            );
            my $i = 0;
            for (@{ $self->{state}{klines} }) {
                if ($_->{user} eq $user && $_->{host} eq $host) {
                    splice @{ $self->{state}{klines} }, $i, 1;
                    last;
                }
                ++$i;
            }
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_gline {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;
    # :klanker GLINE * meep.com :Fuckers

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count || $count < 2) {
            push @$ref, ['461', 'GLINE'];
            last SWITCH;
        }
        if ($args->[0] !~ /\@/ && !$self->state_nick_exists($args->[0])) {
            push @$ref, ['401', $args->[0]];
            last SWITCH;
        }
        my ($user_part, $host_part);
        if ($args->[0] =~ /\@/) {
            ($user_part, $host_part)
            = (split /[!@]/, $self->state_user_full($args->[0]))[1..2];
        }
        else {
            ($user_part, $host_part) = split /\@/, $args->[0];
        }
        my $time = time;
        my $reason = join ' ', $args->[1], strftime('(%c)', localtime $time);
        my $full = $self->state_user_full($nick);

        push @{ $self->{state}{glines} }, {
            setby  => $full,
            setat  => time,
            user   => $user_part,
            host   => $host_part,
            reason => $reason,
        };

        $self->send_output(
            {
                prefix   => $nick,
                command  => 'GLINE',
                params   => [$user_part, $host_part, $reason],
                colonify => 0,
            },
            grep { $self->_state_peer_capab($_, 'GLN') }
                $self->_state_connected_peers()
        );

        $self->send_event(
            "daemon_gline",
            $full,
            $user_part,
            $host_part,
            $reason,
        );

        for ($self->_state_local_users_match_gline($user_part, $host_part)) {
            $self->_terminate_conn_error($_, 'G-Lined');
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_kill {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count) {
            push @$ref, ['461', 'KILL'];
            last SWITCH;
        }
        if ($self->state_peer_exists($args->[0])) {
            push @$ref, ['483'];
            last SWITCH;
        }
        if (!$self->state_nick_exists($args->[0])) {
            push @$ref, ['401', $args->[0]];
            last SWITCH;
        }
        my $target = $self->state_user_nick($args->[0]);
        my $comment = $args->[1] || '<No reason given>';
        if ($self->_state_is_local_user($target)) {
            my $route_id = $self->_state_user_route($target);
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'KILL',
                    params  => [
                        $target,
                        join('!', $server, $nick )." ($comment)",
                    ]
                },
                $self->_state_connected_peers(),
            );

            $self->send_output(
                {
                    prefix  => $self->state_user_full($nick),
                    command => 'KILL',
                    params  => [$target, $comment],
                },
                $route_id,
            );
            if ($route_id eq 'spoofed') {
                $self->call('del_spoofed_nick', $target, "Killed ($comment)");
            }
            else {
                $self->{state}{conns}{$route_id}{killed} = 1;
                $self->_terminate_conn_error($route_id, "Killed ($comment)");
            }
        }
        else {
            $self->{state}{users}{uc_irc($target)}{killed} = 1;
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'KILL',
                    params  => [
                        $target,
                        join('!', $server, $nick )." ($comment)",
                    ],
                },
                $self->_state_connected_peers(),
            );
            $self->send_output(
                @{ $self->_daemon_peer_quit(
                    $target,
                    "Killed ($nick ($comment))"
                )}
            );
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_nick {
    my $self   = shift;
    my $nick   = shift || return;
    my $new    = shift;
    my $server = uc $self->server_name();
    my $ref    = [ ];

    SWITCH: {
        if (!$new) {
            push @$ref, ['431'];
            last SWITCH;
        }
        my $nicklen = $self->server_config('NICKLEN');
        $new = substr($new, 0, $nicklen) if length($new) > $nicklen;
        if ($nick eq $new) {
            last SWITCH;
        }
        if (!is_valid_nick_name($new)) {
            push @$ref, ['432', $new];
            last SWITCH;
        }
        my $unick = uc_irc($nick);
        my $unew = uc_irc($new);
        if ($self->state_nick_exists($new) && $unick ne $unew) {
            push @$ref, ['433', $new];
            last SWITCH;
        }
        my $full = $self->state_user_full($nick);
        my $record = $self->{state}{users}{$unick};
        my $common = { $nick => $record->{route_id} };

        for my $chan (keys %{ $record->{chans} }) {
            for my $user ($self->state_chan_list($chan)) {
                next if !$self->_state_is_local_user($user);
                $common->{$user} = $self->_state_user_route($user);
            }
        }
        if ($unick eq $unew) {
            $record->{nick} = $new;
            $record->{ts} = time;
        }
        else {
            $record->{nick} = $new;
            $record->{ts} = time;
            # Remove from peoples accept lists
            for (keys %{ $record->{accepts} }) {
                delete $self->{state}{users}{$_}{accepts}{$unick};
            }
            delete $record->{accepts};
            delete $self->{state}{users}{$unick};
            $self->{state}{users}{$unew} = $record;
            delete $self->{state}{peers}{$server}{users}{$unick};
            $self->{state}{peers}{$server}{users}{$unew} = $record;

            for my $chan (keys %{ $record->{chans} }) {
                $self->{state}{chans}{$chan}{users}{$unew}
                    = delete $self->{state}{chans}{$chan}{users}{$unick};
            }
        }
        my @peers = $self->_state_connected_peers();
        $self->send_output(
            {
                prefix  => $nick,
                command => 'NICK',
                params  => [$new, $record->{ts}],
            },
            @peers,
        );

        $self->send_output(
            {
                prefix  => $full,
                command => 'NICK',
                params  => [$new],
            },
            map{ $common->{$_} } keys %$common,
        );
        $self->send_event("daemon_nick", $full, $new);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_away {
    my $self   = shift;
    my $nick   = shift || return;
    my $msg    = shift;
    my $server = $self->server_name();
    my $ref    = [ ];

    SWITCH: {
        my $record = $self->{state}{users}{uc_irc($nick)};
        if (!$msg) {
            delete $record->{away};
            $self->send_output(
                {
                    prefix => $nick,
                    command => 'AWAY',
                    colonify => 0,
                },
                $self->_state_connected_peers(),
            );
            push @$ref, {
                prefix  => $server,
                command => '305',
                params  => ['You are no longer marked as being away'],
            };
            last SWITCH;
        }

        $record->{away} = $msg;
        $self->send_output(
            {
                prefix   => $nick,
                command  => 'AWAY',
                params   => [$msg],
                colonify => 0,
            },
            $self->_state_connected_peers(),
        );
        push @$ref, {
            prefix  => $server,
            command => '306',
            params  => ['You have been marked as being away'],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

# Pseudo cmd for ISupport 005 numerics
sub _daemon_cmd_isupport {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];

    push @$ref, {
        prefix  => $server,
        command => '005',
        params  => [
            $nick,
            join(' ', map {
                (defined $self->{config}{isupport}{$_}
                    ? join '=', $_, $self->{config}{isupport}{$_}
                    : $_
                )
                } qw(CALLERID EXCEPTS INVEX MAXCHANNELS MAXBANS MAXTARGETS
                     NICKLEN TOPICLEN KICKLEN)
            ),
            'are supported by this server',
        ],
    };

    push @$ref, {
        prefix  => $server,
        command => '005',
        params  => [
            $nick,
            join(' ', map {
                (defined $self->{config}{isupport}{$_}
                    ? join '=', $_, $self->{config}{isupport}{$_}
                    : $_
                )
                } qw(CHANTYPES PREFIX CHANMODES NETWORK CASEMAPPING DEAF)
            ), 'are supported by this server',
        ],
    };

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_info {
    my $self   = shift;
    my $nick   = shift || return;
    my $target = shift;
    my $server = $self->server_name();
    my $ref    = [ ];

    SWITCH: {
        if ($target && !$self->state_peer_exists($target)) {
            push @$ref, ['402', $target];
            last SWITCH;
        }
        if ($target && uc $server ne uc $target) {
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'INFO',
                    params  => [$self->_state_peer_name($target)],
                },
                $self->_state_peer_route($target),
            );
            last SWITCH;
        }

        for my $info (@{ $self->server_config('Info') }) {
            push @$ref, {
                prefix => $server,
                command => '371',
                params => [$nick, $info],
            };
        }

        push @$ref, {
            prefix  => $server,
            command => '374',
            params  => [$nick, 'End of /INFO list.'],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_version {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $target = shift;

    SWITCH: {
        if ($target && !$self->state_peer_exists($target)) {
            push @$ref, ['402', $target];
            last SWITCH;
        }
        if ($target && uc $server ne uc $target) {
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'VERSION',
                    params  => [$self->_state_peer_name($target)],
                },
                $self->_state_peer_route($target)
            );
            last SWITCH;
        }

        push @$ref, {
            prefix  => $server,
            command => '351',
            params  => [
                $nick,
                $self->server_version(),
                $server,
                'eGHIMZ TS5ow',
            ],
        };
        push @$ref, $_ for @{ $self->_daemon_cmd_isupport($nick) };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_admin {
    my $self   = shift;
    my $nick   = shift || return;
    my $target = shift;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $admin  = $self->server_config('Admin');

    SWITCH: {
        if ($target && !$self->state_peer_exists($target)) {
            push @$ref, ['402', $target];
            last SWITCH;
        }
        if ($target && uc $server ne uc $target) {
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'ADMIN',
                    params  => [$self->_state_peer_name($target)],
                },
                $self->_state_peer_route($target),
            );
            last SWITCH;
        }

        push @$ref, {
            prefix  => $server,
            command => '256',
            params  => [$nick, $server, 'Administrative Info'],
        };

        push @$ref, {
            prefix  => $server,
            command => '257',
            params  => [$nick, $admin->[0]],
        };

        push @$ref, {
            prefix  => $server,
            command => '258',
            params  => [$nick, $admin->[1]],
        };

        push @$ref, {
            prefix  => $server,
            command => '259',
            params  => [$nick, $admin->[2]],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_summon {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    push @$ref, '445';
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_time {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $target = shift;
    my $ref    = [ ];

    SWITCH: {
        if ($target && !$self->state_peer_exists($target)) {
            push @$ref, ['402', $target];
            last SWITCH;
        }
        if ($target && uc $server ne uc $target) {
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'TIME',
                    params  => [$self->_state_peer_name($target)],
                },
                $self->_state_peer_route($target),
            );
            last SWITCH;
        }

        push @$ref, {
            prefix  => $server,
            command => '391',
            params  => [
                $nick,
                $server,
                strftime("%A %B %e %Y -- %T %z", localtime),
            ],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_users {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $global = keys %{ $self->{state}{users} };
    my $local  = keys %{ $self->{state}{peers}{uc $server}{users} };

    push @$ref, {
        prefix  => $server,
        command => '265',
        params  => [
            $nick,
            "Current local users: $local  Max: "
                . $self->{state}{stats}{maxlocal},
        ],
    };

    push @$ref, {
        prefix  => $server,
        command => '266',
        params  => [
            $nick,
            "Current global users: $global  Max: "
                . $self->{state}{stats}{maxglobal},
        ],
    };

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_lusers {
    my $self       = shift;
    my $nick       = shift || return;
    my $server     = $self->server_name();
    my $ref        = [ ];
    my $invisible  = $self->{state}{stats}{invisible};
    my $users      = keys(%{ $self->{state}{users} }) - $invisible;
    my $servers    = keys %{ $self->{state}{peers} };
    my $chans      = keys %{ $self->{state}{chans} };
    my $local      = keys %{ $self->{state}{peers}{uc $server}{users} };
    my $peers      = keys %{ $self->{state}{peers}{uc $server}{peers} };
    my $totalconns = $self->{state}{stats}{conns_cumlative};
    my $mlocal     = $self->{state}{stats}{maxlocal};
    my $conns      = $self->{state}{stats}{maxconns};

    push @$ref, {
        prefix  => $server,
        command => '251',
        params  => [
            $nick,
            "There are $users users and $invisible invisible on "
                . "$servers servers",
        ],
    };

    $servers--;

    push @$ref, {
        prefix  => $server,
        command => '252',
        params  => [
            $nick,
            $self->{state}{stats}{ops_online},
            "IRC Operators online",
        ]
    } if $self->{state}{stats}{ops_online};

    push @$ref, {
        prefix  => $server,
        command => '254',
        params  => [$nick, $chans, "channels formed"],
    } if $chans;

    push @$ref, {
        prefix  => $server,
        command => '255',
        params  => [$nick, "I have $local clients and $peers servers"],
    };

    push @$ref, $_ for $self->_daemon_cmd_users($nick);

    push @$ref, {
        prefix  => $server,
        command => '250',
        params  => [
            $nick, "Highest connection count: $conns ($mlocal clients) "
                . "($totalconns connections received)",
        ],
    };

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_motd {
    my $self   = shift;
    my $nick   = shift || return;
    my $target = shift;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $motd   = $self->server_config('MOTD');

    SWITCH: {
        if ($target && !$self->state_peer_exists($target)) {
            push @$ref, ['402', $target];
            last SWITCH;
        }
        if ($target && uc $server ne uc $target) {
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'MOTD',
                    params  => [$self->_state_peer_name($target)],
                },
                $self->_state_peer_route($target),
            );
            last SWITCH;
        }
        if ($motd && ref $motd eq 'ARRAY') {
            push @$ref, {
                prefix  => $server,
                command => '375',
                params  => [$nick, "- $server Message of the day - "],
            };
            push @$ref, {
                prefix  => $server,
                command => '372',
                params  => [$nick, "- $_"]
            } for @$motd;
            push @$ref, {
                prefix  => $server,
                command => '376',
                params  => [$nick, "End of MOTD command"],
            };
        }
        else {
            push @$ref, '422';
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_stats {
    my $self   = shift;
    my $nick   = shift || return;
    my $char   = shift;
    my $target = shift;
    my $server = $self->server_name();
    my $ref    = [ ];

    SWITCH: {
        if (!$char) {
            push @$ref, ['461', 'STATS'];
            last SWITCH;
        }
        $char = substr $char, 0, 1;
        if ($char !~ /[ump]/) {
            push @$ref, {
                prefix  => $server,
                command => '263',
                params  => [
                    $nick,
                    'Server load is temporarily too heavy. '
                        .'Please wait a while and try again.'
                ],
            };
            last SWITCH;
        }
        if ($target && !$self->state_peer_exists($target)) {
            push @$ref, ['402', $target];
            last SWITCH;
        }
        if ($target && uc $server ne uc $target) {
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'STATS',
                    params  => [
                        $char,
                        $self->_state_peer_name($target),
                    ],
                },
                $self->_state_peer_route($target),
            );
            last SWITCH;
        }

        SWITCH2: {
            if ($char eq 'u') {
                my $uptime = time - $self->server_config('created');
                my $days   = int $uptime / 86400;
                my $remain = $uptime % 86400;
                my $hours  = int $remain / 3600;
                $remain   %= 3600;
                my $mins   = int $remain / 60;
                $remain   %= 60;

                push @$ref, {
                    prefix  => $server,
                    command => '242',
                    params  => [
                        $nick,
                        sprintf("Server Up %d days, %2.2d:%2.2d:%2.2d",
                            $days, $hours, $mins, $remain),
                    ],
                };

                my $totalconns = $self->{state}{stats}{conns_cumlative};
                my $local = $self->{state}{stats}{maxlocal};
                my $conns = $self->{state}{stats}{maxconns};

                push @$ref, {
                    prefix  => $server,
                    command => '250',
                    params  => [
                        $nick,
                        "Highest connection count: $conns ($local "
                            ."clients) ($totalconns connections received)",
                    ],
                };
                last SWITCH2;
            }
            if ($char eq 'm') {
                my $cmds = $self->{state}{stats}{cmds};
                push @$ref, {
                    prefix  => $server,
                    command => '212',
                    params  => [
                        $nick,
                        $_,
                        $cmds->{$_}{local},
                        $cmds->{$_}{bytes},
                        $cmds->{$_}{remote},
                    ],
                } for sort keys %$cmds;
                last SWITCH2;
            }
            if ($char eq 'p') {
                my @ops = map { $self->_client_nickname( $_ ) }
                    keys %{ $self->{state}{localops} };
                for my $op (sort @ops) {
                    my $record = $self->{state}{users}{uc_irc($op)};
                    push @$ref, {
                        prefix  => $server,
                        command => '249',
                        params  => [
                            $nick,
                            sprintf("[O] %s (%s\@%s) Idle: %u",
                                $record->{nick}, $record->{auth}{ident},
                                $record->{auth}{hostname},
                                time - $record->{idle_time}),
                        ],
                    };
                }

                push @$ref, {
                    prefix  => $server,
                    command => '249',
                    params  => [$nick, scalar @ops . " OPER(s)"],
                };
                last SWITCH2;
            }
        }

        push @$ref, {
            prefix  => $server,
            command => '219',
            params  => [$nick, $char, 'End of /STATS report'],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_userhost {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $str    = '';

    for my $query (@_) {
        my ($proper, $userhost)
            = split /!/, $self->state_user_full($query);
        if ($proper && $userhost) {
            $str = join(' ', $str, $proper
                . ($self->state_user_is_operator($proper)
                    ? '*'
                    : ''
                ) . '=' . ($self->_state_user_away($proper)
                    ? '-'
                    : '+'
                ) . $userhost);
        }
    }

    push @$ref, {
        prefix  => $server,
        command => '302',
        params  => [$nick, ($str ? $str : ':')],
    };

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_ison {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$count) {
            push @$ref, ['461', 'ISON'];
            last SWITCH;
        }
        my $string = '';
        $string = join ' ', map {
            $self->{state}{users}{uc_irc($_)}{nick}
        } grep { $self->state_nick_exists($_) } @$args;

        push @$ref, {
            prefix  => $server,
            command => '303',
            params  => [$nick, ($string =~ /\s+/ ? $string : ":$string")],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_list {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        my @chans;
        if (!$count) {
            @chans = map { $self->_state_chan_name($_) }
                keys %{ $self->{state}{chans} };
        }
        my $last = pop @$args;
        if ($count && $last !~ /^[#&]/ &&
            !$self->state_peer_exists($last)) {
            push @$ref, ['401', $last];
            last SWITCH;
        }
        if ($count && $last !~ /^[#&]/ && uc $last ne uc $server) {
            $self->send_output(
                {
                    prefix  => $self->state_user_full($nick),
                    command => 'LIST',
                    params  => [
                        @$args,
                        $self->_state_peer_name($last),
                    ],
                }, $self->_state_peer_route($last),
            );
            last SWITCH;
        }
        if ($count && $last !~ /^[#&]/ && @$args == 0) {
            @chans = map { $self->_state_chan_name($_) }
                keys %{ $self->{state}{chans} };
        }
        if ($count && $last !~ /^[#&]/ && @$args == 1) {
            $last = pop @$args;
        }
        if ($count && $last =~ /^[#&]/) {
            @chans = split /,/, $last;
        }
        push @$ref, {
            prefix  => $server,
            command => '321',
            params  => [$nick, 'Channel', 'Users  Name'],
        };

        my $count = 0;
        INNER: for my $chan (@chans) {
            if (!is_valid_chan_name($chan)
                || !$self->state_chan_exists($chan)) {
                if (!$count) {
                    push @$ref, ['401', $chan];
                    last INNER;
                }
                $count++;
                next INNER;
            }
            $count++;
            if ($self->state_chan_mode_set( $chan, 'p')
                    || $self->state_chan_mode_set($chan, 's')
                    && !$self->state_is_chan_member($nick, $chan)) {
                next INNER;
            }
            my $record = $self->{state}{chans}{uc_irc($chan)};
            push @$ref, {
                prefix  => $server,
                command => '322',
                params  => [
                    $nick,
                    $record->{name},
                    scalar keys %{ $record->{users} },
                    (defined $record->{topic}
                        ? $record->{topic}[0]
                        : ''
                    ),
                ],
            };
        }

        push @$ref, {
            prefix  => $server,
            command => '323',
            params  => [$nick, 'End of /LIST'],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_names {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        my (@chans, $query);
        if (!$count) {
            @chans = $self->state_user_chans($nick);
            $query = '*';
        }
        my $last = pop @$args;
        if ($count && $last !~ /^[#&]/
            && !$self->state_peer_exists($last)) {
            push @$ref, ['401', $last];
            last SWITCH;
        }
        if ($count && $last !~ /^[#&]/ & uc $last ne uc $server) {
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'NAMES',
                    params  => [@$args, $self->_state_peer_name($last)],
                },
                $self->_state_peer_route($last),
            );
            last SWITCH;
        }
        if ($count && $last !~ /^[#&]/ && @$args == 0) {
            @chans = $self->state_user_chans($nick);
            $query = '*';
        }
        if ($count && $last !~ /^[#&]/ && @$args == 1) {
            $last = pop @$args;
        }
        if ($count && $last =~ /^[#&]/) {
            my ($chan) = grep {
                $_ && $self->state_chan_exists($_)
                && $self->state_is_chan_member($nick, $_)
            } split /,/, $last;
            @chans = ();

            if ($chan) {
                push @chans, $chan;
                $query = $self->_state_chan_name($chan);
            }
            else {
                $query = '*';
            }
        }

        for my $chan (@chans) {
            my $record = $self->{state}{chans}{uc_irc($chan)};
            my $type = '=';
            $type = '@' if $record->{mode} =~ /s/;
            $type = '*' if $record->{mode} =~ /p/;
            my $length = length($server)+3+length($chan)+length($nick)+7;
            my $buffer = '';

            for my $name (sort $self->state_chan_list_prefixed($record->{name})) {
                if (length(join ' ', $buffer, $name) + $length > 510) {
                    push @$ref, {
                        prefix  => $server,
                        command => '353',
                        params  => [$nick, $type, $record->{name}, $buffer]
                    };
                    $buffer = $name;
                    next;
                }
                if ($buffer) {
                    $buffer = join ' ', $buffer, $name;
                }
                else {
                    $buffer = $name;
                }
            }
            push @$ref, {
                prefix  => $server,
                command => '353',
                params  => [$nick, $type, $record->{name}, $buffer],
            };
        }
        push @$ref, {
            prefix  => $server,
            command => '366',
            params  => [$nick, $query, 'End of NAMES list'],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_whois {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my ($first, $second) = @_;

    SWITCH: {
        if (!$first && !$second) {
            push @$ref, ['431'];
            last SWITCH;
        }
        if (!$second && $first) {
            $second = (split /,/, $first)[0];
            $first = $server;
        }
        if ($first && $second) {
            $second = (split /,/, $second)[0];
        }
        if (uc_irc($first) eq uc_irc($second)
            && $self->state_nick_exists($second)) {
            $first = $self->state_user_server($second);
        }
        my $query;
        my $target;
        $query = $first if !$second;
        $query = $second if $second;
        $target = $first if $second && uc $first ne uc$server;
        if ($target && !$self->state_peer_exists($target)) {
            push @$ref, ['402', $target];
            last SWITCH;
        }
        if ($target) {
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'WHOIS',
                    params  => [
                        $self->_state_peer_name($target),
                        $second,
                    ],
                },
                $self->_state_peer_route($target),
            );
            last SWITCH;
        }
        # Okay we got here *phew*
        if (!$self->state_nick_exists($query)) {
            push @$ref, ['401', $query];
        }
        else {
            my $record = $self->{state}{users}{uc_irc($query)};
            push @$ref, {
                prefix  => $server,
                command => '311',
                params  => [
                    $nick,
                    $record->{nick},
                    $record->{auth}{ident},
                    $record->{auth}{hostname},
                    '*',
                    $record->{ircname},
                ],
            };
            my @chans;
            LOOP: for my $chan (keys %{ $record->{chans} }) {
                if ($self->{state}{chans}{$chan}{mode} =~ /[ps]/
                        && !$self->state_is_chan_member($nick, $chan)) {
                    next LOOP;
                }
                my $prefix = '';
                $prefix .= '@' if $record->{chans}{$chan} =~ /o/;
                $prefix .= '%' if $record->{chans}{$chan} =~ /h/;
                $prefix .= '+' if $record->{chans}{$chan} =~ /v/;
                push @chans, $prefix . $self->{state}{chans}{$chan}{name};
            }
            if (@chans) {
                my $buffer = '';
                my $length = length($server) + 3 + length($nick)
                    + length($record->{nick}) + 7;

                LOOP2: for my $chan (@chans) {
                    if (length(join ' ', $buffer, $chan) + $length > 510) {
                        push @$ref, {
                            prefix  => $server,
                            command => '319',
                            params  => [$nick, $record->{nick}, $buffer],
                        };
                        $buffer = $chan;
                        next LOOP2;
                    }
                    if ($buffer) {
                        $buffer = join ' ', $buffer, $chan;
                    }
                    else {
                        $buffer = $chan;
                    }
                }
                push @$ref, {
                    prefix  => $server,
                    command => '319',
                    params  => [$nick, $record->{nick}, $buffer],
                };
            }
            push @$ref, {
                prefix  => $server,
                command => '312',
                params  => [
                    $nick,
                    $record->{nick},
                    $record->{server},
                    $self->_state_peer_desc($record->{server}),
                ],
            };
            push @$ref, {
                prefix  => $server,
                command => '301',
                params  => [
                    $nick,
                    $record->{nick},
                    $record->{away},
                ],
            } if $record->{type} eq 'c' && $record->{away};
            push @$ref, {
                prefix  => $server,
                command => '313',
                params  => [$nick, $record->{nick}, 'is an IRC Operator'],
            } if $record->{umode} && $record->{umode} =~ /o/;
            if ($record->{type} eq 'c'
                && ($self->server_config('whoisactually')
                    or $self->state_user_is_operator($nick))) {
                push @$ref, {
                    prefix  => $server,
                    command => '338',
                    params  => [
                        $nick,
                        $record->{nick},
                        $record->{socket}[0],
                        'actually using host',
                    ],
                };
            }
            push @$ref, {
                prefix  => $server,
                command => '317',
                params  => [
                    $nick,
                    $record->{nick},
                    time - $record->{idle_time},
                    $record->{conn_time},
                    'seconds idle, signon time',
                ],
            } if $record->{type} eq 'c';
        }
        push @$ref, {
            prefix  => $server,
            command => '318',
            params  => [$nick, $query, 'End of /WHOIS list.'],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_who {
    my $self   = shift;
    my $nick   = shift || return;
    my ($who, $op_only) = @_;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $orig   = $who;

    SWITCH: {
        if (!$who) {
            push @$ref, ['461', 'WHO'];
            last SWITCH;
        }
        if ($self->state_chan_exists($who)
            && $self->state_is_chan_member($nick, $who)) {
            my $record = $self->{state}{chans}{uc_irc($who)};
            $who = $record->{name};
            for my $member (keys %{ $record->{users} }) {
                my $rpl_who = {
                    prefix  => $server,
                    command => '352',
                    params  => [$nick, $who],
                };
                my $memrec = $self->{state}{users}{$member};
                push @{ $rpl_who->{params} }, $memrec->{auth}{ident};
                push @{ $rpl_who->{params} }, $memrec->{auth}{hostname};
                push @{ $rpl_who->{params} }, $memrec->{server};
                push @{ $rpl_who->{params} }, $memrec->{nick};
                my $status = ($memrec->{away} ? 'G' : 'H');
                $status .= '*' if $memrec->{umode} =~ /o/;
                $status .= '@' if $record->{users}{$member} =~ /o/;
                $status .= '%' if $record->{users}{$member} =~ /h/;
                $status .= '+' if $record->{users}{$member} !~ /o/
                    and $record->{users}{$member} =~ /v/;
                push @{ $rpl_who->{params} }, $status;
                push @{ $rpl_who->{params} }, "$memrec->{hops} "
                    . $memrec->{ircname};
                push @$ref, $rpl_who;
            }
        }
        if ($self->state_nick_exists($who)) {
            my $nickrec = $self->{state}{users}{uc_irc($who)};
            $who = $nickrec->{nick};
            my $rpl_who = {
                prefix  => $server,
                command => '352',
                params  => [$nick, '*'],
            };
            push @{ $rpl_who->{params} }, $nickrec->{auth}{ident};
            push @{ $rpl_who->{params} }, $nickrec->{auth}{hostname};
            push @{ $rpl_who->{params} }, $nickrec->{server};
            push @{ $rpl_who->{params} }, $nickrec->{nick};
            my $status = ($nickrec->{away} ? 'G' : 'H');
            $status .= '*' if $nickrec->{umode} =~ /o/;
            push @{ $rpl_who->{params} }, $status;
            push @{ $rpl_who->{params} }, "$nickrec->{hops} "
                . $nickrec->{ircname};
            push @$ref, $rpl_who;
        }
        push @$ref, {
            prefix  => $server,
            command => '315',
            params  => [$nick, $orig, 'End of WHO list'],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_mode {
    my $self     = shift;
    my $nick     = shift || return;
    my $chan     = shift;
    my $server   = $self->server_name();
    my $maxmodes = $self->server_config('MODES');
    my $ref      = [ ];
    my $args     = [@_];
    my $count    = @$args;

    SWITCH: {
        if (!$self->state_chan_exists($chan)) {
            push @$ref, ['403', $chan];
            last SWITCH;
        }

        my $record = $self->{state}{chans}{uc_irc($chan)};
        $chan = $record->{name};

        if (!$count && !$self->state_is_chan_member($nick, $chan)) {
            push @$ref, {
                prefix   => $server,
                command  => '324',
                params   => [$nick, $chan, '+' . $record->{mode}],
                colonify => 0,
            };
            push @$ref, {
                prefix   => $server,
                command  => '329',
                params   => [$nick, $chan, $record->{ts}],
                colonify => 0,
            };
            last SWITCH;
        }
        if (!$count) {
            push @$ref, {
                prefix  => $server,
                command => '324',
                params  => [
                    $nick,
                    $chan,
                    '+' . $record->{mode},
                    ($record->{ckey} || ()),
                    ($record->{climit} || ()),
                ],
                colonify => 0,
            };
            push @$ref, {
                prefix   => $server,
                command  => '329',
                params   => [$nick, $chan, $record->{ts}],
                colonify => 0,
            };
            last SWITCH;
        }

        my $unknown = 0;
        my $notop = 0;
        my $nick_is_op = $self->state_is_chan_op($nick, $chan);
        my $nick_is_hop = $self->state_is_chan_hop($nick, $chan);
        my $reply;
        my @reply_args;
        my $parsed_mode = parse_mode_line(@$args);
        my $mode_count = 0;

        while (my $mode = shift @{ $parsed_mode->{modes} }) {
            if ($mode !~ /[eIbklimnpstohv]/) {
                push @$ref, [
                    '472',
                    (split //, $mode)[1],
                    $chan,
                ] if !$unknown;
                $unknown++;
                next;
            }

            my $arg;
            if ($mode =~ /^(\+[ohvklbIe]|-[ohvbIe])/) {
                $arg = shift @{ $parsed_mode->{args} };
            }
            if ($mode =~ /[-+]b/ && !defined $arg) {
                push @$ref, {
                    prefix  => $server,
                    command => '367',
                    params  => [
                        $nick,
                        $chan,
                        @{ $record->{bans}{$_} },
                    ]
                } for keys %{ $record->{bans} };
                push @$ref, {
                    prefix  => $server,
                    command => '368',
                    params  => [$nick, $chan, 'End of Channel Ban List'],
                };
                next;
            }
            if (!$nick_is_op && !$nick_is_hop) {
                push @$ref, ['482', $chan] if !$notop;
                $notop++;
                next;
            }
            if ($mode =~ /[-+]I/ && !defined $arg) {
                push @$ref, {
                    prefix  => $server,
                    command => '346',
                    params  => [
                        $nick,
                        $chan,
                        @{ $record->{invex}{$_} },
                    ],
                } for keys %{ $record->{invex} };
                push @$ref, {
                    prefix  => $server,
                    command => '347',
                    params  => [$nick, $chan, 'End of Channel Invite List']
                };
                next;
            }
            if ($mode =~ /[-+]e/ && !defined $arg) {
                push @$ref, {
                    prefix  => $server,
                    command => '348',
                    params  => [$nick, $chan, @{ $record->{excepts}{$_} } ]
                } for keys %{ $record->{excepts} };
                push @$ref, {
                    prefix  => $server,
                    command => '349',
                    params  => [
                        $nick,
                        $chan,
                        'End of Channel Exception List',
                    ],
                };
                next;
            }
            if (!$nick_is_op && $nick_is_hop && $mode =~ /[op]/) {
                push @$ref, ['482', $chan] if !$notop;
                $notop++;
                next;
            }
            if (!$nick_is_op && $nick_is_hop && $record->{mode} =~ /p/
                    && $mode =~ /h/) {
                push @$ref, ['482', $chan] if !$notop;
                $notop++;
                next;
            }
            if (($mode =~ /^[-+][ohv]/ || $mode =~ /^\+[lk]/)
                    && !defined $arg) {
                next;
            }
            if ($mode =~ /^[-+][ohv]/ && !$self->state_nick_exists($arg)) {
                next if ++$mode_count > $maxmodes;
                push @$ref, ['401', $arg];
                next;
            }
            if ($mode =~ /^[-+][ohv]/
                    && !$self->state_is_chan_member($arg, $chan)) {
                next if ++$mode_count > $maxmodes;
                push @$ref, ['441', $chan, $self->state_user_nick($arg)];
                next;
            }
            if (my ($flag, $char) = $mode =~ /^([-+])([ohv])/ ) {
                next if ++$mode_count > $maxmodes;

                if ($flag eq '+'
                    && $record->{users}{uc_irc($arg)} !~ /$char/) {
                    # Update user and chan record
                    $arg = uc_irc($arg);
                    if ($mode eq '+h' && $record->{users}{$arg} =~ /o/) {
                        next;
                    }
                    if ($char eq 'h' && $record->{users}{$arg} =~ /v/) {
                        $record->{users}{$arg} =~ s/v//g;
                        $reply .= '-v';
                        push @reply_args, $self->state_user_nick($arg);
                    }
                    if ($char eq 'o' && $record->{users}{$arg} =~ /h/ ) {
                        $record->{users}{$arg} =~ s/h//g;
                        $reply .= '-h';
                        push @reply_args, $self->state_user_nick($arg);
                    }
                    $record->{users}{$arg} = join('', sort
                        split //, $record->{users}{$arg} . $char);
                    $self->{state}{users}{$arg}{chans}{uc_irc($chan)}
                        = $record->{users}{$arg};
                    $reply .= $mode;
                    push @reply_args, $self->state_user_nick($arg);
                }

                if ($flag eq '-' && $record->{users}{uc_irc($arg)}
                    =~ /$char/) {
                    # Update user and chan record
                    $arg = uc_irc($arg);
                    $record->{users}{$arg} =~ s/$char//g;
                    $self->{state}{users}{$arg}{chans}{uc_irc($chan)}
                        = $record->{users}{$arg};
                    $reply .= $mode;
                    push @reply_args, $self->state_user_nick($arg);
                }
                next;
            }
            if ($mode eq '+l' && $arg =~ /^\d+$/ && $arg > 0) {
            next if ++$mode_count > $maxmodes;
            $reply .= $mode;
            push @reply_args, $arg;
            if ($record->{mode} !~ /l/) {
                $record->{mode} = join('', sort
                    split //, $record->{mode} . 'l');
            }
            $record->{climit} = $arg;
            next;
        }
        if ($mode eq '-l' && $record->{mode} =~ /l/) {
            $record->{mode} =~ s/l//g;
            delete $record->{climit};
            $reply .= $mode;
            next;
        }
        if ($mode eq '+k' && $arg) {
            next if ++$mode_count > $maxmodes;
            $reply .= $mode;
            push @reply_args, $arg;
            if ($record->{mode} !~ /k/) {
                $record->{mode} = join('', sort
                    split //, $record->{mode} . 'k');
            }
            $record->{ckey} = $arg;
            next;
        }
        if ($mode eq '-k' && $record->{mode} =~ /k/) {
            $reply .= $mode;
            push @reply_args, '*';
            $record->{mode} =~ s/k//g;
            delete $record->{ckey};
            next;
        }
        # Bans
        if (my ($flag) = $mode =~ /([-+])b/) {
            next if ++$mode_count > $maxmodes;
            my $mask = normalize_mask($arg);
            my $umask = uc_irc $mask;
            if ($flag eq '+' && !$record->{bans}{$umask}) {
                $record->{bans}{$umask}
                    = [$mask, $self->state_user_full($nick), time];
                $reply .= $mode;
                push @reply_args, $mask;
            }
            if ($flag eq '-' && $record->{bans}{$umask}) {
                delete $record->{bans}{$umask};
                $reply .= $mode;
                push @reply_args, $mask;
            }
            next;
        }
        # Invex
        if (my ($flag) = $mode =~ /([-+])I/) {
            next if ++$mode_count > $maxmodes;
            my $mask = normalize_mask( $arg );
            my $umask = uc_irc $mask;

            if ($flag eq '+' && !$record->{invex}{$umask}) {
                $record->{invex}{$umask}
                    = [$mask, $self->state_user_full($nick), time];
                $reply .= $mode;
                push @reply_args, $mask;
            }
            if ($flag eq '-' && $record->{invex}{$umask}) {
                delete $record->{invex}{$umask};
                $reply .= $mode;
                push @reply_args, $mask;
            }
            next;
        }
        # Exceptions
        if (my ($flag) = $mode =~ /([-+])e/) {
            next if ++$mode_count > $maxmodes;
            my $mask = normalize_mask($arg);
            my $umask = uc_irc($mask);

                if ($flag eq '+' && !$record->{excepts}{$umask}) {
                    $record->{excepts}{$umask}
                        = [$mask, $self->state_user_full($nick), time];
                    $reply .= $mode;
                    push @reply_args, $mask;
                }
                if ($flag eq '-' && $record->{excepts}{$umask}) {
                    delete $record->{excepts}{$umask};
                    $reply .= $mode;
                    push @reply_args, $mask;
                }
                next;
            }
            # The rest should be argumentless.
            my ($flag, $char) = split //, $mode;
            if ($flag eq '+' && $record->{mode} !~ /$char/) {
                $reply .= $mode;
                $record->{mode} = join('', sort
                    split //, $record->{mode} . $char);
                next;
            }
            if ($flag eq '-' && $record->{mode} =~ /$char/) {
                $reply .= $mode;
                $record->{mode} =~ s/$char//g;
                next;
            }
        } # while

        if ($reply) {
            $reply = unparse_mode_line($reply);
            my $output = {
                prefix   => $self->state_user_full($nick),
                command  => 'MODE',
                params   => [$chan, $reply, @reply_args],
                colonify => 0,
            };
            $self->_send_output_to_channel($chan, $output);
        }
    } # SWITCH

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_join {
    my $self     = shift;
    my $nick     = shift || return;
    my $server   = $self->server_name();
    my $ref      = [ ];
    my $args     = [@_];
    my $count    = @$args;
    my $route_id = $self->_state_user_route($nick);
    my $unick    = uc_irc($nick);

    SWITCH: {
        my (@channels, @chankeys);
        if (!$count) {
            push @$ref, ['461', 'JOIN'];
            last SWITCH;
        }

        @channels = split /,/, $args->[0];
        @chankeys = split /,/, $args->[1] if $args->[1];
        my $channel_length = $self->server_config('CHANNELLEN');

        LOOP: for my $channel (@channels) {
            my $uchannel = uc_irc($channel);
            if ($channel eq '0'
                    and my @chans = $self->state_user_chans($nick)) {
                $self->_send_output_to_client(
                    $route_id,
                    (ref $_ eq 'ARRAY' ? @$_ : $_),
                ) for map { $self->_daemon_cmd_part($nick, $_) } @chans;
                next LOOP;
            }
            # Channel isn't valid
            if (!is_valid_chan_name($channel)
                    || length $channel > $channel_length) {
                $self->_send_output_to_client(
                    $route_id,
                    '403',
                    $channel,
                );
                next LOOP;
            }
            # Too many channels
            if ($self->state_user_chans($nick)
                >= $self->server_config('MAXCHANNELS')
                && !$self->state_user_is_operator($nick)) {
                $self->_send_output_to_client(
                    $route_id,
                    '405',
                    $channel,
                );
                next LOOP;
            }
            # Channel doesn't exist
            if (!$self->state_chan_exists($channel)) {
                my $record = {
                    name  => $channel,
                    ts    => time,
                    mode  => 'nt',
                    users => { $unick => 'o' },
                };
                $self->{state}{chans}{$uchannel} = $record;
                $self->{state}{users}{$unick}{chans}{$uchannel} = 'o';
                my @peers = $self->_state_connected_peers();
                $self->send_output(
                    {
                        command => 'SJOIN',
                        params  => [
                            $record->{ts},
                            $channel,
                            '+' . $record->{mode},
                            '@' . $nick,
                        ],
                    },
                    @peers,
                ) if $channel !~ /^&/;
                my $output = {
                    prefix  => $self->state_user_full($nick),
                    command => 'JOIN',
                    params  => [$channel],
                };
                $self->send_output($output, $route_id);
                $self->send_event(
                    "daemon_join",
                    $output->{prefix},
                    $channel,
                );
                $self->send_output(
                    {
                        prefix  => $server,
                        command => 'MODE',
                        params  => [$channel, '+' . $record->{mode}],
                    },
                    $route_id,
                );
                $self->_send_output_to_client(
                    $route_id,
                    (ref $_ eq 'ARRAY' ? @$_ : $_),
                ) for $self->_daemon_cmd_names($nick, $channel);
                $self->_send_output_to_client(
                    $route_id,
                    (ref $_ eq 'ARRAY' ? @$_ : $_ ),
                ) for $self->_daemon_cmd_topic($nick, $channel);
                next LOOP;
            }
            # Numpty user is already on channel
            if ($self->state_is_chan_member($nick, $channel)) {
                next LOOP;
            }
            my $chanrec = $self->{state}{chans}{$uchannel};
            my $bypass;
            if ($self->state_user_is_operator($nick)
                && $self->{config}{OPHACKS}) {
                $bypass = 1;
            }
            # Channel is full
            if (!$bypass && $chanrec->{mode} =~ /l/
                && keys %$chanrec >= $chanrec->{climit}) {
                $self->_send_output_to_client($route_id, '471', $channel);
                next LOOP;
            }
            my $chankey;
            $chankey = shift @chankeys if $chanrec->{mode} =~ /k/;
            # Channel +k and no key or invalid key provided
            if (!$bypass && $chanrec->{mode} =~ /k/
                && (!$chankey || $chankey ne $chanrec->{ckey})) {
                $self->_send_output_to_client($route_id, '475', $channel);
                next LOOP;
            }
            # Channel +i and not INVEX
            if (!$bypass && $chanrec->{mode} =~ /i/
                && !$self->_state_user_invited($nick, $channel)) {
                $self->_send_output_to_client($route_id, '473', $channel);
                next LOOP;
            }
            # Channel +b and no exception
            if (!$bypass && $self->_state_user_banned($nick, $channel)) {
                $self->_send_output_to_client($route_id, '474', $channel);
                next LOOP;
            }
            # JOIN the channel
            delete $self->{state}{users}{$unick}{invites}{$uchannel};
            # Add user
            $self->{state}{users}{$unick}{chans}{$uchannel} = '';
            $self->{state}{chans}{$uchannel}{users}{$unick} = '';
            # Send JOIN message to peers and local users.
            $self->send_output(
                {
                    prefix  => $server,
                    command => 'SJOIN',
                    params  => [$chanrec->{ts}, $channel, '+', $nick],
                },
                $self->_state_connected_peers(),
            ) if $channel !~ /^&/;

            my $output = {
                prefix  => $self->state_user_full($nick),
                command => 'JOIN',
                params  => [$channel],
            };
            $self->_send_output_to_client($route_id, $output);
            $self->_send_output_to_channel($channel, $output, $route_id);

            # Send NAMES and TOPIC to client
            $self->_send_output_to_client(
                $route_id,
                (ref $_ eq 'ARRAY' ? @$_ : $_),
            ) for $self->_daemon_cmd_names($nick, $channel);
            $self->_send_output_to_client(
                $route_id,
                (ref $_ eq 'ARRAY' ? @$_ : $_),
            ) for $self->_daemon_cmd_topic($nick, $channel);
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_part {
    my $self   = shift;
    my $nick   = shift || return;
    my $chan   = shift;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$chan) {
            push @$ref, ['461', 'PART'];
            last SWITCH;
        }
        if (!$self->state_chan_exists($chan)) {
            push @$ref, ['403', $chan];
            last SWITCH;
        }
        if (!$self->state_is_chan_member($nick, $chan)) {
            push @$ref, ['442', $chan];
            last SWITCH;
        }
        $self->_send_output_to_channel(
            $chan,
            {
                prefix  => $self->state_user_full($nick),
                command => 'PART',
                params  => [$chan, ($args->[0] || $nick)],
            },
        );
        $nick = uc_irc($nick);
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$nick};
        delete $self->{state}{users}{$nick}{chans}{$chan};
        if (! keys %{ $self->{state}{chans}{$chan}{users} }) {
            delete $self->{state}{chans}{$chan};
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_kick {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$count || $count < 2) {
            push @$ref, ['461', 'KICK'];
            last SWITCH;
        }
        my $chan = (split /,/, $args->[0])[0];
        my $who = (split /,/, $args->[1])[0];
        if (!$self->state_chan_exists($chan)) {
            push @$ref, ['403', $chan];
            last SWITCH;
        }
        $chan = $self->_state_chan_name($chan);
        if (!$self->state_nick_exists($who) ) {
            push @$ref, ['401', $who];
            last SWITCH;
        }
        $who = $self->state_user_nick($who);
        if (!$self->state_is_chan_op($nick, $chan)) {
            push @$ref, ['482', $chan];
            last SWITCH;
        }
        if (!$self->state_is_chan_member($who, $chan)) {
            push @$ref, ['441', $who, $chan];
            last SWITCH;
        }
        my $comment = $args->[2] || $who;
        $self->_send_output_to_channel(
            $chan,
            {
                prefix  => $self->state_user_full($nick),
                command => 'KICK',
                params  => [$chan, $who, $comment],
            },
        );
        $who = uc_irc($who);
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$who};
        delete $self->{state}{users}{$who}{chans}{$chan};
        if (!keys %{ $self->{state}{chans}{$chan}{users} }) {
            delete $self->{state}{chans}{$chan};
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_remove {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$count || $count < 2) {
            push @$ref, ['461', 'REMOVE'];
            last SWITCH;
        }
        my $chan = (split /,/, $args->[0])[0];
        my $who = (split /,/, $args->[1])[0];
        if (!$self->state_chan_exists($chan)) {
            push @$ref, ['403', $chan];
            last SWITCH;
        }
        $chan = $self->_state_chan_name($chan);
        if (!$self->state_nick_exists($who)) {
            push @$ref, ['401', $who];
            last SWITCH;
        }
        my $fullwho = $self->state_user_full($who);
        $who = (split /!/, $fullwho)[0];
        if (!$self->state_is_chan_op($nick, $chan)) {
            push @$ref, ['482', $chan];
            last SWITCH;
        }
        if (!$self->state_is_chan_member($who, $chan)) {
            push @$ref, ['441', $who, $chan];
            last SWITCH;
        }
        my $comment = "Requested by $nick";
        $comment .= qq{ "$args->[2]"} if $args->[2];
        $self->_send_output_to_channel(
            $chan,
            {
                prefix  => $fullwho,
                command => 'PART',
                params  => [$chan, $comment],
            },
        );
        $who = uc_irc($who);
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$who};
        delete $self->{state}{users}{$who}{chans}{$chan};
        if (! keys %{ $self->{state}{chans}{$chan}{users} }) {
            delete $self->{state}{chans}{$chan};
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_invite {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$count || $count < 2) {
            push @$ref, ['461', 'INVITE'];
            last SWITCH;
        }
        my ($who, $chan) = @$args;
        if (!$self->state_nick_exists($who)) {
            push @$ref, ['401', $who];
            last SWITCH;
        }
        $who = $self->state_user_nick($who);
        if (!$self->state_chan_exists($chan)) {
            push @$ref, ['403', $chan];
            last SWITCH;
        }
        $chan = $self->_state_chan_name($chan);
        if (!$self->state_is_chan_member($nick, $chan)) {
            push @$ref, ['442', $chan];
            last SWITCH;
        }
        if ($self->state_is_chan_member($who, $chan)) {
            push @$ref, ['443', $who, $chan];
            last SWITCH;
        }
        if ($self->state_chan_mode_set($chan, 'i')
                && !$self->state_is_chan_op($nick, $chan)) {
            push @$ref, ['482', $chan];
            last SWITCH;
        }
        my $local;
        if ($self->_state_is_local_user($who)) {
            my $record = $self->{state}{users}{uc_irc($who)};
            $record->{invites}{uc_irc($chan)} = time;
            $local = 1;
        }
        my $away = $self->_state_user_away_msg($who);
        my $route_id = $self->_state_user_route($who);
        my $output = {
            prefix   => $self->state_user_full($nick),
            command  => 'INVITE',
            params   => [$who, $chan],
            colonify => 0,
        };
        if ($route_id eq 'spoofed') {
            $self->send_event(
                "daemon_invite",
                $output->{prefix},
                @{ $output->{params} }
            );
        }
        else {
            if (!$local) {
                $output->{prefix} = $nick;
                push @{ $output->{params} }, time;
            }
            $self->send_output($output, $route_id);
        }
        push @$ref, {
            prefix  => $server,
            command => '341',
            params  => [$chan, $who],
        };
        if (defined $away) {
            push @$ref, {
                prefix  => $server,
                command => '301',
                params  => [$nick, $who, $away],
            };
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_umode {
    my $self   = shift;
    my $nick   = shift || return;
    my $umode  = shift;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $record = $self->{state}{users}{uc_irc($nick)};

    if (!$umode) {
        push @$ref, {
            prefix  => $server,
            command => '221',
            params  => [$nick, '+' . $record->{umode}],
        };
    }
    else {
        my $peer_ignore;
        my $parsed_mode = parse_mode_line($umode);
        my $route_id = $self->_state_user_route($nick);
        my $previous = $record->{umode};

        while (my $mode = shift @{ $parsed_mode->{modes} }) {
            next if $mode eq '+o';
            my ($action, $char) = split //, $mode;
            if ($action eq '+' && $record->{umode} !~ /$char/) {
                next if $char =~ /[wzl]a/ && $record->{umode} !~ /o/;
                $record->{umode} .= $char;
                if ($char eq 'i') {
                    $self->{state}{stats}{invisible}++;
                    $peer_ignore = delete $record->{_ignore_i_umode};
                }
                if ($char eq 'w') {
                    $self->{state}{wallops}{$route_id} = time;
                }
                if ($char eq 'z') {
                    $self->{state}{operwall}{$route_id} = time;
                }
                if ($char eq 'l') {
                    $self->{state}{locops}{$route_id} = time;
                }
            }
            if ($action eq '-' && $record->{umode} =~ /$char/) {
                $record->{umode} =~ s/$char//g;
                $self->{state}{stats}{invisible}-- if $char eq 'i';

                if ($char eq 'o') {
                    $self->{state}{stats}{ops_online}--;
                    delete $self->{state}{localops}{$route_id};
                    $self->antiflood( $route_id, 1);
                }
                if ($char eq 'w') {
                    delete $self->{state}{wallops}{$route_id};
                }
                if ($char eq 'z') {
                    delete $self->{state}{operwall}{$route_id};
                }
                if ($char eq 'l') {
                    delete $self->{state}{locops}{$route_id};
                }
            }
        }

        $record->{umode} = join '', sort split //, $record->{umode};
        my $peerprev = $previous;
        my $peerumode = $record->{umode};
        $peerprev =~ s/[^aiow]//g;
        $peerumode =~ s/[^aiow]//g;
        my $pset = gen_mode_change($peerprev, $peerumode);
        my $set = gen_mode_change($previous, $record->{umode});
        if ($pset && !$peer_ignore ) {
            my $hashref = {
                prefix  => $nick,
                command => 'MODE',
                params  => [$nick, $pset],
            };
            $self->send_output(
                $hashref,
                $self->_state_connected_peers(),
            );
        }
        if ($set) {
            my $hashref = {
                prefix  => $nick,
                command => 'MODE',
                params  => [$nick, $set],
            };
            $self->send_event(
                "daemon_umode",
                $self->state_user_full($nick),
                $set
            ) if !$peer_ignore;
            push @$ref, $hashref;
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_topic {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH:{
        if (!$count) {
            push @$ref, ['461', 'TOPIC'];
            last SWITCH;
        }
        if (!$self->state_chan_exists($args->[0])) {
            push @$ref, ['403', $args->[0]];
            last SWITCH;
        }
        if ($self->state_chan_mode_set($args->[0], 's')
            && !$self->state_is_chan_member($nick, $args->[0])) {
            push @$ref, ['442', $args->[0]];
            last SWITCH;
        }
        my $chan_name = $self->_state_chan_name($args->[0]);
        if ($count == 1
                and my $topic = $self->state_chan_topic($args->[0])) {
            push @$ref, {
                prefix  => $server,
                command => '332',
                params  => [$nick, $chan_name, $topic->[0]],
            };
            push @$ref, {
                prefix  => $server,
                command => '333',
                params  => [$nick, $chan_name, @{ $topic }[1..2]],
            };
            last SWITCH;
        }
        if ($count == 1) {
            push @$ref, {
                prefix  => $server,
                command => '331',
                params  => [$nick, $chan_name, 'No topic is set'],
            };
            last SWITCH;
        }
        if (!$self->state_is_chan_member($nick, $args->[0])) {
            push @$ref, ['442', $args->[0]];
            last SWITCH;
        }
        if ($self->state_chan_mode_set($args->[0], 't')
        && !$self->state_is_chan_op($nick, $args->[0])) {
            push @$ref, ['482', $args->[0]];
            last SWITCH;
        }
        my $record = $self->{state}{chans}{uc_irc($args->[0])};
        my $topic_length = $self->server_config('TOPICLEN');
        if (length $args->[0] > $topic_length) {
            $args->[1] = substr $args->[0], 0, $topic_length;
        }
        if ($args->[1] eq '') {
            delete $record->{topic};
        }
        else {
            $record->{topic} = [
                $args->[1],
                $self->state_user_full($nick),
                time,
            ];
        }
        $self->_send_output_to_channel(
            $args->[0],
            {
                prefix  => $self->state_user_full($nick),
                command => 'TOPIC',
                params  => [$chan_name, $args->[1]],
            },
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_links {
    my $self   = shift;
    my $nick   = shift || return;
    my $target = shift;
    my $server = $self->server_name();
    my $ref    = [ ];

    SWITCH:{
        if ($target && !$self->state_peer_exists($target)) {
            push @$ref, ['402', $target];
            last SWITCH;
        }
        if ($target && uc $server ne uc $target) {
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'LINKS',
                    params  => [$self->_state_peer_name($target)],
                },
                $self->_state_peer_route($target)
            );
            last SWITCH;
        }

        for ($self->_state_server_links($server, $server, $nick)) {
            push @$ref, $_;
        }
        push @$ref, {
            prefix  => $server,
            command => '364',
            params  => [
                $nick,
                $server,
                $server,
                join( ' ', '0', $self->server_config('serverdesc'))
            ],
        };
        push @$ref, {
            prefix  => $server,
            command => '365',
            params  => [$nick, '*', 'End of /LINKS list.'],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_squit {
    my $self    = shift;
    my $peer_id = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    return if !$self->state_peer_exists($args->[0]);

    SWITCH: {
        if ($peer_id ne $self->_state_peer_route($args->[0])) {
            $self->send_output(
                {
                    command => 'SQUIT',
                    params  => $args,
                },
                $self->_state_peer_route($args->[0]),
            );
            last SWITCH;
        }
        if ($peer_id eq $self->_state_peer_route($args->[0])) {
            $self->send_output(
                {
                    command => 'SQUIT',
                    params  => $args,
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            $self->send_event("daemon_squit", @$args);
            my $quit_msg = join ' ',
                $self->_state_peer_for_peer($args->[0]), $args->[0];

            for my $nick ($self->_state_server_squit($args->[0])) {
                my $output = {
                    prefix  => $self->state_user_full($nick),
                    command => 'QUIT',
                    params  => [$quit_msg],
                };
                my $common = { };
                for my $uchan ($self->state_user_chans($nick)) {
                    $uchan = uc_irc($uchan);
                    delete $self->{state}{chans}{$uchan}{users}{$nick};
                    for my $user ($self->state_chan_list($uchan)) {
                        next if !$self->_state_is_local_user($user);
                        $common->{$user} = $self->_state_user_route($user);
                    }
                    if (!keys %{ $self->{state}{chans}{$uchan}{users} }) {
                        delete $self->{state}{chans}{$uchan};
                    }
                }
                $self->send_output($output, values %$common);
                $self->send_event(
                    "daemon_quit",
                    $output->{prefix},
                    $output->{params}[0],
                );
                my $record = delete $self->{state}{users}{$nick};
                if ($record->{umode} =~ /o/) {
                    $self->{state}{stats}{ops_online}--;
                }
                if ($record->{umode} =~ /i/) {
                    $self->{state}{stats}{invisible}--;
                }
            }
            last SWITCH;
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_rkline {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    # :klanker RKLINE logserv.gumbynet.org.uk 600 ^m.*\ foo\.(com|uk|net)$ :Foo

    SWITCH: {
        if (!$count || $count < 5) {
            last SWITCH;
        }
        my $full = $self->state_user_full($nick);
        my $target = $args->[0];
        my $us = 0;
        my $ucserver = uc $server;
        my %targets;
        for my $peer (keys %{ $self->{state}{peers} }) {
            if (matches_mask( $target, $peer)) {
                if ($ucserver eq $peer) {
                    $us = 1;
                }
                else {
                    $targets{$self->_state_peer_route($peer)}++;
                }
            }
        }

        delete $targets{$peer_id};
        $self->send_output(
            {
                prefix   => $nick,
                command  => 'RKLINE',
                params   => $args,
                colonify => 0,
            },
            grep { $self->_state_peer_capab($_, 'KLN') } keys %targets,
        );

        if ($us) {
            $self->send_event("daemon_rkline", $full, @$args);
            push @{ $self->{state}{rklines} }, {
                setby    => $full,
                setat    => time,
                target   => $args->[0],
                duration => $args->[1],
                user     => $args->[2],
                host     => $args->[3],
                reason   => $args->[4],
            };
            $self->_terminate_conn_error($_, 'K-Lined')
                for $self->_state_local_users_match_rkline($args->[2], $args->[3]);
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_kline {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count || $count < 5) {
            last SWITCH;
        }
        my $full = $self->state_user_full($nick);
        my $target = $args->[0];
        my $us = 0;
        my $ucserver = uc $server;
        my %targets;

        for my $peer (keys %{ $self->{state}{peers} }) {
            if (matches_mask($target, $peer)) {
                if ($ucserver eq $peer) {
                    $us = 1;
                }
                else {
                    $targets{$self->_state_peer_route($peer)}++;
                }
            }
        }
        delete $targets{$peer_id};
        $self->send_output(
            {
                prefix   => $nick,
                command  => 'KLINE',
                params   => $args,
                colonify => 0,
            },
            grep { $self->_state_peer_capab($_, 'KLN') } keys %targets,
        );
        if ($us) {
            $self->send_event("daemon_kline", $full, @$args);
            push @{ $self->{state}{klines} }, {
                setby    => $full,
                setat    => time(),
                target   => $args->[0],
                duration => $args->[1],
                user     => $args->[2],
                host     => $args->[3],
                reason   => $args->[4],
            };
            $self->_terminate_conn_error($_, 'K-Lined')
                for $self->_state_local_users_match_gline($args->[2], $args->[3]);
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_unkline {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    # :klanker UNKLINE logserv.gumbynet.org.uk * moos.loud.me.uk
    SWITCH: {
        if (!$count || $count < 3) {
            last SWITCH;
        }
        my $full = $self->state_user_full($nick);
        my $target = $args->[0];
        my $us = 0;
        my $ucserver = uc $server;
        my %targets;

        for my $peer (keys %{ $self->{state}{peers} }) {
            if (matches_mask($target, $peer)) {
                if ($ucserver eq $peer) {
                    $us = 1;
                }
                else {
                    $targets{$self->_state_peer_route($peer)}++;
                }
            }
        }
        delete $targets{$peer_id};
        $self->send_output(
            {
                prefix   => $nick,
                command  => 'UNKLINE',
                params   => $args,
                colonify => 0,
            },
            grep { $self->_state_peer_capab($_, 'UNKLN') } keys %targets,
        );

        if ($us) {
            $self->send_event("daemon_unkline", $full, @$args);
            my $i = 0;
            for (@{ $self->{state}{klines} }) {
                if ($_->{user} eq $args->[1] && $_->{host} eq $args->[2]) {
                    splice (@{ $self->{state}{klines} }, $i, 1);
                    last;
                }
                ++$i;
            }
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_gline {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    # :klanker GLINE * meep.com :Fuckers
    SWITCH: {
        if (!$count || $count < 3) {
            last SWITCH;
        }
        my $full = $self->state_user_full($nick);
        push @{ $self->{state}{glines} }, {
            setby  => $full,
            setat  => time,
            user   => $args->[0],
            host   => $args->[1],
            reason => $args->[2],
        };
        $self->send_output(
            {
                prefix  => $nick,
                command => 'GLINE',
                params  => $args,
                colonify => 0,
            },
            grep { $_ ne $peer_id && $self->_state_peer_capab($_, 'GLN') }
                $self->_state_connected_peers(),
        );
        $self->send_event("daemon_gline", $full, @$args);
        $self->_terminate_conn_error($_, 'G-Lined')
            for $self->_state_local_users_match_gline($args->[0], $args->[1]);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_wallops {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        my $full = $self->state_user_full($prefix) || $prefix;
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        if ($self->state_peer_exists($full)) {
            $self->send_output(
                {
                    prefix  => $full,
                    command => 'WALLOPS',
                    params  => ['OPERWALL - ' . $args->[0]],
                }, keys %{ $self->{state}{wallops} },
            );
            $self->send_event("daemon_wallops", $full, $args->[0]);
        }
        else {
            $self->send_output(
                {
                    prefix  => $full,
                    command => 'WALLOPS',
                    params  => ['OPERWALL - ' . $args->[0]],
                },
                keys %{ $self->{state}{operwall} },
            );
            $self->send_event("daemon_operwall", $full, $args->[0]);
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_operwall {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        my $full = $self->state_user_full($prefix) || $prefix;
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        if ($self->state_peer_exists($full)) {
            $self->send_output(
                {
                    prefix  => $full,
                    command => 'WALLOPS',
                    params  => ['OPERWALL - ' . $args->[0]],
                },
                keys %{ $self->{state}{wallops} },
            );
            $self->send_event("daemon_wallops", $full, $args->[0]);
        }
        else {
            $self->send_output(
                {
                    prefix  => $full,
                    command => 'WALLOPS',
                    params  => ['OPERWALL - ' . $args->[0]],
                },
                keys %{ $self->{state}{operwall} },
            );
            $self->send_event("daemon_operwall", $full, $args->[0]);
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_eob {
    my $self    = shift;
    my $peer_id = shift || return;
    my $peer    = shift || return;
    my $ref     = [ ];
    $self->send_event("daemon_eob", $peer);
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_kill {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if ($self->state_peer_exists($args->[0])) {
            last SWITCH;
        }
        if (!$self->state_nick_exists($args->[0])) {
            last SWITCH;
        }

        my $target = $self->state_user_nick($args->[0]);
        my $comment = $args->[1];
        if ($self->_state_is_local_user($target)) {
            my $route_id = $self->_state_user_route($target);
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'KILL',
                    params  => [
                        $target,
                        join('!', $server, $comment),
                    ],
                }, grep { $_ ne $peer_id } $self->_state_connected_peers()
            );

            $self->send_output(
                {
                    prefix  => $self->state_user_full($nick),
                    command => 'KILL',
                    params  => [
                        $target,
                        join('!', $server, $comment),
                    ],
                },
                $route_id,
            );

            if ($route_id eq 'spoofed') {
                $self->call(
                    'del_spoofed_nick',
                    $target,
                    "Killed ($comment)",
                );
            }
            else {
                $self->{state}{conns}{$route_id}{killed} = 1;
                $self->_terminate_conn_error(
                    $route_id,
                    "Killed ($comment)",
                );
            }
        }
        else {
            $self->{state}{users}{uc_irc($target)}{killed} = 1;
            $self->send_output(
                {
                    prefix  => $nick,
                    command => 'KILL',
                    params  => [$target, join('!', $server, $comment)],
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            $self->send_output(
                @{ $self->_daemon_peer_quit(
                    $target, "Killed ($nick ($comment))" ) },
            );
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_svinfo {
    my $self    = shift;
    my $peer_id = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    $self->{state}{conns}{$peer_id}{svinfo} = $args;
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_ping {
    my $self = shift;
    my $peer_id = shift || return;
    my $server = $self->server_name();
    my $ref = [ ];
    my $args = [ @_ ];
    my $count = @$args;

    SWITCH: {
        if (!$count) {
            last SWITCH;
        }
        if ($count >= 2 && uc $server ne uc $args->[1]) {
            $self->send_output(
                {
                    command => 'PING',
                    params  => $args,
                },
                $self->_state_peer_route($args->[1]),
            ) if $self->state_peer_exists($args->[1]);
            $self->send_output(
                {
                    command => 'PING',
                    params  => $args,
                },
                $self->_state_user_route($args->[1]),
            ) if $self->state_nick_exists($args->[1]);
            last SWITCH;
        }
        $self->send_output(
            {
                command => 'PONG',
                params  => [$server, $args->[0]],
            },
            $peer_id,
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_pong {
    my $self    = shift;
    my $peer_id = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count) {
            last SWITCH;
        }
        if ($count >= 2 && uc $self->server_name() ne uc $args->[1]) {
            $self->send_output(
                {
                    command => 'PONG',
                    params => $args,
                },
                $self->_state_peer_route($args->[1]),
            ) if $self->state_peer_exists($args->[1]);
            $self->send_output(
                {
                    command => 'PONG',
                    params => $args,
                },
                $self->_state_user_route($args->[1]),
            ) if $self->state_nick_exists($args->[1]);
            last SWITCH;
        }
        delete $self->{state}{conns}{$peer_id}{pinged};
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_server {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    my $peer    = $self->{state}{conns}{$peer_id}{name};

    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        if ($self->state_peer_exists($args->[0])) {
            $self->_terminate_conn_error($peer_id, 'Server exists');
            last SWITCH;
        }
        my $record = {
            name => $args->[0],
            hops => $args->[1],
            desc => ( $args->[2] || '' ),
            route_id => $peer_id,
            type => 'r',
            peer => $prefix,
            peers => { },
            users => { },
        };
        my $uname = uc $record->{name};
        $self->{state}{peers}{$uname} = $record;
        $self->{state}{peers}{uc $prefix}{peers}{$uname} = $record;
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'SERVER',
                params  => [
                    $record->{name},
                    $record->{hops} + 1,
                    $record->{desc},
                ],
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        $self->send_event(
            "daemon_server",
            $record->{name},
            $prefix,
            $record->{hops},
            $record->{desc},
        );
    }
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_quit {
    my $self    = shift;
    my $nick    = shift || return;
    my $qmsg    = shift || 'Client Quit';
    my $conn_id = shift;
    my $ref     = [ ];
    my $full    = $self->state_user_full($nick);

    $nick = uc_irc($nick);
    my $record = delete $self->{state}{users}{$nick};
    return $ref if !$record;
    $self->send_output(
        {
            prefix  => $record->{nick},
            command => 'QUIT',
            params  => [$qmsg],
        },
        grep { !$conn_id || $_ ne $conn_id }
            $self->_state_connected_peers(),
    ) if !$record->{killed};

    push @$ref, {
        prefix  => $full,
        command => 'QUIT',
        params  => [$qmsg],
    };

    $self->send_event("daemon_quit", $full, $qmsg);

    # Remove for peoples accept lists
    delete $self->{state}{users}{$_}{accepts}{uc_irc($nick)}
        for keys %{ $record->{accepts} };

    # Okay, all 'local' users who share a common channel with user.
    my $common = { };
    for my $uchan (keys %{ $record->{chans} }) {
        delete $self->{state}{chans}{$uchan}{users}{$nick};
        for my $user ($self->state_chan_list($uchan)) {
            next if !$self->_state_is_local_user($user);
            $common->{$user} = $self->_state_user_route($user);
        }
        if (!keys %{ $self->{state}{chans}{$uchan}{users} }) {
            delete $self->{state}{chans}{$uchan};
        }
     }

    push @$ref, $common->{$_} for keys %$common;
    $self->{state}{stats}{ops_online}-- if $record->{umode} =~ /o/;
    $self->{state}{stats}{invisible}-- if $record->{umode} =~ /i/;
    delete $self->{state}{peers}{uc $record->{server}}{users}{$nick};

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_nick {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    my $peer    = $self->{state}{conns}{$peer_id}{name};
    my $nicklen = $self->server_config('NICKLEN');

    SWITCH: {
        if (!$count || $count < 8 && !$prefix) {
            $self->_terminate_conn_error(
                $peer_id,
                'Not enough arguments to server command.',
            );
            last SWITCH;
        }
        if ($prefix && $self->state_nick_exists($args->[0])) {
            $self->send_output(
                {
                    prefix  => $server,
                    command => 'KILL',
                    params  => [$args->[0], "$server (Nick exists)"],
                },
                $peer_id,
            );
            my $unick = uc_irc($prefix);
            $self->{state}{users}{$unick}{nick_collision} = 1;
            $self->daemon_server_kill($prefix, 'Nick Collision', $peer_id);
            last SWITCH;
        }
        if ($prefix && length($args->[0]) > $nicklen) {
            $self->send_output(
                {
                    prefix  => $server,
                    command => 'KILL',
                    params  => [$args->[0], "$server (Bad nickname)"],
                },
                $peer_id,
            );
            my $unick = uc_irc($prefix);
            $self->{state}{users}{$unick}{nick_collision} = 1;
            $self->daemon_server_kill($prefix, 'Nick Collision', $peer_id);
            last SWITCH;
        }
        if ($prefix) {
            my $full = $self->state_user_full($prefix);
            my $unick = uc_irc($prefix);
            my $new = $args->[0];
            my $unew = uc_irc($new);
            my $ts = $args->[1] || time;
            my $record = $self->{state}{users}{$unick};
            my $server = uc $record->{server};

            if ($unick eq $unew) {
                $record->{nick} = $new;
                $record->{ts} = $ts;
            }
            else {
                $record->{nick} = $new;
                $record->{ts} = $ts;
                # Remove from peoples accept lists
                delete $self->{state}{users}{$_}{accepts}{$unick}
                    for keys %{ $record->{accepts} };
                delete $record->{accepts};
                delete $self->{state}{users}{$unick};
                $self->{state}{users}{$unew} = $record;
                delete $self->{state}{peers}{$server}{users}{$unick};
                $self->{state}{peers}{$server}{users}{$unew} = $record;

                for my $chan (keys %{ $record->{chans} }) {
                    $self->{state}{chans}{$chan}{users}{$unew}
                      = delete $self->{state}{chans}{$chan}{users}{$unick};
                }
            }
            my $common = { };
            for my $chan (keys %{ $record->{chans} }) {
                for my $user ($self->state_chan_list($chan)) {
                    next if !$self->_state_is_local_user($user);
                    $common->{$user} = $self->_state_user_route($user);
                }
            }
            $self->send_output(
                {
                    prefix  => $prefix,
                    command => 'NICK',
                    params  => $args,
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            $self->send_output(
                {
                    prefix  => $full,
                    command => 'NICK',
                    params  => [$new],
                },
                map{ $common->{$_} } keys %{ $common },
            );
            $self->send_event("daemon_nick", $full, $new);
            last SWITCH;
        }
        if ($self->state_nick_exists($args->[0])
                and my ($nick, $userhost) = split /!/,
                $self->state_user_full($args->[0])) {
            my $unick = uc_irc $nick;
            my $incoming = join '@', @{ $args }[4..5];
            if ($userhost eq $incoming) {
                my $ts = $self->{state}{users}{$unick}{ts};
                if ($args->[2] > $ts) {
                    $self->{state}{users}{$unick}{nick_collision} = 1;
                    $self->daemon_server_kill(
                        $nick,
                        'Nick Collision',
                        $peer_id,
                    );
                }
                else {
                    last SWITCH;
                }
            }
            else {
                my $ts = $self->{state}{users}{$unick}{ts};
                if ($args->[2] < $ts) {
                    $self->{state}{users}{$unick}{nick_collision} = 1;
                    $self->daemon_server_kill(
                        $nick,
                        'Nick Collision',
                        $peer_id,
                    );
                }
                else {
                    last SWITCH;
                }
            }
        }
        if (!$self->state_peer_exists($args->[6])) {
            last SWITCH;
        }
        if (length( $args->[0] ) > $nicklen) {
            $self->send_output(
                {
                    prefix  => $server,
                    command => 'KILL',
                    params  => [$args->[0], "$server (Bad nickname)"],
                },
                $peer_id,
            );
            last SWITCH;
        }
        my $unick = uc_irc($args->[0]);
        $args->[3] =~ s/^\+//g;
        my $record = {
            nick  => $args->[0],
            hops  => $args->[1],
            ts    => $args->[2],
            type  => 'r',
            umode => $args->[3],
            auth  => {
                ident => $args->[4],
                hostname => $args->[5],
            },
            route_id => $peer_id,
            server => $args->[6],
            ircname => ( $args->[7] || '' ),
        };
        $self->{state}{users}{ $unick } = $record;
        $self->{state}{stats}{ops_online}++ if $record->{umode} =~ /o/;
        $self->{state}{stats}{invisible}++ if $record->{umode} =~ /i/;
        $self->{state}{peers}{uc $record->{server}}{users}{$unick}
            = $record;
        $self->_state_update_stats();
         $self->send_output(
             {
                 command => 'NICK',
                 params  => $args,
             },
             grep { $_ ne $peer_id } $self->_state_connected_peers(),
         );
        $self->send_event("daemon_nick", @$args);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_part {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $chan    = shift;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$chan) {
            last SWITCH;
        }
        if (!$self->state_chan_exists($chan)) {
            last SWITCH;
        }
        if (!$self->state_is_chan_member($nick, $chan)) {
            last SWITCH;
        }
        $self->_send_output_to_channel(
            $chan, {
                prefix  => $self->state_user_full($nick),
                command => 'PART',
                params  => [$chan, ($args->[0] || $nick)],
            },
            $peer_id,
        );
        $nick = uc_irc($nick);
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$nick};
        delete $self->{state}{users}{$nick}{chans}{$chan};
        if (!keys %{ $self->{state}{chans}{$chan}{users} }) {
            delete $self->{state}{chans}{$chan};
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_kick {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my $chan = (split /,/, $args->[0])[0];
        my $who = (split /,/, $args->[1])[0];
        if (!$self->state_chan_exists($chan)) {
            last SWITCH;
        }
        $chan = $self->_state_chan_name($chan);
        if ( !$self->state_nick_exists($who)) {
            last SWITCH;
        }
        $who = $self->state_user_nick($who);
        if (!$self->state_is_chan_op($nick, $chan)) {
            last SWITCH;
        }
        if (!$self->state_is_chan_member($who, $chan)) {
            last SWITCH;
        }
        my $comment = $args->[2] || $who;
        $self->_send_output_to_channel(
            $chan, {
                prefix  => $self->state_user_full($nick),
                command => 'KICK',
                params  => [$chan, $who, $comment],
            },
            $peer_id,
        );
        $who = uc_irc($who);
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$who};
        delete $self->{state}{users}{$who}{chans}{$chan};
        if (! keys %{ $self->{state}{chans}{$chan}{users} }) {
            delete $self->{state}{chans}{$chan};
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_sjoin {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    #my $peer = $self->{state}{conns}{$peer_id}{name};

    SWITCH: {
        if (!$count || $count < 4) {
            last SWITCH;
        }
        my $ts = $args->[0];
        my $chan = $args->[1];
        my $nicks = pop @{ $args };
        my $ignore_modes = 0;
        if (!$self->state_chan_exists($chan)) {
            my $server = $self->server_name();
            my $chanrec = { name => $chan, ts => $ts };
            my @args = @{ $args }[2..$#{ $args }];
            my $cmode = shift @args;
            $cmode =~ s/^\+//g;
            $chanrec->{mode} = $cmode;
            for my $mode (split //, $cmode) {
                my $arg;
                $arg = shift @args if $mode =~ /[lk]/;
                $chanrec->{climit} = $arg if $mode eq 'l';
                $chanrec->{ckey} = $arg if $mode eq 'k';
            }
            push @$args, $nicks;
            my $uchan = uc_irc($chanrec->{name});
            for my $nick (split /\s+/, $nicks) {
                my $umode = '';
                $umode .= 'o' if $nick =~ s/\@//g;
                $umode = 'h' if $nick =~ s/\%//g;
                $umode .= 'v' if $nick =~ s/\+//g;
                my $unick = uc_irc($nick);
                $chanrec->{users}{$unick} = $umode;
                $self->{state}{users}{$unick}{chans}{$uchan} = $umode;

                $self->send_event(
                    "daemon_join",
                    $self->state_user_full($nick),
                    $chan,
                );
                $self->send_event(
                    "daemon_mode",
                    $server,
                    $chan,
                    '+' . $umode,
                    $nick,
                ) if $umode;
            }
            $self->{state}{chans}{$uchan} = $chanrec;
            $self->send_output(
                {
                    prefix  => $prefix,
                    command => 'SJOIN',
                    params  => $args,
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            last SWITCH;
        }
        my $chanrec = $self->{state}{chans}{uc_irc($chan)};
        my @local_users = map { $self->_state_user_route($_) }
            grep { $self->_state_is_local_user($_) }
            keys %{ $chanrec->{users} };

        if ($ts < $chanrec->{ts}) {
            # Incoming is older
            if ($nicks =~ /^\@/) {
                # Remove all modes expect bans/invex/excepts
                # deop/dehalfop/devoice all existing users
                my @deop;
                my @deop_list;
                my $common = { };

                for my $user (keys %{ $chanrec->{users} }) {
                    $common->{$user} = $self->_state_user_route($user)
                        if $self->_state_is_local_user($user);
                    next if !$chanrec->{users}{$user};
                    my $current = $chanrec->{users}{$user};
                    my $proper = $self->state_user_nick($user);
                    $chanrec->{users}{$user} = '';
                    $self->{state}{users}{$user}{chans}{uc_irc($chanrec->{name})} = '';
                    push @deop, "-$current";
                    push @deop_list, $proper for split //, $current;
                }

                if (keys %$common && @deop) {
                    my $server = $self->server_name();
                    $self->send_event(
                        "daemon_mode",
                        $server,
                        $chanrec->{name},
                        unparse_mode_line(join '', @deop),
                        @deop_list,
                    );
                    my @output_modes;
                    my $length = length($server) + 4
                                + length($chan) + 4;
                    my @buffer = ('', '');
                    for my $deop (@deop) {
                        my $arg = shift @deop_list;
                        my $mode_line = unparse_mode_line($buffer[0].$deop);
                        if (length(join ' ', $mode_line, $buffer[1],
                                $arg) + $length > 510) {
                            push @output_modes, {
                                prefix   => $server,
                                command  => 'MODE',
                                colonify => 0,
                                params   => [
                                    $chanrec->{name},
                                    $buffer[0],
                                    split /\s+/,
                                    $buffer[1],
                                ],
                            };
                            $buffer[0] = $deop;
                            $buffer[1] = $arg;
                            next;
                        }
                        $buffer[0] = $mode_line;
                        if ($buffer[1]) {
                            $buffer[1] = join ' ', $buffer[1], $arg;
                        }
                        else {
                            $buffer[1] = $arg;
                        }
                    }
                    push @output_modes, {
                        prefix   => $server,
                        command  => 'MODE',
                        colonify => 0,
                        params   => [
                            $chanrec->{name},
                            $buffer[0],
                            split /\s+/, $buffer[1],
                        ],
                    };
                    $self->send_output($_, values %$common)
                        for @output_modes;
                }
                my $origmode = $chanrec->{mode};
                my @args = @{ $args }[2..$#{ $args }];
                my $chanmode = shift @args;
                my $reply = '';
                my @reply_args;

                for my $mode (grep { $_ ne '+' } split //, $chanmode) {
                    my $arg;
                    $arg = shift @args if $mode =~ /[lk]/;
                    if ($mode eq 'l' && ($chanrec->{mode} !~ /l/
                            || $arg ne $chanrec->{climit})) {
                        $reply .= '+' . $mode;
                        push @reply_args, $arg;
                        if ($chanrec->{mode} !~ /$mode/) {
                            $chanrec->{mode} .= $mode;
                        }
                        $chanrec->{mode} = join '', sort split //,
                        $chanrec->{mode};
                        $chanrec->{climit} = $arg;
                    }
                    elsif ($mode eq 'k' && ($chanrec->{mode} !~ /k/
                        || $arg ne $chanrec->{ckey})) {
                        $reply .= '+' . $mode;
                        push @reply_args, $arg;
                        if ($chanrec->{mode} !~ /$mode/) {
                            $chanrec->{mode} .= $mode;
                        }
                        $chanrec->{mode} = join '', sort split //,
                            $chanrec->{mode};
                        $chanrec->{ckey} = $arg;
                    }
                    elsif ($chanrec->{mode} !~ /$mode/) {
                        $reply .= '+' . $mode;
                        $chanrec->{mode} = join '', sort split //,
                            $chanrec->{mode};
                    }
                }

                if (keys %$common && ($reply || $origmode)) {
                    $origmode = join '', grep { $chanmode !~ /$_/ }
                        split //, ($origmode || '');
                    $chanrec->{mode} =~ s/[$origmode]//g if $origmode;
                    $reply = '-' . $origmode . $reply if $origmode;
                    if ($origmode && $origmode =~ /k/) {
                        unshift @reply_args, '*';
                        delete $chanrec->{ckey};
                    }
                    if ($origmode and $origmode =~ /l/) {
                        delete $chanrec->{climit};
                    }
                    $self->send_output(
                        {
                            prefix   => $self->server_name(),
                            command  => 'MODE',
                            colonify => 0,
                            params   => [
                                $chanrec->{name},
                                unparse_mode_line($reply),
                                @reply_args,
                            ],
                        },
                        values %$common,
                        ) if $reply;
                    }
                    # NOTICE HERE
                    $self->send_output(
                    {
                        prefix  => $self->server_name(),
                        command => 'NOTICE',
                        params  => [
                            $chanrec->{name},
                            "*** Notice -- TS for " . $chanrec->{name}
                                . " changed from " . $chanrec->{ts}
                                . " to $ts",
                        ],
                    },
                    @local_users,
                );
                $chanrec->{ts} = $ts;
            }
            elsif (grep { /^\@/ } $self->state_chan_list_prefixed($chan)) {
                $args->[0] = $chanrec->{ts};
            }
            else {
                # NOTICE HERE
                $self->send_output(
                    {
                        prefix  => $self->server_name(),
                        command => 'NOTICE',
                        params  => [
                            $chanrec->{name},
                            "*** Notice -- TS for " . $chanrec->{name}
                            . " changed from " . $chanrec->{ts}
                            . " to $ts",
                        ],
                    },
                    @local_users,
                );
                $chanrec->{ts} = $ts;
            }
        }
        elsif ($ts > $chanrec->{ts}) {
            # Incoming is younger
            if ($nicks !~ /^\@/) {
                $args->[0] = $chanrec->{ts};
            }
            elsif (grep { /^\@/ } $self->state_chan_list_prefixed($chan)) {
                pop @$args while $#{ $args } > 2;
                $args->[2] = '+';
                $args->[0] = $chanrec->{ts};
                $nicks = join ' ', map { my $s = $_; $s =~ s/[@%+]//g; $s; }
                    split /\s+/, $nicks;
            }
            else {
                $chanrec->{ts} = $ts;
            }
        }
        # Propagate SJOIN to connected peers except the one that told us.
        push @$args, $nicks;
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'SJOIN',
                params  => $args,
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        # Generate appropriate JOIN messages for all local
        # channel members
        my $uchan = uc_irc($chanrec->{name});
        #my @local_users = map { $self->_state_user_route($_) }
        #    grep { $self->_state_is_local_user($_) }
        #    keys %{ $chanrec->{users} };
        my $modes;
        my @mode_parms;
        for my $nick (split /\s+/, $nicks) {
            my $proper = $nick;
            $proper =~ s/[@%+]//g;
            $nick = uc_irc($nick);
            my $umode = '';
            my @op_list;
            $umode .= 'o' if $nick =~ s/\@//g;
            $umode = 'h' if $nick =~ s/\%//g;
            $umode .= 'v' if $nick =~ s/\+//g;
            $chanrec->{users}{$nick} = $umode;
            $self->{state}{users}{$nick}{chans}{$uchan} = $umode;
            push @op_list, $proper for split //, $umode;
            my $output = {
                prefix  => $self->state_user_full($nick),
                command => 'JOIN',
                params  => [$chanrec->{name}],
            };
            $self->send_output($output, @local_users);
            $self->send_event(
                "daemon_join",
                $output->{prefix},
                $chanrec->{name},
            );
            if ($umode) {
                $modes .= $umode;
                push @mode_parms, @op_list;
            }
        }
        if ($modes) {
            my $server = $self->server_name();
            $self->send_event(
                "daemon_mode",
                $server,
                $chanrec->{name},
                '+' . $modes,
                @mode_parms,
            );
            my @output_modes;
            my $length = length($server) + 4 + length($chan) + 4;
            my @buffer = ('+', '');
            for my $umode (split //, $modes) {
                my $arg = shift @mode_parms;
                if (length(join ' ', @buffer, $arg) + $length > 510) {
                    push @output_modes, {
                        prefix   => $server,
                        command  => 'MODE',
                        colonify => 0,
                        params   => [
                            $chanrec->{name},
                            $buffer[0],
                            split /\s+/,
                            $buffer[1],
                        ],
                    };
                    $buffer[0] = "+$umode";
                    $buffer[1] = $arg;
                    next;
                }
                $buffer[0] .= $umode;
                if ($buffer[1]) {
                    $buffer[1] = join ' ', $buffer[1], $arg;
                }
                else {
                    $buffer[1] = $arg;
                }
            }
            push @output_modes, {
                prefix   => $server,
                command  => 'MODE',
                colonify => 0,
                params   => [
                    $chanrec->{name},
                    $buffer[0],
                    split /\s+/,
                    $buffer[1],
                ],
            };
            $self->send_output($_, @local_users)
                for @output_modes;
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_mode {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $chan    = shift;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = scalar @$args;

    SWITCH: {
        if (!$self->state_chan_exists($chan)) {
            last SWITCH;
        }
        my $record = $self->{state}{chans}{uc_irc($chan)};
        $chan = $record->{name};
        my $full;
        $full = $self->state_user_full($nick)
            if $self->state_nick_exists($nick);
        my $reply;
        my @reply_args;
        my $parsed_mode = parse_mode_line(@$args);

        while (my $mode = shift (@{ $parsed_mode->{modes} })) {
            my $arg;
            $arg = shift @{ $parsed_mode->{args} }
                if $mode =~ /^(\+[ohvklbIe]|-[ohvbIe])/;
                    if (my ($flag,$char) = $mode =~ /^(\+|-)([ohv])/) {
                    if ($flag eq '+'
                        && $record->{users}{uc_irc($arg)} !~ /$char/) {
                        # Update user and chan record
                        $arg = uc_irc($arg);
                        next if $mode eq '+h'
                            && $record->{users}{$arg} =~ /o/;
                        if ($char eq 'h' && $record->{users}{$arg} =~ /v/) {
                            $record->{users}{$arg} =~ s/v//g;
                            $reply .= '-v';
                            push @reply_args, $self->state_user_nick($arg);
                        }
                        if ($char eq 'o' && $record->{users}{$arg} =~ /h/) {
                            $record->{users}{$arg} =~ s/h//g;
                            $reply .= '-h';
                            push @reply_args, $self->state_user_nick($arg);
                        }
                        $record->{users}{$arg} = join('', sort split //,
                            $record->{users}{$arg} . $char);
                        $self->{state}{users}{$arg}{chans}{uc_irc($chan)}
                            = $record->{users}{$arg};
                        $reply .= "+$char";
                        push @reply_args, $self->state_user_nick($arg);
                    }
                    if ($flag eq '-' && $record->{users}{uc_irc($arg)}
                        =~ /$char/) {
                        # Update user and chan record
                        $arg = uc_irc($arg);
                        $record->{users}{$arg} =~ s/$char//g;
                        $self->{state}{users}{$arg}{chans}{uc_irc($chan)}
                            = $record->{users}{$arg};
                        $reply .= "-$char";
                        push @reply_args, $self->state_user_nick($arg);
                    }
                    next;
                }
                if ($mode eq '+l' && $arg =~ /^\d+$/ && $arg > 0) {
                    $record->{mode} = join('', sort split //,
                        $record->{mode} . 'l' ) if $record->{mode} !~ /l/;
                    $record->{climit} = $arg;
                    $reply .= '+l';
                    push @reply_args, $arg;
                    next;
                }
                if ($mode eq '-l' && $record->{mode} =~ /l/) {
                    $record->{mode} =~ s/l//g;
                    delete $record->{climit};
                    $reply .= '-l';
                    next;
                }
                if ($mode eq '+k' && $arg) {
                    $record->{mode} = join('', sort split //,
                        $record->{mode} . 'k') if $record->{mode} !~ /k/;
                    $record->{ckey} = $arg;
                    $reply .= '+k';
                    push @reply_args, $arg;
                    next;
                }
                if ($mode eq '-k' && $record->{mode} =~ /k/) {
                    $record->{mode} =~ s/k//g;
                    delete $record->{ckey};
                    $reply .= '-k';
                    next;
                }
                # Bans
                if (my ($flag) = $mode =~ /(\+|-)b/) {
                    my $mask = normalize_mask($arg);
                    my $umask = uc_irc($mask);
                    if ($flag eq '+' && !$record->{bans}{$umask} ) {
                        $record->{bans}{$umask}
                            = [$mask, ($full || $server), time];
                        $reply .= '+b';
                        push @reply_args, $mask;
                    }
                    if ($flag eq '-' && $record->{bans}{$umask}) {
                        delete $record->{bans}{$umask};
                        $reply .= '-b';
                        push @reply_args, $mask;
                    }
                    next;
                }
                # Invex
                if (my ($flag) = $mode =~ /(\+|-)I/) {
                    my $mask = normalize_mask($arg);
                    my $umask = uc_irc($mask);
                    if ($flag eq '+' && !$record->{invex}{$umask}) {
                        $record->{invex}{$umask}
                            = [$mask, ($full || $server), time];
                        $reply .= '+I';
                        push @reply_args, $mask;
                    }
                    if ($flag eq '-' && $record->{invex}{$umask}) {
                        delete $record->{invex}{$umask};
                        $reply .= '-I';
                        push @reply_args, $mask;
                    }
                    next;
                }
                # Exceptions
                if (my ($flag) = $mode =~ /(\+|-)e/) {
                    my $mask = normalize_mask($arg);
                    my $umask = uc_irc($mask);
                    if ($flag eq '+' && !$record->{excepts}{$umask}) {
                        $record->{excepts}{$umask}
                            = [$mask, ($full || $server), time];
                        $reply .= '+e';
                        push @reply_args, $mask;
                    }
                    if ($flag eq '-' && $record->{excepts}{$umask}) {
                        delete $record->{excepts}{$umask};
                        $reply .= '-e';
                        push @reply_args, $mask;
                    }
                    next;
                }
                # The rest should be argumentless.
                my ($flag, $char) = split //, $mode;
                if ( $flag eq '+' && $record->{mode} !~ /$char/) {
                    $record->{mode} = join('', sort split //,
                        $record->{mode} . $char);
                    $reply .= "+$char";
                    next;
                }
                if ($flag eq '-' && $record->{mode} =~ /$char/) {
                    $record->{mode} =~ s/$char//g;
                    $reply .= "-$char";
                    next;
                }
            } # while

            unshift @$args, $record->{name};
            if ($reply) {
            my $parsed_line = unparse_mode_line($reply);
            $self->send_output(
                {
                    prefix   => $nick,
                    command  => 'MODE',
                    colonify => 0,
                    params   => [
                        $record->{name},
                        $parsed_line,
                        @reply_args,
                    ],
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            $self->send_output(
                {
                    prefix   => ($full || $server),
                    command  => 'MODE',
                    colonify => 0,
                    params   => [
                        $record->{name},
                        $parsed_line,
                        @reply_args,
                    ],
                },
                map { $self->_state_user_route($_) }
                    grep { $self->_state_is_local_user($_) }
                    keys %{ $record->{users} },
            );
            $self->send_event(
                "daemon_mode",
                ($full || $server),
                $record->{name},
                $parsed_line,
                @reply_args,
            );
        }
    } # SWITCH

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_umode {
    my $self        = shift;
    my $peer_id     = shift || return;
    my $prefix      = shift || return;
    my $nick        = shift || return;
    my $umode       = shift;
    my $server      = $self->server_name();
    my $ref         = [ ];
    my $record      = $self->{state}{users}{uc_irc($nick)};
    my $parsed_mode = parse_mode_line($umode);

    while (my $mode = shift @{ $parsed_mode->{modes} }) {
        my ($action, $char) = split //, $mode;
        if ($action eq '+' && $record->{umode} !~ /$char/) {
            $record->{umode} .= $char;
            $self->{state}{stats}{invisible}++ if $char eq 'i';
            if ($char eq 'o') {
                $self->{state}{stats}{ops_online}++;
            }
        }
        if ($action eq '-' && $record->{umode} =~ /$char/) {
            $record->{umode} =~ s/$char//g;
            $self->{state}{stats}{invisible}-- if $char eq 'i';
            if ($char eq 'o') {
                $self->{state}{stats}{ops_online}--;
            }
        }
    }
    $self->send_output(
        {
            prefix  => $prefix,
            command => 'MODE',
            params  => [$nick, $umode],
        },
        grep { $_ ne $peer_id } $self->_state_connected_peers(),
    );
    $self->send_event(
        "daemon_umode",
        $self->state_user_full($nick),
        $umode,
    );

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_message {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $type    = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count) {
            push @$ref, ['461', $type];
            last SWITCH;
        }
        if ($count < 2 || !$args->[1]) {
            push @$ref, ['412'];
            last SWITCH;
        }
        my $targets     = 0;
        my $max_targets = $self->server_config('MAXTARGETS');
        my $full        = $self->state_user_full($nick);
        my $targs       = $self->_state_parse_msg_targets($args->[0]);

        LOOP: for my $target (keys %$targs) {
            my $targ_type = shift @{ $targs->{$target} };
            if ($targ_type =~ /(server|host)mask/
                    && !$self->state_user_is_operator($nick)) {
                push @$ref, ['481'];
                next LOOP;
            }
            if ($targ_type =~ /(server|host)mask/
                    && $targs->{$target}[0] !~ /\./) {
                push @$ref, ['413', $target];
                next LOOP;
            }
            if ($targ_type =~ /(server|host)mask/
                    && $targs->{$target}[0] !~ /\x2E.*[\x2A\x3F]+.*$/) {
                push @$ref, ['414', $target];
                next LOOP;
            }
            if ($targ_type eq 'channel_ext'
                    && !$self->state_chan_exists($targs->{$target}[1])) {
                push @$ref, ['401', $targs->{$target}[1]];
                next LOOP;
            }
            if ($targ_type eq 'channel'
                    && !$self->state_chan_exists($target)) {
                push @$ref, ['401', $target];
                next LOOP;
            }
            if ($targ_type eq 'nick'
                    && !$self->state_nick_exists($target)) {
                push @$ref, ['401', $target];
                next LOOP;
            }
            if ($targ_type eq 'nick_ext'
                    && !$self->state_peer_exists($targs->{$target}[1])) {
                push @$ref, ['402', $targs->{$target}[1]];
                next LOOP;
            }
            $targets++;
            if ($targets > $max_targets) {
                push @$ref, ['407', $target];
                last SWITCH;
            }
            # $$whatever
            if ($targ_type eq 'servermask') {
                my $us = 0;
                my %targets;
                my $ucserver = uc $self->server_name();
                for my $peer (keys %{ $self->{state}{peers} }) {
                    if (matches_mask($targs->{$target}[0], $peer)) {
                        if ($ucserver eq $peer) {
                            $us = 1;
                        }
                        else {
                            $targets{ $self->_state_peer_route($peer) }++;
                        }
                    }
                }
                delete $targets{$peer_id};
                $self->send_output(
                    {
                        prefix  => $nick,
                        command => $type,
                        params  => [$target, $args->[1]],
                    },
                    keys %targets,
                );
                if ($us) {
                    my $local = $self->{state}{peers}{uc $self->server_name()}{users};
                    my @local;
                    my $spoofed = 0;
                    for my $luser (values %$local) {
                        if ($luser->{route_id} eq 'spoofed') {
                            $spoofed = 1;
                        }
                        else {
                            push @local, $luser->{route_id};
                        }
                    }
                    $self->send_output(
                        {
                            prefix  => $full,
                            command => $type,
                            params  => [$target, $args->[1]],
                        },
                        @local,
                    );
                    $self->send_event(
                        "daemon_" . lc $type,
                        $full,
                        $target,
                        $args->[1],
                    ) if $spoofed;
                }
                next LOOP;
            }
            # $#whatever
            if ($targ_type eq 'hostmask') {
                my $spoofed = 0;
                my %targets;
                my @local;
                HOST: for my $luser (values %{ $self->{state}{users} }) {
                    next HOST if !matches_mask(
                        $targs->{$target}[0], $luser->{auth}{hostname});
                    if ($luser->{route_id} eq 'spoofed') {
                        $spoofed = 1;
                    }
                    elsif ( $luser->{type} eq 'r') {
                        $targets{$luser->{route_id}}++;
                    }
                    else {
                        push @local, $luser->{route_id};
                    }
                }
                delete $targets{$peer_id};
                $self->send_output(
                    {
                        prefix  => $nick,
                        command => $type,
                        params  => [$target, $args->[1]],
                    },
                    keys %targets,
                );
                $self->send_output(
                    {
                        prefix  => $full,
                        command => $type,
                        params  => [$target, $args->[1]],
                    },
                    @local,
                );
                $self->send_event(
                    "daemon_" . lc $type,
                    $full,
                    $target,
                    $args->[1],
                ) if $spoofed;
                next LOOP;
            }
            if ($targ_type eq 'nick_ext') {
                $targs->{$target}[1]
                    = $self->_state_peer_name($targs->{$target}[1]);
                if ($targs->{$target}[2]
                        && !$self->state_user_is_operator($nick)) {
                    push @$ref, ['481'];
                    next LOOP;
                }
                if ($targs->{$target}[1] ne $self->server_name()) {
                    $self->send_output(
                        {
                            prefix  => $nick,
                            command => $type,
                            params  => [$target, $args->[1]],
                        },
                        $self->_state_peer_route($targs->{$target}[1]),
                    );
                    next LOOP;
                }
                if (uc $targs->{$target}[0] eq 'OPERS') {
                    if (!$self->state_user_is_operator($nick)) {
                        push @$ref, ['481'];
                        next LOOP;
                    }
                    $self->send_output(
                        {
                            prefix  => $full,
                            command => $type,
                            params  => [$target, $args->[1]],
                        },
                        keys %{ $self->{state}{localops} },
                    );
                    next LOOP;
                }

                my @local = $self->_state_find_user_host(
                    $targs->{$target}[0],
                    $targs->{$target}[2],
                );

                if (@local == 1) {
                    my $ref = shift @local;
                    if ($ref->[0] eq 'spoofed') {
                        $self->send_event(
                            "daemon_" . lc $type,
                            $full,
                            $ref->[1],
                            $args->[1],
                        );
                    }
                    else {
                        $self->send_output(
                            {
                                prefix  => $full,
                                command => $type,
                                params  => [$target, $args->[1]],
                            },
                            $ref->[0],
                        );
                    }
                }
                else {
                    push @$ref, ['407', $target];
                    next LOOP;
                    }
                }
                my $channel;
                my $status_msg;
                if ($targ_type eq 'channel') {
                    $channel = $self->_state_chan_name($target);
                }
                if ($targ_type eq 'channel_ext') {
                    $channel = $self->_state_chan_name($targs->{target}[1]);
                    $status_msg = $targs->{target}[0];
                }
                if ($channel && $status_msg
                        && !$self->state_user_chan_mode($nick, $channel)) {
                    push @$ref, ['482', $target];
                    next LOOP;
                }
                if ($channel && $self->state_chan_mode_set($channel, 'n')
                        && !$self->state_is_chan_member($nick, $channel)) {
                    push @$ref, ['404', $channel];
                    next LOOP;
                }
                if ($channel && $self->state_chan_mode_set($channel, 'm')
                        && !$self->state_user_chan_mode($nick, $channel)) {
                    push @$ref, ['404', $channel];
                    next LOOP;
                }
                if ($channel && $self->_state_user_banned($nick, $channel)
                        && !$self->state_user_chan_mode($nick, $channel)) {
                    push @$ref, ['404', $channel];
                    next LOOP;
                }
                if ($channel) {
                    my $common = { };
                    my $msg = {
                        command => $type,
                        params  => [
                            ($status_msg ? $target : $channel),
                            $args->[1],
                        ],
                    };
                    for my $member ($self->state_chan_list($channel, $status_msg)) {
                        next if $self->_state_user_is_deaf($member);
                        $common->{ $self->_state_user_route($member) }++;
                    }
                    delete $common->{$peer_id};
                    for my $route_id (keys %$common) {
                        $msg->{prefix} = $nick;
                        if ($self->_connection_is_client($route_id)) {
                            $msg->{prefix} = $full;
                        }
                        if ($route_id ne 'spoofed') {
                            $self->send_output($msg, $route_id);
                        }
                        else {
                            my $tmsg = $type eq 'PRIVMSG'
                                ? 'public'
                                : 'notice';
                            $self->send_event(
                                "daemon_$tmsg",
                                $full,
                                $channel,
                                $args->[1],
                            );
                        }
                    }
                    next LOOP;
                }
                my $server = $self->server_name();
                if ($self->state_nick_exists($target)) {
                    $target = $self->state_user_nick($target);
                    if (my $away = $self->_state_user_away_msg($target)) {
                        push @$ref, {
                            prefix  => $server,
                            command => '301',
                            params  => [$nick, $target, $away],
                        };
                    }
                    my $targ_umode = $self->state_user_umode($target);
                    # Target user has CALLERID on
                    if ($targ_umode && $targ_umode =~ /[Gg]/) {
                        my $targ_rec = $self->{state}{users}{uc_irc($target) };
                        if (($targ_umode =~ /G/ && (
                            !$self->state_users_share_chan($target, $nick)
                            || !$targ_rec->{accepts}{uc_irc($nick)}))
                            || ($targ_umode =~ /g/
                            && !$targ_rec->{accepts}{uc_irc($nick)})) {
                            push @$ref, {
                                prefix  => $server,
                                command => '716',
                                params  => [
                                    $nick,
                                    $target,
                                    'is in +g mode (server side ignore)',
                                ],
                            };
                            if (!$targ_rec->{last_caller}
                                || (time - $targ_rec->{last_caller} ) >= 60) {
                                my ($n, $uh) = split /!/,
                                    $self->state_user_full($nick);
                                $self->send_output(
                                    {
                                        prefix  => $server,
                                        command => '718',
                                        params  => [
                                            $target,
                                            "$n\[$uh\]",
                                            'is messaging you, and you are umode +g.'
                                        ],
                                    },
                                    $targ_rec->{route_id},
                                ) if $targ_rec->{route_id} ne 'spoofed';
                                push @$ref, {
                                    prefix  => $server,
                                    command => '717',
                                    params  => [
                                        $nick,
                                        $target,
                                        'has been informed that you messaged them.',
                                    ],
                                };
                            }
                        $targ_rec->{last_caller} = time();
                        next LOOP;
                    }
                }
                my $msg = {
                    prefix  => $nick,
                    command => $type,
                    params  => [$target, $args->[1]],
                };
                my $route_id = $self->_state_user_route($target);
                if ($route_id eq 'spoofed') {
                    $msg->{prefix} = $full;
                    $self->send_event(
                        "daemon_" . lc $type,
                        $full,
                        $target,
                        $args->[1],
                    );
                }
                else {
                    if ($self->_connection_is_client($route_id)) {
                        $msg->{prefix} = $full;
                    }
                    $self->send_output($msg, $route_id);
                }
                next LOOP;
            }
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_topic {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH:{
        if (!$count) {
            last SWITCH;
        }
        if (!$self->state_chan_exists($args->[0])) {
            last SWITCH;
        }
        my $chan_name = $self->_state_chan_name($args->[0]);
        my $record = $self->{state}{chans}{uc_irc($args->[0])};
        $record->{topic}
            = [$args->[1], $self->state_user_full($nick), time];
        $self->_send_output_to_channel(
            $args->[0],
            {
                prefix  => $self->state_user_full($nick),
                command => 'TOPIC',
                params  => [$chan_name, $args->[1]],
            },
            $peer_id,
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_invite {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count || $count < 3) {
            last SWITCH;
        }
        my ($who, $chan) = @$args;
        $who = $self->state_user_nick($who);
        $chan = $self->_state_chan_name($chan);
        my $local;
        if ($self->_state_is_local_user($who)) {
            my $record = $self->{state}{users}{uc_irc($who)};
            $record->{invites}{uc_irc($chan)} = time;
            $local = 1;
        }
        my $route_id = $self->_state_user_route($who);
        my $output = {
            prefix   => $self->state_user_full($nick),
            command  => 'INVITE',
            params   => [$who, $chan],
            colonify => 0,
        };
        if ($route_id eq 'spoofed') {
            $self->send_event(
                "daemon_invite",
                $output->{prefix},
                @{ $output->{params} },
            );
        }
        else {
            if (!$local) {
                $output->{prefix} = $nick;
                push @{ $output->{params} }, $args->[2];
            }
            $self->send_output($output, $route_id);
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_away {
    my $self    = shift;
    my $peer_id = shift || return;
    my $nick    = shift || return;
    my $msg     = shift;
    my $server  = $self->server_name();
    my $ref     = [ ];

    SWITCH: {
        my $record = $self->{state}{users}{uc_irc($nick)};
        if (!$msg) {
            delete $record->{away};
            $self->send_output(
                {
                    prefix   => $nick,
                    command  => 'AWAY',
                    colonify => 0,
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            last SWITCH;
        }
        $record->{away} = $msg;
        $self->send_output(
            {
                prefix   => $nick,
                command  => 'AWAY',
                params   => [$msg],
                colonify => 0,
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _state_create {
    my $self = shift;

    $self->_state_delete();

    # Connection specific tables
    $self->{state}{conns} = { };

    # IRC State specific
    $self->{state}{users} = { };
    $self->{state}{peers} = { };
    $self->{state}{chans} = { };

    # Register ourselves as a peer.
    $self->{state}{peers}{uc $self->server_name()} = {
        name => $self->server_name(),
        hops => 0,
        desc => $self->{config}{SERVERDESC},
    };

    $self->{state}{stats} = {
        maxconns   => 0,
        maxlocal   => 0,
        maxglobal  => 0,
        ops_online => 0,
        invisible  => 0,
        cmds       => { },
    };

    return 1;
}

sub _state_delete {
    my $self = shift;
    delete $self->{state};
    return 1;
}

sub _state_update_stats {
    my $self   = shift;
    my $server = $self->server_name();
    my $global = keys %{ $self->{state}{users} };
    my $local  = keys %{ $self->{state}{peers}{uc $server}{users} };

    $self->{state}{stats}{maxglobal}
        = $global if $global > $self->{state}{stats}{maxglobal};
    $self->{state}{stats}{maxlocal}
        = $local if $local > $self->{state}{stats}{maxlocal};
    return 1;
}

sub _state_conn_stats {
    my $self = shift;

    $self->{state}{stats}{conns_cumlative}++;
    my $conns = keys %{ $self->{state}{conns} };
    $self->{state}{stats}{maxconns} = $conns
        if $conns > $self->{state}{stats}{maxconns};
    return 1;
}

sub _state_cmd_stat {
    my $self   = shift;
    my $cmd    = shift || return;
    my $line   = shift || return;
    my $remote = shift;
    my $record = $self->{state}{stats}{cmds}{$cmd} || {
        remote => 0,
        local  => 0,
        bytes  => 0,
    };

    $record->{local}++ if !$remote;
    $record->{remote}++ if $remote;
    $record->{bytes} += length $line;
    $self->{state}{stats}{cmds}{$cmd} = $record;
    return 1;
}

sub _state_find_user_host {
    my $self  = shift;
    my $luser = shift || return;
    my $host  = shift || '*';
    my $local = $self->{state}{peers}{uc $self->server_name()}{users};
    my @conns;
    for my $user (values %$local) {
        if (matches_mask($host, $user->{auth}{hostname})
            && matches_mask($luser, $user->{auth}{ident})) {
            push @conns, [$user->{route_id}, $user->{nick}];
        }
    }

    return @conns;
}

sub _state_local_users_match_rkline {
    my $self  = shift;
    my $luser = shift || return;
    my $host  = shift || return;
    my $local = $self->{state}{peers}{uc $self->server_name()}{users};
    my @conns;

    for my $user (values %$local) {
        next if $user->{route_id} eq 'spoofed';
        next if $user->{umode} && $user->{umode} =~ /o/;
        if (($user->{socket}[0] =~ /$host/
                || $user->{auth}{hostname} =~ /$host/)
                && $user->{auth}{ident} =~ /$luser/) {
            push @conns, $user->{route_id};
        }
    }
    return @conns;
}

sub _state_local_users_match_gline {
    my $self  = shift;
    my $luser = shift || return;
    my $host  = shift || return;
    my $local = $self->{state}{peers}{uc $self->server_name()}{users};
    my @conns;

    if (my $netmask = Net::Netmask->new2($host)) {
        for my $user (values %$local) {
            next if $user->{route_id} eq 'spoofed';
            next if $user->{umode} && $user->{umode} =~ /o/;
            if ($netmask->match($user->{socket}[0])
                    && matches_mask($luser, $user->{auth}{ident})) {
                push @conns, $user->{route_id};
            }
        }
    }
    else {
        for my $user (values %$local) {
            next if $user->{route_id} eq 'spoofed';
            next if $user->{umode} && $user->{umode} =~ /o/;

            if ((matches_mask($host, $user->{socket}[0])
                   || matches_mask($host, $user->{auth}{hostname}))
                   && matches_mask($luser, $user->{auth}{ident})) {
                push @conns, $user->{route_id};
            }
        }
    }

    return @conns;
}

sub _state_user_matches_rkline {
    my $self    = shift;
    my $conn_id = shift || return;
    my $record  = $self->{state}{conns}{$conn_id};
    my $host    = $record->{auth}{hostname} || $record->{socket}[0];
    my $user    = $record->{auth}{ident} || "~" . $record->{user};
    my $ip      = $record->{socket}[0];

    for my $gline (@{ $self->{state}{rklines} }) {
        if (($host =~ /$gline->{host}/ || $ip =~ /$gline->{host}/)
                && $user =~ /$gline->{user}/) {
            return 1;
        }
  }
  return 0;
}

sub _state_user_matches_kline {
    my $self    = shift;
    my $conn_id = shift || return;
    my $record  = $self->{state}{conns}{$conn_id};
    my $host    = $record->{auth}{hostname} || $record->{socket}[0];
    my $user    = $record->{auth}{ident} || "~" . $record->{user};
    my $ip      = $record->{socket}[0];

    for my $gline (@{ $self->{state}{klines} }) {
        if (my $netmask = Net::Netmask->new2($gline->{host})) {
            if ($netmask->match($ip)
                && matches_mask($gline->{user}, $user)) {
                return 1;
            }
        }
        elsif ((matches_mask($gline->{host}, $host)
               || matches_mask($gline->{host}, $ip))
               && matches_mask($gline->{user}, $user)) {
            return 1;
        }
    }

    return 0;
}

sub _state_user_matches_gline {
    my $self    = shift;
    my $conn_id = shift || return;
    my $record  = $self->{state}{conns}{$conn_id};
    my $host    = $record->{auth}{hostname} || $record->{socket}[0];
    my $user    = $record->{auth}{ident} || "~" . $record->{user};
    my $ip      = $record->{socket}[0];

    for my $gline (@{ $self->{state}{glines} }) {
        if (my $netmask = Net::Netmask->new2($gline->{host})) {
            if ($netmask->match($ip)
                && matches_mask($gline->{user}, $user)) {
                return 1;
            }
            elsif ((matches_mask($gline->{host}, $host)
                || matches_mask($gline->{host}, $ip))
                && matches_mask($gline->{user}, $user)) {
                return 1;
            }
        }
    }

    return 0;
}

sub _state_auth_client_conn {
    my $self    = shift;
    my $conn_id = shift || return;

    if (!$self->{config}{auth} || !@{ $self->{config}{auth} }) {
        return 1;
    }
    my $record = $self->{state}{conns}{$conn_id};
    my $host = $record->{auth}{hostname} || $record->{socket}[0];
    my $user = $record->{auth}{ident} || "~" . $record->{user};
    my $uh = join '@', $user, $host;
    my $ui = join '@', $user, $record->{socket}[0];

    for my $auth (@{ $self->{config}{auth} }) {
        if (matches_mask($auth->{mask}, $uh)
                || matches_mask($auth->{mask}, $ui)) {
            if ($auth->{password} && (!$record->{pass}
                    || $auth->{password} ne $record->{pass})) {
                return 0;
            }
            $record->{auth}{hostname} = $auth->{spoof} if $auth->{spoof};

            if (!$record->{auth}{ident} && $auth->{no_tilde}) {
                $record->{auth}{ident} = $record->{user};
            }
            return 1;
        }
    }

    return 0;
}

sub _state_auth_peer_conn {
    my $self = shift;
    my ($conn_id, $name, $pass) = @_;

    if (!$conn_id || !$self->_connection_exists($conn_id)) {
        return;
    }

    return if !$name || !$pass;
    my $peers = $self->{config}{peers};
    if (!$peers->{uc $name} || $peers->{uc $name}{pass} ne $pass) {
        return 0;
    }

    my $conn = $self->{state}{conns}{$conn_id};
    if (!$peers->{uc $name}{ipmask} && $conn->{socket}[0] =~ /^127\./) {
        return 1;
    }
    return 0 if !$peers->{uc $name}{ipmask};
    my $client_ip = $conn->{socket}[0];

    if (ref $peers->{uc $name}{ipmask} eq 'ARRAY') {
        for my $block (grep { $_->isa('Net::Netmask') }
            @{ $peers->{uc $name}{ipmask} }) {
            return 1 if $block->match($client_ip);
        }
    }

    return 1 if matches_mask(
        '*!*@'.$peers->{uc $name}{ipmask},
        "*!*\@$client_ip",
    );

    return 0;
}

sub _state_send_credentials {
    my $self    = shift;
    my $conn_id = shift || return;
    my $name    = shift || return;
    return if !$self->_connection_exists($conn_id);
    return if !$self->{config}{peers}{uc $name};

    my $peer = $self->{config}{peers}{uc $name};
    $self->send_output(
        {
            command => 'PASS',
            params  => [$peer->{rpass}, 'TS'],
        },
        $conn_id,
    );

    $self->send_output(
        {
            command => 'CAPAB',
            params  => [
                join (' ', @{ $self->{config}{capab} },
                    ($peer->{zip} ? 'ZIP' : ())
                ),
            ],
        },
        $conn_id,
    );

    my $rec = $self->{state}{peers}{uc $self->server_name()};
    $self->send_output(
        {
            command => 'SERVER',
            params  => [$rec->{name}, $rec->{hops} + 1, $rec->{desc}],
        },
        $conn_id,
    );

    $self->send_output(
        {
            command => 'SVINFO',
            params  => [5, 5, 0, time],
        },
        $conn_id,
    );

    $self->{state}{conns}{$conn_id}{zip} = $peer->{zip};
    return 1;
}

sub _state_send_burst {
    my $self    = shift;
    my $conn_id = shift || return;
    return if !$self->_connection_exists($conn_id);
    my $server  = $self->server_name();
    my $conn    = $self->{state}{conns}{$conn_id};
    my $burst   = grep { /^EOB$/i } @{ $conn->{capab} };
    my $invex   = grep { /^IE$/i } @{ $conn->{capab} };
    my $excepts = grep { /^EX$/i } @{ $conn->{capab} };
    my %map     = qw(bans b excepts e invex I);
    my @lists   = qw(bans);
    push @lists, 'excepts' if $excepts;
    push @lists, 'invex' if $invex;

    # Send SERVER burst
    for ($self->_state_server_burst($server, $conn->{name})) {
        $self->send_output($_, $conn_id );
    }

    # Send NICK burst
    for my $nick (keys %{ $self->{state}{users} }) {
        my $record = $self->{state}{users}{$nick};
        next if $record->{route_id} eq $conn_id;

        my $umode_fixed = $record->{umode};
        $umode_fixed =~ s/[^aiow]//g;
        my $arrayref = [
            $record->{nick},
            $record->{hops} + 1,
            $record->{ts},
            '+' . $umode_fixed,
            $record->{auth}{ident},
            $record->{auth}{hostname},
            $record->{server}, $record->{ircname},
        ];
        $self->send_output(
            {
                command => 'NICK',
                params  => $arrayref,
            },
            $conn_id,
        );
    }

    # Send SJOIN+MODE burst
    for my $chan (keys %{ $self->{state}{chans} }) {
        next if $chan =~ /^\&/;
        my $chanrec = $self->{state}{chans}{$chan};
        my @nicks = map { $_->[1] }
            sort { $a->[0] cmp $b->[0] }
            map { my $w = $_; $w =~ tr/@%+/ABC/; [$w, $_] }
            $self->state_chan_list_prefixed($chan);

        my $arrayref2 = [
            $chanrec->{ts},
            $chanrec->{name},
            '+' . $chanrec->{mode},
            ($chanrec->{ckey} || ()),
            ($chanrec->{climit} || ()),
            join ' ', @nicks,
        ];

        $self->send_output(
            {
                prefix  => $server,
                command => 'SJOIN',
                params  => $arrayref2,
            },
            $conn_id,
        );

        # TODO: MODE burst
        # Banlist|Exceptions|Invex
        my @output_modes;
        OUTER: for my $type (@lists) {
            my $length = length($server) + 4 + length($chan) + 4;
            my @buffer = ( '', '' );
            INNER: for my $thing (keys %{ $chanrec->{$type} }) {
                $thing = $chanrec->{$type}{$thing}[0];
                if (length(join ' ', @buffer, $thing)+$length+1 > 510) {
                    $buffer[0] = '+' . $buffer[0];
                    push @output_modes, {
                        prefix   => $server,
                        command  => 'MODE',
                        colonify => 0,
                        params   => [
                            $chanrec->{name},
                            $buffer[0],
                            split /\s+/, $buffer[1],
                        ],
                    };
                    $buffer[0] = '+' . $map{$type};
                    $buffer[1] = $thing;
                    next INNER;
                }

                if ($buffer[1]) {
                    $buffer[0] .= $map{$type};
                    $buffer[1] = join ' ', $buffer[1], $thing;
                }
                else {
                    $buffer[0] = '+' . $map{$type};
                    $buffer[1] = $thing;
                }
            }

            push @output_modes, {
                prefix   => $server,
                command  => 'MODE',
                colonify => 0,
                params   => [
                    $chanrec->{name},
                    $buffer[0],
                    split /\s+/, $buffer[1],
                ],
            } if $buffer[0];
        }
        $self->send_output($_, $conn_id) for @output_modes;
    }

    $self->send_output(
        {
            prefix  => $server,
            command => 'EOB',
        },
        $conn_id,
    ) if $burst;

    return 1;
}

sub _state_server_burst {
    my $self = shift;
    my $peer = shift || return;
    my $targ = shift || return;
    if (!$self->state_peer_exists( $peer )
        || !$self->state_peer_exists($targ)) {
    }

    my $ref = [ ];
    $peer = $self->_state_peer_name($peer);
    my $upeer = uc $peer;
    my $utarg = uc $targ;

    for my $server (keys %{ $self->{state}{peers}{$upeer}{peers} }) {
        next if $server eq $utarg;
        my $rec = $self->{state}{peers}{$server};
        push @$ref, {
            prefix  => $peer,
            command => 'SERVER',
            params  => [$rec->{name}, $rec->{hops} + 1, $rec->{desc}],
        };
        push @$ref, $_ for $self->_state_server_burst($rec->{name}, $targ);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _state_server_links {
    my $self = shift;
    my $peer = shift || return;
    my $orig = shift || return;
    my $nick = shift || return;
    return if !$self->state_peer_exists($peer);

    my $ref = [ ];
    $peer = $self->_state_peer_name($peer);
    my $upeer = uc $peer;

    for my $server (keys %{ $self->{state}{peers}{$upeer}{peers} }) {
        my $rec = $self->{state}{peers}{$server};
        for ($self->_state_server_links($rec->{name}, $orig, $nick)) {
            push @$ref, $_;
        }
        push @$ref, {
            prefix  => $orig,
            command => '364',
            params  => [
                $nick,
                $rec->{name},
                $peer,
                join( ' ', $rec->{hops}, $rec->{desc}),
            ],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _state_peer_for_peer {
    my $self = shift;
    my $peer = shift || return;
    return if !$self->state_peer_exists($peer);
    $peer = uc $peer;
    return $self->{state}{peers}{$peer}{peer};
}

sub _state_server_squit {
    my $self = shift;
    my $peer = shift || return;
    return if !$self->state_peer_exists($peer);
    my $ref = [ ];
    my $upeer = uc $peer;
    push @$ref, $_ for keys %{ $self->{state}{peers}{$upeer}{users} };

    for my $server (keys %{ $self->{state}{peers}{$upeer}{peers} }) {
        push @$ref, $_ for $self->_state_server_squit($server);
    }

    delete $self->{state}{peers}{$upeer};
    delete $self->{state}{peers}{uc $self->server_name()}{peers}{$upeer};
    return @$ref if wantarray;
    return $ref;
}

sub _state_register_peer {
    my $self    = shift;
    my $conn_id = shift || return;
    return if !$self->_connection_exists($conn_id);
    my $server  = $self->server_name();
    my $record  = $self->{state}{conns}{$conn_id};

    if (!$record->{cntr}) {
        $self->_state_send_credentials($conn_id, $record->{name});
    }

    $record->{burst} = $record->{registered} = 1;
    $record->{type} = 'p';
    $record->{route_id} = $conn_id;
    $record->{peer}     = $server;
    $record->{users} = { };
    $record->{peers} = { };
    $self->{state}{peers}{uc $server}{peers}{uc $record->{name}} = $record;
    $self->{state}{peers}{ uc $record->{name} } = $record;
    $self->antiflood($conn_id, 0);
    $self->send_output(
        {
            prefix  => $server,
            command => 'SERVER',
            params  => [
                $record->{name},
                $record->{hops} + 1,
                $record->{desc},
            ],
        },
        grep { $_ ne $conn_id } $self->_state_connected_peers(),
    );

    $self->send_event(
        "daemon_server",
        $record->{name},
        $server,
        $record->{hops},
        $record->{desc},
    );

    return 1;
}

sub _state_register_client {
    my $self    = shift;
    my $conn_id = shift || return;
    return if !$self->_connection_exists($conn_id);

    my $record = $self->{state}{conns}{$conn_id};
    $record->{ts} = $record->{idle_time} = $record->{conn_time} = time;
    $record->{_ignore_i_umode} = 1;
    $record->{server}   = $self->server_name();
    $record->{hops}     = 0;
    $record->{route_id} = $conn_id;
    $record->{umode}    = '';

    if (!$record->{auth}{ident}) {
        $record->{auth}{ident} = '~' . $record->{user};
    }

    if ($record->{auth}{hostname} eq 'localhost' ||
        !$record->{auth}{hostname} && $record->{socket}[0] =~ /^127\./) {
        $record->{auth}{hostname} = $self->server_name();
    }

    if (!$record->{auth}{hostname}) {
        $record->{auth}{hostname} = $record->{socket}[0];
    }

    $self->{state}{users}{uc_irc($record->{nick})} = $record;
    $self->{state}{peers}{uc $record->{server}}{users}{uc_irc($record->{nick})} = $record;

    my $arrayref = [
        $record->{nick},
        $record->{hops} + 1,
        $record->{ts}, '+i',
        $record->{auth}{ident},
        $record->{auth}{hostname},
        $record->{server},
        $record->{ircname},
    ];
    delete $self->{state}{pending}{uc_irc($record->{nick})};
    $self->send_output(
        {
            command => 'NICK',
            params  => $arrayref,
        },
        $self->_state_connected_peers(),
    );
    $self->send_event("daemon_nick", @$arrayref);
    $self->_state_update_stats();
    return 1;
}

sub state_nicks {
    my $self = shift;
    return map { $self->{state}{users}{$_}{nick} }
        keys %{ $self->{state}{users} };
}

sub state_nick_exists {
    my $self = shift;
    my $nick = shift || return 1;
    $nick    = uc_irc($nick);

    if (!defined $self->{state}{users}{$nick}
        && !defined $self->{state}{pending}{$nick}) {
        return 0;
    }
    return 1;
}

sub state_chans {
    my $self = shift;
    return map { $self->{state}{chans}{$_}{name} }
        keys %{ $self->{state}{chans} };
}

sub state_chan_exists {
    my $self = shift;
    my $chan = shift || return;
    return 0 if !defined $self->{state}{chans}{uc_irc($chan)};
    return 1;
}

sub state_peers {
    my $self = shift;
    return map { $self->{state}{peers}{$_}{name} }
        keys %{ $self->{state}{peers} };
}

sub state_peer_exists {
    my $self = shift;
    my $peer = shift || return;
    return 0 if !defined $self->{state}{peers}{uc $peer};
    return 1;
}

sub _state_peer_name {
    my $self = shift;
    my $peer = shift || return;
    return if !$self->state_peer_exists($peer);
    return $self->{state}{peers}{uc $peer}{name};
}

sub _state_peer_desc {
    my $self = shift;
    my $peer = shift || return;
    return if !$self->state_peer_exists($peer);
    return $self->{state}{peers}{uc $peer}{desc};
}

sub _state_peer_capab {
    my $self = shift;
    my $conn_id = shift || return;
    my $capab = shift || return;
    $capab = uc $capab;
    return if !$self->_connection_is_peer($conn_id);
    my $conn = $self->{state}{conns}{$conn_id};
    return scalar grep { $_ eq $capab } @{ $conn->{capab} };
}

sub state_user_full {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    my $record = $self->{state}{users}{uc_irc($nick)};
    return $record->{nick} . '!' . $record->{auth}{ident}
        . '@' . $record->{auth}{hostname};
}

sub state_user_nick {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    return $self->{state}{users}{uc_irc($nick)}{nick};
}

sub _state_user_ip {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick)
        || !$self->_state_is_local_user($nick);
    my $record = $self->{state}{users}{uc_irc($nick)};
    return $record->{socket}[0];
}

sub _state_user_away {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    return 1 if defined $self->{state}{users}{uc_irc($nick)}{away};
    return 0;
}

sub _state_user_away_msg {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    return $self->{state}{users}{uc_irc($nick)}{away};
}

sub state_user_umode {
    my $self = shift;
    my $nick = shift || return;
    return if! $self->state_nick_exists($nick);
    return $self->{state}{users}{uc_irc($nick)}{umode};
}

sub state_user_is_operator {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    return 0 if $self->{state}{users}{uc_irc($nick)}{umode} !~ /o/;
    return 1;
}

sub _state_user_is_deaf {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    return 0 if $self->{state}{users}{uc_irc($nick)}{umode} !~ /D/;
    return 1;
}

sub state_user_chans {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    my $record = $self->{state}{users}{uc_irc($nick)};
    return map { $self->{state}{chans}{$_}{name} }
        keys %{ $record->{chans} };
}

sub _state_user_route {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    my $record = $self->{state}{users}{uc_irc($nick)};
    return $record->{route_id};
}

sub state_user_server {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    my $record = $self->{state}{users}{uc_irc($nick)};
    return $record->{server};
}

sub _state_peer_route {
    my $self = shift;
    my $peer = shift || return;
    return if !$self->state_peer_exists($peer);
    my $record = $self->{state}{peers}{uc $peer};
    return $record->{route_id};
}

sub _state_connected_peers {
    my $self = shift;
    my $server = uc $self->server_name();
    return if !keys %{ $self->{state}{peers} } > 1;
    my $record = $self->{state}{peers}{$server};
    return map { $record->{peers}{$_}{route_id} }
        keys %{ $record->{peers} };
}

sub state_chan_list {
    my $self = shift;
    my $chan = shift || return;
    my $status_msg = shift || '';
    return if !$self->state_chan_exists($chan);

    $status_msg =~ s/[^@%+]//g;
    my $record = $self->{state}{chans}{uc_irc($chan)};
    return map { $self->{state}{users}{$_}{nick} }
        keys %{ $record->{users} } if !$status_msg;

    my %map = qw(o 3 h 2 v 1);
    my %sym = qw(@ 3 % 2 + 1);
    my $lowest = (sort map { $sym{$_} } split //, $status_msg)[0];

    return map { $self->{state}{users}{$_}{nick} }
        grep {
            $record->{users}{ $_ } and (reverse sort map { $map{$_} }
            split //, $record->{users}{$_})[0] >= $lowest
        } keys %{ $record->{users} };
}

sub state_chan_list_prefixed {
    my $self = shift;
    my $chan = shift || return;
    return if !$self->state_chan_exists($chan);
    my $record = $self->{state}{chans}{uc_irc($chan)};

    return map {
        my $n = $self->{state}{users}{$_}{nick};
        my $m = $record->{users}{$_};
        my $p = '';
        $p = '@' if $m =~ /o/;
        $p = '%' if $m =~ /h/ && !$p;
        $p = '+' if $m =~ /v/ && !$p;
        $p . $n;
    } keys %{ $record->{users} };
}

sub _state_chan_timestamp {
    my $self = shift;
    my $chan = shift || return;
    return if !$self->state_chan_exists($chan);
    return $self->{state}{chans}{uc_irc($chan)}{ts};
}

sub state_chan_topic {
    my $self = shift;
    my $chan = shift || return;
    return if !$self->state_chan_exists($chan);
    my $record = $self->{state}{chans}{uc_irc($chan)};
    return if !$record->{topic};
    return [@{ $record->{topic} }];
}

sub _state_is_local_user {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    my $record = $self->{state}{peers}{uc $self->server_name()};
    return 1 if defined $record->{users}{uc_irc($nick)};
    return 0;
}

sub _state_chan_name {
    my $self = shift;
    my $chan = shift || return;
    return if !$self->state_chan_exists($chan);
    return $self->{state}{chans}{uc_irc($chan)}{name};
}

sub state_chan_mode_set {
    my $self = shift;
    my $chan = shift || return;
    my $mode = shift || return;
    return if !$self->state_chan_exists($chan);

    $mode =~ s/[^a-zA-Z]+//g;
    $mode = (split //, $mode )[0] if length $mode > 1;
    my $record = $self->{state}{chans}{uc_irc($chan)};
    return 1 if $record->{mode} =~ /$mode/;
    return 0;
}

sub _state_user_invited {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    return if !$self->state_nick_exists($nick);
    return 0 if !$self->state_chan_exists($chan);
    my $nickrec = $self->{state}{users}{uc_irc($nick)};
    return 1 if $nickrec->{invites}{uc_irc($chan)};
    # Check if user matches INVEX
    return 1 if $self->_state_user_matches_list($nick, $chan, 'invex');
    return 0;
}

sub _state_user_banned {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    return 0 if !$self->_state_user_matches_list($nick, $chan, 'bans');
    return 1 if !$self->_state_user_matches_list($nick, $chan, 'excepts');
    return 0;
}

sub _state_user_matches_list {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    my $list = shift || 'bans';
    return if !$self->state_nick_exists($nick);
    return 0 if !$self->state_chan_exists($chan);
    my $full = $self->state_user_full($nick);
    my $record = $self->{state}{chans}{uc_irc($chan)};

    for my $mask (keys %{ $record->{$list} }) {
        return 1 if matches_mask($mask, $full);
    }
    return 0;
}

sub state_is_chan_member {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    return if !$self->state_nick_exists($nick);
    return 0 if !$self->state_chan_exists($chan);
    my $record = $self->{state}{users}{uc_irc($nick)};
    return 1 if defined $record->{chans}{uc_irc($chan)};
    return 0;
}

sub state_user_chan_mode {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    return if !$self->state_is_chan_member($nick, $chan);
    return $self->{state}{users}{uc_irc($nick)}{chans}{uc_irc($chan)};
}

sub state_is_chan_op {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    return if !$self->state_is_chan_member($nick, $chan);
    my $record = $self->{state}{users}{uc_irc($nick)};
    return 1 if $record->{chans}{uc_irc($chan)} =~ /o/;
    return 1 if $self->{config}{OPHACKS} && $record->{umode} =~ /o/;
    return 0;
}

sub state_is_chan_hop {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    return if !$self->state_is_chan_member($nick, $chan);
    my $record = $self->{state}{users}{uc_irc($nick)};
    return 1 if $record->{chans}{uc_irc($chan)} =~ /h/;
    return 0;
}

sub state_has_chan_voice {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    return if !$self->state_is_chan_member($nick, $chan);
    my $record = $self->{state}{users}{uc_irc($nick)};
    return 1 if $record->{chans}{uc_irc($chan)} =~ /v/;
    return 0;
}

sub _state_o_line {
    my $self = shift;
    my $nick = shift || return;
    my ($user, $pass) = @_;
    return if !$self->state_nick_exists($nick);
    return if !$user || !$pass;

    my $ops = $self->{config}{ops};
    return if !$ops->{$user};
    return -1 if !chkpasswd ($pass, $ops->{$user}{password});

    my $client_ip = $self->_state_user_ip($nick);
    return if !$client_ip;
    if (!$ops->{$user}{ipmask} && ($client_ip && $client_ip =~ /^127\./)) {
        return 1;
    }
    return 0 if !$ops->{$user}{ipmask};

    if (ref $ops->{$user}{ipmask} eq 'ARRAY') {
        for my $block (grep { $_->isa('Net::Netmask') } @{ $ops->{$user}{ipmask} }) {
            return 1 if $block->match($client_ip);
        }
    }
    return 1 if matches_mask($ops->{$user}{ipmask}, $client_ip);
    return 0;
}

sub _state_users_share_chan {
    my $self = shift;
    my $nick1 = shift || return;
    my $nick2 = shift || return;
    return if !$self->state_nick_exists($nick1)
        || !$self->state_nick_exists($nick2);
    my $rec1 = $self->{state}{users}{uc_irc($nick1)};
    my $rec2 = $self->{state}{users}{uc_irc($nick2)};
    for my $chan (keys %{ $rec1->{chans} }) {
        return 1 if $rec2->{chans}{$chan};
    }
    return 0;
}

sub _state_parse_msg_targets {
    my $self = shift;
    my $targets = shift || return;
    my %results;

    for my $target (split /,/, $targets) {
        if ($target =~ /^[#&]/) {
            $results{$target} = ['channel'];
            next;
        }
        if ($target =~ /^([@%+]+)([#&].+)$/ ) {
            $results{$target} = ['channel_ext', $1, $2];
            next;
        }
        if ( $target =~ /^\${2}(.+)$/ ) {
            $results{$target} = ['servermask', $1];
            next;
        }
        if ( $target =~ /^\$#(.+)$/ ) {
            $results{$target} = ['hostmask', $1];
            next;
        }
        if ($target =~ /@/ ) {
            my ($nick, $server) = split /@/, $target, 2;
            my $host;
            ($nick, $host) = split ( /%/, $nick, 2 ) if $nick =~ /%/;
            $results{$target} = ['nick_ext', $nick, $server, $host];
            next;
        }
        $results{$target} = ['nick'];
    }

    return \%results;
}

sub server_name {
    return $_[0]->server_config('ServerName');
}

sub server_version {
    return $_[0]->server_config('Version');
}

sub server_created {
    return strftime("This server was created %a %h %d %Y at %H:%M:%S %Z",
        localtime($_[0]->server_config('created')));
}

sub _client_nickname {
    my $self = shift;
    my $wheel_id = $_[0] || return;
    return '*' if !$self->{state}{conns}{$wheel_id}{nick};
    return $self->{state}{conns}{$wheel_id}{nick};
}


sub _client_ip {
    my $self = shift;
    my $wheel_id = shift || return '';
    return $self->{state}{conns}{$wheel_id}{socket}[0];
}

sub server_config {
    my $self = shift;
    my $value = shift || return;
    return $self->{config}{uc $value};
}

sub configure {
    my $self = shift;
    my $opts = ref $_[0] eq 'HASH' ? $_[0] : { @_ };
    $opts->{uc $_} = delete $opts->{$_} for keys %$opts;

    my %defaults = (
        CREATED       => time(),
        CASEMAPPING   => 'rfc1459',
        SERVERNAME    => 'poco.server.irc',
        SERVERDESC    => 'Poco? POCO? POCO!',
        VERSION       => do {
            no strict 'vars';
            ref($self) . '-' . (defined $VERSION ? $VERSION : 'dev-git');
        },
        NETWORK       => 'poconet',
        HOSTLEN       => 63,
        NICKLEN       => 9,
        USERLEN       => 10,
        REALLEN       => 50,
        KICKLEN       => 120,
        TOPICLEN      => 80,
        AWAYLEN       => 160,
        CHANNELLEN    => 50,
        PASSWDLEN     => 20,
        KEYLEN        => 23,
        MAXCHANNELS   => 15,
        MAXACCEPT     => 20,
        MODES         => 4,
        MAXTARGETS    => 4,
        MAXBANS       => 25,
        MAXBANLENGTH  => 1024,
        AUTH          => 1,
        ANTIFLOOD     => 1,
        WHOISACTUALLY => 1,
        OPHACKS       => 0,
    );
    $self->{config}{$_} = $defaults{$_} for keys %defaults;

    for my $opt (qw(HOSTLEN NICKLEN USERLEN REALLEN TOPICLEN CHANNELLEN
        PASSWDLEN KEYLEN MAXCHANNELS MAXACCEPT MODES MAXTARGETS MAXBANS)) {
        my $new = delete $opts->{$opt};
        if (defined $new && $new > $self->{config}{$opt}) {
            $self->{config}{$opt} = $new;
        }
    }

    for my $opt (qw(KICKLEN AWAYLEN)) {
        my $new = delete $opts->{$opt};
        if (defined $new && $new < $self->{config}{$opt}) {
            $self->{config}{$opt} = $new;
        }
    }

    for my $opt (keys %$opts) {
        $self->{config}{$opt} = $opts->{$opt} if defined $opts->{$opt};
    }

    $self->{config}{BANLEN}
        = sum(@{ $self->{config} }{qw(NICKLEN USERLEN HOSTLEN)}, 3);
    $self->{config}{USERHOST_REPLYLEN}
        = sum(@{ $self->{config} }{qw(NICKLEN USERLEN HOSTLEN)}, 5);

    $self->{config}{SERVERNAME} =~ s/[^a-zA-Z0-9\-.]//g;
    if ($self->{config}{SERVERNAME} !~ /\./) {
        $self->{config}{SERVERNAME} .= '.';
    }

    if (!defined $self->{config}{ADMIN}
            || ref $self->{config}{ADMIN} ne 'ARRAY'
            || @{ $self->{config}{ADMIN} } != 3) {
        $self->{config}{ADMIN} = [];
        $self->{config}{ADMIN}[0] = 'Somewhere, Somewhere, Somewhere';
        $self->{config}{ADMIN}[1] = 'Some Institution';
        $self->{config}{ADMIN}[2] = 'someone@somewhere';
    }

    if (!defined $self->{config}{INFO}
            || ref $self->{config}{INFO} ne 'ARRAY'
            || !@{ $self->{config}{INFO} } == 1) {
        $self->{config}{INFO} = [split /\n/, <<'EOF'];
# POE::Component::Server::IRC
#
# Author: Chris "BinGOs" Williams
#
# Filter-IRCD Written by Hachi
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#
EOF
    }

    $self->{Error_Codes} = {
        401 => [1, "No such nick/channel"],
        402 => [1, "No such server"],
        403 => [1, "No such channel"],
        404 => [1, "Cannot send to channel"],
        405 => [1, "You have joined too many channels"],
        406 => [1, "There was no such nickname"],
        407 => [1, "Too many targets"],
        408 => [1, "No such service"],
        409 => [1, "No origin specified"],
        411 => [0, "No recipient given (%s)"],
        412 => [0, "No text to send"],
        413 => [1, "No toplevel domain specified"],
        414 => [1, "Wildcard in toplevel domain"],
        415 => [1, "Bad server/host mask"],
        421 => [1, "Unknown command"],
        422 => [0, "MOTD File is missing"],
        423 => [1, "No administrative info available"],
        424 => [1, "File error doing % on %"],
        431 => [1, "No nickname given"],
        432 => [1, "Erroneous nickname"],
        433 => [1, "Nickname is already in use"],
        436 => [1, "Nickname collision KILL from %s\@%s"],
        437 => [1, "Nick/channel is temporarily unavailable"],
        441 => [1, "They aren\'t on that channel"],
        442 => [1, "You\'re not on that channel"],
        443 => [2, "is already on channel"],
        444 => [1, "User not logged in"],
        445 => [0, "SUMMON has been disabled"],
        446 => [0, "USERS has been disabled"],
        451 => [0, "You have not registered"],
        461 => [1, "Not enough parameters"],
        462 => [0, "Unauthorised command (already registered)"],
        463 => [0, "Your host isn\'t among the privileged"],
        464 => [0, "Password mismatch"],
        465 => [0, "You are banned from this server"],
        466 => [0, "You will be banned from this server"],
        467 => [1, "Channel key already set"],
        471 => [1, "Cannot join channel (+l)"],
        472 => [1, "is unknown mode char to me for %s"],
        473 => [1, "Cannot join channel (+i)"],
        474 => [1, "Cannot join channel (+b)"],
        475 => [1, "Cannot join channel (+k)"],
        476 => [1, "Bad Channel Mask"],
        477 => [1, "Channel doesn\'t support modes"],
        478 => [2, "Channel list is full"],
        481 => [0, "Permission Denied- You\'re not an IRC operator"],
        482 => [1, "You\'re not channel operator"],
        483 => [0, "You can\'t kill a server!"],
        484 => [0, "Your connection is restricted!"],
        485 => [0, "You\'re not the original channel operator"],
        491 => [0, "No O-lines for your host"],
        501 => [0, "Unknown MODE flag"],
        502 => [0, "Cannot change mode for other users"],
    };

    $self->{config}{isupport} = {
        INVEX     => undef,
        EXCEPT    => undef,
        CALLERID  => undef,
        CHANTYPES => '#&',
        PREFIX    => '(ohv)@%+',
        CHANMODES => 'eIb,k,l,imnpst',
        STATUSMSG => '@%+',
        DEAF      => 'D',
        MAXLIST   => 'beI:' . $self->{config}{MAXBANS},
        map { ($_, $self->{config}{$_}) }
            qw(MAXCHANNELS MAXTARGETS NICKLEN TOPICLEN KICKLEN CASEMAPPING
            NETWORK MODES AWAYLEN),
    };

    $self->{config}{capab} = [qw(QS EX CHW IE HOPS UNKLN KLN GLN EOB)];

    return 1;
}

sub _send_output_to_client {
    my $self     = shift;
    my $wheel_id = shift || return 0;
    my $nick     = $self->_client_nickname($wheel_id);
    $nick        = shift if $self->_connection_is_peer($wheel_id);
    my $err      = shift || return 0;
    return if !$self->_connection_exists($wheel_id);

    SWITCH: {
        if (ref $err eq 'HASH') {
            $self->send_output($err, $wheel_id);
            last SWITCH;
        }
        if (defined $self->{Error_Codes}{$err}) {
            my $input = {
                command => $err,
                prefix  => $self->server_name(),
                params  => [$nick],
            };
            if ($self->{Error_Codes}{$err}[0] > 0) {
                for (my $i = 1; $i <= $self->{Error_Codes}{$err}[0]; $i++) {
                    push @{ $input->{params} }, shift;
                }
            }
            if ($self->{Error_Codes}{$err}[1] =~ /%/) {
                push @{ $input->{params} },
                    sprintf($self->{Error_Codes}{$err}[1], @_);
            }
            else {
            push @{ $input->{params} }, $self->{Error_Codes}{$err}[1];
            }
            $self->send_output($input, $wheel_id);
        }
    }

    return 1;
}

sub _send_output_to_channel {
    my $self    = shift;
    my $channel = shift || return;
    my $output  = shift || return;
    my $conn_id = shift || '';
    return if !$self->state_chan_exists($channel);

    # Get conn_ids for each of our peers.
    my $ref = [ ];
    my $peers = { };
    $peers->{$_}++ for $self->_state_connected_peers();
    delete $peers->{$conn_id} if $conn_id;
    push @$ref, $self->_state_user_route($_)
        for grep { $self->_state_is_local_user($_) }
            $self->state_chan_list($channel);
    @$ref = grep { $_ ne $conn_id } @$ref;

    if ($channel !~ /^\&/ && scalar keys %$peers
        && $output->{command} ne 'JOIN') {
        my $full = $output->{prefix};
        my $nick = (split /!/, $full)[0];
        my $output2 = { %$output };
        $output2->{prefix} = $nick;
        $self->send_output($output2, keys %$peers);
    }

    $self->send_output($output, @$ref);
    $self->send_event(
        "daemon_" . lc $output->{command},
        $output->{prefix},
        @{ $output->{params} },
    );
    return 1;
}

sub add_operator {
    my $self = shift;
    my $ref;
    if (ref $_[0] eq 'HASH') {
        $ref = $_[0];
    }
    else {
        $ref = { @_ };
    }
    $ref->{lc $_} = delete $ref->{$_} for keys %$ref;

    if (!defined $ref->{username} || !defined $ref->{password}) {
        warn "Not enough parameters\n";
        return;
    }

    my $record = $self->{state}{peers}{uc $self->server_name()};
    my $user = delete $ref->{username};
    $self->{config}{ops}{$user} = $ref;
    return 1;
}

sub del_operator {
    my $self = shift;
    my $user = shift || return;
    return if !defined $self->{config}{ops}{$user};
    delete $self->{config}{ops}{$user};
    return;
}

sub add_auth {
    my $self = shift;
    my $parms;
    if (ref $_[0] eq 'HASH') {
        $parms = $_[0];
    }
    else {
        $parms = { @_ };
    }
    $parms->{lc $_} = delete $parms->{$_} for keys %$parms;

    if (!$parms->{mask}) {
        warn "Not enough parameters specified\n";
        return;
    }
    push @{ $self->{config}{auth} }, $parms;
    return 1;
}

sub del_auth {
    my $self = shift;
    my $mask = shift || return;
    my $i = 0;

    for (@{ $self->{config}{auth} }) {
        if ($_->{mask} eq $mask) {
            splice( @{ $self->{config}{auth} }, $i, 1 );
            last;
        }
        ++$i;
    }
    return;
}

sub add_peer {
    my $self = shift;
    my $parms;
    if (ref $_[0] eq 'HASH') {
        $parms = $_[0];
    }
    else {
        $parms = { @_ };
    }
    $parms->{lc $_} = delete $parms->{$_} for keys %$parms;

    if (!defined $parms->{name} || !defined $parms->{pass}
           || !defined $parms->{rpass}) {
        croak((caller(0))[3].": Not enough parameters specified\n");
        return;
    }

    $parms->{type} = 'c' if !$parms->{type} || lc $parms->{type} ne 'r';
    $parms->{type} = lc $parms->{type};
    $parms->{rport} = 6667 if $parms->{type} eq 'r' && !$parms->{rport};

    for (qw(sockport sockaddr)) {
        $parms->{ $_ } = '*' if !$parms->{ $_ };
    }

    $parms->{ipmask} = $parms->{raddress} if $parms->{raddress};
    $parms->{zip} = 0 if !$parms->{zip};
    my $name = $parms->{name};
    $self->{config}{peers}{uc $name} = $parms;
    $self->add_connector(
        remoteaddress => $parms->{raddress},
        remoteport    => $parms->{rport},
        name          => $name,
    ) if $parms->{type} eq 'r' && $parms->{auto};

    return 1;
}

sub del_peer {
    my $self = shift;
    my $name = shift || return;
    return if !defined $self->{config}{peers}{uc $name};
    delete $self->{config}{peers}{uc $name};
    return;
}

sub _terminate_conn_error {
    my $self    = shift;
    my $conn_id = shift || return;
    my $msg     = shift;
    return if !$self->_connection_exists($conn_id);

    $self->disconnect($conn_id, $msg);
    $self->send_output(
        {
            command => 'ERROR',
            params  => [
                'Closing Link: ' . $self->_client_ip($conn_id)
                . ' (' . $msg . ')',
            ],
        },
        $conn_id,
    );

    while (my ($nick, $id) = each %{ $self->{state}{pending} }) {
        if ($id == $conn_id) {
            delete $self->{state}{pending}{$nick};
            last;
        }
    }

    return 1;
}

sub daemon_server_kill {
    my $self   = shift;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$count) {
            last SWITCH;
        }
        if ($self->state_peer_exists($args->[0])) {
            last SWITCH;
        }
        if (!$self->state_nick_exists($args->[0])) {
            last SWITCH;
        }

        my $target = $self->state_user_nick($args->[0]);
        my $comment = $args->[1] || '<No reason given>';
        my $conn_id = ($args->[2] && $self->_connection_exists($args->[2])
            ? $args->[2]
            : '');

        if ($self->_state_is_local_user($target)) {
        my $route_id = $self->_state_user_route($target);
        $self->send_output(
            {
                prefix  => $server,
                command => 'KILL',
                params  => [$target, $comment],
            },
            $route_id,
        );
        $self->_terminate_conn_error(
            $route_id,
            "Killed ($server ($comment))",
        );
        if ($route_id eq 'spoofed') {
            $self->call(
                'del_spoofed_nick',
                $target,
                "Killed ($server ($comment))",
            );
        }
        else {
            $self->{state}{conns}{$route_id}{killed} = 1;
            $self->_terminate_conn_error(
                $route_id,
                "Killed ($server ($comment))",
            );
        }
    }
    else {
        $self->{state}{users}{uc_irc($target)}{killed} = 1;
        $self->send_output(
            {
                prefix  => $server,
                command => 'KILL',
                params  => [$target, "$server ($comment)"],
            },
            grep { !$conn_id || $_ ne $conn_id }
                $self->_state_connected_peers(),
        );
        $self->send_output(
            @{ $self->_daemon_peer_quit(
                $target,
                "Killed ($server ($comment))"
            ) });
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub daemon_server_mode {
    my $self   = shift;
    my $chan   = shift;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_chan_exists($chan)) {
            last SWITCH;
        }
        my $record = $self->{state}{chans}{uc_irc($chan)};
        $chan = $record->{name};
        my $full = $server;
        my $parsed_mode = parse_mode_line(@$args);

        while(my $mode = shift (@{ $parsed_mode->{modes} })) {
            my $arg;
            if ($mode =~ /^(\+[ohvklbIe]|-[ohvbIe])/) {
                $arg = shift @{ $parsed_mode->{args} };
            }
            if (my ($flag, $char) = $mode =~ /^(\+|-)([ohv])/) {
                next if !$self->state_is_chan_member($arg, $chan);
                if ($flag eq '+' && $record->{users}{uc_irc($arg)} !~ /$char/) {
                    # Update user and chan record
                    $arg = uc_irc $arg;
                    next if $mode eq '+h' && $record->{users}{$arg} =~ /o/;
                    if ($char eq 'h' && $record->{users}{$arg} =~ /v/) {
                        $record->{users}{$arg} =~ s/v//g;
                    }
                    if ($char eq 'o' && $record->{users}{$arg} =~ /h/) {
                        $record->{users}{$arg} =~ s/h//g;
                    }
                    $record->{users}{$arg} = join('', sort split //,
                        $record->{users}{$arg} . $char);
                    $self->{state}{users}{$arg}{chans}{uc_irc($chan)}
                        = $record->{users}{$arg};
                }
                if ($flag eq '-' && $record->{users}{uc_irc($arg)} =~ /$char/) {
                    # Update user and chan record
                    $arg = uc_irc($arg);
                    $record->{users}{$arg} =~ s/$char//g;
                $self->{state}{users}{$arg}{chans}{uc_irc($chan)}
                    = $record->{users}{$arg};
                }
                next;
            }
            if ($mode eq '+l' && $arg =~ /^\d+$/ && $arg > 0) {
                if ($record->{mode} !~ /l/) {
                $record->{mode} = join('', sort split //,
                    $record->{mode} . 'l');
                }
                $record->{climit} = $arg;
                next;
            }
            if ($mode eq '-l' && $record->{mode} =~ /l/) {
                $record->{mode} =~ s/l//g;
                delete $record->{climit};
                next;
            }
            if ($mode eq '+k' && $arg) {
                if ($record->{mode} !~ /k/) {
                    $record->{mode} = join('', sort split //,
                        $record->{mode} . 'k');
                }
                $record->{ckey} = $arg;
                next;
            }
            if ($mode eq '-k' && $record->{mode} =~ /k/) {
                $record->{mode} =~ s/k//g;
                delete $record->{ckey};
                next;
            }
            # Bans
            if (my ($flag) = $mode =~ /(\+|-)b/) {
                my $mask = normalize_mask($arg);
                my $umask = uc_irc($mask);
                if ($flag eq '+' && !$record->{bans}{$umask}) {
                    $record->{bans}{$umask}
                        = [$mask, ($full || $server), time];
                }
                if ($flag eq '-' and $record->{bans}{$umask}) {
                    delete $record->{bans}{$umask};
                }
                next;
            }
            # Invex
            if (my ($flag) = $mode =~ /(\+|-)I/) {
                my $mask = normalize_mask($arg);
                my $umask = uc_irc($mask);
                if ($flag eq '+' && !$record->{invex}{$umask}) {
                    $record->{invex}{$umask}
                        = [$mask, ($full || $server), time];
                }
                if ($flag eq '-' && $record->{invex}{$umask}) {
                    delete $record->{invex}{$umask};
                }
                next;
            }
            # Exceptions
            if (my ($flag) = $mode =~ /(\+|-)e/) {
                my $mask = normalize_mask($arg);
                my $umask = uc_irc($mask);
                if ($flag eq '+' && !$record->{excepts}{$umask}) {
                    $record->{excepts}{$umask}
                        = [$mask, ($full || $server), time];
                }
                if ($flag eq '-' && $record->{excepts}{$umask}) {
                    delete $record->{excepts}{$umask};
                }
                next;
            }
            # The rest should be argumentless.
            my ($flag, $char) = split //, $mode;
            if ($flag eq '+' && $record->{mode} !~ /$char/) {
                $record->{mode} = join('', sort split //,
                $record->{mode} . $char);
                next;
            }
            if ($flag eq '-' && $record->{mode} =~ /$char/) {
                $record->{mode} =~ s/$char//g;
                next;
            }
        } # while

        unshift @$args, $record->{name};
        $self->send_output(
            {
                prefix   => $server,
                command  => 'MODE',
                params   => $args,
                colonify => 0,
            },
            $self->_state_connected_peers(),
        );
        $self->send_output(
            {
                prefix   => ($full || $server),
                command  => 'MODE',
                params   => $args,
                colonify => 0,
            },
            map { $self->_state_user_route($_) }
                grep { $self->_state_is_local_user($_) }
                    keys %{ $record->{users} },
        );
        $self->send_event("daemon_mode", $server, @$args);
    } # SWITCH

    return @$ref if wantarray;
    return $ref;
}

sub daemon_server_kick {
    my $self   = shift;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my $chan = (split /,/, $args->[0])[0];
        my $who = (split /,/, $args->[1])[0];
        if (!$self->state_chan_exists($chan)) {
            last SWITCH;
        }
        $chan = $self->_state_chan_name($chan);
        if (!$self->state_nick_exists($who)) {
            last SWITCH;
        }
        $who = $self->state_user_nick($who);
        if (!$self->state_is_chan_member($who, $chan)) {
            last SWITCH;
        }
        my $comment = $args->[2] || $who;
        $self->_send_output_to_channel(
            $chan,
            {
                prefix  => $server,
                command => 'KICK',
                params  => [$chan, $who, $comment],
            },
        );
        $who = uc_irc($who);
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$who};
        delete $self->{state}{users}{$who}{chans}{$chan};
        if (!keys %{ $self->{state}{chans}{$chan}{users} }) {
            delete $self->{state}{chans}{$chan};
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub daemon_server_remove {
    my $self   = shift;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my $chan = (split /,/, $args->[0])[0];
        my $who = (split /,/, $args->[1])[0];
        if (!$self->state_chan_exists($chan)) {
            last SWITCH;
        }
        $chan = $self->_state_chan_name($chan);
        if (!$self->state_nick_exists($who)) {
            last SWITCH;
        }
        my $fullwho = $self->state_user_full($who);
        $who = (split /!/, $who)[0];
        if (!$self->state_is_chan_member($who, $chan)) {
            last SWITCH;
        }
        my $comment = 'Enforced PART';
        $comment .= " \"$args->[2]\"" if $args->[2];
        $self->_send_output_to_channel(
            $chan,
            {
                prefix  => $fullwho,
                command => 'PART',
                params  => [$chan, $comment],
            },
        );
        $who = uc_irc($who);
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$who};
        delete $self->{state}{users}{$who}{chans}{$chan};
        if (!keys %{ $self->{state}{chans}{$chan}{users} }) {
            delete $self->{state}{chans}{$chan};
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub daemon_server_wallops {
    my $self   = shift;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    if ($count) {
        $self->send_output(
            {
                prefix  => $server,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            $self->_state_connected_peers(),
            keys %{ $self->{state}{operwall} },
        );
        $self->send_event("daemon_wallops", $server, $args->[0]);
    }

    return @$ref if wantarray;
    return $ref;
}

sub add_spoofed_nick {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    my $ref;
    if (ref $_[ARG0] eq 'HASH') {
        $ref = $_[ARG0];
    }
    else {
        $ref = { @_[ARG0..$#_] };
    }

    $ref->{ lc $_ } = delete $ref->{$_} for keys %$ref;
    return if !$ref->{nick};
    return if $self->state_nick_exists($ref->{nick});
    my $record = $ref;
    $record->{ts} = time if !$record->{ts};
    $record->{type} = 's';
    $record->{server} = $self->server_name();
    $record->{hops} = 0;
    $record->{route_id} = 'spoofed';
    $record->{umode} = 'i' if !$record->{umode};
    if (!defined $record->{ircname}) {
        $record->{ircname} = "* I'm too lame to read the documentation *";
    }
    $self->{state}{stats}{invisible}++ if $record->{umode} =~ /i/;
    $self->{state}{stats}{ops_online}++ if $record->{umode} =~ /o/;
    $record->{idle_time} = $record->{conn_time} = $record->{ts};
    $record->{auth}{ident} = delete $record->{user} || $record->{nick};
    $record->{auth}{hostname} = delete $record->{hostname}
        || $self->server_name();
    $self->{state}{users}{uc_irc($record->{nick})} = $record;
    $self->{state}{peers}{uc $record->{server}}{users}{uc_irc($record->{nick})} = $record;

    my $arrayref = [
        $record->{nick},
        $record->{hops} + 1,
        $record->{ts},
        '+' . $record->{umode},
        $record->{auth}{ident},
        $record->{auth}{hostname},
        $record->{server},
        $record->{ircname},
    ];

    $self->send_output(
        {
            command => 'NICK',
            params  => $arrayref,
        },
        $self->_state_connected_peers(),
    );
    $self->send_event("daemon_nick", @$arrayref);
    $self->_state_update_stats();
    return;
}

sub del_spoofed_nick {
    my ($kernel, $self, $nick) = @_[KERNEL, OBJECT, ARG0];
    return if !$self->state_nick_exists($nick);
    return if $self->_state_user_route($nick) ne 'spoofed';

    my $message = $_[ARG1] || 'Client Quit';
    $self->send_output(
        @{ $self->_daemon_cmd_quit($nick, qq{"$message"}) },
        qq{"$message"},
    );
    return;
}

sub _spoofed_command {
    my ($kernel, $self, $state, $nick) = @_[KERNEL, OBJECT, STATE, ARG0];
    return if !$self->state_nick_exists($nick);
    return if $self->_state_user_route($nick) ne 'spoofed';

    $nick = $self->state_user_nick($nick);
    $state =~ s/daemon_cmd_//;
    my $command = "_daemon_cmd_" . $state;

    if ($state =~ /^(privmsg|notice)$/) {
        my $type = uc $1;
        $self->_daemon_cmd_message($nick, $type, @_[ARG1 .. $#_]);
        return;
    }
    elsif ($state eq 'sjoin') {
        my $chan = $_[ARG1];
        return if !$chan || !$self->state_chan_exists($chan);
        return if $self->state_is_chan_member($nick, $chan);
        $chan = $self->_state_chan_name($chan);
        my $ts = $self->_state_chan_timestamp($chan) - 10;
        $self->_daemon_peer_sjoin(
            'spoofed',
            $self->server_name(),
            $ts,
            $chan,
            '+nt',
            '@' . $nick,
        );
        return;
    }

    $self->$command($nick, @_[ARG1 .. $#_]) if $self->can($command);
    return;
}

1;

=encoding utf8

=head1 NAME

POE::Component::Server::IRC - A fully event-driven networkable IRC server daemon module.

=head1 SYNOPSIS

 # A fairly simple example:
 use strict;
 use warnings;
 use POE qw(Component::Server::IRC);

 my %config = (
     servername => 'simple.poco.server.irc',
     nicklen    => 15,
     network    => 'SimpleNET'
 );

 my $pocosi = POE::Component::Server::IRC->spawn( config => \%config );

 POE::Session->create(
     package_states => [
         'main' => [qw(_start _default)],
     ],
     heap => { ircd => $pocosi },
 );

 $poe_kernel->run();

 sub _start {
     my ($kernel, $heap) = @_[KERNEL, HEAP];

     $heap->{ircd}->yield('register', 'all');

     # Anyone connecting from the loopback gets spoofed hostname
     $heap->{ircd}->add_auth(
         mask     => '*@localhost',
         spoof    => 'm33p.com',
         no_tilde => 1,
     );

     # We have to add an auth as we have specified one above.
     $heap->{ircd}->add_auth(mask => '*@*');

     # Start a listener on the 'standard' IRC port.
     $heap->{ircd}->add_listener(port => 6667);

     # Add an operator who can connect from localhost
     $heap->{ircd}->add_operator(
         {
             username => 'moo',
             password => 'fishdont',
         }
     );
 }

 sub _default {
     my ($event, $args) = @_[ARG0 .. $#_];

     print "$event: ";
     for my $arg (@$args) {
         if (ref($arg) eq 'ARRAY') {
             print "[", join ( ", ", @$arg ), "] ";
         }
         elsif (ref($arg) eq 'HASH') {
             print "{", join ( ", ", %$arg ), "} ";
         }
         else {
             print "'$arg' ";
         }
     }

     print "\n";
  }

=head1 DESCRIPTION

POE::Component::Server::IRC is a POE component which implements an IRC
server (also referred to as an IRC daemon or IRCd). It should be compliant
with the pertient IRC RFCs and is based on reverse engineering Hybrid IRCd
behaviour with regards to interactions with IRC clients and other IRC
servers.

Yes, that's right. POE::Component::Server::IRC is capable of linking to
foreign IRC networks. It supports the TS5 server to server protocol and
has been tested with linking to Hybrid-7 based networks. It should in
theory work with any TS5-based IRC network.

POE::Component::Server::IRC also has a services API, which enables one to
extend the IRCd to create IRC Services. This is fully event-driven (of
course =]). There is also a Plugin system, similar to that sported by
L<POE::Component::IRC|POE::Component::IRC>.

B<Note:> This is a subclass of
L<POE::Component::Server::IRC::Backend|POE::Component::IRC::Server::Backend>.
You should read its documentation too.

=head1 CONSTRUCTOR

=head2 C<spawn>

Returns a new instance of the component. Takes the following parameters:

=over 4

=item * B<'config'>, a hashref of configuration options, see the
L<C<configure>|/configure> method for details.

=back

Any other parameters will be passed along to
L<POE::Component::Server::IRC::Backend|POE::Component::Server::IRC::Backend>'s
L<C<create>|POE::Component::Server::IRC::Backend/create> method.

If the component is spawned from within another session then that session
will automagically be registered with the component to receive events and
be sent an L<C<ircd_registered>|POE::Component::IRC::Server::Backend/ircd_registered>
event.

=head1 METHODS

=head2 Information

=head3 C<server_name>

No arguments, returns the name of the ircd.

=head3 C<server_version>

No arguments, returns the software version of the ircd.

=head3 C<server_created>

No arguments, returns a string signifying when the ircd was created.

=head3 C<server_config>

Takes one argument, the server configuration value to query.

=head2 Configuration

These methods provide mechanisms for configuring and controlling the IRCd
component.

=head3 C<configure>

Configures your new shiny IRCd.

Takes a number of parameters:

=over 4

=item * B<'servername'>, a name to bless your shiny new IRCd with,
defaults to 'poco.server.irc';

=item * B<'serverdesc'>, a description for your IRCd, defaults to
'Poco? POCO? POCO!';

=item * B<'network'>, the name of the IRC network you will be creating,
defaults to 'poconet';

=item * B<'nicklen'>, the max length of nicknames to support, defaults
to 9. B<Note>: the nicklen must be the same on all servers on your IRC
network;

=item * B<'maxtargets'>, max number of targets a user can send
PRIVMSG/NOTICE's to, defaults to 4;

=item * B<'maxchannels'>, max number of channels users may join, defaults
to 15;

=item * B<'version'>, change the server version that is reported;

=item * B<'admin'>, an arrayref consisting of the 3 lines that will be
returned by ADMIN;

=item * B<'info'>, an arrayref consisting of lines to be returned by INFO;

=item * B<'ophacks'>, set to true to enable oper hacks. Default is false;

=item * B<'whoisactually'>, setting this to a false value means that only
opers can see 338. Defaults to true;

=back

=head3 C<add_auth>

By default the IRCd allows any user to connect to the server without a
password. Configuring auths enables you to control who can connect and
set passwords required to connect.

Takes the following parameters:

=over 4

=item * B<'mask'>, a user@host or user@ipaddress mask to match against,
mandatory;

=item * B<'password'>, if specified, any client matching the mask must
provide this to connect;

=item * B<'spoof'>, if specified, any client matching the mask will have
their hostname changed to this;

=item * B<'no_tilde'>, if specified, the '~' prefix is removed from their
username;

=back

Auth masks are processed in order of addition.

If auth masks have been defined, then a connecting user *must* match one
of the masks in order to be authorised to connect. This is a feature >;)

=head3 C<del_auth>

Takes a single argument, the mask to remove.

=head3 C<add_operator>

This adds an O line to the IRCd. Takes a number of parameters:

=over 4

=item * B<'username'>, the username of the IRC oper, mandatory;

=item * B<'password'>, the password, mandatory;

=item * B<'ipmask'>, either a scalar ipmask or an arrayref of Net::Netmask
objects;

=back

A scalar ipmask can contain '*' to match any number of characters or '?' to
match one character. If no 'ipmask' is provided, operators are only allowed
to OPER from the loopback interface.

B<'password'> can be either plain-text, L<C<crypt>|crypt>'d or unix/apache
md5. See the C<mkpasswd> function in
L<POE::Component::Server::IRC::Common|POE::Component::Server::IRC::Common>
for how to generate passwords.

=head3 C<del_operator>

Takes a single argument, the username to remove.

=head3 C<add_peer>

Adds peer servers that we will allow to connect to us and who we will
connect to. Takes the following parameters:

=over 4

=item * B<'name'>, the name of the server. This is the IRC name, not
hostname, mandatory;

=item * B<'pass'>, the password they must supply to us, mandatory;

=item * B<'rpass'>, the password we need to supply to them, mandatory;

=item * B<'type'>, the type of server, 'c' for a connecting server, 'r'
for one that we will connect to;

=item * B<'raddress'>, the remote address to connect to, implies 'type'
eq 'r';

=item * B<'rport'>, the remote port to connect to, default is 6667;

=item * B<'ipmask'>, either a scalar ipmask or an arrayref of Net::Netmask
objects;

=item * B<'auto'>, if set to true value will automatically connect to
remote server if type is 'r';

=item * B<'zip'>, set to a true value to enable ziplink support. This must
be done on both ends of the connection. Requires
L<POE::Filter::Zlib::Stream|POE::Filter::Zlib::Stream>;

=back

=head3 C<del_peer>

Takes a single argument, the peer to remove. This does not disconnect the
said peer if it is currently connected.

=head2 State queries

The following methods allow you to query state information regarding
nicknames, channels, and peers.

=head3 C<state_nicks>

Takes no arguments, returns a list of all nicknames in the state.

=head3 C<state_chans>

Takes no arguments, returns a list of all channels in the state.

=head3 C<state_peers>

Takes no arguments, returns a list of all irc servers in the state.

=head3 C<state_nick_exists>

Takes one argument, a nickname, returns true or false dependent on whether
the given nickname exists or not.

=head3 C<state_chan_exists>

Takes one argument, a channel name, returns true or false dependent on
whether the given channel exists or not.

=head3 C<state_peer_exists>

Takes one argument, a peer server name, returns true or false dependent
on whether the given peer exists or not.

=head3 C<state_user_full>

Takes one argument, a nickname, returns that users full nick!user@host
if they exist, undef if they don't.

=head3 C<state_user_nick>

Takes one argument, a nickname, returns the proper nickname for that user.
Returns undef if the nick doesn't exist.

=head3 C<state_user_umode>

Takes one argument, a nickname, returns that users mode setting.

=head3 C<state_user_is_operator>

Takes one argument, a nickname, returns true or false dependent on whether
the given nickname is an IRC operator or not.

=head3 C<state_user_chans>

Takes one argument, a nickname, returns a list of channels that that nick
is a member of.

=head3 C<state_user_server>

Takes one argument, a nickname, returns the name of the peer server that
that user is connected from.

=head3 C<state_chan_list>

Takes one argument, a channel name, returns a list of the member nicks on
that channel.

=head3 C<state_chan_list_prefixed>

Takes one argument, a channel name, returns a list of the member nicks on
that channel, nicknames will be prefixed with @%+ if they are +o +h or +v,
respectively.

=head3 C<state_chan_topic>

Takes one argument, a channel name, returns undef if no topic is set on
that channel, or an arrayref consisting of the topic, who set it and the
time they set it.

=head3 C<state_chan_mode_set>

Takes two arguments, a channel name and a channel mode character. Returns
true if that channel mode is set, false otherwise.

=head3 C<state_is_chan_member>

Takes two arguments, a nick and a channel name. Returns true if that nick
is on channel, false otherwise.

=head3 C<state_user_chan_mode>

Takes two arguments, a nick and a channel name. Returns that nicks status
(+ohv or '') on that channel.

=head3 C<state_is_chan_op>

Takes two arguments, a nick and a channel name. Returns true if that nick
is an channel operator, false otherwise.

=head3 C<state_is_chan_hop>

Takes two arguments, a nick and a channel name. Returns true if that nick
is an channel half-operator, false otherwise.

=head3 C<state_has_chan_voice>

Takes two arguments, a nick and a channel name. Returns true if that nick
has channel voice, false otherwise.

=head2 Server actions

=head3 C<daemon_server_kill>

Takes two arguments, a nickname and a comment (which is optional); Issues
a SERVER KILL of the given nick;

=head3 C<daemon_server_mode>

First argument is a channel name, remaining arguments are channel modes
and their parameters to apply.

=head3 C<daemon_server_kick>

Takes two arguments that are mandatory and an optional one: channel name,
nickname of the user to kick and a pithy comment.

=head3 C<daemon_server_remove>

Takes two arguments that are mandatory and an optional one: channel name,
nickname of the user to remove and a pithy comment.

=head3 C<daemon_server_wallops>

Takes one argument, the message text to send.

=head1 INPUT EVENTS

These are POE events that can be sent to the component.

=head2 C<add_spoofed_nick>

Takes a single argument a hashref which should have the following keys:

=over 4

=item * B<'nick'>, the nickname to add, mandatory;

=item * B<'user'>, the ident you want the nick to have, defaults to the
same as the nick;

=item * B<'hostname'>, the hostname, defaults to the server name;

=item * B<'umode'>, specify whether this is to be an IRCop etc, defaults
to 'i';

=item * B<'ts'>, unixtime, default is time(), best not to meddle;

=back

B<Note:> spoofed nicks are currently only really functional for use as IRC
services.

=head2 C<del_spoofed_nick>

Takes a single mandatory argument, the spoofed nickname to remove.
Optionally, you may specify a quit message for the spoofed nick.

=head2 Spoofed nick commands

The following input events are for the benefit of spoofed nicks. All
require a nickname of a spoofed nick as the first argument.

=head3 C<daemon_cmd_join>

Takes two arguments, a spoofed nick and a channel name to join.

=head3 C<daemon_cmd_part>

Takes two arguments, a spoofed nick and a channel name to part from.

=head3 C<daemon_cmd_mode>

Takes at least three arguments, a spoofed nick, a channel and a channel
mode to apply. Additional arguments are parameters for the channel modes.

=head3 C<daemon_cmd_kick>

Takes at least three arguments, a spoofed nick, a channel name and the
nickname of a user to kick from that channel. You may supply a fourth
argument which will be the kick comment.

=head3 C<daemon_cmd_topic>

Takes three arguments, a spoofed nick, a channel name and the topic to
set on that channel. If the third argument is an empty string then the
channel topic will be unset.

=head3 C<daemon_cmd_nick>

Takes two arguments, a spoofed nick and a new nickname to change to.

=head3 C<daemon_cmd_gline>

Takes three arguments, a spoofed nick, a user@host mask to gline and a
reason for the gline.

=head3 C<daemon_cmd_kline>

Takes a number of arguments depending on where the KLINE is to be applied
and for how long:

To set a permanent KLINE:

 $ircd->yield(
     'daemon_cmd_kline',
     $spoofed_nick,
     $nick || $user_host_mask,
     $reason,
 );

To set a temporary 10 minute KLINE:

 $ircd->yield(
     'daemon_cmd_kline',
     $spoofed_nick,
     10,
     $nick || $user_host_mask,
     $reason,
 );

To set a temporary 10 minute KLINE on all servers:

 $ircd->yield(
     'daemon_cmd_kline',
     $spoofed_nick,
     10,
     $nick || $user_host_mask,
     'on',
     '*',
     $reason,
 );

=head3 C<daemon_cmd_unkline>

Removes a KLINE as indicated by the user@host mask supplied.

To remove a KLINE:

 $ircd->yield(
     'daemon_cmd_unkline',
     $spoofed_nick,
     $user_host_mask,
 );

To remove a KLINE from all servers:

 $ircd->yield(
     'daemon_cmd_unkline',
     $spoofed_nick,
     $user_host_mask,
     'on',
     '*',
 );

=head3 C<daemon_cmd_rkline>

Used to set a regex based KLINE. The regex given must be based on a
user@host mask.

To set a permanent RKLINE:

 $ircd->yield(
     'daemon_cmd_rkline',
     $spoofed_nick,
     '^.*$@^(yahoo|google|microsoft)\.com$',
     $reason,
 );

To set a temporary 10 minute RKLINE:

 $ircd->yield(
     'daemon_cmd_rkline',
     $spoofed_nick,
     10,
     '^.*$@^(yahoo|google|microsoft)\.com$',
     $reason,
 );

To set a temporary 10 minute RKLINE on all servers:

 $ircd->yield(
     'daemon_cmd_kline',
     $spoofed_nick,
     10,
     '^.*$@^(yahoo|google|microsoft)\.com$',
     'on',
     '*',
     $reason,
 );

=head3 C<daemon_cmd_sjoin>

Takes two arguments a spoofed nickname and an existing channel name. This
command will then manipulate the channel timestamp to clear all modes on
that channel, including existing channel operators, reset the channel mode
to '+nt', the spoofed nick will then join the channel and gain channel ops.

=head3 C<daemon_cmd_privmsg>

Takes three arguments, a spoofed nickname, a target (which can be a
nickname or a channel name) and whatever text you wish to send.

=head3 C<daemon_cmd_notice>

Takes three arguments, a spoofed nickname, a target (which can be a
nickname or a channel name) and whatever text you wish to send.

=head3 C<daemon_cmd_locops>

Takes two arguments, a spoofed nickname and the text message to send to
local operators.

=head3 C<daemon_cmd_wallops>

Takes two arguments, a spoofed nickname and the text message to send to
all operators.

=head3 C<daemon_cmd_operwall>

Takes two arguments, a spoofed nickname and the text message to send to
all operators.

=head1 OUTPUT EVENTS

=head2 C<ircd_daemon_error>

=over

=item Emitted: when we fail to register with a peer;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the connection id;

=item * C<ARG1>, the server name;

=item * C<ARG2>, the reason;

=back

=back

=head2 C<ircd_daemon_server>

=over

=item Emitted: when a server is introduced onto the network;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the server name;

=item * C<ARG1>, the name of the server that is introducing them;

=item * C<ARG2>, the hop count;

=item * C<ARG3>, the server description;

=back

=back

=head2 C<ircd_daemon_squit>

=over

=item Emitted: when a server quits the network;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the server name;

=back

=back

=head2 C<ircd_daemon_nick>

=over

=item Emitted: when a user is introduced onto the network or changes their
nickname

=item Target: all plugins and registered sessions;

=item Args (new user):

=over 4

=item * C<ARG0>, the nickname;

=item * C<ARG1>, the hop count;

=item * C<ARG2>, the time stamp (TS);

=item * C<ARG3>, the user mode;

=item * C<ARG4>, the ident;

=item * C<ARG5>, the hostname;

=item * C<ARG6>, the server name;

=item * C<ARG7>, the real name;

=back

=item Args (nick change):

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the new nickname;

=back

=back

=head2 C<ircd_daemon_umode>

=over

=item Emitted: when a user changes their user mode;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the user mode change;

=back

=back

=head2 C<ircd_daemon_quit>

=over

=item Emitted: when a user quits or the server they are on squits;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the quit message;

=back

=back

=head2 C<ircd_daemon_join>

=over

=item Emitted: when a user joins a channel

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the channel name;

=back

=back

=head2 C<ircd_daemon_part>

=over

=item Emitted: when a user parts a channel;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the channel name;

=item * C<ARG2>, the part message;

=back

=back

=head2 C<ircd_daemon_kick>

=over

=item Emitted: when a user is kicked from a channel;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host of the kicker;

=item * C<ARG1>, the channel name;

=item * C<ARG2>, the nick of the kicked user;

=item * C<ARG3>, the kick message;

=back

=back

=head2 C<ircd_daemon_mode>

=over

=item Emitted: when a channel mode is changed;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host or server name;

=item * C<ARG1>, the channel name;

=item * C<ARG2..$#_>, the modes and their arguments;

=back

=back

=head2 C<ircd_daemon_topic>

=over

=item Emitted: when a channel topic is changed

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host of the changer;

=item * C<ARG1>, the channel name;

=item * C<ARG2>, the new topic;

=back

=back

=head2 C<ircd_daemon_public>

=over

=item Emitted: when a channel message is sent (a spoofed nick must be in
the channel)

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host of the sender;

=item * C<ARG1>, the channel name;

=item * C<ARG2>, the message;

=back

=back

=head2 C<ircd_daemon_privmsg>

=over

=item Emitted: when someone sends a private message to a spoofed nick

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host of the sender;

=item * C<ARG1>, the spoofed nick targeted;

=item * C<ARG2>, the message;

=back

=back

=head2 C<ircd_daemon_notice>

=over

=item Emitted: when someone sends a notice to a spoofed nick or channel

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host of the sender;

=item * C<ARG1>, the spoofed nick targeted or channel spoofed nick is in;

=item * C<ARG2>, the message;

=back

=back

=head2 C<ircd_daemon_invite>

=over

=item Emitted: when someone invites a spoofed nick to a channel;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host of the inviter;

=item * C<ARG1>, the spoofed nick being invited;

=item * C<ARG2>, the channel being invited to;

=back

=back

=head2 C<ircd_daemon_rehash>

=over

=item Emitted: when an oper issues a REHASH command;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host of the oper;

=back

=back

=head2 C<ircd_daemon_die>

=over

=item Emitted: when an oper issues a DIE command;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host of the oper;

=back

=back

B<Note:> the component will shutdown, this is a feature;

=head2 C<ircd_daemon_gline>

=over

=item Emitted: when an oper issues a GLINE command;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the user mask;

=item * C<ARG2>, the host mask;

=item * C<ARG3>, the reason;

=back

=back

=head2 C<ircd_daemon_kline>

=over

=item Emitted: when an oper issues a KLINE command;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the target for the KLINE;

=item * C<ARG2>, the duration in seconds;

=item * C<ARG3>, the user mask;

=item * C<ARG4>, the host mask;

=item * C<ARG5>, the reason;

=back

=back

=head2 C<ircd_daemon_rkline>

=over

=item Emitted: when an oper issues an RKLINE command;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the target for the RKLINE;

=item * C<ARG2>, the duration in seconds;

=item * C<ARG3>, the user mask;

=item * C<ARG4>, the host mask;

=item * C<ARG5>, the reason;

=back

=back

=head2 C<ircd_daemon_unkline>

=over

=item Emitted: when an oper issues an UNKLINE command;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the target for the UNKLINE;

=item * C<ARG2>, the user mask;

=item * C<ARG3>, the host mask;

=back

=back

=head2 C<ircd_daemon_locops>

=over

=item Emitted: when an oper issues a LOCOPS command;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the locops message;

=back

=back

=head2 C<ircd_daemon_operwall>

=over

=item Emitted: when an oper issues a WALLOPS or OPERWALL command;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the wallops or operwall message;

=back

=back

=head2 C<ircd_daemon_wallops>

=over

=item Emitted: when a server issues a WALLOPS;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the server name;

=item * C<ARG1>, the wallops message;

=back

=back

=head1 BUGS

A few have turned up in the past and they are sure to again. Please use
L<http://rt.cpan.org/> to report any. Alternatively, email the current
maintainer.

=head1 DEVELOPMENT

You can find the latest source on github:
L<http://github.com/bingos/poe-component-server-irc>

The project's developers usually hang out in the C<#poe> IRC channel on
irc.perl.org. Do drop us a line.

=head1 MAINTAINER

Hinrik E<Ouml>rn SigurE<eth>sson <hinrik.sig@gmail.com>

=head1 AUTHOR

Chris 'BinGOs' Williams

=head1 LICENSE

Copyright C<(c)> Chris Williams

This module may be used, modified, and distributed under the same terms as
Perl itself. Please see the license that came with your Perl distribution
for details.

=head1 KUDOS

Rocco Caputo for creating POE.

Buu for pestering me when I started to procrastinate =]

=head1 SEE ALSO

L<POE|POE> L<http://poe.perl.org/>

L<POE::Component::Server::IRC::Backend|POE::Component::IRC::Server::Backend>

L<Net::Netmask|Net::Netmask>

Hybrid IRCD L<http://ircd-hybrid.com/>

TSOra L<http://www.idolnet.org/docs/README.TSora>

RFC 2810 L<http://www.faqs.org/rfcs/rfc2810.html>

RFC 2811 L<http://www.faqs.org/rfcs/rfc2811.html>

RFC 2812 L<http://www.faqs.org/rfcs/rfc2812.html>

RFC 2813 L<http://www.faqs.org/rfcs/rfc2813.html>

=cut
