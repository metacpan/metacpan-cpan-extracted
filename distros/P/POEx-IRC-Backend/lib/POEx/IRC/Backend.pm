package POEx::IRC::Backend;
$POEx::IRC::Backend::VERSION = '0.030003';
use strictures 2;

use Carp;
use Scalar::Util 'blessed';

use IRC::Message::Object ();

use Net::IP::Minimal 'ip_is_ipv6';

use POE qw/
  Wheel::ReadWrite
  Wheel::SocketFactory

  Filter::Stackable
  Filter::IRCv3
  Filter::Line
/;

use Socket qw/
  AF_INET AF_INET6
  pack_sockaddr_in

  getnameinfo
  NI_NUMERICHOST
  NI_NUMERICSERV
  NIx_NOSERV
/;

use Types::Standard -all;
use Types::TypeTiny -all;

use Try::Tiny;

use POEx::IRC::Backend::Connect;
use POEx::IRC::Backend::Connector;
use POEx::IRC::Backend::Listener;


sub RUNNING_IN_HELL () { $^O =~ /(cygwin|MSWin32)/ }

sub get_unpacked_addr {
  my ($sock_packed, %params) = @_;
  my ($err, $addr, $port) = getnameinfo $sock_packed,
     NI_NUMERICHOST | NI_NUMERICSERV,
      ( $params{noserv} ? NIx_NOSERV : () );
  croak $err if $err;
  $params{noserv} ? $addr : ($addr, $port)
}


use Moo; use MooX::TypeTiny;
with 'POEx::IRC::Backend::Role::CheckAvail';


has session_id => (
  init_arg  => undef,
  lazy      => 1,
  is        => 'ro',
  writer    => '_set_session_id',
);

has controller => (
  ## Session ID for controller session
  ## Typically set by 'register' event, though it doesn't have to be:
  lazy      => 1,
  is        => 'ro',
  writer    => '_set_controller',
  predicate => 'has_controller',
);

has filter_irc => (
  lazy    => 1,
  isa     => InstanceOf['POE::Filter'],
  is      => 'ro',
  default => sub { POE::Filter::IRCv3->new },
);

has filter_line => (
  lazy    => 1,
  isa     => InstanceOf['POE::Filter'],
  is      => 'ro',
  default => sub {
    POE::Filter::Line->new(
      InputRegexp   => '\015?\012',
      OutputLiteral => "\015\012",
    )
  },
);

has filter => (
  lazy    => 1,
  isa     => InstanceOf['POE::Filter'],
  is      => 'ro',
  default => sub {
    my ($self) = @_;
    POE::Filter::Stackable->new(
      Filters => [ $self->filter_line, $self->filter_irc ],
    );
  },
);

has listeners => (
  ## POEx::IRC::Backend::Listener objs
  ## These are listeners for a particular port.
  init_arg => undef,
  is      => 'ro',
  isa     => HashRef,
  writer  => '_set_listeners',
  default => sub { +{} },
);

has connectors => (
  ## POEx::IRC::Backend::Connector objs
  ## These are outgoing (peer) connectors.
  init_arg => undef,
  is      => 'ro',
  isa     => HashRef,
  writer  => '_set_connectors',
  default => sub { +{} },
);

has wheels => (
  ## POEx::IRC::Backend::Connect objs
  ## These are our connected wheels.
  init_arg  => undef,
  is        => 'ro',
  isa       => HashRef,
  writer    => '_set_wheels',
  default   => sub { +{} },
);

has ssl_context => (
  lazy      => 1,
  is        => 'ro',
  writer    => '_set_ssl_context',
  default   => sub { undef },
);


sub spawn {
  my ($class, %args) = @_;
  my $ssl_opts = delete $args{ssl_opts};
  my $self = blessed $class ? $class : $class->new(%args);

  POE::Session->create(
    object_states => [
      $self => {
        _start => '_start',
        _stop  => '_stop',

        register          => '_register_controller',
        shutdown          => '_shutdown',
        create_connector  => '_create_connector',
        create_listener   => '_create_listener',
        remove_listener   => '_remove_listener',
        send              => '_send',

        _accept_conn_v4   => '_accept_conn',
        _accept_conn_v6   => '_accept_conn',
        _accept_fail      => '_accept_fail',
        _idle_alarm       => '_idle_alarm',

        _connector_up_v4  => '_connector_up',
        _connector_up_v6  => '_connector_up',
        _connector_failed => '_connector_failed',

        _ircsock_input    => '_ircsock_input',
        _ircsock_error    => '_ircsock_error',
        _ircsock_flushed  => '_ircsock_flushed',
      },
    ],
  ) or confess "Failed to spawn POE::Session";

  if (defined $ssl_opts) {
    confess "expected ssl_opts to be an ARRAY but got $ssl_opts"
      unless ref $ssl_opts eq 'ARRAY';
    my $ssl_err;
    try {
      die "Failed to load POE::Component::SSLify" unless $self->has_ssl_support;
      $self->_set_ssl_context(
        POE::Component::SSLify::SSLify_ContextCreate( @$ssl_opts )
      );
      1
    } catch {
      $ssl_err = $_;
      undef
    } or confess "SSLify failure: $ssl_err";
  }

  $self
}

