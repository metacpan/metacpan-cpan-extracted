#!/usr/bin/perl -w
package Net::BitTorrent;
{
    use strict;
    use warnings;
    use Scalar::Util qw[blessed weaken refaddr];
    use List::Util qw[max];
    use Time::HiRes;
    use Socket qw[/inet_/ SOCK_STREAM SOCK_DGRAM SOL_SOCKET PF_INET SOMAXCONN
        /pack_sockaddr_in/ SO_REUSEADDR];
    use Carp qw[carp];
    use Digest::SHA qw[sha1_hex];
    use POSIX qw[];
    sub _EWOULDBLOCK { $^O eq q[MSWin32] ? 10035 : POSIX::EWOULDBLOCK() }
    sub _EINPROGRESS { $^O eq q[MSWin32] ? 10036 : POSIX::EINPROGRESS() }
    use lib q[../../lib];
    use Net::BitTorrent::Util qw[:bencode :compact];
    use Net::BitTorrent::Torrent;
    use Net::BitTorrent::Peer;
    use Net::BitTorrent::DHT;
    use Net::BitTorrent::Version;
    use version qw[qv];
    our $VERSION_BASE = 50; our $UNSTABLE_RELEASE = 0; our $VERSION = sprintf(($UNSTABLE_RELEASE ? q[%.3f_%03d] : q[%.3f]), (version->new(($VERSION_BASE))->numify / 1000), $UNSTABLE_RELEASE);
    my (@CONTENTS) = \my (
        %_tcp,                  %_udp,
        %_schedule,             %_tid,
        %_event,                %torrents,
        %_connections,          %peerid,
        %_max_ul_rate,          %_k_ul,
        %_max_dl_rate,          %_k_dl,
        %_dht,                  %_use_dht,
        %__UDP_OBJECT_CACHE,    %_peers_per_torrent,
        %_connections_per_host, %_half_open,
        #############################################################
        %_encryption_mode
    );
    my %REGISTRY;
    sub _MSE_DISABLED {0}
    sub _MSE_ENABLED  {1}
    sub _MSE_FORCED   {2}

    sub new {
        my ($class, $args) = @_;
        my $self = bless \$class, $class;
        my ($host, @ports) = (q[0.0.0.0], (0));

        # Defaults
        $_max_ul_rate{refaddr $self}          = 0;
        $_k_ul{refaddr $self}                 = 0;
        $_max_dl_rate{refaddr $self}          = 0;
        $_k_dl{refaddr $self}                 = 0;
        $_peers_per_torrent{refaddr $self}    = 100;
        $_half_open{refaddr $self}            = 8;
        $_connections_per_host{refaddr $self} = 1;
        $torrents{refaddr $self}              = {};
        $_tid{refaddr $self}                  = qq[\0] x 5;
        $_use_dht{refaddr $self}              = 1;
        $_encryption_mode{refaddr $self}      = _MSE_ENABLED;

        # Internals
        $_connections{refaddr $self} = {};
        $_schedule{refaddr $self}    = {};
        $_dht{refaddr $self}   = Net::BitTorrent::DHT->new({Client => $self});
        $peerid{refaddr $self} = Net::BitTorrent::Version::gen_peerid();
        if (defined $args) {
            if (ref($args) ne q[HASH]) {
                carp q[Net::BitTorrent->new({}) requires ]
                    . q[parameters to be passed as a hashref];
                return;
            }
            $host = $args->{q[LocalHost]}
                if defined $args->{q[LocalHost]};
            @ports
                = defined $args->{q[LocalPort]}
                ? (ref($args->{q[LocalPort]}) eq q[ARRAY]
                   ? @{$args->{q[LocalPort]}}
                   : $args->{q[LocalPort]}
                )
                : @ports;
        }

        # Try opening a matching set of ports
        for my $port (@ports) {
            last
                if $self->_socket_open_tcp($host, $port)
                    && $self->_socket_open_udp($host, $port);
        }

        # Clear everything just in case
        $self->_reset_bandwidth;
        weaken($REGISTRY{refaddr $self} = $self);
        $$self = $peerid{refaddr $self};
        return $self;
    }

    # Accessors | Private
    sub _tcp               { return $_tcp{refaddr +shift} }
    sub _udp               { return $_udp{refaddr +shift} }
    sub _connections       { return $_connections{refaddr +shift} }
    sub _max_ul_rate       { return $_max_ul_rate{refaddr +shift} }
    sub _max_dl_rate       { return $_max_dl_rate{refaddr +shift} }
    sub _peers_per_torrent { return $_peers_per_torrent{refaddr +shift} }
    sub _half_open         { return $_half_open{refaddr +shift} }

    sub _connections_per_host {
        return $_connections_per_host{refaddr +shift};
    }
    sub _dht { return $_dht{refaddr +shift} }

    sub _use_dht {
        my ($s) = @_;
        return $_udp{refaddr $s} && $_use_dht{refaddr $s};
    }

    sub _tcp_port {
        my ($self) = @_;
        return if not defined $_tcp{refaddr $self};
        my ($port, undef)
            = unpack_sockaddr_in(getsockname($_tcp{refaddr $self}));
        return $port;
    }

    sub _tcp_host {
        my ($self) = @_;
        return if not defined $_tcp{refaddr $self};
        my (undef, $packed_ip)
            = unpack_sockaddr_in(getsockname($_tcp{refaddr $self}));
        return inet_ntoa($packed_ip);
    }

    sub _udp_port {
        my ($self) = @_;
        return if not defined $_udp{refaddr $self};
        my ($port, undef)
            = unpack_sockaddr_in(getsockname($_udp{refaddr $self}));
        return $port;
    }

    sub _udp_host {
        my ($self) = @_;
        return if not defined $_udp{refaddr $self};
        my (undef, $packed_ip)
            = unpack_sockaddr_in(getsockname($_udp{refaddr $self}));
        return inet_ntoa($packed_ip);
    }

    sub _encryption_mode {
        my ($self) = @_;
        return $_encryption_mode{refaddr $self};
    }

    # Setters | Private
    sub _set_encryption_mode {
        my ($self, $value) = @_;
        if (not defined $value
            or (    ($value != _MSE_DISABLED)
                and ($value != _MSE_ENABLED)
                and ($value != _MSE_FORCED))
            )
        {   carp
                q[Net::BitTorrent->_set_encryption_mode( VALUE ) requires an integer value];
            return;
        }
        return $_encryption_mode{refaddr $self} = $value;
    }

    sub _set_max_ul_rate {    # BYTES per second
        my ($self, $value) = @_;
        if (not defined $value or $value !~ m[^\d+$] or !$value) {
            carp
                q[Net::BitTorrent->_set_max_ul_rate( VALUE ) requires an integer value];
            return;
        }
        return $_max_ul_rate{refaddr $self} = $value;
    }

    sub _set_max_dl_rate {    # BYTES per second
        my ($self, $value) = @_;
        if (not defined $value or $value !~ m[^\d+$]) {
            carp
                q[Net::BitTorrent->_set_max_dl_rate( VALUE ) requires an integer value];
            return;
        }
        return $_max_dl_rate{refaddr $self} = $value;
    }

    sub _set_peers_per_torrent {
        my ($self, $value) = @_;
        if (not defined $value or $value !~ m[^\d+$] or $value < 1) {
            carp
                q[Net::BitTorrent->_set_peers_per_torrent( VALUE ) requires an integer value];
            return;
        }
        return $_peers_per_torrent{refaddr $self} = $value;
    }

    sub _set_half_open {
        my ($self, $value) = @_;
        if (not defined $value or $value !~ m[^\d+$] or $value < 1) {
            carp
                q[Net::BitTorrent->_set_half_open( VALUE ) requires an integer value];
            return;
        }
        return $_half_open{refaddr $self} = $value;
    }

    sub _set_connections_per_host {
        my ($self, $value) = @_;
        if (not defined $value or $value !~ m[^\d+$] or $value < 1) {
            carp
                q[Net::BitTorrent->_set_connections_per_host( VALUE ) requires an integer value];
            return;
        }
        return $_connections_per_host{refaddr $self} = $value;
    }

    sub _set_use_dht {
        my ($self, $value) = @_;
        if (not defined $value or $value !~ m[^[10]$]) {
            carp
                q[Net::BitTorrent->_set_use_dht( VALUE ) requires a bool value];
            return;
        }
        return $_use_dht{refaddr $self} = $value;
    }

    # Accessors | Public
    sub peerid   { my ($self) = @_; return $peerid{refaddr $self} }
    sub torrents { my ($self) = @_; return $torrents{refaddr $self} }

    # Methods | Public
    sub do_one_loop {
        my ($self, $timeout) = @_;
        $self->_process_schedule;
        $timeout
            = defined $timeout && $timeout =~ m[^(\-1|\d+)\.?\d*$]
            ? $timeout < 0
                ? undef
                : $timeout
            : 1;
        my ($rin, $win, $ein) = (q[], q[], q[]);
    PUSHSOCK: for my $fileno (keys %{$_connections{refaddr $self}}) {
            vec($rin, $fileno, 1) = 1
                if $_connections{refaddr $self}{$fileno}{q[Mode]} =~ m[r];
            vec($win, $fileno, 1) = 1
                if $_connections{refaddr $self}{$fileno}{q[Mode]} =~ m[w];
            vec($ein, $fileno, 1) = 1;
        }
        my ($nfound, $timeleft) = select($rin, $win, $ein, $timeout);
        $self->_process_connections(\$rin, \$win, \$ein)
            if $nfound and $nfound != -1;
        return 1;
    }

    # Methods | Private
    sub _reset_bandwidth {
        my ($self) = @_;
        $self->_schedule({Time   => time + 1,
                          Code   => \&_reset_bandwidth,
                          Object => $self
                         }
        );

        #warn sprintf q[Speed report: Up: %5dB/s | Down: %5dB/s],
        #    $_k_ul{refaddr $_[0]},
        #    $_k_dl{refaddr $_[0]};
        return $_k_dl{refaddr $_[0]} = $_k_ul{refaddr $_[0]} = 0;
    }

    sub _add_connection {
        my ($self, $connection, $mode) = @_;
        if (not defined $connection) {
            carp q[Net::BitTorrent->_add_connection() requires an object];
            return;
        }
        if (not blessed $connection) {
            carp
                q[Net::BitTorrent->_add_connection() requires a blessed object];
            return;
        }
        my $_sock = $connection->_socket;
        if ((not $_sock) or (ref($_sock) ne q[GLOB])) { return; }
        if ((!$mode) || ($mode !~ m[^(?:ro|rw|wo)$])) {
            carp
                q[Net::BitTorrent->_add_connection(SOCKET, MODE) requires a mode parameter];
            return;
        }
        return $_connections{refaddr $self}{fileno $_sock} = {
                                                        Object => $connection,
                                                        Mode   => $mode
        };
    }

    sub _remove_connection {
        my ($self, $connection) = @_;
        if (not defined $connection) {
            carp q[Net::BitTorrent->_remove_connection() requires an object];
            return;
        }
        if (not blessed $connection) {
            carp
                q[Net::BitTorrent->_remove_connection() requires a blessed object];
            return;
        }
        my $socket = $connection->_socket;
        return if not defined $socket;
        return delete $_connections{refaddr $self}{fileno $socket};
    }

    sub _socket_open_tcp {
        my ($self, $host, $port) = @_;
        if (   not $self
            || not blessed $self
            || not $self->isa(q[Net::BitTorrent]))
        {   carp
                q[Net::BitTorrent->_socket_open_tcp(HOST, PORT) requires a blessed object];
            return;
        }
        if ((!$_tcp{refaddr $self}) && (!$host)) {
            carp q[Net::BitTorrent::_socket_open_tcp( ) ]
                . q[requires a hostname];
            return;
        }
        if (defined $port and $port !~ m[^\d+$]) {
            carp q[Net::BitTorrent::_socket_open_tcp( ) ]
                . q[requires an integer port number];
            return;
        }
        my $_packed_host = undef;
        $host ||= q[0.0.0.0];
        $port ||= 0;
        $port =~ m[^(\d+)$];
        $port = $1;
        if (    $host
            and $host
            !~ m[^(?:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.]?){4})$])
        {   my ($name, $aliases, $addrtype, $length, @addrs)
                = gethostbyname($host)
                or return;
            $_packed_host = $addrs[0];
        }
        else { $_packed_host = inet_aton($host) }
        socket(my ($_tcp), PF_INET, SOCK_STREAM, getprotobyname(q[tcp]))
            or return;

       # - What is the difference between SO_REUSEADDR and SO_REUSEPORT?
       #    [http://www.unixguide.net/network/socketfaq/4.11.shtml]
       # - setsockopt - what are the options for ActivePerl under Windows NT?
       #    [http://perlmonks.org/?node_id=63280]
       #      setsockopt($_tcp, SOL_SOCKET, SO_REUSEADDR, pack(q[l], 1))
       #         or return;
       # SO_REUSEPORT is undefined on Win32... Boo...
       #if ($reuse_port and defined SO_REUSEPORT) {       # XXX - undocumented
       #   setsockopt($_udp, SOL_SOCKET, SO_REUSEPORT, pack(q[l], 1))
       #       or return;
       #}
        bind($_tcp, pack_sockaddr_in($port, $_packed_host))
            or return;
        listen($_tcp, 1) or return;
        $_connections{refaddr $self}{fileno $_tcp} = {Object => $self,
                                                      Mode   => q[ro],
            }
            or return;
        if (   defined $_tcp{refaddr $self}
            && fileno $_tcp{refaddr $self}
            && defined $_connections{refaddr $self}
            {fileno $_tcp{refaddr $self}})
        {   delete $_connections{refaddr $self}{fileno $_tcp{refaddr $self}};
            close $_tcp{refaddr $self};
        }
        return $_tcp{refaddr $self} = $_tcp;
    }

    sub _socket_open_udp {
        my ($self, $host, $port) = @_;
        if (   not $self
            || not blessed $self
            || not $self->isa(q[Net::BitTorrent]))
        {   carp
                q[Net::BitTorrent->_socket_open_udp(HOST, PORT) requires a blessed object];
            return;
        }
        if ((!$_tcp{refaddr $self}) && (!$host)) {
            carp q[Net::BitTorrent::_socket_open_udp( ) ]
                . q[requires a hostname];
            return;
        }
        if (defined $port and $port !~ m[^\d+$]) {
            carp q[Net::BitTorrent::_socket_open_udp( ) ]
                . q[requires an integer port number];
            return;
        }
        my $_packed_host = undef;
        $host ||= q[0.0.0.0];

        #$port = $port ? $port : $_udp{refaddr $self} ? $self->_udp_port : 0;
        $port ||= 0;
        $port =~ m[^(\d+)$];
        $port = $1;
        if (    $host
            and $host
            !~ m[^(?:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.]?){4})$])
        {   my ($name, $aliases, $addrtype, $length, @addrs)
                = gethostbyname($host)
                or return;
            $_packed_host = $addrs[0];
        }
        else { $_packed_host = inet_aton($host) }
        socket(my ($_udp), PF_INET, SOCK_DGRAM, getprotobyname(q[udp]))
            or return;

       # - What is the difference between SO_REUSEADDR and SO_REUSEPORT?
       #    [http://www.unixguide.net/network/socketfaq/4.11.shtml]
       # - setsockopt - what are the options for ActivePerl under Windows NT?
       #    [http://perlmonks.org/?node_id=63280]
       #     setsockopt($_udp, SOL_SOCKET, SO_REUSEADDR, pack(q[l], 1))
       #        or return;
       # SO_REUSEPORT is undefined on Win32... Boo...
       #if ($reuse_port and defined SO_REUSEPORT) {       # XXX - undocumented
       #   setsockopt($_udp, SOL_SOCKET, SO_REUSEPORT, pack(q[l], 1))
       #       or return;
       #}
        bind($_udp, pack_sockaddr_in($port, $_packed_host))
            or return;
        $_connections{refaddr $self}{fileno $_udp} = {Object => $self,
                                                      Mode   => q[ro],
            }
            or return;
        if (   $_udp{refaddr $self}
            && fileno $_udp{refaddr $self}
            && defined $_connections{refaddr $self}
            {fileno $_udp{refaddr $self}})
        {   delete $_connections{refaddr $self}{fileno $_udp{refaddr $self}};
            close $_udp{refaddr $self};
        }
        return $_udp{refaddr $self} = $_udp;
    }

    sub _process_connections {
        my ($self, $rin, $win, $ein) = @_;
        if (!(     ($rin and ref $rin and ref $rin eq q[SCALAR])
               and ($win and ref $win and ref $win eq q[SCALAR])
               and ($ein and ref $ein and ref $ein eq q[SCALAR])
            )
            )
        {   carp
                q[Malformed parameters to Net::BitTorrent::_process_connections(RIN, WIN, EIN)];
            return;
        }
    POPSOCK: foreach my $fileno (keys %{$_connections{refaddr $self}}) {
            next POPSOCK unless defined $_connections{refaddr $self}{$fileno};
            if (   $_tcp{refaddr $self}
                && $fileno == fileno $_tcp{refaddr $self})
            {   if (vec($$rin, $fileno, 1) == 1) {
                    vec($$rin, $fileno, 1) = 0;
                    if (scalar(
                            grep {
                                $_->{q[Object]}->isa(q[Net::BitTorrent::Peer])
                                    && !$_->{q[Object]}->torrent
                                } values %{$_connections{refaddr $self}}
                        ) < $_half_open{refaddr $self}
                        )
                    {   accept(my ($new_socket), $_tcp{refaddr $self})
                            or next POPSOCK;
                        Net::BitTorrent::Peer->new({Socket => $new_socket,
                                                    Client => $self
                                                   }
                        );
                    }
                }
            }
            elsif (   $_udp{refaddr $self}
                   && $fileno == fileno $_udp{refaddr $self})
            {   if (vec($$rin, $fileno, 1) == 1) {
                    vec($$rin, $fileno, 1) = 0;
                    my $paddr
                        = recv($_udp{refaddr $self}, my ($data), 1024, 0)
                        or next POPSOCK;
                    if ($__UDP_OBJECT_CACHE{refaddr $self}{$paddr}{q[Object]})
                    {   $__UDP_OBJECT_CACHE{refaddr $self}{$paddr}{q[Object]}
                            ->_on_data($paddr, $data)
                            or
                            delete $__UDP_OBJECT_CACHE{refaddr $self}{$paddr}
                            {q[Object]};
                        next POPSOCK;
                    }
                    else {
                        for my $_tor (values %{$torrents{refaddr $self}}) {
                            for my $_tier (@{$_tor->trackers}) {
                                my ($tracker) = grep {
                                    $_->isa(
                                        q[Net::BitTorrent::Torrent::Tracker::UDP]
                                        )
                                        and $_->_packed_host eq $paddr
                                } @{$_tier->urls};
                                if (   $tracker
                                    && $tracker->_on_data($paddr, $data))
                                {   $__UDP_OBJECT_CACHE{refaddr $self}{$paddr}
                                        = {Object => $tracker};
                                    weaken($__UDP_OBJECT_CACHE{refaddr $self}
                                           {$paddr}{q[Object]});
                                    next POPSOCK;
                                }
                            }
                        }
                    }
                    if (   $_use_dht{refaddr $self}
                        && $_dht{refaddr $self}->_on_data($paddr, $data))
                    {   $__UDP_OBJECT_CACHE{refaddr $self}{$paddr}
                            = {Object => $_dht{refaddr $self}};
                        weaken($__UDP_OBJECT_CACHE{refaddr $self}{$paddr}
                               {q[Object]});
                    }
                    next POPSOCK;
                }
            }
            else {
                my $read = (($_max_dl_rate{refaddr $self}
                             ? max(0,
                                   (      $_max_dl_rate{refaddr $self}
                                        - $_k_dl{refaddr $self}
                                   )
                                 )
                             : (2**15)
                            ) * vec($$rin, $fileno, 1)
                );
                my $write = (($_max_ul_rate{refaddr $self}
                              ? max(0,
                                    (      $_max_ul_rate{refaddr $self}
                                         - $_k_ul{refaddr $self}
                                    )
                                  )
                              : (2**15)
                             ) * vec($$win, $fileno, 1)
                );
                my $error = vec($$ein, $fileno, 1)
                    && (   $^E
                        && ($^E != _EINPROGRESS)
                        && ($^E != _EWOULDBLOCK));
                if ($read || $write || $error) {
                    my ($this_r, $this_w)
                        = $_connections{refaddr $self}{$fileno}{q[Object]}
                        ->_rw($read, $write, $error);
                    $_k_dl{refaddr $self} += defined $this_r ? $this_r : 0;
                    $_k_ul{refaddr $self} += defined $this_w ? $this_w : 0;
                    vec($$rin, $fileno, 1) = 0;
                    vec($$win, $fileno, 1) = 0;
                    vec($$ein, $fileno, 1) = 0;
                }
            }
        }
        return 1;
    }

    # Methods | Private | Torrents
    sub _locate_torrent {
        my ($self, $infohash) = @_;
        carp q[Bad infohash for Net::BitTorrent->_locate_torrent(INFOHASH)]
            && return
            if $infohash !~ m[^[\d|a-f]{40}$]i;
        return $torrents{refaddr $self}{lc $infohash}
            ? $torrents{refaddr $self}{lc $infohash}
            : undef;
    }

    # Methods | Public | Torrents
    sub add_torrent {
        my ($self, $args) = @_;
        if (ref($args) ne q[HASH]) {
            carp
                q[Net::BitTorrent->add_torrent() requires params passed as a hash ref];
            return;
        }
        $args->{q[Client]} = $self;
        my $torrent = Net::BitTorrent::Torrent->new($args);
        return if not defined $torrent;
        return if $self->_locate_torrent($torrent->infohash);
        return $torrents{refaddr $self}{$torrent->infohash} = $torrent;
    }

    sub remove_torrent {
        my ($self, $torrent) = @_;
        if (   not blessed($torrent)
            or not $torrent->isa(q[Net::BitTorrent::Torrent]))
        {   carp
                q[Net::BitTorrent->remove_torrent(TORRENT) requires a blessed Net::BitTorrent::Torrent object];
            return;
        }
        for my $_peer ($torrent->peers) {
            $_peer->_disconnect(
                              q[Removing .torrent torrent from local client]);
        }
        $torrent->stop;    # XXX - Should this be here?
        return delete $torrents{refaddr $self}{$torrent->infohash};
    }

    # Methods | Public | Callback system
    sub on_event {
        my ($self, $type, $method) = @_;
        carp sprintf q[Unknown callback: %s], $type
            unless ___check_event($type);
        $_event{refaddr $self}{$type} = $method;
    }

    # Methods | Private | Callback system
    sub _event {
        my ($self, $type, $args) = @_;
        carp sprintf
            q[Unknown event: %s. This is a bug in Net::BitTorrent; Report it.],
            $type
            unless ___check_event($type);
        return $_event{refaddr $self}{$type}
            ? $_event{refaddr $self}{$type}($self, $args)
            : ();
    }

    # Functions | Private | Callback system
    sub ___check_event {
        my $type = shift;
        return scalar grep { $_ eq $type } qw[
            ip_filter
            incoming_packet outgoing_packet
            peer_connect    peer_disconnect
            peer_read       peer_write
            tracker_connect tracker_disconnect
            tracker_read    tracker_write
            tracker_success tracker_failure
            piece_hash_pass piece_hash_fail
            file_open       file_close
            file_read       file_write
            file_error
        ];
    }

    # Methods | Private | Internal event scheduler
    sub _schedule {
        my ($self, $args) = @_;
        if ((!$args) || (ref $args ne q[HASH])) {
            carp
                q[Net::BitTorrent->_schedule() requires params to be passed as a HashRef];
            return;
        }
        if ((!$args->{q[Object]}) || (!blessed $args->{q[Object]})) {
            carp
                q[Net::BitTorrent->_schedule() requires a blessed 'Object' parameter];
            return;
        }
        if ((!$args->{q[Time]}) || ($args->{q[Time]} !~ m[^\d+(?:\.\d+)?$])) {
            carp
                q[Net::BitTorrent->_schedule() requires an integer or float 'Time' parameter];
            return;
        }
        if ((!$args->{q[Code]}) || (ref $args->{q[Code]} ne q[CODE])) {
            carp q[Net::BitTorrent->_schedule() requires a 'Code' parameter];
            return;
        }
        my $tid = $self->_generate_token_id();
        $_schedule{refaddr $self}{$tid} = {Timestamp => $args->{q[Time]},
                                           Code      => $args->{q[Code]},
                                           Object    => $args->{q[Object]}
        };
        weaken $_schedule{refaddr $self}{$tid}{q[Object]};
        return $tid;
    }

    sub _cancel {
        my ($self, $tid) = @_;
        if (!$tid) {
            carp q[Net::BitTorrent->_cancel( TID ) requires an ID];
            return;
        }
        if (!$_schedule{refaddr $self}{$tid}) {
            carp sprintf
                q[Net::BitTorrent->_cancel( TID ) cannot find an event with TID == %s],
                $tid;
            return;
        }
        return delete $_schedule{refaddr $self}{$tid};
    }

    sub _process_schedule {
        my ($self) = @_;
        for my $job (keys %{$_schedule{refaddr $self}}) {
            if ($_schedule{refaddr $self}{$job}->{q[Timestamp]} <= time) {
                &{$_schedule{refaddr $self}{$job}->{q[Code]}}(
                                 $_schedule{refaddr $self}{$job}->{q[Object]})
                    if defined $_schedule{refaddr $self}{$job}->{q[Object]};
                delete $_schedule{refaddr $self}{$job};
            }
        }
        return 1;
    }

    # Methods | Private | Various
    sub _generate_token_id {
        return if defined $_[1];
        my ($self) = @_;
        $_tid{refaddr $self} ||= qq[\0] x 4;
        my ($len) = ($_tid{refaddr $self} =~ m[^([a-z]+)]);
        $_tid{refaddr $self} = (
                   ($_tid{refaddr $self} =~ m[^z*(\0*)$])
                   ? ($_tid{refaddr $self} =~ m[\0]
                      ? pack(q[a] . (length $_tid{refaddr $self}),
                             (q[a] x (length($len || q[]) + 1))
                          )
                      : (q[a] . (qq[\0] x (length($_tid{refaddr $self}) - 1)))
                       )
                   : ++$_tid{refaddr $self}
        );
        return $_tid{refaddr $self};
    }

    sub _build_reserved {
        my ($self) = @_;
        my @reserved = qw[0 0 0 0 0 0 0 0];
        $reserved[5] |= 0x10;    # Ext Protocol
        $reserved[7] |= 0x04;    # Fast Ext
        return join q[], map {chr} @reserved;
    }

    sub as_string {
        my ($self, $advanced) = @_;
        my $dump
            = !$advanced ? $peerid{refaddr $self} : sprintf <<'END',
Net::BitTorrent

Peer ID: %s
DHT is %sabled (Node ID: %s)
TCP Address: %s:%d
UDP Address: %s:%d
----------
Torrents in queue: %d
%s
----------
END
            $peerid{refaddr $self},
            $_use_dht{refaddr $self} ? q[En] : q[Dis],
            unpack(q[H*], $_dht{refaddr $self}->node_id),
            $self->_tcp_host, $self->_tcp_port, $self->_udp_host,
            $self->_udp_port, (scalar keys %{$torrents{refaddr $self}}), join(
            qq[\r\n],
            map {
                sprintf q[%40s (%d: %s)], $_->infohash, $_->status,
                    $_->_status_as_string()
                } values %{$torrents{refaddr $self}}
            );
        return defined wantarray ? $dump : print STDERR qq[$dump\n];
    }

    sub CLONE {
        for my $_oID (keys %REGISTRY) {
            my $_obj = $REGISTRY{$_oID};
            my $_nID = refaddr $_obj;
            for (@CONTENTS) {
                $_->{$_nID} = $_->{$_oID};
                delete $_->{$_oID};
            }
            delete $_schedule{$_nID};
            weaken($REGISTRY{$_nID} = $_obj);
            delete $REGISTRY{$_oID};
        }
        return 1;
    }
    DESTROY {
        my ($self) = @_;
        close($_tcp{refaddr $self}) if $_tcp{refaddr $self};
        close($_udp{refaddr $self}) if $_udp{refaddr $self};
        foreach my $conn (values %{$_connections{refaddr $self}}) {
            close($conn->{q[Object]}->_socket) if $conn->{q[Object]};
        }
        for (@CONTENTS) { delete $_->{refaddr $self}; }
        return delete $REGISTRY{refaddr $self};
    }
    1;
}

