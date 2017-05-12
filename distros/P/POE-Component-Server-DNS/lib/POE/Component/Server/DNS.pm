package POE::Component::Server::DNS;
$POE::Component::Server::DNS::VERSION = '0.32';
#ABSTRACT: A non-blocking, concurrent DNS server POE component

use strict;
use warnings;
use POE qw(Component::Client::DNS Wheel::ReadWrite Component::Client::DNS::Recursive Wheel::SocketFactory Filter::DNS::TCP);
use Socket;
use Net::DNS::RR;
use IO::Socket::INET;

sub spawn {
  my $package = shift;
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;

  my $options = delete $args{options};

  my $self = bless \%args, $package;

  $self->{_handlers} = [ ];

  unless ( $self->{no_clients} ) {
      $self->{_localhost} = Net::DNS::RR->new('localhost. 0 A 127.0.0.1');
  }

  $self->{session_id} = POE::Session->create(
	object_states => [
		$self => { shutdown => '_shutdown', _sock_err_tcp => '_sock_err', },
		$self => [ qw(_start _dns_incoming _dns_err _dns_response _dns_recursive add_handler del_handler _handled_req _sock_up _sock_err log_event _sock_up_tcp) ],
	],
	heap => $self,
	options => ( $options && ref $options eq 'HASH' ? $options : { } ),
  )->ID();

  return $self;
}

sub _start {
  my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];

  $self->{session_id} = $session->ID();

  if ( $self->{alias} ) {
     $kernel->alias_set($self->{alias});
  }
  else {
     $kernel->alias_set("$self");
     $self->{alias} = "$self";
  }

  unless ( $self->{no_clients} ) {
      $self->{resolver_opts} = { } unless $self->{resolver_opts} and ref $self->{resolver_opts} eq 'HASH';
      delete $self->{resolver_opts}->{Alias};
      $self->{resolver} = POE::Component::Client::DNS->spawn( Alias => "resolver" . $self->session_id(), %{ $self->{resolver_opts} } );
#      $self->{recursive}->hints( { event => '_hints' } );
  }

  $self->{factory} = POE::Wheel::SocketFactory->new(
	SocketProtocol => 'udp',
	BindAddress => $self->{address} || INADDR_ANY,
	BindPort => ( defined $self->{port} ? $self->{port} : 53 ),
	SuccessEvent   => '_sock_up',
	FailureEvent   => '_sock_err',
  );

  $self->{factory_tcp} = POE::Wheel::SocketFactory->new(
    SocketProtocol => 'tcp',
    Reuse => 1,
    BindAddress => $self->{address} || INADDR_ANY,
    BindPort => ( defined $self->{port} ? $self->{port} : 53 ),
    SuccessEvent   => '_sock_up_tcp',
    FailureEvent   => '_sock_err_tcp',
  );

  undef;
}

sub _sock_up {
  my ($kernel,$self,$dns_socket) = @_[KERNEL,OBJECT,ARG0];
  $self->{_sockport} = ( sockaddr_in( getsockname($dns_socket) ) )[0];
  delete $self->{factory};
  $self->{dnsrw} = POE::Wheel::ReadWrite->new(
	    Handle => $dns_socket,
	    Driver => DNS::Driver::SendRecv->new(),
	    Filter => DNS::Filter::UDPDNS->new(),
	    InputEvent => '_dns_incoming',
	    ErrorEvent => '_dns_err',
	);
  undef;
}

sub _sock_up_tcp {
  my ($kernel,$self,$dns_socket, $address, $port) = @_[KERNEL,OBJECT,ARG0, ARG1, ARG2];
  $address = inet_ntoa($address);

  POE::Session->create(
	object_states => [
		$self => { _start => '_socket_success', _stop => '_socket_death' },
		$self => [ qw( _sock_err _socket_input _socket_death _handled_req _dns_incoming _dns_recursive _dns_response) ],
	],
    args => [$dns_socket],
    heap => { _tcp_sockport => "$address:$port", },
  );

  undef;
}