sub _start {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $self->_set_session_id( $_[SESSION]->ID );
  $kernel->refcount_increment( $self->session_id, "IRCD Running" );
}

sub _stop {}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->session_id => shutdown => @_ )
}

sub _shutdown {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  $kernel->refcount_decrement( $self->session_id => "IRCD Running" );
  $kernel->refcount_decrement( $self->controller => "IRCD Running" );

  ## _disconnected should also clear our alarms.
  $self->_disconnected($_, "Server shutdown") for keys %{ $self->wheels };

  for my $attr (map {; '_set_'.$_ } qw/ listeners connectors wheels /) {
    $self->$attr(+{})
  }
}

sub _register_controller {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  $kernel->refcount_decrement( $self->controller => "IRCD Running" )
    if $self->has_controller;
  $self->_set_controller( $_[SENDER]->ID );
  $kernel->refcount_increment( $self->controller => "IRCD Running" );

  $kernel->post( $self->controller => ircsock_registered => $self );
}

sub _idle_alarm {
  my ($kernel, $self, $w_id) = @_[KERNEL, OBJECT, ARG0];
  my $this_conn = $self->wheels->{$w_id} || return;

  $kernel->post( $self->controller => ircsock_connection_idle => $this_conn );

  $this_conn->alarm_id(
    $kernel->delay_set( _idle_alarm => $this_conn->idle, $w_id )
  );
}

sub create_listener {
  my $self = shift;
  $poe_kernel->post( $self->session_id => create_listener => @_ );
  $self
}