=pod

=head1 NAME

Net::BitTorrent - BitTorrent peer-to-peer protocol class

=head1 Synopsis

  use Net::BitTorrent;

  my $client = Net::BitTorrent->new();

  $client->on_event(
      q[piece_hash_pass],
      sub {
          my ($self, $args) = @_;
          printf(qq[pass: piece number %04d of %s\n],
                 $args->{q[Index]}, $args->{q[Torrent]}->infohash);
      }
  );

  my $torrent = $client->add_torrent({Path => q[a.legal.torrent]})
      or die q[Cannot load .torrent];

  $torrent->hashcheck;  # Verify any existing data

  $client->do_one_loop() while 1;

=head1 Description

L<Net::BitTorrent|Net::BitTorrent> is a class based implementation of the
BitTorrent Protocol for distributed data exchange.

=head1 Constructor

=over 4

=item C<new ( { [ARGS] } )>

Creates a L<Net::BitTorrent|Net::BitTorrent> object.  This constructor
expects arguments as a hashref, using key-value pairs, all of which are
optional.  The most common are:

=over 4

=item C<LocalHost>

Local host bind address.  The value must be an IPv4 ("dotted quad") IP-
address of the C<xxx.xxx.xxx.xxx> form.

Default: C<0.0.0.0> (any address)