sub _socket_death {
  my $heap = $_[HEAP];
  if ($heap->{socket_wheel}) {
    delete $heap->{socket_wheel};
  }
}

sub _socket_success {
  my ($heap,$kernel,$connected_socket) = @_[HEAP, KERNEL, ARG0];

  $heap->{socket_wheel} = POE::Wheel::ReadWrite->new(
        Handle => $connected_socket,
        Filter => POE::Filter::DNS::TCP->new(),
        InputEvent => '_dns_incoming',
        ErrorEvent => '_sock_err',
  );
}

sub _socket_input {
  my ($heap, $buf) = @_[HEAP, ARG0];
  warn Dumper $buf;
  delete $heap->{socket_wheel};
}

sub _sock_err {
  my ($operation, $errnum, $errstr, $wheel_id) = @_[ARG0..ARG3];
  # ErrorEvent may also indicate EOF on a FileHandle by returning operation "read" error 0. For sockets, this means the remote end has closed the connection.
  return undef if ($operation eq "read" and $errnum == 0);
  delete $_[OBJECT]->{factory};
  delete $_[OBJECT]->{"factory_tcp"};
  die "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  undef;
}

sub session_id {
  return $_[0]->{session_id};
}

sub resolver {
  return $_[0]->{resolver};
}

sub sockport {
  return $_[0]->{_sockport};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->session_id() => 'shutdown' );
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list( $_[SESSION] );
  delete $self->{dnsrw};
  delete $self->{'factory'};
  delete $self->{'factory_tcp'};
  unless ( $self->{no_clients} ) {
      $self->{resolver}->shutdown();
      #$self->{recursive}->shutdown();
  }
  $kernel->refcount_decrement( $_->{session}, __PACKAGE__ ) for @{ $self->{_handlers} };
  $kernel->refcount_decrement( $_, __PACKAGE__ ) for keys %{ $self->{_sessions} };
  delete $self->{_handlers};
  undef;
}

sub log_event {
  my ($kernel,$self,$sender,$event) = @_[KERNEL,OBJECT,SENDER,ARG0];
  $sender = $sender->ID();

  if ( exists $self->{_sessions}->{ $sender } and !$event ) {
	delete $self->{_sessions}->{ $sender };
	$kernel->refcount_decrement( $sender => __PACKAGE__ );
	return;
  }

  if ( exists $self->{_sessions}->{ $sender } ) {
	$self->{_sessions}->{ $sender } = $event;
	return;
  }

  $self->{_sessions}->{ $sender } = $event;
  $kernel->refcount_increment( $sender => __PACKAGE__ );
  return;
}

