package POE::Component::Server::IRC::Backend;
BEGIN {
  $POE::Component::Server::IRC::Backend::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::Server::IRC::Backend::VERSION = '1.52';
}

use strict;
use warnings;
use Carp qw(croak);
use List::Util qw(first);
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Stackable
           Filter::Line Filter::IRCD);
use Net::Netmask;
use Socket qw(unpack_sockaddr_in inet_ntoa);
use base qw(POE::Component::Syndicator);

use constant {
    OBJECT_STATES_HASHREF => {
        syndicator_started => '_start',
        add_connector      => '_add_connector',
        add_listener       => '_add_listener',
        del_listener       => '_del_listener',
        send_output        => '_send_output',
        shutdown           => '_shutdown',
    },
    OBJECT_STATES_ARRAYREF => [qw(
        _accept_connection
        _accept_failed
        _conn_alarm
        _conn_input
        _conn_error
        _conn_flushed
        _event_dispatcher
        _sock_failed
        _sock_up
    )],
};

sub create {
    my $package = shift;
    croak("$package requires an even number of parameters") if @_ & 1;
    my %args = @_;
    $args{ lc $_ } = delete $args{$_} for keys %args;
    my $self = bless { }, $package;

    $self->{raw_events} = $args{raw_events} if defined $args{raw_events};
    $self->{prefix} = defined $args{prefix}
        ? $args{prefix}
        : 'ircd_';
    $self->{antiflood} = defined $args{antiflood}
        ? $args{antiflood}
        : 1;

    $self->{auth} = defined $args{auth}
        ? $args{auth}
        : 1;

    if ($args{sslify_options} && ref $args{sslify_options} eq 'ARRAY') {
        eval {
            require POE::Component::SSLify;
            POE::Component::SSLify->import(
                qw(SSLify_Options Server_SSLify Client_SSLify)
            );
        };
        chomp $@;
        croak("Can't use ssl: $@") if $@;

        eval { SSLify_Options(@{ $args{sslify_options} }); };
        chomp $@;
        croak("Can't use ssl: $@") if $@;
        $self->{got_ssl} = 1;
    }

    if ($args{states}) {
        my $error = $self->_validate_states($args{states});
        croak($error) if defined $error;
    }

    $self->_syndicator_init(
        prefix        => $self->{prefix},
        reg_prefix    => 'PCSI_',
        types         => [ SERVER => 'IRCD', USER => 'U' ],
        object_states => [
            $self => OBJECT_STATES_HASHREF,
            $self => OBJECT_STATES_ARRAYREF,
            ($args{states}
                ? map { $self => $_ } @{ $args{states} }
                : ()
            ),
        ],
        ($args{plugin_debug} ? (debug => 1) : () ),
        (ref $args{options} eq 'HASH' ? (options => $args{options}) : ()),
    );

    if ($self->{auth}) {
        require POE::Component::Server::IRC::Plugin::Auth;
        $self->plugin_add(
            'Auth_'.$self->session_id(),
            POE::Component::Server::IRC::Plugin::Auth->new(),
        );
    }

    return $self;
}

sub _validate_states {
    my ($self, $states) = @_;

    for my $events (@$states) {
        if (ref $events eq 'HASH') {
            for my $event (keys %$events) {
                if (OBJECT_STATES_HASHREF->{$event}
                    || first { $event eq $_ } @{ +OBJECT_STATES_ARRAYREF }) {
                    return "Event $event is reserved by ". __PACKAGE__;
                }
            }
        }
        elsif (ref $events eq 'ARRAY') {
            for my $event (@$events) {
                if (OBJECT_STATES_HASHREF->{$event}
                    || first { $event eq $_ } @{ +OBJECT_STATES_ARRAYREF }) {
                    return "Event $event is reserved by ". __PACKAGE__;
                }
            }
        }
    }

    return;
}

sub _start {
    my ($kernel, $self, $sender) = @_[KERNEL, OBJECT, SENDER];

    $self->{ircd_filter} = POE::Filter::IRCD->new(
        colonify => 1,
    );
    $self->{line_filter} = POE::Filter::Line->new(
        InputRegexp => '\015?\012',
        OutputLiteral => "\015\012",
    );
    $self->{filter} = POE::Filter::Stackable->new(
        Filters => [$self->{line_filter}, $self->{ircd_filter}],
    );

    return;
}

sub raw_events {
    my ($self, $value) = @_;
    $self->{raw_events} = 1 if $value;
    return;
}

sub shutdown {
    my ($self) = shift;
    $self->yield('shutdown', @_);
    return;
}

sub _shutdown {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    $self->{terminating} = 1;
    delete $self->{listeners};
    delete $self->{connectors};
    delete $self->{wheels};
    $self->_syndicator_destroy();
    return;
}

sub _accept_failed {
    my ($kernel, $self, $operation, $errnum, $errstr, $listener_id)
        = @_[KERNEL, OBJECT, ARG0..ARG3];

    my $port = $self->{listeners}{$listener_id}{port};
    my $addr = $self->{listeners}{$listener_id}{addr};
    delete $self->{listeners}{$listener_id};
    $self->send_event(
        "$self->{prefix}listener_failure",
        $listener_id,
        $operation,
        $errnum,
        $errstr,
        $port,
        $addr,
    );
    return;
}

