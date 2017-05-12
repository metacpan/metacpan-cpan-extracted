package POE::Component::Server::RADIUS;
{
  $POE::Component::Server::RADIUS::VERSION = '1.08';
}

#ABSTRACT: a POE based RADIUS server component

use strict;
use warnings;
use Socket;
use POE;
use Net::Radius::Dictionary;
use Net::Radius::Packet;
use Net::IP::Minimal qw(ip_is_ipv4);

use constant DATAGRAM_MAXLEN => 4096;
use constant RADIUS_PORT => 1812;
use constant ACCOUNTING_PORT => 1813;
use constant RADIUS_PORT_OLD => 1645;
use constant ACCOUNTING_PORT_OLD => 1646;

# Stolen from POE::Wheel. This is static data, shared by all
my $current_id = 0;
my %active_identifiers;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  unless ( ref $opts{dict} and $opts{dict}->isa('Net::Radius::Dictionary') ) {
	warn "No 'dict' object provided, bailing out\n";
	return;
  }
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { shutdown => '_shutdown',
		      accept   => '_command',
		      reject   => '_command',
	   },
	   $self => [qw(_start _get_auth_data _get_acct_data register unregister _req_alarm)],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub _allocate_identifier {
  while (1) {
    last unless exists $active_identifiers{ ++$current_id };
  }
  return $active_identifiers{$current_id} = $current_id;
}

sub _free_identifier {
  my $id = shift;
  delete $active_identifiers{$id};
}