=item C<LocalPort>

TCP and UDP port opened to remote peers for incoming connections.  If
handed a list of ports (ex. C<{ LocalPort =E<gt> [6952, 6881..6889] }>),
L<Net::BitTorrent|Net::BitTorrent> will traverse the list, attempting to
open on each of the ports until we succeed or run out of ports.

Default: C<0> (any available, chosen by the OS)

=back

=back

=head1 Methods

Unless stated, all methods return either a C<true> or C<false> value,
with C<true> meaning that the operation was a success.  When a method
states that it returns some other specific value, failure will result in
C<undef> or an empty list.

=over 4

=item C<add_torrent ( { ... } )>

Loads a .torrent file and adds the
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent> object to the
client's queue.

Aside from the C<Client> parameter (which is filled in automatically),
this method hands everything off to
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent>'s constructor, so
see L<Net::BitTorrent::Torrent::new( )|Net::BitTorrent::Torrent/"new ( { [ARGS] } )">
for a list of expected parameters.

This method returns the new
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent> object on success.

See also: L<torrents ( )|/"torrents ( )">,
L<remove_torrent ( )|/"remove_torrent ( TORRENT )">,
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent>

=item C<do_one_loop ( [TIMEOUT] )>

Processes the internal schedule and handles activity of the various
socket-containing objects (L<peers|Net::BitTorrent::Peer>,
L<trackers|Net::BitTorrent::Torrent::Tracker>,
L<DHT|Net::BitTorrent::DHT>).  This method should be called frequently
to be of any use at all.

