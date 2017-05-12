package POE::Component::Server::SimpleSMTP;
BEGIN {
  $POE::Component::Server::SimpleSMTP::VERSION = '1.50';
}

#ABSTRACT: A simple to use POE SMTP Server.

use strict;
use warnings;
use POSIX;
use POE qw(Component::Client::SMTP Component::Client::DNS Wheel::SocketFactory Wheel::ReadWrite Filter::Transparent::SMTP);
use POE::Component::Client::DNSBL;
use base qw(POE::Component::Pluggable);
use POE::Component::Pluggable::Constants qw(:ALL);
use Email::MessageID;
use Email::Simple;
use Email::Address;
use Carp;
use Socket;
use Storable;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  _massage_handlers( $opts{handlers} ) if $opts{handlers};
  $opts{handlers} = [ ] unless $opts{handlers} and ref $opts{handlers} eq 'ARRAY';
  $opts{domains}  = [ ] unless $opts{domains} and ref $opts{domains} eq 'ARRAY';
  $opts{simple} = 1 unless defined $opts{simple} and !$opts{simple};
  $opts{handle_connects} = 1 unless defined $opts{handle_connects} and !$opts{handle_connects};
  $opts{hostname} = 'localhost' unless defined $opts{hostname};
  $opts{relay} = 0 unless $opts{relay};
  $opts{origin} = 0 unless $opts{origin};
  $opts{maxrelay} = 5 unless $opts{maxrelay};
  $opts{relay_auth} = 'PLAIN' if $opts{relay_auth};
  $opts{version} = join('-', __PACKAGE__, $POE::Component::Server::SimpleSMTP::VERSION ) unless $opts{version};
  my $self = bless \%opts, $package;
  $self->_pluggable_init( prefix => 'smtpd_', types => [ 'SMTPD', 'SMTPC' ], debug => 1 );
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { shutdown       => '_shutdown',
		      send_event     => '__send_event',
		      send_to_client => '_send_to_client',
		      start_listener => '_start_listener',
	            },
	   $self => [ qw(_start register unregister _accept_client _accept_failed _conn_input _conn_error _conn_flushed _conn_alarm _send_to_client __send_event _process_queue _smtp_send_relay _smtp_send_mx _smtp_send_success _smtp_send_failure _process_dns_mx _fh_buffer _buffer_error _buffer_flush _dnsbl _sender_verify) ],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub mail_queue {
  my $self = shift;
  return map { { %$_ } } @{ $self->{_mail_queue} };
}

sub pause_queue {
  my $self = shift;
  $self->{paused} = 1;
}

sub resume_queue {
  my $self = shift;
  my $pause = delete $self->{paused};
  $poe_kernel->post( $self->{session_id}, '_process_queue' ) if $pause;
}

sub paused {
  return $_[0]->{paused};
}

sub cancel_message {
  my $self = shift;
  my $uid = shift || return;
  return unless scalar @{ $self->{_mail_queue} };
  my $i = 0;
  for ( @{ $self->{_mail_queue} } ) {
	splice( @{ $self->{_mail_queue} }, $i, 1 ), last
		 if $_->{uid} eq $uid;
	++$i;
  }
  return 1;
}

sub data_mode {
  my $self = shift;
  my $id = shift || return;
  return unless $self->_conn_exists( $id );
  my $handle = shift;
  if ( $handle and $^O ne 'MSWin32' ) {
	$poe_kernel->call( $self->{session_id}, '_fh_buffer', $id, $handle );
  } 
  else {
  	$self->{clients}->{ $id }->{buffer} = [ ];
  }
  return 1;
}

sub getsockname {
  return unless $_[0]->{listener};
  return $_[0]->{listener}->getsockname();
}

sub get_handlers {
  my $self = shift;
  my $handlers = Storable::dclone( $self->{handlers} );
  delete $_->{RE} for @{ $handlers };
  return $handlers;
}

sub set_handlers {
  my $self = shift;
  my $handlers = shift || return;
  _massage_handlers( $handlers );
  $self->{handlers} = $handlers;
  return 1;
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
  return 0 unless grep { $_ eq $cmd } @{ $self->{cmds} };
  return 1;
}

sub _massage_handlers {
  my $handler = shift || return;
  croak( "HANDLERS is not a ref to an array!" ) 
	unless ref $handler and ref $handler eq 'ARRAY';
  my $count = 0;
  while ( $count < scalar( @$handler ) ) {
     if ( ref $handler->[ $count ] and ref( $handler->[ $count ] ) eq 'HASH' ) {
	$handler->[ $count ]->{ uc $_ } = delete $handler->[ $count ]->{ $_ } 
	    for keys %{ $handler->[ $count ] };
	croak( "HANDLER number $count does not have a SESSION argument!" )
		unless $handler->[ $count ]->{'SESSION'};
	croak( "HANDLER number $count does not have an EVENT argument!" )
		unless $handler->[ $count ]->{'EVENT'};
	croak( "HANDLER number $count does not have a MATCH argument!" )
		unless $handler->[ $count ]->{'MATCH'};
	$handler->[ $count ]->{'SESSION'} = $handler->[ $count ]->{'SESSION'}->ID()
		if UNIVERSAL::isa( $handler->[ $count ]->{'SESSION'}, 'POE::Session' );
	my $regex;
	eval { $regex = qr/$handler->[ $count ]->{'MATCH'}/ };
	if ( $@ ) {
		croak( "HANDLER number $count has a malformed MATCH -> $@" );
	}
	else {
		$handler->[ $count ]->{'RE'} = $regex;
	}
     }
     else {
	croak( "HANDLER number $count is not a reference to a HASH!" );
     }
     $count++;
  }
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
    $self->{events}->{'smtpd_all'}->{$sender_id} = $sender_id;
    $self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
    $kernel->refcount_increment($sender_id, __PACKAGE__);
    $kernel->post( $sender, 'smtpd_registered', $self );
  }

  #$self->{filter} = POE::Filter::Line->new( Literal => "\015\012" );
  $self->{filter} = POE::Filter::Transparent::SMTP->new(
    InputLiteral => qq{\015\012},
    OutputLiteral => qq{\015\012},
  );

  $self->{cmds} = [ qw(ehlo helo mail rcpt data noop vrfy rset expn help quit) ];

  $kernel->call( $self->{session_id}, 'start_listener' );

  $self->{resolver} = POE::Component::Client::DNS->spawn()
    unless $self->{resolver} and $self->{resolver}->isa('POE::Component::Client::DNS');

  $self->{_dnsbl} = POE::Component::Client::DNSBL->spawn(
	resolver => $self->{resolver},
	dnsbl    => $self->{dnsbl},
  ) if $self->{dnsbl_enable};


  return;
}