sub session_id {
  return $_[0]->{session_id};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub dictionary {
  return $_[0]->{dict};
}

sub add_client {
  my $self = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  unless ( $opts{name} and $opts{address} and $opts{secret} ) {
    warn "You must provide a 'name' and 'address' and 'secret'\n";
    return;
  }
  unless ( ip_is_ipv4( $opts{address} ) ) {
    warn "'address' must be an IPv4 address\n";
    return;
  }
  if ( $self->{clients}->{ $opts{name} } ) {
    warn "That 'name' already exists\n";
    return;
  }
  if ( grep { $self->{clients}->{$_}->{address} eq $opts{address} } keys %{ $self->{clients} } ) {
    warn "That 'address' already exists\n";
    return;
  }
  $self->{clients}->{ $opts{name} }->{$_} = $opts{$_} for qw(address secret);
  return 1;
}

sub del_client {
  my $self = shift;
  my $value = shift || return;
  if ( $self->{clients}->{ $value } ) {
     delete $self->{clients}->{ $value };
     return 1;
  }
  if ( ip_is_ipv4( $value ) ) {
     foreach my $name ( keys %{ $self->{clients} } ) {
	next unless $self->{clients}->{$name}->{address} eq $value;
	delete $self->{clients}->{$name};
	return 1;
     }
  }
  return;
}

sub _validate_client {
  my $self = shift;
  my $client = shift || return;
  foreach my $name ( keys %{ $self->{clients} } ) {
     next unless $self->{clients}->{$name}->{address} eq $client;
     return $self->{clients}->{$name}->{secret};
  }
  return;
}

sub authports {
  my $self = shift;
  return map { ( sockaddr_in( getsockname $_ ) )[0] } @{ $self->{_authsocks} };
}

sub acctports {
  my $self = shift;
  return map { ( sockaddr_in( getsockname $_ ) )[0] } @{ $self->{_acctsocks} };
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  $kernel->alias_set( $self->{alias} ) if $self->{alias};
  $kernel->refcount_increment($self->{session_id}, __PACKAGE__) unless $self->{alias};
  my @authports; my @acctports;
  push @authports, $self->{authport} if defined $self->{authport};
  push @acctports, $self->{acctport} if defined $self->{acctport};
  unless ( defined $self->{authport} ) {
     push @authports, RADIUS_PORT;
     push @authports, RADIUS_PORT_OLD if $self->{legacy};
  }
  unless ( defined $self->{acctport} ) {
     push @acctports, ACCOUNTING_PORT;
     push @acctports, ACCOUNTING_PORT_OLD if $self->{legacy};
  }
  my $proto = getprotobyname('udp');
  foreach my $port ( @authports ) {
     my $paddr = sockaddr_in($port, INADDR_ANY);
     socket( my $socket, PF_INET, SOCK_DGRAM, $proto);
     bind( $socket, $paddr);
     push @{ $self->{_authsocks} }, $socket;
     $kernel->select_read( $socket, '_get_auth_data' );
  }
  foreach my $port ( @acctports ) {
     my $paddr = sockaddr_in($port, INADDR_ANY);
     socket( my $socket, PF_INET, SOCK_DGRAM, $proto);
     bind( $socket, $paddr);
     push @{ $self->{_acctsocks} }, $socket;
     $kernel->select_read( $socket, '_get_acct_data' );
  }
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement($self->{session_id}, __PACKAGE__) unless $self->{alias};
  $kernel->select_read( $_ ) for @{ $self->{_authsocks} };
  $kernel->select_read( $_ ) for @{ $self->{_acctsocks} };
  delete $self->{_authsocks}; delete $self->{_acctsocks};
  delete $self->{_requests};
  $kernel->refcount_decrement( $_, __PACKAGE__ ) for keys %{ $self->{sessions} };
  return;
}

sub _get_auth_data {
  my ($kernel,$self,$socket) = @_[KERNEL,OBJECT,ARG0];
  my $remote_address = recv( $socket, my $message = '', 4096, 0 );
  # Check remote_address is valid
  my $client = inet_ntoa( ( sockaddr_in $remote_address )[1] );
  my $secret = $self->_validate_client( $client );
  return unless $secret;
  my $p = Net::Radius::Packet->new( $self->{dict}, $message );
  # Check $p is valid
  return unless $p->code eq 'Access-Request';
  my $data = {
     map { ( $_, $p->attr($_) ) } $p->attributes()
  };
  $data->{'User-Password'} = $p->password( $secret ) if $data->{'User-Password'};
  my $req_id = _allocate_identifier();
  $self->{_requests}->{ $req_id } = {
	identifier => $p->identifier,
	authenticator => $p->authenticator,
	from => $remote_address,
	client => $client,
	secret => $secret,
	socket => $socket,
  };
  # dispatch to interested sessions
  $kernel->post( $_, $self->{sessions}->{$_}->{authevent}, $client, $data, $req_id, $p )
	for grep { $self->{sessions}->{$_}->{authevent} } keys %{ $self->{sessions} };
  # set an alarm
  $self->{_requests}->{ $req_id }->{alarm_id} = 
	$kernel->delay_set( '_req_alarm', $self->{timeout} || 10, $req_id );
  return;
}

sub _req_alarm {
  my ($kernel,$self,$req_id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->{_requests}->{ $req_id };
  delete $self->{_requests}->{ $req_id };
  _free_identifier( $req_id );
  return;
}

sub _get_acct_data {
  my ($kernel,$self,$socket) = @_[KERNEL,OBJECT,ARG0];
  my $remote_address = recv( $socket, my $message = '', 4096, 0 );
  # Check remote_address is valid
  my $client = inet_ntoa( ( sockaddr_in $remote_address )[1] );
  my $secret = $self->_validate_client( $client );
  return unless $secret;
  return unless auth_acct_verify( $message, $secret );
  my $p = Net::Radius::Packet->new( $self->{dict}, $message );
  # Check $p is valid
  return unless $p->code eq 'Accounting-Request';
  my $data = {
     map { ( $_, $p->attr($_) ) } $p->attributes()
  };
  # dispatch to interested sessions
  $kernel->post( $_, $self->{sessions}->{$_}->{acctevent}, $client, $data, $p )
	for grep { $self->{sessions}->{$_}->{acctevent} } keys %{ $self->{sessions} };
  my $rp = Net::Radius::Packet->new( $self->{dict} );
  $rp->set_identifier($p->identifier);
  $rp->set_authenticator($p->authenticator);
  $rp->set_code('Accounting-Response');
  my $reply = auth_resp( $rp->pack, $secret );
  warn "Problem sending packet to '$client'\n" unless
	send( $socket, $reply, 0, $remote_address ) == length($reply);
  return;
}

sub _command {
  my ($kernel,$self,$state,$req_id) = @_[KERNEL,OBJECT,STATE,ARG0];
  my %args;
  if ( ref $_[ARG1] eq 'HASH' ) {
    %args = %{ $_[ARG1] };
  }
  elsif ( ref $_[ARG1] eq 'ARRAY' ) {
    %args = @{ $_[ARG1] };
  }
  else {
    %args = @_[ARG1..$#_];
  }
  return unless $self->{_requests}->{ $req_id };
  my $req = delete $self->{_requests}->{ $req_id };
  _free_identifier( $req_id );
  $kernel->alarm_remove( $req->{alarm_id} );
  my $code;
  $code = 'Access-Accept' if $state eq 'accept';
  $code = 'Access-Reject' if $state eq 'reject';
  my $rp = Net::Radius::Packet->new( $self->{dict} );
  $rp->set_identifier( $req->{identifier} );
  $rp->set_authenticator( $req->{authenticator} );
  $rp->set_code( $code );
  $rp->set_attr( $_, $args{$_} ) for keys %args;
  my $reply = auth_resp( $rp->pack, $req->{secret} );
  warn "Problem sending packet to '$req->{client}'\n" unless
	send( $req->{socket}, $reply, 0, $req->{from} ) == length($reply);
  return;
}

sub register {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  my $sender_id = $sender->ID();
  my %args;
  if ( ref $_[ARG0] eq 'HASH' ) {
    %args = %{ $_[ARG0] };
  }
  elsif ( ref $_[ARG0] eq 'ARRAY' ) {
    %args = @{ $_[ARG0] };
  }
  else {
    %args = @_[ARG0..$#_];
  }
  $args{lc $_} = delete $args{$_} for keys %args;
  unless ( $args{authevent} or $args{acctevent} ) {
    warn "You must specify either 'authevent' or 'acctevent' arguments\n";
    return;
  }
  if ( defined $self->{sessions}->{ $sender_id } ) {
    $self->{sessions}->{ $sender_id } = \%args;
  }
  else {
    $self->{sessions}->{ $sender_id } = \%args;
    $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  }
  return;
}

sub unregister {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  my $sender_id = $sender->ID();
  my %args;
  if ( ref $_[ARG0] eq 'HASH' ) {
    %args = %{ $_[ARG0] };
  }
  elsif ( ref $_[ARG0] eq 'ARRAY' ) {
    %args = @{ $_[ARG0] };
  }
  else {
    %args = @_[ARG0..$#_];
  }
  $args{lc $_} = delete $args{$_} for keys %args;
  my $data = delete $self->{sessions}->{ $sender_id };
  $kernel->refcount_decrement( $sender_id, __PACKAGE__ ) if $data;
  return;
}

1;

__END__

=pod

=head1 NAME

POE::Component::Server::RADIUS - a POE based RADIUS server component

=head1 VERSION

version 1.08

=head1 SYNOPSIS

   use strict;
   use Net::Radius::Dictionary;
   use POE qw(Component::Server::RADIUS);

   # Lets define some users who we'll allow access if they can provide the password
   my %users = (
           aj => '0fGbqzu0cfA',
           clippy => 'D)z5gcjex1fB',
           cobb => '3ctPbe,cyl8K',
           crudpuppy => '0"bchMltV7dz',
           cthulhu => 'pn}Vbe0Dwr5z',
           matt => 'dyQ4sZ^x0eta',
           mike => 'iRr3auKbv8l>',
           mrcola => 'ynj4H?jec1Ol',
           tanya => 'korvS2~Rip4f',
           tux => 'Io2obo2kT%xq',
   );

   # We need a Net::Radius::Dictionary object to pass to the poco
   my $dict = Net::Radius::Dictionary->new( 'dictionary' );

   my $radiusd = POE::Component::Server::RADIUS->spawn( dict => $dict );

   # Add some NAS devices to the poco
   $radiusd->add_client( name => 'creosote', address => '192.168.1.73', secret => 'Po9hpbN^nz6n' );
   $radiusd->add_client( name => 'dunmanifestin', address => '192.168.1.17', secret => '9g~dorQuos5E' );
   $radiusd->add_client( name => 'genua', address => '192.168.1.71', secret => 'Qj8zmmr3hZb,' );
   $radiusd->add_client( name => 'ladysybilramkin', address => '192.168.1.217', secret => 'j8yTuBfl)t2s' );
   $radiusd->add_client( name => 'mort', address => '192.168.1.229', secret => '8oEhfKm(krr0' );
   $radiusd->add_client( name => 'ysabell', address => '192.168.1.84', secret => 'i8quDld_2suH' );

   POE::Session->create(
      package_states => [
	        'main' => [qw(_start _authenticate _accounting)],
      ],
      heap => { users => \%users, },
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     # We need to register with the poco to receive events
     $poe_kernel->post(
	    $radiusd->session_id(),
	    'register',
	    authevent => '_authenticate',
	    acctevent => '_accounting'
     );
     return;
   }

   sub _authenticate {
     my ($kernel,$sender,$heap,$client,$data,$req_id) = @_[KERNEL,SENDER,HEAP,ARG0,ARG1,ARG2];
     # Lets ignore dodgy requests
     return unless $data->{'User-Name'} and $data->{'User-Password'};
     # Send a reject if the username doesn't exist
     unless ( $heap->{users}->{ $data->{'User-Name'} } ) {
        $kernel->call( $sender, 'reject', $req_id );
        return;
     }
     # Does the password match? If not send a reject
     unless ( $heap->{users}->{ $data->{'User-Name'} } eq $data->{'User-Password'} ) {
        $kernel->call( $sender, 'reject', $req_id );
        return;
     }
     # Okay everything is cool.
     $kernel->call( $sender, 'accept', $req_id );
     return;
   }

   sub _accounting {
     my ($kernel,$sender,$heap,$client,$data) = @_[KERNEL,SENDER,HEAP,ARG0,ARG1];
     # Do something with the data provided, like log to a database or a file
     return;
   }

=head1 DESCRIPTION

POE::Component::Server::RADIUS is a L<POE> component that provides Remote Authentication Dial In User Service (RADIUS) server
services to other POE sessions and components.

RADIUS is commonly used by ISPs and corporations managing access to Internet or internal networks and is
an AAA (authentication, authorisation, and accounting) protocol.

The component deals with the receiving and transmission of RADIUS packets and uses the excellent L<Net::Radius::Packet>
and L<Net::Radius::Dictionary> modules to construct the RADIUS packets.

Currently only PAP authentication is supported. Help and advice would be appreciated on implementing others. See contact details
below.

The component does not deal with the actual authentication of users nor with the logging of accounting data. That is the job
of other sessions which register with the component to receive events.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Creates a new POE::Component::Server::RADIUS session that starts various UDP sockets. Takes one mandatory and a number of optional parameters:

  'dict', a Net::Radius::Dictionary object reference, mandatory;
  'alias', set an alias that you can use to address the component later;
  'options', a hashref of POE session options;
  'authport', specify a port to listen on for authentication requests;
  'acctport', specify a port to listen on for accounting requests;
  'legacy', set to a true value to make the component honour legacy listener ports;
  'timeout', set a time out in seconds that the poco waits for sessions to respond to auth requests,
	     default 10;

By default the component listens on ports C<1812> and C<1813> for authentication and accounting requests, respectively. These are
the C<official> ports from the applicable RFCs. Setting C<legacy> option makes the component also listen on ports C<1645> and
C<1646>.

Returns a POE::Component::Server::RADIUS object, which provides the following methods:

=back

=head1 METHODS

=over

=item C<add_client>

Adds a RADIUS client to the server configuration. RADIUS clients need to be registered with their IP address and a shared secret.
Takes a number of required parameters:

  'name', a unique reference name;
  'address', an IPv4 address;
  'secret', a shared secret pass-phrase;

=item C<del_client>

Removes a previously registered RADIUS client. Takes one argument, either a C<name> or an IPv4 address.

=item C<session_id>

Takes no arguments. Returns the POE Session ID of the component.

=item C<shutdown>

Terminates the component.

=item C<authports>

Returns a list of all the UDP ports configured for authentication requests.

=item C<acctports>

Returns a list of all the UDP ports configured for accounting requests.

=item C<dictionary>

Returns a reference to the L<Net::Radius::Dictionary> object that was supplied to C<spawn>.

=back

=head1 INPUT EVENTS

These are events that the component will accept:

=over

=item C<register>

This will register the sending session to receive events from the component. It requires either one of the following parameters. You
may specify both if you require:

  'authevent', event in your session that will be triggered for authentication requests;
  'acctevent', event in your session that will be triggered for accounting requests;

The component automatically responds to accounting requests.

Authentication requests require your session to send either an C<accept> or C<reject> response back to the component.

=item C<accept>

Tells the component to send an C<Access-Accept> response back to the requesting client. Requires one mandatory argument which is
a request_id previously given you by the component (See OUTPUT EVENTS for details). The remaining parameters are assumed to be
RADIUS attributes that you want adding to the C<Access-Accept> response. Check with the RFC for what attributes are valid.

=item C<reject>

Tells the component to send an C<Access-Reject> response back to the requesting client. Requires one mandatory argument which is
a request_id previously given you by the component (See OUTPUT EVENTS for details). The remaining parameters are assumed to be
RADIUS attributes that you want adding to the C<Access-Reject> response. Check with the RFC for what attributes are valid.

=item C<unregister>

This will unregister the sending session from receiving events.

=item C<shutdown>

Terminates the component.

=back

=head1 OUTPUT EVENTS

Dependent on which event types your session registered with the component to receive, you will get either one or the other of these
or both.

=over

=item C<acctevent> type events

ARG0 will be the IP address of the RADIUS client. The component will have already discarded accounting requests from clients
which don't have a matching IP address and shared-secret. ARG1 will be hashref containing RADIUS attributes and value pairs.
ARG2 will be a L<Net::Radius::Packet> object representing the request.

As the component automatically responds to valid clients with an C<Accounting-Response> packet, your session need not take any
further action in response to these events.

=item C<authevent> type events

ARG0 will be the IP address of the RADIUS client. The component will have already 'decrypted' the C<User-Password> provided using
the configured shared-secret for the RADIUS client. ARG1 will be a hashref containing RADIUS attributes and value pairs. ARG3 will
be a unique request_id required when sending C<accept> or C<reject> events back to the component. ARG4 will be a
L<Net::Radius::Packet> object representing the request.

You must check the validity of the request and then issue either an C<accept> or C<reject> event back to the component using the
request_id and specifying any RADIUS attributes that you wish conveyed to the client.

The component times out authentication requests to prevent stale requests. This timeout is configurable through the C<spawn> constructor.

To get timely responses back to RADIUS clients it is suggested that you use C<call> instead of C<post> to send
C<accept> or C<reject> events back to the component.

=back

=head1 SEE ALSO

L<POE>

L<http://en.wikipedia.org/wiki/RADIUS>

L<http://www.faqs.org/rfcs/rfc2138.html>

L<http://www.faqs.org/rfcs/rfc2866.html>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