The optional TIMEOUT parameter is the maximum amount of time, in seconds,
possibly fractional, C<select()> is allowed to wait before returning.
This TIMEOUT defaults to C<1.0> (one second).  To wait indefinitely,
TIMEOUT should be C<-1.0> (C<...-E<gt>do_one_loop(-1)>).

=item C<on_event ( TYPE, CODEREF )>

Net::BitTorrent provides a convenient callback system.  To set a callback,
use the C<on_event( )> method.  For example, to catch all attempts to read
from a file, use C<$client-E<gt>on_event( 'file_read', \&on_read )>.

See the L<Events|/Events> section for a list of events sorted by their
related classes.

=item C<peerid ( )>

Returns the L<Peer ID|Net::BitTorrent::Version/"gen_peerid ( )">
generated to identify this L<Net::BitTorrent|Net::BitTorrent> object
internally, with remote L<peers|Net::BitTorrent::Peer>, and
L<trackers|Net::BitTorrent::Torrent::Tracker>.

See also: wiki.theory.org (http://tinyurl.com/4a9cuv),
L<Peer ID Specification|Net::BitTorrent::Version/"Peer ID Specification">

=item C<remove_torrent ( TORRENT )>

Removes a L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent> object
from the client's queue.

=begin future

Before the torrent torrent is closed, we announce to the tracker that we
have 'stopped' downloading and a callback to store the current state is
called.

=end future

See also: L<torrents ( )|/"torrents ( )">,
L<add_torrent ( )|/"add_torrent ( { ... } )">,
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent>

=item C<torrents ( )>

Returns the list of queued L<torrents|Net::BitTorrent::Torrent>.

See also: L<add_torrent ( )|/"add_torrent ( { ... } )">,
L<remove_torrent ( )|/"remove_torrent ( TORRENT )">

=back

=head1 Events

When triggered, client-wide callbacks receive two arguments: the
C<Net::BitTorrent> object and a hashref containing pertinent information.
For per-torrent callbacks, please see
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent/"Events">

This is the current list of events and the information passed to
callbacks.

Note: This list is subject to change.  Unless mentioned specifically,
return values from callbacks do not affect behavior.

=head2 Net::BitTorrent::Peer

=over

=item C<ip_filter>

This gives a client author a chance to block or accept connections with
a peer before an initial handshake is sent.  The argument hash contains
the following key:

=over

=item C<Address>

IPv4:port (or, on rare occasions, hostname:port) address of the potential peer.

=back

Note: The return value from your C<ip_filter> callback determines how we
proceed.  An I<explicitly false> return value (ie C<0>) means this peer
should not be contacted and (in the case of an incoming peer) the
connection is dropped.

=item C<peer_connect>

Triggered when we have both sent and received a valid handshake with
the remote peer.  The argument hash contains the following keys:

=over

=item C<Peer>

The remote L<peer|Net::BitTorrent::Peer> with whom we have established
a connection.

=back

=item C<peer_disconnect>

Triggered when a connection with a remote peer is lost or terminated.
The argument hash contains the following keys:

=over

=item C<Peer>

The remote L<peer|Net::BitTorrent::Peer> with whom we have established
a connection.

=item C<Reason>

When possible, this is a 'user friendly' string.

=back

=item C<peer_read>

This is triggered whenever we receive data from a remote peer via TCP.
The argument hash contains the following keys:

=over

=item C<Peer>

The L<peer|Net::BitTorrent::Peer> who sent the packet.

=item C<Length>

The amount of data, in bytes, sent by the peer.

=back

=item C<peer_write>

This is triggered whenever we send data to a remote peer via TCP.  The
argument hash contains the following keys:

=over

=item C<Peer>

The L<peer|Net::BitTorrent::Peer> on the receiving end of this data.

=item C<Length>

The amount of data, in bytes, sent to the remote peer.

=back

=item C<outgoing_packet>

Triggered when we send a packet to a remote peer.  The argument hash
contains the following keys:

=over

=item C<Payload>

The parsed data sent in the packet (when applicable) in a hashref.

=item C<Peer>

The remote L<peer|Net::BitTorrent::Peer> receiving this data.

=item C<Type>

The type of packet sent.  These values match the packet types exported
from L<Net::BitTorrent::Protocol|Net::BitTorrent::Protocol/":types">.

=back

=item C<incoming_packet>

Triggered when we receive a packet to a remote peer.  The argument hash
contains the following keys:

=over

=item C<Payload>

The parsed data sent in the packet (when applicable) in a hashref.

=item C<Peer>

The remote L<peer|Net::BitTorrent::Peer> sending this data.

=item C<Type>

The type of packet sent.  These values match the packet types exported
from L<Net::BitTorrent::Protocol|Net::BitTorrent::Protocol/":types">.

=back

=back

=head2 Net::BitTorrent::Torrent::File

=over

=item C<file_error>

Triggered when we run into an error handling the file in some way. The
argument hash contains the following keys:

=over

=item C<File>

The L<file|Net::BitTorrent::Torrent::File> object related to this fault.

=item C<Message>

The error message describing what (may have) gone wrong.

=back

=item C<file_open>

Triggered every time we open a file represented in a
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent> object. The argument
hash contains the following keys:

=over

=item C<File>

The L<file|Net::BitTorrent::Torrent::File> object.

=item C<Mode>

How the file is opened.  To simplify things, C<Net::BitTorrent> currently
uses 'r' for read access and 'w' for write.

=back

=item C<file_close>

Triggered every time we close a file.  The argument hash contains the
following key:

=over

=item C<File>

The L<file|Net::BitTorrent::Torrent::File> object.

=back

=item C<file_write>

Triggered every time we write data to a file.  The argument hash contains
the following keys:

=over

=item C<File>

The L<file|Net::BitTorrent::Torrent::File> object.

=item C<Length>

The actual amount of data written to the file.

=back

=item C<file_read>

Triggered every time we read data from a file.  The argument hash
contains the following keys:

=over

=item C<File>

The L<file|Net::BitTorrent::Torrent::File> object related to this fault.

=item C<Length>

The actual amount of data written to the file.

=back

=back

=head2 Net::BitTorrent::Torrent::Tracker::HTTP/Net::BitTorrent::Torrent::Tracker::UDP

Note: The tracker objects passed to these callbacks will either be a
L<Net::BitTorrent::Torrent::Tracker::HTTP|Net::BitTorrent::Torrent::Tracker::HTTP>
or a
L<Net::BitTorrent::Torrent::Tracker::UDP|Net::BitTorrent::Torrent::Tracker::UDP>.

=over

=item C<tracker_connect>

Triggered when we connect to a remote tracker.  The argument hash
contains the following keys:

=over

=item C<Tracker>

The tracker object related to this event.

=item C<Event>

If defined, this describes why we are contacting the tracker.  See the
BitTorrent specification for more.

=back

Note: This callback is only triggered from
L<TCP|Net::BitTorrent::Torrent::Tracker::HTTP> trackers, as
L<UDP|Net::BitTorrent::Torrent::Tracker::UDP> is 'connection-less.'

=item C<tracker_disconnect>

Triggered when we disconnect from a remote tracker.  The argument hash
contains the following key:

=over

=item C<Tracker>

The tracker object related to this event.

=back

Note: This callback is only triggered from
L<TCP|Net::BitTorrent::Torrent::Tracker::HTTP> trackers, as
L<UDP|Net::BitTorrent::Torrent::Tracker::UDP> is 'connection-less.'

=item C<tracker_success>

Triggered when an announce attempt succeeds.  The argument hash contains
the following keys:

=over

=item C<Tracker>

The tracker object related to this event.

=item C<Payload>

The data returned by the tracker in a hashref.  The content of this
payload based on what we receive from the tracker but these are the
typical keys found therein:

=over

=item C<complete>

The number of seeds in the swarm according to the tracker.

=item C<incomplete>

The number of leeches in the swarm according to the tracker.

=item C<peers>

A L<compact|Net::BitTorrent::Util/"compact ( LIST )"> list of peers in the swarm.

=item C<min_interval>

The minimum amount of time before we should contact the tracker again.

=back

=back

=item C<tracker_failure>

Triggered when an announce attempt fails.  The argument hash contains the
following keys:

=over

=item C<Tracker>

The tracker object related to this event.

=item C<Reason>

The reason given by the remote tracker (when applicable) or as defined
by C<Net::BitTorrent> on socket errors.

=back

=item C<tracker_write>

Triggered when we write data to a remote tracker.  The argument hash
contains the following keys:

=over

=item C<Tracker>

The tracker object related to this event.

=item C<Length>

The amount of data sent to the remote tracker.

=back

=item C<tracker_read>

Triggered when data is read from a tracker.  The argument hash contains
the following keys:

=over

=item C<Tracker>

The tracker object related to this event.

=item C<Length>

The amount of data received from the remote tracker.

=back

=back

=head2 Net::BitTorrent::Torrent

=over

=item C<piece_hash_fail>

Triggered when a piece fails to validate.  The argument hash contains the
following keys:

=over

=item C<Torrent>

The L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent> object related to
this event.

=item C<Index>

The zero-based index of the piece that failed to match the hash defined
for it in the .torrent metadata.

=back

=item C<piece_hash_pass>

Triggered when a previously missing piece validates.  The argument hash
contains the following keys:

=over

=item C<Torrent>

The L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent> object related
to this event.

=item C<Index>

The zero-based index of the piece that was verified against the .torrent
metadata.

=back

=item C<as_string ( [ VERBOSE ] )>

Returns a 'ready to print' dump of the  object's data structure.  If
called in void context, the structure is printed to C<STDERR>.
C<VERBOSE> is a boolean value.

=back

=head1 Bugs

Numerous, I'm sure.

Please see the section entitled
"L<Bug Reporting|Net::BitTorrent::Notes/"Bug Reporting">" in
L<Net::BitTorrent::Notes|Net::BitTorrent::Notes> if you've found one.

=head1 Notes

=head2 Support Links

Please refer to
L<Net::BitTorrent::Notes|Net::BitTorrent::Notes/"Support and Information Links for C<Net::BitTorrent>">.

=head2 Dependencies

L<Net::BitTorrent|Net::BitTorrent> requires L<version|version> and
L<Digest::SHA|Digest::SHA> to function and relies upon
L<Module::Build|Module::Build> for installation.  As of perl 5.10, these
are all CORE modules; they come bundled with the distribution.

=head2 Examples

For a demonstration of L<Net::BitTorrent|Net::BitTorrent>, see
F<scripts/bittorrent.pl>.

=head2 Installation

See L<Net::BitTorrent::Notes|Net::BitTorrent::Notes/"Installation">.

=head1 See Also

http://bittorrent.org/beps/bep_0003.html - BitTorrent Protocol
Specification

L<Net::BitTorrent::Notes|Net::BitTorrent::Notes> - Random stuff.  More
jibba jabba.

L<Peer ID Specification|Net::BitTorrent::Notes/"Peer ID Specification"> -
The standard used to identify L<Net::BitTorrent|Net::BitTorrent> in the
wild.

=head1 Acknowledgments

Bram Cohen, for designing the base protocol and letting the community
decide what to do with it.

L Rotger

C<#bittorrent> on Freenode for letting me idle.

Michel Valdrighi for b2

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2009 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.  See the F<LICENSE>
file included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

Neither this module nor the L<Author|/Author> is affiliated with
BitTorrent, Inc.

=for svn $Id: BitTorrent.pm d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
