package POE::Component::Server::IRC;
$POE::Component::Server::IRC::VERSION = '1.66';
use strict;
use warnings;
use Carp qw(carp croak);
use IRC::Utils qw(uc_irc parse_mode_line unparse_mode_line normalize_mask
                  matches_mask matches_mask_array gen_mode_change is_valid_nick_name
                  is_valid_chan_name has_color has_formatting parse_user);
use List::Util qw(sum);
use POE;
use POE::Component::Server::IRC::Common qw(chkpasswd);
use POE::Component::Server::IRC::Plugin qw(:ALL);
use POSIX 'strftime';
use Net::CIDR ();
use base qw(POE::Component::Server::IRC::Backend);

my $sid_re  = qr/^[0-9][A-Z0-9][A-Z0-9]$/;
my $id_re   = qr/^[A-Z][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]$/;
my $uid_re  = qr/^[0-9][A-Z0-9][A-Z0-9][A-Z][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]$/;
my $host_re = qr/^[^.:][A-Za-z0-9.:-]+$/;
my $user_re = qr/^[^\x2D][\x24\x2D-\x39\x41-\x7E]+$/;

sub spawn {
    my ($package, %args) = @_;
    $args{lc $_} = delete $args{$_} for keys %args;
    my $config = delete $args{config};
    my $debug = delete $args{debug};
    my $self = $package->create(
        ($debug ? (raw_events => 1) : ()),
        %args,
        states => [
            [qw(add_spoofed_nick del_spoofed_nick _state_drkx_line_alarm _daemon_do_safelist)],
            {
                map { +"daemon_cmd_$_" => '_spoofed_command' }
                    qw(join part mode kick topic nick privmsg notice xline unxline resv unresv
                       rkline unrkline kline unkline sjoin locops wallops globops dline undline)
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
    my ($conn_id, $peeraddr, $peerport, $sockaddr, $sockport, $needs_auth, $secured, $filter)
        = map { ${ $_ } } @_;

    if ($self->_connection_exists($conn_id)) {
        delete $self->{state}{conns}{$conn_id};
    }

    $self->{state}{conns}{$conn_id}{registered} = 0;
    $self->{state}{conns}{$conn_id}{type}       = 'u';
    $self->{state}{conns}{$conn_id}{seen}       = time();
    $self->{state}{conns}{$conn_id}{conn_time}  = time();
    $self->{state}{conns}{$conn_id}{secured}    = $secured;
    $self->{state}{conns}{$conn_id}{stats}      = $filter;
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
    my ($conn_id, $peeraddr, $peerport, $sockaddr, $sockport, $name, $filter)
        = map { ${ $_ } } @_;

    if ($self->_connection_exists($conn_id)) {
        delete $self->{state}{conns}{$conn_id};
    }

    $self->{state}{conns}{$conn_id}{peer}       = $name;
    $self->{state}{conns}{$conn_id}{registered} = 0;
    $self->{state}{conns}{$conn_id}{cntr}       = 1;
    $self->{state}{conns}{$conn_id}{type}       = 'u';
    $self->{state}{conns}{$conn_id}{seen}       = time();
    $self->{state}{conns}{$conn_id}{conn_time}  = time();
    $self->{state}{conns}{$conn_id}{stats}      = $filter;
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
        my $peer = $self->{state}{conns}{$conn_id}{sid};
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
    return PCSI_EAT_CLIENT if $self->_connection_terminated($conn_id);
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

sub _connection_terminated {
    my $self = shift;
    my $conn_id = shift || return;
    return if !defined $self->{state}{conns}{$conn_id};
    return 1 if defined $self->{state}{conns}{$conn_id}{terminated};
}

sub _client_register {
    my $self    = shift;
    my $conn_id = shift || return;
    return if !$self->_connection_exists($conn_id);
    return if !$self->{state}{conns}{$conn_id}{nick};
    return if !$self->{state}{conns}{$conn_id}{user};
    return if $self->{state}{conns}{$conn_id}{capneg};
    my $server    = $self->server_name();

    my $auth = $self->_auth_finished($conn_id);
    return if !$auth;
    # pass required for link
    if (!$self->_state_auth_client_conn($conn_id)) {
        my $crec = $self->{state}{conns}{$conn_id};
        $self->_send_to_realops(
            sprintf(
                'Unauthorized client connection from %s!%s@%s on [%s/%u].',
                $crec->{nick}, $crec->{user}, $crec->{socket}[0],
                $crec->{socket}[2], $crec->{socket}[3],
            ),
            'Notice', 'u',
        );
        $self->_terminate_conn_error(
            $conn_id,
            'You are not authorized to use this server',
        );
        return;
    }
    if ($self->{auth}) {
        if ( $self->{state}{conns}{$conn_id}{need_ident} &&
             !$self->{state}{conns}{$conn_id}{auth}{ident} ) {
            $self->_send_output_to_client(
                $conn_id,
                {
                    prefix  => $server,
                    command => 'NOTICE',
                    params  => [
                        '*',
                        '*** Notice -- You need to install identd to use this server',
                    ],
                },
            );
            $self->_terminate_conn_error(
                $conn_id,
                'Install identd',
            );
            return;
        }
    }
    if (my $reason = $self->_state_user_matches_xline($conn_id)) {
        my $crec = $self->{state}{conns}{$conn_id};
        $self->_send_to_realops(
            sprintf(
                'X-line Rejecting [%s] [%s], user %s!%s@%s [%s]',
                $crec->{ircname}, $reason,
                $crec->{nick}, $crec->{user},
                ( $crec->{auth}{hostname} || $crec->{socket}[0] ),
                $crec->{socket}[0],
            ),
            'Notice',
            'j',
        );
        $self->_send_output_to_client( $conn_id, '465' );
        $self->_terminate_conn_error($conn_id, "X-Lined: [$reason]");
        return;
    }
    if (my $reason = $self->_state_user_matches_kline($conn_id)) {
        $self->_send_output_to_client( $conn_id, '465' );
        $self->_terminate_conn_error($conn_id, "K-Lined: [$reason]");
        return;
    }
    if (my $reason = $self->_state_user_matches_rkline($conn_id)) {
        $self->_send_output_to_client( $conn_id, '465' );
        $self->_terminate_conn_error($conn_id, "K-Lined: [$reason]");
        return;
    }

    if ( !$self->{state}{conns}{$conn_id}{auth}{ident} &&
         $self->{state}{conns}{$conn_id}{user} !~ $user_re ) {
        my $crec = $self->{state}{conns}{$conn_id};
        $self->_send_to_realops(
            sprintf(
                'Invalid username: %s (%s@%s)',
                $crec->{nick}, $crec->{user},
                ( $crec->{auth}{hostname} || $crec->{socket}[0] ),
            ),
            'Notice',
            'j',
        );
        $self->_terminate_conn_error(
            $conn_id,
            sprintf(
                'Invalid username [%s]', $crec->{user},
            ),
        );
        return;
    }

    my $clients = keys %{ $self->{state}{sids}{$self->server_sid()}{uids} };
    if ( $self->{config}{MAXCLIENTS} < $clients + 1 ) {
        my $crec = $self->{state}{conns}{$conn_id};
        if (!$crec->{exceed_limit}) {
            $self->_terminate_conn_error($conn_id,
                  'Sorry, server is full - try later');
            return;
        }
    }

    # Add new nick
    my $uid       = $self->_state_register_client($conn_id);
    my $umode     = $self->{state}{conns}{$conn_id}{umode};
    my $nick      = $self->_client_nickname($conn_id);
    my $port      = $self->{state}{conns}{$conn_id}{socket}[3];
    my $version   = $self->server_version();
    my $network   = $self->server_config('NETWORK');
    my $server_is = "$server\[$server/$port]";

    if (my $sslinfo = $self->connection_secured($conn_id)) {
        $self->_send_output_to_client(
            $conn_id,
            {
                prefix  => $server,
                command => 'NOTICE',
                params  => [
                    $nick,
                    "*** Connected securely via $sslinfo",
                ],
            },
        );
    }

    $self->_state_auth_flags_notices($conn_id);

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
                'DFGHRSWXabcdefgijklnopqrsuwy',
                'biklmnopstveIh',
                'bkloveIh',
            ],
        }
    );

    for my $output (@{ $self->_daemon_do_isupport($uid) }) {
        $output->{prefix} = $server;
        $output->{params}[0] = $nick;
        $self->_send_output_to_client($conn_id, $output);
    }

    $self->{state}{conns}{$conn_id}{registered} = 1;
    $self->{state}{conns}{$conn_id}{type} = 'c';

    $self->send_output( $_, $conn_id ) for
      map { $_->{prefix} = $server; $_->{params}[0] = $nick; $_ }
        @{ $self->_daemon_do_lusers($uid) };


    $self->send_output( $_, $conn_id ) for
      map { $_->{prefix} = $server; $_->{params}[0] = $nick; $_ }
        @{ $self->_daemon_do_motd($uid) };

    if ( $umode ) {
        $self->send_output(
            {
                prefix  => $self->{state}{uids}{$uid}{full}->(),
                command => 'MODE',
                params => [ $nick, "+$umode" ],
            },
            $conn_id,
        );
    }

    $self->send_event(
        'cmd_mode',
        $conn_id,
        {
            command => 'MODE',
            params  => [$nick, "+i"],
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

        if ($cmd eq 'CAP' ) {
            $self->_daemon_cmd_cap($wheel_id, @$params);
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

               # TS6 server
               # PASS password TS 6 6FU
               if ($params->[2] && $params->[3]) {
                  $self->{state}{conns}{$wheel_id}{ts_data} = [ @{$params}[2,3] ];
                  my $ts  = $params->[2];
                  my $sid = $params->[3];
                  my $errstr;
                  if ($sid !~ $sid_re || $ts ne '6') {
                      my $crec = $self->{state}{conns}{$wheel_id};
                      $self->_send_to_realops(
                          sprintf(
                              'Link [unknown@%s] introduced server with bogus server ID %s',
                              $crec->{socket}[0], $sid,
                          ), qw[Notice s],
                      );
                      $errstr  = 'Bogus server ID introduced';
                  }
                  elsif ($self->state_sid_exists( $sid )) {
                      my $crec = $self->{state}{conns}{$wheel_id};
                      $self->_send_to_realops(
                          sprintf(
                              'Attempt to re-introduce server %s SID %s from [unknown@%s]',
                              $self->_state_sid_name($sid), $sid, $crec->{socket}[0],
                          ), qw[Notice s],
                      );
                      $errstr = 'Server ID already exists';
                  }
                  if ($errstr) {
                    $self->_terminate_conn_error($wheel_id, $errstr);
                    last SWITCH;
                  }
              }
              else {
                  $self->_terminate_conn_error($wheel_id, 'Incompatible TS version' );
                  last SWITCH;
              }
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
            $conn->{desc} = $params->[2] || '(unknown location)';

            if ( $conn->{desc} && $conn->{desc} =~ m!^\(H\) ! ) {
                $conn->{hidden} = 1;
                $conn->{desc} =~ s!^\(H\) !!;
            }

            if (!$conn->{ts_server}) {
                $self->_terminate_conn_error($wheel_id, 'Non-TS server.');
                last SWITCH;
            }
            my $result = $self->_state_auth_peer_conn($wheel_id,
                            $conn->{name}, $conn->{pass});
            if (!$result || $result <= 0) {
                my $errstr; my $snotice;
                if (!defined $result || $result == 0) {
                    $snotice = 'No entry for';
                    $errstr  = 'No connect {} block.';
                }
                elsif ($result == -1) {
                    $snotice = 'Bad password';
                    $errstr  = 'Invalid password.';
                }
                elsif ($result == -2) {
                    $snotice = 'Invalid certificate fingerprint';
                    $errstr  = 'Invalid certificate fingerprint.';
                }
                else {
                    $snotice = 'Invalid host';
                    $errstr  = 'Invalid host.';
                }
                $self->_send_to_realops(
                    sprintf(
                        'Unauthorized server connection attempt from [unknown@%s]: %s for server %s',
                        $conn->{socket}[0], $snotice, $conn->{name},
                    ),
                    'Notice', 's',
                );
                $self->_terminate_conn_error(
                    $wheel_id,
                    $errstr,
                );
                last SWITCH;
            }
            if ($self->state_peer_exists($conn->{name})) {
                $self->_send_to_realops(
                    sprintf(
                        'Attempt to re-introduce server %s from [unknown@%s]',
                        $conn->{name}, $conn->{socket}[0],
                    ), qw[Notice s],
                );
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
            my $nicklen = $self->server_config('NICKLEN');
            if (length($params->[0]) > $nicklen) {
                $params->[0] = substr($params->[0], 0, $nicklen);
            }

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

            if ( my $reason = $self->_state_is_resv( $params->[0], $wheel_id ) ) {
                $self->_send_output_to_client(
                    $wheel_id, {
                        prefix  => $self->server_name(),
                        command => '432',
                        params  => [
                            '*',
                            $params->[0],
                            $reason,
                        ],
                    }
                );
                last SWITCH;
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

    my $cmd     = uc $input->{command};
    my $params  = $input->{params};
    my $prefix  = $input->{prefix};
    my $sid = $self->server_sid();
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

        if ($cmd =~ /\d{3}/ && $params->[0] !~ m!^$sid!) {
            $self->send_output(
                $input,
                $self->_state_uid_route($params->[0]),
            );
            last SWITCH;
        }
        if ($cmd =~ /\d{3}/ && $params->[0] =~ m!^$sid!) {
            $input->{prefix} = $self->_state_sid_name($prefix);
            my $uid = $params->[0];
            $input->{params}[0] = $self->state_user_nick($uid);
            $self->send_output(
                $input,
                $self->_state_uid_route($uid),
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

        if ($cmd =~ /^(VERSION|TIME|LINKS|ADMIN|INFO|MOTD|STATS)$/i ) {
            my $client_method = '_daemon_peer_miscell';
            $client_method = '_daemon_peer_links' if $cmd eq 'LINKS';
            $self->_send_output_to_client(
                $conn_id,
                $prefix,
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_ )
            ) for $self->$client_method($cmd, $prefix, @$params);
            last SWITCH;
        }

        if ($cmd =~ /^(PING|PONG)$/i && $self->can($method)) {
            $self->$method($conn_id, $prefix, @{ $params });
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

        if ( $cmd =~ m!^E?TRACE$!i ) {
            $self->send_output( $_, $conn_id ) for
              $self->_daemon_peer_tracing($cmd, $conn_id, $prefix, @$params);
            last SWITCH;
        }

        # Chanmode and umode have distinct commands now
        # No need for check, MODE is always umode
        if ($cmd eq 'MODE') {
            $method = '_daemon_peer_umode';
        }

        if ($cmd =~ m!^(UN)?([DKX]LINE|RESV)$!i ) {
            $self->send_output( $_, $conn_id ) for
              $self->$method($conn_id, $prefix, @$params);
            last SWITCH;
        }

        if ($cmd =~ m!^WHO(IS|WAS)$!i ) {
            $self->send_output( $_, $conn_id ) for
              $self->$method($conn_id, $prefix, @$params);
            last SWITCH;
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
    my $uid  = $self->_client_uid($wheel_id);
    my $invalid = 0;
    my $pseudo  = 0;

    SWITCH: {
        my $method = '_daemon_cmd_' . lc $cmd;
        if ($cmd eq 'QUIT') {
            my $qmsg = $params->[0];
            delete $self->{state}{localops}{ $wheel_id };
            if ( $qmsg and my $msgtime = $self->{config}{anti_spam_exit_message_time} ) {
              $qmsg = '' if
                time - $self->{state}{conns}{$wheel_id}->{conn_time} < $msgtime;
            }
            $self->_terminate_conn_error(
                $wheel_id,
                ($qmsg ? qq{Quit: "$qmsg"} : 'Client Quit'),
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

            $self->_send_output_to_client($wheel_id, (ref $_ eq 'ARRAY' ? @{ $_ } : $_) )
                for $self->_daemon_cmd_umode($nick, @{ $params }[1..$#{ $params }]);
            last SWITCH;
        }

        if ($cmd eq 'CAP') {
            $self->_daemon_cmd_cap($wheel_id, @$params);
            last SWITCH;
        }

        if ( $cmd =~ m!^(ADMIN|INFO|VERSION|TIME|MOTD)$! ) {
            $self->_send_output_to_client(
                $wheel_id,
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_),
            ) for $self->_daemon_client_miscell($cmd, $nick, @$params);
            last SWITCH;
        }

        if ( $cmd =~ m!^E?TRACE$!i ) {
            $self->_send_output_to_client(
                $wheel_id,
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_),
            ) for $self->_daemon_client_tracing($cmd, $nick, @$params);
            last SWITCH;
        }

        if ($self->can($method)) {
            $self->_send_output_to_client(
                $wheel_id,
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_),
            ) for $self->$method($nick, @$params);
            last SWITCH;
        }

        if (defined $self->{config}{pseudo}{$cmd}) {
            $pseudo = 1;
            my $pseudo = $self->{config}{pseudo}{$cmd};
            if (!$params->[0]) {
                $self->_send_output_to_client($wheel_id, '412');
                last SWITCH;
            }
            my $targ = $self->state_user_nick($pseudo->{nick});
            my $serv = $self->_state_peer_name($pseudo->{host});
            if ( !$targ || !$serv ) {
                $self->_send_output_to_client($wheel_id, '440', $pseudo->{name});
                last SWITCH;
            }
            my $msg;
            if ($pseudo->{prepend}) {
                my $join = ($pseudo->{prepend} =~ m! $! ? '' : ' ');
                $msg = join $join, $pseudo->{prepend}, $params->[0];
            }
            else {
                $msg = $params->[0];
            }
            $self->_send_output_to_client(
                $wheel_id,
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_),
            ) for $self->_daemon_cmd_message($nick, 'PRIVMSG', $pseudo->{nick}, $msg);
            last SWITCH;
        }

        $invalid = 1;
        $self->_send_output_to_client($wheel_id, '421', $cmd);
    }

    return 1 if $invalid || $pseudo;
    $self->_state_cmd_stat($cmd, $input->{raw_line});
    return 1;
}

sub _daemon_cmd_help {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            my $lastuse = $self->{state}{lastuse}{help};
            my $pacewait = $self->{config}{pace_wait};
            if ( $lastuse && $pacewait && ( $lastuse + $pacewait ) > time() ) {
                push @$ref, ['263', 'HELP'];
                last SWITCH;
            }
            $self->{state}{lastuse}{help} = time();
        }
        my $item = shift @$args || 'index';
        if (!$self->{_help}) {
            require POE::Component::Server::IRC::Help;
            $self->{_help} = POE::Component::Server::IRC::Help->new();
        }
        $item = lc $item;
        my @lines = $self->{_help}->topic($item);
        if (!scalar @lines) {
            push @$ref, [ '524', $item ];
            last SWITCH;
        }
        my $reply = '704';
        foreach my $line (@lines) {
            push @$ref, {
                prefix  => $server,
                command => $reply,
                params  => [
                    $nick,
                    $item,
                    $line,
                ],
            };
            $reply = '705';
        }
        push @$ref, {
            prefix  => $server,
            command => '706',
            params  => [
               $nick,
               $item,
               'End of /HELP.',
            ],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_watch {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$count) {
            $args->[0] = 'l';
        }
        my $uid = $self->state_user_uid($nick);
        my $watches = $self->{state}{uids}{$uid}{watches} || { };
        my $list = 0;
        ITEM: foreach my $item ( split m!,!, $args->[0] ) {
            if ( $item =~ m!^\+! ) {
               $item =~ s!^\+!!;
               if ( keys %$watches >= $self->{config}{max_watch} ) {
                  push @$ref, ['512', $self->{config}{max_watch}];
                  next ITEM;
               }
               next ITEM if !$item || !is_valid_nick_name($item);
               # Add_to_watch_list
               $watches->{uc_irc $item} = $item;
               $self->{state}{watches}{uc_irc $item}{uids}{$uid} = 1;
               # Show_watch possible refactor here
               if ( my $tuid = $self->state_user_uid($item) ) {
                  my $rec = $self->{state}{uids}{$tuid};
                  push @$ref, {
                      prefix  => $server,
                      command => '604',
                      params  => [
                          $nick,
                          $rec->{nick},
                          $rec->{auth}{ident},
                          $rec->{auth}{hostname},
                          $rec->{ts},
                          'is online',
                      ],
                  };
               }
               else {
                  my $laston = $self->{state}{watches}{uc_irc $item}{laston} || 0;
                  push @$ref, {
                      prefix  => $server,
                      command => '605',
                      params  => [
                          $nick, $item, '*', '*', $laston, 'is offline'
                      ],
                  };
               }
               next ITEM;
            }
            if ( $item =~ m!^\-! ) {
               $item =~ s!^\-!!;
               next ITEM if !$item;
               $item = uc_irc $item;
               my $pitem = delete $watches->{$item};
               delete $self->{state}{watches}{$item}{uids}{$uid};
               if ( my $tuid = $self->state_user_uid($item) ) {
                  my $rec = $self->{state}{uids}{$tuid};
                  push @$ref, {
                      prefix  => $server,
                      command => '602',
                      params  => [
                          $nick,
                          $rec->{nick},
                          $rec->{auth}{ident},
                          $rec->{auth}{hostname},
                          $rec->{ts},
                          'stopped watching',
                      ],
                  };
               }
               else {
                  my $laston = $self->{state}{watches}{$item}{laston} || 0;
                  push @$ref, {
                      prefix  => $server,
                      command => '602',
                      params  => [
                          $nick, $pitem, '*', '*', $laston, 'stopped watching'
                      ],
                  };
               }
               delete $self->{state}{watches}{$item}
                  if !keys %{ $self->{state}{watches}{$item}{uids} };
               next ITEM;
            }
            if ( $item =~ m!^C!i ) {
               foreach my $watched ( keys %$watches ) {
                  delete $self->{state}{watches}{$watched}{uids}{$uid};
                  delete $self->{state}{watches}{$watched}
                    if !keys %{ $self->{state}{watches}{$watched}{uids} };
               }
               $watches = { };
               next ITEM;
            }
            if ( $item =~ m!^S!i ) {
               next ITEM if $list & 0x1;
               $item = substr $item, 0, 1;
               $list |= 0x1;
               my @watching = sort keys %$watches;
               my $wcount = 0;
               my $mcount = @watching;
               if ( defined $self->{state}{watches}{uc_irc $nick} ) {
                  $wcount = keys %{ $self->{state}{watches}{uc_irc $nick}{uids} };
               }
               push @$ref, {
                   prefix  => $server,
                   command => '603',
                   params  => [
                        $nick,
                        "You have $mcount and are on $wcount WATCH entries",
                   ],
               };
               my $len = length($server) + length($nick) + 8;
               my $buf = '';
               WATCHED: foreach my $watched ( @watching ) {
                   $watched = $watches->{$watched};
                   if (length(join ' ', $buf, $watched)+$len+1 > 510) {
                      push @$ref, {
                          prefix  => $server,
                          command => '606',
                          params  => [ $nick, $buf ],
                      };
                      $buf = $watched;
                      next WATCHED;
                   }
                   $buf = join ' ', $buf, $watched;
                   $buf =~ s!^\s+!!;
               }
               if ($buf) {
                   push @$ref, {
                       prefix  => $server,
                       command => '606',
                       params  => [ $nick, $buf ],
                   };
               }
               push @$ref, {
                   prefix  => $server,
                   command => '607',
                   params  => [
                         $nick,
                         "End of WATCH $item",
                   ],
               };
               next ITEM;
            }
            if ( $item =~ m!^L!i ) {
               next ITEM if $list & 0x2;
               $item = substr $item, 0, 1;
               $list |= 0x2;
               foreach my $watched ( keys %$watches ) {
                  if ( my $tuid = $self->state_user_uid($watched) ) {
                      my $rec = $self->{state}{uids}{$tuid};
                      push @$ref, {
                          prefix  => $server,
                          command => '604',
                          params  => [
                              $nick,
                              $rec->{nick},
                              $rec->{auth}{ident},
                              $rec->{auth}{hostname},
                              $rec->{ts},
                              'is online',
                          ],
                      };
                  }
                  elsif ( $item eq 'L' ) {
                      push @$ref, {
                          prefix  => $server,
                          command => '605',
                          params  => [
                              $nick, $watches->{$watched}, '*', '*', 0, 'is offline'
                          ],
                      };
                  }
               }
               push @$ref, {
                   prefix  => $server,
                   command => '607',
                   params  => [
                        $nick,
                        "End of WATCH $item",
                   ],
               };
               next ITEM;
            }
        }
        $self->{state}{uids}{$uid}{watches} = $watches;
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_cap {
    my $self     = shift;
    my $wheel_id = shift || return;
    my $subcmd   = shift;
    my $args     = [@_];
    my $server   = $self->server_name();

    my $registered = $self->_connection_registered($wheel_id);

    SWITCH: {
        if (!$subcmd) {
          $self->_send_output_to_client($wheel_id, '461', 'CAP');
          last SWITCH;
        }
        $subcmd = uc $subcmd;
        if( $subcmd !~ m!^(LS|LIST|REQ|ACK|NAK|CLEAR|END)$! ) {
          $self->_send_output_to_client($wheel_id, '410', $subcmd);
          last SWITCH;
        }
        if ( $subcmd eq 'END' && $registered  ) { #NOOP
          last SWITCH;
        }
        if ( $subcmd eq 'END' && !$registered ) {
          my $capneg = delete $self->{state}{conns}{$wheel_id}{capneg};
          $self->_client_register($wheel_id) if $capneg;
          last SWITCH;
        }
        $self->{state}{conns}{$wheel_id}{capneg} = 1 if !$registered && $subcmd =~ m!^(LS|REQ)$!;
        if ( $subcmd eq 'LS' ) {
          my $output = {
              prefix  => $server,
              command => 'CAP',
              params  => [ $self->_client_nickname($wheel_id), $subcmd, ],
          };
          push @{ $output->{params} }, join ' ', sort keys %{ $self->{state}{caps} };
          $self->_send_output_to_client($wheel_id, $output);
          last SWITCH;
        }
        if ( $subcmd eq 'LIST' ) {
          my $output = {
              prefix  => $server,
              command => 'CAP',
              params  => [ $self->_client_nickname($wheel_id), $subcmd, ],
          };
          push @{ $output->{params} }, join ' ', sort keys %{ $self->{state}{conns}{$wheel_id}{caps} };
          $self->_send_output_to_client($wheel_id, $output);
          last SWITCH;
        }
        if ( $subcmd eq 'REQ' ) {
          foreach my $cap ( split ' ', $args->[0] ) {
             my $ocap = $cap;
             my $neg = $cap =~ s!^\-!!;
             $cap = lc $cap;
             if ( !$self->{state}{caps}{$cap} ) {
                my $output = {
                    prefix  => $server,
                    command => 'CAP',
                    params  => [ $self->_client_nickname($wheel_id), 'NAK', $args->[0] ],
                };
                $self->_send_output_to_client($wheel_id, $output);
                last SWITCH;
             }
             if ( $neg ) {
               delete $self->{state}{conns}{$wheel_id}{caps}{$cap};
             }
             else {
               $self->{state}{conns}{$wheel_id}{caps}{$cap} = 1;
             }
          }
          my $output = {
             prefix  => $server,
             command => 'CAP',
             params  => [ $self->_client_nickname($wheel_id), 'ACK', $args->[0] ],
          };
          $self->_send_output_to_client($wheel_id, $output);
          last SWITCH;
        }
    }

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
        my $uid         = $self->state_user_uid($nick);
        my $sid         = $self->server_sid();
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
                    && $targs->{$target}[1] =~ /\x2E[^.]*[\x2A\x3F]+[^.]*$/) {
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
                        prefix  => $uid,
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
                        prefix  => $uid,
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
                            prefix  => $uid,
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
            if ($channel) {
                my $res = $self->state_can_send_to_channel($nick,$channel,$args->[1],$type);
                if ( !$res ) {
                    next LOOP;
                }
                elsif ( ref $res eq 'ARRAY' ) {
                    push @$ref, $res;
                    next LOOP;
                }
                if ( $res != 2 && $self->state_flood_attack_channel($nick,$channel,$type) ) {
                    next LOOP;
                }
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
                    $msg->{prefix} = $uid;
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

                # Flood check
                next LOOP if $self->state_flood_attack_client($nick,$target,$type);

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
                    my $targ_uid = $targ_rec->{uid};
                    my $local = $targ_uid =~ m!^sid!;
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
                                    prefix  => ( $local ? $server : $sid ),
                                    command => '718',
                                    params => [
                                        ( $local ? $target : $targ_uid ),
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

                my $targ_uid = $self->state_user_uid($target);
                my $msg = {
                    prefix  => $uid,
                    command => $type,
                    params  => [$targ_uid, $args->[1]],
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
                        $msg->{params}[0] = $target;
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
    my $qmsg = shift;
    my $ref  = [ ];
    my $name = uc $self->server_name();
    my $sid  = $self->server_sid();

    $nick = uc_irc($nick);
    my $record = delete $self->{state}{peers}{$name}{users}{$nick};
    $qmsg = 'Client Quit' if !$qmsg;
    my $full = $record->{full}->();
    delete $self->{state}{peers}{$name}{uids}{ $record->{uid} };
    my $uid = $record->{uid};
    $self->send_output(
        {
            prefix  => $uid,
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

    # Remove from peoples accept lists
    for my $user (keys %{ $record->{accepts} }) {
        delete $self->{state}{users}{$user}{accepts}{uc_irc($nick)};
    }

    if ( defined $self->{state}{watches}{$nick} ) {
        my $laston = time();
        $self->{state}{watches}{$nick}{laston} = $laston;
        foreach my $wuid ( keys %{ $self->{state}{watches}{$nick}{uids} } ) {
            next if !defined $self->{state}{uids}{$wuid};
            my $wrec = $self->{state}{uids}{$wuid};
            $self->send_output(
                {
                    prefix  => $record->{server},
                    command => '601',
                    params  => [
                         $wrec->{nick},
                         $record->{nick},
                         $record->{auth}{ident},
                         $record->{auth}{hostname},
                         $laston,
                         'logged offline',
                    ],
                },
                $wrec->{route_id},
            );
        }
    }
    # clear WATCH list
    foreach my $watched ( keys %{ $record->{watches} } ) {
       delete $self->{state}{watches}{$watched}{uids}{$uid};
       delete $self->{state}{watches}{$watched}
          if !keys %{ $self->{state}{watches}{$watched}{uids} };
    }

    # Okay, all 'local' users who share a common channel with user.
    my $common = { };
    for my $uchan (keys %{ $record->{chans} }) {
        delete $self->{state}{chans}{$uchan}{users}{$uid};
        for my $user ( keys %{ $self->{state}{chans}{$uchan}{users} } ) {
            next if $user !~ m!^$sid!;
            $common->{$user} = $self->_state_uid_route($user);
        }

        if (!keys %{ $self->{state}{chans}{$uchan}{users} }) {
            delete $self->{state}{chans}{$uchan};
        }
    }

    push @$ref, $common->{$_} for keys %$common;
    $self->{state}{stats}{ops_online}-- if $record->{umode} =~ /o/;
    $self->{state}{stats}{invisible}-- if $record->{umode} =~ /i/;
    delete $self->{state}{users}{$nick} if !$record->{nick_collision};
    delete $self->{state}{uids}{ $record->{uid} };
    delete $self->{state}{localops}{$record->{route_id}};
    unshift @{ $self->{state}{whowas}{$nick} }, {
        logoff  => time(),
        account => $record->{account},
        nick    => $record->{nick},
        user    => $record->{auth}{ident},
        host    => $record->{auth}{hostname},
        real    => $record->{auth}{realhost},
        sock    => $record->{socket}[0],
        ircname => $record->{ircname},
        server  => $name,
    };
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_ping {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
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
            my $target = $self->_state_peer_sid($args->[1]);
            $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => 'PING',
                    params  => [$nick, $target],
                },
                $self->_state_sid_route($target),
            );
            last SWITCH;
        }
        push @$ref, {
            prefix  => $sid,
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
            my $target = $self->_state_peer_sid($args->[1]);
            $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => 'PONG',
                    params  => [$nick, $target],
                },
                $self->_state_sid_route($target),
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
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        last SWITCH if $self->state_user_is_operator($nick);
        if (!$count || $count < 2) {
            push @$ref, ['461', 'OPER'];
            last SWITCH;
        }

        my $record = $self->{state}{users}{uc_irc($nick)};
        my $result = $self->_state_o_line($nick, @$args);
        if (!$result || $result <= 0) {
            my $omsg; my $errcode = '491';
            if (!defined $result) {
                $omsg = 'no operator {} block';
            }
            elsif ($result == -1) {
                $omsg = 'password mismatch';
                $errcode = '464';
            }
            elsif ($result == -2) {
                $omsg = 'requires SSL/TLS';
            }
            elsif ($result == -3) {
                $omsg = 'client certificate fingerprint mismatch';
            }
            else {
                $omsg = 'host mismatch';
            }
            $self->_send_to_realops(
                sprintf(
                  'Failed OPER attempt as %s by %s (%s) - %s',
                  $args->[0], $nick, (split /!/, $record->{full}->())[1], $omsg),
                'Notice',
                's',
            );
            push @$ref, [$errcode];
            last SWITCH;
        }
        my $opuser = $args->[0];
        $self->{stats}{ops}++;
        $record->{umode} .= 'o';
        $record->{opuser} = $opuser;
        $self->{state}{stats}{ops_online}++;
        push @$ref, {
            prefix  => $server,
            command => '381',
            params  => [$nick, 'You are now an IRC operator'],
        };

        my @peers = $self->_state_connected_peers();

        if (my $whois = $self->{config}{ops}{$opuser}{whois}) {
            $record->{svstags}{313} = {
                numeric => '313',
                umodes  => '+',
                tagline => $whois,
            };
            $self->send_output(
              {
                prefix  => $sid,
                command => 'SVSTAG',
                params  => [
                  $record->{uid},
                  $record->{ts},
                  '313', '+', $whois,
                ],
              },
              @peers,
            );
        }

        my $umode = $self->{config}{ops}{$opuser}{umode} || $self->{config}{oper_umode};
        $record->{umode} .= $umode;
        $umode .= 'o';
        $umode = join '', sort split //, $umode;

        my $uid  = $record->{uid};
        my $full = $record->{full}->();

        my $notice = sprintf("%s{%s} is now an operator",$full,$opuser);

        $self->send_output(
          {
            prefix  => $sid,
            command => 'GLOBOPS',
            params  => [ $notice ],
          },
          @peers,
        );

        $self->_send_to_realops( $notice );

        my $reply = {
            prefix  => $uid,
            command => 'MODE',
            params  => [$uid, "+$umode"],
        };

        $self->send_output(
            $reply,
            @peers,
        );
        $self->send_event(
            "daemon_umode",
            $full,
            "+$umode",
        );


        my $route_id = $record->{route_id};
        $self->{state}{localops}{$route_id} = time;
        $self->antiflood($route_id, 0);
        $reply->{prefix} = $full;
        $reply->{params}[0] = $record->{nick};
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

sub _daemon_cmd_close {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['723','close'];
            last SWITCH;
        }
        $self->send_event("daemon_close", $nick);
        my $count = 0;
        foreach my $conn_id ( keys %{ $self->{state}{conns} } ) {
            next if $self->{state}{conns}{$conn_id}{type} ne 'u';
            my $crec = $self->{state}{conns}{$conn_id};
            push @$ref, {
                prefix  => $server,
                command => '362',
                params  => [
                    $nick,
                    sprintf(
                      '%s[%s@%s]',
                      ( $crec->{name} || $crec->{nick} || '' ),
                      ( $crec->{user} || 'unknown' ),
                      $crec->{socket}[0],
                    ),
                    'Closed: status = unknown',
                ],
            };
            $count++;
            $self->_terminate_conn_error($conn_id,'Oper Closing');
        }
        push @$ref, {
            prefix  => $server,
            command => '363',
            params  => [
                $nick,
                $count,
                'Connections closed',
            ],
        };
    }
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_set {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    my %vars = (
      FLOODCOUNT    => sub {
          my $val = shift;
          if ( $val && $val >= 0 ) {
              $self->{config}{floodcount} = $val;
              $self->_send_to_realops(
                  sprintf(
                    '%s has changed FLOODCOUNT to %s',
                    $self->state_user_full($nick,1), $val,
                  ), qw[Notice s],
              );
          }
          else {
              push @$ref, {
                  prefix  => $server,
                  command => 'NOTICE',
                  params  => [
                      $nick,
                      sprintf(
                          'FLOODCOUNT is currently %s',
                          $self->{config}{floodcount},
                      ),
                  ],
              };
          }
      },
      FLOODTIME     => sub {
          my $val = shift;
          if ( $val && $val >= 0 ) {
              $self->{config}{floodtime} = $val;
              $self->_send_to_realops(
                  sprintf(
                    '%s has changed FLOODTIME to %s',
                    $self->state_user_full($nick,1), $val,
                  ), qw[Notice s],
              );
          }
          else {
              push @$ref, {
                  prefix  => $server,
                  command => 'NOTICE',
                  params  => [
                      $nick,
                      sprintf(
                          'FLOODTIME is currently %s',
                          $self->{config}{floodtime},
                      ),
                  ],
              };
          }
      },
      IDENTTIMEOUT  => sub {
          my $val = shift;
          if ( $val && $val >= 0 ) {
              $self->{config}{ident_timeout} = $val;
              $self->_send_to_realops(
                  sprintf(
                    '%s has changed IDENTTIMEOUT to %s',
                    $self->state_user_full($nick,1), $val,
                  ), qw[Notice s],
              );
          }
          else {
              push @$ref, {
                  prefix  => $server,
                  command => 'NOTICE',
                  params  => [
                      $nick,
                      sprintf(
                          'IDENTTIMEOUT is currently %s',
                          ( $self->{config}{ident_timeout} || 10 ),
                      ),
                  ],
              };
          }
      },
      MAX           =>  sub {
          my $val = shift;
          if ( $val && $val >= 0 ) {
              if ( $val > 7000 ) {
                  push @$ref, {
                      prefix  => $server,
                      command => 'NOTICE',
                      params  => [
                          $nick,
                          sprintf(
                              'You cannot set MAXCLIENTS to > 7000, restoring to %u',
                              $self->{config}{MAXCLIENTS},
                          ),
                      ],
                  };
                  return;
              }
              if ( $val < 32 ) {
                  push @$ref, {
                      prefix  => $server,
                      command => 'NOTICE',
                      params  => [
                          $nick,
                          sprintf(
                              'You cannot set MAXCLIENTS to < 32, restoring to %u',
                              $self->{config}{MAXCLIENTS},
                          ),
                      ],
                  };
                  return;
              }
              $self->{config}{MAXCLIENTS} = $val;
              $self->_send_to_realops(
                  sprintf(
                    '%s has changed MAXCLIENTS to %s',
                    $self->state_user_full($nick,1), $val,
                  ), qw[Notice s],
              );
          }
          else {
              push @$ref, {
                  prefix  => $server,
                  command => 'NOTICE',
                  params  => [
                      $nick,
                      sprintf(
                          'MAXCLIENTS is currently %s',
                          $self->{config}{MAXCLIENTS},
                      ),
                  ],
              };
          }
      },
      SPAMNUM       => sub {
          my $val = shift;
          if ( defined $val && $val >= 0 ) {
              $self->{config}{MAX_JOIN_LEAVE_COUNT} = $val;
              if ( $val == 0 ) {
                  $self->_send_to_realops(
                      sprintf(
                        '%s has disabled ANTI_SPAMBOT',
                        $self->state_user_full($nick,1),
                      ), qw[Notice s],
                  );
              }
              else {
                  $self->_send_to_realops(
                      sprintf(
                        '%s has changed SPAMNUM to %s',
                        $self->state_user_full($nick,1), $val,
                      ), qw[Notice s],
                  );
              }
          }
          else {
              push @$ref, {
                  prefix  => $server,
                  command => 'NOTICE',
                  params  => [
                      $nick,
                      sprintf(
                          'SPAMNUM is currently %s',
                          $self->{config}{MAX_JOIN_LEAVE_COUNT},
                      ),
                  ],
              };
          }
      },
      SPAMTIME      => sub {
          my $val = shift;
          if ( $val && $val >= 0 ) {
              $self->{config}{MIN_JOIN_LEAVE_TIME} = $val;
              $self->_send_to_realops(
                  sprintf(
                    '%s has changed SPAMTIME to %s',
                    $self->state_user_full($nick,1), $val,
                  ), qw[Notice s],
              );
          }
          else {
              push @$ref, {
                  prefix  => $server,
                  command => 'NOTICE',
                  params  => [
                      $nick,
                      sprintf(
                          'SPAMTIME is currently %s',
                          $self->{config}{MIN_JOIN_LEAVE_TIME},
                      ),
                  ],
              };
          }
      },
      JFLOODTIME    => sub {
          my $val = shift;
          if ( $val && $val >= 0 ) {
              $self->{config}{joinfloodtime} = $val;
              $self->_send_to_realops(
                  sprintf(
                    '%s has changed JFLOODTIME to %s',
                    $self->state_user_full($nick,1), $val,
                  ), qw[Notice s],
              );
          }
          else {
              push @$ref, {
                  prefix  => $server,
                  command => 'NOTICE',
                  params  => [
                      $nick,
                      sprintf(
                          'JFLOODTIME is currently %s',
                          $self->{config}{joinfloodtime},
                      ),
                  ],
              };
          }
      },
      JFLOODCOUNT   => sub {
          my $val = shift;
          if ( $val && $val >= 0 ) {
              $self->{config}{joinfloodcount} = $val;
              $self->_send_to_realops(
                  sprintf(
                    '%s has changed JFLOODCOUNT to %s',
                    $self->state_user_full($nick,1), $val,
                  ), qw[Notice s],
              );
          }
          else {
              push @$ref, {
                  prefix  => $server,
                  command => 'NOTICE',
                  params  => [
                      $nick,
                      sprintf(
                          'JFLOODCOUNT is currently %s',
                          $self->{config}{joinfloodcount},
                      ),
                  ],
              };
          }
      },
    );

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if ($count > 0) {
            if ( defined $vars{ uc $args->[0] } ) {
                $vars{ uc $args->[0] }->( $args->[1] );
                last SWITCH;
            }
            push @$ref, {
                prefix  => $server,
                command => 'NOTICE',
                params  => [
                    $nick,
                    'Variable not found.',
                ],
            };
            last SWITCH;
        }
        push @$ref, {
            prefix  => $server,
            command => 'NOTICE',
            params  => [
                $nick,
                'Available QUOTE SET commands:',
            ],
        };
        my @names;
        foreach my $var ( sort keys %vars ) {
            push @names, $var;
            if ( scalar @names == 4 ) {
                push @$ref, {
                    prefix  => $server,
                    command => 'NOTICE',
                    params  => [
                        $nick,
                        join(' ',@names),
                    ],
                };
                @names = ();
            }
        }
        if (@names) {
            push @$ref, {
                prefix  => $server,
                command => 'NOTICE',
                params  => [
                    $nick,
                    join(' ',@names),
                ],
            };
        }
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
            push @$ref, ['723', 'locops'];
            last SWITCH;
        }
        if (!$count) {
            push @$ref, ['461', 'LOCOPS'];
            last SWITCH;
        }
        my $full = $self->state_user_full($nick,1);
        $self->_send_to_realops( "from $nick: " . $args->[0], 'locops', 'l' );
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
            push @$ref, ['723', 'wallops'];
            last SWITCH;
        }
        if (!$count) {
            push @$ref, ['461', 'WALLOPS'];
            last SWITCH;
        }

        my $full = $self->state_user_full($nick);
        my $uid  = $self->state_user_uid($nick);

        $self->send_output(
            {
                prefix  => $uid,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            $self->_state_connected_peers(),
        );

        $self->send_output(
            {
                prefix  => $full,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            keys %{ $self->{state}{wallops} },
        );

        $self->send_event("daemon_wallops", $full, $args->[0]);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_globops {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['723', 'globops'];
            last SWITCH;
        }
        if (!$count) {
            push @$ref, ['461', 'GLOBOPS'];
            last SWITCH;
        }

        $self->send_output(
            {
                prefix  => $self->state_user_uid($nick),
                command => 'GLOBOPS',
                params  => [ $args->[0] ],
            },
            $self->_state_connected_peers(),
        );

        my $msg  = "from $nick: " . $args->[0];

        $self->_send_to_realops(
            $msg,
            'Globops',
            's',
        );

        $self->send_event("daemon_globops", $nick, $args->[0]);
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

        my $conn_id = $self->_state_peer_route($peer);

        if ( !grep { $_ eq $peer }
                keys %{ $self->{state}{peers}{uc $server}{peers} }) {
            $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => 'SQUIT',
                    params  => [ $self->_state_peer_sid($peer), $reason ],
                },
                $conn_id,
            );
            last SWITCH;
        }

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
        my $reason;

        {
            if (!$reason) {
                $reason = pop @$args || '<No reason supplied>';
            }
            $self->send_event(
                "daemon_rkline",
                $full,
                $server,
                $duration,
                $user,
                $host,
                $reason,
            );

            last SWITCH if !$self->_state_add_drkx_line( 'rkline', $full, time(),
                                                         $server, $duration * 60,
                                                         $user, $host, $reason );

            my $temp = $duration ? "temporary $duration min. " : '';

            my $reply_notice = "Added ${temp}RK-Line [$user\@host]";
            my $locop_notice = "$full added ${temp}RK-Line for [$user\@$host] [$reason]";

            push @$ref, {
                prefix  => $server,
                command => 'NOTICE',
                params  => [ $nick, $reply_notice ],
            };

            $self->_send_to_realops( $locop_notice, 'Notice', 's' );

            $self->_state_do_local_users_match_rkline($user, $host, $reason);
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_unrkline {
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
        if (!$count || $count < 1) {
            push @$ref, ['461', 'UNRKLINE'];
            last SWITCH;
        }
        my ($user, $host) = split /\@/, $args->[0];
        if (!$user || !$host) {
            last SWITCH;
        }

        my $result = $self->_state_del_drkx_line( 'rkline', $user, $host );

        if ( !$result ) {
           push @$ref, { prefix => $server, command => 'NOTICE', params => [ $nick, "No RK-Line for [$user\@$host] found" ] };
           last SWITCH;
        }

        my $full = $self->state_user_full($nick);

        $self->send_event(
            "daemon_unrkline", $full, $server, $user, $host,
        );

        push @$ref, {
            prefix  => $server,
            command => 'NOTICE',
            params  => [ $nick, "RK-Line for [$user\@$host] is removed" ],
        };

        $self->_send_to_realops( "$full has removed the RK-Line for: [$user\@$host]", 'Notice', 's' );
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
            my $on  = shift @$args;
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
                    prefix  => $self->state_user_uid($nick),
                    command => 'KLINE',
                    params  => [
                        $target,
                        $duration * 60,
                        $user,
                        $host,
                        $reason,
                    ],
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

            last SWITCH if !$self->_state_add_drkx_line( 'kline', $full, time(), $server,
                                                         $duration * 60, $user, $host, $reason );
            $self->send_event(
                "daemon_kline",
                $full,
                $target,
                $duration,
                $user,
                $host,
                $reason,
            );

            my $temp = $duration ? "temporary $duration min. " : '';

            my $reply_notice = "Added ${temp}K-Line [$user\@host]";
            my $locop_notice = "$full added ${temp}K-Line for [$user\@$host] [$reason]";

            push @$ref, {
                prefix  => $server,
                command => 'NOTICE',
                params  => [ $nick, $reply_notice ],
            };

            $self->_send_to_realops( $locop_notice, 'Notice', 's' );

            $self->_state_do_local_users_match_kline($user, $host, $reason);
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
            my $target = $args->[3];
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
                    prefix   => $self->state_user_uid($nick),
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

        last SWITCH if !$us;

        my $target = $args->[3] || $server;

        my $result = $self->_state_del_drkx_line( 'kline', $user, $host );

        if ( !$result ) {
           push @$ref, { prefix => $server, command => 'NOTICE', params => [ $nick, "No K-Line for [$user\@$host] found" ] };
           last SWITCH;
        }

        $self->send_event(
            "daemon_unkline", $full, $target, $user, $host,
        );

        push @$ref, {
            prefix  => $server,
            command => 'NOTICE',
            params  => [ $nick, "K-Line for [$user\@$host] is removed" ],
        };

        $self->_send_to_realops( "$full has removed the K-Line for: [$user\@$host]", 'Notice', 's' );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_resv {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count || $count < 2) {
            push @$ref, ['461', 'RESV'];
            last SWITCH;
        }
        my $duration = 0;
        if ($args->[0] =~ /^\d+$/) {
            $duration = shift @$args;
            $duration = 14400 if $duration > 14400;
        }
        my $mask = shift @$args;
        if (!$mask) {
            push @$ref, ['461', 'RESV'];
            last SWITCH;
        }
        if ($args->[0] && uc $args->[0] eq 'ON'
                && scalar @$args < 2) {
            push @$ref, ['461', 'RESV'];
            last SWITCH;
        }
        my ($peermask,$reason);
        my $us = 0;
        if ($args->[0] && uc $args->[0] eq 'ON') {
          my $on = shift @$args;
          $peermask = shift @$args;
          $reason  = shift @$args || '<No reason supplied>';
          my %targpeers; my $ucserver = uc $server;
          foreach my $peer ( keys %{ $self->{state}{peers} } ) {
             if (matches_mask($peermask, $peer)) {
                if ($ucserver eq $peer) {
                   $us = 1;
                }
                else {
                   $targpeers{ $self->_state_peer_route($peer) }++;
                }
             }
          }
          $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => 'RESV',
                    params  => [
                        $peermask,
                        ( $duration * 60 ),
                        $mask,
                        $reason,
                    ],
                },
                grep { $self->_state_peer_capab($_, 'CLUSTER') } keys %targpeers,
            );
        }
        else {
          $us = 1;
        }

        last SWITCH if !$us;

        if ( $self->_state_have_resv($mask) ) {
           push @$ref, {
              prefix  => $server,
              command => 'NOTICE',
              params  => [ $nick, "A RESV has already been placed on: $mask" ],
          };
          last SWITCH;
        }

        if ( !$reason ) {
          $reason = shift @$args || '<No reason supplied>';
        }

        my $full = $self->state_user_full($nick);

        last SWITCH if !$self->_state_add_drkx_line( 'resv', $full, time(), $server,
                                                     $duration * 60, $mask, $reason );
        $self->send_event(
            "daemon_resv",
            $full,
            $mask,
            $duration,
            $reason,
        );

        my $temp = $duration ? "temporary $duration min. " : '';

        my $reply_notice = "Added ${temp}RESV [$mask]";
        my $locop_notice = "$full added ${temp}RESV for [$mask] [$reason]";

        push @$ref, {
            prefix  => $server,
            command => 'NOTICE',
            params  => [ $nick, $reply_notice ],
        };

        $self->_send_to_realops( $locop_notice, 'Notice', 's' );

    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_unresv {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count ) {
            push @$ref, ['461', 'UNRESV'];
            last SWITCH;
        }
        my $unmask = shift @$args;
        if ($args->[0] && uc $args->[0] eq 'ON'
                && scalar @$args < 2) {
            push @$ref, ['461', 'UNRESV'];
            last SWITCH;
        }
        my $us = 0;
        if ($args->[0] && uc $args->[0] eq 'ON') {
          my $on = shift @$args;
          my $peermask = shift @$args;
          my %targpeers; my $ucserver = uc $server;
          foreach my $peer ( keys %{ $self->{state}{peers} } ) {
             if (matches_mask($peermask, $peer)) {
                if ($ucserver eq $peer) {
                   $us = 1;
                }
                else {
                   $targpeers{ $self->_state_peer_route($peer) }++;
                }
             }
          }
          $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => 'UNRESV',
                    params  => [
                        $peermask,
                        $unmask,
                    ],
                    colonify => 0,
                },
                grep { $self->_state_peer_capab($_, 'CLUSTER') } keys %targpeers,
            );
        }
        else {
          $us = 1;
        }

        last SWITCH if !$us;

        my $result = $self->_state_del_drkx_line( 'resv', $unmask );

        if ( !$result ) {
           push @$ref, { prefix => $server, command => 'NOTICE', params => [ $nick, "No RESV for [$unmask] found" ] };
           last SWITCH;
        }

        my $full = $self->state_user_full($nick);
        $self->send_event(
            "daemon_unresv",
            $full,
            $unmask,
        );

        push @$ref, {
            prefix  => $server,
            command => 'NOTICE',
            params  => [ $nick, "RESV for [$unmask] is removed" ],
        };

        $self->_send_to_realops( "$full has removed the RESV for: [$unmask]", 'Notice', 's' );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_xline {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count || $count < 2) {
            push @$ref, ['461', 'XLINE'];
            last SWITCH;
        }
        my $duration = 0;
        if ($args->[0] =~ /^\d+$/) {
            $duration = shift @$args;
            $duration = 14400 if $duration > 14400;
        }
        my $mask = shift @$args;
        if (!$mask) {
            push @$ref, ['461', 'XLINE'];
            last SWITCH;
        }
        if ($args->[0] && uc $args->[0] eq 'ON'
                && scalar @$args < 2) {
            push @$ref, ['461', 'XLINE'];
            last SWITCH;
        }
        my ($peermask,$reason);
        my $us = 0;
        if ($args->[0] && uc $args->[0] eq 'ON') {
          my $on = shift @$args;
          $peermask = shift @$args;
          $reason  = shift @$args || '<No reason supplied>';
          my %targpeers; my $ucserver = uc $server;
          foreach my $peer ( keys %{ $self->{state}{peers} } ) {
             if (matches_mask($peermask, $peer)) {
                if ($ucserver eq $peer) {
                   $us = 1;
                }
                else {
                   $targpeers{ $self->_state_peer_route($peer) }++;
                }
             }
          }
          $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => 'XLINE',
                    params  => [
                        $peermask,
                        ( $duration * 60 ),
                        $mask,
                        $reason,
                    ],
                },
                grep { $self->_state_peer_capab($_, 'CLUSTER') } keys %targpeers,
            );
        }
        else {
          $us = 1;
        }

        last SWITCH if !$us;

        if ( !$reason ) {
          $reason = shift @$args || '<No reason supplied>';
        }

        my $full = $self->state_user_full($nick);

        last SWITCH if !$self->_state_add_drkx_line( 'xline', $full, time(), $server,
                                                     $duration * 60, $mask, $reason );
        $self->send_event(
            "daemon_xline",
            $full,
            $mask,
            $duration,
            $reason,
        );

        my $temp = $duration ? "temporary $duration min. " : '';

        my $reply_notice = "Added ${temp}X-Line [$mask]";
        my $locop_notice = "$full added ${temp}X-Line for [$mask] [$reason]";

        push @$ref, {
            prefix  => $server,
            command => 'NOTICE',
            params  => [ $nick, $reply_notice ],
        };

        $self->_send_to_realops( $locop_notice, 'Notice', 's' );

        $self->_state_do_local_users_match_xline($mask,$reason);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_unxline {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count ) {
            push @$ref, ['461', 'UNXLINE'];
            last SWITCH;
        }
        my $unmask = shift @$args;
        if ($args->[0] && uc $args->[0] eq 'ON'
                && scalar @$args < 2) {
            push @$ref, ['461', 'UNXLINE'];
            last SWITCH;
        }
        my $us = 0;
        if ($args->[0] && uc $args->[0] eq 'ON') {
          my $on = shift @$args;
          my $peermask = shift @$args;
          my %targpeers; my $ucserver = uc $server;
          foreach my $peer ( keys %{ $self->{state}{peers} } ) {
             if (matches_mask($peermask, $peer)) {
                if ($ucserver eq $peer) {
                   $us = 1;
                }
                else {
                   $targpeers{ $self->_state_peer_route($peer) }++;
                }
             }
          }
          $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => 'UNXLINE',
                    params  => [
                        $peermask,
                        $unmask,
                    ],
                    colonify => 0,
                },
                grep { $self->_state_peer_capab($_, 'CLUSTER') } keys %targpeers,
            );
        }
        else {
          $us = 1;
        }

        last SWITCH if !$us;

        my $result = $self->_state_del_drkx_line( 'xline', $unmask );

        if ( !$result ) {
           push @$ref, { prefix => $server, command => 'NOTICE', params => [ $nick, "No X-Line for [$unmask] found" ] };
           last SWITCH;
        }

        my $full = $self->state_user_full($nick);
        $self->send_event(
            "daemon_unxline",
            $full,
            $unmask,
        );

        push @$ref, {
            prefix  => $server,
            command => 'NOTICE',
            params  => [ $nick, "X-Line for [$unmask] is removed" ],
        };

        $self->_send_to_realops( "$full has removed the X-Line for: [$unmask]", 'Notice', 's' );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_dline {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count || $count < 2) {
            push @$ref, ['461', 'DLINE'];
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
        my $netmask;
        if ( $mask !~ m![:.]! && $self->state_nick_exists($mask) ) {
            my $uid = $self->state_user_uid($mask);
            if ( $uid !~ m!^$sid! ) {
              push @$ref, { prefix => $server, command => 'NOTICE', params => [ $nick, 'Cannot DLINE nick on another server' ] };
              last SWITCH;
            }
            if ( $self->{state}{uids}{$uid}{umode} =~ m!o! || $self->{state}{uids}{$uid}{route_id} eq 'spoofed' ) {
              my $tnick = $self->{state}{uids}{$uid}{nick};
              push @$ref, { prefix => $server, command => 'NOTICE', params => [ $nick, "$tnick is E-lined" ] };
              last SWITCH;
            }
            my $addr = $self->{state}{uids}{$uid}{socket}[0];
            $netmask = Net::CIDR::cidrvalidate($addr);
        }
        elsif ( $mask !~ m![:.]! && !$self->state_nick_exists($mask) ) {
            push @$ref, ['401', $mask];
            last SWITCH;
        }
        if ( !$netmask ) {
          $netmask = Net::CIDR::cidrvalidate($mask);
          if ( !$netmask ) {
              push @$ref, { prefix => $server, command => 'NOTICE', params => [ $nick, 'Unable to parse provided IP mask' ] };
              last SWITCH;
          }
        }
        if ($args->[0] && uc $args->[0] eq 'ON'
                && scalar @$args < 2) {
            push @$ref, ['461', 'DLINE'];
            last SWITCH;
        }
        my ($peermask,$reason,$on);
        my $us = 0;
        if ($args->[0] && uc $args->[0] eq 'ON') {
          $on = shift @$args;
          $peermask = shift @$args;
          $reason  = shift @$args || '<No reason supplied>';
          my %targpeers; my $ucserver = uc $server;
          foreach my $peer ( keys %{ $self->{state}{peers} } ) {
             if (matches_mask($peermask, $peer)) {
                if ($ucserver eq $peer) {
                   $us = 1;
                }
                else {
                   $targpeers{ $self->_state_peer_route($peer) }++;
                }
             }
          }
          $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => 'DLINE',
                    params  => [
                        $peermask,
                        ( $duration * 60 ),
                        $netmask,
                        $reason,
                    ],
                },
                grep { $self->_state_peer_capab($_, 'DLN') } keys %targpeers,
            );
        }
        else {
          $us = 1;
        }

        last SWITCH if !$us;

        if ( !$reason ) {
          $reason = shift @$args || '<No reason supplied>';
        }

        my $full = $self->state_user_full($nick);

        last SWITCH if !$self->_state_add_drkx_line( 'dline',
                                 $full, time, $server, $duration * 60,
                                    $netmask, $reason );

        $self->send_event(
            "daemon_dline",
            $full,
            $netmask,
            $duration,
            $reason,
        );

        $self->add_denial( $netmask, 'You have been D-lined.' );

        my $temp = $duration ? "temporary $duration min. " : '';

        my $reply_notice = "Added ${temp}D-Line [$netmask]";
        my $locop_notice = "$full added ${temp}D-Line for [$netmask] [$reason]";

        push @$ref, {
            prefix  => $server,
            command => 'NOTICE',
            params  => [ $nick, $reply_notice ],
        };

        $self->_send_to_realops( $locop_notice, 'Notice', 's' );

        $self->_state_do_local_users_match_dline($netmask,$reason);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_undline {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            push @$ref, ['481'];
            last SWITCH;
        }
        if (!$count ) {
            push @$ref, ['461', 'UNDLINE'];
            last SWITCH;
        }
        my $unmask = shift @$args;
        if ($args->[0] && uc $args->[0] eq 'ON'
                && scalar @$args < 2) {
            push @$ref, ['461', 'UNDLINE'];
            last SWITCH;
        }
        my $us = 0;
        if ($args->[0] && uc $args->[0] eq 'ON') {
          my $on = shift @$args;
          my $peermask = shift @$args;
          my %targpeers; my $ucserver = uc $server;
          foreach my $peer ( keys %{ $self->{state}{peers} } ) {
             if (matches_mask($peermask, $peer)) {
                if ($ucserver eq $peer) {
                   $us = 1;
                }
                else {
                   $targpeers{ $self->_state_peer_route($peer) }++;
                }
             }
          }
          $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => 'UNDLINE',
                    params  => [
                        $peermask,
                        $unmask,
                    ],
                    colonify => 0,
                },
                grep { $self->_state_peer_capab($_, 'UNDLN') } keys %targpeers,
            );
        }
        else {
          $us = 1;
        }

        last SWITCH if !$us;

        my $result = $self->_state_del_drkx_line( 'dline', $unmask );

        if ( !$result ) {
           push @$ref, { prefix => $server, command => 'NOTICE', params => [ $nick, "No D-Line for [$unmask] found" ] };
           last SWITCH;
        }

        my $full = $self->state_user_full($nick);
        $self->send_event(
            "daemon_undline",
            $full,
            $unmask,
        );

        $self->del_denial( $unmask );

        push @$ref, {
            prefix  => $server,
            command => 'NOTICE',
            params  => [ $nick, "D-Line for [$unmask] is removed" ],
        };

        $self->_send_to_realops(
            "$full has removed the D-Line for: [$unmask]",
            'Notice',
            's',
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_kill {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = ( $self->{config}{'hidden_servers'} ?
                   $self->{config}{'hidden_servers'} : $self->server_name() );
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
        my $target  = $self->state_user_nick($args->[0]);
        my $targuid = $self->state_user_uid($target);
        my $uid     = $self->state_user_uid($nick);
        my $comment = $args->[1] || '<No reason given>';
        if ($self->_state_is_local_user($target)) {
            my $route_id = $self->_state_user_route($target);
            $self->send_output(
                {
                    prefix  => $uid,
                    command => 'KILL',
                    params  => [
                        $targuid,
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
            $self->{state}{uids}{$targuid}{killed} = 1;
            $self->send_output(
                {
                    prefix  => $uid,
                    command => 'KILL',
                    params  => [
                        $targuid,
                        join('!', $server, $nick )." ($comment)",
                    ],
                },
                $self->_state_connected_peers(),
            );
            $self->send_output(
                @{ $self->_daemon_peer_quit(
                    $targuid,
                    "Killed ($nick ($comment))"
                )}
            );
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_tracing {
    my $self    = shift;
    my $cmd     = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $args    = [@_];
    my $count   = @$args;
    my $ref     = [ ];
    $cmd        = uc $cmd;

    SWITCH: {
        if ($count > 1) {
           my $targ = ( $self->state_user_uid($args->[1]) || $self->_state_peer_sid($args->[1] ) );
           if (!$targ) {
              push @$ref, {
                  prefix  => $sid,
                  command => '402',
                  params  => [
                      $uid,
                      $args->[1],
                  ],
              };
              last SWITCH;
           }
           if ($targ !~ m!^$sid!) {
              my $psid = substr $targ, 0, 3;
              $self->send_output(
                  {
                      prefix  => $uid,
                      command => $cmd,
                      params  => [
                          $args->[0],
                          $targ,
                      ],
                  },
                  $self->_state_sid_route($psid),
              );
              last SWITCH;
           }
        }
        if ($args->[0]) {
           my $targ = ( $self->state_user_uid($args->[0]) || $self->_state_peer_sid($args->[0] ) );
           if (!$targ) {
              push @$ref, {
                  prefix  => $sid,
                  command => '402',
                  params  => [
                      $uid,
                      $args->[0],
                  ],
              };
              last SWITCH;
           }
           if ($targ !~ m!^$sid!) {
              my $name;
              my $route_id;
              if ( length $targ == 3 ) {
                  $name     = $self->{state}{sids}{$targ}{name};
                  $route_id = $self->{state}{sids}{$targ}{route_id};
              }
              else {
                  $name     = $self->{state}{uids}{$targ}{nick};
                  $route_id = $self->{state}{uids}{$targ}{route_id};
              }
              push @$ref, {
                  prefix  => $sid,
                  command => '200',
                  params  => [
                      $uid,
                      'Link',
                      $self->server_version(),
                      $name,
                      $self->{state}{conns}{$route_id}{name},
                  ],
              };
              $self->send_output(
                  {
                      prefix  => $uid,
                      command => $cmd,
                      params  => [
                          $targ,
                      ],
                  },
                  $route_id,
              );
              last SWITCH;
           }
        }
        my $method = ( $cmd eq 'ETRACE' ? '_daemon_do_etrace' : '_daemon_do_trace' );
        push @$ref, $_ for @{ $self->$method($uid, @$args) };
    }
    return @$ref if wantarray;
    return $ref;
}

sub _state_find_peer {
    my $self   = shift;
    my $targ   = shift || return;
    my $connid = shift;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ume    = uc $server;
    my $result;

    if ($self->state_nick_exists($targ)) {
       $result = $self->state_user_uid($targ);
    }
    if (!$result && $self->state_peer_exists($targ)) {
       $result = $self->_state_peer_sid($targ);
    }
    if (!$result && $targ =~ m![\x2A\x3F]!) {
       PEERS: foreach my $peer ( sort keys %{ $self->{state}{peers} } ) {
          if ( matches_mask($targ,$peer,'ascii') ) {
             return $sid if $ume eq $peer;
             my $peerrec = $self->{state}{peers}{$peer};
             next PEERS if $connid && $connid eq $peerrec->{route_id}
                  && $peerrec->{type} eq 'r';
             $result = $peerrec->{sid};
             last PEERS;
          }
       }
       if (!$result) {
          USERS: foreach my $user ( sort keys %{ $self->{state}{users} } ) {
             if ( matches_mask($targ,$user) ) {
                my $rec = $self->{state}{users}{$user};
                return $sid if $rec->{uid} =~ m!^$sid!;
                next USERS if $connid && $connid eq $rec->{route_id}
                     && $self->{state}{sids}{ $rec->{sid} }{type} eq 'r';
                $result = $rec->{uid};
                last USERS
             }
          }
       }
    }
    return $result if $result;
    return;
}

sub _daemon_client_tracing {
    my $self   = shift;
    my $cmd    = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $args   = [@_];
    my $count  = @$args;
    my $ref    = [ ];
    $cmd       = uc $cmd;

    SWITCH: {
        if (!$self->state_user_is_operator($nick)) {
            if ( $cmd eq 'ETRACE' ) {
                push @$ref, ['481'];
                last SWITCH;
            }
            push @$ref, {
                prefix  => $server,
                command => '262',
                params  => [
                    $nick, $server, 'End of TRACE',
                ],
            };
            last SWITCH;
        }
        if ($count > 1) {
           my $targ = $self->_state_find_peer($args->[1]);
           if (!$targ) {
              push @$ref, [ '402', $args->[1] ];
              last SWITCH;
           }
           if ($targ !~ m!^$sid!) {
              my $psid = substr $targ, 0, 3;
              $self->send_output(
                  {
                      prefix  => $self->state_user_uid($nick),
                      command => $cmd,
                      params  => [
                          $args->[0],
                          $targ,
                      ],
                  },
                  $self->_state_sid_route($psid),
              );
              last SWITCH;
           }
        }
        my $uid = $self->state_user_uid($nick);
        if ($args->[0]) {
           my $targ = $self->_state_find_peer($args->[0]);
           if (!$targ) {
              push @$ref, [ '402', $args->[0] ];
              last SWITCH;
           }
           if ($targ !~ m!^$sid!) {
              my $name;
              my $route_id;
              if ( length $targ == 3 ) {
                  $name     = $self->{state}{sids}{$targ}{name};
                  $route_id = $self->{state}{sids}{$targ}{route_id};
              }
              else {
                  $name     = $self->{state}{uids}{$targ}{nick};
                  $route_id = $self->{state}{uids}{$targ}{route_id};
              }
              push @$ref, {
                  prefix  => $server,
                  command => '200',
                  params  => [
                      $nick,
                      'Link',
                      $self->server_version(),
                      $name,
                      $self->{state}{conns}{$route_id}{name},
                  ],
              };
              $self->send_output(
                  {
                      prefix  => $uid,
                      command => $cmd,
                      params  => [
                          $targ,
                      ],
                  },
                  $route_id,
              );
              last SWITCH;
           }
        }
        my $method = ( $cmd eq 'ETRACE' ? '_daemon_do_etrace' : '_daemon_do_trace' );
        push @$ref, $_ for map { $_->{prefix} = $server; $_->{params}[0] = $nick; $_ }
                       @{ $self->$method($uid, @$args) };
    }
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_etrace {
    my $self   = shift;
    my $uid    = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $args   = [@_];
    my $count  = @$args;
    my $ref    = [ ];

    SWITCH: {
        my $rec = $self->{state}{uids}{$uid};
        $self->_send_to_realops(
          sprintf(
            'ETRACE requested by %s (%s@%s) [%s]',
            $rec->{nick},
            $rec->{auth}{ident},
            $rec->{auth}{hostname},
            $rec->{server},
          ),
          'Notice',
          'y',
        );
        my $doall = 0;
        if (!$args->[0]) {
          $doall = 1;
        }
        elsif (uc $args->[0] eq uc $server) {
          $doall = 1;
        }
        elsif ($args->[0] eq $sid) {
          $doall = 1;
        }
        my $name = $args->[0];
        if ($name && $name =~ m!^[0-9]!) {
            $name = $self->state_user_nick($name);
        }
        $name = uc_irc $name if $name;
        # Local clients
        my @connects;
        my $conns = $self->{state}{conns};
        foreach my $conn_id ( keys %$conns ) {
            next if $conns->{$conn_id}{type} ne 'c';
            next if defined $self->{state}{localops}{ $conn_id };
            push @connects, $conn_id;
        }
        foreach my $conn_id ( sort { $conns->{$a}{nick} cmp $conns->{$b}{nick} }
                                @connects ) {
            next if !$doall || ( $name && $name ne uc_irc $conns->{$conn_id}{nick} );
            my $connrec = $conns->{$conn_id};
            push @$ref, {
                prefix  => $sid,
                command => '709',
                params  => [
                    $uid,
                    'User', 'users',
                    $connrec->{nick},
                    $connrec->{auth}{ident},
                    $connrec->{auth}{hostname},
                    $connrec->{socket}[0],
                    $connrec->{ircname},
                ],
            };
        }
        foreach my $conn_id ( sort { $conns->{$a}{nick} cmp $conns->{$b}{nick} }
                                keys %{ $self->{state}{localops} } ) {
            next if !$doall || ( $name && $name ne uc_irc $conns->{$conn_id}{nick} );
            my $connrec = $conns->{$conn_id};
            push @$ref, {
                prefix  => $sid,
                command => '709',
                params  => [
                    $uid,
                    'Oper', 'opers',
                    $connrec->{nick},
                    $connrec->{auth}{ident},
                    $connrec->{auth}{hostname},
                    $connrec->{socket}[0],
                    $connrec->{ircname},
                ],
            };
        }
        # End of ETRACE
        push @$ref, {
            prefix  => $sid,
            command => '759',
            params  => [
                $uid, $server, 'End of ETRACE',
            ],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_trace {
    my $self   = shift;
    my $uid    = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $args   = [@_];
    my $count  = @$args;
    my $ref    = [ ];

    SWITCH: {
        my $rec = $self->{state}{uids}{$uid};
        $self->_send_to_realops(
          sprintf(
            'TRACE requested by %s (%s@%s) [%s]',
            $rec->{nick},
            $rec->{auth}{ident},
            $rec->{auth}{hostname},
            $rec->{server},
          ),
          'Notice',
          'y',
        );
        my $doall = 0;
        if (!$args->[0]) {
          $doall = 1;
        }
        elsif (uc $args->[0] eq uc $server) {
          $doall = 1;
        }
        elsif ($args->[0] eq $sid) {
          $doall = 1;
        }
        my $name = $args->[0];
        if ($name && $name =~ m!^[0-9]!) {
            $name = $self->state_user_nick($name);
        }
        $name = uc_irc $name if $name;
        # Local clients
        my $conns = $self->{state}{conns};
        my %connects;
        foreach my $conn_id ( keys %$conns ) {
            next if defined $self->{state}{localops}{ $conn_id };
            push @{ $connects{ $conns->{$conn_id}{type} } }, $conn_id;
        }
        foreach my $conn_id ( sort { $conns->{$a}{nick} cmp $conns->{$b}{nick} }
                                @{ $connects{c} } ) {
            next if !$doall || ( $name && $name ne uc_irc $conns->{$conn_id}{nick} );
            my $connrec = $conns->{$conn_id};
            push @$ref, {
                prefix  => $sid,
                command => '205',
                params  => [
                    $uid,
                    'User', 'users',
                    $connrec->{nick},
                    sprintf('[%s@%s]',$connrec->{auth}{ident},$connrec->{auth}{hostname}),
                    sprintf('(%s)',$connrec->{socket}[0]),
                    time - $connrec->{seen},
                    time - $connrec->{idle_time},
                ],
                colonify => 0,
            };
        }
        foreach my $conn_id ( sort { $conns->{$a}{nick} cmp $conns->{$b}{nick} }
                                keys %{ $self->{state}{localops} } ) {
            next if !$doall || ( $name && $name ne uc_irc $conns->{$conn_id}{nick} );
            my $connrec = $conns->{$conn_id};
            push @$ref, {
                prefix  => $sid,
                command => '204',
                params  => [
                    $uid,
                    'Oper', 'opers',
                    $connrec->{nick},
                    sprintf('[%s@%s]',$connrec->{auth}{ident},$connrec->{auth}{hostname}),
                    sprintf('(%s)',$connrec->{socket}[0]),
                    time - $connrec->{seen},
                    time - $connrec->{idle_time},
                ],
                colonify => 0,
            };
        }
        # Servers
        foreach my $conn_id ( sort { $conns->{$a}{name} cmp $conns->{$b}{name} }
                                @{ $connects{p} } ) {
            next if !$doall || ( $name && $name ne uc_irc $conns->{$conn_id}{name} );
            my $connrec = $conns->{$conn_id};
            my $srvcnt = 0; my $clicnt = 0;
            $self->_state_peer_dependents( $connrec->{sid}, \$srvcnt, \$clicnt );
            push @$ref, {
                prefix  => $sid,
                command => '206',
                params  => [
                    $uid,
                    'Serv', 'server',
                    "${srvcnt}S", "${clicnt}C",
                    sprintf(
                      '%s[%s@%s]', $connrec->{name},
                      ( $connrec->{auth}{ident} || 'unknown' ),
                      ( $connrec->{auth}{hostname} || $connrec->{socket}[0] ) ),
                    sprintf('%s!%s@%s','*','*',$connrec->{name}),
                    time - $connrec->{conn_time},
                ],
                colonify => 0,
            };
        }
        # Unknowns
        foreach my $conn_id ( sort { $conns->{$a}{nick} <=> $conns->{$b}{nick} }
                                @{ $connects{u} } ) {
            next if !$doall;
            my $connrec = $conns->{$conn_id};
            push @$ref, {
                prefix  => $sid,
                command => '203',
                params  => [
                    $uid,
                    '????', 'default',
                    sprintf(
                      '[%s@%s]', ( $connrec->{auth}{ident} || 'unknown' ),
                      ( $connrec->{auth}{hostname} || $connrec->{socket}[0] ) ),
                    sprintf('(%s)',$connrec->{socket}[0]),
                    time - $connrec->{conn_time},
                ],
                colonify => 0,
            };
        }
        if ($doall) {
            my $users   = ( defined $connects{c} ? @{ $connects{c} } : 0 );
            my $opers   = ( defined $self->{state}{localops} ? keys %{ $self->{state}{localops} } : 0 );
            my $servers = ( defined $connects{p} ? @{ $connects{p} } : 0 );;
            $users -= $opers;
            # 209
            if ($servers) {
                push @$ref, {
                    prefix  => $sid,
                    command => '209',
                    params  => [
                        $uid,
                        'Class', 'server', $servers,
                    ],
                    colonify => 0,
                };
            }
            if ($opers) {
                push @$ref, {
                    prefix  => $sid,
                    command => '209',
                    params  => [
                        $uid,
                        'Class', 'opers', $opers,
                    ],
                    colonify => 0,
                };
            }
            if ($users) {
                push @$ref, {
                    prefix  => $sid,
                    command => '209',
                    params  => [
                        $uid,
                        'Class', 'users', $users,
                    ],
                    colonify => 0,
                };
            }
        }
        # End of TRACE
        push @$ref, {
            prefix  => $sid,
            command => '262',
            params  => [
                $uid, $server, 'End of TRACE',
            ],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _state_peer_dependents {
    my $self   = shift;
    my $sid    = shift || return;
    my $srvcnt = shift;
    my $clicnt = shift;

    $$srvcnt++;
    $$clicnt += keys %{ $self->{state}{sids}{$sid}{uids} };
    foreach my $psid ( keys %{ $self->{state}{sids}{$sid}{sids} } ) {
        $self->_state_peer_dependents($psid,$srvcnt,$clicnt);
    }
    return;
}
sub _daemon_cmd_nick {
    my $self   = shift;
    my $nick   = shift || return;
    my $new    = shift;
    my $server = uc $self->server_name();
    my $sid    = $self->server_sid();
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
        my $record = $self->{state}{users}{$unick};
        if ( my $reason = $self->_state_is_resv( $new, $record->{route_id} ) ) {
            $self->_send_to_realops(
                sprintf(
                    'Forbidding reserved nick %s from user %s',
                    $new,
                    $self->state_user_full($nick),
                ),
                'Notice',
                'j',
            );
            push @$ref, {
               prefix  => $self->server_name(),
               command => '432',
               params  => [
                      $nick,
                      $new,
                      $reason,
               ],
            };
            last SWITCH;
        }
        my $unew = uc_irc($new);
        if ($self->state_nick_exists($new) && $unick ne $unew) {
            push @$ref, ['433', $new];
            last SWITCH;
        }
        my $full   = $record->{full}->();
        my $common = { $record->{uid} => $record->{route_id} };

        my $nonickchange = '';
        CHANS: for my $chan (keys %{ $record->{chans} }) {
            my $chanrec = $self->{state}{chans}{$chan};
            if ( $chanrec->{mode} =~ /N/ ) {
                if ( $record->{chans} !~ /[oh]/ ) {
                    $nonickchange = $chanrec->{name};
                    last CHANS;
                }
            }
            USER: for my $user ( keys %{ $chanrec->{users} } ) {
                next USER if $user !~ m!^$sid!;
                $common->{$user} = $self->_state_uid_route($user);
            }
        }

        if ($nonickchange) {
            push @$ref,['447',$nonickchange];
            last SWITCH;
        }

        my $lastattempt = $record->{_nick_last};
        if ( $lastattempt && ( $lastattempt + $self->{config}{max_nick_time} < time() ) ) {
            $record->{_nick_count} = 0;
        }

        if ( ( $self->{config}{anti_nick_flood} && $record->{umode} !~ /o/ ) &&
              $record->{_nick_count} && ( $record->{_nick_count} >= $self->{config}{max_nick_changes} ) ) {
            push @$ref,['438',$new,$self->{config}{max_nick_time}];
            last SWITCH;
        }

        $record->{_nick_last} = time();
        $record->{_nick_count}++;

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
            # WATCH ON/OFF
            if ( defined $self->{state}{watches}{$unick} ) {
                foreach my $wuid ( keys %{ $self->{state}{watches}{$unick}{uids} } ) {
                    next if !defined $self->{state}{uids}{$wuid};
                    my $wrec = $self->{state}{uids}{$wuid};
                    my $laston = time();
                    $self->{state}{watches}{$unick}{laston} = $laston;
                    $self->send_output(
                        {
                            prefix  => $record->{server},
                            command => '605',
                            params  => [
                                $wrec->{nick},
                                $nick,
                                $record->{auth}{ident},
                                $record->{auth}{hostname},
                                $laston,
                                'is offline',
                            ],
                        },
                        $wrec->{route_id},
                    );
                }
            }
            if ( defined $self->{state}{watches}{$unew} ) {
                foreach my $wuid ( keys %{ $self->{state}{watches}{$unew}{uids} } ) {
                    next if !defined $self->{state}{uids}{$wuid};
                    my $wrec = $self->{state}{uids}{$wuid};
                    $self->send_output(
                        {
                            prefix  => $record->{server},
                            command => '604',
                            params  => [
                                $wrec->{nick},
                                $record->{nick},
                                $record->{auth}{ident},
                                $record->{auth}{hostname},
                                $record->{ts},
                                'is online',
                            ],
                        },
                        $wrec->{route_id},
                    );
                }
            }
            delete $self->{state}{users}{$unick};
            $self->{state}{users}{$unew} = $record;
            delete $self->{state}{peers}{$server}{users}{$unick};
            $self->{state}{peers}{$server}{users}{$unew} = $record;
            if ( $record->{umode} =~ /r/ ) {
                $record->{umode} =~ s/r//g;
                $self->send_output(
                    {
                        prefix  => $full,
                        command => 'MODE',
                        params  => [
                            $record->{nick},
                            '-r',
                        ],
                    },
                    $record->{route_id},
                );
            }
            unshift @{ $self->{state}{whowas}{$unick} }, {
                logoff  => time(),
                account => $record->{account},
                nick    => $nick,
                user    => $record->{auth}{ident},
                host    => $record->{auth}{hostname},
                real    => $record->{auth}{realhost},
                sock    => $record->{socket}[0],
                ircname => $record->{ircname},
                server  => $record->{server},
            };
        }

        $self->_send_to_realops(
            sprintf(
                'Nick change: From %s to %s [%s]',
                $nick, $new, (split /!/, $full)[1],
            ),
            'Notice',
            'n',
        );

        $self->send_output(
            {
                prefix  => $record->{uid},
                command => 'NICK',
                params  => [$new, $record->{ts}],
            },
            $self->_state_connected_peers(),
        );

        $self->send_event("daemon_nick", $full, $new);

        $self->send_output(
            {
                prefix  => $full,
                command => 'NICK',
                params  => [$new],
            },
            values %$common,
        );
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
        my $rec = $self->{state}{users}{uc_irc($nick)};
        if (!$msg) {
            delete $rec->{away};
            $self->send_output(
                {
                    prefix => $rec->{uid},
                    command => 'AWAY',
                },
                $self->_state_connected_peers(),
            );
            push @$ref, {
                prefix  => $server,
                command => '305',
                params  => [ $rec->{nick}, 'You are no longer marked as being away' ],
            };
            $self->_state_do_away_notify($rec->{uid},'*',$msg);
            last SWITCH;
        }

        $rec->{away} = $msg;

        $self->send_output(
            {
                prefix   => $rec->{uid},
                command  => 'AWAY',
                params   => [$msg],
            },
            $self->_state_connected_peers(),
        );
        push @$ref, {
            prefix  => $server,
            command => '306',
            params  => [ $rec->{nick}, 'You have been marked as being away' ],
        };
        $self->_state_do_away_notify($rec->{uid},'*',$msg);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_client_miscell {
    my $self   = shift;
    my $cmd    = shift;
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
            $target = $self->_state_peer_sid($target);
            $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => uc $cmd,
                    params  => [$target],
                },
                $self->_state_sid_route($target),
            );
            last SWITCH;
        }
        if ($cmd =~ m!^(ADMIN|INFO|MOTD)$!i) {
            $self->_send_to_realops(
                sprintf(
                    '%s requested by %s (%s) [%s]',
                    $cmd, $nick, (split /!/,$self->state_user_full($nick))[1], $server,
                ), qw[Notice y],
            );
        }
        my $method = '_daemon_do_' . lc $cmd;
        my $uid = $self->state_user_uid($nick);
        push @$ref, $_ for map { $_->{prefix} = $server; $_->{params}[0] = $nick; $_ }
                       @{ $self->$method($uid) };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_miscell {
    my $self   = shift;
    my $cmd    = shift;
    my $uid    = shift || return;
    my $sid    = $self->server_sid();
    my $args   = [@_];
    my $count  = @$args;
    my $ref    = [ ];

    SWITCH: {
        if ($cmd ne 'STATS' && $args->[0] !~ m!^$sid!) {
            $self->send_output(
                {
                    prefix  => $uid,
                    command => $cmd,
                    params  => $args,
                },
                $self->_state_sid_route(substr $args->[0], 0, 3),
            );
            last SWITCH;
        }
        if ($cmd eq 'STATS' && $args->[1] !~ m!^$sid!) {
            $self->send_output(
                {
                    prefix  => $uid,
                    command => $cmd,
                    params  => $args,
                },
                $self->_state_sid_route(substr $args->[1], 0, 3),
            );
            last SWITCH;
        }
        if ($cmd =~ m!^(ADMIN|INFO|MOTD)$!i) {
            my $urec = $self->{state}{uids}{$uid};
            $self->_send_to_realops(
                sprintf(
                    '%s requested by %s (%s) [%s]',
                    $cmd, $urec->{nick}, (split /!/,$urec->{full}->())[1], $urec->{server},
                ), qw[Notice y],
            );
        }
        my $method = '_daemon_do_' . lc $cmd;
        $ref = $self->$method($uid, @$args);
    }

    return @$ref if wantarray;
    return $ref;
}

# Pseudo cmd for ISupport 005 numerics
sub _daemon_do_isupport {
    my $self   = shift;
    my $uid    = shift || return;
    my $sid    = $self->server_sid();
    my $ref    = [ ];

    push @$ref, {
        prefix  => $sid,
        command => '005',
        params  => [
            $uid,
            join(' ', map {
                (defined $self->{config}{isupport}{$_}
                    ? join '=', $_, $self->{config}{isupport}{$_}
                    : $_
                )
                } qw(CALLERID EXCEPTS INVEX MAXCHANNELS MAXLIST MAXTARGETS
                     NICKLEN TOPICLEN KICKLEN KNOCK DEAF)
            ),
            'are supported by this server',
        ],
    };

    push @$ref, {
        prefix  => $sid,
        command => '005',
        params  => [
            $uid,
            join(' ', map {
                (defined $self->{config}{isupport}{$_}
                    ? join '=', $_, $self->{config}{isupport}{$_}
                    : $_
                )
                } qw(CHANTYPES PREFIX CHANMODES NETWORK CASEMAPPING SAFELIST ELIST)
            ), 'are supported by this server',
        ],
    };

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_info {
    my $self   = shift;
    my $uid    = shift || return;
    my $sid    = $self->server_sid();
    my $ref    = [ ];

    {
        for my $info (@{ $self->server_config('Info') }) {
            push @$ref, {
                prefix => $sid,
                command => '371',
                params => [$uid, $info],
            };
        }

        push @$ref, {
            prefix  => $sid,
            command => '374',
            params  => [$uid, 'End of /INFO list.'],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_version {
    my $self   = shift;
    my $uid    = shift || return;
    my $sid    = $self->server_sid();
    my $ref    = [ ];

    push @$ref, {
        prefix  => $sid,
        command => '351',
        params  => [
             $uid,
             $self->server_version(),
             $self->server_name(),
             'eGHIMZ6 TS6ow',
        ],
    };

    push @$ref, $_ for @{ $self->_daemon_do_isupport($uid) };

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_admin {
    my $self   = shift;
    my $uid    = shift || return;
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $admin  = $self->server_config('Admin');

    {
        push @$ref, {
            prefix  => $sid,
            command => '256',
            params  => [$uid, $self->server_name(), 'Administrative Info'],
        };

        push @$ref, {
            prefix  => $sid,
            command => '257',
            params  => [$uid, $admin->[0]],
        };

        push @$ref, {
            prefix  => $sid,
            command => '258',
            params  => [$uid, $admin->[1]],
        };

        push @$ref, {
            prefix  => $sid,
            command => '259',
            params  => [$uid, $admin->[2]],
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

sub _daemon_do_time {
    my $self   = shift;
    my $uid    = shift || return;
    my $sid    = $self->server_sid();
    my $ref    = [ ];

    {
        push @$ref, {
            prefix  => $sid,
            command => '391',
            params  => [
                $uid,
                $self->server_name(),
                strftime("%A %B %e %Y -- %T %z", localtime),
            ],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_users {
    my $self   = shift;
    my $uid    = shift || return;
    my $hidden = shift;
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $global = keys %{ $self->{state}{uids} };
    my $local  = $hidden ? $global : scalar keys %{ $self->{state}{sids}{$sid}{uids} };
    my $maxloc = $hidden ? 'maxglobal' : 'maxlocal';

    push @$ref, {
        prefix  => $sid,
        command => '265',
        params  => [
            $uid,
            "Current local users: $local  Max: "
                . $self->{state}{stats}{$maxloc},
        ],
    };

    push @$ref, {
        prefix  => $sid,
        command => '266',
        params  => [
            $uid,
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
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if ($count && $count > 1) {
            my $target = ( $self->_state_peer_sid($args->[1]) || $self->state_user_uid($args->[1]) );
            if (!$target) {
                push @$ref, ['402', $args->[1]];
                last SWITCH;
            }
            my $targsid = substr $target, 0, 3;
            my $sid = $self->server_sid();
            if ( $targsid ne $sid ) {
                $self->send_output(
                    {
                        prefix  => $self->state_user_uid($nick),
                        command => 'LUSERS',
                        params  => [
                            $args->[0],
                            $target,
                        ],
                    },
                    $self->_state_sid_route($targsid),
                );
                last SWITCH;
            }
        }
        my $uid = $self->state_user_uid($nick);
        push @$ref, $_ for map { $_->{prefix} = $server; $_->{params}[0] = $nick; $_ }
                       @{ $self->_daemon_do_lusers($uid) };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_lusers {
    my $self       = shift;
    my $uid        = shift || return;
    my $sid        = $self->server_sid();
    my $ref        = [ ];
    my $args       = [@_];
    my $count      = @$args;

    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my $target = ( $self->_state_peer_sid($args->[1]) || $self->state_user_uid($args->[1]) );
        if (!$target) {
            push @$ref, ['402', $args->[1]];
            last SWITCH;
        }
        my $targsid = substr $target, 0, 3;
        if ( $targsid ne $sid ) {
            $self->send_output(
                {
                    prefix  => $uid,
                    command => 'LUSERS',
                    params  => $args,
                },
                $self->_state_sid_route($targsid),
            );
            last SWITCH;
        }
        push @$ref, $_ for @{ $self->_daemon_do_lusers($uid) };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_lusers {
    my $self       = shift;
    my $uid        = shift || return;
    my $sid        = $self->server_sid();
    my $ref        = [ ];
    my $hidden     = ( $self->{config}{'hidden_servers'} && $self->{state}{uids}{$uid}{umode} !~ /o/ );
    my $invisible  = $self->{state}{stats}{invisible};
    my $users      = keys(%{ $self->{state}{uids} }) - $invisible;
    my $servers    = $hidden ? 1 : scalar keys %{ $self->{state}{sids} };
    my $chans      = keys %{ $self->{state}{chans} };
    my $local      = $hidden ? ( $users + $invisible ) : scalar keys %{ $self->{state}{sids}{$sid}{uids} };
    my $peers      = $hidden ? 0 : scalar keys %{ $self->{state}{sids}{$sid}{sids} };
    my $totalconns = $self->{state}{stats}{conns_cumlative};
    my $mlocal     = $self->{state}{stats}{maxlocal};
    my $conns      = $self->{state}{stats}{maxconns};

    push @$ref, {
        prefix  => $sid,
        command => '251',
        params  => [
            $uid,
            "There are $users users and $invisible invisible on "
                . "$servers servers",
        ],
    };

    $servers--;

    push @$ref, {
        prefix  => $sid,
        command => '252',
        params  => [
            $uid,
            $self->{state}{stats}{ops_online},
            "IRC Operators online",
        ]
    } if $self->{state}{stats}{ops_online};

    push @$ref, {
        prefix  => $sid,
        command => '254',
        params  => [$uid, $chans, "channels formed"],
    } if $chans;

    push @$ref, {
        prefix  => $sid,
        command => '255',
        params  => [$uid, "I have $local clients and $peers servers"],
    };

    push @$ref, $_ for $self->_daemon_do_users($uid, $hidden);

    push @$ref, {
        prefix  => $sid,
        command => '250',
        params  => [
            $uid, "Highest connection count: $conns ($mlocal clients) "
                . "($totalconns connections received)",
        ],
    } if !$hidden;

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_motd {
    my $self   = shift;
    my $uid    = shift || return;
    my $sid    = $self->server_sid();
    my $server = $self->server_name();
    my $ref    = [ ];
    my $motd   = $self->server_config('MOTD');

    {
        if ($motd && ref $motd eq 'ARRAY') {
            push @$ref, {
                prefix  => $sid,
                command => '375',
                params  => [$uid, "- $server Message of the day - "],
            };
            push @$ref, {
                prefix  => $sid,
                command => '372',
                params  => [$uid, "- $_"]
            } for @$motd;
            push @$ref, {
                prefix  => $sid,
                command => '376',
                params  => [$uid, "End of MOTD command"],
            };
        }
        else {
            push @$ref, {
                prefix  => $sid,
                command => '422',
                params  => [$uid, $self->{Error_Codes}{'422'}[1]],
            };
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
    my $sid    = $self->server_sid();
    my $ref    = [ ];

    SWITCH: {
        if (!$char) {
            push @$ref, ['461', 'STATS'];
            last SWITCH;
        }
        $char = substr $char, 0, 1;
        if (!$self->state_user_is_operator($nick)) {
            my $lastuse = $self->{state}{lastuse}{stats};
            my $pacewait = $self->{config}{pace_wait};
            if ( $lastuse && $pacewait && ( $lastuse + $pacewait ) > time() ) {
                push @$ref, ['263', 'STATS'];
                last SWITCH;
            }
            $self->{state}{lastuse}{stats} = time();
        }
        if ($char =~ /^[Ll]$/ && !$target) {
            push @$ref, ['461', 'STATS'];
            last SWITCH;
        }
        if ($target) {
           my $targ = $self->_state_find_peer($target);
           if (!$targ) {
              push @$ref, [ '402', $target ];
              last SWITCH;
           }
           if ($targ !~ m!^$sid!) {
              my $psid = substr $targ, 0, 3;
              $self->send_output(
                  {
                      prefix  => $self->state_user_uid($nick),
                      command => 'STATS',
                      params  => [
                          $char,
                          $targ,
                      ],
                  },
                  $self->_state_sid_route($psid),
              );
              last SWITCH;
           }
        }
        my $uid = $self->state_user_uid($nick);
        push @$ref, $_ for map { $_->{prefix} = $server; $_->{params}[0] = $nick; $_ }
                       @{ $self->_daemon_do_stats($uid, $char, $target) };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _rbytes {
  my $bytes=shift;
  my $d=2;
  return undef if !defined $bytes;
  return [ $bytes, 'Bytes' ]                              if abs($bytes) <= 2** 0*1000;
  return [ sprintf("%.*f",$d,$bytes/2**10), 'Kilobytes' ] if abs($bytes) <  2**10*1000;
  return [ sprintf("%.*f",$d,$bytes/2**20), 'Megabytes' ] if abs($bytes) <  2**20*1000;
  return [ sprintf("%.*f",$d,$bytes/2**30), 'Gigabytes' ] if abs($bytes) <  2**30*1000;
  return [ sprintf("%.*f",$d,$bytes/2**40), 'Terabytes' ] if abs($bytes) <  2**40*1000;
  return [ sprintf("%.*f",$d,$bytes/2**50), 'Petabytes' ];
}

sub _daemon_do_stats {
    my $self   = shift;
    my $uid    = shift || return;
    my $char   = shift;
    my $targ   = shift;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];

    my $rec      = $self->{state}{uids}{$uid};
    my $is_oper  = ( $rec->{umode} =~ /o/ );
    my $is_admin = ( $rec->{umode} =~ /a/ );

    my %perms = (
        admin => qr/[AaEFf]/,
        oper  => qr/[OoCcDdeHhIiKkLlQqSsTtUvXxYyz?]/,
    );

    $self->_send_to_realops(
        sprintf(
            'STATS %s requested by %s (%s@%s) [%s]',
            $char, $rec->{nick}, $rec->{auth}{ident},
            $rec->{auth}{hostname}, $rec->{server},
        ), qw[Notice y],
    );

    SWITCH: {
        if (($char =~ $perms{admin} && !$is_admin) ||
            ($char =~ $perms{oper} && !$is_oper)) {
            push @$ref, {
                prefix  => $sid,
                command => '481',
                params  => [
                    $uid,
                    'Permission denied - You are not an IRC operator',
                ],
            };
            last SWITCH;
        }
        if ($char =~ /^[aA]$/) {
            require Net::DNS::Resolver;
            foreach my $ns ( Net::DNS::Resolver->new()->nameservers ) {
                push @$ref, {
                    prefix  => $sid,
                    command => '226',
                    params  => [
                        $uid,
                        $ns,
                    ],
                };
            }
            last SWITCH;
        }
        if ($char =~ /^[cC]$/) {
            foreach my $peer ( sort keys %{ $self->{config}{peers} } ) {
                my $cblk = $self->{config}{peers}{$peer};
                my $feat;
                $feat .= 'A' if $cblk->{auto};
                $feat .= 'S' if $cblk->{ssl};
                $feat  = '*' if !length $feat;
                push @$ref, {
                    prefix  => $sid,
                    command => '213',
                    params  => [
                        $uid, 'C',
                        ( $cblk->{raddress} || $cblk->{sockaddr} ),
                        $feat,
                        $cblk->{name},
                        ( $cblk->{rport} || $cblk->{sockport} ),
                        'server',
                    ],
                    colonify => 0,
                };
            }
            last SWITCH;
        }
        if ($char eq 's') {
            foreach my $pseudo ( sort keys %{ $self->{config}{pseudo} } ) {
                my $prec = $self->{config}{pseudo}{$pseudo};
                push @$ref, {
                    prefix  => $sid,
                    command => '227',
                    params  => [
                        $uid, 's',
                        $prec->{cmd},
                        $prec->{name},
                        join( '@', $prec->{nick},
                        $prec->{host}),
                        ( $prec->{prepend} || '*' ),
                    ],
                };
            }
            last SWITCH;
        }
        if ($char eq 'S') {
            foreach my $service ( sort keys %{ $self->{state}{services} } ) {
                my $srec = $self->{state}{services}{$service};
                push @$ref, {
                    prefix  => $sid,
                    command => '246',
                    params  => [
                        $uid, 'S', '*', '*',
                        $srec->{name}, 0, 0,
                    ],
                    colonify => 0,
                };
            }
            last SWITCH;
        }
        if ($char =~ /^[Dd]$/) {
            my $tdline = ( $char eq 'd' );
            foreach my $dline ( @{ $self->{state}{dlines} } ) {
                next if  $tdline && !$dline->{duration};
                next if !$tdline && $dline->{duration};
                push @$ref, {
                    prefix  => $sid,
                    command => '225',
                    params  => [
                        $uid, $char,
                        $dline->{mask}, $dline->{reason},
                    ],
                };
            }
            last SWITCH;
        }
        if ($char eq 'e') {
            foreach my $mask ( sort keys %{ $self->{exemptions} } ) {
                push @$ref, {
                    prefix  => $sid,
                    command => '225',
                    params  => [
                        $uid, $char,
                        $mask, '',
                    ],
                };
            }
            last SWITCH;
        }
        if ($char =~ /^[Xx]$/) {
            my $txline = ( $char eq 'x' );
            foreach my $xline ( @{ $self->{state}{xlines} } ) {
                next if  $txline && !$xline->{duration};
                next if !$txline && $xline->{duration};
                push @$ref, {
                    prefix  => $sid,
                    command => '247',
                    params  => [
                        $uid, $char,
                        $xline->{mask}, $xline->{reason},
                    ],
                };
            }
            last SWITCH;
        }
        if ($char =~ /^[Kk]$/) {
            my $tkline = ( $char eq 'k' );
            foreach my $kline ( @{ $self->{state}{klines} } ) {
                next if  $tkline && !$kline->{duration};
                next if !$tkline && $kline->{duration};
                push @$ref, {
                    prefix  => $sid,
                    command => '216',
                    params  => [
                        $uid, $char,
                        $kline->{host}, '*',
                        $kline->{user}, $kline->{reason},
                    ],
                };
            }
            last SWITCH;
        }
        if ($char eq 'v') {
            my $srec = $self->{state}{sids}{$sid};
            my $count = 0;
            foreach my $psid ( keys %{ $srec->{sids} } ) {
                my $prec = $srec->{sids}{$psid};
                my $peer = $self->{config}{peers}{uc $prec->{name}};
                my $type = '*';
                $type = 'AutoConn.' if $peer->{auto};
                $type = 'Remote.' if $peer->{type} ne 'r';
                push @$ref, {
                    prefix  => $sid,
                    command => '249',
                    params  => [
                        $uid, 'v',
                        $prec->{name},
                        sprintf('(%s!%s@%s)', $type, '*', '*'),
                        'Idle:',
                        ( time() - $prec->{seen} ),
                    ],
                    colonify => 0,
                };
                $count++;
            }
            push @$ref, {
                    prefix  => $sid,
                    command => '249',
                    params  => [
                        $uid, 'v',
                        "$count Server(s)",
                    ],
            };
            last SWITCH;
        }
        if ($char eq 'P') {
            foreach my $listener ( keys %{ $self->{listeners} } ) {
                my $lrec = $self->{listeners}{$listener};
                push @$ref, {
                    prefix  => $sid,
                    command => '220',
                    params  => [
                        $uid, 'P',
                        $lrec->{port},
                        ( $is_admin ?
                          ( $lrec->{bindaddr} || '*' ) : $server ),
                        '*',
                        ( $lrec->{usessl} ? 's' : 'S' ),
                        'active',
                    ],
                };
            }
            last SWITCH;
        }
        if ($char eq 'u') {
            my $uptime = time - $self->server_config('created');
            my $days   = int $uptime / 86400;
            my $remain = $uptime % 86400;
            my $hours  = int $remain / 3600;
            $remain   %= 3600;
            my $mins   = int $remain / 60;
            $remain   %= 60;

            push @$ref, {
                prefix  => $sid,
                command => '242',
                params  => [
                    $uid,
                    sprintf("Server Up %d days, %2.2d:%2.2d:%2.2d",
                        $days, $hours, $mins, $remain),
                ],
            };

            my $totalconns = $self->{state}{stats}{conns_cumlative};
            my $local = $self->{state}{stats}{maxlocal};
            my $conns = $self->{state}{stats}{maxconns};

            push @$ref, {
                prefix  => $sid,
                command => '250',
                params  => [
                    $uid, 'u',
                    "Highest connection count: $conns ($local "
                        ."clients) ($totalconns connections received)",
                ],
            };
            last SWITCH;
        }
        if ($char =~ /^[mM]$/) {
            my $cmds = $self->{state}{stats}{cmds};
            push @$ref, {
                prefix  => $sid,
                command => '212',
                params  => [
                    $uid, 'M',
                    $_,
                    $cmds->{$_}{local},
                    $cmds->{$_}{bytes},
                    $cmds->{$_}{remote},
                ],
            } for sort keys %$cmds;
            last SWITCH;
        }
        if ($char eq 'p') {
            my @ops = map { $self->_client_nickname( $_ ) }
                keys %{ $self->{state}{localops} };
            for my $op (sort @ops) {
                my $record = $self->{state}{users}{uc_irc($op)};
                next if $record->{umode} =~ /H/ && !$is_oper;
                push @$ref, {
                    prefix  => $sid,
                    command => '249',
                    params  => [
                        $uid, 'p',
                        sprintf("[O] %s (%s\@%s) Idle: %u",
                            $record->{nick}, $record->{auth}{ident},
                            $record->{auth}{hostname},
                            time - $record->{idle_time}),
                    ],
                    colonify => 0,
                };
            }

            push @$ref, {
                prefix  => $sid,
                command => '249',
                params  => [$uid, scalar @ops . " OPER(s)"],
            };
            last SWITCH;
        }
        if ($char =~ /^[Oo]$/) {
            foreach my $op ( keys %{ $self->{config}{ops} } ) {
                my $orec = $self->{config}{ops}{$op};
                my $mask = 'localhost';
                if ( $orec->{ipmask} ) {
                    if (ref $orec->{ipmask} eq 'ARRAY') {
                        $mask = '<masks>';
                    }
                    else {
                        $mask = $orec->{ipmask};
                    }
                }
                push @$ref, {
                    prefix  => $sid,
                    command => '243',
                    params  => [
                        $uid, 'O',
                        sprintf('%s@%s','*', $mask ),
                        '*', $orec->{username},
                        $orec->{umode}, 'opers',
                    ],
                };
            }
            last SWITCH;
        }
        if ($char =~ /^[Qq]$/) {
            my @chans; my @nicks;
            foreach my $mask ( sort keys %{ $self->{state}{resvs} } ) {
                if ($mask =~ m!^\#!) {
                    push @chans, $mask;
                }
                else {
                    push @nicks, $mask;
                }
            }
            foreach my $mask (@chans,@nicks) {
                my $resv = $self->{state}{resvs}{$mask};
                push @$ref, {
                    prefix  => $sid,
                    command => '217',
                    params  => [
                        $uid,
                        ( $resv->{duration} ? 'q' : 'Q' ),
                        $resv->{mask}, $resv->{reason},
                    ],
                };
            }
            last SWITCH;
        }
        if ($char =~ /^[Ll]$/) {
            my $doall = 0;
            if (uc $targ eq uc $server) {
                $doall = 1;
            }
            elsif ($targ eq $sid) {
                $doall = 1;
            }
            my $name = $targ;
            if (!$doall && $name =~ m!^[0-9]!) {
                $name = $self->state_user_nick($name);
            }
            my $conns = $self->{state}{conns};
            my %connects;
            foreach my $conn_id ( keys %$conns ) {
                push @{ $connects{ $conns->{$conn_id}{type} } }, $conn_id;
            }
            # unknown
            foreach my $conn_id ( @{ ( $doall ? $connects{u} : [] ) } ) {
                my $connrec = $conns->{$conn_id};
                my $send = $connrec->{stats}->send();
                my $recv = $connrec->{stats}->recv();
                my $msgs = $self->connection_msgs($conn_id);
                push @$ref, {
                    prefix  => $sid,
                    command => '211',
                    params  => [
                        $uid,
                        sprintf(
                          '%s[%s@%s]', ( $connrec->{nick} || '' ),
                          ( $connrec->{auth}{ident} || 'unknown' ),
                          ( $char eq 'L' ? $connrec->{socket}[0] :
                              ($connrec->{auth}{hostname} || $connrec->{socket}[0] ) ),
                        ), '0', $msgs->[0], ( $send >> 10 ), $msgs->[1], ( $recv >> 10 ),
                        sprintf(
                            '%s %s -',
                            ( time - $connrec->{conn_time} ),
                            ( time > $connrec->{seen} ? ( time - $connrec->{seen} ) : 0 ),
                        ),
                    ],
                };
            }
            # clients
            foreach my $conn_id ( sort { $conns->{$a}{nick} <=> $conns->{$b}{nick} }
                                @{ $connects{c} } ) {
                next if !$doall && !matches_mask($name,$conns->{$conn_id}{nick});
                my $connrec = $conns->{$conn_id};
                my $send = $connrec->{stats}->send();
                my $recv = $connrec->{stats}->recv();
                my $msgs = $self->connection_msgs($conn_id);
                push @$ref, {
                    prefix  => $sid,
                    command => '211',
                    params  => [
                        $uid,
                        sprintf(
                          '%s[%s@%s]', ( $connrec->{nick} || '' ),
                          ( $connrec->{auth}{ident} || 'unknown' ),
                          ( $char eq 'L' ? $connrec->{socket}[0] :
                              ($connrec->{auth}{hostname} || $connrec->{socket}[0] ) ),
                        ), '0', $msgs->[0], ( $send >> 10 ), $msgs->[1], ( $recv >> 10 ),
                        sprintf(
                            '%s %s -',
                            ( time - $connrec->{conn_time} ),
                            ( time > $connrec->{seen} ? ( time - $connrec->{seen} ) : 0 ),
                        ),
                    ],
                };
            }
            # servers
            foreach my $conn_id ( sort { $conns->{$a}{name} cmp $conns->{$b}{name} }
                                @{ $connects{p} } ) {
                next if !$doall && !matches_mask($name,$conns->{$conn_id}{name});
                my $connrec = $conns->{$conn_id};
                my $send = $connrec->{stats}->send();
                my $recv = $connrec->{stats}->recv();
                my $msgs = $self->connection_msgs($conn_id);
                push @$ref, {
                    prefix  => $sid,
                    command => '211',
                    params  => [
                        $uid,
                        sprintf(
                          '%s[%s@%s]', ( $connrec->{name} || '' ),
                          ( $connrec->{auth}{ident} || 'unknown' ),
                          ( $char eq 'L' ? $connrec->{socket}[0] :
                              ($connrec->{auth}{hostname} || $connrec->{socket}[0] ) ),
                        ), '0', $msgs->[0], ( $send >> 10 ), $msgs->[1], ( $recv >> 10 ),
                        sprintf(
                            '%s %s %s',
                            ( time - $connrec->{conn_time} ),
                            ( time > $connrec->{seen} ? ( time - $connrec->{seen} ) : 0 ),
                            join ' ', @{ $connrec->{capab} },
                        ),
                    ],
                };
            }
            last SWITCH;
        }
        if ($char eq '?') {
            my $trecv = my $tsent = 0; my $scnt = 0;
            foreach my $link ( sort keys %{ $self->{state}{sids}{$sid}{sids} } ) {
                $scnt++;
                my $srec = $self->{state}{sids}{$link};
                my $send = $srec->{stats}->send();
                my $recv = $srec->{stats}->recv();
                my $msgs = $self->connection_msgs($srec->{route_id});
                $trecv += $recv; $tsent += $send;
                push @$ref, {
                    prefix  => $sid,
                    command => '211',
                    params  => [
                        $uid,
                        sprintf('%s[unknown@%s]', $srec->{name}, $srec->{socket}[0]),
                        '0', $msgs->[0], ( $send >> 10 ), $msgs->[1], ( $recv >> 10 ),
                        sprintf(
                            '%s %s %s',
                            ( time - $srec->{conn_time} ),
                            ( time > $srec->{seen} ? ( time - $srec->{seen} ) : 0 ),
                            join(' ', @{ $srec->{capab} })
                        ),
                    ],
                };
            }
            push @$ref, {
                prefix  => $sid,
                command => '249',
                params  => [ $uid, '?', "$scnt total server(s)", ],
            };
            push @$ref, {
                prefix  => $sid,
                command => '249',
                params  => [
                    $uid, '?', sprintf('Sent total: %s %s', @{ _rbytes($tsent) }),
                ],
            };
            push @$ref, {
                prefix  => $sid,
                command => '249',
                params  => [
                    $uid, '?', sprintf('Recv total: %s %s', @{ _rbytes($trecv) }),
                ],
            };
            my $uptime = time - $self->server_config('created');
            push @$ref, {
                prefix  => $sid,
                command => '249',
                params  => [
                    $uid, '?', sprintf(
                        'Server send: %s %s (%4.1f K/s)',
                        @{ _rbytes($self->{_globalstats}{sent}) },
                        ( $uptime == 0 ? 0 :
                          ( ($self->{_globalstats}{sent} >> 10) / $uptime )
                        ),
                    ),
                ],
            };
            push @$ref, {
                prefix  => $sid,
                command => '249',
                params  => [
                    $uid, '?', sprintf(
                        'Server recv: %s %s (%4.1f K/s)',
                        @{ _rbytes($self->{_globalstats}{recv}) },
                        ( $uptime == 0 ? 0 :
                          ( ($self->{_globalstats}{sent} >> 10) / $uptime )
                        ),
                    ),
                ],
            };
            last SWITCH;
        }
    }

    push @$ref, {
        prefix  => $sid,
        command => '219',
        params  => [$uid, $char, 'End of /STATS report'],
    };

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_userhost {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $str    = '';
    my $cnt    = 0;

    for my $query (@_) {
        last if $cnt >= 5;
        $cnt++;
        my $uid = $self->state_user_uid($query);
        next if !$uid;
        my $urec = $self->{state}{uids}{$uid};
        my ($name,$uh) = split /!/, $urec->{full}->();
        if ( $nick eq $name ) {
            $uh = join '@', (split /\@/, $uh)[0], $urec->{socket}[0];
        }
        my $status = '';
        if ( $urec->{umode} =~ /o/ && ( $urec->{umode} !~ /H/ ||
              $self->state_user_is_operator($nick) ) ) {
            $status .= '*';
        }
        $status .= '=';
        $status .= ( defined $urec->{away} ? '-' : '+' );
        $str = join ' ', $str, $name . $status . $uh;
        $str =~ s!^ !!g;
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

sub _daemon_do_safelist {
    my ($kernel,$self,$client) = @_[KERNEL,OBJECT,ARG0];
    my $server = $self->server_name();
    my $mask = $client->{safelist};
    return if !$mask;
    my $start = delete $mask->{start};

    if ($start) {
        $self->send_output(
            {
            prefix  => $server,
            command => '321',
            params  => [$client->{nick}, 'Channel', 'Users  Name'],
            },
            $client->{route_id},
        );
        $mask->{chans} = [ keys %{ $self->{state}{chans} } ];
        $kernel->yield('_daemon_do_safelist',$client);
        return;
    }
    else {
        my $chan = shift @{ $mask->{chans} };
        if (!$chan) {
            $self->send_output(
                {
                    prefix  => $server,
                    command => '323',
                    params  => [$client->{nick}, 'End of /LIST'],
                },
                $client->{route_id},
            );
            delete $client->{safelist};
            return;
        }
        my $show = 0;
        SWITCH: {
            last SWITCH if !defined $self->{state}{chans}{$chan};
            if ($mask->{all}) {
                $show = 1;
                last SWITCH;
            }
            if ($mask->{hide}) {
                my $match = matches_mask_array($mask->{hide},[$chan]);
                $show = 0 if keys %$match;
                last SWITCH;
            }
            if ($mask->{show}) {
                my $match = matches_mask_array($mask->{show},[$chan]);
                if ( keys %$match ) {
                   $show = 1;
                }
                else {
                   $show = 0;
                   last SWITCH;
                }
            }
            if ($mask->{users_max} || $mask->{users_min}) {
                my $usercnt = keys %{ $self->{state}{chans}{$chan}{users} };
                if ($mask->{users_max}) {
                    if ($usercnt > $mask->{users_max}) {
                        $show = 1;
                    }
                    else {
                        $show = 0;
                    }
                }
                if ($mask->{users_min}) {
                    if ($usercnt < $mask->{users_min}) {
                        $show = 1;
                    }
                    else {
                        $show = 0;
                    }
                }
            }
            if ($mask->{create_max} || $mask->{create_min}) {
                my $chants = $self->{state}{chans}{$chan}{ts};
                if ($mask->{create_max}) {
                    if ($chants > $mask->{create_max}) {
                        $show = 1;
                    }
                    else {
                        $show = 0;
                    }
                }
                if ($mask->{create_min}) {
                    if ($chants < $mask->{create_min}) {
                        $show = 1;
                    }
                    else {
                        $show = 0;
                    }
                }
            }
            if ($mask->{topic_max} || $mask->{topic_min} || $mask->{topic_msk}) {
                my $chantopic = $self->{state}{chans}{$chan}{topic};
                if (!$chantopic) {
                    $show = 0;
                }
                else {
                    if ($mask->{topic_max}) {
                        if($mask->{topic_max} > $chantopic->[2]) {
                              $show = 1;
                        }
                        else {
                              $show = 0;
                        }
                    }
                    if ($mask->{topic_min}) {
                        if($mask->{topic_min} < $chantopic->[2]) {
                              $show = 1;
                        }
                        else {
                              $show = 0;
                        }
                    }
                    if ($mask->{topic_msk}) {
                        if(matches_mask($mask->{topic_msk},$chantopic->[0],'ascii')) {
                              $show = 1;
                        }
                        else {
                              $show = 0;
                        }
                    }
                }
            }
        }
        my $hidden = ( $self->{state}{chans}{$chan}{mode} =~ m![ps]! );
        if ($show && $hidden && !defined $client->{chans}{$chan}) {
            $show = 0;
        }
        if ($show) {
            my $chanrec = $self->{state}{chans}{$chan};
            my $bluf = sprintf('[+%s]', $chanrec->{mode});
            if ( defined $chanrec->{topic} ) {
                $bluf = join ' ', $bluf, $chanrec->{topic}[0];
            }
            $self->send_output(
                {
                    prefix  => $server,
                    command => '322',
                    params  => [
                        $client->{nick},
                        $chanrec->{name},
                        scalar keys %{ $chanrec->{users} },
                        $bluf,
                    ],
                },
                $client->{route_id},
            );
        }
        $kernel->yield('_daemon_do_safelist',$client);
    }
    return;
}

sub _daemon_cmd_list {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        my $rec = $self->{state}{users}{uc_irc $nick};
        my $task = { start => 1 };
        my $errors;
        if (!$count) {
            if ($rec->{safelist}) {
               delete $rec->{safelist};
               push @$ref, {
                    prefix  => $server,
                    command => '323',
                    params  => [$nick, 'End of /LIST'],
               };
               last SWITCH;
            }
            $task->{all} = 1;
        }
        else {
            OPTS: foreach my $opt ( split /,/, $args->[0] ) {
                if ($opt =~ m!^T!i) {
                    if ($opt !~ m!^T:!i && $opt !~ m!^T[<>]\d+$!i) {
                        $errors++;
                        last OPTS;
                    }
                    my ($pre,$act,$mins) = $opt =~ m!^(T)([<>:])(.+)$!i;
                    if ($act eq '<') {
                        $task->{topic_min} = time() - ( $mins * 60 );
                    }
                    elsif ($act eq '>') {
                        $task->{topic_max} = time() - ( $mins * 60 );
                    }
                    else {
                        $task->{topic_msk} = $mins;
                    }
                    next OPTS;
                }
                if ($opt =~ m!^C!i) {
                    if ($opt !~ m!^C[<>]\d+$!i) {
                        $errors++;
                        last OPTS;
                    }
                    my ($pre,$act,$mins) = $opt =~ m!^(C)([<>])(\d+)$!i;
                    if ($act eq '<') {
                        $task->{create_min} = time() - ( $mins * 60 );
                    }
                    else {
                        $task->{create_max} = time() - ( $mins * 60 );
                    }
                    next OPTS;
                }
                if ($opt =~ m!^\<!) {
                    if ($opt !~ m!^\<\d+$!) {
                        $errors++;
                        last OPTS;
                    }
                    my ($act,$users) = $opt =~ m!^(\<)(\d+)$!;
                    $task->{users_min} = $users;
                    next OPTS;
                }
                if ($opt =~ m!^\>!) {
                    if ($opt !~ m!^\>\d+$!) {
                        $errors++;
                        last OPTS;
                    }
                    my ($act,$users) = $opt =~ m!^(\>)(\d+)$!;
                    $task->{users_max} = $users;
                    next OPTS;
                }
                my ($hide) = $opt =~ s/^!//;
                if ($opt !~ m![\x2A\x3F]! && $opt !~ m!^[#&]! ) {
                    $errors++;
                    last OPTS;
                }
                if ( $hide ) {
                    push @{ $task->{hide} }, $opt;
                }
                else {
                    push @{ $task->{show} }, $opt;
                }
            }
        }
        if ( $errors ) {
            push @$ref, ['521'];
            last SWITCH;
        }
        $rec->{safelist} = $task;
        $poe_kernel->yield('_daemon_do_safelist',$rec);
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

    # TODO: hybrid only seems to support NAMES #channel so fix this
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

        my $chan_prefix_method = 'state_chan_list_prefixed';
        my $uid = $self->state_user_uid($nick);
        $chan_prefix_method = 'state_chan_list_multi_prefixed'
          if $self->{state}{uids}{$uid}{caps}{'multi-prefix'};

        my $flag = ( $self->{state}{uids}{$uid}{caps}{'userhost-in-names'} ? 'FULL' : '' );

        for my $chan (@chans) {
            my $record = $self->{state}{chans}{uc_irc($chan)};
            my $type = '=';
            $type = '@' if $record->{mode} =~ /s/;
            $type = '*' if $record->{mode} =~ /p/;
            my $length = length($server)+3+length($chan)+length($nick)+7;
            my $buffer = '';

            for my $name (sort $self->$chan_prefix_method($record->{name},$flag)) {
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
        $target = $first if $second && uc $first ne uc $server;
        if ($target && !$self->state_peer_exists($target)) {
            push @$ref, ['402', $target];
            last SWITCH;
        }
        if ($target) {
        }
        # Okay we got here *phew*
        if (!$self->state_nick_exists($query)) {
            push @$ref, ['401', $query];
        }
        else {
          my $uid = $self->state_user_uid($nick);
          my $who =  $self->state_user_uid($query);
          if ( $target ) {
             my $tsid = $self->_state_peer_sid($target);
             if ( $who =~ m!^$tsid! ) {
               $self->send_output(
                  {
                      prefix  => $self->state_user_uid($nick),
                      command => 'WHOIS',
                      params  => [
                          $tsid,
                          $query,
                      ],
                  },
                  $self->_state_sid_route($tsid),
               );
               last SWITCH;
             }
          }
          $ref = $self->_daemon_do_whois($uid,$who);
          foreach my $reply ( @$ref ) {
            $reply->{prefix} = $server;
            $reply->{params}[0] = $nick;
          }
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_whois {
    my $self    = shift;
    my $peer_id = shift;
    my $uid     = shift || return;
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my ($first, $second) = @_;

    my $targ = substr $first, 0, 3;
    SWITCH: {
        if ( $targ !~ m!^$sid! ) {
          $self->send_output(
            {
                prefix  => $uid,
                command => 'WHOIS',
                params  => [
                    $first,
                    $second,
                ],
           },
           $self->_state_sid_route($targ),
        );
        last SWITCH;
      }
      my $who = $self->state_user_uid($second);
      $ref = $self->_daemon_do_whois($uid,$who);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_whois {
    my $self   = shift;
    my $uid    = shift || return;
    my $sid    = $self->server_sid();
    my $server = $self->server_name();
    my $nicklen = $self->server_config('NICKLEN');
    my $ref    = [ ];
    my $query  = shift;

    my $querier = $self->{state}{uids}{$uid};
    my $record  = $self->{state}{uids}{$query};

    push @$ref, {
       prefix  => $sid,
       command => '311',
       params  => [
          $uid,
          $record->{nick},
          $record->{auth}{ident},
          $record->{auth}{hostname},
          '*',
          $record->{ircname},
       ],
    };
    my @chans;
    my $noshow = ( $record->{umode} =~ m!p! && $querier->{umode} !~ m!o! && $uid ne $query );
    LOOP: for my $chan (keys %{ $record->{chans} }) {
        next LOOP if $noshow;
        if ($self->{state}{chans}{$chan}{mode} =~ /[ps]/
              && !defined $self->{state}{chans}{$chan}{users}{$uid}) {
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
        my $length = length($server) + 3 + $nicklen
                    + length($record->{nick}) + 7;

        LOOP2: for my $chan (@chans) {
             if (length(join ' ', $buffer, $chan) + $length > 510) {
                 push @$ref, {
                    prefix  => $sid,
                    command => '319',
                    params  => [$uid, $record->{nick}, $buffer],
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
             prefix  => $sid,
             command => '319',
             params  => [$uid, $record->{nick}, $buffer],
        };
    }
    # RPL_WHOISSERVER
    my $hidden = ( $self->{config}{'hidden_servers'} && ( $querier->{umode} !~ /o/ || $uid ne $query ) );
    push @$ref, {
        prefix  => $sid,
        command => '312',
        params  => [
             $uid,
             $record->{nick},
             ( $hidden ? $self->{config}{'hidden_servers'} : $record->{server} ),
             ( $hidden ? $self->server_config('NETWORKDESC') : $self->_state_peer_desc($record->{server}) ),
        ],
    };
    # RPL_WHOISREGNICK
    push @$ref, {
        prefix  => $sid,
        command => '307',
        params  => [
              $uid,
              $record->{nick},
              'has identified for this nick'
        ],
    } if $record->{umode} =~ m!r!;
    # RPL_WHOISACCOUNT
    push @$ref, {
        prefix  => $sid,
        command => '330',
        params  => [
              $uid,
              $record->{nick},
              $record->{account},
              'is logged in as'
        ],
    } if $record->{account} ne '*';
    # RPL_AWAY
    push @$ref, {
        prefix  => $sid,
        command => '301',
        params  => [
              $uid,
              $record->{nick},
              $record->{away},
        ],
    } if $record->{type} eq 'c' && $record->{away};
    if ($record->{umode} !~ m!H! || $querier->{umode} =~ m!o!) {
        my $operstring;
        if ( $record->{svstags}{313} ) {
           $operstring = $record->{svstags}{313}{tagline};
        }
        else {
           $operstring = 'is a Network Service' if $self->_state_sid_serv($record->{sid});
           $operstring = 'is a Server Administrator' if $record->{umode} =~ m!a! && !$operstring;
           $operstring = 'is an IRC Operator' if $record->{umode} =~ m!o! && !$operstring;
        }
        push @$ref, {
            prefix  => $sid,
            command => '313',
            params  => [$uid, $record->{nick}, $operstring],
        } if $operstring;
    }
    if ($record->{type} eq 'c' && ($uid eq $query || $querier->{umode} =~ m!o!) ) {
        my $umodes = join '', '+', sort split //, $record->{umode};
        push @$ref, {
               prefix  => $sid,
               command => '379',
               params  => [
                    $uid,
                    $record->{nick},
                    "is using modes $umodes"
               ],
        };
    }
    if ($record->{type} eq 'c'
         && ($self->server_config('whoisactually')
         or $self->{state}{uids}{$uid}{umode} =~ /o/)) {
        push @$ref, {
               prefix  => $sid,
               command => '338',
               params  => [
                    $uid,
                    $record->{nick},
                    join('@', $record->{auth}{ident}, $record->{auth}{realhost}),
                    ( $record->{ipaddress} || 'fake.hidden' ),
                    'Actual user@host, actual IP',
               ],
        };
     }
     if ($record->{type} eq 'c') {
        push @$ref, {
            prefix  => $sid,
            command => '317',
            params  => [
                  $uid,
                  $record->{nick},
                  time - $record->{idle_time},
                  $record->{conn_time},
                  'seconds idle, signon time',
            ],
        } if $record->{umode} !~ m!q! || $querier->{umode} =~ m!o! || $uid eq $query;
     }
     push @$ref, {
        prefix  => $sid,
        command => '318',
        params  => [$uid, $record->{nick}, 'End of /WHOIS list.'],
     };

    if ($record->{umode} =~ m!y! && $uid ne $query) {
        # Send NOTICE
        my $local = ( $record->{sid} eq $sid );
        $self->send_output(
            {
                prefix  => ( $local ? $self->server_name() : $sid ),
                command => 'NOTICE',
                params  => [
                    ( $local ? $record->{nick} : $record->{uid} ),
                    sprintf('*** Notice -- %s (%s@%s) [%s] is doing a /whois on you',
                        $querier->{nick}, $querier->{auth}{ident}, $querier->{auth}{hostname},
                        $querier->{server},
                    ),
                ],
            },
            $record->{route_id},
        );
    }
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_whowas {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [@_];
    my $count  = @$args;

    SWITCH: {
        if (!$args->[0]) {
            push @$ref, ['431'];
            last SWITCH;
        }
        if (!$self->state_user_is_operator($nick)) {
            my $lastuse = $self->{state}{lastuse}{whowas};
            my $pacewait = $self->{config}{pace_wait};
            if ( $lastuse && $pacewait && ( $lastuse + $pacewait ) > time() ) {
                push @$ref, ['263', 'WHOWAS'];
                last SWITCH;
            }
            $self->{state}{lastuse}{whowas} = time();
        }
        my $query = (split /,/, $args->[0])[0];
        if ($args->[2]) {
           my $targ = $self->_state_find_peer($args->[2]);
           if (!$targ) {
              push @$ref, [ '402', $args->[2] ];
              last SWITCH;
           }
           if ($targ !~ m!^$sid!) {
              my $psid = substr $targ, 0, 3;
              $self->send_output(
                  {
                      prefix  => $self->state_user_uid($nick),
                      command => 'WHOWAS',
                      params  => [
                          $args->[0], $args->[1], $targ,
                      ],
                  },
                  $self->_state_sid_route($psid),
              );
              last SWITCH;
           }
        }
        my $uid = $self->state_user_uid($nick);
        push @$ref, $_ for map { $_->{prefix} = $server; $_->{params}[0] = $nick; $_ }
                       @{ $self->_daemon_do_whowas($uid,@$args) };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_whowas {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my ($first, $second, $third) = @_;

    my $targ = substr $third, 0, 3;
    SWITCH: {
        if ( $targ !~ m!^$sid! ) {
          $self->send_output(
            {
                prefix  => $uid,
                command => 'WHOWAS',
                params  => [
                    $first,
                    $second,
                    $third,
                ],
           },
           $self->_state_sid_route($targ),
        );
        last SWITCH;
      }
      $ref = $self->_daemon_do_whowas($uid,$first,$second);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_whowas {
    my $self   = shift;
    my $uid    = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [@_];
    my $query = shift @$args;

    SWITCH: {
        my $is_oper = ( $self->{state}{uids}{$uid}{umode} =~ /o/ );
        my $max   = shift @$args;
        if ( $uid !~ m!^$sid! && ( !$max || $max < 0 || $max > 20 ) ) {
            $max = 20;
        }
        if (!$self->{state}{whowas}{uc_irc $query}) {
            push @$ref, {
                prefix  => $sid,
                command => '406',
                params  => [$uid, $query, 'There was no such nickname'],
            };
            last SWITCH;
        }
        my $cnt = 0;
        WASNOTWAS: foreach my $was ( @{ $self->{state}{whowas}{uc_irc $query} } ) {
            push @$ref, {
                prefix  => $sid,
                command => '314',
                params  => [
                    $uid,
                    $was->{nick}, $was->{user}, $was->{host}, '*',
                    $was->{ircname},
                ],
            };
            push @$ref, {
                prefix  => $sid,
                command => '338',
                params  => [
                    $uid,
                    $was->{nick},
                    join('@', $was->{user}, $was->{real}),
                    $was->{sock},
                    'Actual user@host, actual IP',
                ],
            } if $is_oper;
            push @$ref, {
                prefix  => $sid,
                command => '330',
                params  => [
                    $uid,
                    $was->{nick},
                    $was->{account},
                    'was logged in as',
                ],
            } if $was->{account} ne '*';
            push @$ref, {
                prefix  => $sid,
                command => '312',
                params  => [
                    $uid,
                    $was->{nick},
                    ( ( $self->{config}{'hidden_servers'} && !$is_oper )
                      ? ( $self->{config}{'hidden_servers'}, $self->{config}{NETWORKDESC} ) : $was->{server} ),
                    strftime("%a %b %e %T %Y", localtime($was->{logoff})),
                ],
            };
            ++$cnt;
            last WASNOTWAS if $max && $cnt >= $max;
        }
    }

    push @$ref, {
        prefix  => $sid,
        command => '369',
        params  => [$uid, $query, 'End of WHOWAS'],
    };

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
            my $uid = $self->state_user_uid($nick);
            my $multiprefix = $self->{state}{uids}{$uid}{caps}{'multi-prefix'};
            my $record = $self->{state}{chans}{uc_irc($who)};
            $who = $record->{name};
            for my $member (keys %{ $record->{users} }) {
                my $rpl_who = {
                    prefix  => $server,
                    command => '352',
                    params  => [$nick, $who],
                };
                my $memrec = $self->{state}{uids}{$member};
                push @{ $rpl_who->{params} }, $memrec->{auth}{ident};
                push @{ $rpl_who->{params} }, $memrec->{auth}{hostname};
                push @{ $rpl_who->{params} }, $memrec->{server};
                push @{ $rpl_who->{params} }, $memrec->{nick};
                my $status = ($memrec->{away} ? 'G' : 'H');
                $status .= '*' if $memrec->{umode} =~ /o/;
                {
                  my $stat = $record->{users}{$member};
                  if ( $stat ) {
                    if ( !$multiprefix ) {
                      $stat =~ s![vh]!!g if $stat =~ /o/;
                      $stat =~ s![v]!!g  if $stat =~ /h/;
                    }
                    else {
                      my $ostat = join '', grep { $stat =~ m!$_! } qw[o h v];
                      $stat = $ostat;
                    }
                    $stat =~ tr/ohv/@%+/;
                    $status .= $stat;
                  }
                }
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
    my $sid      = $self->server_sid();
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
        my $notop   = 0;
        my $notoper = 0;
        my $nick_is_op   = $self->state_is_chan_op($nick, $chan);
        my $nick_is_hop  = $self->state_is_chan_hop($nick, $chan);
        my $nick_is_oper = $self->state_user_is_operator($nick);
        my $no_see_bans  = ( $record->{mode} =~ /u/ && !( $nick_is_op || $nick_is_hop ) );
        my $mode_u_set   = ( $record->{mode} =~ /u/ );
        my $reply;
        my @reply_args; my %subs;
        my $parsed_mode = parse_mode_line(@$args);
        my $mode_count = 0;

        while (my $mode = shift @{ $parsed_mode->{modes} }) {
            if ($mode !~ /[CceIbkMNRSTLOlimnpstohuv]/) {
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
                } for grep { !$no_see_bans } keys %{ $record->{bans} };
                push @$ref, {
                    prefix  => $server,
                    command => '368',
                    params  => [$nick, $chan, 'End of Channel Ban List'],
                };
                next;
            }
            if ($mode =~ m![OL]! && !$nick_is_oper) {
                push @$ref, ['481'] if !$notoper;
                $notoper++;
                next;
            }
            if (!$nick_is_op && !$nick_is_hop && $mode !~ m![OL]!) {
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
                } for grep { !$no_see_bans } keys %{ $record->{invex} };
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
                } for grep { !$no_see_bans } keys %{ $record->{excepts} };
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
                    && $record->{users}{$self->state_user_uid($arg)} !~ /$char/) {
                    # Update user and chan record
                    $arg = $self->state_user_uid($arg);
                    $record->{users}{$arg} = join('', sort
                        split //, $record->{users}{$arg} . $char);
                    $self->{state}{uids}{$arg}{chans}{uc_irc($chan)}
                        = $record->{users}{$arg};
                    $reply .= $mode;
                    my $anick = $self->state_user_nick($arg);
                    $subs{$anick} = $arg;
                    push @reply_args, $anick;
                }

                if ($flag eq '-' && $record->{users}{uc_irc($arg)}
                    =~ /$char/) {
                    # Update user and chan record
                    $arg = $self->state_user_uid($arg);
                    $record->{users}{$arg} =~ s/$char//g;
                    $self->{state}{uids}{$arg}{chans}{uc_irc($chan)}
                        = $record->{users}{$arg};
                    $reply .= $mode;
                    my $anick = $self->state_user_nick($arg);
                    $subs{$anick} = $arg;
                    push @reply_args, $anick;
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
        my $maxbans = ( $record->{mode} =~ m!L! ? $self->{config}{max_bans_large} : $self->{config}{MAXBANS} );
        if (my ($flag) = $mode =~ /([-+])b/) {
            next if ++$mode_count > $maxmodes;
            my $mask = normalize_mask($arg);
            my $umask = uc_irc $mask;
            if ($flag eq '+' && !$record->{bans}{$umask}) {
                if ( keys %{ $record->{bans} } >= $maxbans ) {
                    push @$ref, [ '478', $record->{name}, 'b' ];
                    next;
                }
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
                if ( keys %{ $record->{invex} } >= $maxbans ) {
                    push @$ref, [ '478', $record->{name}, 'I' ];
                    next;
                }
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
                    if ( keys %{ $record->{excepts} } >= $maxbans ) {
                        push @$ref, [ '478', $record->{name}, 'e' ];
                        next;
                    }
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
                $reply  .= $mode;
                $record->{mode} = join('', sort
                    split //, $record->{mode} . $char);
                next;
            }
            if ($flag eq '-' && $record->{mode} =~ /$char/) {
                $reply  .= $mode;
                $record->{mode} =~ s/$char//g;
                next;
            }
        } # while

        if ($reply) {
            $reply = unparse_mode_line($reply);
            my @reply_args_peer = map {
              ( defined $subs{$_} ? $subs{$_} : $_ )
            } @reply_args;
            $self->send_output(
               {
                  prefix  => $self->state_user_uid($nick),
                  command => 'TMODE',
                  params  => [$record->{ts}, $chan, $reply, @reply_args_peer],
                  colonify => 0,
               },
               $self->_state_connected_peers(),
            );
            my $full = $self->state_user_full($nick);
            $self->_send_output_channel_local(
                $record->{name},
                {
                    prefix   => $full,
                    command  => 'MODE',
                    colonify => 0,
                    params   => [
                        $record->{name},
                        $reply,
                        @reply_args,
                    ],
                },
                '', ( $mode_u_set ? 'oh' : '' ),
            );
            if ($mode_u_set) {
                my $bparse = parse_mode_line( $reply, @reply_args );
                my $breply; my @breply_args;
                while (my $bmode = shift (@{ $bparse->{modes} })) {
                    my $arg;
                    $arg = shift @{ $bparse->{args} }
                      if $bmode =~ /^(\+[ohvklbIe]|-[ohvbIe])/;
                      next if $bmode =~ m!^[+-][beI]$!;
                      $breply .= $bmode;
                      push @breply_args, $arg if $arg;
                }
                if ($breply) {
                   my $parsed_line = unparse_mode_line($breply);
                   $self->_send_output_channel_local(
                      $record->{name},
                      {
                          prefix   => $full,
                          command  => 'MODE',
                          colonify => 0,
                          params   => [
                              $record->{name},
                              $parsed_line,
                              @breply_args,
                          ],
                      },
                      '','-oh',
                   );
                }
            }
        }
    } # SWITCH

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_join {
    my $self     = shift;
    my $nick     = shift || return;
    my $server   = $self->server_name();
    my $sid      = $self->server_sid();
    my $ref      = [ ];
    my $args     = [@_];
    my $count    = @$args;
    my $route_id = $self->_state_user_route($nick);
    my $uid      = $self->state_user_uid($nick);
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
        my $nick_is_oper = $self->state_user_is_operator($nick);

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
                && !$nick_is_oper) {
                $self->_send_output_to_client(
                    $route_id,
                    '405',
                    $channel,
                );
                next LOOP;
            }
            # Channel is RESV
            if (my $reason = $self->_state_is_resv($channel,$route_id)) {
                if ( !$nick_is_oper ) {
                    $self->_send_to_realops(
                        sprintf(
                            'Forbidding reserved channel %s from user %s',
                            $channel,
                            $self->state_user_full($nick),
                        ),
                        'Notice',
                        'j',
                    );
                    $self->_send_output_to_client(
                        $route_id,
                        '485',
                        $channel,
                        $reason,
                    );
                    next LOOP;
                }
            }
            # Channel doesn't exist
            if (!$self->state_chan_exists($channel)) {
                my $record = {
                    name  => $channel,
                    ts    => time,
                    mode  => 'nt',
                    users => { $uid => 'o' },
                };
                $self->{state}{chans}{$uchannel} = $record;
                $self->{state}{users}{$unick}{chans}{$uchannel} = 'o';
                my @peers = $self->_state_connected_peers();
                $self->send_output(
                    {
                        prefix  => $sid,
                        command => 'SJOIN',
                        params  => [
                            $record->{ts},
                            $channel,
                            '+' . $record->{mode},
                            '@' . $uid,
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
                next LOOP;
            }
            # Numpty user is already on channel
            if ($self->state_is_chan_member($nick, $channel)) {
                next LOOP;
            }
            my $chanrec = $self->{state}{chans}{$uchannel};
            my $bypass;
            if ($nick_is_oper && $self->{config}{OPHACKS}) {
                $bypass = 1;
            }
            # OPER only channel +O
            if ($chanrec->{mode} =~ /O/ && !$nick_is_oper) {
                push @$ref, ['520',$chanrec->{name}];
                next LOOP;
            }
            my $umode = $self->state_user_umode($nick);
            # SSL only channel +S
            if ($chanrec->{mode} =~ /S/ && $umode !~ /S/) {
                push @$ref, ['489',$chanrec->{name}];
                next LOOP;
            }
            # Registered users only +R
            if($chanrec->{mode} =~ /R/ && $umode !~ /r/) {
                push @$ref, ['477',$chanrec->{name}];
                next LOOP;
            }
            # Channel is full
            if (!$bypass && $chanrec->{mode} =~ /l/
                && keys %{$chanrec->{users}} >= $chanrec->{climit}) {
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
            # Spambot checks
            $self->state_check_spambot_warning($nick,$channel) if !$nick_is_oper;
            $self->state_check_joinflood_warning($nick,$channel) if !$nick_is_oper;
            # JOIN the channel
            delete $self->{state}{users}{$unick}{invites}{$uchannel};
            delete $self->{state}{chans}{$uchannel}{invites}{$uid};
            # Add user
            $self->{state}{uids}{$uid}{chans}{$uchannel} = '';
            $self->{state}{chans}{$uchannel}{users}{$uid} = '';
            # Send JOIN message to peers and local users.
            $self->send_output(
                {
                    prefix  => $uid,
                    command => 'JOIN',
                    params  => [$chanrec->{ts}, $channel, '+'],
                },
                $self->_state_connected_peers(),
            ) if $channel !~ /^&/;

            my $output = {
                prefix  => $self->state_user_full($nick),
                command => 'JOIN',
                params  => [$channel],
            };
            my $extout = {
                prefix  => $self->state_user_full($nick),
                command => 'JOIN',
                params  => [
                    $channel,
                    $self->{state}{uids}{$uid}{account},
                    $self->{state}{uids}{$uid}{ircname},
                ],
            };
            $self->_send_output_to_client($route_id, $output);
            $self->_send_output_channel_local($channel, $output, $route_id, '', '', 'extended-join');
            $self->_send_output_channel_local($channel, $extout, $route_id, '', 'extended-join');

            # Send NAMES and TOPIC to client
            $self->_send_output_to_client(
                $route_id,
                (ref $_ eq 'ARRAY' ? @$_ : $_),
            ) for $self->_daemon_cmd_names($nick, $channel);
            $self->_send_output_to_client(
                $route_id,
                (ref $_ eq 'ARRAY' ? @$_ : $_),
            ) for $self->_daemon_cmd_topic($nick, $channel);

            if ( $self->{state}{uids}{$uid}{away} ) {
                $self->_state_do_away_notify($uid,$channel,$self->{state}{uids}{$uid}{away});
            }
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

        $chan = $self->_state_chan_name($chan);
        my $uid = $self->state_user_uid($nick);
        my $urec = $self->{state}{uids}{$uid};

        my $pmsg = $args->[0];
        my $params = [ $chan ];

        if ( $pmsg and my $msgtime = $self->{config}{anti_spam_exit_message_time} ) {
           $pmsg = '' if time - $urec->{conn_time} < $msgtime;
        }

        if ( $pmsg && !$self->state_can_send_to_channel($nick,$chan,$pmsg,'PART') ) {
           $pmsg = '';
        }

        push @$params, $pmsg if $pmsg;

        $self->state_check_spambot_warning($nick) if $urec->{umode} !~ /o/;

        $self->send_output(
            {
                prefix  => $uid,
                command => 'PART',
                params  => $params,
            },
            $self->_state_connected_peers(),
        );
        $self->_send_output_channel_local(
            $chan,
            {
                prefix  => $self->state_user_full($nick),
                command => 'PART',
                params  => $params,
            },
        );

        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$uid};
        delete $self->{state}{uids}{$uid}{chans}{$chan};
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
        if (!$self->state_is_chan_op($nick, $chan) && !$self->state_is_chan_hop($nick, $chan)) {
            push @$ref, ['482', $chan];
            last SWITCH;
        }
        if (!$self->state_nick_exists($who) ) {
            push @$ref, ['401', $who];
            last SWITCH;
        }
        $who = $self->state_user_nick($who);
        if (!$self->state_is_chan_member($who, $chan)) {
            push @$ref, ['441', $who, $chan];
            last SWITCH;
        }
        if (
             $self->state_is_chan_hop($nick, $chan) &&
             !$self->state_is_chan_op($nick, $chan) &&
             $self->state_is_chan_op($who, $chan)
           ) {
               push @$ref, ['482', $chan];
               last SWITCH;
        }
        my $comment = $args->[2] || $who;
        my $uid  = $self->state_user_uid($nick);
        my $wuid = $self->state_user_uid($who);
        $self->send_output(
            {
                prefix  => $uid,
                command => 'KICK',
                params  => [$chan, $wuid, $comment],
            },
            $self->_state_connected_peers(),
        );
        $self->_send_output_channel_local(
            $chan,
            {
                prefix  => $self->state_user_full($nick),
                command => 'KICK',
                params  => [$chan, $who, $comment],
            },
        );
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$wuid};
        delete $self->{state}{uids}{$wuid}{chans}{$chan};
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
        if (!$self->state_is_chan_op($nick, $chan) && !$self->state_is_chan_hop($nick, $chan)) {
            push @$ref, ['482', $chan];
            last SWITCH;
        }
        if (!$self->state_nick_exists($who) ) {
            push @$ref, ['401', $who];
            last SWITCH;
        }
        $who = $self->state_user_nick($who);
        if (!$self->state_is_chan_member($who, $chan)) {
            push @$ref, ['441', $who, $chan];
            last SWITCH;
        }
        if (
             $self->state_is_chan_hop($nick, $chan) &&
             !$self->state_is_chan_op($nick, $chan) &&
             $self->state_is_chan_op($who, $chan)
           ) {
               push @$ref, ['482', $chan];
               last SWITCH;
        }
        my $comment = "Requested by $nick";
        $comment .= qq{ "$args->[2]"} if $args->[2];
        my $uid = $self->state_user_uid($who);
        $self->send_output(
            {
                prefix  => $uid,
                command => 'PART',
                params  => [$chan, $comment],
            },
            $self->_state_connected_peers(),
        );
        $self->_send_output_channel_local(
            $chan,
            {
                prefix  => $self->state_user_full($who),
                command => 'PART',
                params  => [$chan, $comment],
            },
        );
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$uid};
        delete $self->{state}{uids}{$uid}{chans}{$chan};
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
    my $sid    = $self->server_sid();
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
                && ( !$self->state_is_chan_op($nick, $chan)
                 || !$self->state_is_chan_hop($nick, $chan) ) ) {
            push @$ref, ['482', $chan];
            last SWITCH;
        }
        my $local; my $invite_only;
        my $wuid = $self->state_user_uid($who);
        my $settime = time;
        # Only store the INVITE if the channel is invite-only
        if ($self->state_chan_mode_set($chan, 'i')) {
           $self->{state}{chans}{uc_irc $chan}{invites}{$wuid} = $settime;
           if ($self->_state_is_local_uid($wuid)) {
              my $record = $self->{state}{uids}{$wuid};
              $record->{invites}{uc_irc($chan)} = $settime;
              $local = 1;
           }
           $invite_only = 1;
        }
        my $invite;
        {
          my $route_id = $self->_state_uid_route($wuid);
          $invite = {
              prefix   => $self->state_user_full($nick),
              command  => 'INVITE',
              params   => [$who, $chan],
              colonify => 0,
          };
          if ($route_id eq 'spoofed') {
              $self->send_event(
                  "daemon_invite",
                  $invite->{prefix},
                  @{ $invite->{params} }
              );
          }
          elsif ( $local ) {
              $self->send_output($invite, $route_id);
          }
        }
        # Send INVITE to all connected peers
        $self->send_output(
            {
              prefix   => $self->state_user_uid($nick),
              command  => 'INVITE',
              params   => [ $wuid, $chan, $self->_state_chan_timestamp($chan) ],
              colonify => 0,
            },
            $self->_state_connected_peers(),
        );
        push @$ref, {
            prefix  => $server,
            command => '341',
            params  => [$chan, $who],
        };
        # Send NOTICE to local channel +oh users or invite-notify if applicable
        if ( $invite_only ) {
           my $notice = {
               prefix  => $server,
               command => 'NOTICE',
               params  => [
                   $chan,
                   sprintf(
                      "%s is inviting %s to %s.",
                      $nick,
                      $who,
                      $chan,
                   ),
               ],
           };
           $self->_send_output_channel_local($chan,$notice,'','oh','','invite-notify'); # Traditional NOTICE
           $self->_send_output_channel_local($chan,$invite,'','oh','invite-notify',''); # invite-notify extension
        }
        my $away = $self->{state}{uids}{$wuid}{away};
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
    my $args   = [ @_ ];
    my $count  = @$args;
    my $server = $self->server_name();
    my $ref    = [ ];
    my $record = $self->{state}{users}{uc_irc($nick)};

    if (!$count) {
        push @$ref, {
            prefix  => $server,
            command => '221',
            params  => [$nick, '+' . $record->{umode}],
        };
    }
    else {
        my $modestring = join('', @$args);
        $modestring =~ s/\s+//g;
        my $cnt += $modestring =~ s/[^a-zA-Z+-]+//g;
        $cnt += $modestring =~ s/[^DFGHRSWXabcdefgijklnopqrsuwy+-]+//g;

        # These can only be set by servers/services
        $modestring =~ s/[SWr]+//g;

        # These can only be set by an OPER
        $cnt += $modestring =~ s/[FHXabcdefjklnsuy]+//g if $record->{umode} !~ /o/;

        push @$ref, ['501'] if $cnt;

        my $umode = unparse_mode_line($modestring);
        my $peer_ignore;
        my $parsed_mode = parse_mode_line($umode);
        my $route_id = $self->_state_user_route($nick);
        my $previous = $record->{umode};

        while (my $mode = shift @{ $parsed_mode->{modes} }) {
            next if $mode eq '+o';
            my ($action, $char) = split //, $mode;
            if ($action eq '+' && $record->{umode} !~ /$char/) {
                $record->{umode} .= $char;
                if ($char eq 'i') {
                    $self->{state}{stats}{invisible}++;
                    $peer_ignore = delete $record->{_ignore_i_umode};
                }
                if ($char eq 'w') {
                    $self->{state}{wallops}{$route_id} = time;
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
                    delete $record->{svstags}{313};
                }
                if ($char eq 'w') {
                    delete $self->{state}{wallops}{$route_id};
                }
                if ($char eq 'l') {
                    delete $self->{state}{locops}{$route_id};
                }
            }
        }

        $record->{umode} = join '', sort split //, $record->{umode};
        my $set = gen_mode_change($previous, $record->{umode});
        if ($set) {
            my $full = $self->state_user_full($nick);
            $self->send_output(
                {
                    prefix  => $record->{uid},
                    command => 'MODE',
                    params  => [$record->{uid}, $set],
                },
                $self->_state_connected_peers(),
            ) if !$peer_ignore;
            my $hashref = {
                prefix  => $full,
                command => 'MODE',
                params  => [$nick, $set],
            };
            $self->send_event(
                "daemon_umode",
                $full,
                $set,
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
        $self->send_output(
            {
                prefix  => $self->state_user_uid($nick),
                command => 'TOPIC',
                params  => [$chan_name, $args->[1]],
            },
            $self->_state_connected_peers(),
        );

        $self->_send_output_channel_local(
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

sub _daemon_cmd_map {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $isoper = $self->state_user_is_operator($nick);

    SWITCH: {
        if ( !$isoper ) {
            my $lastuse = $self->{state}{lastuse}{map};
            my $pacewait = $self->{config}{pace_wait};
            if ( $lastuse && $pacewait && ( $lastuse + $pacewait ) > time() ) {
                push @$ref, ['263', 'MAP'];
                last SWITCH;
            }
            $self->{state}{lastuse}{map} = time();
        }

        my $full = $self->state_user_full($nick);
        my $msg = sprintf('MAP requested by %s (%s) [%s]',
            $nick, (split /!/,$full)[1], $server,
        );

        $self->_send_to_realops( $msg, 'Notice', 'y' );

        push @$ref, $_ for
            $self->_state_do_map( $nick, $sid, $isoper, 0 );

        push @$ref, {
            prefix  => $server,
            command => '017',
            params => [
                $nick,
                'End of /MAP',
            ],
        };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_links {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $args   = [ @_ ];
    my $count  = @$args;
    my $ref    = [ ];

    SWITCH:{
        my $target;
        if ($count > 1 && !$self->state_peer_exists( $args->[0] )) {
            push @$ref, ['402', $args->[0]];
            last SWITCH;
        }
        my $lastuse  = $self->{state}{lastuse}{links};
        my $pacewait = $self->{config}{pace_wait};
        if ( $lastuse && $pacewait && ( $lastuse + $pacewait ) > time() ) {
            push @$ref, ['263', 'LINKS'];
            last SWITCH;
        }
        $self->{state}{lastuse}{links} = time();
        if ( $count > 1 ) {
          $target = shift @$args;
        }
        if ($target && uc $server ne uc $target) {
            $self->send_output(
                {
                    prefix  => $self->state_user_uid($nick),
                    command => 'LINKS',
                    params  => [
                        $self->_state_peer_sid($target),
                        $args->[0],
                    ],
                },
                $self->_state_peer_route($target)
            );
            last SWITCH;
        }

        $self->_send_to_realops(
            sprintf(
               'LINKS requested by %s (%s) [%s]',
               $nick, (split /!/,$self->state_user_full($nick))[1], $server,
            ), qw[Notice y],
        );

        my $mask = shift @$args || '*';

        push @$ref, $_ for
                 @{ $self->_daemon_do_links($nick,$server,$mask) };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_do_links {
    my $self   = shift;
    my $client = shift || return;
    my $prefix = shift || return;
    my $mask   = shift || return;
    my $sid    = $self->server_sid();
    my $server = $self->server_name();
    my $ref    = [ ];

    for ($self->_state_sid_links($sid, $prefix, $client, $mask)) {
         push @$ref, $_;
    }
    push @$ref, {
        prefix  => $prefix,
        command => '364',
        params  => [
            $client,
            $server,
            $server,
            join( ' ', '0', $self->server_config('serverdesc'))
        ],
    } if matches_mask($mask, $server);
    push @$ref, {
        prefix  => $prefix,
        command => '365',
        params  => [$client, $mask, 'End of /LINKS list.'],
    };

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_cmd_knock {
    my $self   = shift;
    my $nick   = shift || return;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
    my $args   = [ @_ ];
    my $count  = @$args;
    my $ref    = [ ];

    SWITCH:{
        if (!$count) {
            push @$ref, ['461', 'KNOCK'];
            last SWITCH;
        }
        my $channel = shift @$args;
        if ( !$self->state_chan_exists($channel) ) {
            push @$ref, ['401', $channel];
            last SWITCH;
        }
        if ( $self->state_is_chan_member($nick,$channel) ) {
            push @$ref, ['714', $channel];
            last SWITCH;
        }
        my $chanrec = $self->{state}{chans}{uc_irc $channel};
        if ( !( $chanrec->{mode} =~ /i/ || $chanrec->{ckey} || ($chanrec->{mode} =~ /l/
             && keys %{$chanrec->{users}} >= $chanrec->{climit}) ) )  {
            push @$ref, ['713', $channel];
            last SWITCH;
        }
        if ( $chanrec->{mode} =~ /p/ || $self->_state_user_banned($nick,$channel) ) {
            push @$ref, ['404', $channel];
            next SWITCH;
        }

        my $uid = $self->state_user_uid($nick);
        my $rec = $self->{state}{uids}{$uid};

        if ( !$rec->{last_knock} ) {
            $rec->{knock_count} = 0;
        }
        if ( $rec->{last_knock} && ( $rec->{last_knock} + $self->{config}{knock_client_time} ) < time() ) {
            $rec->{knock_count} = 0;
        }
        if ( $rec->{knock_count} && $rec->{knock_count} > $self->{config}{knock_client_count} ) {
            push @$ref, ['712', $channel,'user'];
            last SWITCH;
        }
        if ( $chanrec->{last_knock} && ( $chanrec->{last_knock} + $self->{config}{knock_delay_channel} ) > time() ) {
            push @$ref, ['712', $channel,'channel'];
            last SWITCH;
        }

        $rec->{last_knock} = time();
        $rec->{knock_count}++;

        push @$ref, ['711', $channel]; # KNOCK Delivered

        $chanrec->{last_knock} = time();

        $self->_send_output_channel_local(
            $channel,
            {
                prefix  => $server,
                command => 'NOTICE',
                params  => [
                    $chanrec->{name},
                    sprintf("KNOCK: %s (%s [%s] has asked for an invite)",
                        $chanrec->{name}, split /!/, $rec->{full}->() ),
                ],
            },
            '', 'oh',
        );
        $self->send_output(
            {
                prefix   => $uid,
                command  => 'KNOCK',
                colonify => 0,
                params   => [ $chanrec->{name} ],
            },
            grep { $self->_state_peer_capab($_,'KNOCK') }
              $self->_state_connected_peers(),
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_certfp {
    my $self       = shift;
    my $peer_id    = shift || return;
    my $prefix     = shift || return;
    my $ref        = [ ];
    my $args       = [@_];

    SWITCH: {
        if ($prefix !~ $uid_re) {
            last SWITCH;
        }
        if(!$args->[0]) {
            last SWITCH;
        }
        my $uid = $self->state_user_uid($prefix);
        last SWITCH if !$uid;
        $self->{state}{uids}{$uid}{certfp} = $args->[0];
        $self->send_output(
            {
                prefix   => $prefix,,
                command  => 'CERTFP',
                colonify => 0,
                params   => $args,
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_knock {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count) {
            last SWITCH;
        }
        my $channel = shift @$args;
        if ( !$self->state_chan_exists($channel) ) {
            last SWITCH;
        }
        my $chanrec = $self->{state}{chans}{uc_irc $channel};
        $chanrec->{last_knock} = time();
        $self->_send_output_channel_local(
            $channel,
            {
                prefix  => $self->server_name(),
                command => 'NOTICE',
                params  => [
                    $chanrec->{name},
                    sprintf("KNOCK: %s (%s [%s] has asked for an invite)",
                        $chanrec->{name}, split /!/, $self->state_user_full($prefix) ),
                ],
            },
            '', 'oh',
        );
        $self->send_output(
            {
                prefix   => $prefix,,
                command  => 'KNOCK',
                colonify => 0,
                params   => [ $chanrec->{name} ],
            },
            grep { $_ ne $peer_id && $self->_state_peer_capab($_,'KNOCK') }
              $self->_state_connected_peers(),
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_squit {
    my $self    = shift;
    my $peer_id = shift || return;
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    return if !$self->state_sid_exists($args->[0]);

    SWITCH: {
        if ($peer_id ne $self->_state_sid_route($args->[0])) {
            $self->send_output(
                {
                    command => 'SQUIT',
                    params  => $args,
                },
                $self->_state_sid_route($args->[0]),
            );
            last SWITCH;
        }
        if ($peer_id eq $self->_state_sid_route($args->[0])) {
            $self->send_output(
                {
                    command => 'SQUIT',
                    params  => $args,
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            my $qsid  = $args->[0];
            my $qpeer = $self->_state_sid_name($qsid);
            $self->send_event("daemon_squit", $qpeer, $args->[1]);
            my $quit_msg = join ' ',
                $self->{state}{sids}{$qsid}{peer}, $qpeer;

            if ($sid eq $self->{state}{sids}{$qsid}{psid}) {
                my $stats = $self->{state}{conns}{$peer_id}{stats}->stats();
                $self->_send_to_realops(
                    sprintf(
                      '%s was connected for %s. %s/%s sendK/recvK.',
                      $qpeer, _duration(time() - $self->{state}{sids}{$qsid}{conn_time}),
                      ( $stats->[0] >> 10 ), ( $stats->[1] >> 10 ),
                    ), qw[Notice e],
                );
            }
            else {
                $self->_send_to_realops(
                    sprintf(
                      'Server %s split from %s',
                      $qpeer, $self->{state}{sids}{$qsid}{peer},
                    ), qw[Notice e],
                );
            }
            for my $uid ($self->_state_server_squit($qsid)) {
                my $output = {
                    prefix  => $self->state_user_full($uid),
                    command => 'QUIT',
                    params  => [$quit_msg],
                };
                my $common = { };
                for my $uchan ( keys %{ $self->{state}{uids}{$uid}{chans} } ) {
                    delete $self->{state}{chans}{$uchan}{users}{$uid};
                    for my $user ( keys %{ $self->{state}{chans}{$uchan}{users} } ) {
                        next if $user !~ m!^$sid!;
                        $common->{$user} = $self->_state_uid_route($user);
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
                my $record = delete $self->{state}{uids}{$uid};
                my $nick = uc_irc $record->{nick};
                delete $self->{state}{users}{$nick};
                # WATCH LOGOFF
                if ( defined $self->{state}{watches}{$nick} ) {
                  my $laston = time();
                  $self->{state}{watches}{$nick}{laston} = $laston;
                  foreach my $wuid ( keys %{ $self->{state}{watches}{$nick}{uids} } ) {
                    next if !defined $self->{state}{uids}{$wuid};
                    my $wrec = $self->{state}{uids}{$wuid};
                    $self->send_output(
                      {
                          prefix  => $record->{server},
                          command => '601',
                          params  => [
                              $wrec->{nick},
                              $record->{nick},
                              $record->{auth}{ident},
                              $record->{auth}{hostname},
                              $laston,
                              'logged offline',
                          ],
                      },
                      $wrec->{route_id},
                    );
                  }
                }
                if ($record->{umode} =~ /o/) {
                    $self->{state}{stats}{ops_online}--;
                }
                if ($record->{umode} =~ /i/) {
                    $self->{state}{stats}{invisible}--;
                }
                unshift @{ $self->{state}{whowas}{$nick} }, {
                    logoff  => time(),
                    account => $record->{account},
                    nick    => $record->{nick},
                    user    => $record->{auth}{ident},
                    host    => $record->{auth}{hostname},
                    real    => $record->{auth}{realhost},
                    sock    => $record->{ipaddress},
                    ircname => $record->{ircname},
                    server  => $record->{server},
                };
            }
            last SWITCH;
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_resv {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count || $count < 3) {
            last SWITCH;
        }
        my ($peermask,$duration,$mask,$reason) = @$args;
        $reason = '<No reason supplied>' if !$reason;
        my $us = 0;
        {
          my %targpeers;
          my $sids = $self->{state}{sids};
          foreach my $psid ( keys %{ $sids } ) {
             if (matches_mask($peermask, $sids->{$psid}{name})) {
                if ($sid eq $psid) {
                   $us = 1;
                }
                else {
                   $targpeers{ $sids->{$psid}{route_id} }++;
                }
             }
          }
          delete $targpeers{$peer_id};
          $self->send_output(
                {
                    prefix  => $uid,
                    command => 'RESV',
                    params  => [
                        $peermask,
                        $duration,
                        $mask,
                        $reason,
                    ],
                },
                grep { $self->_state_peer_capab($_, 'CLUSTER') } keys %targpeers,
            );
        }

        last SWITCH if !$us;

        if ( !$reason ) {
          $reason = shift @$args || '<No reason supplied>';
        }

        if ( $self->_state_have_resv($mask) ) {
           push @$ref, {
              prefix  => $sid,
              command => 'NOTICE',
              params  => [ $uid, "A RESV has already been placed on: $mask" ],
          };
          last SWITCH;
        }

        my $full = $self->state_user_full($uid);

        last SWITCH if !$self->_state_add_drkx_line( 'resv', $full, time(), $server,
                                                     $duration, $mask, $reason );
        my $minutes = $duration / 60;

        $self->send_event(
            "daemon_resv",
            $full,
            $mask,
            $minutes,
            $reason,
        );

        my $temp = $duration ? "temporary $minutes min. " : '';

        my $reply_notice = "Added ${temp}RESV [$mask]";
        my $locop_notice = "$full added ${temp}RESV for [$mask] [$reason]";

        push @$ref, {
            prefix  => $sid,
            command => 'NOTICE',
            params  => [ $uid, $reply_notice ],
        };

        $self->_send_to_realops( $locop_notice, 'Notice', 's' );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_unresv {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;


    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my ($peermask,$unmask) = @$args;
        my $us = 0;
        {
          my %targpeers;
          my $sids = $self->{state}{sids};
          foreach my $psid ( keys %{ $sids } ) {
             if (matches_mask($peermask, $sids->{$psid}{name})) {
                if ($sid eq $psid) {
                   $us = 1;
                }
                else {
                   $targpeers{ $sids->{$psid}{route_id} }++;
                }
             }
          }
          delete $targpeers{$peer_id};
          $self->send_output(
                {
                    prefix  => $uid,
                    command => 'UNRESV',
                    params  => [
                        $peermask,
                        $unmask,
                    ],
                    colonify => 0,
                },
                grep { $self->_state_peer_capab($_, 'CLUSTER') } keys %targpeers,
            );
        }

        last SWITCH if !$us;

        my $result = $self->_state_del_drkx_line( 'resv', $unmask );

        my $full = $self->state_user_full($uid);

        if ( !$result ) {
           push @$ref, { prefix => $server, command => 'NOTICE', params => [ $uid, "No RESV for [$unmask] found" ] };
           last SWITCH;
        }

        $self->send_event(
            "daemon_unresv",
            $full,
            $unmask,
        );

        push @$ref, {
            prefix  => $sid,
            command => 'NOTICE',
            params  => [ $uid, "RESV for [$unmask] is removed" ],
        };

        $self->_send_to_realops( "$full has removed the RESV for: [$unmask]", 'Notice', 's' );

    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_xline {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count || $count < 3) {
            last SWITCH;
        }
        my ($peermask,$duration,$mask,$reason) = @$args;
        $reason = '<No reason supplied>' if !$reason;
        my $us = 0;
        {
          my %targpeers;
          my $sids = $self->{state}{sids};
          foreach my $psid ( keys %{ $sids } ) {
             if (matches_mask($peermask, $sids->{$psid}{name})) {
                if ($sid eq $psid) {
                   $us = 1;
                }
                else {
                   $targpeers{ $sids->{$psid}{route_id} }++;
                }
             }
          }
          delete $targpeers{$peer_id};
          $self->send_output(
                {
                    prefix  => $uid,
                    command => 'XLINE',
                    params  => [
                        $peermask,
                        $duration,
                        $mask,
                        $reason,
                    ],
                },
                grep { $self->_state_peer_capab($_, 'CLUSTER') } keys %targpeers,
            );
        }

        last SWITCH if !$us;

        if ( !$reason ) {
          $reason = shift @$args || '<No reason supplied>';
        }

        my $full = $self->state_user_full($uid);

        last SWITCH if !$self->_state_add_drkx_line( 'xline', $full, time(), $server,
                                                     $duration, $mask, $reason );
        my $minutes = $duration / 60;

        $self->send_event(
            "daemon_xline",
            $full,
            $mask,
            $minutes,
            $reason,
        );

        my $temp = $duration ? "temporary $minutes min. " : '';

        my $reply_notice = "Added ${temp}X-Line [$mask]";
        my $locop_notice = "$full added ${temp}X-Line for [$mask] [$reason]";

        push @$ref, {
            prefix  => $sid,
            command => 'NOTICE',
            params  => [ $uid, $reply_notice ],
        };

        $self->_send_to_realops( $locop_notice, 'Notice', 's' );

        $self->_state_do_local_users_match_xline($mask,$reason);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_unxline {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;


    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my ($peermask,$unmask) = @$args;
        my $us = 0;
        {
          my %targpeers;
          my $sids = $self->{state}{sids};
          foreach my $psid ( keys %{ $sids } ) {
             if (matches_mask($peermask, $sids->{$psid}{name})) {
                if ($sid eq $psid) {
                   $us = 1;
                }
                else {
                   $targpeers{ $sids->{$psid}{route_id} }++;
                }
             }
          }
          delete $targpeers{$peer_id};
          $self->send_output(
                {
                    prefix  => $uid,
                    command => 'UNXLINE',
                    params  => [
                        $peermask,
                        $unmask,
                    ],
                    colonify => 0,
                },
                grep { $self->_state_peer_capab($_, 'CLUSTER') } keys %targpeers,
            );
        }

        last SWITCH if !$us;

        my $result = $self->_state_del_drkx_line( 'xline', $unmask );

        my $full = $self->state_user_full($uid);

        if ( !$result ) {
           push @$ref, { prefix => $server, command => 'NOTICE', params => [ $uid, "No X-Line for [$unmask] found" ] };
           last SWITCH;
        }

        $self->send_event(
            "daemon_unxline",
            $full,
            $unmask,
        );

        push @$ref, {
            prefix  => $sid,
            command => 'NOTICE',
            params  => [ $uid, "X-Line for [$unmask] is removed" ],
        };

        $self->_send_to_realops( "$full has removed the X-Line for: [$unmask]", 'Notice', 's' );

    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_dline {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count || $count < 3) {
            last SWITCH;
        }
        my ($peermask,$duration,$netmask,$reason) = @$args;
        $reason = '<No reason supplied>' if !$reason;
        my $us = 0;
        {
          my %targpeers;
          my $sids = $self->{state}{sids};
          foreach my $psid ( keys %{ $sids } ) {
             if (matches_mask($peermask, $sids->{$psid}{name})) {
                if ($sid eq $psid) {
                   $us = 1;
                }
                else {
                   $targpeers{ $sids->{$psid}{route_id} }++;
                }
             }
          }
          delete $targpeers{$peer_id};
          $self->send_output(
                {
                    prefix  => $uid,
                    command => 'DLINE',
                    params  => [
                        $peermask,
                        $duration,
                        $netmask,
                        $reason,
                    ],
                },
                grep { $self->_state_peer_capab($_, 'DLN') } keys %targpeers,
            );
        }

        last SWITCH if !$us;

        $netmask = Net::CIDR::cidrvalidate($netmask);

        last SWITCH if !$netmask;

        my $full = $self->state_user_full($uid);

        my $minutes = $duration / 60;

        last SWITCH if !$self->_state_add_drkx_line( 'dline',
                                 $full, time, $server, $duration,
                                    $netmask, $reason );

        $self->send_event(
            "daemon_dline",
            $full,
            $netmask,
            $minutes,
            $reason,
        );

        $self->add_denial( $netmask, 'You have been D-lined.' );

        my $temp = $duration ? "temporary $minutes min. " : '';

        my $reply_notice = "Added ${temp}D-Line [$netmask]";
        my $locop_notice = "$full added ${temp}D-Line for [$netmask] [$reason]";

        push @$ref, {
            prefix  => $sid,
            command => 'NOTICE',
            params  => [ $uid, $reply_notice ],
        };

        $self->_send_to_realops( $locop_notice, 'Notice', 's' );

        $self->_state_do_local_users_match_dline($netmask,$reason);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_undline {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;


    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my ($peermask,$unmask) = @$args;
        my $us = 0;
        {
          my %targpeers;
          my $sids = $self->{state}{sids};
          foreach my $psid ( keys %{ $sids } ) {
             if (matches_mask($peermask, $sids->{$psid}{name})) {
                if ($sid eq $psid) {
                   $us = 1;
                }
                else {
                   $targpeers{ $sids->{$psid}{route_id} }++;
                }
             }
          }
          delete $targpeers{$peer_id};
          $self->send_output(
                {
                    prefix  => $uid,
                    command => 'UNDLINE',
                    params  => [
                        $peermask,
                        $unmask,
                    ],
                    colonify => 0,
                },
                grep { $self->_state_peer_capab($_, 'UNDLN') } keys %targpeers,
            );
        }

        last SWITCH if !$us;

        my $result = $self->_state_del_drkx_line( 'dline', $unmask );

        my $full = $self->state_user_full($uid);

        if ( !$result ) {
           push @$ref, { prefix => $sid, command => 'NOTICE', params => [ $uid, "No D-Line for [$unmask] found" ] };
           last SWITCH;
        }

        $self->send_event(
            "daemon_undline",
            $full,
            $unmask,
        );

        $self->del_denial( $unmask );

        push @$ref, {
            prefix  => $sid,
            command => 'NOTICE',
            params  => [ $uid, "D-Line for [$unmask] is removed" ],
        };

        $self->_send_to_realops( "$full has removed the D-Line for: [$unmask]", 'Notice', 's' );

    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_encap {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count) {
            last SWITCH;
        }
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
                prefix   => $prefix,
                command  => 'ENCAP',
                params   => $args,
                colonify => 1,
            },
            grep { $self->_state_peer_capab($_, 'ENCAP') } keys %targets,
        );

        last SWITCH if !$us;

        $self->send_event(
            'daemon_encap',
            ( $self->_state_sid_name($prefix) || $self->state_user_full($prefix) ),
            @$args,
        );

        # Add ENCAP subcommand handling here if required.
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_kline {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count || $count < 5) {
            last SWITCH;
        }
        my $full = $self->state_user_full($uid);
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
                prefix   => $uid,
                command  => 'KLINE',
                params   => $args,
                colonify => 0,
            },
            grep { $self->_state_peer_capab($_, 'KLN') } keys %targets,
        );

        last SWITCH if !$us;

        last SWITCH if !$self->_state_add_drkx_line( 'kline', $full, time(), @$args );

        my $minutes = $args->[1] / 60;
        $args->[1] = $minutes;

        $self->send_event("daemon_kline", $full, @$args);

        my $temp = $minutes ? "temporary $minutes min. " : '';

        my $reply_notice = sprintf('Added %sK-Line [%s@%s]', $temp, $args->[2], $args->[3]);
        my $locop_notice = sprintf('%s added %sK-Line for [%s@%s] [%s]',
                                   $full, $temp, $args->[2], $args->[3], $args->[4] );

        push @$ref, {
            prefix  => $self->server_sid(),
            command => 'NOTICE',
            params  => [ $uid, $reply_notice ],
        };

        $self->_send_to_realops( $locop_notice, 'Notice', 's' );

        $self->_state_do_local_users_match_kline($args->[2], $args->[3], $args->[4]);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_unkline {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    # :klanker UNKLINE logserv.gumbynet.org.uk * moos.loud.me.uk
    SWITCH: {
        if (!$count || $count < 3) {
            last SWITCH;
        }
        my $full = $self->state_user_full($uid);
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
                prefix   => $uid,
                command  => 'UNKLINE',
                params   => $args,
                colonify => 0,
            },
            grep { $self->_state_peer_capab($_, 'UNKLN') } keys %targets,
        );

        last SWITCH if !$us;

        my $result = $self->_state_del_drkx_line( 'kline', $args->[1], $args->[2] );

        my $sid  = $self->server_sid();

        my $unmask = join '@', $args->[1], $args->[2];

        if ( !$result ) {
           push @$ref, { prefix => $sid, command => 'NOTICE', params => [ $uid, "No K-Line for [$unmask] found" ] };
           last SWITCH;
        }

        $self->send_event("daemon_unkline", $full, @$args);

        push @$ref, {
            prefix  => $sid,
            command => 'NOTICE',
            params  => [ $uid, "K-Line for [$unmask] is removed" ],
        };

        $self->_send_to_realops( "$full has removed the K-Line for: [$unmask]", 'Notice', 's' );
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
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        # Prefix can either be SID or UID
        my $full = $self->_state_sid_name( $prefix );
        $full = $self->state_user_full( $prefix ) if !$full;

        $self->send_output(
            {
                prefix  => $full,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            keys %{ $self->{state}{wallops} },
         );
         $self->send_event("daemon_wallops", $full, $args->[0]);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_globops {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        # Hot potato
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'GLOBOPS',
                params  => [$args->[0]],
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        # Prefix can either be SID or UID
        my $full = $self->_state_sid_name( $prefix );
        $full = $self->state_user_nick( $prefix ) if !$full;

        my $msg  = "from $full: " . $args->[0];

        $self->_send_to_realops(
            $msg, 'globops', 's',
        );

        $self->send_event("daemon_globops", $full, $args->[0]);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_eob {
    my $self    = shift;
    my $peer_id = shift || return;
    my $peer    = shift || return;
    my $ref     = [ ];
    if ($self->{state}{conns}{$peer_id}{sid} eq $peer) {
        my $crec = $self->{state}{conns}{$peer_id};
        $self->_send_to_realops(
            sprintf(
                'End of burst from %s (%u seconds)',
                $crec->{name}, ( time() - $crec->{conn_time} ),
            ),
            'Notice',
            's',
        );
    }
    $self->send_event('daemon_eob', $self->{state}{sids}{$peer}{name}, $peer);
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_kill {
    my $self    = shift;
    my $peer_id = shift || return;
    my $killer  = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if ($self->state_sid_exists($args->[0])) {
            last SWITCH;
        }
        if (!$self->state_uid_exists($args->[0])) {
            last SWITCH;
        }

        my $target = $args->[0];
        my $comment = $args->[1];
        if ($self->_state_is_local_uid($target)) {
            my $route_id = $self->_state_uid_route($target);
            $self->send_output(
                {
                    prefix  => $killer,
                    command => 'KILL',
                    params  => [
                        $target,
                        join('!', $server, $comment),
                    ],
                }, grep { $_ ne $peer_id } $self->_state_connected_peers()
            );

            $self->send_output(
                {
                    prefix  => ( $self->_state_sid_name($killer) || $self->state_user_full($killer) ),
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
            $self->{state}{uids}{$target}{killed} = 1;
            $self->send_output(
                {
                    prefix  => $killer,
                    command => 'KILL',
                    params  => [$target, join('!', $server, $comment)],
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            $self->send_output(
                @{ $self->_daemon_peer_quit(
                    $target, "Killed ($killer ($comment))" ) },
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
    # SVINFO 6 6 0 :1525185763
    if ( !( $args->[0] eq '6' && $args->[1] eq '6' ) ) {
      $self->_terminate_conn_error($peer_id, 'Incompatible TS version');
      return;
    }
    $self->{state}{conns}{$peer_id}{svinfo} = $args;
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_ping {
    my $self    = shift;
    my $peer_id = shift || return;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $prefix  = shift;
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count) {
            last SWITCH;
        }
        if ($count >= 2 && $sid ne $args->[1]) {
            if ( $self->state_sid_exists($args->[1]) ) {
              $self->send_output(
                {
                    prefix  => $prefix,
                    command => 'PING',
                    params  => $args,
                },
                $self->_state_sid_route($args->[1]),
              );
              last SWITCH;
            }
            if ( $self->state_uid_exists($args->[1]) ) {
              my $route_id = $self->_state_uid_route($args->[1]);
              if ( $args->[1] =~ m!^$sid! ) {
                $self->send_output(
                  {
                    prefix  => $self->_state_sid_name($prefix),
                    command => 'PING',
                    params  => [ $args->[0], $self->state_user_nick($args->[1]) ],
                  },
                  $route_id,
                );
              }
              else {
                $self->send_output(
                  {
                    prefix  => $prefix,
                    command => 'PING',
                    params  => $args,
                  },
                  $route_id,
                );
              }
            }
            last SWITCH;
        }
        $self->send_output(
            {
                prefix  => $sid,
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
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $prefix  = shift;
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count) {
            last SWITCH;
        }
        if ($count >= 2 && uc $sid ne $args->[1]) {
            if ( $self->state_sid_exists($args->[1]) ) {
              $self->send_output(
                {
                    prefix  => $prefix,
                    command => 'PONG',
                    params  => $args,
                },
                $self->_state_sid_route($args->[1]),
              );
              last SWITCH;
            }
            if ( $self->state_uid_exists($args->[1]) ) {
              my $route_id = $self->_state_uid_route($args->[1]);
              if ( $args->[1] =~ m!^$sid! ) {
                $self->send_output(
                  {
                    prefix  => $self->_state_sid_name($prefix),
                    command => 'PONG',
                    params  => [ $args->[0], $self->state_user_nick($args->[1]) ],
                  },
                  $route_id,
                );
              }
              else {
                $self->send_output(
                  {
                    prefix  => $prefix,
                    command => 'PONG',
                    params  => $args,
                  },
                  $route_id,
                );
              }
              last SWITCH;
            }
        }
        delete $self->{state}{conns}{$peer_id}{pinged};
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_sid {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    my $peer    = $self->{state}{conns}{$peer_id}{name};

    #             0           1  2        3
    # :8H8 SID rhyg.dummy.net 2 0FU :ircd-hybrid test server
    # :0FU SID llestr.dummy.net 3 7UP :ircd-hybrid test server

    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        if ($args->[0] !~ $host_re) {
            $self->_send_to_realops(
                sprintf(
                    'Link %s[unknown@%s] introduced server with bogus server name %s',
                    $peer->{name}, $peer->{socket}[0], $args->[0],
                ), 'Notice', 's',
            );
            $self->_terminate_conn_error($peer_id, 'Bogus server name introduced');
            last SWITCH;
        }
        if ($args->[2] !~ $sid_re) {
            $self->_send_to_realops(
                sprintf(
                    'Link %s[unknown@%s] introduced server with bogus server ID %s',
                    $peer->{name}, $peer->{socket}[0], $args->[2],
                ), 'Notice', 's',
            );
            $self->_terminate_conn_error($peer_id, 'Bogus server ID introduced');
            last SWITCH;
        }
        if ($self->state_sid_exists($args->[2])) {
            my $prec = $self->{state}{conns}{$peer_id};
            $self->_send_to_realops(
                sprintf(
                    'Link %s[unknown@%s] cancelled, server ID %s already exists',
                    $prec->{name}, $prec->{socket}[0], $args->[2],
                ), 'Notice', 's',
            );
            $self->_terminate_conn_error($peer_id, 'Link cancelled, server ID already exists');
            last SWITCH;
        }
        if ($self->state_peer_exists($args->[0])) {
            my $prec = $self->{state}{conns}{$peer_id};
            $self->_send_to_realops(
                sprintf(
                    'Link %s[unknown@%s] cancelled, server %s already exists',
                    $prec->{name}, $prec->{socket}[0], $args->[0],
                ), 'Notice', 's',
            );
            $self->_terminate_conn_error($peer_id, 'Server exists');
            last SWITCH;
        }
        my $record = {
            name => $args->[0],
            hops => $args->[1],
            sid  => $args->[2],
            desc => ( $args->[3] || '' ),
            route_id => $peer_id,
            type => 'r',
            psid => $prefix,
            peer => $self->_state_sid_name( $prefix ),
            peers => { },
            users => { },
        };
        if ( $record->{desc} && $record->{desc} =~ m!^\(H\) ! ) {
            $record->{hidden} = 1;
            $record->{desc} =~ s!^\(H\) !!;
        }
        $self->{state}{sids}{ $prefix }{sids}{ $record->{sid} } = $record;
        $self->{state}{sids}{ $record->{sid} } = $record;
        my $uname = uc $record->{name};
        $record->{serv} = 1 if $self->{state}{services}{$uname};
        $self->{state}{peers}{$uname} = $record;
        $self->{state}{peers}{ uc $record->{peer} }{peers}{$uname} = $record;
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'SID',
                params  => [
                    $record->{name},
                    $record->{hops} + 1,
                    $record->{sid},
                    ( $record->{hidden} ? '(H) ' : '' ) .
                      $record->{desc},
                ],
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        $self->_send_to_realops(
            sprintf(
                'Server %s being introduced by %s',
                $record->{name}, $record->{peer},
            ),
            'Notice',
            'e',
        );
        $self->send_event(
            'daemon_sid',
            $record->{name},
            $prefix,
            $record->{hops},
            $record->{sid},
            $record->{desc},
        );
        $self->send_event(
            'daemon_server',
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
    my $uid     = shift || return;
    my $qmsg    = shift || 'Client Quit';
    my $conn_id = shift;
    my $ref     = [ ];
    my $sid     = $self->server_sid();

    my $record = delete $self->{state}{uids}{$uid};
    return $ref if !$record;
    my $full = $record->{full}->();
    my $nick = uc_irc($record->{nick});
    delete $self->{state}{users}{$nick};
    delete $self->{state}{sids}{ $record->{sid} }{users}{$nick};
    delete $self->{state}{sids}{ $record->{sid} }{uids}{$uid};
    $self->send_output(
        {
            prefix  => $uid,
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

    $self->_send_to_realops(
        sprintf(
            'Client exiting at %s: %s (%s@%s) [%s] [%s]',
            $record->{server}, $record->{nick}, $record->{auth}{ident},
            $record->{auth}{realhost}, $record->{ipaddress}, $qmsg,
        ),
        'Notice', 'F',
    );

    $self->send_event("daemon_quit", $full, $qmsg);

    # Remove for peoples accept lists
    delete $self->{state}{users}{$_}{accepts}{uc_irc($nick)}
        for keys %{ $record->{accepts} };

    # WATCH LOGOFF
    if ( defined $self->{state}{watches}{$nick} ) {
        my $laston = time();
        $self->{state}{watches}{$nick}{laston} = $laston;
        foreach my $wuid ( keys %{ $self->{state}{watches}{$nick}{uids} } ) {
            next if !defined $self->{state}{uids}{$wuid};
            my $wrec = $self->{state}{uids}{$wuid};
            $self->send_output(
                {
                    prefix  => $record->{server},
                    command => '601',
                    params  => [
                         $wrec->{nick},
                         $record->{nick},
                         $record->{auth}{ident},
                         $record->{auth}{hostname},
                         $laston,
                         'logged offline',
                    ],
                },
                $wrec->{route_id},
            );
        }
    }
    # Okay, all 'local' users who share a common channel with user.
    my $common = { };
    for my $uchan (keys %{ $record->{chans} }) {
        delete $self->{state}{chans}{$uchan}{users}{$uid};
        for my $user ( keys %{ $self->{state}{chans}{$uchan}{users} } ) {
            next if $user !~ m!^$sid!;
            $common->{$user} = $self->_state_uid_route($user);
        }
        if (!keys %{ $self->{state}{chans}{$uchan}{users} }) {
            delete $self->{state}{chans}{$uchan};
        }
     }

    push @$ref, $common->{$_} for keys %$common;
    $self->{state}{stats}{ops_online}-- if $record->{umode} =~ /o/;
    $self->{state}{stats}{invisible}-- if $record->{umode} =~ /i/;
    delete $self->{state}{peers}{uc $record->{server}}{users}{$nick};
    unshift @{ $self->{state}{whowas}{$nick} }, {
        logoff  => time(),
        account => $record->{account},
        nick    => $record->{nick},
        user    => $record->{auth}{ident},
        host    => $record->{auth}{hostname},
        real    => $record->{auth}{realhost},
        sock    => $record->{ipaddress},
        ircname => $record->{ircname},
        server  => $record->{server},
    };
    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_uid {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift;
    my $server  = $self->server_name();
    my $mysid   = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    my $rhost   = ( $self->_state_our_capab('RHOST')
                    && $self->_state_peer_capab( $peer_id, 'RHOST') );


    SWITCH: {
        if (!$count || $count < 9) {
            $self->_terminate_conn_error(
                $peer_id,
                'Not enough arguments to server command.',
            );
            last SWITCH;
        }
        if ( $self->state_nick_exists( $args->[0] ) ) {
            my $unick = uc_irc($args->[0]);
            my $exist = $self->{state}{users}{ $unick };
            my $userhost = ( split /!/, $self->state_user_full($args->[0]) )[1];
            my $incoming = join '@', @{ $args }[4..5];
            # Received TS  < Existing TS
            if ( $args->[2] < $exist->{ts} ) {
              # If userhosts different, collide existing user
              if ( $incoming ne $userhost ) {
                # Send KILL for existing user UID to all servers
                $exist->{nick_collision} = 1;
                $self->daemon_server_kill( $exist->{uid}, 'Nick Collision' );
              }
              # If userhosts same, collide new user
              else {
                # Send KILL for new user UID back to sending peer
                $self->send_output(
                  {
                    prefix  => $mysid,
                    command => 'KILL',
                    params  => [$args->[7+$rhost], 'Nick Collision'],
                  },
                  $peer_id,
                );
                last SWITCH;
              }
            }
            # Received TS == Existing TS
            if ( $args->[2] == $exist->{ts} ) {
              # Collide both
              $exist->{nick_collision} = 1;
              $self->daemon_server_kill( $exist->{uid}, 'Nick Collision', $peer_id);
              $self->send_output(
                 {
                    prefix  => $mysid,
                    command => 'KILL',
                    params  => [$args->[7+$rhost], 'Nick Collision'],
                 },
                 $peer_id,
              );
              last SWITCH;
            }
            # Received TS  > Existing TS
            if ( $args->[2] > $exist->{ts} ) {
              # If userhosts same, collide existing user
              if ( $incoming eq $userhost ) {
                # Send KILL for existing user UID to all servers
                $exist->{nick_collision} = 1;
                $self->daemon_server_kill( $exist->{uid}, 'Nick Collision' );
              }
              # If userhosts different, collide new user, drop message
              else {
                # Send KILL for new user UID back to sending peer
                $self->send_output(
                  {
                    prefix  => $mysid,
                    command => 'KILL',
                    params  => [$args->[7+$rhost], 'Nick Collision'],
                  },
                  $peer_id,
                );
                last SWITCH;
              }
            }
            #last SWITCH;
        }

        # check if we have RHOST set and they do, if so then there will be 11 args not 10

        my $record = {
            server      => $self->_state_sid_name( $prefix ),
            type        => 'r',
            route_id    => $peer_id,
            sid         => $prefix,
            nick        => $args->[0],
            hops        => $args->[1],
            ts          => $args->[2],
            umode       => $args->[3],
            auth        => {
               ident    => $args->[4],
               hostname => $args->[5],
            },
            ipaddress   => $args->[6+$rhost],
            uid         => $args->[7+$rhost],
            account     => $args->[8+$rhost],
            ircname     => ( $args->[9+$rhost] || '' ),
        };

        $record->{full} = sub {
            return sprintf('%s!%s@%s',
              $record->{nick},
              $record->{auth}{ident},
              $record->{auth}{hostname});
        };

        if ( $rhost ) {
          $record->{auth}{realhost} = $args->[6];
        }
        else {
          $record->{auth}{realhost} = $record->{auth}{hostname};
        }

        my $unick = uc_irc( $args->[0] );

        $self->{state}{users}{ $unick } = $record;
        $self->{state}{uids}{ $record->{uid} } = $record;
        $self->{state}{stats}{ops_online}++ if $record->{umode} =~ /o/;
        $self->{state}{stats}{invisible}++ if $record->{umode} =~ /i/;
        $self->{state}{sids}{$prefix}{users}{$unick} = $record;
        $self->{state}{sids}{$prefix}{uids}{ $record->{uid} } = $record;
        $self->_state_update_stats();

        if ( defined $self->{state}{watches}{$unick} ) {
            foreach my $wuid ( keys %{ $self->{state}{watches}{$unick}{uids} } ) {
                next if !defined $self->{state}{uids}{$wuid};
                my $wrec = $self->{state}{uids}{$wuid};
                $self->send_output(
                    {
                        prefix  => $server,
                        command => '600',
                        params  => [
                             $wrec->{nick},
                             $record->{nick},
                             $record->{auth}{ident},
                             $record->{auth}{hostname},
                             $record->{ts},
                            'logged online',
                        ],
                    },
                    $wrec->{route_id},
                );
            }
        }

        $self->send_output(
             {
                 prefix  => $prefix,
                 command => 'UID',
                 params  => $args,
             },
             grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );

        $self->_send_to_realops(
             sprintf(
                 'Client connecting at %s: %s (%s@%s) [%s] [%s] <%s>',
                 $record->{server}, $record->{nick}, $record->{auth}{ident},
                 $record->{auth}{realhost}, $record->{ipaddress},
                 $record->{ircname}, $record->{uid},
             ),
             'Notice', 'F',
        );

        $self->send_event('daemon_uid', $prefix, @$args);
        $self->send_event('daemon_nick', @{ $args }[0..5], $record->{server}, ( $args->[9+$rhost] || '' ) );

    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_nick {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift;
    my $mysid   = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    my $peer    = $self->{state}{conns}{$peer_id}{name};
    my $nicklen = $self->server_config('NICKLEN');

    SWITCH: {
        if (!$count || $count < 2) {
          last SWITCH;
        }
        if ( !$self->state_uid_exists( $prefix ) ) {
          last SWITCH;
        }
        my $newts = $args->[1];
        if ( $self->state_nick_exists($args->[0]) && $prefix ne $self->state_user_uid($args->[0]) ) {
            my $unick = uc_irc($args->[0]);
            my $exist = $self->{state}{users}{ $unick };
            my $userhost = ( split /!/, $self->state_user_full($args->[0]) )[1];
            my $incoming = ( split /!/, $self->state_user_full($prefix) )[1];
            # Received TS  < Existing TS
            if ( $newts < $exist->{ts} ) {
              # If userhosts different, collide existing user
              if ( $incoming ne $userhost ) {
                # Send KILL for existing user UID to all servers
                $exist->{nick_collision} = 1;
                $self->daemon_server_kill( $exist->{uid}, 'Nick Collision' );
              }
              # If userhosts same, collide new user
              else {
                # Send KILL for new user UID back to sending peer
                $self->send_output(
                  {
                    prefix  => $mysid,
                    command => 'KILL',
                    params  => [$prefix, 'Nick Collision'],
                  },
                  $peer_id,
                );
                last SWITCH;
              }
            }
            # Received TS == Existing TS
            if ( $args->[2] == $exist->{ts} ) {
              # Collide both
              $exist->{nick_collision} = 1;
              $self->daemon_server_kill( $exist->{uid}, 'Nick Collision', $peer_id);
              $self->send_output(
                 {
                    prefix  => $mysid,
                    command => 'KILL',
                    params  => [$prefix, 'Nick Collision'],
                 },
                 $peer_id,
              );
              last SWITCH;
            }
            # Received TS  > Existing TS
            if ( $newts > $exist->{ts} ) {
              # If userhosts same, collide existing user
              if ( $incoming eq $userhost ) {
                # Send KILL for existing user UID to all servers
                $exist->{nick_collision} = 1;
                $self->daemon_server_kill( $exist->{uid}, 'Nick Collision' );
              }
              # If userhosts different, collide new user, drop message
              else {
                # Send KILL for new user UID back to sending peer
                $self->send_output(
                  {
                    prefix  => $mysid,
                    command => 'KILL',
                    params  => [$prefix, 'Nick Collision'],
                  },
                  $peer_id,
                );
                last SWITCH;
              }
            }
            #last SWITCH;
        }

        my $new = $args->[0];
        my $unew = uc_irc($new);
        my $ts = $args->[1] || time;
        my $record = $self->{state}{uids}{$prefix};
        my $unick = uc_irc($record->{nick});
        my $sid    = $record->{sid};
        my $full   = $record->{full}->();

        if ($unick eq $unew) {
            $record->{nick} = $new;
            $record->{ts} = $ts;
        }
        else {
            my $nick = $record->{nick};
            $record->{nick} = $new;
            $record->{ts} = $ts;
            # Remove from peoples accept lists
            # WATCH OFF
            if ( defined $self->{state}{watches}{$unick} ) {
                foreach my $wuid ( keys %{ $self->{state}{watches}{$unick}{uids} } ) {
                    next if !defined $self->{state}{uids}{$wuid};
                    my $wrec = $self->{state}{uids}{$wuid};
                    my $laston = time();
                    $self->{state}{watches}{$unick}{laston} = $laston;
                    $self->send_output(
                        {
                            prefix  => $record->{server},
                            command => '605',
                            params  => [
                                $wrec->{nick},
                                $nick,
                                $record->{auth}{ident},
                                $record->{auth}{hostname},
                                $laston,
                                'is offline',
                            ],
                        },
                        $wrec->{route_id},
                    );
                }
            }
            if ( defined $self->{state}{watches}{$unew} ) {
                foreach my $wuid ( keys %{ $self->{state}{watches}{$unew}{uids} } ) {
                    next if !defined $self->{state}{uids}{$wuid};
                    my $wrec = $self->{state}{uids}{$wuid};
                    $self->send_output(
                        {
                            prefix  => $record->{server},
                            command => '604',
                            params  => [
                                $wrec->{nick},
                                $record->{nick},
                                $record->{auth}{ident},
                                $record->{auth}{hostname},
                                $record->{ts},
                                'is online',
                            ],
                        },
                        $wrec->{route_id},
                    );
                }
            }
            delete $self->{state}{users}{$_}{accepts}{$unick}
                for keys %{ $record->{accepts} };
            delete $record->{accepts};
            delete $self->{state}{users}{$unick};
            $self->{state}{users}{$unew} = $record;
            delete $self->{state}{sids}{$sid}{users}{$unick};
            $self->{state}{sids}{$sid}{users}{$unew} = $record;
            if ( $record->{umode} =~ /r/ ) {
                $record->{umode} =~ s/r//g;
            }
            unshift @{ $self->{state}{whowas}{$unick} }, {
                logoff  => time(),
                account => $record->{account},
                nick    => $nick,
                user    => $record->{auth}{ident},
                host    => $record->{auth}{hostname},
                real    => $record->{auth}{realhost},
                sock    => $record->{ipaddress},
                ircname => $record->{ircname},
                server  => $record->{server},
            };
        }
        my $common = { };
        for my $chan (keys %{ $record->{chans} }) {
            for my $user ( keys %{ $self->{state}{chans}{uc_irc $chan}{users} } ) {
                next if $user !~ m!^$mysid!;
                $common->{$user} = $self->_state_uid_route($user);
            }
        }
        {
            my ($nick,$userhost) = split /!/, $full;
            $self->_send_to_realops(
                sprintf(
                    'Nick change: From %s to %s [%s]',
                    $nick, $new, $userhost,
                ),
                'Notice',
                'n',
            );
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
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_part {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
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
        if (!$self->state_uid_chan_member($uid, $chan)) {
            last SWITCH;
        }
        $self->send_output(
             {
                 prefix  => $uid,
                 command => 'PART',
                 params  => [$chan, ($args->[0] || '')],
             },
             grep { $_ ne $peer_id } $self->_state_connected_peers(),
         );
        $self->_send_output_channel_local(
            $chan, {
                prefix  => $self->state_user_full($uid),
                command => 'PART',
                params  => [$chan, ($args->[0] || '')],
            },
        );
        my $uchan = uc_irc($chan);
        delete $self->{state}{chans}{$uchan}{users}{$uid};
        delete $self->{state}{uids}{$uid}{chans}{$uchan};
        if (!keys %{ $self->{state}{chans}{$uchan}{users} }) {
            delete $self->{state}{chans}{$uchan};
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_kick {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my $chan = (split /,/, $args->[0])[0];
        my $wuid = (split /,/, $args->[1])[0];
        if (!$self->state_chan_exists($chan)) {
            last SWITCH;
        }
        if ( !$self->state_uid_exists($wuid)) {
            last SWITCH;
        }
        if (!$self->state_uid_chan_member($wuid, $chan)) {
            last SWITCH;
        }
        my $who = $self->state_user_nick($wuid);
        my $comment = $args->[2] || $who;
        $self->send_output(
             {
                 prefix  => $uid,
                 command => 'KICK',
                 params  => [$chan, $wuid, $comment],
             },
             grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        $self->_send_output_channel_local(
            $chan, {
                prefix  => $self->state_user_full($uid),
                command => 'KICK',
                params  => [$chan, $who, $comment],
            },
        );
        my $uchan = uc_irc($chan);
        delete $self->{state}{chans}{$uchan}{users}{$wuid};
        delete $self->{state}{uids}{$wuid}{chans}{$uchan};
        if (!keys %{ $self->{state}{chans}{$uchan}{users} }) {
            delete $self->{state}{chans}{$uchan};
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_sjoin {
    my $self    = shift;
    my $peer_id = shift;
    $self->_daemon_do_joins( $peer_id, 'SJOIN', @_ );
}

sub _daemon_peer_join {
    my $self    = shift;
    my $peer_id = shift;
    $self->_daemon_do_joins( $peer_id, 'JOIN', @_ );
}

sub _daemon_do_joins {
    my $self    = shift;
    my $peer_id = shift || return;
    my $cmd     = shift;
    my $prefix  = shift;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;
    my $server  = $self->server_name();

    # We have to handle either SJOIN or JOIN
    # :<SID> SJOIN <TS> <CHANNAME> +<CHANMODES> :<UIDS>
    # :<UID>  JOIN <TS> <CHANNAME> +

    SWITCH: {
        if ($cmd eq 'SJOIN' && ( !$count || $count < 4) ) {
            last SWITCH;
        }
        if ($cmd eq 'JOIN' && ( !$count || $count < 3) ) {
            last SWITCH;
        }
        my $ts = $args->[0];
        my $chan = $args->[1];
        my $uids;
        if ( $cmd eq 'JOIN' ) {
            $uids = $prefix;
        }
        else {
           $uids = pop @{ $args };
        }
        if (!$self->state_chan_exists($chan)) {
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
            push @$args, $uids;
            my $uchan = uc_irc($chanrec->{name});
            for my $uid (split /\s+/, $uids) {
                my $umode = '';
                $umode .= 'o' if $uid =~ s/\@//g;
                $umode .= 'h' if $uid =~ s/\%//g;
                $umode .= 'v' if $uid =~ s/\+//g;
                $chanrec->{users}{$uid} = $umode;
                $self->{state}{uids}{$uid}{chans}{$uchan} = $umode;

                $self->send_event(
                    'daemon_join',
                    $self->state_user_full($uid),
                    $chan,
                );
                $self->send_event(
                    'daemon_mode',
                    $server,
                    $chan,
                    '+' . $umode,
                    $self->state_user_nick($uid),
                ) if $umode;
            }
            $self->{state}{chans}{$uchan} = $chanrec;
            $self->send_output(
                {
                    prefix  => $prefix,
                    command => $cmd,
                    params  => $args,
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            last SWITCH;
        }

        # :8H8 SJOIN 1526826863 #ooby +cmntlk 699 secret :@7UPAAAAAA

        my $chanrec = $self->{state}{chans}{uc_irc($chan)};
        my @local_users; my @local_extjoin; my @local_nextjoin;
        {
            my @tmp_users =
                grep { $self->_state_is_local_uid($_) }
                keys %{ $chanrec->{users} };

            @local_extjoin = map { $self->_state_uid_route($_) }
                grep { $self->{state}{uids}{$_}{caps}{'extended-join'} }
                @tmp_users;

            @local_nextjoin = map { $self->_state_uid_route($_) }
                grep { !$self->{state}{uids}{$_}{caps}{'extended-join'} }
                @tmp_users;

            @local_users = ( @local_extjoin, @local_nextjoin );

        }
        # If the TS received is lower than our TS of the channel a TS6 server must
        # remove status modes (+ov etc) and channel modes (+nt etc).  If the
        # originating server is TS6 capable (ie, it has a SID), the server must
        # also remove any ban modes (+b etc).  The new modes and statuses are then
        # accepted.

        if ( $ts < $chanrec->{ts} ) {
          my @deop;
          my @deop_list;
          my $common = { };

          # Remove all +ovh
          for my $user (keys %{ $chanrec->{users} }) {
             $common->{$user} = $self->_state_uid_route($user)
               if $self->_state_is_local_uid($user);
             next if !$chanrec->{users}{$user};
             my $current = $chanrec->{users}{$user};
             my $proper = $self->state_user_nick($user);
             $chanrec->{users}{$user} = '';
             $self->{state}{uids}{$user}{chans}{uc_irc($chanrec->{name})} = '';
             push @deop, "-$current";
             push @deop_list, $proper for split //, $current;
          }

          if (keys %$common && @deop) {
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

          # Remove all +beI modes
          if ( $cmd eq 'SJOIN' ) {
            my $tmap = { bans => 'b', excepts => 'e', invex => 'I' };
            my @types; my @mask_list;
            foreach my $type ( qw[bans excepts invex] ) {
              next if !$chanrec->{$type};
              foreach my $umask ( keys %{ $chanrec->{$type} } ) {
                my $rec = delete $chanrec->{$type}{$umask};
                push @types, '-' . $tmap->{$type};
                push @mask_list, $rec->[0];
              }
            }
            $self->send_event(
               "daemon_mode",
               $server,
               $chanrec->{name},
               unparse_mode_line(join '', @types),
               @mask_list,
            );
            if ( @local_users && @types ) {
              my @output_modes;
              my $length = length($server) + 4
                           + length($chan) + 4;
              my @buffer = ('', '');
              for my $type (@types) {
                my $arg = shift @mask_list;
                my $mode_line = unparse_mode_line($buffer[0].$type);
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
                   $buffer[0] = $type;
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
              $self->send_output($_, @local_users)
                  for @output_modes;
            }
          }

          # Remove TOPIC
          if ( $chanrec->{topic} ) {
             delete $chanrec->{topic};
             $self->send_output(
                 {
                    prefix  => $server,
                    command => 'TOPIC',
                    params  => [$chan, ''],
                 },
                 @local_users,
            );
          }
          # Set TS to incoming TS and send NOTICE
          $self->send_output(
              {
                 prefix  => $server,
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
          # Remove invites
          my $invites = delete $chanrec->{invites} || {};
          foreach my $invite ( keys %{ $invites } ) {
            next unless $self->state_uid_exists( $invite );
            next unless $self->_state_is_local_uid( $invite );
            delete $self->{state}{uids}{$invite}{invites}{uc_irc $chanrec->{name}};
          }
          # Remove channel modes and apply incoming modes
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
                prefix   => $server,
                command  => 'MODE',
                colonify => 0,
                params   => [
                   $chanrec->{name},
                   unparse_mode_line($reply),
                   @reply_args,
                ],
             },
             @local_users,
          ) if $reply;
          # Take incomers and announce +ovh
          # Actually do it later
        }

        # If the TS received is equal to our TS of the channel the server should keep
        # its current modes and accept the received modes and statuses.

        elsif ( $ts == $chanrec->{ts} ) {
          # Have to merge chanmodes
          my $origmode = $chanrec->{mode};
          my @args = @{ $args }[2..$#{ $args }];
          my $chanmode = shift @args;
          my $reply = '';
          my @reply_args;
          for my $mode (grep { $_ ne '+' } split //, $chanmode) {
             my $arg;
             $arg = shift @args if $mode =~ /[lk]/;
             if ($mode eq 'l' && ($chanrec->{mode} !~ /l/
                 || $arg > $chanrec->{climit})) {
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
                    || ($arg cmp $chanrec->{ckey}) > 0 )) {
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
          $self->send_output(
             {
                prefix   => $server,
                command  => 'MODE',
                colonify => 0,
                params   => [
                   $chanrec->{name},
                   unparse_mode_line($reply),
                   @reply_args,
                ],
             },
             @local_users,
          ) if $reply;
        }

        # If the TS received is higher than our TS of the channel the server should keep
        # its current modes and ignore the received modes and statuses.  Any statuses
        # given in the received message will be removed.

        else {
           $uids = join ' ', map { my $s = $_; $s =~ s/[@%+]//g; $s; }
                    split /\s+/, $uids;
        }
        # Send it on
        $self->send_output(
           {
             prefix  => $prefix,
             command => $cmd,
             params  => [ @$args, $uids ]
           },
           grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        # Joins and modes for new arrivals
        my $uchan = uc_irc($chanrec->{name});
        my $modes;
        my @aways;
        my @mode_parms;
        for my $uid (split /\s+/, $uids) {
            my $umode = '';
            my @op_list;
            $umode .= 'o' if $uid =~ s/\@//g;
            $umode .= 'h' if $uid =~ s/\%//g;
            $umode .= 'v' if $uid =~ s/\+//g;
            next if !defined $self->{state}{uids}{$uid};
            $chanrec->{users}{$uid} = $umode;
            $self->{state}{uids}{$uid}{chans}{$uchan} = $umode;
            push @op_list, $self->state_user_nick($uid) for split //, $umode;
            my $full = $self->state_user_full($uid);
            if ( @local_nextjoin ) {
                my $output = {
                    prefix  => $full,
                    command => 'JOIN',
                    params  => [$chanrec->{name}],
                };
                $self->send_output($output, @local_nextjoin);
            }
            if ( @local_extjoin ) {
                my $extout = {
                    prefix  => $full,
                    command => 'JOIN',
                    params  => [
                        $chanrec->{name},
                        $self->{state}{uids}{$uid}{account},
                        $self->{state}{uids}{$uid}{ircname},
                    ],
                };
                $self->send_output($extout, @local_extjoin);
            }
            $self->send_event(
                "daemon_join",
                $full,
                $chanrec->{name},
            );
            if ($umode) {
                $modes .= $umode;
                push @mode_parms, @op_list;
            }
            if ( $self->{state}{uids}{$uid}{away} ) {
               push @aways, { uid => $uid, msg => $self->{state}{uids}{$uid}{away} };
            }
        }
        if ($modes) {
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
        if ( @aways ) {
           $self->_state_do_away_notify($_->{uid},$chanrec->{name},$_->{msg})
             for @aways;
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_tmode {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $ts      = shift;
    my $chan    = shift;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = scalar @$args;

    SWITCH: {
        if (!$self->state_chan_exists($chan)) {
            last SWITCH;
        }
        my $record = $self->{state}{chans}{uc_irc($chan)};
        if ( $ts > $record->{ts} ) {
            last SWITCH;
        }
        $chan = $record->{name};
        my $mode_u_set = ( $record->{mode} =~ /u/ );
        my $full;
        $full = $self->state_user_full($uid)
            if $self->state_uid_exists($uid);
        my $reply;
        my @reply_args; my %subs;
        my $parsed_mode = parse_mode_line(@$args);

        while (my $mode = shift (@{ $parsed_mode->{modes} })) {
            my $arg;
            $arg = shift @{ $parsed_mode->{args} }
                if $mode =~ /^(\+[ohvklbIe]|-[ohvbIe])/;
                if (my ($flag,$char) = $mode =~ /^(\+|-)([ohv])/) {
                    if ($flag eq '+'
                        && $record->{users}{uc_irc($arg)} !~ /$char/) {
                        # Update user and chan record
                        $record->{users}{$arg} = join('', sort split //,
                            $record->{users}{$arg} . $char);
                        $self->{state}{uids}{$arg}{chans}{uc_irc($chan)}
                            = $record->{users}{$arg};
                        $reply .= "+$char";
                        $subs{$arg} = $self->state_user_nick($arg);
                        push @reply_args, $arg;
                    }
                    if ($flag eq '-' && $record->{users}{uc_irc($arg)}
                        =~ /$char/) {
                        # Update user and chan record
                        $record->{users}{$arg} =~ s/$char//g;
                        $self->{state}{uids}{$arg}{chans}{uc_irc($chan)}
                            = $record->{users}{$arg};
                        $reply .= "-$char";
                        $subs{$arg} = $self->state_user_nick($arg);
                        push @reply_args, $arg;
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
                        prefix   => $uid,
                        command  => 'TMODE',
                        colonify => 0,
                        params   => [
                            $record->{name},
                            $parsed_line,
                            @reply_args,
                        ],
                    },
                    grep { $_ ne $peer_id } $self->_state_connected_peers(),
                );
                my @reply_args_chan = map {
                  ( defined $subs{$_} ? $subs{$_} : $_ )
                } @reply_args;

                $self->send_event(
                    "daemon_mode",
                    ($full || $server),
                    $record->{name},
                    $parsed_line,
                    @reply_args_chan,
                );

                $self->_send_output_channel_local(
                    $record->{name},
                    {
                        prefix   => ($full || $server),
                        command  => 'MODE',
                        colonify => 0,
                        params   => [
                            $record->{name},
                            $parsed_line,
                            @reply_args_chan,
                        ],
                    },
                    '',
                    ( $mode_u_set ? 'oh' : '' ),
                );
                if ($mode_u_set) {
                    my $bparse = parse_mode_line( join ' ', $parsed_line, @reply_args_chan );
                    my $breply; my @breply_args;
                    while (my $bmode = shift (@{ $bparse->{modes} })) {
                        my $arg;
                        $arg = shift @{ $bparse->{args} }
                          if $bmode =~ /^(\+[ohvklbIe]|-[ohvbIe])/;
                        next if $bmode =~ m!^[+-][beI]$!;
                        $breply .= $bmode;
                        push @breply_args, $arg;
                    }
                    if ($breply) {
                       $parsed_line = unparse_mode_line($breply);
                       $self->_send_output_channel_local(
                          $record->{name},
                          {
                              prefix   => ($full || $server),
                              command  => 'MODE',
                              colonify => 0,
                              params   => [
                                  $record->{name},
                                  $parsed_line,
                                  @breply_args,
                              ],
                          },
                          '','-oh',
                       );
                    }
                }
            }
    } # SWITCH

    return @$ref if wantarray;
    return $ref;
}

# :<SID> BMASK <TS> <CHANNAME> <TYPE> :<MASKS>
sub _daemon_peer_bmask {
    my $self        = shift;
    my $peer_id     = shift || return;
    my $prefix      = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = scalar @$args;
    my %map     = qw(b bans e excepts I invex);

    SWITCH: {
        if ( !$count || $count < 4 ) {
            last SWITCH;
        }
        my ($ts,$chan,$trype,$masks) = @$args;
        if ( !$self->state_chan_exists($chan) ) {
            last SWITCH;
        }
        my $chanrec = $self->{state}{chans}{uc_irc($chan)};
        # Simple TS rules apply
        if ( $ts > $chanrec->{ts} ) {
          # Drop MODE
          last SWITCH;
        }
        $self->send_output(
          {
              prefix  => $prefix,
              command => 'BMASK',
              params  => $args,
          },
          grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        my $mode_u_set = ( $chanrec->{mode} =~ /u/ );
        my $sid = $self->server_sid();
        my $server = $self->server_name();
        my @local_users = map { $self->_state_uid_route( $_ ) }
                           grep { !$mode_u_set || $chanrec->{users}{$_} =~ /[oh]/ }
                           grep { $_ =~ m!^$sid! } keys %{ $chanrec->{users} };
        my @mask_list = split m!\s+!, $masks;
        my @marsk_list;
        foreach my $marsk ( @mask_list ) {
            my $mask = normalize_mask($marsk);
            my $umask = uc_irc($mask);
            next if $chanrec->{ $map{ $trype } }{$umask};
            $chanrec->{ $map{ $trype } }{$umask} =
              [ $mask, $server, time() ];
            push @marsk_list, $marsk;
        }
        # Only bother with the next bit if we have local users on the channel
        # OR masks to announce
        if ( !@local_users || !@marsk_list ) {
          last SWITCH;
        }
        my @types;
        push @types, "+$trype" for @marsk_list;
        my @output_modes;
        my $length = length($server) + 4
                     + length($chan) + 4;
        my @buffer = ('', '');
        for my $type (@types) {
            my $arg = shift @marsk_list;
            my $mode_line = unparse_mode_line($buffer[0].$type);
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
               $buffer[0] = $type;
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
        $self->send_output($_, @local_users)
               for @output_modes;
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_tburst {
    my $self        = shift;
    my $peer_id     = shift || return;
    my $prefix      = shift || return;
    my $ref         = [ ];
    my $args        = [ @_ ];
    my $count       = @$args;

    # :8H8 TBURST 1525787545 #dummynet 1526409011 llestr!bingos@staff.gumbynet.org.uk :this is dummynet, foo

    SWITCH: {
      if ( !$self->state_chan_exists( $args->[1] ) ) {
        last SWITCH;
      }
      my ($chants,$chan,$topicts,$who,$what) = @$args;
      my $accept;
      my $uchan = uc_irc $chan;
      my $chanrec = $self->{state}{chans}{$uchan};
      if ( $chants < $chanrec->{ts} ) {
        $accept = 1;
      }
      elsif ( $chants == $chanrec->{ts} ) {
        if ( !$chanrec->{topic} ) {
          $accept = 1;
        }
        elsif ( $topicts > $chanrec->{topic}[2] ) {
          $accept = 1;
        }
      }
      if ( !$accept ) {
        last SWITCH;
      }
      $self->send_output(
        {
            prefix  => $prefix,
            command => 'TBURST',
            params  => $args,
        },
        grep { $self->_state_peer_capab($_,'TBURST') }
          grep { $_ ne $peer_id } $self->_state_connected_peers(),
      );
      my $differing = ( !$chanrec->{topic} || $chanrec->{topic}[0] ne $what );
      $chanrec->{topic} = [ $what, $who, $topicts ];
      if ( !$differing ) {
        last SWITCH;
      }
      my $whom = ( $self->{config}{'hidden_servers'} ? $self->server_name() : $self->_state_sid_name( $prefix ) )
                 || $self->state_user_full( $prefix ) || $self->server_name();
      $self->_send_output_channel_local(
        $chan,
        {
          prefix  => $whom,
          command => 'TOPIC',
          params  => [ $chan, $what ],
        },
      );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_umode {
    my $self        = shift;
    my $peer_id     = shift || return;
    my $prefix      = shift || return;
    my $uid         = shift || return;
    my $umode       = shift;
    my $ref         = [ ];
    my $record      = $self->{state}{uids}{$uid};
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
            params  => [$uid, $umode],
        },
        grep { $_ ne $peer_id } $self->_state_connected_peers(),
    );
    $self->send_event(
        "daemon_umode",
        $record->{full}->(),
        $umode,
    );

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_message {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $type    = shift || return;
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        my $nick = $self->state_user_nick($uid);
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
        my $full        = $self->state_user_full($uid);
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
                    && $targs->{$target}[0] =~ /\x2E[^.]*[\x2A\x3F]+[^.]*$/) {
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
            if ($targ_type eq 'uid'
                    && !$self->state_uid_exists($target)) {
                push @$ref, ['401', $target];
                next LOOP;
            }
            if ($targ_type eq 'uid') {
                $target = $self->state_user_nick($target);
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
                        prefix  => $uid,
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
                        prefix  => $uid,
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
                            prefix  => $uid,
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
                if ($channel && $self->state_chan_mode_set($channel, 'T')
                        && $type eq 'NOTICE' && !$self->state_user_chan_mode($nick, $channel)) {
                    push @$ref, ['404', $channel];
                    next LOOP;
                }
                if ($channel && $self->state_chan_mode_set($channel, 'M')
                        && $self->state_user_umode($nick) !~ /r/) {
                    push @$ref, ['477', $channel];
                    next LOOP;
                }
                if ($channel && $self->_state_user_banned($nick, $channel)
                        && !$self->state_user_chan_mode($nick, $channel)) {
                    push @$ref, ['404', $channel];
                    next LOOP;
                }
                if ($channel && $self->state_chan_mode_set($channel, 'c')
                        && ( has_color($args->[1]) || has_formatting($args->[1]) ) ){
                    push @$ref, ['408', $channel];
                    next LOOP;
                }
                if ($channel && $self->state_chan_mode_set($channel, 'C')
                        && $args->[1] =~ m!^\001! && $args->[1] !~ m!^\001ACTION! ){
                    push @$ref, ['492', $channel];
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
                        $msg->{prefix} = $uid;
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
                    prefix  => $uid,
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
    my $uid     = shift || return;
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
        my $record = $self->{state}{chans}{uc_irc($args->[0])};
        my $chan_name = $record->{name};
        if ( $args->[1] ) {
          $record->{topic}
            = [$args->[1], $self->state_user_full($uid), time];
        }
        else {
          delete $record->{topic};
        }
        $self->send_output(
            {
                prefix  => $uid,
                command => 'TOPIC',
                params  => [$chan_name, $args->[1]],
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        $self->_send_output_channel_local(
            $chan_name,
            {
                prefix  => $self->state_user_full($uid),
                command => 'TOPIC',
                params  => [$chan_name, $args->[1]],
            },
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_invite {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    # :7UPAAAAAA INVITE 8H8AAAAAA #dummynet 1525787545
    SWITCH: {
        if (!$count || $count < 3) {
            last SWITCH;
        }
        my ($who, $chan) = @$args;
        $chan = $self->_state_chan_name($chan);
        my $uchan = uc_irc($chan);
        my $chanrec = $self->{state}{chans}{$uchan};
        if ($self->_state_is_local_uid($who)) {
            my $record = $self->{state}{uids}{$who};
            $record->{invites}{$uchan} = time;
            my $route_id = $self->_state_uid_route($who);
            my $output = {
                prefix   => $self->state_user_full($uid),
                command  => 'INVITE',
                params   => [$self->state_user_nick($who), $chan],
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
                $self->send_output( $output, $route_id );
            }
        }
        if ( $chanrec->{mode} && $chanrec->{mode} =~ m!i! ) {
           $chanrec->{invites}{$who} = time;
           # Send NOTICE to +oh local channel members
           # ":%s NOTICE %%%s :%s is inviting %s to %s."
           my $notice = {
               prefix  => $server,
               command => 'NOTICE',
               params  => [
                   $chan,
                   sprintf(
                      "%s is inviting %s to %s.",
                      $self->state_user_nick($uid),
                      $self->state_user_nick($who),
                      $chan,
                   ),
               ],
           };
           my $invite = {
                prefix   => $self->state_user_full($uid),
                command  => 'INVITE',
                params   => [$self->state_user_nick($who), $chan],
                colonify => 0,
           };
           $self->_send_output_channel_local($chan,$notice,'','oh','','invite-notify');
           $self->_send_output_channel_local($chan,$invite,'','oh','invite-notify','');
        }
        # Send it on to other peers
        $self->send_output(
            {
                prefix   => $uid,
                command  => 'INVITE',
                params   => $args,
                colonify => 0,
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_away {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $msg     = shift;
    my $server  = $self->server_name();
    my $ref     = [ ];

    SWITCH: {
        my $rec = $self->{state}{uids}{$uid};
        if (!$msg) {
            delete $rec->{away};
            $self->send_output(
                {
                    prefix   => $uid,
                    command  => 'AWAY',
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            $self->_state_do_away_notify($uid,'*',$msg);
            last SWITCH;
        }
        $rec->{away} = $msg;

        $self->send_output(
            {
                prefix   => $uid,
                command  => 'AWAY',
                params   => [$msg],
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        $self->_state_do_away_notify($uid,'*',$msg);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_links {
    my $self    = shift;
    my $peer_id = shift || return;
    my $uid     = shift || return;
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my ($target,$mask) = @$args;
        if ( $sid ne $target ) {
           $self->send_output(
               {
                  prefix  => $uid,
                  command => 'LINKS',
                  params  => $args,
               },
               $self->_state_sid_route($target),
           );
           last SWITCH;
        }
        my $urec = $self->{state}{uids}{$uid};
        $self->_send_to_realops(
            sprintf(
               'LINKS requested by %s (%s) [%s]',
               $urec->{nick}, (split /!/,$urec->{full}->())[1], $urec->{server},
            ), qw[Notice y],
        );
        push @$ref, $_ for
             @{ $self->_daemon_do_links($uid,$sid,$mask ) };
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_svsjoin {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$self->_state_sid_serv($prefix) && $prefix ne $sid) {
            last SWITCH;
        }
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my $client = shift @$args;
        my $uid = $self->state_user_uid($client);
        last SWITCH if !$uid;
        if ( $uid =~ m!^$sid! ) {
           my $rec = $self->{state}{uids}{$uid};
           $self->_send_output_to_client(
                $rec->{route_id},
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_),
           ) for $self->_daemon_cmd_join($rec->{nick}, @$args);
           last SWITCH;
        }
        my $route_id = $self->_state_uid_route($uid);
        if ( $route_id eq $peer_id ) {
          # The fuck
          last SWITCH;
        }
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'SVSJOIN',
                params  => [
                    $client,
                    @$args,
                ],
            },
            $route_id,
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_svspart {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$self->_state_sid_serv($prefix) && $prefix ne $sid) {
            last SWITCH;
        }
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my $client = shift @$args;
        my $uid = $self->state_user_uid($client);
        last SWITCH if !$uid;
        if ( $uid =~ m!^$sid! ) {
           my $rec = $self->{state}{uids}{$uid};
           $self->_send_output_to_client(
                $rec->{route_id},
                (ref $_ eq 'ARRAY' ? @{ $_ } : $_),
           ) for $self->_daemon_cmd_part($rec->{nick}, @$args);
           last SWITCH;
        }
        my $route_id = $self->_state_uid_route($uid);
        if ( $route_id eq $peer_id ) {
          # The fuck
          last SWITCH;
        }
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'SVSPART',
                params  => [
                    $client,
                    @$args,
                ],
            },
            $route_id,
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_svshost {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    # :9T9 SVSHOST 7UPAAAABO 1529239224 fake.host.name
    SWITCH: {
        if (!$self->_state_sid_serv($prefix) && $prefix ne $sid) {
            last SWITCH;
        }
        if (!$count || $count < 3) {
            last SWITCH;
        }
        my $client = shift @$args;
        my $uid = $self->state_user_uid($client);
        last SWITCH if !$uid;
        last SWITCH if $args->[0] !~ m!^\d+$!;
        last SWITCH if $args->[0] != $self->{state}{uids}{$uid}{ts};
        if ($args->[1] =~ $host_re) {
            $self->_state_do_change_hostmask($uid, $args->[1]);
        }
        unshift @$args, $uid;
        $self->send_output(
            {
                prefix   => $prefix,
                command  => 'SVSHOST',
                params   => $args,
                colonify => 0,
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_svsmode {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    # :9T9 SVSMODE 7UPAAAABO 1529239224 +<modes> extra_arg
    SWITCH: {
        if (!$self->_state_sid_serv($prefix) && $prefix ne $sid) {
            last SWITCH;
        }
        if (!$count || $count < 3) {
            last SWITCH;
        }
        my $client = shift @$args;
        my $uid = $self->state_user_uid($client);
        last SWITCH if !$uid;
        last SWITCH if $args->[0] !~ m!^\d+$!;
        last SWITCH if $args->[0] != $self->{state}{uids}{$uid}{ts};
        my $rec = $self->{state}{uids}{$uid};
        my $local = ( $uid =~ m!^$sid! );
        $local = $rec->{route_id} if $local;
        my $extra_arg = ( $count >= 4 ? $args->[2] : '' );
        my $umode = unparse_mode_line($args->[1]);
        my $parsed_mode = parse_mode_line($umode);
        my $previous = $rec->{umode};
        MODE: while (my $mode = shift @{ $parsed_mode->{modes} }) {
            next MODE if $mode eq '+o';
            my ($action, $char) = split //, $mode;
            next MODE if $char =~ m![SW]!;
            if ($action eq '+' && $char eq 'x') {
                if ($extra_arg && $extra_arg =~ $host_re) {
                    $self->_state_do_change_hostmask($uid, $extra_arg);
                }
                next MODE;
            }
            if ($action eq '+' && $char eq 'd') {
                if ($extra_arg) {
                    $rec->{account} = $extra_arg;
                    foreach my $chan ( keys %{ $rec->{chans} } ) {
                        $self->_send_output_channel_local(
                            $chan,
                            {
                                prefix   => $rec->{full}->(),
                                command  => 'ACCOUNT',
                                colonify => 0,
                                params   => [ $rec->{account} ],
                            },
                            $rec->{route_id},
                            '',
                            'account-notify',
                        );
                    }
                }
                next MODE;
            }
            if ($action eq '+' && $rec->{umode} !~ /$char/) {
                $rec->{umode} .= $char;
                if ($char eq 'i') {
                    $self->{state}{stats}{invisible}++;
                }
                if ($char eq 'w' && $local ) {
                    $self->{state}{wallops}{$local} = time;
                }
                if ($char eq 'l' && $local ) {
                    $self->{state}{locops}{$local} = time;
                }
            }
            if ($action eq '-' && $rec->{umode} =~ /$char/) {
                $rec->{umode} =~ s/$char//g;
                $self->{state}{stats}{invisible}-- if $char eq 'i';

                if ($char eq 'o') {
                    $self->{state}{stats}{ops_online}--;
                    delete $rec->{svstags}{313};
                    if ( $local ) {
                        delete $self->{state}{localops}{$local};
                        $self->antiflood( $local, 1);
                    }
                }
                if ($char eq 'w' && $local) {
                    delete $self->{state}{wallops}{$local};
                }
                if ($char eq 'l' && $local) {
                    delete $self->{state}{locops}{$local};
                }
            }
        }
        $rec->{umode} = join '', sort split //, $rec->{umode};
        unshift @$args, $uid;
        $self->send_output(
            {
                prefix   => $prefix,
                command  => 'SVSMODE',
                params   => $args,
                colonify => 0,
            },
            grep { $_ ne $peer_id } $self->_state_connected_peers(),
        );
        last SWITCH if !$local;
        my $set = gen_mode_change($previous, $rec->{umode});
        if ($set) {
            my $full = $rec->{full}->();
            $self->send_output(
                {
                    prefix  => $full,
                    command => 'MODE',
                    params  => [$rec->{nick}, $set],
                },
                $local
            );
            $self->send_event(
                "daemon_umode",
                $full,
                $set,
            );
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_svsnick {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$self->_state_sid_serv($prefix) && $prefix ne $sid) {
            last SWITCH;
        }
        if (!$count) {
            last SWITCH;
        }
        my $newnick = ( $count == 4 ? $args->[2] : $args->[1] );
        last SWITCH if !is_valid_nick_name($newnick); # maybe check nicklen too
        my $uid = $self->state_user_uid($args->[0]);
        last SWITCH if !$uid;
        my $rec = $self->{state}{uids}{$uid};
        my $ts = 0; my $newts = 0;
        if ( $count == 4 ) {
            $ts = $args->[1];
            last SWITCH if $ts && $ts != $rec->{ts};
        }
        else {
            $ts = $args->[2];
        }
        if ( $count == 3 ) {
            $newts = $ts;
        }
        else {
            $newts = $args->[3];
        }
        if ($uid !~ m!^$sid!) { # Not ours
            if ($rec->{route_id} eq $peer_id) {
                # eh!?
                last SWITCH;
            }
            $self->send_output(
                {
                    prefix  => $prefix,
                    command => 'SVSNICK',
                    params  => [
                        $uid,
                        $newnick,
                        $newts,
                    ],
                },
                $rec->{route_id},
            );
            last SWITCH;
        }

        my $full  = $rec->{full}->();
        my $nick  = $rec->{nick};
        my $unick = uc_irc $nick;
        my $unew  = uc_irc $newnick;
        my $server = uc $self->server_name();

        if ( $self->state_nick_exists($newnick) ) {
            if ( defined $self->{state}{users}{$unew} ) {
               my $exist = $self->{state}{users}{$unew};
               if ( $rec eq $exist ) {
                  $rec->{nick} = $newnick;
                  $rec->{ts}   = $newts;
                  last SWITCH;
               }
               # SVSNICK Collide methinks
                $self->_terminate_conn_error(
                    $rec->{route_id},
                    'SVSNICK Collide',
                );
                last SWITCH;
            }
            if ( defined $self->{state}{pending}{$unew} ) {
                $self->_terminate_conn_error(
                    $self->{state}{pending}{$unew},
                    'SVSNICK Override',
                );
            }
        }

        my $common;
        for my $chan (keys %{ $rec->{chans} }) {
            for my $user ( keys %{ $self->{state}{chans}{$chan}{users} } ) {
                next if $user !~ m!^$sid!;
                $common->{$user} = $self->_state_uid_route($user);
            }
        }

        if ($unick eq $unew) {
            $rec->{nick} = $newnick;
            $rec->{ts}   = $newts;
        }
        else {
            $rec->{nick} = $newnick;
            $rec->{ts}   = $newts;
            # WATCH ON/OFF
            if ( defined $self->{state}{watches}{$unick} ) {
                foreach my $wuid ( keys %{ $self->{state}{watches}{$unick}{uids} } ) {
                    next if !defined $self->{state}{uids}{$wuid};
                    my $wrec = $self->{state}{uids}{$wuid};
                    my $laston = time();
                    $self->{state}{watches}{$unick}{laston} = $laston;
                    $self->send_output(
                        {
                            prefix  => $rec->{server},
                            command => '605',
                            params  => [
                                $wrec->{nick},
                                $nick,
                                $rec->{auth}{ident},
                                $rec->{auth}{hostname},
                                $laston,
                                'is offline',
                            ],
                        },
                        $wrec->{route_id},
                    );
                }
            }
            if ( defined $self->{state}{watches}{$unew} ) {
                foreach my $wuid ( keys %{ $self->{state}{watches}{$unew}{uids} } ) {
                    next if !defined $self->{state}{uids}{$wuid};
                    my $wrec = $self->{state}{uids}{$wuid};
                    $self->send_output(
                        {
                            prefix  => $rec->{server},
                            command => '604',
                            params  => [
                                $wrec->{nick},
                                $rec->{nick},
                                $rec->{auth}{ident},
                                $rec->{auth}{hostname},
                                $rec->{ts},
                                'is online',
                            ],
                        },
                        $wrec->{route_id},
                    );
                }
            }
            # Remove from peoples accept lists
            for (keys %{ $rec->{accepts} }) {
                delete $self->{state}{users}{$_}{accepts}{$unick};
            }
            delete $rec->{accepts};
            delete $self->{state}{users}{$unick};
            $self->{state}{users}{$unew} = $rec;
            delete $self->{state}{peers}{$server}{users}{$unick};
            $self->{state}{peers}{$server}{users}{$unew} = $rec;
            if ( $rec->{umode} =~ /r/ ) {
                $rec->{umode} =~ s/r//g;
                $self->send_output(
                    {
                        prefix  => $full,
                        command => 'MODE',
                        params  => [
                            $rec->{nick},
                            '-r',
                        ],
                    },
                    $rec->{route_id},
                );
            }
            unshift @{ $self->{state}{whowas}{$unick} }, {
                logoff  => time(),
                account => $rec->{account},
                nick    => $nick,
                user    => $rec->{auth}{ident},
                host    => $rec->{auth}{hostname},
                real    => $rec->{auth}{realhost},
                sock    => $rec->{socket}[0],
                ircname => $rec->{ircname},
                server  => $rec->{server},
            };
        }

        $self->_send_to_realops(
            sprintf(
                'Nick change: From %s to %s [%s]',
                $nick, $newnick, (split /!/,$full)[1],
            ),
            'Notice',
            'n',
        );

        $self->send_output(
            {
                prefix  => $rec->{uid},
                command => 'NICK',
                params  => [$newnick, $rec->{ts}],
            },
            $self->_state_connected_peers(),
        );

        $self->send_event("daemon_nick", $full, $newnick);

        $self->send_output(
            {
                prefix  => $full,
                command => 'NICK',
                params  => [$newnick],
            },
            $rec->{route_id}, values %$common,
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_svskill {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    SWITCH: {
        if (!$self->_state_sid_serv($prefix) && $prefix ne $sid) {
            last SWITCH;
        }
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my $client = shift @$args;
        my $uid = $self->state_user_uid($client);
        last SWITCH if !$uid;
        last SWITCH if $args->[0] !~ m!^\d+$!;
        last SWITCH if $args->[0] != $self->{state}{uids}{$uid}{ts};
        if ( $uid =~ m!^$sid! ) {
           my $rec = $self->{state}{uids}{$uid};
           my $reason = 'SVSKilled: ';
           if ( $count == 3 ) {
              $reason .= pop @$args;
           }
           else {
              $reason .= '<No reason supplied>';
           }
           $self->_terminate_conn_error(
                $rec->{route_id},
                $reason,
           );
           last SWITCH;
        }
        my $route_id = $self->_state_uid_route($uid);
        if ( $route_id eq $peer_id ) {
          # The fuck
          last SWITCH;
        }
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'SVSKILL',
                params  => [
                    $client,
                    @$args,
                ],
            },
            $route_id,
        );
    }

    return @$ref if wantarray;
    return $ref;
}

sub _daemon_peer_svstag {
    my $self    = shift;
    my $peer_id = shift || return;
    my $prefix  = shift || return;
    my $sid     = $self->server_sid();
    my $ref     = [ ];
    my $args    = [ @_ ];
    my $count   = @$args;

    #      - parv[0] = nickname
    #      - parv[1] = TS
    #      - parv[2] = [-][raw]
    #      - parv[3] = required user mode(s) to see the tag
    #      - parv[4] = tag line

    SWITCH: {
        if (!$self->_state_sid_serv($prefix) && $prefix ne $sid) {
            last SWITCH;
        }
        if (!$count || $count < 2) {
            last SWITCH;
        }
        my $client = shift @$args;
        my $uid = $self->state_user_uid($client);
        last SWITCH if !$uid;
        last SWITCH if $args->[0] !~ m!^\d+$!;
        last SWITCH if $args->[0] != $self->{state}{uids}{$uid}{ts};
        my $rec = $self->{state}{uids}{$uid};
        if ( $args->[1] eq '-' ) {
            delete $rec->{svstags}{$_} for keys %{ $rec->{svstags} };
            $self->send_output(
                {
                    prefix  => $prefix,
                    command => 'SVSTAG',
                    params  => [
                        $uid,
                        $rec->{ts},
                        $args->[1],
                    ],
                },
                grep { $_ ne $peer_id } $self->_state_connected_peers(),
            );
            last SWITCH;
        }
        last SWITCH if $count < 5 || !$args->[3];
        $rec->{svstags}{$args->[1]} = {
            numeric => $args->[1],
            umodes  => $args->[2],
            tagline => $args->[3],
        };
        $self->send_output(
            {
                prefix  => $prefix,
                command => 'SVSTAG',
                params  => [
                    $uid,
                    $rec->{ts},
                    $args->[1],
                    $args->[2],
                    $args->[3],
                ],
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
        ts => 6,
    };

    if ( my $sid = $self->{config}{SID} ) {
      my $rec = $self->{state}{peers}{uc $self->server_name()};
      $rec->{sid} = $sid;
      $rec->{ts}  = 6;
      $self->{state}{sids}{uc $sid} = $rec;
      $self->{state}{uids} = { };
      $self->{genuid} = $sid . 'AAAAAA';
    }

    $self->{state}{stats} = {
        maxconns   => 0,
        maxlocal   => 0,
        maxglobal  => 0,
        ops_online => 0,
        invisible  => 0,
        cmds       => { },
    };

    $self->{state}{caps} = {
      'account-notify'    => 1,
      'away-notify'       => 1,
      'chghost'           => 1,
      'extended-join'     => 1,
      'invite-notify'     => 1,
      'multi-prefix'      => 1,
      'userhost-in-names' => 1,
    };

    return 1;
}

sub _state_rand_sid {
  my $self = shift;
  my @components = ( 0 .. 9, 'A' .. 'Z' );
  my $total = scalar @components;
  my $prefx = 10;
  $self->{config}{SID} = join '', $components[ rand $prefx ], $components[ rand $total ], $components[ rand $total ];
}

sub _state_gen_uid {
    my $self = shift;
    my $uid = $self->{genuid};
    $self->{genuid} = _add_one_uid( $uid );
    while ( defined $self->{state}{uids}{$uid} ) {
       $uid = $self->{genuid};
       $self->{genuid} = _add_one_uid( $uid );
    }
    return $uid;
}

sub _add_one_uid {
  my $UID = shift;
  my @cols = unpack 'a' x length $UID, $UID;
  my ($add,$add1);
  $add1 = $add = sub {
    my $idx = shift;
    if ( $idx != 3 ) {
      if ( $cols[$idx] eq 'Z' ) {
        $cols[$idx] = '0';
      }
      elsif ( $cols[$idx] eq '9' ) {
        $cols[$idx] = 'A';
        $add->( $idx - 1 );
      }
      else {
        $cols[$idx]++;
      }
    }
    else {
      if ( $cols[$idx] eq 'Z' ) {
        @cols[3..8] = qw[A A A A A A];
      }
      else {
        $cols[$idx]++;
      }
    }
  };
  $add->(8);
  return pack 'a' x scalar @cols, @cols;
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

sub _state_add_drkx_line {
    my $self = shift;
    my $type = shift || return;
    my @args = @_;
    return if !@args;
    return if $type !~ m!^((RK|[DKX])LINE|RESV)$!i;
    $type = lc($type) . 's';
    my $ref = { };
    foreach my $field ( qw[setby setat target duration] ) {
      $ref->{$field} = shift @args;
      return if !defined $ref->{$field};
    }
    $ref->{reason} = pop @args;
    if ( $type =~ m!^([xd]lines|resvs)$! ) {
      $ref->{mask} = shift @args;
      return if !$ref->{mask};
    }
    else {
      $ref->{user} = shift @args;
      $ref->{host} = shift @args;
      return if !$ref->{user} || !$ref->{host};
    }
    if ( $ref->{duration} ) {
      $ref->{alarm} =
        $poe_kernel->delay_set(
          '_state_drkx_line_alarm',
          $ref->{duration},
          $type,
          $ref,
        );
    }
    if ( $type eq 'resvs' ) {
      $self->{state}{$type}{ uc_irc $ref->{mask} } = $ref;
    }
    else {
      push @{ $self->{state}{$type} }, $ref;
    }
    return 1;
}

sub _state_del_drkx_line {
    my $self = shift;
    my $type = shift || return;
    my @args = @_;
    return if !@args;
    return if $type !~ m!^((RK|[DKX])LINE|RESV)$!i;
    $type = lc($type) . 's';
    my ($mask,$user,$host);
    if ( $type =~ m!^([xd]lines|resvs)$! ) {
      $mask = shift @args;
      return if !$mask;
    }
    else {
      $user = shift @args;
      $host = shift @args;
      return if !$user || !$host;
    }
    my $result; my $i = 0;
    if ( $type eq 'resvs' ) {
       $result = delete $self->{state}{resvs}{ uc_irc $mask };
    }
    else {
       LINES: for (@{ $self->{state}{$type} }) {
         if ($mask && $_->{mask} eq $mask) {
             $result = splice @{ $self->{state}{$type} }, $i, 1;
             last LINES;
         }
         if ($user && ($_->{user} eq $user && $_->{host} eq $host)) {
             $result = splice @{ $self->{state}{$type} }, $i, 1;
             last LINES;
         }
         ++$i;
       }
    }
    return if !$result;
    if ( my $alarm = delete $result->{alarm} ) {
      $poe_kernel->alarm_remove( $alarm );
    }
    return $result;
}

{

  my %drkxlines = (
    'rklines' => 'RK-Line',
    'klines'  => 'K-Line',
    'dlines'  => 'D-Line',
    'xlines'  => 'X-Line',
    'resvs'   => 'RESV',
  );

  sub _state_drkx_line_alarm {
      my ($kernel,$self,$type,$ref) = @_[KERNEL,OBJECT,ARG0,ARG1];
      my $fancy = $drkxlines{$type};
      delete $ref->{alarm};
      my $res; my $i = 0;
      if ( $type eq 'resvs' ) {
          $res = delete $self->{state}{resvs}{uc_irc $ref->{mask}};
      }
      else {
         LINES: foreach my $drkxline ( @{ $self->{state}{$type} } ) {
            if ( $drkxline eq $ref ) {
                $res = splice @{ $self->{state}{$type} }, $i, 1;
                last LINES;
            }
            ++$i;
         }
      }
      return if !$res;
      my $mask = $res->{mask} || join '@', $res->{user}, $res->{host};
      my $locops = sprintf 'Temporary %s for [%s] expired', $fancy, $mask;
      $self->del_denial( $res->{mask} ) if $type eq 'dlines';
      $self->send_event( "daemon_expired", lc($fancy), $mask );
      $self->_send_to_realops( $locops, 'Notice', 'X' );
      return;
  }

}

sub _state_is_resv {
    my $self    = shift;
    my $thing   = shift || return;
    my $conn_id = shift;
    if ($conn_id && !$self->_connection_exists($conn_id)) {
        $conn_id = '';
    }
    if ($conn_id && $self->{state}{conns}{$conn_id}{resv_exempt}) {
        return 0;
    }
    foreach my $mask ( keys %{ $self->{state}{resvs} } ) {
      if ( matches_mask( $mask, $thing ) ) {
        return $self->{state}{resvs}{$mask}{reason};
      }
    }
    return 0;
}

sub _state_have_resv {
    my $self = shift;
    my $mask = shift || return;
    return 1 if $self->{state}{resvs}{uc_irc $mask};
    return 0;
}

sub _state_do_away_notify {
    my $self = shift;
    my $uid  = shift || return;
    my $chan = shift || return;
    my $msg  = shift;
    return if !$self->state_uid_exists($uid);
    my $sid  = $self->server_sid();
    my $rec = $self->{state}{uids}{$uid};
    my $common = { };
    my @chans;
    if ( $chan eq '*' ) {
      @chans = keys %{ $rec->{chans} };
    }
    else {
      push @chans, uc_irc $chan;
    }
    for my $uchan (@chans) {
        for my $user ( keys %{ $self->{state}{chans}{$uchan}{users} } ) {
            next if $user !~ m!^$sid!;
            next if !$self->{state}{uids}{$user}{caps}{'away-notify'};
            $common->{$user} = $self->_state_uid_route($user);
        }
    }
    my $ref = {
      prefix  => $rec->{full}->(),
      command => 'AWAY',
    };
    $ref->{params} = [ $msg ] if $msg;
    $self->send_output( $ref, $common->{$_} ) for keys %$common;
    return 1;
}

sub _state_do_local_users_match_xline {
    my $self    = shift;
    my $mask    = shift || return;
    my $reason  = shift || '<No reason supplied>';
    my $sid     = $self->server_sid();
    my $server  = $self->server_name();

    foreach my $luser ( keys %{ $self->{state}{sids}{$sid}{uids} } ) {
       my $urec = $self->{state}{uids}{$luser};
       next if $urec->{route_id} eq 'spoofed';
       next if $urec->{umode} =~ m!o!;
       if ( $urec->{ircname} && matches_mask( $mask, $urec->{ircname} ) ) {
          $self->send_output(
             {
                prefix  => $server,
                command => '465',
                params  => [
                   $urec->{nick},
                   "You are banned from this server- $reason",
                ],
             },
             $urec->{route_id},
          );
          $self->_terminate_conn_error( $urec->{route_id}, $reason );
       }
    }
    return 1;
}

sub _state_do_local_users_match_dline {
    my $self    = shift;
    my $netmask = shift || return;
    my $reason  = shift || '<No reason supplied>';
    my $sid     = $self->server_sid();
    my $server  = $self->server_name();

    foreach my $luser ( keys %{ $self->{state}{sids}{$sid}{uids} } ) {
       my $urec = $self->{state}{uids}{$luser};
       next if $urec->{route_id} eq 'spoofed';
       next if $urec->{umode} =~ m!o!;
       if ( Net::CIDR::cidrlookup($urec->{socket}[0],$netmask) ) {
          $self->send_output(
             {
                prefix  => $server,
                command => '465',
                params  => [
                   $urec->{nick},
                   "You are banned from this server- $reason",
                ],
             },
             $urec->{route_id},
          );
          $self->_terminate_conn_error( $urec->{route_id}, $reason );
       }
    }
    return 1;
}

sub _state_do_local_users_match_rkline {
    my $self    = shift;
    my $luser   = shift || return;
    my $host    = shift || return;
    my $reason  = shift || '<No reason supplied>';
    my $sid     = $self->server_sid();
    my $server  = $self->server_name();
    my $local   = $self->{state}{sids}{$sid}{uids};

    for my $urec (values %$local) {
        next if $urec->{route_id} eq 'spoofed';
        next if $urec->{umode} && $urec->{umode} =~ /o/;
        if (($urec->{socket}[0] =~ /$host/
                || $urec->{auth}{hostname} =~ /$host/)
                && $urec->{auth}{ident} =~ /$luser/) {
          $self->send_output(
             {
                prefix  => $server,
                command => '465',
                params  => [
                   $urec->{nick},
                   "You are banned from this server- $reason",
                ],
             },
             $urec->{route_id},
          );
          $self->_terminate_conn_error( $urec->{route_id}, $reason );
        }
    }
    return 1;
}

sub _state_do_local_users_match_kline {
    my $self   = shift;
    my $luser  = shift || return;
    my $host   = shift || return;
    my $reason = shift || '<No reason supplied>';
    my $local  = $self->{state}{peers}{uc $self->server_name()}{users};
    my $server = $self->server_name();

    if (my $netmask = Net::CIDR::cidrvalidate($host)) {
        for my $user (values %$local) {
            next if $user->{route_id} eq 'spoofed';
            next if $user->{umode} && $user->{umode} =~ /o/;
            if (Net::CIDR::cidrlookup($user->{socket}[0],$netmask)
                    && matches_mask($luser, $user->{auth}{ident})) {
                $self->send_output(
                    {
                        prefix  => $server,
                        command => '465',
                        params  => [
                          $user->{nick},
                          "You are banned from this server- $reason",
                        ],
                    },
                    $user->{route_id},
                );
                $self->_terminate_conn_error( $user->{route_id}, $reason );
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
                $self->send_output(
                    {
                        prefix  => $server,
                        command => '465',
                        params  => [
                          $user->{nick},
                          "You are banned from this server- $reason",
                        ],
                    },
                    $user->{route_id},
                );
                $self->_terminate_conn_error( $user->{route_id}, $reason );
            }
        }
    }

    return 1;
}

sub _state_user_matches_rkline {
    my $self    = shift;
    my $conn_id = shift || return;
    my $record  = $self->{state}{conns}{$conn_id};
    my $host    = $record->{auth}{hostname} || $record->{socket}[0];
    my $user    = $record->{auth}{ident} || "~" . $record->{user};
    my $ip      = $record->{socket}[0];

    return 0 if $record->{kline_exempt};

    for my $kline (@{ $self->{state}{rklines} }) {
        if (($host =~ /$kline->{host}/ || $ip =~ /$kline->{host}/)
                && $user =~ /$kline->{user}/) {
            return $kline->{reason};
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

    return 0 if $record->{kline_exempt};

    for my $kline (@{ $self->{state}{klines} }) {
        if (my $netmask = Net::CIDR::cidrvalidate($kline->{host})) {
            if (Net::CIDR::cidrlookup($ip,$netmask)
                && matches_mask($kline->{user}, $user)) {
                return $kline->{reason};
            }
        }
        elsif ((matches_mask($kline->{host}, $host)
               || matches_mask($kline->{host}, $ip))
               && matches_mask($kline->{user}, $user)) {
            return $kline->{reason};
        }
    }

    return 0;
}

sub _state_user_matches_xline {
    my $self    = shift;
    my $conn_id = shift || return;
    my $record  = $self->{state}{conns}{$conn_id};
    my $ircname = $record->{ircname} || return;

    for my $xline (@{ $self->{state}{xlines} }) {
      if ( matches_mask( $xline->{mask}, $ircname ) ) {
        return $xline->{reason};
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
                    || !chkpasswd($record->{pass}, $auth->{password}) )) {
                return 0;
            }
            if ($auth->{spoof}) {
                $self->_send_to_realops(
                    sprintf(
                        '%s spoofing: %s as %s',
                        $record->{nick}, $record->{auth}{hostname},
                        $auth->{spoof},
                    ),
                    'Notice',
                    's',
                );
                $record->{auth}{hostname} = $auth->{spoof};
            }
            foreach my $feat ( qw(exceed_limit kline_exempt resv_exempt can_flood need_ident) ) {
                $record->{$feat} = 1 if $auth->{$feat};
            }
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

    return 0 if !$name || !$pass;
    my $peers = $self->{config}{peers};
    return 0 if !$peers->{uc $name};
    my $peer = $peers->{uc $name};
    return -1 if !chkpasswd($pass,$peer->{pass});

    my $conn = $self->{state}{conns}{$conn_id};

    if ($peer->{certfp} && $conn->{secured}) {
        my $certfp = $self->connection_certfp($conn_id);
        return -2 if !$certfp || $certfp ne $peer->{certfp};
    }

    if (!$peer->{ipmask} && $conn->{socket}[0] =~ /^(127\.|::1)/) {
        return 1;
    }
    return -3 if !$peer->{ipmask};
    my $client_ip = $conn->{socket}[0];

    if (ref $peer->{ipmask} eq 'ARRAY') {
        for my $block ( @{ $peer->{ipmask} }) {
            if ( eval { $block->isa('Net::Netmask') } ) {
              return -3 if $block->match($client_ip);
              next;
            }
            return 1 if Net::CIDR::cidrlookup( $client_ip, $block );
        }
    }

    return 1 if matches_mask(
        '*!*@'.$peer->{ipmask},
        "*!*\@$client_ip",
    );

    return -3;
}

{

  my %flag_notices = (
    kline_exempt  => '*** You are exempt from K/RK lines',
    resv_exempt   => '*** You are exempt from resvs',
    exceed_limit  => '*** You are exempt from user limits',
    can_flood     => '*** You are exempt from flood protection',
  );

  sub _state_auth_flags_notices {
      my $self    = shift;
      my $conn_id = shift || return;
      return if !$self->_connection_exists($conn_id);
      my $server = $self->server_name();
      my $crec = $self->{state}{conns}{$conn_id};
      my $nick = $crec->{nick};

      foreach my $feat ( qw(kline_exempt resv_exempt exceed_limit can_flood) ) {
          next if !$crec->{$feat};
          $self->antiflood($conn_id, 0) if $feat eq 'can_flood';
          $self->_send_output_to_client(
              $conn_id,
              {
                  prefix  => $server,
                  command => 'NOTICE',
                  params  => [ $nick, $flag_notices{$feat} ],
              },
          );
      }
      return 1;
  }

}

sub _state_send_credentials {
    my $self    = shift;
    my $conn_id = shift || return;
    my $name    = shift || return;
    return if !$self->_connection_exists($conn_id);
    return if !$self->{config}{peers}{uc $name};
    return if $self->_connection_terminated($conn_id);

    my $peer = $self->{config}{peers}{uc $name};
    my $rec = $self->{state}{peers}{uc $self->server_name()};
    my $sid = $rec->{sid};

    $self->send_output(
        {
            command => 'PASS',
            params  => [$peer->{rpass}, 'TS', ( $sid ? ( 6 => $sid ) : () )],
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

    my $desc = '';
    $desc = '(H) ' if $self->{config}{hidden};
    $desc .= $rec->{desc};

    $self->send_output(
        {
            command => 'SERVER',
            params  => [
                $rec->{name},
                $rec->{hops} + 1,
                $desc,
            ],
        },
        $conn_id,
    );

    $self->send_output(
        {
            command => 'SVINFO',
            params  => [6, 6, 0, time],
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
    return if $self->_connection_terminated($conn_id);
    my $server  = $self->server_name();
    my $sid     = $self->server_sid();
    my $conn    = $self->{state}{conns}{$conn_id};
    my $burst   = grep { /^EOB$/i } @{ $conn->{capab} };
    my $invex   = grep { /^IE$/i } @{ $conn->{capab} };
    my $excepts = grep { /^EX$/i } @{ $conn->{capab} };
    my $tburst  = grep { /^TBURST$/i } @{ $conn->{capab} };
    my $rhost   = grep { /^RHOST$/i } @{ $conn->{capab} };
    $rhost      = ( $self->_state_our_capab('RHOST') && $rhost );
    my %map     = qw(bans b excepts e invex I);
    my @lists   = qw(bans);
    push @lists, 'excepts' if $excepts;
    push @lists, 'invex' if $invex;

    # Send SERVER burst
    my %eobs;
    for ($self->_state_server_burst($sid, $conn->{sid})) {
        $eobs{ $_->{prefix} }++;
        $self->send_output($_, $conn_id );
    }

    # Send NICK burst
    for my $uid (keys %{ $self->{state}{uids} }) {
        my $record = $self->{state}{uids}{$uid};
        next if $record->{route_id} eq $conn_id;

        my $umode_fixed = $record->{umode};
        $umode_fixed =~ s/[^aiow]//g;
        my $prefix = $record->{sid};
        my $arrayref = [
            $record->{nick},
            $record->{hops} + 1,
            $record->{ts},
            '+' . $umode_fixed,
            $record->{auth}{ident},
            $record->{auth}{hostname},
        ];
        push @$arrayref, $record->{auth}{realhost} if $rhost;
        push @$arrayref, ( $record->{ipaddress} || 0 ),
             $record->{uid}, $record->{account}, $record->{ircname};
        my @uid_burst = (
            {
                prefix  => $prefix,
                command => 'UID',
                params  => $arrayref,
            },
        );
        if ( $record->{away} ) {
            push @uid_burst, {
                prefix  => $record->{uid},
                command => 'AWAY',
                params  => [ $record->{away} ],
            };
        }
        foreach my $svstag ( keys %{ $record->{svstags} } ) {
            push @uid_burst, {
                prefix  => $prefix,
                command => 'SVSTAG',
                params  => [
                    $record->{uid},
                    $record->{ts},
                    $svstag,
                    $record->{svstags}{$svstag}{umodes},
                    $record->{svstags}{$svstag}{tagline},
                ],
            };
        }
        $self->send_output( $_, $conn_id ) for @uid_burst;
    }

    # Send SJOIN+MODE burst
    for my $chan (keys %{ $self->{state}{chans} }) {
        next if $chan =~ /^\&/;
        my $chanrec = $self->{state}{chans}{$chan};
        my @uids = map { $_->[1] }
            sort { $a->[0] cmp $b->[0] }
            map { my $w = $_; $w =~ tr/@%+/ABC/; [$w, $_] }
            $self->state_chan_list_multi_prefixed($chan,'UIDS');

        my $chanref = [
            $chanrec->{ts},
            $chanrec->{name},
            '+' . $chanrec->{mode},
            ($chanrec->{ckey} || ()),
            ($chanrec->{climit} || ()),
        ];

        my $length = length( join ' ', @$chanref ) + 11;
        my $buf = '';
        UID: foreach my $uid ( @uids ) {
            if (length(join ' ', $buf, '1', $uid)+$length+1 > 510) {
                $self->send_output(
                  {
                      prefix  => $sid,
                      command => 'SJOIN',
                      params  => [ @$chanref, $buf ],
                  },
                  $conn_id,
                );
                $buf = $uid;
                next UID;
            }
            $buf = join ' ', $buf, $uid;
            $buf =~ s!^\s+!!;
        }
        if ($buf) {
            $self->send_output(
               {
                   prefix  => $sid,
                   command => 'SJOIN',
                   params  => [ @$chanref, $buf ],
               },
               $conn_id,
            );
        }

        my @output_modes;
        OUTER: for my $type (@lists) {
            my $length = length($sid) + 5 + length($chan) + 4 + length($chanrec->{ts}) + 2;
            my @buffer = ( '', '' );
            INNER: for my $thing (keys %{ $chanrec->{$type} }) {
                $thing = $chanrec->{$type}{$thing}[0];
                if (length(join ' ', '1', $buffer[1], $thing)+$length+1 > 510) {
                    $buffer[0] = '+' . $buffer[0];
                    push @output_modes, {
                        prefix   => $sid,
                        command  => 'BMASK',
                        colonify => 1,
                        params   => [
                            $chanrec->{ts},
                            $chanrec->{name},
                            $map{$type},
                            $buffer[1],
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
                prefix   => $sid,
                command  => 'BMASK',
                colonify => 1,
                params   => [
                    $chanrec->{ts},
                    $chanrec->{name},
                    $map{$type},
                    $buffer[1],
                ],
            } if $buffer[1];
        }
        $self->send_output($_, $conn_id) for @output_modes;

        if ( $tburst && $chanrec->{topic} ) {
            $self->send_output(
                {
                    prefix  => $sid,
                    command => 'TBURST',
                    params  => [
                        $chanrec->{ts},
                        $chanrec->{name},
                        @{ $chanrec->{topic} }[2,1,0],
                    ],
                    colonify => 1,
                },
                $conn_id,
            );
        }
    }

    # EOB for each connected peer if EOB supported
    # and our own EOB first
    if ( $burst ) {
      $self->send_output(
        {
            prefix  => $sid,
            command => 'EOB',
        },
        $conn_id,
      );
      delete $eobs{$sid};
      $self->send_output(
          {
              prefix  => $_,
              command => 'EOB',
          },
          $conn_id,
      ) for keys %eobs;
    }

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

    for my $server (keys %{ $self->{state}{sids}{$peer}{sids} }) {
        next if $server eq $targ;
        my $rec = $self->{state}{sids}{$server};
        my $desc = '';
        $desc = '(H) ' if $rec->{hidden};
        $desc .= $rec->{desc};
        push @$ref, {
            prefix  => $peer,
            command => 'SID',
            params  => [$rec->{name}, $rec->{hops} + 1, $server, $desc],
        };
        push @$ref, $_ for $self->_state_server_burst($rec->{sid}, $targ);
    }

    return @$ref if wantarray;
    return $ref;
}

sub _state_do_change_hostmask {
    my $self   = shift;
    my $uid    = shift || return;
    my $nhost  = shift || return;
    my $ref    = [ ];
    my $sid    = $self->server_sid();
    my $server = $self->server_name();

    SWITCH: {
        if ($nhost !~ $host_re ) {
          last SWITCH;
        }
        my $rec = $self->{state}{uids}{$uid};
        if ($nhost eq $rec->{auth}{hostname}) {
          last SWITCH;
        }
        my $local = ( $uid =~ m!^$sid! );
        my $conn_id = ($local ? $rec->{route_id} : '');
        my $full = $rec->{full}->();
        foreach my $chan ( keys %{ $rec->{chans} } ) {
          $self->_send_output_channel_local(
              $chan,
              {
                prefix  => $full,
                command => 'QUIT',
                params  => [ 'Changing hostname' ],
              },
              $conn_id, '', '', 'chghost'
          );
          $self->_send_output_channel_local(
              $chan,
              {
                prefix   => $full,
                command  => 'CHGHOST',
                colonify => 0,
                params   => [ $rec->{auth}{ident}, $nhost ],
              },
              $conn_id,
              '',
              'chghost'
          );
        }
        $rec->{auth}{hostname} = $nhost;
        if ($local) {
           $self->send_output(
              {
                  prefix  => $server,
                  command => '396',
                  params  => [
                      $rec->{nick},
                      $nhost,
                      'is now your visible host',
                  ],
              },
              $rec->{route_id},
           );
        }
        $full = $rec->{full}->();
        CHAN: foreach my $uchan ( keys %{ $rec->{chans} } ) {
           my $chan = $self->{state}{chans}{$uchan}{name};
           my $modeline;
           MODES: {
              my $modes = $rec->{chans}{$uchan};
              last MODES if !$modes;
              $modes = join '',
                map { $_->[1] }
                sort { $a->[0] cmp $b->[0] }
                map { my $w = $_; $w =~ tr/ohv/ABC/; [$w, $_] }
                split //, $modes;
              my @args;
              push @args, $_ for
                 map { $rec->{nick} } split //, $modes;
              $modeline = join ' ', "+$modes", @args;
           }
           $self->_send_output_channel_local(
              $chan,
              {
                prefix   => $full,
                command  => 'JOIN',
                colonify => 0,
                params   => [ $chan ],
              },
              $conn_id, '', '', [ qw[chghost extended-join] ]
           );
           $self->_send_output_channel_local(
              $chan,
              {
                prefix   => $full,
                command  => 'JOIN',
                colonify => 0,
                params   => [ $chan, $rec->{account}, $rec->{ircname} ],
              },
              $conn_id, '', 'extended-join', 'chghost'
           );
           if ($modeline) {
              $self->_send_output_channel_local(
                  $chan,
                  {
                      prefix   => $server,
                      command  => 'MODE',
                      colonify => 0,
                      params   => [ $chan, split m! !, $modeline ],
                  },
                  $conn_id, '', '', 'chghost'
              );
           }
           if ($rec->{away}) {
              $self->_send_output_channel_local(
                  $chan,
                  {
                      prefix   => $full,
                      command  => 'AWAY',
                      params   => [ $rec->{away} ],
                  },
                  $conn_id, '', 'away-notify', 'chghost'
              );
           }
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _state_do_map {
    my $self   = shift;
    my $nick   = shift || return;
    my $psid   = shift || return;
    my $isoper = shift;
    my $plen   = shift;
    my $ctn    = shift;
    my $ref    = [ ];
    return if !$self->state_sid_exists($psid);
    my $rec = $self->{state}{sids}{$psid};

    SWITCH: {
        my $global = scalar keys %{ $self->{state}{uids} };
        my $local  = scalar keys %{ $rec->{uids} };
        my $suffix = sprintf(" | Users: %5d (%1.2f%%)", $local, ( 100 * $local / $global ) );

        my $prompt = ' ' x $plen;
        substr $prompt, -2, 2, '|-' if $plen;
        substr $prompt, -2, 2, '`-' if !$ctn && $plen;
        my $buffer = $rec->{name} . ( $isoper ? "[$psid]" : '' ) . ' ';
        $buffer .= '-' x ( 64 - length($buffer) - length($prompt) );
        $buffer .= $suffix;

        if ( $plen && $plen > 60 ) {
            push @$ref, {
                prefix  => $self->server_name(),
                command => '016',
                params  => [
                    $nick,
                    join '', $prompt, $rec->{name}
                ],
            };
            last SWITCH;
        }

        push @$ref, {
            prefix  => $self->server_name(),
            command => '015',
            params  => [
                $nick,
                join '', $prompt, $buffer
            ],
        };
        my $sids = $self->{state}{sids}{$psid}{sids};
        my $cnt = keys %$sids;
        foreach my $server (sort { keys %{ $sids->{$a}{sids} } <=> keys %{ $sids->{$b}{sids} } } keys %$sids) {
          push @$ref, $_ for $self->_state_do_map( $nick, $server, $isoper, $plen + 2, --$cnt );
        }
    }

    return @$ref if wantarray;
    return $ref;
}

sub _state_sid_links {
    my $self = shift;
    my $psid = shift || return;
    my $orig = shift || return;
    my $nick = shift || return;
    my $mask = shift || '*';
    return if !$self->state_sid_exists($psid);

    my $ref = [ ];
    my $peer = $self->_state_sid_name($psid);

    my $sids = $self->{state}{sids}{$psid}{sids};
    for my $server (sort { keys %{ $sids->{$b}{sids} } <=> keys %{ $sids->{$a}{sids} } } keys %$sids) {
        my $rec = $self->{state}{sids}{$server};
        for ($self->_state_sid_links($server, $orig, $nick)) {
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
        } if matches_mask($mask, $rec->{name});
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
    my $sid = shift || return;
    return if !$self->state_sid_exists($sid);
    my $ref = [ ];
    push @$ref, $_ for keys %{ $self->{state}{sids}{$sid}{uids} };

    for my $psid (keys %{ $self->{state}{sids}{$sid}{sids} }) {
        push @$ref, $_ for $self->_state_server_squit($psid);
    }

    my $rec = delete $self->{state}{sids}{$sid};
    my $upeer = uc $rec->{name};
    my $me = uc $self->server_name();
    my $mysid = $self->server_sid();

    $self->_send_to_realops(
        sprintf(
            'Server %s split from %s',
            $rec->{name},
            $self->{state}{sids}{ $rec->{psid} }{name},
        ), qw[Notice e],
    ) if $mysid ne $rec->{psid};

    delete $self->{state}{peers}{$upeer};
    delete $self->{state}{peers}{$me}{peers}{$upeer};
    delete $self->{state}{peers}{$me}{sids}{$sid};
    return @$ref if wantarray;
    return $ref;
}

sub _state_register_peer {
    my $self    = shift;
    my $conn_id = shift || return;
    return if !$self->_connection_exists($conn_id);
    my $server  = $self->server_name();
    my $mysid   = $self->server_sid();
    my $record  = $self->{state}{conns}{$conn_id};
    my $psid    = $record->{ts_data}[1];
    return if !$psid;

    if (!$record->{cntr}) {
        $self->_state_send_credentials($conn_id, $record->{name});
    }

    $record->{burst} = $record->{registered} = 1;
    $record->{conn_time} = time;
    $record->{type} = 'p';
    $record->{route_id} = $conn_id;
    $record->{peer}     = $server;
    $record->{psid}     = $mysid;
    $record->{users} = { };
    $record->{peers} = { };
    $record->{sid} = $psid;
    my $ucname = uc $record->{name};
    $record->{serv} = 1 if $self->{state}{services}{$ucname};
    $self->{state}{peers}{uc $server}{peers}{ $ucname } = $record;
    $self->{state}{peers}{ $ucname } = $record;
    $self->{state}{sids}{ $mysid }{sids}{ $psid } = $record;
    $self->{state}{sids}{ $psid } = $record;
    $self->antiflood($conn_id, 0);

    if (my $sslinfo = $self->connection_secured($conn_id)) {
        $self->_send_to_realops(
            sprintf(
                'Link with %s[unknown@%s] established: [TLS: %s] (Capabilities: %s)',
                $record->{name}, $record->{socket}[0], $sslinfo, join(' ', @{ $record->{capab} }),
            ),
            'Notice',
            's',
        );
    }
    else {
        $self->_send_to_realops(
            sprintf(
                'Link with %s[unknown@%s] established: (Capabilities: %s)',
                $record->{name}, $record->{socket}[0], join(' ', @{ $record->{capab} }),
            ),
            'Notice',
            's',
        );
    }

    $self->send_output(
        {
            prefix  => $mysid,
            command => 'SID',
            params  => [
                $record->{name},
                $record->{hops} + 1,
                $psid,
                ( $record->{hidden} ? '(H) ' : '' ) .
                  $record->{desc},
            ],
        },
        grep { $_ ne $conn_id } $self->_state_connected_peers(),
    );

    $self->send_event(
        'daemon_sid',
        $record->{name},
        $mysid,
        $record->{hops},
        $psid,
        $record->{desc},
    );
    $self->send_event(
        'daemon_server',
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


    $record->{uid} = $self->_state_gen_uid();
    $record->{sid} = substr $record->{uid}, 0, 3;

    if (!$record->{auth}{ident}) {
        $record->{auth}{ident} = '~' . $record->{user};
    }

    if ($record->{auth}{hostname} eq 'localhost' ||
        !$record->{auth}{hostname} && $record->{socket}[0] =~ /^(127\.|::1)/) {
        $record->{auth}{hostname} = $self->server_name();
    }

    if (!$record->{auth}{hostname}) {
        $record->{auth}{hostname} = $record->{socket}[0];
    }

    $record->{auth}{realhost} = $record->{auth}{hostname};

    $record->{account} = '*';

    $record->{ipaddress} = $record->{socket}[0]; # Needed later for UID command
    $record->{ipaddress} = '0' if $record->{ipaddress} =~ m!^:!;

    my $unick = uc_irc $record->{nick};
    my $ucserver = uc $record->{server};
    $self->{state}{users}{$unick} = $record;
    $self->{state}{uids}{ $record->{uid} } = $record if $record->{uid};
    $self->{state}{peers}{$ucserver}{users}{$unick} = $record;
    $self->{state}{peers}{$ucserver}{uids}{ $record->{uid} } = $record if $record->{uid};

    $record->{full} = sub {
        return sprintf('%s!%s@%s',
          $record->{nick},
          $record->{auth}{ident},
          $record->{auth}{hostname});
    };

    my $umode = '+i';
    if ( $record->{secured} ) {
        $umode .= 'S';
        $record->{umode} = 'S';
        if (my $certfp = $self->connection_certfp($conn_id)) {
            $record->{certfp} = $certfp;
        }
    }

    my $arrayref = [
        $record->{nick},
        $record->{hops} + 1,
        $record->{ts}, $umode,
        $record->{auth}{ident},
        $record->{auth}{hostname},
        $record->{ipaddress},
        $record->{uid},
        $record->{account},
        $record->{ircname},
    ];

    my $rhostref = [
        $record->{nick},
        $record->{hops} + 1,
        $record->{ts}, $umode,
        $record->{auth}{ident},
        $record->{auth}{hostname},
        $record->{auth}{realhost},
        $record->{ipaddress},
        $record->{uid},
        $record->{account},
        $record->{ircname},
    ];

    delete $self->{state}{pending}{uc_irc($record->{nick})};

    foreach my $peer_id ( $self->_state_connected_peers() ) {
        if ( $self->_state_peer_capab( $peer_id, 'RHOST' ) ) {
            $self->send_output(
              {
                  prefix  => $record->{sid},
                  command => 'UID',
                  params  => $rhostref,
              },
              $peer_id,
            );
        }
        else {
            $self->send_output(
              {
                  prefix  => $record->{sid},
                  command => 'UID',
                  params  => $arrayref,
              },
              $peer_id,
            );
        }
        if ($record->{certfp}) {
            $self->send_output(
              {
                  prefix   => $record->{uid},
                  command  => 'CERTFP',
                  params   => [ $record->{certfp} ],
                  colonify => 0,
              },
              $peer_id,
            );
        }
    }

    $self->_send_to_realops(
        sprintf(
            'Client connecting: %s (%s@%s) [%s] {%s} [%s] <%s>',
            @{ $rhostref }[0,4,6], $record->{socket}[0],
            'users', $record->{ircname}, $record->{uid},
        ),
        'Notice',
        'c',
    );

    $self->send_event('daemon_uid', @$arrayref);
    $self->send_event('daemon_nick', @{ $arrayref }[0..5], $record->{server}, ( $arrayref->[9] || '' ) );
    $self->_state_update_stats();

    if ( defined $self->{state}{watches}{$unick} ) {
        foreach my $wuid ( keys %{ $self->{state}{watches}{$unick}{uids} } ) {
            next if !defined $self->{state}{uids}{$wuid};
            my $wrec = $self->{state}{uids}{$wuid};
            $self->send_output(
                {
                    prefix  => $record->{server},
                    command => '600',
                    params  => [
                         $wrec->{nick},
                         $record->{nick},
                         $record->{auth}{ident},
                         $record->{auth}{hostname},
                         $record->{ts},
                         'logged online',
                    ],
                },
                $wrec->{route_id},
            );
        }
    }
    return $record->{uid};
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

sub state_uid_exists {
    my $self = shift;
    my $uid = shift || return 1;
    return 1 if defined $self->{state}{uids}{$uid};
    return 0;
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

sub state_sid_exists {
    my $self = shift;
    my $sid  = shift || return;
    return 0 if !defined $self->{state}{sids}{ $sid };
    return 1;
}

sub state_check_joinflood_warning {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    my $joincount = $self->{config}{joinfloodcount};
    my $jointime  = $self->{config}{joinfloodtime};
    return if !$joincount || !$jointime;
    return if !$self->state_nick_exists($nick);
    return if !$self->state_chan_exists($chan);
    my $crec = $self->{state}{chans}{uc_irc $chan};
    $crec->{_num_joined}++;
    $crec->{_num_joined} -= ( time - ( $self->{_last_joined} || time ) ) *
                              ( $joincount / $jointime );
    if ( $crec->{_num_joined} <= 0 ) {
        $crec->{_num_joined} = 0;
        delete $crec->{_jfnotice};
    }
    elsif ( $crec->{_num_joined} >= $joincount ) {
        if ( !$crec->{_jfnotice} ) {
            $crec->{_jfnotice} = 1;
            my $urec = $self->{state}{users}{uc_irc $nick};
            $self->_send_to_realops(
                sprintf(
                    'Possible Join Flooder %s[%s] on %s target: %s',
                    $urec->{nick}, (split /!/,$urec->{full}->())[1],
                    $urec->{server}, $crec->{name},
                ),
                qw[Notice b],
            );
        }
    }
    $crec->{_last_joined} = time();
}

sub state_check_spambot_warning {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    my $spamnum = $self->{config}{MAX_JOIN_LEAVE_COUNT};
    return if !$self->state_nick_exists($nick);
    my $urec = $self->{state}{users}{uc_irc $nick};

    if ( $spamnum && $urec->{_jl_cnt} && $urec->{_jl_cnt} >= $spamnum ) {
        if ( $urec->{_owcd} && $urec->{_owcd} > 0 ) {
            $urec->{_owcd}--;
        }
        else {
            $urec->{_owcd} = 0;
        }
        if ( $urec->{_owcd} == 0 ) {
            my $msg = $chan ?
              sprintf(
                'User %s (%s) trying to join %s is a possible spambot',
                $urec->{nick}, (split /!/,$urec->{full}->())[1], $chan,
              ) :
              sprintf(
                'User %s (%s) is a possible spambot',
                $urec->{nick}, (split /!/,$urec->{full}->())[1],
              );
              $self->_send_to_realops(
                  $msg, qw[Notice b],
              );
              $urec->{_owcd} = $self->{config}{OPER_SPAM_COUNTDOWN};
        }
    }
    else {
        my $delta = time() - ( $urec->{_last_leave} || 0 );
        if ( $delta > $self->{config}{JOIN_LEAVE_COUNT_EXPIRE} ) {
           my $dec_cnt = $delta / $self->{config}{JOIN_LEAVE_COUNT_EXPIRE};
           if ($dec_cnt > ( $urec->{_jl_cnt} || 0 )) {
                $urec->{_jl_cnt} = 0;
           }
           else {
                $urec->{_jl_cnt} -= $dec_cnt;
           }
        }
        else {
           $urec->{_jl_cnt}++ if ( time() - $urec->{_last_join} )
                                    < $self->{config}{MIN_JOIN_LEAVE_TIME};
        }
        if ( $chan ) {
            $urec->{_last_join}  = time();
        }
        else {
            $urec->{_last_leave} = time();
        }
    }
}

sub state_flood_attack_channel {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    my $type = shift || 'PRIVMSG';
    return 0 if !$self->{config}{floodcount} || !$self->{config}{floodtime};
    return if !$self->state_nick_exists($nick);
    return if !$self->state_chan_exists($chan);
    my $urec = $self->{state}{users}{uc_irc $nick};
    return 0 if $urec->{route_id} eq 'spoofed';
    return 0 if $urec->{can_flood} || $urec->{umode} =~ /o/;
    my $crec = $self->{state}{chans}{uc_irc $chan};
    my $first = $crec->{_first_msg};
    if ( $first && ( $first + $self->{config}{floodtime} < time() ) ) {
       if ( $crec->{_recv_msgs} ) {
          $crec->{_recv_msgs} = 0;
       }
       else {
          $crec->{_flood_notice} = 0;
       }
       $crec->{_first_msg} = time();
    }
    my $recv = $crec->{_recv_msgs};
    if ( $recv && $recv >= $self->{config}{floodcount} ) {
       if ( !$crec->{_flood_notice} ) {
          $self->_send_to_realops(
              sprintf(
                'Possible Flooder %s[%s] on %s target: %s',
                $urec->{nick}, (split /!/, $urec->{full}->())[1],
                $urec->{server}, $crec->{name},
              ), qw[Notice b],
          );
          $crec->{_flood_notice} = 1;
       }
       if ( $type ne 'NOTICE' ) {
          $self->send_output(
              {
                  prefix  => $self->server_name(),
                  command => 'NOTICE',
                  params  => [
                      $urec->{nick},
                      "*** Message to $crec->{name} throttled due to flooding",
                  ],
              },
              $urec->{route_id},
          );
       }
       return 1;
    }
    $crec->{_first_msg} = time() if !$first;
    $crec->{_recv_msgs}++;
    return 0;
}

sub state_flood_attack_client {
    my $self = shift;
    my $nick = shift || return;
    my $targ = shift || return;
    my $type = shift || 'PRIVMSG';
    return 0 if !$self->{config}{floodcount} || !$self->{config}{floodtime};
    return if !$self->state_nick_exists($nick);
    return if !$self->state_nick_exists($targ);
    my $urec = $self->{state}{users}{uc_irc $nick};
    return 0 if $urec->{route_id} eq 'spoofed';
    return 0 if $urec->{can_flood} || $urec->{umode} =~ /o/;
    my $trec = $self->{state}{users}{uc_irc $targ};
    my $first = $trec->{_first_msg};
    if ( $first && ( $first + $self->{config}{floodtime} < time() ) ) {
       if ( $trec->{_recv_msgs} ) {
          $trec->{_recv_msgs} = 0;
       }
       else {
          $trec->{_flood_notice} = 0;
       }
       $trec->{_first_msg} = time();
    }
    my $recv = $trec->{_recv_msgs};
    if ( $recv && $recv >= $self->{config}{floodcount} ) {
       if ( !$trec->{_flood_notice} ) {
          $self->_send_to_realops(
              sprintf(
                'Possible Flooder %s[%s] on %s target: %s',
                $urec->{nick}, (split /!/, $urec->{full}->())[1],
                $urec->{server}, $trec->{nick},
              ), qw[Notice b],
          );
          $trec->{_flood_notice} = 1;
       }
       if ( $type ne 'NOTICE' ) {
          $self->send_output(
              {
                  prefix  => $self->server_name(),
                  command => 'NOTICE',
                  params  => [
                      $urec->{nick},
                      "*** Message to $trec->{nick} throttled due to flooding",
                  ],
              },
              $urec->{route_id},
          );
       }
       return 1;
    }
    $trec->{_first_msg} = time() if !$first;
    $trec->{_recv_msgs}++;
    return 0;
}

sub state_can_send_to_channel {
    my $self = shift;
    my $nick = shift || return;
    my $chan = shift || return;
    my $msg  = shift || return;
    my $type = shift || 'PRIVMSG';
    return if !$self->state_nick_exists($nick);
    return if !$self->state_chan_exists($chan);
    my $uid = $self->state_user_uid($nick);
    my $crec = $self->{state}{chans}{uc_irc $chan};
    my $urec = $self->{state}{uids}{$uid};
    my $member = defined $crec->{users}{$uid};

    if ( $crec->{mode} =~ /c/ && ( has_color($msg) || has_formatting($msg) ) ) {
        return [ '408', $crec->{name} ];
    }
    if ( $crec->{mode} =~ /C/ && $msg =~ m!^\001! && $msg !~ m!^\001ACTION! ) {
        return [ '492', $crec->{name} ];
    }
    if ( $crec->{mode} =~ /n/ && !$member ) {
        return [ '404', $crec->{name} ];
    }
    if ( $crec->{mode} =~ /M/ && $urec->{umode} !~ /r/ ) {
        return [ '477', $crec->{name} ];
    }
    if ( $member && $crec->{users}{$uid} ) {
        return 2;
    }
    if ( $crec->{mode} =~ /m/ ) {
        return [ '404', $crec->{name} ];
    }
    if ( $crec->{mode} =~ /T/ && $type eq 'NOTICE' ) {
        return [ '404', $crec->{name} ];
    }
    if ( $self->_state_user_banned($nick, $chan) ) {
        return [ '404', $crec->{name} ];
    }
    return 1;
}

sub _state_peer_name {
    my $self = shift;
    my $peer = shift || return;
    return if !$self->state_peer_exists($peer);
    return $self->{state}{peers}{uc $peer}{name};
}

sub _state_peer_sid {
    my $self = shift;
    my $peer = shift || return;
    if ( $peer =~ m!^\d! ) {
        return if !$self->state_sid_exists($peer);
        return $self->{state}{sids}{$peer}{sid};
    }
    else {
        return if !$self->state_peer_exists($peer);
        return $self->{state}{peers}{uc $peer}{sid};
    }
}

sub _state_sid_name {
    my $self = shift;
    my $sid = shift || return;
    return if !$self->state_sid_exists($sid);
    return $self->{state}{sids}{$sid}{name};
}

sub _state_sid_serv {
    my $self = shift;
    my $sid = shift || return;
    return if !$self->state_sid_exists($sid);
    return 0 if !$self->{state}{sids}{$sid}{serv};
    return 1;
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

sub _state_our_capab {
    my $self = shift;
    my $capab = shift || return;
    $capab = uc $capab;
    my $capabs = $self->{config}{capab};
    return scalar grep { $_ eq $capab } @{ $capabs };
}

sub state_user_full {
    my $self = shift;
    my $nick = shift || return;
    my $oper = shift;
    my $opuser = '';
    my $record;
    if ( $nick =~ m!^\d! ) {
      return if !$self->state_uid_exists($nick);
      $record = $self->{state}{uids}{$nick};
    }
    else {
      return if !$self->state_nick_exists($nick);
      $record = $self->{state}{users}{uc_irc($nick)};
    }
    if ( $oper && defined $record->{opuser} ) {
      $opuser = '{' . $record->{opuser} . '}';
    }
    return $record->{full}->() . $opuser;
}

sub state_user_nick {
    my $self = shift;
    my $nick = shift || return;
    if ( $nick =~ m!^\d! ) {
      return if !$self->state_uid_exists($nick);
      return $self->{state}{uids}{$nick}{nick};
    }
    else {
      return if !$self->state_nick_exists($nick);
      return $self->{state}{users}{uc_irc($nick)}{nick};
    }
}

sub state_user_uid {
    my $self = shift;
    my $nick = shift || return;
    if ( $nick =~ m!^\d! ) {
      return if !$self->state_uid_exists($nick);
      return $self->{state}{uids}{$nick}{uid};
    }
    else {
      return if !$self->state_nick_exists($nick);
      return $self->{state}{users}{uc_irc($nick)}{uid};
    }
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

sub _state_uid_route {
    my $self = shift;
    my $uid = shift || return;
    return if !$self->state_uid_exists($uid);
    my $record = $self->{state}{uids}{ $uid };
    return $record->{route_id};
}

sub state_user_server {
    my $self = shift;
    my $nick = shift || return;
    return if !$self->state_nick_exists($nick);
    my $record = $self->{state}{users}{uc_irc($nick)};
    return $record->{server};
}

sub state_uid_sid {
    my $self = shift;
    my $uid = shift || return;
    return if !$self->state_uid_exists($uid);
    return substr( $uid, 0, 3 );
}

sub _state_peer_route {
    my $self = shift;
    my $peer = shift || return;
    return if !$self->state_peer_exists($peer);
    my $record = $self->{state}{peers}{uc $peer};
    return $record->{route_id};
}

sub _state_sid_route {
    my $self = shift;
    my $sid = shift || return;
    return if !$self->state_sid_exists($sid);
    my $record = $self->{state}{sids}{$sid};
    return $record->{route_id};
}

sub _state_connected_peers {
    my $self = shift;
    my $server = uc $self->server_name();
    return if !(keys %{ $self->{state}{peers} } > 1);
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
    return map { $self->{state}{uids}{$_}{nick} }
        keys %{ $record->{users} } if !$status_msg;

    my %map = qw(o 3 h 2 v 1);
    my %sym = qw(@ 3 % 2 + 1);
    my $lowest = (sort map { $sym{$_} } split //, $status_msg)[0];

    return map { $self->{state}{uids}{$_}{nick} }
        grep {
            $record->{users}{ $_ } and (reverse sort map { $map{$_} }
            split //, $record->{users}{$_})[0] >= $lowest
        } keys %{ $record->{users} };
}

sub state_chan_list_prefixed {
    my $self = shift;
    my $chan = shift || return;
    my $flag = shift;
    return if !$self->state_chan_exists($chan);
    my $record = $self->{state}{chans}{uc_irc($chan)};

    return map {
        my $n = $self->{state}{uids}{$_}{nick};
        $n = (($flag && $flag eq 'FULL') ? $self->state_user_full($_) : $n );
        my $m = $record->{users}{$_};
        my $p = '';
        $p = '@' if $m =~ /o/;
        $p = '%' if $m =~ /h/ && !$p;
        $p = '+' if $m =~ /v/ && !$p;
        $p . $n;
    } keys %{ $record->{users} };
}

sub state_chan_list_multi_prefixed {
    my $self = shift;
    my $chan = shift || return;
    my $flag = shift;
    return if !$self->state_chan_exists($chan);
    my $record = $self->{state}{chans}{uc_irc($chan)};

    return map {
        my $rec = $self->{state}{uids}{$_};
        my $n = ( ($flag && $flag eq 'UIDS') ? $_ : $rec->{nick} );
        $n = (($flag && $flag eq 'FULL') ? $self->state_user_full($_) : $n );
        my $m = $record->{users}{$_};
        my $p = '';
        $p .= '@' if $m =~ /o/;
        $p .= '%' if $m =~ /h/;
        $p .= '+' if $m =~ /v/;
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
    my $record = $self->{state}{sids}{uc $self->server_sid()};
    if ( $nick =~ m!^\d! ) {
      return if !$self->state_uid_exists($nick);
      return 1 if defined $record->{uids}{$nick};
    }
    else {
      return if !$self->state_nick_exists($nick);
      return 1 if defined $record->{users}{uc_irc($nick)};
    }
    return 0;
}

sub _state_is_local_uid {
    my $self = shift;
    my $uid = shift || return;
    return if !$self->state_uid_exists($uid);
    return 1 if $self->server_sid() eq substr( $uid, 0, 3 );
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

sub state_uid_chan_member {
    my $self = shift;
    my $uid  = shift || return;
    my $chan = shift || return;
    return if !$self->state_uid_exists($uid);
    return 0 if !$self->state_chan_exists($chan);
    my $record = $self->{state}{uids}{$uid};
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

    if ($ops->{$user}{ssl_required}) {
        return -2 if $self->{state}{users}{uc_irc $nick}{umode} !~ /S/;
    }

    if ($ops->{$user}{certfp}) {
        my $certfp = $self->{state}{users}{uc_irc $nick}{certfp};
        if (!$certfp || uc($certfp) ne uc($ops->{$user}{certfp})) {
            return -3;
        }
    }

    my $client_ip = $self->_state_user_ip($nick);
    return if !$client_ip;
    if (!$ops->{$user}{ipmask} && ($client_ip && $client_ip =~ /^(127\.|::1)/)) {
        return 1;
    }
    return 0 if !$ops->{$user}{ipmask};

    if (ref $ops->{$user}{ipmask} eq 'ARRAY') {
        for my $block (@{ $ops->{$user}{ipmask} }) {
            if ( eval { $block->isa('Net::Netmask') } ) {
              return 1 if $block->match($client_ip);
              next;
            }
            return 1 if Net::CIDR::cidrlookup( $client_ip, $block );
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
        if ( $target =~ /^\$([^#].+)$/ ) {
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
        if ($target =~ $uid_re) {
            $results{$target} = ['uid'];
            next;
        }
        $results{$target} = ['nick'];
    }

    return \%results;
}

sub server_name {
    return $_[0]->{config}{'SERVERNAME'};
}

sub server_version {
    return $_[0]->{config}{'VERSION'};
}

sub server_sid {
    return $_[0]->{config}{'SID'};
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

sub _client_uid {
    my $self = shift;
    my $wheel_id = $_[0] || return;
    return '*' if !$self->{state}{conns}{$wheel_id}{uid};
    return $self->{state}{conns}{$wheel_id}{uid};
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
        NETWORKDESC   => 'poco mcpoconet',
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
        MAXCHANNELS   => 15,  # Think this is called CHANLIMIT now
        MAXACCEPT     => 20,
        MODES         => 4,
        MAXTARGETS    => 4,
        MAXCLIENTS    => 512,
        MAXBANS       => 50,
        MAXBANLENGTH  => 1024,
        AUTH          => 1,
        ANTIFLOOD     => 1,
        OPHACKS       => 0,
        JOIN_LEAVE_COUNT_EXPIRE     => 120,
        OPER_SPAM_COUNTDOWN         => 5,
        MAX_JOIN_LEAVE_COUNT        => 25,
        MIN_JOIN_LEAVE_TIME         => 60,
        knock_client_count          => 1,
        knock_client_time           => 5 * 60,
        knock_delay_channel         => 60,
        pace_wait                   => 10,
        max_watch                   => 50,
        max_bans_large              => 500,
        oper_umode                  => 'aceklnswy',
        anti_spam_exit_message_time => 5 * 60,
        anti_nick_flood             => 1,
        max_nick_time               => 20,
        max_nick_changes            => 5,
        floodcount                  => 10,
        floodtime                   => 1,
        joinfloodcount              => 18,
        joinfloodtime               => 6,
        hidden_servers              => '',
        hidden                      => '',
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
      next if $opt !~ m!^(knock_|pace_|max_watch|max_bans_|oper_umode|max_nick|anti_|flood|hidden)!i;
      $self->{config}{lc $opt} = delete $opts->{$opt}
        if defined $opts->{$opt};
    }

    $self->{config}{oper_umode} =~ s/[^DFGHRSWXabcdefgijklnopqrsuwy]+//g;
    $self->{config}{oper_umode} =~ s/[SWori]+//g;

    for my $opt (keys %$opts) {
        $self->{config}{$opt} = $opts->{$opt} if defined $opts->{$opt};
    }

    {
      my $sid = delete $self->{config}{SID};
      if (!$sid || $sid !~ $sid_re) {
        warn "No SID or SID is invalid, generating a random one\n";
        $self->_state_rand_sid();
      }
      else {
        $self->{config}{SID} = uc $sid;
      }
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
            || !(@{ $self->{config}{INFO} } == 1)) {
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
        263 => [1, "Server load is temporarily too heavy. Please wait a while and try again."],
        401 => [1, "No such nick/channel"],
        402 => [1, "No such server"],
        403 => [1, "No such channel"],
        404 => [1, "Cannot send to channel"],
        405 => [1, "You have joined too many channels"],
        406 => [1, "There was no such nickname"],
        407 => [1, "Too many targets"],
        408 => [1, "You cannot use control codes on this channel"],
        409 => [0, "No origin specified"],
        410 => [1, "Invalid CAP subcommand"],
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
        438 => [1, "Nick change too fast. Please wait %s seconds."],
        440 => [1, "Services are currently unavailable."],
        441 => [1, "They aren\'t on that channel"],
        442 => [1, "You\'re not on that channel"],
        443 => [2, "is already on channel"],
        444 => [1, "User not logged in"],
        445 => [0, "SUMMON has been disabled"],
        446 => [0, "USERS has been disabled"],
        447 => [0, "Cannot change nickname while on %s (+N)"],
        451 => [0, "You have not registered"],
        461 => [1, "Not enough parameters"],
        462 => [0, "Unauthorised command (already registered)"],
        463 => [0, "Your host isn\'t among the privileged"],
        464 => [0, "Password incorrect"],
        465 => [0, "You are banned from this server"],
        466 => [0, "You will be banned from this server"],
        467 => [1, "Channel key already set"],
        471 => [1, "Cannot join channel (+l)"],
        472 => [1, "is unknown mode char to me for %s"],
        473 => [1, "Cannot join channel (+i)"],
        474 => [1, "Cannot join channel (+b)"],
        475 => [1, "Cannot join channel (+k)"],
        476 => [1, "Bad Channel Mask"],
        477 => [1, "You need to identify to a registered nick to join or speak in that channel."],
        478 => [2, "Channel list is full"],
        481 => [0, "Permission Denied- You\'re not an IRC operator"],
        482 => [1, "You\'re not channel operator"],
        483 => [0, "You can\'t kill a server!"],
        484 => [0, "Your connection is restricted!"],
        485 => [1, "Cannot join channel (%s)"],
        489 => [1, "Cannot join channel (+S) - SSL/TLS required"],
        491 => [0, "Only few of mere mortals may try to enter the twilight zone"],
        492 => [1, "You cannot send CTCPs to this channel."],
        501 => [0, "Unknown MODE flag"],
        502 => [0, "Cannot change mode for other users"],
        512 => [0, "Maximum size for WATCH-list is %s entries"],
        520 => [1, "Cannot join channel (+O)"],
        521 => [0, "Bad list syntax"],
        524 => [1, "Help not found"],
        710 => [2, "has asked for an invite."],
        711 => [1, "Your KNOCK has been delivered."],
        712 => [1, "Too many KNOCKs (%s)."],
        713 => [1, "Channel is open."],
        714 => [1, "You are already on that channel."],
        723 => [1, "Insufficient oper privileges."],
    };

    $self->{config}{isupport} = {
        INVEX     => 'I',
        EXCEPTS   => 'e',
        CALLERID  => undef,
        CHANTYPES => '#&',
        KNOCK     => undef,
        PREFIX    => '(ohv)@%+',
        CHANMODES => 'beI,k,l,cimnprstuCLMNORST',
        STATUSMSG => '@%+',
        DEAF      => 'D',
        MAXLIST   => 'beI:' . $self->{config}{MAXBANS},
        SAFELIST  => undef,
        ELIST     => 'CMNTU',
        map { ($_, $self->{config}{$_}) }
            qw(MAXCHANNELS MAXTARGETS NICKLEN TOPICLEN KICKLEN CASEMAPPING
            NETWORK MODES AWAYLEN),
    };

    $self->{config}{capab} = [qw(KNOCK DLN TBURST UNDLN ENCAP UNKLN KLN RHOST SVS CLUSTER EOB QS)];

    $self->{config}{cmds}{uc $_}++ for
        qw[accept admin away bmask cap close connect die dline encap eob etrace globops info invite ison isupport join kick kill],
        qw[kline knock links list locops lusers map message mode motd names nick oper part pass ping pong quit rehash remove],
        qw[resv rkline set sid sjoin squit stats summon svinfo svshost svsjoin svskill svsmode svsnick svspart svstag tburst time],
        qw[tmode topic trace uid umode undline unkline unresv unrkline unxline user userhost users version wallops watch who whois whowas xline];

    return 1;
}

sub _send_to_realops {
    my $self     = shift;
    my $msg      = shift || return;
    my $type     = shift || 'Notice';
    my $flags    = shift; # Future use
    my $server   = $self->server_name();
    $flags =~ s/[^a-zA-Z]+//g if $flags;

    my %types = (
      NOTICE  => 'Notice',
      LOCOPS  => 'LocOps',
      GLOBOPS => 'Global',
    );

    my $notice =
      sprintf('*** %s -- %s', ( $types{uc $type} || 'Notice' ), $msg );

    my @locops;

    if ( $flags ) {
      @locops = grep { $self->{state}{conns}{$_}{umode} =~ m![$flags]! }
                  keys %{ $self->{state}{localops} };
    }
    else {
      @locops = keys %{ $self->{state}{localops} };
    }

    $self->send_event( 'daemon_snotice', $notice );

    $self->send_output(
         {
            prefix  => $server,
            command => 'NOTICE',
            params  => [
                '*',
                $notice,
            ],
         },
         @locops,
    );
    return 1;
}

sub _send_output_to_client {
    my $self     = shift;
    my $wheel_id = shift || return 0;
    my $nick     = $self->_client_nickname($wheel_id);
    my $prefix   = $self->server_name();
    if ( $self->_connection_is_peer($wheel_id) ) {
        $nick   = shift;
        $prefix = $self->server_sid();
    }
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

sub _send_output_channel_local {
    my $self    = shift;
    my $channel = shift || return;
    return if !$self->state_chan_exists($channel);
    my ($output,$conn_id,$status,$poscap,$negcap) = @_;
    return if !$output;
    my $sid = $self->server_sid();

    my $is_msg = ( $output->{command} =~ m!^(PRIVMSG|NOTICE)$! ? 1 : 0 );
    my $chanrec = $self->{state}{chans}{uc_irc($channel)};
    my @targs;
    my $negative = ( $status ? $status =~ s!^\-!! : '' );
    UID: foreach my $uid ( keys %{ $chanrec->{users} } ) {
      next if $uid !~ m!^$sid!;
      my $route_id = $self->_state_uid_route( $uid );
      if ( $conn_id && $conn_id eq $route_id ) {
        next UID;
      }
      if ( $status ) {
        my $matched;
        STATUS: foreach my $stat ( split //, $status ) {
          $matched++ if $chanrec->{users}{$uid} =~ m!$stat!;
        }
        next UID if ( $negative && $matched ) || ( !$negative && !$matched );
      }
      if ( $poscap ) {
        foreach my $cap ( @{ ref $poscap eq 'ARRAY' ? $poscap : [ $poscap ] } ) {
            next UID if !$self->{state}{uids}{$uid}{caps}{$cap};
        }
      }
      if ( $negcap ) {
        foreach my $cap ( @{ ref $negcap eq 'ARRAY' ? $negcap : [ $negcap ] } ) {
            next UID if $self->{state}{uids}{$uid}{caps}{$cap};
        }
      }
      if ( $is_msg && $self->{state}{uids}{$uid}{umode} =~ m!D! ) { # +D 'deaf'
        next UID;
      }
      # Default
      push @targs, $route_id;
    }

    $self->send_output($output,@targs);

    my $spoofs = grep { $_ eq 'spoofed' } @targs;

    $self->send_event(
        "daemon_" . lc $output->{command},
        $output->{prefix},
        @{ $output->{params} },
    ) if !$is_msg || $spoofs;

    return 1;
}

sub _duration {
    my $duration = shift;
    $duration = 0 if !defined $duration || $duration !~ m!^\d+$!;
    my $timestr;
    my $days = my $hours = my $mins = my $secs = 0;
    while ($duration >= 60 * 60 * 24) {
        $duration -= 60 * 60 * 24;
        ++$days;
    }
    while ($duration >= 60 * 60) {
        $duration -= 60 * 60;
        ++$hours;
    }
    while ($duration >= 60) {
        $duration -= 60;
        ++$mins;
    }
    $secs = $duration;
    return sprintf(
        '%u day%s, %02u:%02u:%02u',
        $days, ($days == 1 ? '' : 's'), $hours, $mins, $secs,
    );
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

    if (($ref->{ssl_required} || $ref->{certfp}) && !$self->{got_ssl}) {
        warn "SSL required, but it is not supported, ignoring\n";
        delete $ref->{ssl_required};
        delete $ref->{certfp};
    }

    if ( $ref->{ipmask} && $ref->{ipmask} eq 'ARRAY' ) {
      my @validated;
      foreach my $mask ( @{ $ref->{ipmask} } ) {
        if ( eval { $mask->isa('Net::Netmask' ) } ) {
          push @validated, $mask;
          next;
        }
        my $valid = Net::CIDR::cidrvalidate($mask);
        push @validated, $valid if $valid;
      }
      $ref->{ipmask} = \@validated;
    }

    if ( $ref->{umode} ) {
        $ref->{umode} =~ s/[^DFGHRSWXabcdefgijklnopqrsuwy]+//g;
        $ref->{umode} =~ s/[SWori]+//g;
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

sub add_service {
    my $self = shift;
    my $host = shift || return;
    $self->{state}{services}{uc $host} = $host;
    return 1;
}

sub del_service {
    my $self = shift;
    my $host = shift || return;
    delete $self->{state}{services}{uc $host};
    return 1;
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
    $parms->{ssl} = 0 if !$parms->{ssl};

    if ( $parms->{ipmask} && $parms->{ipmask} eq 'ARRAY' ) {
      my @validated;
      foreach my $mask ( @{ $parms->{ipmask} } ) {
        if ( eval { $mask->isa('Net::Netmask' ) } ) {
          push @validated, $mask;
          next;
        }
        my $valid = Net::CIDR::cidrvalidate($mask);
        push @validated, $valid if $valid;
      }
      $parms->{ipmask} = \@validated;
    }

    my $name = $parms->{name};
    $self->{config}{peers}{uc $name} = $parms;
    $self->add_service( $name ) if $parms->{service};
    $self->add_connector(
        remoteaddress => $parms->{raddress},
        remoteport    => $parms->{rport},
        name          => $name,
        usessl        => $parms->{ssl},
    ) if $parms->{type} eq 'r' && $parms->{auto};

    return 1;
}

sub del_peer {
    my $self = shift;
    my $name = shift || return;
    return if !defined $self->{config}{peers}{uc $name};
    my $rec = delete $self->{config}{peers}{uc $name};
    $self->del_service( $rec->{name} ) if $rec->{service};
    return;
}

sub add_pseudo {
    my $self = shift;
    my $parms;
    if (ref $_[0] eq 'HASH') {
        $parms = $_[0];
    }
    else {
        $parms = { @_ };
    }
    $parms->{lc $_} = delete $parms->{$_} for keys %$parms;

    if (!defined $parms->{cmd} || !defined $parms->{name}
           || !defined $parms->{target}) {
        croak((caller(0))[3].": Not enough parameters specified\n");
        return;
    }

    my ($nick,$user,$host) = parse_user( $parms->{target} );

    if (!$nick || !$user || !$host) {
        croak((caller(0))[3].": target is invalid\n");
        return;
    }

    $parms->{nick} = $nick;
    $parms->{user} = $user;
    $parms->{host} = $host;

    my $cmd = delete $parms->{cmd};
    $cmd = uc $cmd;

    if (defined $self->{config}{cmds}{$cmd} || defined $self->{config}{pseudo}{$cmd}) {
        croak((caller(0))[3].": That command already exists\n");
        return;
    }

    $self->{config}{pseudo}{$cmd} = $parms;
    return 1;
}

sub del_pseudo {
    my $self = shift;
    my $cmd  = shift || return;
    delete $self->{config}{pseudo}{uc $cmd};
    return 1;
}

sub _terminate_conn_error {
    my $self    = shift;
    my $conn_id = shift || return;
    my $msg     = shift;
    return if !$self->_connection_exists($conn_id);

    $self->disconnect($conn_id, $msg);
    $self->{state}{conns}{$conn_id}{terminated} = 1;
    if ( $self->{state}{conns}{$conn_id}{type} eq 'c' ) {
        my $conn = $self->{state}{conns}{$conn_id};
        $self->_send_to_realops(
            sprintf(
                'Client exiting: %s (%s@%s) [%s] [%s]',
                $conn->{nick},
                $conn->{auth}{ident},
                $conn->{auth}{realhost},
                $conn->{socket}[0],
                $msg,
            ),
            'Notice',
            'c',
        );
    }
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

    foreach my $nick ( keys %{ $self->{state}{pending} }) {
        my $id = $self->{state}{pending}{$nick};
        if ($id == $conn_id) {
            delete $self->{state}{pending}{$nick};
            last;
        }
    }

    return 1;
}

sub daemon_server_join {
    my $self   = shift;
    my $server = $self->server_name();
    my $mysid  = $self->server_sid();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$count || $count < 2) {
            last SWITCH;
        }
        if ( $args->[0] =~ m!^\d! && !$self->state_uid_exists($args->[0]) ) {
            last SWITCH;
        }
        elsif ( $args->[0] !~ m!^\d! && !$self->state_nick_exists($args->[0])) {
            last SWITCH;
        }
        if ( $args->[1] !~ m!^[#&]! ) {
            last SWITCH;
        }
        $ref = $self->_daemon_peer_svsjoin( 'spoofed', $mysid, @$args );
    }

    return @$ref if wantarray;
    return $ref;
}

sub daemon_server_kill {
    my $self   = shift;
    my $server = $self->server_name();
    my $mysid  = $self->server_sid();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$count) {
            last SWITCH;
        }
        if ( $args->[0] =~ m!^\d! && !$self->state_uid_exists($args->[0]) ) {
            last SWITCH;
        }
        elsif ( $args->[0] !~ m!^\d! && !$self->state_nick_exists($args->[0])) {
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
            $self->send_output(
                {
                    prefix  => $mysid,
                    command => 'KILL',
                    params  => [
                        $self->state_user_uid($target),
                        join('!', $server, $target )." ($comment)",
                    ],
                },
                grep { !$conn_id || $_ ne $conn_id }
                    $self->_state_connected_peers(),
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
            my $tuid = $self->state_user_uid( $target );
            $self->{state}{uids}{$tuid}{killed} = 1;
            $self->send_output(
                {
                    prefix  => $mysid,
                    command => 'KILL',
                    params  => [$tuid, "$server ($comment)"],
                },
                grep { !$conn_id || $_ ne $conn_id }
                    $self->_state_connected_peers(),
            );
            $self->send_output(
            @{ $self->_daemon_peer_quit(
                $tuid,
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
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    SWITCH: {
        if (!$self->state_chan_exists($chan)) {
            last SWITCH;
        }
        my $record = $self->{state}{chans}{uc_irc($chan)};
        $chan = $record->{name};
        my $mode_u_set   = ( $record->{mode} =~ /u/ );
        my $full = $server;
        my %subs; my @reply_args; my $reply;
        my $parsed_mode = parse_mode_line(@$args);

        while(my $mode = shift (@{ $parsed_mode->{modes} })) {
            next if $mode !~ /^[+-][CceIbkMNRSTLOlimnpstohuv]$/;
            my $arg;
            if ($mode =~ /^(\+[ohvklbIe]|-[ohvbIe])/) {
                $arg = shift @{ $parsed_mode->{args} };
            }
            if (my ($flag, $char) = $mode =~ /^([-+])([ohv])/ ) {

                if ($flag eq '+'
                    && $record->{users}{$self->state_user_uid($arg)} !~ /$char/) {
                    # Update user and chan record
                    $arg = $self->state_user_uid($arg);
                    $record->{users}{$arg} = join('', sort
                        split //, $record->{users}{$arg} . $char);
                    $self->{state}{uids}{$arg}{chans}{uc_irc($chan)}
                        = $record->{users}{$arg};
                    $reply .= $mode;
                    my $anick = $self->state_user_nick($arg);
                    $subs{$anick} = $arg;
                    push @reply_args, $anick;
                }

                if ($flag eq '-' && $record->{users}{uc_irc($arg)}
                    =~ /$char/) {
                    # Update user and chan record
                    $arg = $self->state_user_uid($arg);
                    $record->{users}{$arg} =~ s/$char//g;
                    $self->{state}{uids}{$arg}{chans}{uc_irc($chan)}
                        = $record->{users}{$arg};
                    $reply .= $mode;
                    my $anick = $self->state_user_nick($arg);
                    $subs{$anick} = $arg;
                    push @reply_args, $anick;
                }
                next;
            }
            if ($mode eq '+l' && $arg =~ /^\d+$/ && $arg > 0) {
                $reply .= $mode;
                push @reply_args, $arg;
                if ($record->{mode} !~ /l/) {
                $record->{mode} = join('', sort split //,
                    $record->{mode} . 'l');
                }
                $record->{climit} = $arg;
                next;
            }
            if ($mode eq '-l' && $record->{mode} =~ /l/) {
                $reply .= $mode;
                $record->{mode} =~ s/l//g;
                delete $record->{climit};
                next;
            }
            if ($mode eq '+k' && $arg) {
                $reply .= $mode;
                push @reply_args, $arg;
                if ($record->{mode} !~ /k/) {
                    $record->{mode} = join('', sort split //,
                        $record->{mode} . 'k');
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
            if (my ($flag) = $mode =~ /(\+|-)b/) {
                my $mask = normalize_mask($arg);
                my $umask = uc_irc($mask);
                if ($flag eq '+' && !$record->{bans}{$umask}) {
                    $record->{bans}{$umask}
                        = [$mask, ($full || $server), time];
                    $reply .= $mode;
                    push @reply_args, $mask;
                }
                if ($flag eq '-' and $record->{bans}{$umask}) {
                    delete $record->{bans}{$umask};
                    $reply .= $mode;
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
            if (my ($flag) = $mode =~ /(\+|-)e/) {
                my $mask = normalize_mask($arg);
                my $umask = uc_irc($mask);
                if ($flag eq '+' && !$record->{excepts}{$umask}) {
                    $record->{excepts}{$umask}
                        = [$mask, ($full || $server), time];
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
                $record->{mode} = join('', sort split //,
                $record->{mode} . $char);
                $reply .= $mode;
                next;
            }
            if ($flag eq '-' && $record->{mode} =~ /$char/) {
                $record->{mode} =~ s/$char//g;
                $reply .= $mode;
                next;
            }
        } # while

        if ($reply) {
            $reply = unparse_mode_line($reply);
            my @reply_args_peer = map {
              ( defined $subs{$_} ? $subs{$_} : $_ )
            } @reply_args;
            $self->send_output(
               {
                  prefix  => $sid,
                  command => 'TMODE',
                  params  => [$record->{ts}, $chan, $reply, @reply_args_peer],
                  colonify => 0,
               },
               $self->_state_connected_peers(),
            );
            $self->_send_output_channel_local(
                $record->{name},
                {
                    prefix   => $server,
                    command  => 'MODE',
                    colonify => 0,
                    params   => [
                        $record->{name},
                        $reply,
                        @reply_args,
                    ],
                },
                '', ( $mode_u_set ? 'oh' : '' ),
            );
            if ($mode_u_set) {
                my $bparse = parse_mode_line( $reply, @reply_args );
                my $breply; my @breply_args;
                while (my $bmode = shift (@{ $bparse->{modes} })) {
                    my $arg;
                    $arg = shift @{ $bparse->{args} }
                      if $bmode =~ /^(\+[ohvklbIe]|-[ohvbIe])/;
                      next if $bmode =~ m!^[+-][beI]$!;
                      $breply .= $bmode;
                      push @breply_args, $arg if $arg;
                }
                if ($breply) {
                   my $parsed_line = unparse_mode_line($breply);
                   $self->_send_output_channel_local(
                      $record->{name},
                      {
                          prefix   => $server,
                          command  => 'MODE',
                          colonify => 0,
                          params   => [
                              $record->{name},
                              $parsed_line,
                              @breply_args,
                          ],
                      },
                      '','-oh',
                   );
                }
            }
        }
    } # SWITCH

    return @$ref if wantarray;
    return $ref;
}

sub daemon_server_kick {
    my $self   = shift;
    my $server = $self->server_name();
    my $sid    = $self->server_sid();
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
        my $wuid = $self->state_user_uid($who);
        my $comment = $args->[2] || $who;
        $self->send_output(
            {
                prefix  => $sid,
                command => 'KICK',
                params  => [$chan, $wuid, $comment],
            },
            $self->_state_connected_peers(),
        );
        $self->_send_output_channel_local(
            $chan,
            {
                prefix  => $server,
                command => 'KICK',
                params  => [$chan, $who, $comment],
            },
        );
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$wuid};
        delete $self->{state}{uids}{$wuid}{chans}{$chan};
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
        my $wuid = $self->state_user_uid($who);
        my $comment = 'Enforced PART';
        $comment .= " \"$args->[2]\"" if $args->[2];
        $self->send_output(
            {
                prefix  => $wuid,
                command => 'PART',
                params  => [$chan, $comment],
            },
            $self->_state_connected_peers(),
        );
        $self->_send_output_channel_local(
            $chan,
            {
                prefix  => $fullwho,
                command => 'PART',
                params  => [$chan, $comment],
            },
        );
        $chan = uc_irc($chan);
        delete $self->{state}{chans}{$chan}{users}{$wuid};
        delete $self->{state}{uids}{$wuid}{chans}{$chan};
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
    my $sid    = $self->server_sid();
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    if ($count) {
        $self->send_output(
            {
                prefix  => $sid,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            $self->_state_connected_peers(),
        );
        $self->send_output(
            {
                prefix  => $server,
                command => 'WALLOPS',
                params  => [$args->[0]],
            },
            keys %{ $self->{state}{wallops} },
        );
        $self->send_event("daemon_wallops", $server, $args->[0]);
    }

    return @$ref if wantarray;
    return $ref;
}

sub daemon_server_realops {
    my $self   = shift;
    my $ref    = [ ];
    my $args   = [ @_ ];
    my $count  = @$args;

    if ($count) {
        $self->_send_to_realops( @$args );
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
    $record->{uid} = $self->_state_gen_uid();
    $record->{sid} = substr $record->{uid}, 0, 3;
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
    $record->{auth}{realhost} = $record->{auth}{hostname};
    $record->{account} = '*' if !$record->{account};
    $record->{ipaddress} = 0;
    $self->{state}{users}{uc_irc($record->{nick})} = $record;
    $self->{state}{uids}{ $record->{uid} } = $record if $record->{uid};
    $self->{state}{peers}{uc $record->{server}}{users}{uc_irc($record->{nick})} = $record;
    $self->{state}{peers}{uc $record->{server}}{uids}{ $record->{uid} } = $record if $record->{uid};

    $record->{full} = sub {
        return sprintf('%s!%s@%s',
          $record->{nick},
          $record->{auth}{ident},
          $record->{auth}{hostname});
    };

    my $arrayref = [
        $record->{nick},
        $record->{hops} + 1,
        $record->{ts},
        '+' . $record->{umode},
        $record->{auth}{ident},
        $record->{auth}{hostname},
        $record->{ipaddress},
        $record->{uid},
        $record->{account},
        $record->{ircname},
    ];

    my $rhostref = [
        $record->{nick},
        $record->{hops} + 1,
        $record->{ts},
        '+' . $record->{umode},
        $record->{auth}{ident},
        $record->{auth}{hostname},
        $record->{auth}{realhost},
        $record->{ipaddress},
        $record->{uid},
        $record->{account},
        $record->{ircname},
    ];

    if (my $whois = $record->{whois}) {
        $record->{svstags}{313} = {
             numeric => '313',
             umodes  => '+',
             tagline => $whois,
        };
    }

    foreach my $peer_id ( $self->_state_connected_peers() ) {
        if ( $self->_state_peer_capab( $peer_id, 'RHOST' ) ) {
            $self->send_output(
              {
                  prefix  => $record->{sid},
                  command => 'UID',
                  params  => $rhostref,
              },
              $peer_id,
            );
        }
        else {
            $self->send_output(
              {
                  prefix  => $record->{sid},
                  command => 'UID',
                  params  => $arrayref,
              },
              $peer_id,
            );
        }
        $self->send_output(
             {
                prefix  => $record->{sid},
                command => 'SVSTAG',
                params  => [
                  $record->{uid},
                  $record->{ts},
                  '313', '+', $record->{whois},
                ],
             },
             $peer_id,
        ) if $record->{whois};
    }


    $self->send_event('daemon_uid', @$arrayref);
    $self->send_event('daemon_nick', @{ $arrayref }[0..5], $record->{server}, ( $arrayref->[9] || '' ) );
    if ( $record->{umode} =~ /o/ ) {
        my $notice = sprintf("%s{%s} is now an operator",$record->{full}->(),$record->{nick});
        $self->_send_to_realops($notice);
    }
    $self->_state_update_stats();
    return;
}

sub del_spoofed_nick {
    my ($kernel, $self, $nick) = @_[KERNEL, OBJECT, ARG0];
    if ( $nick =~ m!^\d! ) {
      return if !$self->state_uid_exists($nick);
      return if $self->_state_uid_route($nick) ne 'spoofed';
    }
    else {
      return if !$self->state_nick_exists($nick);
      return if $self->_state_user_route($nick) ne 'spoofed';
    }
    $nick = $self->state_user_nick($nick);

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
    my $uid = $self->state_user_uid($nick);
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
            $self->server_sid(),
            $ts,
            $chan,
            '+nt',
            '@' . $uid,
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
foreign IRC networks. It supports the TS6 server to server protocol and
has been tested with linking to Hybrid-8 based networks. It should in
theory work with any TS6-based IRC network.

POE::Component::Server::IRC also has a services API, which enables one to
extend the IRCd to create IRC Services. This is fully event-driven (of
course =]). There is also a Plugin system, similar to that sported by
L<POE::Component::IRC|POE::Component::IRC>.

B<Note:> This is a subclass of
L<POE::Component::Server::IRC::Backend|POE::Component::Server::IRC::Backend>.
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

=item * B<'sid'>, servers unique ID.  This is three characters long and must be in
the form [0-9][A-Z0-9][A-Z0-9]. Specifying this enables C<TS6>.

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

=item * B<'exceed_limit'>, if specified, any client matching the mask will not
have their connection limited, if the server is full;

=item * B<'kline_exempt'>, if true, any client matching the mask will be exempt
from KLINEs and RKLINEs;

=item * B<'resv_exempt'>, if true, any client matching the mask will be exempt
from RESVs;

=item * B<'can_flood'>, if true, any client matching the mask will be exempt
from flood protection;

=item * B<'need_ident'>, if true, any client matching the mask will be
required to have a valid response to C<Ident> queries;

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

=item * B<'ipmask'>, either a scalar ipmask or an arrayref of addresses or CIDRs
as understood by L<Net::CIDR>::cidrvalidate;

=item * B<'ssl_required'>, set to true to require that the oper is connected
securely using SSL/TLS;

=item * B<'certfp'>, specify the fingerprint of the oper's client certificate
to verify;

=back

A scalar ipmask can contain '*' to match any number of characters or '?' to
match one character. If no 'ipmask' is provided, operators are only allowed
to OPER from the loopback interface.

B<'password'> can be either plain-text, L<C<crypt>|crypt>'d or unix/apache
md5. See the C<mkpasswd> function in
L<POE::Component::Server::IRC::Common|POE::Component::Server::IRC::Common>
for how to generate passwords.

B<'ssl_required'> and B<'certfp'> obviously both require that the server
supports SSL/TLS connections. B<'certfp'> is the SHA256 digest fingerprint
of the client certificate. This can be obtained from the PEM formated cert
using one of the following methods:

  OpenSSL/LibreSSL:
    openssl x509 -sha256 -noout -fingerprint -in cert.pem | sed -e 's/^.*=//;s/://g'

  GnuTLS:
    certtool -i < cert.pem | egrep -A 1 'SHA256 fingerprint'

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

=item * B<'ipmask'>, either a scalar ipmask or an arrayref of addresses or CIDRs
as understood by L<Net::CIDR>::cidrvalidate;

=item * B<'auto'>, if set to true value will automatically connect to
remote server if type is 'r';

=item * B<'zip'>, set to a true value to enable ziplink support. This must
be done on both ends of the connection. Requires
L<POE::Filter::Zlib::Stream|POE::Filter::Zlib::Stream>;

=item * B<'service'>, set to a true value to enable the peer to be
accepted as a services peer.

=item * B<'ssl'>, set to a true value to enable SSL/TLS support. This must
be done on both ends of the connection. Requires L<POE::Component::SSLify>.

=item * B<'certfp'>, specify the fingerprint of the peer's client certificate
to verify;

=back

B<'certfp'> is the SHA256 digest fingerprint of the client certificate.
This can be obtained from the PEM formated cert using one of the following
methods:

  OpenSSL/LibreSSL:
    openssl x509 -sha256 -noout -fingerprint -in cert.pem | sed -e 's/^.*=//;s/://g'

  GnuTLS:
    certtool -i < cert.pem | egrep -A 1 'SHA256 fingerprint'

=head3 C<del_peer>

Takes a single argument, the peer to remove. This does not disconnect the
said peer if it is currently connected.

=head3 C<add_service>

Adds a service peer. A service peer is a peer that is accepted to send
service commands C<SVS*>. Takes a single argument the service peer to add.
This does not have to be a directly connected peer as defined with C<add_peer>.

=head3 C<del_service>

Takes a single argument, the service peer to remove. This does not disconnect
the said service peer, but it will deny the peer access to service commands.

=head3 C<add_pseudo>

Adds a pseudo command, also known as a service alias. The command is transformed
by the server into a C<PRIVMSG> and sent to the given target.

Takes several arguments:

=over 4

=item * B<'cmd'>, (mandatory) command/alias to be added.

=item * B<'name'>, (mandatory) the service name, eg. NickServ, this is
used in error messages reported to users.

=item * B<'target'>, (mandatory) the target for the command in nick!user@host
format.

=item * B<'prepend'>, (optional) text that will prepended to the user's
message.

=back

=head3 C<del_pseudo>

Removes a previously defined pseudo command/alias.

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

If a second argument is provided and the nickname provided is an oper,
then the returned value will be nick!user@host{opuser}

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

=head3 C<daemon_server_join>

Takes two arguments that are mandatory: a nickname of a user and a channel
name. The user will join the channel.

=head3 C<daemon_server_kick>

Takes two arguments that are mandatory and an optional one: channel name,
nickname of the user to kick and a pithy comment.

=head3 C<daemon_server_remove>

Takes two arguments that are mandatory and an optional one: channel name,
nickname of the user to remove and a pithy comment.

=head3 C<daemon_server_wallops>

Takes one argument, the message text to send.

=head3 C<daemon_server_realops>

Sends server notices.

Takes one mandatory argument, the message text to send.

Second argument is the notice type, this can be C<Notice>, C<locops>
or C<Globops>. Defaults to C<Notice>.

Third argument is a umode flag. The notice will be sent to OPERs who
have this umode set. Default is none and the notice will be sent to
all OPERs.

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

=head3 C<daemon_cmd_unrkline>

Removes an RKLINE as indicated by the user@host mask supplied. 

To remove a RKLINE:

 $ircd->yield(
     'daemon_cmd_unrkline',
     $spoofed_nick,
     $user_host_mask,
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

=head3 C<daemon_cmd_globops>

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

=head2 C<ircd_daemon_snotice>

=over

=item Emitted: when the server issues a notice for various reasons

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the message;

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

=head2 C<ircd_daemon_dline>

=over

=item Emitted: when an oper issues a DLINE command;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host;

=item * C<ARG1>, the duration;

=item * C<ARG2>, the network mask;

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

=head2 C<ircd_daemon_expired>

=over

=item Emitted: when a temporary D-Line, X-Line, K-Line or RK-Line expires

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, What expired, can be C<d-line>, C<x-line>, C<k-line> or C<rk-line>;

=item * C<ARG1>, the mask (D-Line and X-Line) or user@host (K-Line and RK-Line);

=back

=back

=head2 C<ircd_daemon_encap>

=over

=item Emitted: when the server receives an C<ENCAP> message;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the server name or full nick!user@host;

=item * C<ARG1>, peermask of targets for the C<ENCAP>;

=item * C<ARG2>, the sub command being propagated;

=item * Subsequent ARGs are dependent on the sub command;

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

=head2 C<ircd_daemon_globops>

=over

=item Emitted: when an oper or server issues a GLOBOPS;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the full nick!user@host or server name;

=item * C<ARG1>, the globops message;

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

L<Net::CIDR|Net::CIDR>

Hybrid IRCD L<http://ircd-hybrid.com/>

RFC 2810 L<http://www.faqs.org/rfcs/rfc2810.html>

RFC 2811 L<http://www.faqs.org/rfcs/rfc2811.html>

RFC 2812 L<http://www.faqs.org/rfcs/rfc2812.html>

RFC 2813 L<http://www.faqs.org/rfcs/rfc2813.html>

=cut