sub _accept_connection {
    my ($kernel, $self, $socket, $peeraddr, $peerport, $listener_id)
        = @_[KERNEL, OBJECT, ARG0..ARG3];

    my $sockaddr = inet_ntoa((unpack_sockaddr_in(getsockname $socket))[1]);
    my $sockport = (unpack_sockaddr_in(getsockname $socket))[0];
    $peeraddr    = inet_ntoa($peeraddr);
    my $listener = $self->{listeners}{$listener_id};

    if ($self->{got_ssl} && $listener->{usessl}) {
        eval {
            $socket = POE::Component::SSLify::Server_SSLify($socket);
        };
        chomp $@;
        die "Failed to SSLify server socket: $@" if $@;
    }

    return if $self->denied($peeraddr);

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle       => $socket,
        Filter       => $self->{filter},
        InputEvent   => '_conn_input',
        ErrorEvent   => '_conn_error',
        FlushedEvent => '_conn_flushed',
    );

    if ($wheel) {
        my $wheel_id = $wheel->ID();
        my $ref = {
            wheel     => $wheel,
            peeraddr  => $peeraddr,
            peerport  => $peerport,
            flooded   => 0,
            sockaddr  => $sockaddr,
            sockport  => $sockport,
            idle      => time(),
            antiflood => $listener->{antiflood},
            compress  => 0
        };

        my $needs_auth = $listener->{auth} && $self->{auth} ? 1 : 0;
        $self->send_event(
            "$self->{prefix}connection",
            $wheel_id,
            $peeraddr,
            $peerport,
            $sockaddr,
            $sockport,
            $needs_auth,
        );

        $ref->{alarm} = $kernel->delay_set(
            '_conn_alarm',
            $listener->{idle},
            $wheel_id,
        );
        $self->{wheels}{$wheel_id} = $ref;
    }
    return;
}

sub add_listener {
    my ($self) = shift;
    croak('add_listener requires an even number of parameters') if @_ & 1;
    $self->yield('add_listener', @_);
    return;
}

