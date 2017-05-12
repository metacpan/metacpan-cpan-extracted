package POE::Component::Server::NNTP;
$POE::Component::Server::NNTP::VERSION = '1.06';
# ABSTRACT: A POE component that provides NNTP server functionality.

use strict;
use warnings;
use POE qw(Component::Client::NNTP Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use base qw(POE::Component::Pluggable);
use POE::Component::Pluggable::Constants qw(:ALL);
use Socket;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  $opts{posting} = 1 unless defined $opts{posting} and !$opts{posting};
  $opts{handle_connects} = 1 unless defined $opts{handle_connects} and !$opts{handle_connects};
  $opts{extra_cmds} = [ ] unless defined $opts{extra_cmds} and ref $opts{extra_cmds} eq 'ARRAY';
  $_ = lc $_ for @{ $opts{extra_cmds} };
  my $self = bless \%opts, $package;
  $self->_pluggable_init( prefix => 'nntpd_', types => [ 'NNTPD', 'NNTPC' ] );
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { shutdown       => '_shutdown',
		      send_event     => '__send_event',
		      send_to_client => '_send_to_client',
	            },
	   $self => [ qw(_start register unregister _accept_client _accept_failed _conn_input _conn_error _conn_flushed _conn_alarm _send_to_client __send_event) ],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub _conn_exists {
  my ($self,$wheel_id) = @_;
  return 0 unless $wheel_id and defined $self->{clients}->{ $wheel_id };
  return 1;
}

sub _valid_cmd {
  my $self = shift;
  my $cmd = shift || return;
  $cmd = lc $cmd;
  return 0 unless grep { $_ eq $cmd } @{ $self->{cmds} }, @{ $self->{extra_cmds} };
  return 1;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub _start {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
	$kernel->alias_set( $self->{alias} );
  }
  else {
	$kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  if ( $kernel != $sender ) {
    my $sender_id = $sender->ID;
    $self->{events}->{'nntpd_all'}->{$sender_id} = $sender_id;
    $self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
    $self->{sessions}->{$sender_id}->{'refcnt'}++;
    $kernel->refcount_increment($sender_id, __PACKAGE__);
    $kernel->post( $sender, 'nntpd_registered', $self );
    $kernel->detach_myself();
  }

  $self->{filter} = POE::Filter::Line->new();

  $self->{cmds} = [ qw(authinfo article body head stat group help ihave last list newgroups newnews next post quit slave) ];

  $self->{listener} = POE::Wheel::SocketFactory->new(
      ( defined $self->{address} ? ( BindAddress => $self->{address} ) : () ),
      ( defined $self->{port} ? ( BindPort => $self->{port} ) : ( BindPort => 119 ) ),
      SuccessEvent   => '_accept_client',
      FailureEvent   => '_accept_failed',
      SocketDomain   => AF_INET,             # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
  );
  return;
}

sub _accept_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport) = @_[KERNEL,OBJECT,ARG0..ARG2];
  my $sockaddr = inet_ntoa( ( unpack_sockaddr_in ( getsockname $socket ) )[1] );
  my $sockport = ( unpack_sockaddr_in ( getsockname $socket ) )[0];
  $peeraddr = inet_ntoa( $peeraddr );

  my $wheel = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	Filter => $self->{filter},
	InputEvent => '_conn_input',
	ErrorEvent => '_conn_error',
	FlushedEvent => '_conn_flushed',
  );

  return unless $wheel;

  my $id = $wheel->ID();
  $self->{clients}->{ $id } =
  {
				wheel    => $wheel,
				peeraddr => $peeraddr,
				peerport => $peerport,
				sockaddr => $sockaddr,
				sockport => $sockport,
  };
  $self->_send_event( 'nntpd_connection', $id, $peeraddr, $peerport, $sockaddr, $sockport );

  $self->{clients}->{ $id }->{alarm} = $kernel->delay_set( '_conn_alarm', $self->{time_out} || 300, $id );
  return;
}


sub _accept_failed {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  delete $self->{listener};
  $self->_send_event( 'nntpd_listener_failed', $operation, $errnum, $errstr );
  return;
}