sub add_handler {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  $sender = $sender->ID();

  # Get the arguments
  my $args;
  if (ref($_[ARG0]) eq 'HASH') {
	$args = { %{ $_[ARG0] } };
  }
  else {
	warn "first parameter must be a ref hash, trying to adjust. "
		."(fix this to get rid of this message)";
	$args = { @_[ARG0 .. $#_ ] };
  }

  $args->{ lc $_ } = delete $args->{$_} for keys %{ $args };

  unless ( $args->{label} ) {
	warn "you must supply a label argument, to make it unique\n";
	return;
  }

  if ( grep { $_->{label} eq $args->{label} } @{ $self->{_handlers} } ) {
	warn "you must supply a unique label argument, I already have that one\n";
	return;
  }

  unless ( $args->{event} ) {
	warn "you must supply an event argument, otherwise where do I send the replies to\n";
	return;
  }

  unless ( $args->{match} ) {
	warn "you must supply a match argument, otherwise what's the point\n";
	return;
  }

  my $regex;
  eval { $regex = qr/$args->{match}/ };

  if ( $@ ) {
	warn "The match argument you supplied was fubar, please try harder\n";
	return;
  }
  else {
	$args->{match} = $regex;
  }

  $args->{session} = $sender unless $args->{session};
  if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
	$args->{session} = $ref->ID();
  }
  else {
	$args->{session} = $sender->ID();
  }

  $kernel->refcount_increment( $args->{session}, __PACKAGE__ );

  push @{ $self->{_handlers} }, $args;

  undef;
}

sub del_handler {
  my ($kernel,$self,$label) = @_[KERNEL,OBJECT,ARG0];
  return unless $label;

  my $i = 0; my $rec;
  for ( @{ $self->{_handlers} } ) {
    if ( $_->{label} eq $label ) {
      splice( @{ $self->{_handlers} }, $i, 1 );
      $rec = $_;
      last;
    }
  }

  $kernel->refcount_decrement( $rec->{session}, __PACKAGE__ );
  undef;
}

sub _dns_incoming {
  my($kernel,$self,$heap,$session,$dnsq) = @_[KERNEL,OBJECT,HEAP,SESSION,ARG0];

  # TCP remote address is handled differently than UDP, so fix that here.
  if (defined($heap->{_tcp_sockport})) {
    $dnsq->answerfrom($heap->{_tcp_sockport});
  }

  my($q) = $dnsq->question();
  return unless $q;

  foreach my $handler ( @{ $self->{_handlers} } ) {
	next unless $q->qname =~ $handler->{match};
	my $callback = $session->callback( '_handled_req', $dnsq );
	$kernel->post(
			$handler->{session},
			$handler->{event},
			$q->qname,
			$q->qclass,
			$q->qtype,
			$callback,
			$dnsq->answerfrom, $dnsq, $handler->{'label'} );
	return;
  }

  if ( $self->{no_clients} ) {
    # Refuse unhandled requests, like an authoritative-only
    #  BIND server would.
    $dnsq->header->rcode('REFUSED');
    $dnsq->header->qr(1);
    $dnsq->header->aa(0);
    $dnsq->header->ra(0);
    $dnsq->header->ad(0);
    my $str = $dnsq->string(); # Doesn't work without this, fucked if I know why.
    $self->_dispatch_log( $dnsq );
	#  $self->{dnsrw}->put( $dnsq ) if $self->{dnsrw};
    $self->{"dnsrw"}->put( $dnsq ) if (!(defined($heap) && defined($heap->{socket_wheel})) && $self->{"dnsrw"});
    $heap->{socket_wheel}->put($dnsq) if $heap->{socket_wheel};

    return;
  }

  if ( $q->qname =~ /^localhost\.*$/i ) {
	$dnsq->push( answer => $self->{_localhost} );
	$self->_dispatch_log( $dnsq );
    $self->{"dnsrw"}->put( $dnsq ) if (!(defined($heap) && defined($heap->{socket_wheel})) && $self->{"dnsrw"});
	$heap->{socket_wheel}->put($dnsq) if $heap->{socket_wheel};
	return;
  }

  if ( $self->{forward_only} ) {
    my %query = (
      class   => $q->qclass,
      type    => $q->qtype,
      host    => $q->qname,
      context => [ $dnsq->answerfrom, $dnsq->header->id ],
      event   => '_dns_response',
    );

    my $response = $self->{resolver}->resolve( %query );
    $kernel->yield( '_dns_response', $response ) if $response;

  }
  else {
#    $self->{recursive}->query_dorecursion( { event => '_dns_recursive', data => [ $dnsq, $dnsq->answerfrom, $dnsq->header->id ], }, $q->qname, $q->qtype, $q->qclass );
    POE::Component::Client::DNS::Recursive->resolve(
	event   => '_dns_recursive',
	context => [ $dnsq, $dnsq->answerfrom, $dnsq->header->id ],
	host    => $q->qname,
	type    => $q->qtype,
	class   => $q->qclass,
    );
  }

  undef;
}

sub _handled_req {
  my ($kernel,$self,$passthru,$passback,$heap) = @_[KERNEL,OBJECT,ARG0,ARG1,HEAP];
  my $reply = $passthru->[0];
  my ($rcode, $ans, $auth, $add, $headermask) = @{ $passback };
  $reply->header->rcode($rcode);
  $reply->push("answer",     @$ans)  if $ans;
  $reply->push("authority",  @$auth) if $auth;
  $reply->push("additional", @$add)  if $add;
  if (!defined ($headermask)) {
	$reply->header->ra($self->{no_clients} ? 0 : 1);
	$reply->header->ad(0);
  }
  else {
	$reply->header->aa(1) if $headermask->{'aa'};
	$reply->header->ra(1) if $headermask->{'ra'};
	$reply->header->ad(1) if $headermask->{'ad'};
  }

  $reply->header->qr(1);
  $self->_dispatch_log( $reply );

  $self->{"dnsrw"}->put( $reply ) if (!(defined($heap) && defined($heap->{socket_wheel})) && $self->{"dnsrw"});
  $heap->{socket_wheel}->put($reply) if $heap->{socket_wheel};
  undef;
}

sub _dns_err {
  my($kernel,$self, $op, $errnum, $errstr) = @_[KERNEL,OBJECT, ARG0..ARG2];
  warn "DNS readwrite: $op generated error $errnum: $errstr\n";
  if (!($op eq "read" and ($errnum == 0 ||  $errnum == 104)))
  {
	warn "SHUTDOWN";
	$kernel->yield('shutdown');
  }
  undef;
}

sub _dns_recursive {
  my ($kernel,$heap,$self,$data) = @_[KERNEL,HEAP,OBJECT,ARG0];
  return if $data->{error};
  my ($dnsq,$answerfrom,$id) = @{ $data->{context} };

  my $socket = $heap->{socket_wheel};

  my $response = $data->{response};
  if ( $response ) {
    $response->header->id( $id );
    $response->answerfrom( $answerfrom );
    $self->_dispatch_log( $response );
    $self->{"dnsrw"}->put( $response ) if (!(defined($socket)) && $self->{"dnsrw"});
    $socket->put($response) if $socket;
    return;
  }
  $dnsq->header->rcode('NXDOMAIN');
  $self->_dispatch_log( $dnsq );
#  $self->{dnsrw}->put( $dnsq ) if $self->{dnsrw};
  $self->{"dnsrw"}->put( $dnsq ) if (!(defined($socket)) && $self->{"dnsrw"});
  $socket->put($dnsq) if $socket;

  undef;
}

sub _dns_response {
  my ($kernel,$self,$heap,$reply) = @_[KERNEL,OBJECT,HEAP,ARG0];

  my ($answerfrom,$id) = @{ $reply->{context} };
  my $response = delete $reply->{response};
  $response->header->id( $id );
  $response->answerfrom( $answerfrom );
  $self->_dispatch_log( $response );
  $self->{"dnsrw"}->put( $response ) if (!(defined($heap) && defined($heap->{socket_wheel})) && $self->{"dnsrw"});
  $heap->{socket_wheel}->put($response) if $heap->{socket_wheel};
  undef;
}

sub _dispatch_log {
  my $self = shift;
  my $packet = shift || return;
  my $af = $packet->answerfrom;
  $poe_kernel->post( $_, $self->{_sessions}->{$_}, $af, $packet ) for keys %{ $self->{_sessions} };
  return 1;
}

package DNS::Driver::SendRecv;
$DNS::Driver::SendRecv::VERSION = '0.32';
use strict;
use POE::Driver;
use Socket;

sub new {
    my $class = shift;
    my $self = []; # the output queue
    bless $self, $class;
}

sub get {
    my $self = shift;
    my $fh = shift;

    my @ret;
    while (1) {
        my $from = recv($fh, my $buffer = '', 4096, 0 );
        last if !$from;
        push @ret, [ $from, $buffer ];
    }
    return if !@ret;
    return \@ret;
}

sub put {
    my $self = shift;
    my $data = shift;

    push @$self, @$data;
    my $sum = 0;
    $sum += length( $_->[1] ) for @$self;
    return $sum;
}

sub flush {
    my $self = shift;
    my $fh = shift;

    while ( @$self ) {
        my $n = send($fh, $self->[0][1], 0, $self->[0][0])
            or return;
        $n == length($self->[0][1])
            or die "Couldn't write complete message to socket: $!\n";
        shift @$self;
    }
}

package DNS::Filter::UDPDNS;
$DNS::Filter::UDPDNS::VERSION = '0.32';
use strict;
use POE::Filter;
use Socket;
use Net::DNS::Packet;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub get {
    my $self = shift;
    my $data = shift;

    my @ret;
    for my $d ( @$data ) {
        ref($d) eq "ARRAY"
            or die "UDPDNS filter expected arrayrefs for input\n";
        my($port, $inet) = sockaddr_in($d->[0]);
        my $inetstr = inet_ntoa($inet);
        my($p, $err) = Net::DNS::Packet->new(\$d->[1]);
        if ( !$p ) {
            warn "Cannot create DNS question for packet received from " .
                "$inetstr: $err\n";
        } else {
            $p->answerfrom("$inetstr:$port");
            push @ret, $p;
        }
    }
    return \@ret;
}

sub put {
    my $self = shift;
    my $data = shift;

    my @ret;
    for my $d ( @$data ) {
        my($inetstr, $port) = split /:/, $d->answerfrom();
        $d->{buffer} = ''; #sigh
        if ( !defined $port ) {
            warn "answerfrom not set in DNS packet, no destination known\n";
        } else {
            push @ret,
                [ pack_sockaddr_in($port, inet_aton($inetstr)), $d->data ];
        }
    }
    return \@ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::DNS - A non-blocking, concurrent DNS server POE component

=head1 VERSION

version 0.32

=head1 SYNOPSIS

  use strict;
  use Net::DNS::RR;
  use POE qw(Component::Server::DNS);

  my $dns_server = POE::Component::Server::DNS->spawn( alias => 'dns_server' );

  POE::Session->create(
        package_states => [ 'main' => [ qw(_start handler log) ], ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Tell the component that we want log events to go to 'log'
    $kernel->post( 'dns_server', 'log_event', 'log' );

    # register a handler for any foobar.com suffixed domains
    $kernel->post( 'dns_server', 'add_handler',
	{
	  event => 'handler',
	  label => 'foobar',
	  match => 'foobar\.com$',
        }
    );
    undef;
  }

  sub handler {
    my ($qname,$qclass,$qtype,$callback) = @_[ARG0..ARG3];
    my ($rcode, @ans, @auth, @add);

    if ($qtype eq "A") {
      my ($ttl, $rdata) = (3600, "10.1.2.3");
      push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
      $rcode = "NOERROR";
    } else {
      $rcode = "NXDOMAIN";
    }

    $callback->($rcode, \@ans, \@auth, \@add, { aa => 1 });
    undef;
  }

  sub log {
    my ($ip_port,$net_dns_packet) = @_[ARG0..ARG1];
    $net_dns_packet->print();
    undef;
  }

=head1 DESCRIPTION

POE::Component::Server::DNS is a L<POE> component that implements a DNS server.

It uses L<POE::Component::Client::DNS> to handle resolving when configured as 'forward_only' and
L<Net::DNS::Resolver::Recurse> wrapped by L<POE::Component::Generic> to perform recursion.

One may add handlers to massage and manipulate responses to particular queries which is vaguely modelled
after L<Net::DNS::Nameserver>.

=head1 CONSTRUCTOR

=over

=item spawn

Starts a POE::Component::Server::DNS component session and returns an object. Takes a number of optional arguments:

  "alias", an alias to address the component by;
  "port", which udp port to listen on. Default is 53, which requires 'root' privilege on UN*X type systems;
  "address", which local IP address to listen on.  Default is INADDR_ANY;
  "resolver_opts", a set of options to pass to the POE::Component::Client::DNS constructor;
  "forward_only", be a forwarding only DNS server. Default is 0, be recursive.
  "no_clients", do not spawn client code (See following notes);

"no_clients" disables the spawning of client code (PoCo::Client::DNS, Net::DNS::Resolver::Recursive), and doesn't attempt to forward or recurse inbound requests.  Any request not handled by one of your handlers will be C<REFUSED>.  Saves some resources when you intend your server to be authoritative only (as opposed to a general resolver for DNS client software to point at directly).  Additionally, this argument changes the default "Recursion Available" flag in responses to off instead of on.

=back

=head1 METHODS

These are methods that may be used with the object returned by spawn().

=over

=item session_id

Returns the L<POE::Session> ID of the component's session.

=item resolver

Returns a reference to the L<POE::Component::Client::DNS> object.

=item shutdown

Terminates the component and associated resolver.

=item sockport

Returns the port of the socket that the component is listening on.

=back

=head1 INPUT EVENTS

These are states that the component will accept:

=over

=item add_handler

Accepts a hashref as an argument with the following keys:

  "event", the event the component will post to, mandatory;
  "label", a unique name for this handler, mandatory;
  "match", a regex expression ( without // ) to match against the host part of queries, mandatory;
  "session", the session where this handler event should be sent to, defaults to SENDER;

See OUTPUT EVENTS for details of what happens when a handler is triggered.

=item del_handler

Accepts a handler label to remove.

=item log_event

Tells the component that a session wishes to receive or stop receiving DNS log events. Specify the event you
wish to receive log events as the first argument. If no event is specified you stop receiving log events.

=item shutdown

Terminates the component and associated resolver.

=back

=head1 HANDLER EVENTS

These events are triggered by a DNS query matching a handler. The applicable event is fired in the requested session
with the following paramters:

  ARG0, query name
  ARG1, query class
  ARG2, query type
  ARG3, a callback coderef
  ARG4, the IP address and port of the requestor, 'IPaddr:port'

Do your manipulating then use the callback to fire the response back to the component, returning a
response code and references to the answer, authority, and additional sections of the response. For advanced
usage there is an optional argument containing an hashref with the settings for the aa, ra, and ad header bits.
The argument is of the form { ad => 1, aa => 0, ra => 1 }.

  $callback->( $rcode, \@ans, \@auth, \@add, { aa => 1 } );

=head1 LOG EVENTS

These events are triggered whenever a DNS response is sent to a client.

  ARG0, the IP address and port of the requestor, 'IPaddr:port';
  ARG1, the Net::DNS::Packet object;

See L<Net::DNS::Packet> for details.

=head1 HISTORY

The component's genesis was inspired by Jan-Pieter's 'Fun with POE' talk at YAPC::EU 2006, which lay much of the
ground-work code such as the L<POE::Driver> and L<POE::Filter> used internally. BinGOs wrapped it all up in a
component, added the tests ( borrowed shamelessly from L<POE::Component::Client::DNS>'s testsuite ) and documentation.

Other suggestions as to the API were provided by Ben 'integral' Smith.

Rocco Caputo brought L<POE::Component::Client::DNS> to the party.

=head1 SEE ALSO

L<POE::Component::Client::DNS>

L<POE::Component::Generic>

L<Net::DNS>

L<Net::DNS::Packet>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Jan-Pieter Cornet <johnpc@xs4all.nl>

=item *

Brandon Black <blblack@gmail.com>

=item *

Richard Harman <richard@richardharman.com>

=item *

Stephan Jauernick <stephan@stejau.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Williams, Jan-Pieter Cornet, Brandon Black, Richard Harman and Stephan Jauernick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