sub _add_listener {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    my %args = @_[ARG0..$#_];

    $args{ lc($_) } = delete $args{$_} for keys %args;

    my $bindaddr  = $args{bindaddr} || '0.0.0.0';
    my $bindport  = $args{port} || 0;
    my $idle      = $args{idle} || 180;
    my $auth      = 1;
    my $antiflood = 1;
    my $usessl    = 0;
    $usessl    = 1 if $args{usessl};
    $auth      = 0 if defined $args{auth} && $args{auth} eq '0';
    $antiflood = 0 if defined $args{antiflood} && $args{antiflood} eq '0';

    my $listener = POE::Wheel::SocketFactory->new(
        BindAddress  => $bindaddr,
        BindPort     => $bindport,
        SuccessEvent => '_accept_connection',
        FailureEvent => '_accept_failed',
        Reuse        => 'on',
        ($args{listenqueue} ? (ListenQueue => $args{listenqueue}) : ()),
    );

    my $id = $listener->ID();
    $self->{listeners}{$id}{wheel}     = $listener;
    $self->{listeners}{$id}{port}      = $bindport;
    $self->{listeners}{$id}{addr}      = $bindaddr;
    $self->{listeners}{$id}{idle}      = $idle;
    $self->{listeners}{$id}{auth}      = $auth;
    $self->{listeners}{$id}{antiflood} = $antiflood;
    $self->{listeners}{$id}{usessl}    = $usessl;

    my ($port, $addr) = unpack_sockaddr_in($listener->getsockname);
    if ($port) {
        $self->{listeners}{$id}{port} = $port;
        $self->send_event(
            $self->{prefix} . 'listener_add',
            $port,
            $id,
            $bindaddr,
        );
    }
    return;
}

sub del_listener {
    my ($self) = shift;
    croak("add_listener requires an even number of parameters") if @_ & 1;
    $self->yield('del_listener', @_);
    return;
}

sub _del_listener {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    my %args = @_[ARG0..$#_];

    $args{lc $_} = delete $args{$_} for keys %args;
    my $listener_id = delete $args{listener};
    my $port = delete $args{port};

    if ($self->_listener_exists($listener_id)) {
        my $port = $self->{listeners}{$listener_id}{port};
        my $addr = $self->{listeners}{$listener_id}{addr};
        delete $self->{listeners}{$listener_id};
        $self->send_event(
            $self->{prefix} . 'listener_del',
            $port,
            $listener_id,
            $addr,
        );
    }
    elsif (defined $port) {
        while (my ($id, $listener) = each %{ $self->{listeners } }) {
            if ($listener->{port} == $port) {
                my $addr = $listener->{addr};
                delete $self->{listeners}{$id};
                $self->send_event(
                    $self->{prefix} . 'listener_del',
                    $port,
                    $listener_id,
                    $addr,
                );
            }
        }
    }

    return;
}

sub _listener_exists {
    my $self = shift;
    my $listener_id = shift || return;
    return 1 if defined $self->{listeners}{$listener_id};
    return;
}

sub add_connector {
    my $self = shift;
    croak("add_connector requires an even number of parameters") if @_ & 1;
    $self->yield('add_connector', @_);
    return;
}

sub _add_connector {
    my ($kernel, $self, $sender) = @_[KERNEL, OBJECT, SENDER];
    my %args = @_[ARG0..$#_];

    $args{lc $_} = delete $args{$_} for keys %args;

    my $remoteaddress = $args{remoteaddress};
    my $remoteport = $args{remoteport};

    return if !$remoteaddress || !$remoteport;

    my $wheel = POE::Wheel::SocketFactory->new(
        SocketProtocol => 'tcp',
        RemoteAddress  => $remoteaddress,
        RemotePort     => $remoteport,
        SuccessEvent   => '_sock_up',
        FailureEvent   => '_sock_failed',
        ($args{bindaddress} ? (BindAddress => $args{bindaddress}) : ()),
    );

    if ($wheel) {
        $args{wheel} = $wheel;
        $self->{connectors}{$wheel->ID()} = \%args;
    }
    return;
}

sub _sock_failed {
    my ($kernel, $self, $op, $errno, $errstr, $connector_id)
        = @_[KERNEL, OBJECT, ARG0..ARG3];

    my $ref = delete $self->{connectors}{$connector_id};
    delete $ref->{wheel};
    $self->send_event("$self->{prefix}socketerr", $ref, $op, $errno, $errstr);
    return;
}

sub _sock_up {
    my ($kernel, $self, $socket, $peeraddr, $peerport, $connector_id)
        = @_[KERNEL, OBJECT, ARG0..ARG3];
    $peeraddr = inet_ntoa($peeraddr);

    my $cntr = delete $self->{connectors}{$connector_id};
    if ($self->{got_ssl} && $cntr->{usessl}) {
        eval {
            $socket = POE::Component::SSLify::Client_SSLify($socket);
        };
        chomp $@;
        die "Failed to SSLify client socket: $@" if $@;
    }

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle       => $socket,
        InputEvent   => '_conn_input',
        ErrorEvent   => '_conn_error',
        FlushedEvent => '_conn_flushed',
        Filter       => POE::Filter::Stackable->new(
            Filters => [$self->{filter}],
        ),
    );

    return if !$wheel;
    my $wheel_id = $wheel->ID();
    my $sockaddr = inet_ntoa((unpack_sockaddr_in(getsockname $socket))[1]);
    my $sockport = (unpack_sockaddr_in(getsockname $socket))[0];
    my $ref = {
        wheel     => $wheel,
        peeraddr  => $peeraddr,
        peerport  => $peerport,
        sockaddr  => $sockaddr,
        sockport  => $sockport,
        idle      => time(),
        antiflood => 0,
        compress  => 0,
    };

    $self->{wheels}{$wheel_id} = $ref;
    $self->send_event(
        "$self->{prefix}connected",
        $wheel_id,
        $peeraddr,
        $peerport,
        $sockaddr,
        $sockport,
        $cntr->{name}
    );
    return;
}

sub _anti_flood {
    my ($self, $wheel_id, $input) = @_;
    my $current_time = time();

    return if !$wheel_id || !$self->connection_exists($wheel_id) || !$input;

    SWITCH: {
        if ($self->{wheels}->{ $wheel_id }->{flooded}) {
            last SWITCH;
        }
        if (!$self->{wheels}{$wheel_id}{timer}
            || $self->{wheels}{$wheel_id}{timer} < $current_time) {

            $self->{wheels}{$wheel_id}{timer} = $current_time;
            my $event = "$self->{prefix}cmd_" . lc $input->{command};
            $self->send_event($event, $wheel_id, $input);
            last SWITCH;
        }
        if ($self->{wheels}{$wheel_id}{timer} <= $current_time + 10) {
            $self->{wheels}{$wheel_id}{timer} += 1;
            push @{ $self->{wheels}{$wheel_id}{msq} }, $input;
            push @{ $self->{wheels}{$wheel_id}{alarm_ids} },
                $poe_kernel->alarm_set(
                    '_event_dispatcher',
                    $self->{wheels}{$wheel_id}{timer},
                    $wheel_id
                );
            last SWITCH;
        }

        $self->{wheels}{$wheel_id}{flooded} = 1;
        $self->send_event("$self->{prefix}connection_flood", $wheel_id);
    }

    return 1;
}

sub _conn_error {
    my ($self, $errstr, $wheel_id) = @_[OBJECT, ARG2, ARG3];
    return if !$self->connection_exists($wheel_id);
    $self->_disconnected(
        $wheel_id,
        $errstr || $self->{wheels}{$wheel_id}{disconnecting}
    );
    return;
}

sub _conn_alarm {
    my ($kernel, $self, $wheel_id) = @_[KERNEL, OBJECT, ARG0];
    return if !$self->connection_exists($wheel_id);
    my $conn = $self->{wheels}{$wheel_id};

    $self->send_event(
        "$self->{prefix}connection_idle",
        $wheel_id,
        $conn->{idle},
    );
    $conn->{alarm} = $kernel->delay_set(
        '_conn_alar',
        $conn->{idle},
        $wheel_id,
    );

    return;
}

sub _conn_flushed {
    my ($kernel, $self, $wheel_id) = @_[KERNEL, OBJECT, ARG0];
    return if !$self->connection_exists($wheel_id);

    if ($self->{wheels}{$wheel_id}{disconnecting}) {
        $self->_disconnected(
            $wheel_id,
            $self->{wheels}{$wheel_id}{disconnecting},
        );
        return;
    }

    if ($self->{wheels}{$wheel_id}{compress_pending}) {
        delete $self->{wheels}{$wheel_id}{compress_pending};
        $self->{wheels}{$wheel_id}{wheel}->get_input_filter()->unshift(
            POE::Filter::Zlib::Stream->new(),
        );
        $self->send_event("$self->{prefix}compressed_conn", $wheel_id);
        return;
    }
    return;
}

sub _conn_input {
    my ($kernel, $self, $input, $wheel_id) = @_[KERNEL, OBJECT, ARG0, ARG1];
    my $conn = $self->{wheels}{$wheel_id};

    if ($self->{raw_events}) {
        $self->send_event(
            "$self->{prefix}raw_input",
            $wheel_id,
            $input->{raw_line},
        );
    }
    $conn->{seen} = time();
    $kernel->delay_adjust($conn->{alarm}, $conn->{idle});

    # TODO: Antiflood code
    if ($self->antiflood($wheel_id)) {
        $self->_anti_flood($wheel_id, $input);
    }
    else {
        my $event = "$self->{prefix}cmd_" . lc $input->{command};
        $self->send_event($event, $wheel_id, $input);
    }
    return;
}

sub _event_dispatcher {
    my ($kernel, $self, $wheel_id) = @_[KERNEL, OBJECT, ARG0];

    if (!$self->connection_exists($wheel_id)
        || $self->{wheels}{$wheel_id}{flooded}) {
        return;
    }

    shift @{ $self->{wheels}{$wheel_id}{alarm_ids} };
    my $input = shift @{ $self->{wheels}{$wheel_id}{msq} };

    if ($input) {
        my $event = "$self->{prefix}cmd_" . lc $input->{command};
        $self->send_event($event, $wheel_id, $input);
    }
    return;
}

sub send_output {
    my ($self, $output) = splice @_, 0, 2;

    if ($output && ref $output eq 'HASH') {
        for my $id (grep { $self->connection_exists($_) } @_) {
            if ($self->{raw_events}) {
                my $out = $self->{filter}->put([$output])->[0];
                $out =~ s/\015\012$//;
                $self->send_event("$self->{prefix}raw_output", $id, $out);
            }
            $self->{wheels}{$id}{wheel}->put($output);
        }
    }

    return;
}

sub _send_output {
    $_[OBJECT]->send_output(@_[ARG0..$#_]);
    return;
}

sub antiflood {
    my ($self, $wheel_id, $value) = @_;

    return if !$self->connection_exists($wheel_id);
    return 0 if !$self->{antiflood};
    return $self->{wheels}{$wheel_id}{antiflood} if !defined $value;

    if (!$value) {
        # Flush pending messages from that wheel
        while (my $alarm_id = shift @{ $self->{wheels}{$wheel_id}{alarm_ids} }) {
            $poe_kernel->alarm_remove($alarm_id);
            my $input = shift @{ $self->{wheels}{$wheel_id}{msq} };

            if ($input) {
                my $event = "$self->{prefix}cmd_" . lc $input->{command};
                $self->send_event($event, $wheel_id, $input);
            }
        }
    }

    $self->{wheels}{$wheel_id}{antiflood} = $value;
    return;
}

sub compressed_link {
    my ($self, $wheel_id, $value, $cntr) = @_;
    return if !$self->connection_exists($wheel_id);
    return $self->{wheels}{$wheel_id}{compress} if !defined $value;

    if ($value) {
        if (!$self->{got_zlib}) {
            eval {
                require POE::Filter::Zlib::Stream;
                $self->{got_zlib} = 1;
            };
            chomp $@;
            croak($@) if !$self->{got_zlib};
        }
        if ($cntr) {
            $self->{wheels}{$wheel_id}{wheel}->get_input_filter()->unshift(
                POE::Filter::Zlib::Stream->new()
            );
            $self->send_event(
                "$self->{prefix}compressed_conn",
                $wheel_id,
            );
        }
        else {
            $self->{wheels}{$wheel_id}{compress_pending} = 1;
        }
    }
    else {
        $self->{wheels}{$wheel_id}{wheel}->get_input_filter()->shift();
    }

    $self->{wheels}{$wheel_id}{compress} = $value;
    return;
}

sub disconnect {
    my ($self, $wheel_id, $string) = @_;
    return if !$wheel_id || !$self->connection_exists($wheel_id);
    $self->{wheels}{$wheel_id}{disconnecting} = $string || 'Client Quit';
    return;
}

sub _disconnected {
    my ($self, $wheel_id, $errstr) = @_;
    return if !$wheel_id || !$self->connection_exists($wheel_id);

    my $conn = delete $self->{wheels}{$wheel_id};
    for my $alarm_id ($conn->{alarm}, @{ $conn->{alarm_ids} }) {
        $poe_kernel->alarm_remove($_);
    }
    $self->send_event(
        "$self->{prefix}disconnected",
        $wheel_id,
        $errstr || 'Client Quit',
    );

    if ( $^O =~ /(cygwin|MSWin)/ ) {
      $conn->{wheel}->shutdown_input();
      $conn->{wheel}->shutdown_output();
    }

    return 1;
}

sub connection_info {
    my ($self, $wheel_id) = @_;
    return if !$self->connection_exists($wheel_id);
    return map {
        $self->{wheels}{$wheel_id}{$_}
    } qw(peeraddr peerport sockaddr sockport);
}

sub connection_exists {
    my ($self, $wheel_id) = @_;
    return if !$wheel_id || !defined $self->{wheels}{$wheel_id};
    return 1;
}

sub _conn_flooded {
    my $self = shift;
    my $conn_id = shift || return;
    return if !$self->connection_exists($conn_id);
    return $self->{wheels}{$conn_id}{flooded};
}

sub add_denial {
    my $self = shift;
    my $netmask = shift || return;
    my $reason = shift || 'Denied';
    return if !$netmask->isa('Net::Netmask');

    $self->{denials}{$netmask} = {
        blk    => $netmask,
        reason => $reason,
    };
    return 1;
}

sub del_denial {
    my $self = shift;
    my $netmask = shift || return;
    return if !$netmask->isa('Net::Netmask');
    return if !$self->{denials}{$netmask};
    delete $self->{denials}{$netmask};
    return 1;
}

sub add_exemption {
    my $self = shift;
    my $netmask = shift || return;
    return if !$netmask->isa('Net::Netmask');

    if (!$self->{exemptions}{$netmask}) {
        $self->{exemptions}{$netmask} = $netmask;
    }
    return 1;
}

sub del_exemption {
    my $self = shift;
    my $netmask = shift || return;
    return if !$netmask->isa('Net::Netmask');
    return if !$self->{exemptions}{$netmask};
    delete $self->{exemptions}{$netmask};
    return 1;
}

sub denied {
    my $self = shift;
    my $ipaddr = shift || return;
    return if $self->exempted($ipaddr);

    for my $mask (keys %{ $self->{denials} }) {
        if ($self->{denials}{$mask}{blk}->match($ipaddr)) {
            return $self->{denials}{$mask}{reason};
        }
    }

    return;
}

sub exempted {
    my $self = shift;
    my $ipaddr = shift || return;
    for my $mask (keys %{ $self->{exemptions} }) {
        return 1 if $self->{exemptions}{$mask}->match($ipaddr);
    }
    return;
}

1;

=encoding utf8

=head1 NAME

POE::Component::Server::IRC::Backend - A POE component class that provides network connection abstraction for POE::Component::Server::IRC

=head1 SYNOPSIS

 package MyIRCD;

 use strict;
 use warnings;
 use base 'POE::Component::Server::IRC::Backend';

 sub spawn {
     my ($package, %args) = @_;

     my $self = $package->create(prefix => 'ircd_', @_);

     # process %args ...

     return $self;
 }

=head1 DESCRIPTION

POE::Component::Server::IRC::Backend - A POE component class that provides
network connection abstraction for
L<POE::Component::Server::IRC|POE::Component::Server::IRC>. It uses a
plugin system. See
L<POE::Component::Server::IRC::Plugin|POE::Component::Server::IRC::Plugin>
for details.

=head1 CONSTRUCTOR

=head2 C<create>

Returns an object. Accepts the following parameters, all are optional:

=over 4

=item * B<'alias'>, a POE::Kernel alias to set;

=item * B<'auth'>, set to a false value to globally disable IRC
authentication, default is auth is enabled;

=item * B<'antiflood'>, set to a false value to globally disable flood
protection, default is true;

=item * B<'prefix'>, this is the prefix that is used to generate event
names that the component produces. The default is 'ircd_'.

=item * B<'states'>, an array reference of extra objects states for the IRC
daemon's POE sessions. The elements can be array references of states
as well as hash references of state => handler pairs.

=item * B<'plugin_debug'>, set to a true value to print plugin debug info.
Default is false.

=item * B<'options'>, a hashref of options to L<POE::Session|POE::Session>

=item * B<'raw_events'>, whether to send L<raw|/ircd_raw_input> events.
False by default. Can be enabled later with L<C<raw_events>|/raw_events>;

=back

If the component is created from within another session, that session will
be automagcially registered with the component to receive events and get
an 'ircd_backend_registered' event.

=head1 METHODS

=head2 General

=head3 C<shutdown>

Takes no arguments. Terminates the component. Removes all listeners and
connectors. Disconnects all current client and server connections. This
is a shorthand for C<< $ircd->yield('shutdown') >>.

=head3 C<session_id>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/session_id>>

Takes no arguments. Returns the ID of the component's session. Ideal for
posting events to the component.

=head3 C<session_alias>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/session_alias>>

Takes no arguments. Returns the session alias that has been set through
L<C<create>|/create>'s B<'alias'> argument.

=head3 C<yield>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/yield>>

This method provides an alternative object based means of posting events
to the component. First argument is the event to post, following arguments
are sent as arguments to the resultant post.

=head3 C<call>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/call>>

This method provides an alternative object based means of calling events
to the component. First argument is the event to call, following arguments
are sent as arguments to the resultant call.

=head3 C<delay>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/delay>>

This method provides a way of posting delayed events to the component. The
first argument is an arrayref consisting of the delayed command to post and
any command arguments. The second argument is the time in seconds that one
wishes to delay the command being posted.

Returns an alarm ID that can be used with L<C<delay_remove>|/delay_remove>
to cancel the delayed event. This will be undefined if something went
wrong.

=head3 C<delay_remove>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/delay_remove>>

This method removes a previously scheduled delayed event from the
component. Takes one argument, the C<alarm_id> that was returned by a
L<C<delay>|/delay> method call.

Returns an arrayref that was originally requested to be delayed.

=head3 C<send_event>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/send_event>>

Sends an event through the component's event handling system. These will
get processed by plugins then by registered sessions. First argument is
the event name, followed by any parameters for that event.

=head3 C<send_event_next>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/send_event_next>>

This sends an event right after the one that's currently being processed.
Useful if you want to generate some event which is directly related to
another event so you want them to appear together. This method can only be
called when POE::Component::IRC is processing an event, e.g. from one of
your event handlers. Takes the same arguments as
L<C<send_event>|/send_event>.

=head3 C<send_event_now>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/send_event_now>>

This will send an event to be processed immediately. This means that if an
event is currently being processed and there are plugins or sessions which
will receive it after you do, then an event sent with C<send_event_now>
will be received by those plugins/sessions I<before> the current event.
Takes the same arguments as L<C<send_event>|/send_event>.

=head3 C<raw_events>

If called with a true value, raw events (L<C<ircd_raw_input>|/ircd_raw_input>
and L<C<ircd_raw_output>|/ircd_raw_output>) will be enabled.

=head2 Connections

=head3 C<antiflood>

Takes two arguments, a connection id and true/false value. If value is
specified antiflood protection is enabled or disabled accordingly for the
specified connection. If a value is not specified the current status of
antiflood protection is returned. Returns undef on error.

=head3 C<compressed_link>

Takes two arguments, a connection id and true/false value. If a value is
specified, compression will be enabled or disabled accordingly for the
specified connection. If a value is not specified the current status of
compression is returned. Returns undef on error.

=head3 C<disconnect>

Requires on argument, the connection id you wish to disconnect. The
component will terminate the connection the next time that the wheel input
is flushed, so you may send some sort of error message to the client on
that connection. Returns true on success, undef on error.

=head3 C<connection_exists>

Requires one argument, a connection id. Returns true value if the connection
exists, false otherwise.

=head3 C<connection_info>

Takes one argument, a connection_id. Returns a list consisting of: the IP
address of the peer; the port on the peer; our socket address; our socket
port. Returns undef on error.

 my ($peeraddr, $peerport, $sockaddr, $sockport) = $ircd->connection_info($conn_id);

=head3 C<add_denial>

Takes one mandatory argument and one optional. The first mandatory
argument is a L<Net::Netmask|Net::Netmask> object that will be used to
check connecting IP addresses against. The second optional argument is a
reason string for the denial.

=head3 C<del_denial>

Takes one mandatory argument, a L<Net::Netmask|Net::Netmask> object to
remove from the current denial list.

=head3 C<denied>

Takes one argument, an IP address. Returns true or false depending on
whether that IP is denied or not.

=head3 C<add_exemption>

Takes one mandatory argument, a L<Net::Netmask|Net::Netmask> object that
will be checked against connecting IP addresses for exemption from denials.

=head3 C<del_exemption>

Takes one mandatory argument, a L<Net::Netmask|Net::Netmask> object to
remove from the current exemption list.

=head3 C<exempted>

Takes one argument, an IP address. Returns true or false depending on
whether that IP is exempt from denial or not.

=head2 Plugins

=head3 C<pipeline>

I<Inherited from L<Object::Pluggable|Object::Pluggable/pipeline>>

Returns the L<Object::Pluggable::Pipeline|Object::Pluggable::Pipeline>
object.

=head3 C<plugin_add>

I<Inherited from L<Object::Pluggable|Object::Pluggable/plugin_add>>

Accepts two arguments:

 The alias for the plugin
 The actual plugin object
 Any number of extra arguments

The alias is there for the user to refer to it, as it is possible to have
multiple plugins of the same kind active in one Object::Pluggable object.

This method goes through the pipeline's C<push()> method, which will call
C<< $plugin->plugin_register($pluggable, @args) >>.

Returns the number of plugins now in the pipeline if plugin was
initialized, C<undef>/an empty list if not.

=head3 C<plugin_del>

I<Inherited from L<Object::Pluggable|Object::Pluggable/plugin_del>>

Accepts the following arguments:

 The alias for the plugin or the plugin object itself
 Any number of extra arguments

This method goes through the pipeline's C<remove()> method, which will call
C<< $plugin->plugin_unregister($pluggable, @args) >>.

Returns the plugin object if the plugin was removed, C<undef>/an empty list
if not.

=head3 C<plugin_get>

I<Inherited from L<Object::Pluggable|Object::Pluggable/plugin_get>>

Accepts the following arguments:

 The alias for the plugin

This method goes through the pipeline's C<get()> method.

Returns the plugin object if it was found, C<undef>/an empty list if not.

=head3 C<plugin_list>

I<Inherited from L<Object::Pluggable|Object::Pluggable/plugin_list>>

Takes no arguments.

Returns a hashref of plugin objects, keyed on alias, or an empty list if
there are no plugins loaded.

=head3 C<plugin_order>

I<Inherited from L<Object::Pluggable|Object::Pluggable/plugin_order>>

Takes no arguments.

Returns an arrayref of plugin objects, in the order which they are
encountered in the pipeline.

=head3 C<plugin_register>

I<Inherited from L<Object::Pluggable|Object::Pluggable/plugin_register>>

Accepts the following arguments:

 The plugin object
 The type of the hook (the hook types are specified with _pluggable_init()'s 'types')
 The event name[s] to watch

The event names can be as many as possible, or an arrayref. They correspond
to the prefixed events and naturally, arbitrary events too.

You do not need to supply events with the prefix in front of them, just the
names.

It is possible to register for all events by specifying 'all' as an event.

Returns 1 if everything checked out fine, C<undef>/an empty list if
something is seriously wrong.

=head3 C<plugin_unregister>

I<Inherited from L<Object::Pluggable|Object::Pluggable/plugin_unregister>>

Accepts the following arguments:

 The plugin object
 The type of the hook (the hook types are specified with _pluggable_init()'s 'types')
 The event name[s] to unwatch

The event names can be as many as possible, or an arrayref. They correspond
to the prefixed events and naturally, arbitrary events too.

You do not need to supply events with the prefix in front of them, just the
names.

It is possible to register for all events by specifying 'all' as an event.

Returns 1 if all the event name[s] was unregistered, undef if some was not
found.

=head1 INPUT EVENTS

These are POE events that the component will accept:

=head2 C<register>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/register>>

Takes N arguments: a list of event names that your session wants to listen
for, minus the C<irc_> prefix.

 $ircd->yield('register', qw(connected disconnected));

The special argument 'all' will register your session for all events.
Registering will generate an L<C<ircd_registered>|/ircd_registered>
event that your session can trap.

=head2 C<unregister>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/unregister>>

Takes N arguments: a list of event names which you I<don't> want to
receive. If you've previously done a L<C<register>|/register>
for a particular event which you no longer care about, this event will
tell the component to stop sending them to you. (If you haven't, it just
ignores you. No big deal.)

If you have registered with 'all', attempting to unregister individual
events such as 'connected', etc. will not work. This is a 'feature'.

=head2 C<add_listener>

Takes a number of arguments. Adds a new listener.

=over 4

=item * B<'port'>, the TCP port to listen on. Default is a random port;

=item * B<'auth'>, enable or disable auth sub-system for this listener.
Enabled by default;

=item * B<'bindaddr'>, specify a local address to bind the listener to;

=item * B<'listenqueue'>, change the SocketFactory's ListenQueue;

=item * B<'usessl'>, whether the listener should use SSL. Default is
false;

=item * B<'antiflood'>, whether the listener should use flood protection.
Defaults is true;

=item * B<'idle'>, the time, in seconds, after which a connection will be
considered idle. Defaults is 180.

=back

=head2 C<del_listener>

Takes one of the following arguments:

=over 4

=item * B<'listener'>, a previously returned listener ID;

=item * B<'port'>, a listening port;

=back

The listener will be deleted. Note: any connected clients on that port
will not be disconnected.

=head2 C<add_connector>

Takes two mandatory arguments, B<'remoteaddress'> and B<'remoteport'>.
Opens a TCP connection to specified address and port.

=over 4

=item * B<'remoteaddress'>, hostname or IP address to connect to;

=item * B<'remoteport'>, the TCP port on the remote host;

=item * B<'bindaddress'>, a local address to bind from (optional);

=back

=head2 C<send_output>

Takes a hashref and one or more connection IDs.

 $ircd->yield(
     'send_output',
     {
         prefix  => 'blah!~blah@blah.blah.blah',
         command => 'PRIVMSG',
         params  => ['#moo', 'cows go moo, not fish :D']
     },
     @list_of_connection_ids,
 );

=head2 C<shutdown>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/shutdown>>

Takes no arguments. Terminates the component. Removes all listeners and
connectors. Disconnects all current client and server connections.

=head1 OUTPUT EVENTS

These following events are sent to interested sessions.

=head2 C<ircd_registered>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/syndicator_registered>>

=over

=item Emitted: when a session registers with the component;

=item Target: the registering session;

=item Args:

=over 4

=item * C<ARG0>: the component's object;

=back

=back

=head2 C<ircd_connection>

=over

=item Emitted: when a client connects to one of the component's listeners;

=item Target: all plugins and registered sessions

=item Args:

=over 4

=item * C<ARG0>: the conn id;

=item * C<ARG1>: their ip address;

=item * C<ARG2>: their tcp port;

=item * C<ARG3>: our ip address;

=item * C<ARG4>: our socket port;

=item * C<ARG5>: a boolean indicating whether the client needs to be authed

=back

=back

=head2 C<ircd_auth_done>

=over

=item Emitted: after a client has connected and the component has validated
hostname and ident;

=item Target: Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the connection id;

=item * C<ARG1>, a HASHREF with the following keys: 'ident' and 'hostname';

=back

=back

=head2 C<ircd_listener_add>

=over

=item Emitted: on a successful L<C<add_listener>|/add_listener> call;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the listening port;

=item * C<ARG1>, the listener id;

=item * C<ARG2>, the listening address;

=back

=back

=head2 C<ircd_listener_del>

=over

=item Emitted: on a successful L<C<del_listener>|/del_listener> call;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the listening port;

=item * C<ARG1>, the listener id;

=item * C<ARG2>, the listener address;

=back

=back

=head2 C<ircd_listener_failure>

=over

=item Emitted: when a listener wheel fails;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the listener id;

=item * C<ARG1>, the name of the operation that failed;

=item * C<ARG2>, numeric value for $!;

=item * C<ARG3>, string value for $!;

=item * C<ARG4>, the port it tried to listen on;

=item * C<ARG5>, the address it tried to listen on;

=back

=back

=head2 C<ircd_socketerr>

=over

=item Emitted: on the failure of an L<C<add_connector>|/add_connector> call

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, a HASHREF containing the params that add_connector() was
called with;

=item * C<ARG1>, the name of the operation that failed;

=item * C<ARG2>, numeric value for $!;

=item * C<ARG3>, string value for $!;

=back

=back

=head2 C<ircd_connected>

=over

=item Emitted: when the component establishes a connection with a peer;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the connection id;

=item * C<ARG1>, their ip address;

=item * C<ARG2>, their tcp port;

=item * C<ARG3>, our ip address;

=item * C<ARG4>, our socket port;

=item * C<ARG5>, the peer's name;

=back

=back

=head2 C<ircd_connection_flood>

=over

=item Emitted: when a client connection is flooded;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the connection id;

=back

=back

=head2 C<ircd_connection_idle>

=over

=item Emitted: when a client connection has not sent any data for a set
period;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the connection id;

=item * C<ARG1>, the number of seconds period we consider as idle;

=back

=back

=head2 C<ircd_compressed_conn>

=over

=item Emitted: when compression has been enabled for a connection

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the connection id;

=back

=back

=head2 C<ircd_cmd_*>

=over

=item Emitted: when a client or peer sends a valid IRC line to us;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the connection id;

=item * C<ARG1>, a HASHREF containing the output record from
POE::Filter::IRCD:

 {
     prefix => 'blah!~blah@blah.blah.blah',
     command => 'PRIVMSG',
     params  => [ '#moo', 'cows go moo, not fish :D' ],
     raw_line => ':blah!~blah@blah.blah.blah.blah PRIVMSG #moo :cows go moo, not fish :D'
 }

=back

=back

=head2 C<ircd_raw_input>

=over

=item Emitted: when a line of input is received from a connection

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the connection id;

=item * C<ARG1>, the raw line of input

=back

=back

=head2 C<ircd_raw_output>

=over

=item Emitted: when a line of output is sent over a connection

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the connection id;

=item * C<ARG1>, the raw line of output

=back

=back

=head2 C<ircd_disconnected>

=over

=item Emitted: when a client disconnects;

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>, the connection id;

=item * C<ARG1>, the error or reason for disconnection;

=back

=back

=head2 C<ircd_shutdown>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/syndicator_shutdown>>

=over

=item Emitted: when the component has been asked to L<C<shutdown>|/shutdown>

=item Target: all registered sessions;

=item Args:

=over 4

=item * C<ARG0>: the session ID of the requesting component

=back

=back

=head2 C<ircd_delay_set>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/syndicator_delay_set>>

=over

=item Emitted: on a successful addition of a delayed event using the
L<C<delay>|/delay> method

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>: the alarm id which can be used later with
L<C<delay_remove>|/delay_remove>

=item * C<ARG1..$#_>: subsequent arguments are those which were passed to
L<C<delay>|/delay>

=back

=back

=head2 C<ircd_delay_removed>

I<Inherited from L<POE::Component::Syndicator|POE::Component::Syndicator/syndicator_delay_removed>>

=over

=item Emitted: when a delayed command is successfully removed

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>: the alarm id which was removed

=item * C<ARG1..$#_>: subsequent arguments are those which were passed to
L<C<delay>|/delay>

=back

=back

=head2 C<ircd_plugin_add>

I<Inherited from L<Object::Pluggable|Object::Pluggable/_pluggable_event>>

=over

=item Emitted: when a new plugin is added to the pipeline

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>: the plugin alias

=item * C<ARG1>: the plugin object

=back

=back

=head2 C<ircd_plugin_del>

I<Inherited from L<Object::Pluggable|Object::Pluggable/_pluggable_event>>

=over

=item Emitted: when a plugin is removed from the pipeline

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>: the plugin alias

=item * C<ARG1>: the plugin object

=back

=back

=head2 C<ircd_plugin_error>

I<Inherited from L<Object::Pluggable|Object::Pluggable/_pluggable_event>>

=over

=item Emitted: when an error occurs while executing a plugin handler

=item Target: all plugins and registered sessions;

=item Args:

=over 4

=item * C<ARG0>: the error message

=item * C<ARG1>: the plugin alias

=item * C<ARG2>: the plugin object

=back

=back

=head1 AUTHOR

Chris 'BinGOs' Williams

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as
Perl itself. Please see the license that came with your Perl distribution
for details.

=head1 SEE ALSO

L<POE|POE>

L<POE::Filter::IRCD|POE::Filter::IRCD>

L<POE::Component::Server::IRC|POE::Component::Server::IRC>

=cut