sub _create_listener {
  my ($kernel, $self, %args) = @_[KERNEL, OBJECT, ARG0 .. $#_];
  $args{lc $_} = delete $args{$_} for keys %args;

  my $bindaddr  = delete $args{bindaddr} || '0.0.0.0';
  my $bindport  = delete $args{port}     || 0;

  my $protocol = ( delete $args{ipv6} || ip_is_ipv6($bindaddr) ) ? 6 : 4;

  my $wheel = POE::Wheel::SocketFactory->new(
    SocketDomain => ($protocol == 6 ? AF_INET6 : AF_INET),
    BindAddress  => $bindaddr,
    BindPort     => $bindport,
    SuccessEvent => 
      ( $protocol == 6 ? '_accept_conn_v6' : '_accept_conn_v4' ),
    FailureEvent => '_accept_fail',
    Reuse        => 1,
  );

  my $id = $wheel->ID;

  my $listener = POEx::IRC::Backend::Listener->new(
    protocol => $protocol,
    wheel => $wheel,
    addr  => $bindaddr,
    port  => $bindport,
    idle  => ( delete($args{idle}) || 180 ),
    ssl   => ( delete($args{ssl})  || 0 ),
    ( keys %args ? (args => \%args) : () ),
  );

  $self->listeners->{$id} = $listener;

  ## Real bound port/addr
  my (undef, $port) = get_unpacked_addr( $wheel->getsockname );
  $listener->set_port($port) if $port;

  $kernel->post( $self->controller => ircsock_listener_created => $listener )
}

sub remove_listener {
  my $self = shift;
  $poe_kernel->post( $self->session_id => remove_listener => @_ );
  $self
}

sub _remove_listener {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my %args = @_[ARG0 .. $#_];
  $args{lc $_} = delete $args{$_} for keys %args;

  if (defined $args{listener} && $self->listeners->{ $args{listener} }) {
    my $listener = delete $self->listeners->{ $args{listener} };
    $listener->clear_wheel;
    $kernel->post( $self->controller =>
      ircsock_listener_removed => $listener
    );
    return
  }

  my @removed;

  LISTENER: for my $id (keys %{ $self->listeners }) {
    my $listener = $self->listeners->{$id};
    if (defined $args{port} && defined $args{addr}) {
      if ($args{addr} eq $listener->addr && $args{port} eq $listener->port) {
        delete $self->listeners->{$id};
        push @removed, $listener;
        next LISTENER
      }
    } elsif (defined $args{addr} && $args{addr} eq $listener->addr) {
      delete $self->listeners->{$id};
      push @removed, $listener;
    } elsif (defined $args{port} && $args{port} eq $listener->port) {
      delete $self->listeners->{$id};
      push @removed, $listener;
    }
  }

  for my $listener (@removed) {
    $listener->clear_wheel;
    $kernel->post( $self->controller => 
      ircsock_listener_removed => $listener 
    );
  }
}

sub _accept_fail {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my ($op, $errnum, $errstr, $listener_id) = @_[ARG0 .. ARG3];

  my $listener = delete $self->listeners->{$listener_id};
  if ($listener) {
    $listener->clear_wheel;
    $kernel->post( $self->controller => 
      ircsock_listener_failure => $listener, $op, $errnum, $errstr
    );
  }
}

sub _accept_conn {
  ## Accepted connection to a listener.
  my ($self, $sock, $p_addr, $p_port, $listener_id) = @_[OBJECT, ARG0 .. ARG3];

  my ($protocol, $un_p_addr) = $_[STATE] eq '_accept_conn_v6' ?
    ( 6, $p_addr )
    : ( 4,
        get_unpacked_addr( pack_sockaddr_in($p_port, $p_addr), noserv => 1 )
      ) 
  ;

  my $listener = $self->listeners->{$listener_id};
  my $using_ssl = $listener->ssl;
  if ($using_ssl) {
    try {
      die "Failed to load POE::Component::SSLify" unless $self->has_ssl_support;
      $sock = POE::Component::SSLify::Server_SSLify($sock, $self->ssl_context);
    } catch {
      warn "Could not SSLify (server) socket: $_";
      undef
    } or return;
  }

  my $wheel = POE::Wheel::ReadWrite->new(
    Handle => $sock,
    Filter => $self->filter,
    InputEvent   => '_ircsock_input',
    ErrorEvent   => '_ircsock_error',
    FlushedEvent => '_ircsock_flushed',
  );

  unless ($wheel) {
    warn "Wheel creation failure in _accept_conn";
    return
  }

  my ($sockaddr, $sockport) = get_unpacked_addr( 
    getsockname(
      $using_ssl ? POE::Component::SSLify::SSLify_GetSocket($sock) : $sock
    )
  );

  my $w_id = $wheel->ID;
  my $this_conn = $self->wheels->{$w_id} = 
    POEx::IRC::Backend::Connect->new(
      ($listener->has_args ? (args => $listener->args) : () ),
      protocol  => $protocol,
      wheel     => $wheel,
      peeraddr  => $un_p_addr,
      peerport  => $p_port,
      sockaddr  => $sockaddr,
      sockport  => $sockport,
      seen      => time,
      idle      => $listener->idle,
      ssl       => $using_ssl,
    );

  $this_conn->alarm_id(
    $poe_kernel->delay_set( _idle_alarm => $this_conn->idle, $w_id )
  );

  $poe_kernel->post( $self->controller => 
    ircsock_listener_open => $this_conn, $listener
  );
}

sub create_connector {
  my $self = shift;
  $poe_kernel->post( $self->session_id => create_connector => @_ );
  $self
}

sub _create_connector {
  ## Connector; try to spawn socket <-> remote peer
  ##  remoteaddr =>
  ##  remoteport =>
  ## [optional]
  ##  bindaddr =>
  ##  ipv6 =>
  ##  ssl  =>
  ## ... other args get added to ->args()
  my (undef, $self) = @_[KERNEL, OBJECT];
  my %args = @_[ARG0 .. $#_];

  $args{lc $_} = delete $args{$_} for keys %args;

  my $remote_addr = delete $args{remoteaddr};
  my $remote_port = delete $args{remoteport};

  die "create_connector expects a remoteaddr and remoteport\n"
    unless defined $remote_addr and defined $remote_port;

  my $protocol =
      delete $args{ipv6}                                 ? 6
    : ip_is_ipv6($remote_addr)                           ? 6
    : ( $args{bindaddr} && ip_is_ipv6($args{bindaddr}) ) ? 6
                                                         : 4;

  my $wheel = POE::Wheel::SocketFactory->new(
    SocketDomain   => ($protocol == 6 ? AF_INET6 : AF_INET),
    SocketProtocol => 'tcp',

    RemoteAddress  => $remote_addr,
    RemotePort     => $remote_port,

    FailureEvent   => '_connector_failed',
    SuccessEvent   => 
      ( $protocol == 6 ? '_connector_up_v6' : '_connector_up_v4' ),

    (
      defined $args{bindaddr} ?
        ( BindAddress => delete $args{bindaddr} ) : () 
    ),
  );

  my $id = $wheel->ID;

  $self->connectors->{$id} = POEx::IRC::Backend::Connector->new(
    wheel     => $wheel,
    addr      => $remote_addr,
    port      => $remote_port,
    protocol  => $protocol,

    (defined $args{ssl}      ?
      (ssl      => delete $args{ssl}) : () ),

    (defined $args{bindaddr} ?
      (bindaddr => delete $args{bindaddr}) : () ),

    ## Attach any extra args to Connector->args()
    (keys %args ?
      (args => \%args) : () ),
  );
}


sub _connector_up {
  my ($kernel, $self, $sock, $p_addr, $p_port, $c_id)
    = @_[KERNEL, OBJECT, ARG0 .. ARG3];

  my ($protocol, $un_p_addr);
  if ($_[STATE] eq '_connector_up_v6') {
    $protocol  = 6;
    $un_p_addr = $p_addr;
  } else {
    $protocol  = 4;
    $un_p_addr = get_unpacked_addr(
      pack_sockaddr_in($p_port, $p_addr), noserv => 1
    );
  }

  ## No need to try to connect out any more; remove from connectors pool:
  my $ct = delete $self->connectors->{$c_id};

  my $using_ssl;
  if ( $ct->ssl ) {
    try {
      die "Failed to load POE::Component::SSLify" unless $self->has_ssl_support;
      $sock = POE::Component::SSLify::Client_SSLify(
        $sock, undef, undef, $self->ssl_context
      );
      $using_ssl = 1
    } catch {
      warn "Could not SSLify (client) socket: $_\n";
      undef
    } or return;
  }

  my $wheel = POE::Wheel::ReadWrite->new(
    Handle       => $sock,
    InputEvent   => '_ircsock_input',
    ErrorEvent   => '_ircsock_error',
    FlushedEvent => '_ircsock_flushed',
    Filter       => POE::Filter::Stackable->new(
      Filters => [ $self->filter ],
    )
  );

  unless ($wheel) {
    warn "Wheel creation failure in _connector_up";
    return
  }

  my ($sockaddr, $sockport) = get_unpacked_addr(
    getsockname(
      $using_ssl ? POE::Component::SSLify::SSLify_GetSocket($sock) : $sock
    )
  );

  my $this_conn = POEx::IRC::Backend::Connect->new(
    ($ct->has_args ? (args => $ct->args) : () ),
    protocol => $protocol,
    wheel    => $wheel,
    peeraddr => $un_p_addr,
    peerport => $p_port,
    sockaddr => $sockaddr,
    sockport => $sockport,
    seen => time,
    ssl  => $using_ssl,
  );

  $self->wheels->{ $wheel->ID } = $this_conn;

  $kernel->post( $self->controller => 
    ircsock_connector_open => $this_conn
  );
}

sub _connector_failed {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my ($op, $errno, $errstr, $c_id) = @_[ARG0 .. ARG3];

  my $ct = delete $self->connectors->{$c_id};
  $ct->clear_wheel;

  $kernel->post( $self->controller =>
    ircsock_connector_failure => $ct, $op, $errno, $errstr
  );
}

## _ircsock_* handlers talk to endpoints via listeners/connectors

sub _ircsock_input {
  # ($input, $w_id)  = @_[ARG0, ARG1];
  my $this_conn = $_[OBJECT]->wheels->{ $_[ARG1] };
  $this_conn->seen( time );
  $poe_kernel->delay_adjust( $this_conn->alarm_id, $this_conn->idle )
    if $this_conn->has_alarm_id;

  $poe_kernel->post( $_[OBJECT]->controller => 
    ircsock_input => $this_conn, IRC::Message::Object->new(%{ $_[ARG0] })
  );
}

sub _ircsock_error {
  ## Lost someone.
  my (undef, $self) = @_[KERNEL, OBJECT];
  my ($errstr, $w_id) = @_[ARG2, ARG3];

  my $this_conn = $self->wheels->{$w_id} || return;

  $self->_disconnected(
    $w_id,
    $errstr || $this_conn->is_disconnecting
  );
}

sub _ircsock_flushed {
  ## Socket's been flushed; we may have something to do.
  my ($self, $w_id) = @_[OBJECT, ARG0];

  my $this_conn = $self->wheels->{$w_id} || return;

  if ($this_conn->is_disconnecting) {
    return $self->_disconnected( $w_id, $this_conn->is_disconnecting )
  }

  if ($this_conn->is_pending_compress) {
    return $self->set_compressed_link_now($w_id)
  }
}

sub _send {
  ## POE bridge to send()
  $_[OBJECT]->send(@_[ARG0 .. $#_ ]);
}

## Methods.

sub send {
  ## ->send(HASH, ID [, ID .. ])
  my ($self, $out, @ids) = @_;

  if (blessed $out && $out->isa('IRC::Message::Object')) {
    # breaks encapsulation for performance reasons:
    $out = +{
      command => $out->command,
      (
        map {; exists $out->{$_} ? ($_ => $out->{$_}) : () }
          qw/ colonify prefix params tags /
      ),
    };
  }

  confess 
    "send() takes a HASH or IRC::Message::Object and a list of connection IDs"
    unless ref $out eq 'HASH' and @ids;

  TARGET: for my $target (@ids) {
    # FIXME tests/docs wrt passing in Connect objs
    $target = $target->wheel_id if blessed $target;
    ($self->wheels->{$target} || next TARGET)->wheel->put($out)
  }

  $self
}

sub disconnect {
  # Mark a wheel for disconnection at next flush.
  my ($self, $w_id, $str) = @_;
  $w_id = $w_id->wheel_id if blessed $w_id;
  confess "disconnect() needs an (extant) wheel ID or Connect object"
    unless defined $w_id;

  # Application code should probably check $conn->has_wheel before trying to
  # call a ->disconnect, but if not, it's hard to determine if we were passed
  # junk or just racing against an already-gone wheel:
  unless (defined $self->wheels->{$w_id}) {
    carp "Attempting to disconnect() unknown wheel '$w_id'\n",
      " This warning may be spurious. Your wheel may have died of natural causes.\n",
      " Try checking '\$conn->has_wheel' before calling disconnect()." ;
    return
  }

  $self->wheels->{$w_id}->is_disconnecting($str // "Client disconnect");
  $self
}

sub disconnect_now {
  my ($self, $w_id, $str) = @_;
  $w_id = $w_id->wheel_id if blessed $w_id;
  confess "disconnect_now needs an (extant) wheel ID or Connect object"
    unless defined $w_id;

  unless (defined $self->wheels->{$w_id}) {
    carp "Attempting to disconnect() unknown wheel '$w_id'\n",
      " This warning may be spurious. Your wheel may have died of natural causes.\n",
      " Try checking '\$conn->has_wheel' before calling disconnect()." ;
    return
  }

  $self->_disconnected($w_id, $str // "Client disconnect");
  $self
}

sub _disconnected {
  ## Wheel needs cleanup.
  my ($self, $w_id, $str) = @_;
  return unless $w_id and $self->wheels->{$w_id};

  my $this_conn = delete $self->wheels->{$w_id};

  ## Idle timer cleanup
  $poe_kernel->alarm_remove( $this_conn->alarm_id ) 
    if $this_conn->has_alarm_id;

  ## Already a dead Connect (wheel was cleared), nothing to do
  return unless $this_conn->has_wheel;

  if (RUNNING_IN_HELL) {
    $this_conn->wheel->shutdown_input;
    $this_conn->wheel->shutdown_output;
  }

  $this_conn->clear_wheel;

  $poe_kernel->post( $self->controller => 
    ircsock_disconnect => $this_conn, $str
  );

  1
}

sub set_compressed_link {
  my ($self, $w_id) = @_;
  confess "set_compressed_link() needs a wheel ID"
    unless defined $w_id;

  confess "Failed to load POE::Filter::Zlib::Stream"
    unless $self->has_zlib_support;

  unless ($self->wheels->{$w_id}) {
    carp "set_compressed_link for nonexistant wheel '$w_id'";
    return
  }

  $self->wheels->{$w_id}->is_pending_compress(1);

  $self
}

sub set_compressed_link_now {
  my ($self, $w_id) = @_;
  confess "set_compressed_link() needs a wheel ID"
    unless defined $w_id;
 
  my $this_conn = $self->wheels->{$w_id};
  unless (defined $this_conn) {
    carp "set_compressed_link_now for nonexistant wheel '$w_id'";
    return
  }

  confess "Failed to load POE::Filter::Zlib::Stream"
    unless $self->has_zlib_support;

  $this_conn->wheel->get_input_filter->unshift(
    POE::Filter::Zlib::Stream->new
  );

  $this_conn->is_pending_compress(0);
  $this_conn->set_compressed(1);

  $poe_kernel->post( $self->controller =>
    ircsock_compressed => $this_conn
  );

  $self
}

sub unset_compressed_link {
  my ($self, $w_id) = @_;
  confess "unset_compressed_link() needs a wheel ID"
    unless defined $w_id;

  my $this_conn = $self->wheels->{$w_id};
  unless (defined $this_conn && $this_conn->compressed) {
    carp 
      "unset_compressed_link on uncompressed or nonexistant wheel '$w_id'";
    return
  }

  $this_conn->wheel->get_input_filter->shift;
  $this_conn->set_compressed(0);

  $self
}

no warnings 'void';
print
 qq[<CaptObviousman> pretend for a moment that I'm stuck with mysql\n],
 qq[<rnowak> ok, fetching my laughing hat and monocle\n],
unless caller; 1;


=pod

=for Pod::Coverage has_\w+ RUNNING_IN_HELL get_unpacked_addr

=head1 NAME

POEx::IRC::Backend - IRC client or server backend

=head1 SYNOPSIS

  use POE;
  use POEx::IRC::Backend;

  POE::Session->create(
    package_states => [
      main => [ qw/
        _start
        ircsock_registered
        ircsock_input
      / ],
    ],
  );

  sub _start {
    # Spawn a Backend and register as the controlling session:
    my $backend = POEx::IRC::Backend->spawn;
    $_[HEAP]->{backend} = $backend;
    $_[KERNEL]->post( $backend->session_id, 'register' );
  }

  sub ircsock_registered {
    my $backend = $_[HEAP]->{backend};

    # Listen for incoming IRC traffic:
    $backend->create_listener(
      bindaddr => $addr,
      port     => $port,
    );

    # Connect to a remote endpoint:
    $backend->create_connector(
      remoteaddr => $remote,
      remoteport => $remoteport,
      # Optional:
      bindaddr => $bindaddr,
      ipv6     => 1,
      ssl      => 1,
    );
  }

  # Handle and dispatch incoming IRC events:
  sub ircsock_input {
    # POEx::IRC::Backend::Connect obj:
    my $this_conn = $_[ARG0];

    # IRC::Message::Object obj:
    my $input_obj = $_[ARG1];

    my $cmd = $input_obj->command;

    # ... dispatch, etc ...
  }

=head1 DESCRIPTION

A L<POE> IRC socket handler that can be used (by client or server
implementations) to speak the IRC protocol to endpoints via
L<IRC::Message::Object> objects.

Inspired by L<POE::Component::Server::IRC::Backend> & L<POE::Component::IRC>.

This is a very low-level interface to IRC sockets; the goal is to provide all
the necessary scaffolding to develop stateless or stateful IRC clients and
daemons. See L<POEx::IRC::Client::Lite> for an experimental IRC client library
using this backend (and the L</"SEE ALSO"> section of this documentation for
related tools).

=head2 Attributes

=head3 controller

Retrieve the L<POE::Session> ID for the backend's registered controller.

Predicate: B<has_controller>

=head3 connectors

A HASH of active Connector objects, keyed on their wheel ID.

=head3 filter

A L<POE::Filter::Stackable> instance consisting of the current L</filter_irc>
stacked with L</filter_line> (at the time the attribute is built).

=head3 filter_irc

A L<POE::Filter::IRCv3> instance with B<colonify> disabled, by default (this
behavior changed in v0.27.2).

A server-side Backend may want a colonifying filter:

  my $backend = POEx::IRC::Backend->new(
    filter_irc => POE::Filter::IRCv3->new(colonify => 1),
    ...
  );

=head3 filter_line

A L<POE::Filter::Line> instance.

=head3 listeners

HASH of active Listener objects, keyed on their wheel ID.

=head3 session_id

Returns the backend's session ID.

=head3 ssl_context

Returns the L<Net::SSLeay> Context object, if we have one (or C<undef> if
not); the context is set up by L</spawn> if C<ssl_opts> are specified.

=head3 wheels

HASH of actively connected wheels, keyed on their wheel ID.


=head2 Methods

=head3 spawn

  my $backend = POEx::IRC::Backend->spawn(
    ## Optional, needed for SSL-ified server-side sockets
    ssl_opts => [
      'server.key',
      'server.cert',
    ],
  );

Creates the backend's L<POE::Session>.

The C<ssl_opts> ARRAY is passed directly to
L<POE::Component::SSLify/SSLify_ContextCreate>, if present. As of C<v0.28.x>,
each Backend gets its own L<Net::SSLeay> context object (rather than sharing
the global context). See L<POE::Component::SSLify> & L<Net::SSLeay>.

=head3 create_connector

  $backend->create_connector(
    remoteaddr => $addr,
    remoteport => $addr,
    ## Optional:
    bindaddr => $local_addr,
    ipv6 => 1,
    ssl  => 1,
    ## Unrecognized opts are stored in the Connector's 'args' hash:
    tag   => 'foo',
  );

Attempts to create a L<POEx::IRC::Backend::Connector> that 
holds a L<POE::Wheel::SocketFactory> connector wheel; connectors will 
attempt to establish an outgoing connection immediately.

Unrecognized options are stored in the L<POEx::IRC::Backend::Connector>'s
C<args> HASH-type attribute; this is passed to successfully created
L<POEx::IRC::Backend::Connect> instances (as of C<v0.26.x>). Note that the
reference is shared, not copied.

=head3 create_listener

  $backend->create_listener(
    bindaddr => $addr,
    port     => $port,
    ## Optional:
    ipv6     => 1,
    ssl      => 1,
    idle     => $seconds,
  );

Attempts to create a L<POEx::IRC::Backend::Listener> 
that holds a L<POE::Wheel::SocketFactory> listener wheel.

Unrecognized arguments will be added to the Listener object's C<args>
attribute, which is then passed on to L<POEx::IRC::Backend::Connect> objects
created by incoming connections to that listener, similar to the behavior
described in L</create_connector> (as of C<v0.28.x>).

=head3 remove_listener

    $backend->remove_listener(
      listener => $listener_id,
    );

    ## or via addr, port, or combination thereof:
    $backend->remove_listener(
      addr => '127.0.0.1',
      port => 6667,
    );

Removes a listener and clears its B<wheel> attribute; the socket shuts down
when the L<POE::Wheel::SocketFactory> wheel goes out of scope.

=head3 disconnect

  $backend->disconnect($wheel_id, $disconnect_string);

Given a L<POEx::IRC::Backend::Connect> or its C<wheel_id>, mark the specified
wheel for disconnection.

This method will warn if the given C<wheel_id> cannot be found, which may be
due to the connection disappearing prior to calling C<disconnect>.

You can avoid spurious warnings by checking if the
L<POEx::IRC::Backend::Connect> still has an active wheel attached:

  if ($this_conn->has_wheel) {
    $backend->disconnect( $this_conn )
  }

Note that disconnection typically happens after a buffer flush; if your
software does not perform entirely like a traditional platform (server
implementations will typically send C<< ERROR: Closing Link >> or similar to
clients marked for disconnection, which will trigger a buffer flush) you may
currently experience "late" disconnects. See L</disconnect_now>.

=head3 disconnect_now

Like L</disconnect>, but attempt to destroy the wheel immediately (without
waiting for a buffer flush).

=head3 send

  $backend->send(
    {
      prefix  => $prefix,
      params  => [ @params ],
      command => $cmd,
    },
    @connect_ids
  );

  use IRC::Message::Object 'ircmsg';
  my $msg = ircmsg(
    command => 'PRIVMSG',
    params  => [ $chan, $string ],
  );
  $backend->send( $msg, $connect_obj );

Feeds L<POE::Filter::IRCv3> and sends the resultant raw IRC 
line to the specified connection wheel ID(s) or L<POEx::IRC::Backend::Connect>
object(s).

Accepts either an L<IRC::Message::Object> or a HASH compatible with
L<POE::Filter::IRCv3> -- look there for details.

Note that unroutable (target connection IDs with no matching live
wheel) messages are silently dropped. You can check L</wheels> yourself before
sending if this behavior is unwanted:

  for my $target (@connect_ids) {
    unless (exists $backend->wheels->{$target}) {
      warn "Cannot send to nonexistant target '$target'";
      next
    }
    $backend->send(
        { prefix => $prefix, params => [ @params ], command => $cmd },
        $target
    );
  }

=head3 has_ssl_support

Returns true if L<POE::Component::SSLify> was successfully loaded.

=head3 has_zlib_support

Returns true if L<POE::Filter::Zlib::Stream> was successfully loaded.

=head3 set_compressed_link

  $backend->set_compressed_link( $conn_id );

Mark a specified connection wheel ID as pending compression; 
L<POE::Filter::Zlib::Stream> will be added to the filter stack when the 
next flush event arrives.

This method will die unless L</has_zlib_support> is true.

=head3 set_compressed_link_now

  $backend->set_compressed_link_now( $conn_id );

Add a L<POE::Filter::Zlib::Stream> to the connection's filter stack 
immediately, rather than upon next flush event.

This method will die unless L</has_zlib_support> is true.

=head3 unset_compressed_link

  $backend->unset_compressed_link( $conn_id );

Remove L<POE::Filter::Zlib::Stream> from the connection's filter stack.


=head2 Received events

=head3 register

  $poe_kernel->post( $backend->session_id,
    'register'
  );

Register the sender session as the backend's controller session. The last 
session to send 'register' is the session that receives notification 
events from the backend component.

=head3 create_connector

Event interface to I<create_connector> -- see L</Methods>

=head3 create_listener

Event interface to I<create_listener> -- see L</Methods>

=head3 remove_listener

Event interface to I<remove_listener> -- see L</Methods>

=head3 send

Event interface to I</send> -- see L</Methods>

=head3 shutdown

Disconnect all wheels and clean up.


=head2 Dispatched events

These events are dispatched to the controller session; see L</register>.

=head3 ircsock_compressed

Dispatched when a connection wheel has had a compression filter added.

C<$_[ARG0]> is the connection's L<POEx::IRC::Backend::Connect>.

=head3 ircsock_connection_idle

Dispatched when a connection wheel has had no input for longer than 
specified idle time (see L</create_listener> regarding idle times).

Currently these events are only issued for incoming Connects accepted on a
Listener, not outgoing Connects created by a Connector; if you need to do
ping/pong-style heartbeating on an outgoing Connector-spawned socket, you will
need to run your own timer.

C<$_[ARG0]> is the connection's L<POEx::IRC::Backend::Connect>.

See also: L<POEx::IRC::Backend::Connect/ping_pending>

=head3 ircsock_connector_failure

Dispatched when a Connector has failed due to some sort of socket error.

C<$_[ARG0]> is the connection's 
L<POEx::IRC::Backend::Connector> with wheel() cleared.

C<@_[ARG1 .. ARG3]> contain the socket error details reported by 
L<POE::Wheel::SocketFactory>; operation, errno, and errstr, respectively.

=head3 ircsock_connector_open

Dispatched when a Connector has established a connection to a peer.

C<$_[ARG0]> is the L<POEx::IRC::Backend::Connect> for the 
connection.

=head3 ircsock_disconnect

Dispatched when a connection wheel has been cleared.

C<$_[ARG0]> is the connection's L<POEx::IRC::Backend::Connect> 
with wheel() cleared.

=head3 ircsock_input

Dispatched when there is some IRC input from a connection wheel.

C<$_[ARG0]> is the connection's 
L<POEx::IRC::Backend::Connect>.

C<$_[ARG1]> is an L<IRC::Message::Object>.

=head3 ircsock_listener_created

Dispatched when a L<POEx::IRC::Backend::Listener> has been 
created.

C<$_[ARG0]> is the L<POEx::IRC::Backend::Listener> instance; 
the instance's port() is altered based on getsockname() details after 
socket creation and before dispatching this event.

=head3 ircsock_listener_failure

Dispatched when a Listener has failed due to some sort of socket error.

C<$_[ARG0]> is the L<POEx::IRC::Backend::Listener> object.

C<@_[ARG1 .. ARG3]> contain the socket error details reported by 
L<POE::Wheel::SocketFactory>; operation, errno, and errstr, respectively.

=head3 ircsock_listener_open

Dispatched when a listener accepts a connection.

C<$_[ARG0]> is the connection's L<POEx::IRC::Backend::Connect>

C<$_[ARG1]> is the connection's L<POEx::IRC::Backend::Listener>

=head3 ircsock_listener_removed

Dispatched when a Listener has been removed.

C<$_[ARG0]> is the L<POEx::IRC::Backend::Listener> object.

=head3 ircsock_registered

Dispatched when a L</register> event has been successfully received, as a 
means of acknowledging the controlling session.

C<$_[ARG0]> is the Backend's C<$self> object.

=head1 BUGS

Probably lots. Please report them via RT, e-mail, IRC
(C<irc.cobaltirc.org#perl>), or GitHub
(L<http://github.com/avenj/poex-irc-backend>).

=head1 SEE ALSO

L<POEx::IRC::Backend::Connect>

L<POEx::IRC::Backend::Connector>

L<POEx::IRC::Backend::Listener>

L<POEx::IRC::Backend::Role::Socket>

L<POEx::IRC::Backend::Role::HasEndpoint>

L<POEx::IRC::Backend::Role::HasWheel>

L<POEx::IRC::Client::Lite> for an experimental IRC client library using this
backend.

L<https://github.com/miniCruzer/irssi-bouncer> for an irssi-based
bouncer/proxy system using this backend.

L<POE::Filter::IRCv3> and L<IRC::Message::Object> for documentation regarding
IRC message parsing.

L<IRC::Toolkit> for an extensive set of IRC-related utilities.

L<POE::Component::IRC> if you're looking for a mature, fully-featured IRC
client library.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Inspiration derived from L<POE::Component::Server::IRC::Backend> and
L<POE::Component::IRC> by BINGOS, HINRIK et al.

=cut