sub start_listener {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'start_listener', @_ );
}

sub _start_listener {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  if ( $self->{listener} ) {
     warn "Listener already started\n";
     return;
  }
  $self->{listener} = POE::Wheel::SocketFactory->new(
      ( defined $self->{address} ? ( BindAddress => $self->{address} ) : () ),
      ( defined $self->{port} ? ( BindPort => $self->{port} ) : ( BindPort => 25 ) ),
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
  my $sockaddr = eval "inet_ntoa( ( unpack_sockaddr_in ( CORE::getsockname $socket ) )[1] )";
  my $sockport = eval "( unpack_sockaddr_in ( CORE::getsockname $socket ) )[0]";
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
  $self->_send_event( 'smtpd_connection', $id, $peeraddr, $peerport, $sockaddr, $sockport );

  $self->{clients}->{ $id }->{alarm} = $kernel->delay_set( '_conn_alarm', $self->{client_time_out} || 300, $id );
  return;
}


sub _accept_failed {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  delete $self->{listener};
  $self->_send_event( 'smtpd_listener_failed', $operation, $errnum, $errstr );
  return;
}

sub _conn_input {
  my ($kernel,$self,$input,$id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  return unless $self->_conn_exists( $id );
  $kernel->delay_adjust( $self->{clients}->{ $id }->{alarm}, $self->{client_time_out} || 300 );
  if ( $self->{clients}->{ $id }->{buffer} ) {
    if ( $input eq '.' and $self->{simple} ) {
	my $mail = delete $self->{clients}->{ $id }->{mail};
	my $rcpt = delete $self->{clients}->{ $id }->{rcpt};
	my $buffer = delete $self->{clients}->{ $id }->{buffer};
	$self->_send_event( 'smtpd_message', $id, $mail, $rcpt, $buffer );
	return;
    }
    elsif ( $input eq '.' and ref( $self->{clients}->{ $id }->{buffer} ) eq 'ARRAY' ) {
	my $buffer = delete $self->{clients}->{ $id }->{buffer};
	$self->_send_event( 'smtpd_data', $id, $buffer );
	return;
    }
    elsif ( $input eq '.' ) {
	my $wheel_id = delete $self->{clients}->{ $id }->{buffer};
	$self->{buffers}->{ $wheel_id }->{shutdown} = 1;
	return;
    }
    if ( ref( $self->{clients}->{ $id }->{buffer} ) eq 'ARRAY' ) {
    	push @{ $self->{clients}->{ $id }->{buffer} }, $input;
    }
    else {
	my $buffer = $self->{clients}->{ $id }->{buffer};
	$self->{buffers}->{ $buffer }->{wheel}->put( $input );
    }
    return;
  }
  $input =~ s/^\s+//g;
  $input =~ s/\s+$//g;
  my @args = split /\s+/, $input, 2;
  my $cmd = shift @args;
  return unless $cmd;
  unless ( $self->_valid_cmd( $cmd ) ) {
    $self->send_to_client( $id, "500 Syntax error, command unrecognized" );
    return;
  }
  $cmd = lc $cmd;
  if ( $cmd eq 'quit' ) {
    $self->{clients}->{ $id }->{quit} = 1;
    $self->send_to_client( $id, '221 closing connection - goodbye!' );
    return;
  }
  $self->_send_event( 'smtpd_cmd_' . $cmd, $id, @args );
  return;
}

sub _conn_error {
  my ($self,$errstr,$id) = @_[OBJECT,ARG2,ARG3];
  return unless $self->_conn_exists( $id );
  delete $self->{clients}->{ $id };
  $self->_send_event( 'smtpd_disconnected', $id );
  return;
}

sub _conn_flushed {
  my ($self,$id) = @_[OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  return unless $self->{clients}->{ $id }->{quit};
  delete $self->{clients}->{ $id };
  $self->_send_event( 'smtpd_disconnected', $id );
  return;
}

sub _conn_alarm {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  delete $self->{clients}->{ $id };
  $self->_send_event( 'smtpd_disconnected', $id );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{listener};
  delete $self->{clients};
  delete $self->{buffers};
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $self->_pluggable_destroy();
  $self->_unregister_sessions();
  $self->{_dnsbl}->shutdown() if $self->{dnsbl_enable};
  $self->{resolver}->shutdown();
  undef;
}

sub _fh_buffer {
  my ($kernel,$self,$id,$handle) = @_[KERNEL,OBJECT,ARG0,ARG1];
  return unless $self->_conn_exists( $id );
  my $wheel = POE::Wheel::ReadWrite->new(
	Handle => $handle,
	FlushedEvent => '_buffer_flush',
	ErrorEvent => '_buffer_error',
  );
  my $wheel_id = $wheel->ID();
  $self->{clients}->{ $id }->{buffer} = $wheel_id;
  $self->{buffers}->{ $wheel_id } = { wheel => $wheel, id => $id };
  return;
}

sub _buffer_flush {
  my ($self,$wheel_id) = @_[OBJECT,ARG0];
  return unless $self->{buffers}->{ $wheel_id }->{shutdown};
  my $data = delete $self->{buffers}->{ $wheel_id };
  my $id = delete $data->{id};
  $self->send_event( 'smtpd_data_fh', $id );
  return;
}

sub _buffer_error {
  my ($kernel,$self,$error,$wheel_id) = @_[KERNEL,OBJECT,ARG1,ARG3];
  return;
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
    $_ = "smtpd_" . $_ unless /^_/;
    $self->{events}->{$_}->{$sender_id} = $sender_id;
    $self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
    unless ($self->{sessions}->{$sender_id}->{refcnt}++ or $session == $sender) {
      $kernel->refcount_increment($sender_id, __PACKAGE__);
    }
  }

  $kernel->post( $sender, 'smtpd_registered', $self );
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
    $_ = "smtpd_" . $_ unless /^_/;
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
  my $smtpd_id = $self->session_id();
  foreach my $session_id ( keys %{ $self->{sessions} } ) {
     if (--$self->{sessions}->{$session_id}->{refcnt} <= 0) {
        delete $self->{sessions}->{$session_id};
	$poe_kernel->refcount_decrement($session_id, __PACKAGE__) 
		unless ( $session_id eq $smtpd_id );
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

  return 1 if $self->_pluggable_process( 'SMTPD', $event, \( @args ), \@extra_args ) == PLUGIN_EAT_ALL;

  push @args, @extra_args if scalar @extra_args;

  $sessions{$_} = $_ for (values %{$self->{events}->{'smtpd_all'}}, values %{$self->{events}->{$event}});

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

  return 1 if $self->_pluggable_process( 'SMTPC', 'response', $id, \$output ) == PLUGIN_EAT_ALL;

  return unless $self->_conn_exists( $id ) and defined $self->{clients}->{ $id }->{wheel};
  $self->{clients}->{ $id }->{wheel}->put($output);
  return 1;
}

sub _check_recipient {
  my $self = shift;
  my $recipient = shift || return;
  foreach my $handler ( @{ $self->{handlers} } ) {
	return $handler if $recipient =~ $handler->{RE};
  }
  return;
}

sub _process_queue {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  return if $self->{paused};
  return if $self->{_smtp_clients} and $self->{_smtp_clients} >= $self->{maxrelay};
  my $item = shift @{ $self->{_mail_queue} };
  $kernel->delay_set( '_process_queue', 120 );
  return unless $item;
  $item->{attempt}++;
  # Process Recipient Handlers here
  if ( $self->{relay} ) {
    $kernel->yield( '_smtp_send_relay', $item );
    return;
  }
  my %domains;
  foreach my $recipient ( @{ $item->{rcpt} } ) {
	if ( my $handler = $self->_check_recipient( $recipient ) ) {
	   $kernel->post( $handler->{'SESSION'}, $handler->{'EVENT'}, $item );
	   next;
	}
	my $host = Email::Address->new(undef,$recipient,undef)->host();
	push @{ $domains{ $host } }, $recipient;
  }
  foreach my $domain ( keys %domains ) {
    my $copy = { %{ $item } };
    $copy->{rcpt} = $domains{ $domain };
    my $response = $self->{resolver}->resolve(
	event   => '_process_dns_mx',
	type    => 'MX',
	host    => $domain,
	context => $copy,
    );
    $kernel->yield( '_process_dns_mx', $response ) if $response;
  }
  return;
}

sub _process_dns_mx {
  my ($kernel,$self,$response) = @_[KERNEL,OBJECT,ARG0];
  my $item = $response->{context};
  unless ( $response->{response} ) {
     if ( time() - $item->{ts} > 345600 ) {
	return;
     }
     push @{ $self->{_mail_queue} }, $item;
     return;
  }
  my @answers = $response->{response}->answer();
  my %mx = map { ( $_->exchange(), $_->preference() ) } 
	   grep { $_->type() eq 'MX' } @answers;
  my @mx = sort { $mx{$a} <=> $mx{$b} } keys %mx;
  push @mx, $response->{host} unless scalar @mx;
  $item->{mx} = \@mx;
  $kernel->yield( '_smtp_send_mx', $item );
  return;
}

sub _smtp_send_mx {
  my ($kernel,$self,$item) = @_[KERNEL,OBJECT,ARG0];
  $item->{count}++;
  my $exchange = shift @{ $item->{mx} };
  push @{ $item->{mx} }, $exchange;
  $self->{_smtp_clients}++;
  POE::Component::Client::SMTP->send(
	From => $item->{from},
	To   => $item->{rcpt},
	Body => $item->{msg},
	Server => $exchange,
	Context => $item,
	Debug => $self->{smtpc_debug},
	Timeout => $self->{time_out} || 300,
	MyHostname => $self->{hostname},
	SMTP_Success => '_smtp_send_success',
	SMTP_Failure => '_smtp_send_failure',
  );
  return;
}

sub _smtp_send_relay {
  my ($kernel,$self,$item) = @_[KERNEL,OBJECT,ARG0];
  $item->{count}++;
  my %auth;
  if ( $self->{relay_user} and $self->{relay_pass} ) {
     $auth{mechanism} = $self->{relay_auth} || 'PLAIN',
     $auth{user} = $self->{relay_user},
     $auth{pass} = $self->{relay_pass},
  }
  $self->{_smtp_clients}++;
  POE::Component::Client::SMTP->send(
	From => $item->{from},
	To   => $item->{rcpt},
	Body => $item->{msg},
	Server => $self->{relay},
	Context => $item,
	Timeout => $self->{time_out} || 300,
	MyHostname => $self->{hostname},
	SMTP_Success => '_smtp_send_success',
	SMTP_Failure => '_smtp_send_failure',
	( scalar keys %auth ? ( Auth => \%auth ) : () ),
  );
  return;
}

sub _smtp_send_success {
  my ($kernel,$self,$item) = @_[KERNEL,OBJECT,ARG0];
  $self->send_event( 'smtpd_send_success', $item->{uid} );
  $kernel->delay_set( '_process_queue', 20 );
  $self->{_smtp_clients}--;
  return;
}

sub _smtp_send_failure {
  my ($kernel,$self,$item,$error) = @_[KERNEL,OBJECT,ARG0,ARG1];
  $self->send_event( 'smtpd_send_failed', $item->{uid}, $error );
  $self->{_smtp_clients}--;
  if ( $error->{SMTP_Server_Error} and $error->{SMTP_Server_Error} =~ /^5/ ) {
	return;
  }
  if ( time() - $item->{ts} > 345600 ) {
	return;
  }
  push @{ $self->{_mail_queue} }, $item;
  $kernel->delay_set( '_process_queue', 20 );
  return;
}

sub SMTPD_connection {
  my ($self,$smtpd) = splice @_, 0, 2;
  my $id = ${ $_[0] };
  my $peeraddr = ${ $_[1] };
  return PLUGIN_EAT_NONE unless $self->{handle_connects};
  unless ( $self->{dnsbl_enable} ) {
     $self->send_to_client( $id, join( ' ', '220', $self->{hostname}, $self->{version}, 'ready' ) );
  }
  else {
     $self->{_dnsbl}->lookup( session => $self->{session_id}, event => '_dnsbl', address => $peeraddr, _id => $id );
  }
  return PLUGIN_EAT_NONE;
}

sub _dnsbl {
  my ($kernel,$self,$data) = @_[KERNEL,OBJECT,ARG0];
  my $id = delete $data->{_id};
  delete $data->{$_} for qw(event session);
  my $to_client = join ' ', '220', $self->{hostname}, $self->{version}, 'ready';
  if ( $data->{error} ) {
     $self->{clients}->{ $id }->{dnsbl} = 'NXDOMAIN';
  }
  else {
     $self->{clients}->{ $id }->{dnsbl} = $data->{response};
     $to_client = '554 No SMTP service here' if $data->{response} ne 'NXDOMAIN';
  }
  $self->send_to_client( $id, $to_client );
  $self->_send_event( 'smtpd_dnsbl', $id, $to_client, $data );
  return;
}

sub _sender_verify {
  my ($kernel,$self,$data) = @_[KERNEL,OBJECT,ARG0];
  return if $data->{error} and $data->{error} eq 'NOERROR';
  my $id = delete $data->{context};
  $self->{clients}->{ $id }->{fverify} = $data->{error};
  return;
}

sub SMTPD_cmd_helo {
  my ($self,$smtpd) = splice @_, 0, 2;
  return PLUGIN_EAT_NONE unless $self->{simple};
  my $id = ${ $_[0] };
  $self->send_to_client( $id, '250 OK' );
  return PLUGIN_EAT_ALL;
}

sub SMTPD_cmd_ehlo {
  my ($self,$smtpd) = splice @_, 0, 2;
  return PLUGIN_EAT_NONE unless $self->{simple};
  my $id = ${ $_[0] };
  $self->send_to_client( $id, '250 ' . $self->{hostname} . ' Hello [' . $self->{clients}->{ $id }->{peeraddr} . '], pleased to meet you' );
  return PLUGIN_EAT_ALL;
}

sub SMTPD_cmd_mail {
  my ($self,$smtpd) = splice @_, 0, 2;
  return PLUGIN_EAT_NONE unless $self->{simple};
  my $id = ${ $_[0] };
  my $args = ${ $_[1] };
  my $response;
  if ( $self->{dnsbl_enable} and ( !$self->{clients}->{ $id }->{dnsbl} or $self->{clients}->{ $id }->{dnsbl} ne 'NXDOMAIN' ) ) {
     $response = '503 bad sequence of commands';
  }
  elsif ( $self->{clients}->{ $id }->{mail} ) {
     $response = '503 Sender already specified';
  }
  elsif ( my ($from) = $args =~ /^from:\s*<(.+)>/i ) {
     $response = "250 <$from>... Sender OK";
     $self->{clients}->{ $id }->{mail} = $from;
     if ( $self->{sender_verify} ) {
        my $host = Email::Address->new(undef,$from,undef)->host();
        my $response = $self->{resolver}->resolve(
	        event   => '_sender_verify',
	        type    => 'MX',
	        host    => $host,
	        context => $id,
        );
        $poe_kernel->post( $self->{session_id}, '_sender_verify', $response ) if $response;
     }
  }
  else {
     $args = '' unless $args;
     $response = "501 Syntax error in parameters scanning '$args'";
  }
  $self->send_to_client( $id, $response );
  return PLUGIN_EAT_ALL;
}

sub SMTPD_cmd_rcpt {
  my ($self,$smtpd) = splice @_, 0, 2;
  return PLUGIN_EAT_NONE unless $self->{simple};
  my $id = ${ $_[0] };
  my $args = ${ $_[1] };
  my $response;
  if ( !$self->{clients}->{ $id }->{mail} ) {
     $response = '503 Need MAIL before RCPT';
  }
  elsif ( $self->{sender_verify} and defined $self->{clients}->{ $id }->{fverify} ) {
     my $fverify = uc $self->{clients}->{ $id }->{fverify};
     if ( $fverify eq 'NXDOMAIN' ) {
       $response = '550 Sender verify failed';
     }
     else {
       $response = '451 Temporary local problem - please try later';
     }
     delete $self->{clients}->{ $id }->{mail};
     delete $self->{clients}->{ $id }->{rcpt};
     delete $self->{clients}->{ $id }->{buffer};
     delete $self->{clients}->{ $id }->{fverify};
     $self->_send_event( 'smtpd_fverify', $id, $response, $fverify );
  }
  elsif ( my ($to) = $args =~ /^to:\s*<(.+)>/i ) {
     # TODO scan through $self->{domains} and reject as necessary.
     unless ( $self->_recipient_domain( $to ) ) {
	$response = "550 #5.1.0 Address rejected $to";
     }
     else {
	$response = "250 <$to>... Recipient OK";
	push @{ $self->{clients}->{ $id }->{rcpt} }, $to;
     }
  }
  else {
     $args = '' unless $args;
     $response = "501 Syntax error in parameters scanning '$args'";
  }
  $self->send_to_client( $id, $response );
  return PLUGIN_EAT_ALL;
}

sub _recipient_domain {
  my $self = shift;
  return 1 unless scalar @{ $self->{domains} };
  my $address = shift || return;
  my $hostpart = ( split /\@/, $address )[-1];
  return unless $hostpart;
  return 1 if grep { uc $_ eq uc $hostpart } @{ $self->{domains} };
  return 0;
}

sub SMTPD_cmd_data {
  my ($self,$smtpd) = splice @_, 0, 2;
  return PLUGIN_EAT_NONE unless $self->{simple};
  my $id = ${ $_[0] };
  my $response;
  if ( !$self->{clients}->{ $id }->{mail} ) {
     $response = '503 Need MAIL command';
  }
  elsif ( !$self->{clients}->{ $id }->{rcpt} ) {
     $response = '503 Need RCPT (recipient)';
  }
  elsif ( $self->{sender_verify} and defined $self->{clients}->{ $id }->{fverify} ) {
     my $fverify = uc $self->{clients}->{ $id }->{fverify};
     if ( $fverify eq 'NXDOMAIN' ) {
       $response = '550 Sender verify failed';
     }
     else {
       $response = '451 Temporary local problem - please try later';
     }
     delete $self->{clients}->{ $id }->{mail};
     delete $self->{clients}->{ $id }->{rcpt};
     delete $self->{clients}->{ $id }->{buffer};
     delete $self->{clients}->{ $id }->{fverify};
     $self->_send_event( 'smtpd_fverify', $id, $response, $fverify );
  }
  else {
     $response = '354 Enter mail, end with "." on a line by itself';
     $self->{clients}->{ $id }->{buffer} = [ ];
  }
  $self->send_to_client( $id, $response );
  return PLUGIN_EAT_ALL;
}

sub SMTPD_cmd_noop {
  my ($self,$smtpd) = splice @_, 0, 2;
  return PLUGIN_EAT_NONE unless $self->{simple};
  my $id = ${ $_[0] };
  $self->send_to_client( $id, '250 OK' );
  return PLUGIN_EAT_ALL;
}

sub SMTPD_cmd_expn {
  my ($self,$smtpd) = splice @_, 0, 2;
  return PLUGIN_EAT_NONE unless $self->{simple};
  my $id = ${ $_[0] };
  $self->send_to_client( $id, '502 Command not implemented; unsupported operation (EXPN)' );
  return PLUGIN_EAT_ALL;
}

sub SMTPD_cmd_vrfy {
  my ($self,$smtpd) = splice @_, 0, 2;
  return PLUGIN_EAT_NONE unless $self->{simple};
  my $id = ${ $_[0] };
  $self->send_to_client( $id, '252 Cannot VRFY user, but will accept message for delivery' );
  return PLUGIN_EAT_ALL;
}

sub SMTPD_cmd_rset {
  my ($self,$smtpd) = splice @_, 0, 2;
  return PLUGIN_EAT_NONE unless $self->{simple};
  my $id = ${ $_[0] };
  delete $self->{clients}->{$id}->{$_} for qw(mail rcpt buffer);
  $self->send_to_client( $id, '250 Reset state' );
  return PLUGIN_EAT_ALL;
}

sub SMTPD_message {
  my ($self,$smtpd) = splice @_, 0, 2;
  return PLUGIN_EAT_NONE unless $self->{simple};
  my $id = ${ $_[0] };
  my $from = ${ $_[1] };
  my $rcpt = ${ $_[2] };
  my $buf = ${ $_[3] };
  my $msg_id = Email::MessageID->new( host => $self->{hostname} );
  my $uid = $msg_id->user();
  unshift @{ $buf }, "Message-ID: " . $msg_id->in_brackets()
	  unless grep { /^Message-ID:/i } @{ $buf };
  unshift @{ $buf }, "Received: from Unknown [" . $self->{clients}->{ $id }->{peeraddr} . "] by " . $self->{hostname} . " " . $self->{version} . " with SMTP id $uid; " . strftime("%a, %d %b %Y %H:%M:%S %z", localtime)
    unless $self->{origin};
  $self->send_to_client( $id, "250 $uid Message accepted for delivery" );
  my $email = Email::Simple->new( join "\r\n", @{ $buf } );
  $email->header_set('Received') if $self->{origin};
  my $subject = $email->header('Subject') || '';
  push @{ $self->{_mail_queue} }, { uid => $uid, from => $from, rcpt => $rcpt, msg => $email->as_string, ts => time(), subject => $subject };
  $poe_kernel->post( $self->{session_id}, '_process_queue' );
  $self->send_event( 'smtpd_message_queued', $id, $from, $rcpt, $uid, scalar @{ $buf }, $subject || '' );
  delete $self->{clients}->{$id}->{$_} for qw(mail rcpt buffer);
  return PLUGIN_EAT_ALL;
}

sub enqueue {
  my $self = shift;
  my %item;
  if ( ref $_[0] and ref $_[0] eq 'HASH' ) {
    %item = %{ $_[0] };
  }
  elsif ( ref $_[0] and ref $_[0] eq 'ARRAY' ) {
    %item = @{ $_[0] };
  }
  else {
    %item = @_;
  }
  $item{lc $_} = delete $item{$_} for keys %item;
  return unless $item{from};
  return unless $item{msg};
  return unless $item{rcpt} and ref $item{rcpt} eq 'ARRAY' and scalar @{ $item{rcpt} };
  $item{ts} = time() unless $item{ts} and $item{ts} =~ /^\d+$/;
  $item{uid} = Email::MessageID->new( host => $self->{hostname} )->user() unless $item{uid};
  $item{subject} = '' unless $item{subject};
  push @{ $self->{_mail_queue} }, \%item;
  $poe_kernel->post( $self->{session_id}, '_process_queue' );
  return 1;
}

1;


__END__
=pod

=head1 NAME

POE::Component::Server::SimpleSMTP - A simple to use POE SMTP Server.

=head1 VERSION

version 1.50

=head1 SYNOPSIS

  # A simple SMTP Server 
  use strict;
  use POE;
  use POE::Component::Server::SimpleSMTP;

  my $hostname = 'mymailserver.local';
  my $relay; # specify a smart 'relay' server if required
  
  POE::Component::Server::SimpleSMTP->spawn(
	hostname => $hostname,
	relay    => $relay,
  );

  $poe_kernel->run();
  exit 0;

=head1 DESCRIPTION

POE::Component::Server::SimpleSMTP is a L<POE> component that provides an ease to
use, but fully extensible SMTP mail server, that is reasonably compliant with 
RFC 2821 L<http://www.faqs.org/rfcs/rfc2821.html>.

In its simplest form it provides SMTP services, accepting mail from clients and
either relaying the mail to a smart host for further delivery or delivering the
mail itself by querying DNS MX records.

One may also disable simple functionality and implement one's own SMTP handling 
and mail queuing. This can be done via a POE state interface or via L<POE::Component::Pluggable> plugins.

=for Pod::Coverage   SMTPD_cmd_data
  SMTPD_cmd_ehlo
  SMTPD_cmd_expn
  SMTPD_cmd_helo
  SMTPD_cmd_mail
  SMTPD_cmd_noop
  SMTPD_cmd_rcpt
  SMTPD_cmd_rset
  SMTPD_cmd_vrfy
  SMTPD_connection
  SMTPD_message

=head1 CONSTRUCTOR

=over

=item spawn

Takes a number of optional arguments:

  'alias', set an alias on the component;
  'address', bind the listening socket to a particular address;
  'port', listen on a particular port, default is 25;
  'options', a hashref of POE::Session options;
  'hostname', the name that the server will identify as in 'EHLO';
  'version', change the version string reported in 220 responses;
  'relay', specify a 'smart host' to send received mail to, default is
	   to deliver direct after determining MX records;
  'relay_auth', ESMTP Authentication to use, currently only PLAIN is supported, which is the default;
  'relay_user', the username required for authenticated relay;
  'relay_pass', the password required for authenticated relay;
  'time_out', alter the timeout period when sending emails, default 300 seconds;
  'maxrelay', maximum number of concurrent outgoing emails, defaults to 5;
  'domains', an arrayref of domain/hostnames that we will accept mail for;
  'origin', set to a true value to enable the stripping of Received headers;

These optional arguments can be used to enable your own SMTP handling:

  'simple', set this to a false value and the component will no 
	    longer handle SMTP processing; 
  'handle_connects', set this to a false value to stop the component sending
	    220 responses on client connections;

In simple mode one may also specify recipient handlers. These are regular expressions 
that are applied to each recipient of a recieved email. If a recipient matches the
handler, it is removed from the process queue and dispatched instead to indicated session/event combo.

  'handlers', an arrayref containing hashrefs. Each hashref should contain the keys:

	'match', a regexp to apply;
	'session', The session to send the email to;
	'event', The event to trigger;

You may also enable DNSBL lookups of connecting clients with the following options:

  'dnsbl_enable', set to a true value to enable DNSBL support;
  'dnsbl', set to a DNSBL to query, default is zen.spamhaus.org;

DNSBL support uses L<POE::Component::Client::DNSBL> to make blacklist queries for each 
connecting client. If a client is found in the blacklist, any further interaction with the
client is denied.

You may also enable sender verification, this does a simple C<MX> DNS lookup on the domain of
the email sender. If there is no C<MX> domain record (ie. an C<NXDOMAIN>) then a C<550> is issued.
In the case of a C<SERVFAIL>, a C<451> is issued. In both cases the email transaction is cancelled.

  'sender_verify', set to a true value to enable sender verification;

See OUTPUT EVENTS below for information on what a handler event contains.

Returns a POE::Component::Server::SimpleSMTP object.

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

Send some output to a connected client. First parameter must be a valid client id. Second parameter is a string of text to send.

=item C<data_mode>

Takes one argument a valid client ID. Switches the client connection to data mode for receiving 
an mail message. This should be done in response to a valid DATA command from a client if
you are doing your own SMTP handling.

You will receive an 'smtpd_data' event when the client has finished sending data. See below.

Optionally, you may supply a filehandle as a second argument. Any data received from the client 
will be written to the filehandle. You will receive an 'smtpd_data_fh' event when the client
has finished sending data.

=item C<getsockname>

Access to the L<POE::Wheel::SocketFactory> method of the underlying listening socket.

=item C<get_handlers>

Returns an arrayref of the current handlers.

=item C<set_handlers>

Accepts an arrayref of handler hashrefs ( see spawn() for details ).

=item C<mail_queue>

Returns a list of hashrefs relating to items in the current mail queue ( when in C<simple> mode ).

=item C<pause_queue>

Pauses the processing of the mail queue. Any currently processing emails will be allowed to finish.

=item C<resume_queue>

Resumes the processing of the mail queue.

=item C<paused>

Indicates whether the mail queue is paused or not.

=item C<cancel_message>

Takes one mandatory parameter a msg_id to remove from the mail queue.

=item C<start_listener>

Takes no arguments, start the socket listener if it has stopped for any reason. Will fail if the listener is
already erm listening.

=item C<enqueue>

Takes one argument, a C<hashref> with the following keys and values. Enqueues the item and requests that the
mail queue be processed. Returns undef on failure or 1 on success.

  'from', the email address of the sender (required);
  'rcpt', an arrayref of the email recipients (required);
  'msg', string representation of the email headers and body (required);
  'ts', the unix time representation of the time the email was received (default is now);
  'uid', the Message-ID (default is to generate one for you);

=back

=head1 INPUT EVENTS

These are events that the component will accept:

=over

=item C<register>

Takes N arguments: a list of event names that your session wants to listen for, minus the 'smtpd_' prefix, ( this is 
similar to L<POE::Component::IRC> ). 

Registering for 'all' will cause it to send all SMTPD-related events to you; this is the easiest way to handle it.

=item C<unregister>

Takes N arguments: a list of event names which you don't want to receive. If you've previously done a 'register' for a particular event which you no longer care about, this event will tell the SMTPD to stop sending them to you. (If you haven't, it just ignores you. No big deal).

=item C<shutdown>

Terminates the component. Shuts down the listener and disconnects connected clients.

=item C<send_event>

Sends an event through the component's event handling system. 

=item C<send_to_client>

Send some output to a connected client. First parameter must be a valid client ID. 
Second parameter is a string of text to send.

=item C<start_listener>

Takes no arguments, start the socket listener if it has stopped for any reason. Will fail if the listener is
already erm listening.

=back

=head1 OUTPUT EVENTS

The component sends the following events to registered sessions:

=over

=item C<smtpd_registered>

This event is sent to a registering session. ARG0 is POE::Component::Server::SimpleSMTP
object.

=item C<smtpd_listener_failed>

Generated if the component cannot either start a listener or there is a problem
accepting client connections. ARG0 contains the name of the operation that failed. 
ARG1 and ARG2 hold numeric and string values for $!, respectively.

=item C<smtpd_connection>

Generated whenever a client connects to the component. ARG0 is the client ID, ARG1
is the client's IP address, ARG2 is the client's TCP port. ARG3 is our IP address and
ARG4 is our socket port.

If 'handle_connects' is true ( which is the default ), the component will automatically
send a 220 SMTP response to the client.

=item C<smtpd_disconnected>

Generated whenever a client disconnects. ARG0 is the client ID.

=item C<smtpd_cmd_*>

Generated for each SMTP command that a connected client sends to us. ARG0 is the 
client ID. ARG1 .. ARGn are any parameters that are sent with the command. Check 
the RFC L<http://www.faqs.org/rfcs/rfc2821.html> for details.

If C<simple> is true ( which is the default ), the component deals with client
commands itself.

=item C<smtpd_data>

Generated when a client sends an email.

  ARG0 will be the client ID;
  ARG1 an arrayref of lines sent by the client, stripped of CRLF line endings;

If C<simple> is true ( which is the default ), the component will deal with 
receiving data from the client itself.

=item C<smtpd_data_fh>

Generated when a client sends an email and a filehandle has been provided.

  ARG0 will be the client ID;

If C<simple> is true ( which is the default ), the component will deal with 
receiving data from the client itself.

=item C<smtpd_dnsbl>

Generated when a DNSBL lookup is completed, in C<simple> mode.

  ARG0 will be the client ID;
  ARG1 will be the response sent to the client, either a 220 or 554;
  ARG2 will be a hashref with the following keys:

    'response', the status returned by the DNSBL, it will be NXDOMAIN if the address given was okay;
    'reason', if an address is blacklisted, this may contain the reason;
    'error', if something goes wrong with the DNS lookup the error string will be contained here;
    'dnsbl', the DNSBL that was used for this request;

=item C<smtpd_fverify>

Generated when a sender verification fails, in C<simple> mode.

  ARG0 will be the client ID;
  ARG1 will be the response sent to the client;
  ARG2 will be the DNS error reason;

=back

In C<simple> mode these events will be generated:

=over

=item C<smtpd_message_queued>

Generated whenever a mail message is queued. 

  ARG0 is the client ID;
  ARG1 is the mail from address;
  ARG2 is an arrayref of recipients;
  ARG3 is the email unique idenitifer;
  ARG4 is the number of lines of the message;
  ARG5 is the subject line of the message, if applicable

=item C<smtpd_send_success>

Generated whenever a mail message is successfully delivered.

  ARG0 is the email unique identifier;

=item C<smtpd_send_failed>

Generated whenever a mail message is unsuccessfully delivered. This can be for a variety of reasons. The poco
will attempt to resend the message on non-fatal errors ( such as an explicit denial of delivery by the SMTP peer ), for up to 4 days.

  ARG0 is the email unique identifier;
  ARG1 is a hashref as returned by POE::Component::Client::SMTP via 'SMTP_Failure'

=back

Handler events are generated whenever a recipient matches a given regexp. ARG0 will 
contain a hashref representing the email item with the following keys:

  'uid', the Message-ID;
  'from', the email address of the sender;
  'rcpt', an arrayref of the email recipients;
  'msg', string representation of the email headers and body;
  'ts', the unix time representation of the time the email was received;

=head1 PLUGINS

POE::Component::Server::SimpleSMTP utilises L<POE::Component::Pluggable> to enable a
L<POE::Component::IRC> type plugin system. 

=head2 PLUGIN HANDLER TYPES

There are two types of handlers that can registered for by plugins, these are 

=over

=item C<SMTPD>

These are the 'smtpd_' prefixed events that are generated. In a handler arguments are
passed as scalar refs so that you may mangle the values if required.

=item C<SMTPC>

These are generated whenever a response is sent to a client. Again, any 
arguments passed are scalar refs for manglement. There is really on one type
of this handler generated 'SMTPC_response'

=back

=head2 PLUGIN EXIT CODES

Plugin handlers should return a particular value depending on what action they wish
to happen to the event. These values are available as constants which you can use 
with the following line:

  use POE::Component::Server::SimpleSMTP::Constants qw(:ALL);

The return values have the following significance:

=over

=item C<SMTPD_EAT_NONE>

This means the event will continue to be processed by remaining plugins and
finally, sent to interested sessions that registered for it.

=item C<SMTP_EAT_CLIENT>

This means the event will continue to be processed by remaining plugins but
it will not be sent to any sessions that registered for it. This means nothing
will be sent out on the wire if it was an SMTPC event, beware!

=item C<SMTPD_EAT_PLUGIN>

This means the event will not be processed by remaining plugins, it will go
straight to interested sessions.

=item C<SMTPD_EAT_ALL>

This means the event will be completely discarded, no plugin or session will see it. This
means nothing will be sent out on the wire if it was an SMTPC event, beware!

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
plugins of the same kind active in one POE::Component::Server::SimpleSMTP object.

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
  The type of the hook, SMTPD or SMTPC
  The event name(s) to watch

The event names can be as many as possible, or an arrayref. They correspond
to the prefixed events and naturally, arbitrary events too.

You do not need to supply events with the prefix in front of them, just the names.

It is possible to register for all events by specifying 'all' as an event.

Returns 1 if everything checked out fine, undef if something's seriously wrong

=item C<plugin_unregister>

Accepts the following arguments:

  The plugin object
  The type of the hook, SMTPD or SMTPC
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
        use POE::Component::Server::SimpleSMTP::Constants qw( :ALL );

        # Our constructor
        sub new {
                ...
        }

        # Required entry point for plugins
        sub plugin_register {
                my( $self, $smtpd ) = @_;

                # Register events we are interested in
                $smtpd->plugin_register( $self, 'SMTPD', qw(all) );

                # Return success
                return 1;
        }

        # Required exit point for pluggable
        sub plugin_unregister {
                my( $self, $smtpd ) = @_;

                # Pluggable will automatically unregister events for the plugin

                # Do some cleanup...

                # Return success
                return 1;
        }

        sub _default {
                my( $self, $smtpd, $event ) = splice @_, 0, 3;

                print "Default called for $event\n";

                # Return an exit code
                return SMTPD_EAT_NONE;
        }

=head1 CAVEATS

This module shouldn't be used C<as is>, as a production SMTP server, as the 
message queue is implemented in memory. *ouch*

=head1 TODO

Design a better message queue so that messages are stored on disk.

=head1 KUDOS

George Nistoric for L<POE::Component::Client::SMTP> and L<POE::Filter::Transparent::SMTP>.

Rocco Caputo for L<POE::Component::Client::DNS>

=head1 SEE ALSO

L<POE::Component::Pluggable>

L<POE::Component::Client::DNS>

L<POE::Component::Client::SMTP>

RFC 2821 L<http://www.faqs.org/rfcs/rfc2821.html>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