sub _conn_input {
  my ($kernel,$self,$input,$id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  return unless $self->_conn_exists( $id );
  $kernel->delay_adjust( $self->{clients}->{ $id }->{alarm}, $self->{time_out} || 300 );
  if ( $self->{clients}->{ $id }->{post_buffer} ) {
    if ( $input eq '.' ) {
	my $buffer = delete $self->{clients}->{ $id }->{post_buffer};
	my $code = $self->{clients}->{ $id }->{post_code};
	$self->_send_event( 'nntpd_posting', $id, $code, $buffer );
	return;
    }
    $input =~ s/^\.\.$/./;
    push @{ $self->{clients}->{ $id }->{post_buffer} }, $input;
    return;
  }
  $input =~ s/^\s+//g;
  $input =~ s/\s+$//g;
  my @args = split /\s+/, $input;
  my $cmd = shift @args;
  return unless $cmd;
  unless ( $self->_valid_cmd( $cmd ) ) {
    $self->send_to_client( $id, "500 command '$cmd' not recognized" );
    return;
  }
  $cmd = lc $cmd;
  if ( $cmd eq 'quit' ) {
    $self->{clients}->{ $id }->{quit} = 1;
    $self->send_to_client( $id, '205 closing connection - goodbye!' );
    return;
  }
  $self->_send_event( 'nntpd_cmd_' . $cmd, $id, @args );
  return;
}

sub _conn_error {
  my ($self,$errstr,$id) = @_[OBJECT,ARG2,ARG3];
  return unless $self->_conn_exists( $id );
  delete $self->{clients}->{ $id };
  $self->_send_event( 'nntpd_disconnected', $id );
  return;
}

sub _conn_flushed {
  my ($self,$id) = @_[OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  return unless $self->{clients}->{ $id }->{quit};
  delete $self->{clients}->{ $id };
  $self->_send_event( 'nntpd_disconnected', $id );
  return;
}

sub _conn_alarm {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  delete $self->{clients}->{ $id };
  $self->_send_event( 'nntpd_disconnected', $id );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{listener};
  delete $self->{clients};
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $self->_pluggable_destroy();
  $self->_unregister_sessions();
  undef;
}

sub register {
  my ($kernel, $self, $session, $sender, @events) =
    @_[KERNEL, OBJECT, SESSION, SENDER, ARG0 .. $#_];

  unless (@events) {
    warn "register: Not enough arguments";
    return;
  }

  my $sender_id = $sender->ID();

  foreach (@events) {
    $_ = "nntpd_" . $_ unless /^_/;
    $self->{events}->{$_}->{$sender_id} = $sender_id;
    $self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
    unless ($self->{sessions}->{$sender_id}->{refcnt}++ or $session == $sender) {
      $kernel->refcount_increment($sender_id, __PACKAGE__);
    }
  }

  $kernel->post( $sender, 'nntpd_registered', $self );
  return;
}

sub unregister {
  my ($kernel, $self, $session, $sender, @events) =
    @_[KERNEL,  OBJECT, SESSION,  SENDER,  ARG0 .. $#_];

  unless (@events) {
    warn "unregister: Not enough arguments";
    return;
  }

  $self->_unregister($session,$sender,@events);
  undef;
}

sub _unregister {
  my ($self,$session,$sender) = splice @_,0,3;
  my $sender_id = $sender->ID();

  foreach (@_) {
    $_ = "nntpd_" . $_ unless /^_/;
    my $blah = delete $self->{events}->{$_}->{$sender_id};
    unless ( $blah ) {
	warn "$sender_id hasn't registered for '$_' events\n";
	next;
    }
    if (--$self->{sessions}->{$sender_id}->{refcnt} <= 0) {
      delete $self->{sessions}->{$sender_id};
      unless ($session == $sender) {
        $poe_kernel->refcount_decrement($sender_id, __PACKAGE__);
      }
    }
  }
  undef;
}

sub _unregister_sessions {
  my $self = shift;
  my $nntpd_id = $self->session_id();
  foreach my $session_id ( keys %{ $self->{sessions} } ) {
     if (--$self->{sessions}->{$session_id}->{refcnt} <= 0) {
        delete $self->{sessions}->{$session_id};
	$poe_kernel->refcount_decrement($session_id, __PACKAGE__)
		unless ( $session_id eq $nntpd_id );
     }
  }
}

sub __send_event {
  my( $self, $event, @args ) = @_[ OBJECT, ARG0, ARG1 .. $#_ ];
  $self->_send_event( $event, @args );
  return;
}

sub _pluggable_event {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, '__send_event', @_ );
}

sub send_event {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, '__send_event', @_ );
}

sub _send_event  {
  my $self = shift;
  my ($event, @args) = @_;
  my $kernel = $POE::Kernel::poe_kernel;
  my $session = $kernel->get_active_session()->ID();
  my %sessions;

  my @extra_args;

  return 1 if $self->_pluggable_process( 'NNTPD', $event, \( @args ), \@extra_args ) == PLUGIN_EAT_ALL;

  push @args, @extra_args if scalar @extra_args;

  $sessions{$_} = $_ for (values %{$self->{events}->{'nntpd_all'}}, values %{$self->{events}->{$event}});

  $kernel->post( $_ => $event => @args ) for values %sessions;
  undef;
}

sub send_to_client {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, '_send_to_client', @_ );
}

sub _send_to_client {
  my ($kernel,$self,$id,$output) = @_[KERNEL,OBJECT,ARG0..ARG1];
  return unless $self->_conn_exists( $id );
  return unless $output;

  return 1 if $self->_pluggable_process( 'NNTPC', 'response', $id, \$output ) == PLUGIN_EAT_ALL;

  $self->{clients}->{ $id }->{wheel}->put($output);
  return 1;
}

sub NNTPD_connection {
  my ($self,$nntpd) = splice @_, 0, 2;
  my $id = ${ $_[0] };
  return 1 unless $self->{handle_connects};
  if ( $self->{posting} ) {
    $self->send_to_client( $id, '200 server ready - posting allowed' );
  }
  else {
    $self->send_to_client( $id, '201 server ready - no posting allowed' );
  }
  return 1;
}

sub NNTPC_response {
  my ($self,$nntpd) = splice @_, 0, 2;
  my $id = $_[0];
  my $text = ${ $_[1] };
  my ($code) = $text =~ /^\s*(\d{3,3})\s*/;
  return 1 unless $code && ( $code eq '340' || $code eq '335' );
  $self->{clients}->{ $id }->{post_code} = $code;
  $self->{clients}->{ $id }->{post_buffer} = [ ];
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::NNTP - A POE component that provides NNTP server functionality.

=head1 VERSION

version 1.06

=head1 SYNOPSIS

  use strict;
  use POE qw(Component::Server::NNTP);

  my %groups;

  while(<DATA>) {
    chomp;
    push @{ $groups{'perl.cpan.testers'}->{'<perl.cpan.testers-381062@nntp.perl.org>'} }, $_;
  }

  my $nntpd = POE::Component::Server::NNTP->spawn( 
  		alias   => 'nntpd',
  		posting => 0,
  		port    => 10119,
  );

  POE::Session->create(
    package_states => [
  	'main' => [ qw(
  			_start
  			nntpd_connection
  			nntpd_disconnected
  			nntpd_cmd_post
  			nntpd_cmd_ihave
  			nntpd_cmd_slave
  			nntpd_cmd_newnews
  			nntpd_cmd_newgroups
  			nntpd_cmd_list
  			nntpd_cmd_group
  			nntpd_cmd_article
  	) ],
    ],
    options => { trace => 0 },
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $heap->{clients} = { };
    $kernel->post( 'nntpd', 'register', 'all' );
    return;
  }

  sub nntpd_connection {
    my ($kernel,$heap,$client_id) = @_[KERNEL,HEAP,ARG0];
    $heap->{clients}->{ $client_id } = { };
    return;
  }

  sub nntpd_disconnected {
    my ($kernel,$heap,$client_id) = @_[KERNEL,HEAP,ARG0];
    delete $heap->{clients}->{ $client_id };
    return;
  }

  sub nntpd_cmd_slave {
    my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
    $kernel->post( $sender, 'send_to_client', $client_id, '202 slave status noted' );
    return;
  }

  sub nntpd_cmd_post {
    my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
    $kernel->post( $sender, 'send_to_client', $client_id, '440 posting not allowed' );
    return;
  }

  sub nntpd_cmd_ihave {
    my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
    $kernel->post( $sender, 'send_to_client', $client_id, '435 article not wanted' );
    return;
  }

  sub nntpd_cmd_newnews {
    my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
    $kernel->post( $sender, 'send_to_client', $client_id, '230 list of new articles follows' );
    $kernel->post( $sender, 'send_to_client', $client_id, '.' );
    return;
  }

  sub nntpd_cmd_newgroups {
    my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
    $kernel->post( $sender, 'send_to_client', $client_id, '231 list of new newsgroups follows' );
    $kernel->post( $sender, 'send_to_client', $client_id, '.' );
    return;
  }

  sub nntpd_cmd_list {
    my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
    $kernel->post( $sender, 'send_to_client', $client_id, '215 list of newsgroups follows' );
    foreach my $group ( keys %groups ) {
  	my $reply = join ' ', $group, scalar keys %{ $groups{$group} }, 1, 'n';
  	$kernel->post( $sender, 'send_to_client', $client_id, $reply );
    }
    $kernel->post( $sender, 'send_to_client', $client_id, '.' );
    return;
  }

  sub nntpd_cmd_group {
    my ($kernel,$sender,$client_id,$group) = @_[KERNEL,SENDER,ARG0,ARG1];
    unless ( $group or exists $groups{lc $group} ) { 
       $kernel->post( $sender, 'send_to_client', $client_id, '411 no such news group' );
       return;
    }
    $group = lc $group;
    $kernel->post( $sender, 'send_to_client', $client_id, "211 1 1 1 $group selected" );
    $_[HEAP]->{clients}->{ $client_id } = { group => $group };
    return;
  }

  sub nntpd_cmd_article {
    my ($kernel,$sender,$client_id,$article) = @_[KERNEL,SENDER,ARG0,ARG1];
    my $group = 'perl.cpan.testers';
    if ( !$article and !defined $_[HEAP]->{clients}->{ $client_id}->{group} ) {
       $kernel->post( $sender, 'send_to_client', $client_id, '412 no newsgroup selected' );
       return;
    }
    $article = 1 unless $article;
    if ( $article !~ /^<.*>$/ and $article ne '1' ) {
       $kernel->post( $sender, 'send_to_client', $client_id, '423 no such article number' );
       return;
    }
    if ( $article =~ /^<.*>$/ and !defined $groups{$group}->{$article} ) {
       $kernel->post( $sender, 'send_to_client', $client_id, '430 no such article found' );
       return;
    }
    foreach my $msg_id ( keys %{ $groups{$group} } ) {
      $kernel->post( $sender, 'send_to_client', $client_id, "220 1 $msg_id article retrieved - head and body follow" );
      $kernel->post( $sender, 'send_to_client', $client_id, $_ ) for @{ $groups{$group}->{$msg_id } };
      $kernel->post( $sender, 'send_to_client', $client_id, '.' );
    }
    return;
  }

  __END__
  Newsgroups: perl.cpan.testers
  Path: nntp.perl.org
  Date: Fri,  1 Dec 2006 09:27:56 +0000
  Subject: PASS POE-Component-IRC-5.14 cygwin-thread-multi-64int 1.5.21(0.15642)
  From: chris@bingosnet.co.uk
  Message-ID: <perl.cpan.testers-381062@nntp.perl.org>

  This distribution has been tested as part of the cpan-testers
  effort to test as many new uploads to CPAN as possible.  See
  http://testers.cpan.org/

=head1 DESCRIPTION

POE::Component::Server::NNTP is a L<POE> component that implements an RFC 977
L<http://www.faqs.org/rfcs/rfc977.html> NNTP server. It is the companion component to
L<POE::Component::Client::NNTP> which implements NNTP client functionality.

You spawn an NNTP server component, create your POE sessions then register your
session to receive events. Whenever clients connect, disconnect or send valid
NNTP protocol commands you will receive an event and an unique client ID. You then
parse and process the commands given and send back applicable NNTP responses.

This component doesn't implement the news database and as such is not by itself a
complete NNTP daemon implementation.

=for Pod::Coverage    NNTPC_response
   NNTPD_connection

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of optional arguments:

  'alias', set an alias on the component;
  'address', bind the component to a particular address, defaults to INADDR_ANY;
  'port', start the listening server on a different port, defaults to 119;
  'options', a hashref of POE::Session options;
  'posting', a true or false value that determines whether the poco
	     responds with a 200 or 201 to clients;
  'handle_connects', true or false whether the poco sends 200/201 
	     responses to connecting clients automagically;
  'extra_cmds', an arrayref of additional NNTP commands that you
	     wish to implement.

Returns a POE::Component::Server::NNTP object.

=back

=head1 METHODS

=over

=item C<session_id>

Returns the POE::Session ID of the component.

=item C<shutdown>

Terminates the component. Shuts down the listener and disconnects connected clients.

=item C<send_event>

Sends an event through the component's event handling system.

=item C<send_to_client>

Send some output to a connected client. First parameter must be a valid client id.
Second parameter is a string of text to send.

=back

=head1 INPUT

These are events that the component will accept:

=over

=item C<register>

Takes N arguments: a list of event names that your session wants to listen for, minus the 'nntpd_' prefix, ( this is
similar to L<POE::Component::IRC> ).

Registering for 'all' will cause it to send all NNTPD-related events to you; this is the easiest way to handle it.

=item C<unregister>

Takes N arguments: a list of event names which you don't want to receive. If you've previously done a 'register' for a particular event which you no longer care about, this event will tell the NNTPD to stop sending them to you. (If you haven't, it just ignores you. No big deal).

=item C<shutdown>

Terminates the component. Shuts down the listener and disconnects connected clients.

=item C<send_event>

Sends an event through the component's event handling system.

=item C<send_to_client>

Send some output to a connected client. First parameter must be a valid client ID.
Second parameter is a string of text to send.

=back

=head1 OUTPUT

The component sends the following events to registered sessions:

=over

=item C<nntpd_registered>

This event is sent to a registering session. ARG0 is POE::Component::Server::NNTP
object.

=item C<nntpd_listener_failed>

Generated if the component cannot either start a listener or there is a problem
accepting client connections. ARG0 contains the name of the operation that failed.
ARG1 and ARG2 hold numeric and string values for $!, respectively.

=item C<nntpd_connection>

Generated whenever a client connects to the component. ARG0 is the client ID, ARG1
is the client's IP address, ARG2 is the client's TCP port. ARG3 is our IP address and
ARG4 is our socket port.

=item C<nntpd_disconnected>

Generated whenever a client disconnects. ARG0 is the client ID.

=item C<nntpd_cmd_*>

Generated for each NNTP command that a connected client sends to us. ARG0 is the
client ID. ARG1 .. ARGn are any parameters that are sent with the command. Check
the RFC L<http://www.faqs.org/rfcs/rfc977.html> for details.

=item C<nntpd_posting>

When the component receives a posting from a client, either as the result of a IHAVE
or POST command, this event is issued. ARG0 will be the client ID. ARG1 will be either
a '335' or '340' indicating what the posting relates to ( either an IHAVE or POST ).
ARG2 will be an arrayref containing the raw lines that the client sent us. No
additional parsing is undertaken on this data.

=back

=head1 PLUGINS

POE::Component::Server::NNTP utilises L<POE::Component::Pluggable> to enable a
L<POE::Component::IRC> type plugin system.

=head2 PLUGIN HANDLER TYPES

There are two types of handlers that can registered for by plugins, these are

=over

=item C<NNTPD>

These are the 'nntpd_' prefixed events that are generated. In a handler arguments are
passed as scalar refs so that you may mangle the values if required.

=item C<NNTPC>

These are generated whenever a response is sent to a client. Again, any
arguments passed are scalar refs for manglement. There is really on one type
of this handler generated 'NNTPC_response'

=back

=head2 PLUGIN EXIT CODES

Plugin handlers should return a particular value depending on what action they wish
to happen to the event. These values are available as constants which you can use
with the following line:

  use POE::Component::Server::NNTP::Constants qw(:ALL);

The return values have the following significance:

=over

=item C<NNTPD_EAT_NONE>

This means the event will continue to be processed by remaining plugins and
finally, sent to interested sessions that registered for it.

=item C<NNTP_EAT_CLIENT>

This means the event will continue to be processed by remaining plugins but
it will not be sent to any sessions that registered for it. This means nothing
will be sent out on the wire if it was an NNTPC event, beware!

=item C<NNTPD_EAT_PLUGIN>

This means the event will not be processed by remaining plugins, it will go
straight to interested sessions.

=item C<NNTPD_EAT_ALL>

This means the event will be completely discarded, no plugin or session will see it. This
means nothing will be sent out on the wire if it was an NNTPC event, beware!

=back

=head2 PLUGIN METHODS

The following methods are available:

=over

=item C<pipeline>

Returns the L<POE::Component::Pluggable::Pipeline> object.

=item C<plugin_add>

Accepts two arguments:

  The alias for the plugin
  The actual plugin object

The alias is there for the user to refer to it, as it is possible to have multiple
plugins of the same kind active in one POE::Component::Server::NNTP object.

This method goes through the pipeline's push() method.

 This method will call $plugin->plugin_register( $nntpd )

Returns the number of plugins now in the pipeline if plugin was initialized, undef
if not.

=item C<plugin_del>

Accepts one argument:

  The alias for the plugin or the plugin object itself

This method goes through the pipeline's remove() method.

This method will call $plugin->plugin_unregister( $nntpd )

Returns the plugin object if the plugin was removed, undef if not.

=item C<plugin_get>

Accepts one argument:

  The alias for the plugin

This method goes through the pipeline's get() method.

Returns the plugin object if it was found, undef if not.

=item C<plugin_list>

Has no arguments.

Returns a hashref of plugin objects, keyed on alias, or an empty list if there are no
plugins loaded.

=item C<plugin_order>

Has no arguments.

Returns an arrayref of plugin objects, in the order which they are encountered in the
pipeline.

=item C<plugin_register>

Accepts the following arguments:

  The plugin object
  The type of the hook, NNTPD or NNTPC
  The event name(s) to watch

The event names can be as many as possible, or an arrayref. They correspond
to the prefixed events and naturally, arbitrary events too.

You do not need to supply events with the prefix in front of them, just the names.

It is possible to register for all events by specifying 'all' as an event.

Returns 1 if everything checked out fine, undef if something's seriously wrong

=item C<plugin_unregister>

Accepts the following arguments:

  The plugin object
  The type of the hook, NNTPD or NNTPC
  The event name(s) to unwatch

The event names can be as many as possible, or an arrayref. They correspond
to the prefixed events and naturally, arbitrary events too.

You do not need to supply events with the prefix in front of them, just the names.

It is possible to register for all events by specifying 'all' as an event.

Returns 1 if all the event name(s) was unregistered, undef if some was not found.

=back

=head2 PLUGIN TEMPLATE

The basic anatomy of a plugin is:

        package Plugin;

        # Import the constants, of course you could provide your own
        # constants as long as they map correctly.
        use POE::Component::Server::NNTP::Constants qw( :ALL );

        # Our constructor
        sub new {
                ...
        }

        # Required entry point for plugins
        sub plugin_register {
                my( $self, $nntpd ) = @_;

                # Register events we are interested in
                $nntpd->plugin_register( $self, 'NNTPD', qw(all) );

                # Return success
                return 1;
        }

        # Required exit point for pluggable
        sub plugin_unregister {
                my( $self, $nntpd ) = @_;

                # Pluggable will automatically unregister events for the plugin

                # Do some cleanup...

                # Return success
                return 1;
        }

        sub _default {
                my( $self, $nntpd, $event ) = splice @_, 0, 3;

                print "Default called for $event\n";

                # Return an exit code
                return NNTPD_EAT_NONE;
        }

=head1 SEE ALSO

L<POE::Component::Client::NNTP>

RFC 977 L<http://www.faqs.org/rfcs/rfc977.html>

RFC 1036 L<http://www.faqs.org/rfcs/rfc1036.html>

L<POE::Component::Pluggable>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
