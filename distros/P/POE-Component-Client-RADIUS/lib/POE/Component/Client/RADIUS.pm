package POE::Component::Client::RADIUS;
$POE::Component::Client::RADIUS::VERSION = '1.04';
#ABSTRACT: a flexible POE-based RADIUS client

use strict;
use warnings;
use Carp;
use POE;
use IO::Socket::INET;
use Net::Radius::Dictionary;
use Net::Radius::Packet;
use Math::Random;

use constant DATAGRAM_MAXLEN => 4096;
use constant RADIUS_PORT => 1812;
use constant ACCOUNTING_PORT => 1813;

my $ERROR;
my $ERRNO;

# Stolen from POE::Wheel. This is static data, shared by all
my $current_id = 0;
my %active_identifiers;

sub spawn {
  my $package = shift;
  return $package->_create( 'spawn', @_ );
}

sub authenticate {
  my $self;
  eval {
    if ( (ref $_[0]) && $_[0]->isa(__PACKAGE__) ) {
	$self = shift;
    }
  };
  if ( $self ) {
	$poe_kernel->post( $self->{session_id}, 'authenticate', @_ );
	return 1;
  }
  my $package = shift;
  return $package->_create( 'authenticate', @_ );
}

sub accounting {
  my $self;
  eval {
    if ( (ref $_[0]) && $_[0]->isa(__PACKAGE__) ) {
	$self = shift;
    }
  };
  if ( $self ) {
	$poe_kernel->post( $self->{session_id}, 'accounting', @_ );
	return 1;
  }
  my $package = shift;
  return $package->_create( 'accounting', @_ );
}

sub _create {
  my $package = shift;
  my $command = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for grep { !/^_/ } keys %opts;
  unless ( ref $opts{dict} and $opts{dict}->isa('Net::Radius::Dictionary') ) {
	warn "No 'dict' object provided, bailing out\n";
	return;
  }
  my $options = delete $opts{options};
  my $self = bless { }, $package;
  if ( $command =~ /^a/ ) {
     unless ( $opts{event} ) {
	warn "You must specify 'event' for '$command'\n";
        return;
     }
     unless ( $opts{server} and _ip_is_v4( $opts{server} ) ) {
	warn "You must specify 'server' as a valid IPv4 address\n";
        return;
     }
     unless ( $opts{secret} ) {
	warn "You must specify a 'secret'\n";
	return;
     }
     unless ( $opts{attributes} and ref $opts{attributes} eq 'HASH' ) {
	warn "You must specify 'attributes' as a hashref of RADIUS attributes\n";
        return;
     }
     if ( $command eq 'authenticate' and !( $opts{username} and $opts{password} ) ) {
	warn "You must specify 'username' and 'password' for 'authenticate'\n";
	return;
     }
     if ( $command eq 'accounting' and !$opts{type} ) {
	warn "You must specify 'type' for an accounting request\n";
	return;
     }
     $opts{port} = RADIUS_PORT if $command eq 'authenticate' and !$opts{port};
     $opts{port} = ACCOUNTING_PORT if $command eq 'accounting' and !$opts{port};
  }
  $self->{session_id} = POE::Session->create(
     object_states => [
	$self => { shutdown => '_shutdown',
		   authenticate => '_command',
		   accounting   => '_command', },
	$self => [qw(_start _create_socket _dispatch _get_datagram _sock_timeout)],
     ],
     heap => $self,
     args => [ $command, %opts ],
     ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub _allocate_identifier {
  while (1) {
    ++$current_id;
    $current_id = 1 if $current_id > 255;
    last unless exists $active_identifiers{ $current_id };
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

sub _start {
  my ($kernel,$self,$sender,$command,@args) = @_[KERNEL,OBJECT,SENDER,ARG0..$#_];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $command eq 'spawn' ) {
     my $opts = { @args };
     $self->{$_} = $opts->{$_} for keys %{ $opts };
     $kernel->alias_set($self->{alias}) if $self->{alias};
     $kernel->refcount_increment($self->{session_id}, __PACKAGE__) unless $self->{alias};
     return;
  }
  if ( $kernel == $sender ) {
	croak "'authenticate' and 'accounting' should be called from another POE Session\n";
  }
  $self->{sender_id} = $sender->ID();
  $kernel->refcount_increment( $self->{sender_id}, __PACKAGE__ );
  $kernel->yield( $command, @args );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  return;
}

sub _command {
  my ($kernel,$self,$state,$session,$sender) = @_[KERNEL,OBJECT,STATE,SESSION,SENDER];
  my $args;
  if ( ref $_[ARG0] eq 'HASH' ) {
     $args = $_[ARG0];
  }
  else {
     $args = { @_[ARG0..$#_] };
  }
  $args->{cmd} = $state;
  if ( $session == $sender ) {
     $args->{sender_id} = $self->{sender_id};
     $self->{dict} = delete $args->{dict};
  }
  else {
     $args->{lc $_} = delete $args->{$_} for grep { !/^_/ } keys %{ $args };
     $args->{sender_id} = $sender->ID();
     unless ( $args->{event} ) {
	warn "You must specify 'SuccessEvent' and 'FailureEvent' for '$state'\n";
        return;
     }
     unless ( $args->{server} and _ip_is_v4( $args->{server} ) ) {
	warn "You must specify 'server' as a valid IPv4 address\n";
        return;
     }
     unless ( $args->{secret} ) {
	warn "You must specify a 'secret'\n";
	return;
     }
     unless ( $args->{attributes} and ref $args->{attributes} eq 'HASH' ) {
	warn "You must specify 'attributes' as a hashref of RADIUS attributes\n";
        return;
     }
     if ( $state eq 'authenticate' and !( $args->{username} and $args->{password} ) ) {
	warn "You must specify 'username' and 'password' for 'authenticate'\n";
	return;
     }
     if ( $state eq 'accounting' and !$args->{type} ) {
	warn "You must specify 'type' for an accounting request\n";
	return;
     }
     $args->{port} = RADIUS_PORT if $state eq 'authenticate' and !$args->{port};
     $args->{port} = ACCOUNTING_PORT if $state eq 'accounting' and !$args->{port};
     $kernel->refcount_increment( $args->{sender_id}, __PACKAGE__ );
  }
  my $req = Net::Radius::Packet->new( $self->{dict} );
  my $packet;
  if ( $state eq 'authenticate' ) {
     $args->{identifier} = _allocate_identifier();
     $args->{authenticator} = _bigrand();
     $req->set_code('Access-Request');
     $req->set_attr('User-Name' => $args->{username});
     $req->set_attr('Service-Type' => '2');
     $req->set_attr('Framed-Protocol' => 'PPP');
     $req->set_attr('NAS-Port' => 1234);
     $req->set_attr('NAS-Identifier' => 'PoCoClientRADIUS');
     $req->set_attr('NAS-IP-Address' => _my_address( $args->{server} ) );
     $req->set_attr('Called-Station-Id' => '0000');
     $req->set_attr('Calling-Station-Id' => '01234567890');
     delete $args->{attributes}->{'User-Name'};
     $req->set_attr( $_ => $args->{attributes}->{$_} ) for keys %{ $args->{attributes} };
     $req->set_identifier( $args->{identifier} );
     $req->set_authenticator( $args->{authenticator} );
     $req->set_password( $args->{password}, $args->{secret} );
     $packet = $req->pack;
  }
  if ( $state eq 'accounting' ) {
     $args->{identifier} = _allocate_identifier();
     $args->{authenticator} = '';
     $req->set_code('Accounting-Request');
     $req->set_attr('Acct-Status-Type', ucfirst lc $args->{type});
     delete $args->{attributes}->{'Acct-Status-Type'};
     $req->set_attr( $_ => $args->{attributes}->{$_} ) for keys %{ $args->{attributes} };
     $req->set_identifier( $args->{identifier} );
     $req->set_authenticator( $args->{authenticator} );
     $packet = auth_resp($req->pack,$args->{secret});
  }
  $kernel->yield( '_create_socket', $packet, $args );
  return;
}

sub _create_socket {
  my ($kernel,$self,$packet,$data) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $socket = IO::Socket::INET->new( Proto => 'udp' );
  $kernel->select_read( $socket, '_get_datagram', $data );
  unless ( $socket ) {
     $data->{error} = $!;
     $kernel->yield( '_dispatch', $data );
     return;
  }
  my $server_address = pack_sockaddr_in( $data->{port}, inet_aton($data->{server}) );
  unless ( $server_address ) {
     $data->{error} = 'Couldn\'t create packed server address and socket';
     $kernel->yield( '_dispatch', $data );
     return;
  }
  unless ( send( $socket, $packet, 0, $server_address ) == length($packet) ) {
     $data->{error} = $!;
     $kernel->yield( '_dispatch', $data );
     return;
  }
  $data->{alarm_id} = $kernel->delay_set( '_sock_timeout', $self->{timeout} || 10, $socket, $data );
  return;
}

sub _sock_timeout {
  my ($kernel,$self,$socket,$data) = @_[KERNEL,OBJECT,ARG0,ARG1];
  $kernel->select_read( $socket );
  $data->{timeout} = 'Timeout waiting for a response';
  $kernel->yield( '_dispatch', $data );
  return;
}

sub _get_datagram {
  my ($kernel,$self,$socket,$data) = @_[KERNEL,OBJECT,ARG0,ARG2];
  $kernel->alarm_remove( delete $data->{alarm_id} );
  $kernel->select_read( $socket );
  my $remote_address = recv( $socket, my $message = '', 4096, 0 );
  unless ( defined $remote_address ) {
     $data->{error} = $!;
     $kernel->yield( '_dispatch', $data );
     return;
  }
  my $resp = Net::Radius::Packet->new( $self->{dict}, $message );
  my ($port, $iaddr) = unpack_sockaddr_in( $remote_address );
  $iaddr = inet_ntoa( $iaddr );
  if ( $data->{identifier} ne $resp->identifier or $iaddr ne $data->{server} ) {
     $data->{error} = 'Unexpected response to request.';
     $kernel->yield( '_dispatch', $data );
     return;
  }
  if ( $data->{cmd} eq 'authenticate' and !auth_req_verify( $message, $data->{secret}, $data->{authenticator} ) ) {
     $data->{error} = 'Couldn\'t authenticate the response from the server.';
     $kernel->yield( '_dispatch', $data );
     return;
  }
  my $reply = {
     map { ( $_, $resp->attr($_) ) } $resp->attributes()
  };
  $reply->{Code} = $resp->code;
  $data->{response} = $reply;
  $kernel->yield( '_dispatch', $data );
  return;
}

sub _dispatch {
  my ($kernel,$self,$data) = @_[KERNEL,OBJECT,ARG0];
  delete $data->{authenticator};
  my $ident = delete $data->{identifier};
  _free_identifier( $ident ) if $ident;
  $kernel->post( $data->{sender_id}, $data->{event}, $data );
  $kernel->refcount_decrement( delete $data->{sender_id}, __PACKAGE__ );
  return;
}

#------------------------------------------------------------------------------
# Subroutine _ip_is_ipv4
# Purpose           : Check if an IP address is version 4
# Params            : IP address
# Returns           : 1 (yes) or 0 (no)
sub _ip_is_v4 {
    my $ip = shift;

    # Check for invalid chars
    unless ($ip =~ m/^[\d\.]+$/) {
        $ERROR = "Invalid chars in IP $ip";
        $ERRNO = 107;
        return 0;
    }

    if ($ip =~ m/^\./) {
        $ERROR = "Invalid IP $ip - starts with a dot";
        $ERRNO = 103;
        return 0;
    }

    if ($ip =~ m/\.$/) {
        $ERROR = "Invalid IP $ip - ends with a dot";
        $ERRNO = 104;
        return 0;
    }

    # Single Numbers are considered to be IPv4
    if ($ip =~ m/^(\d+)$/ and $1 < 256) { return 1 }

    # Count quads
    my $n = ($ip =~ tr/\./\./);

    # IPv4 must have from 1 to 4 quads
    unless ($n >= 0 and $n < 4) {
        $ERROR = "Invalid IP address $ip";
        $ERRNO = 105;
        return 0;
    }

    # Check for empty quads
    if ($ip =~ m/\.\./) {
        $ERROR = "Empty quad in IP address $ip";
        $ERRNO = 106;
        return 0;
    }

    foreach (split /\./, $ip) {

        # Check for invalid quads
        unless ($_ >= 0 and $_ < 256) {
            $ERROR = "Invalid quad in IP address $ip - $_";
            $ERRNO = 107;
            return 0;
        }
    }
    return 1;
}

sub _bigrand {
  my @numbers;
  push @numbers, scalar random_uniform_integer(1,0,65536) for 0 .. 7;
  pack "n8", @numbers;
}

sub _my_address {
  my $remote = shift || '198.41.0.4';
  my $socket = IO::Socket::INET->new(
        Proto       => 'udp',
        PeerAddr    => $remote,
        PeerPort    => 53,
  );
  return unless $socket;
  return $socket->sockhost;
}

qq[Sound of crickets];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Client::RADIUS - a flexible POE-based RADIUS client

=head1 VERSION

version 1.04

=head1 SYNOPSIS

   use strict;
   use Net::Radius::Dictionary;
   use POE qw(Component::Client::RADIUS);

   my $username = 'bingos';
   my $password = 'moocow';
   my $secret = 'bogoff';

   my $server = '192.168.1.1';

   my $dictionary = '/etc/radius/dictionary';

   my $dict = Net::Radius::Dictionary->new( $dictionary );

   die "No dictionary found\n" unless $dict;

   my $radius = POE::Component::Client::RADIUS->spawn( dict => $dict );

   POE::Session->create(
     package_states => [
       'main' => [qw(_start _auth)],
     ],
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     $poe_kernel->post(
      $radius->session_id(),
      'authenticate',
      event => '_auth',
      username => $username,
      password => $password,
      server => $server,
	    secret => $secret,
     );
     return;
   }

   sub _auth {
     my ($kernel,$sender,$data) = @_[KERNEL,SENDER,ARG0];

     # Something went wrong
     if ( $data->{error} ) {
       warn $data->{error}, "\n";
       $kernel->post( $sender, 'shutdown' );
       return;
     }

     # There was a timeout getting a response back from the RADIUS server
     if ( $data->{timeout} ) {
       warn $data->{timeout}, "\n";
       $kernel->post( $sender, 'shutdown' );
       return;
     }

     # Okay we got a response
     if ( $data->{response}->{Code} eq 'Access-Accept' ) {
       print "Yay, we were authenticated\n";
     }
     elsif ( $data->{response}->{Code} eq 'Access-Reject' ) {
       print "Boo, the server didn't like us\n";
     }
     else {
       print $data->{response}->{Code}, "\n";
     }

     print join ' ', $_, $data->{response}->{$_}, "\n" for keys %{ $data->{response} };

     return;
   }

=head1 DESCRIPTION

POE::Component::Client::RADIUS is a L<POE> Component that provides Remote Authentication Dial In User Service (RADIUS) client
services to other POE sessions and components.

RADIUS is commonly used by ISPs and corporations managing access to Internet or internal networks and is 
an AAA (authentication, authorisation, and accounting) protocol.

The component deals with the transmission and receiving of RADIUS packets and uses the excellent L<Net::Radius::Packet>
and L<Net::Radius::Dictionary> modules to construct the RADIUS packets.

Currently only PAP authentication is supported. Help and advice would be appreciated on implementing others. See contact details
below.

=head1 CONSTRUCTORS

One may start POE::Component::Client::RADIUS in two ways. If you spawn it creates a session that can then broker lots
of RADIUS requests on your behalf. Or you may use 'authenticate' and 'accounting' to broker 'one-shot' instances.

  POE::Component::Client::RADIUS->spawn( ... );

  POE::Component::Client::RADIUS->authenticate( ... );

  POE::Component::Client::RADIUS->accounting( ... );

=over

=item C<spawn>

Creates a new POE::Component::Client::RADIUS session that may be used lots of times. Takes the following parameters:

  'dict', a Net::Radius::Dictionary object reference, mandatory;
  'alias', set an alias that you can use to address the component later;
  'options', a hashref of POE session options;

Returns an POE::Component::Client::RADIUS object.

=item C<authenticate>

Creates a one-shot POE::Component::Client::RADIUS session that will send an authentication request, receive the response and then
terminates. Takes the following mandatory parameters:

  'dict', a Net::Radius::Dictionary object reference;
  'server', IP address of the RADIUS server to communicate with;
  'username', the username to authenticate;
  'password', the user's password;
  'attributes', a hashref of RADIUS attributes to construct the packet from;
  'secret', a shared secret between this RADIUS client and the RADIUS server;
  'event', the event in the calling session that will be triggered with the response;

'attributes' must be provided, but may be an empty hashref. The component will make up any necessary attributes to send.
Check with the RADIUS RFC L<http://www.faqs.org/rfcs/rfc2138.html> for details.

One can also pass arbitary data which will be passed back in the response event. It is advised that one uses an underscore prefix to avoid clashes with future versions.

=item C<accounting>

Creates a one-shot POE::Component::Client::RADIUS session that will send an accounting request, receive the response and then
terminates. Takes the following mandatory parameters:

  'dict', a Net::Radius::Dictionary object reference;
  'server', IP address of the RADIUS server to communicate with;
  'type', the type of accounting request;
  'attributes', a hashref of RADIUS attributes to construct the packet from;
  'secret', a shared secret between this RADIUS client and the RADIUS server;
  'event', the event in the calling session that will be triggered with the response;

Check with the RADIUS Accounting RFC L<http://www.faqs.org/rfcs/rfc2866.html> for what one may specify as 'type' and 'attributes'.

One can also pass arbitary data which will be passed back in the response event. It is advised that one uses an underscore prefix to avoid clashes with future versions.

=back

=head1 METHODS

=over

=item C<session_id>

Takes no arguments. Returns the POE Session ID of the component.

=item C<shutdown>

Terminates the component.

=back

=head1 INPUT EVENTS

When C<spawn>ed, the component will accept the following events:

=over

=item C<authenticate>

Send an authentication request, receive the response and trigger a result event back to the sending session.
Takes the following mandatory parameters:

  'server', IP address of the RADIUS server to communicate with;
  'username', the username to authenticate;
  'password', the user's password;
  'attributes', a hashref of RADIUS attributes to construct the packet from;
  'secret', a shared secret between this RADIUS client and the RADIUS server;
  'event', the event in the calling session that will be triggered with the response;

'attributes' must be provided, but may be an empty hashref. The component will make up any necessary attributes to send.
Check with the RADIUS RFC L<http://www.faqs.org/rfcs/rfc2138.html> for details.

One can also pass arbitary data which will be passed back in the response event. It is advised that one uses an underscore prefix to avoid clashes with future versions.

=item C<accounting>

Send an accounting request, receive the response and trigger a result event back to the sending session.
Takes the following mandatory parameters:

  'server', IP address of the RADIUS server to communicate with;
  'type', the type of accounting request;
  'attributes', a hashref of RADIUS attributes to construct the packet from;
  'secret', a shared secret between this RADIUS client and the RADIUS server;
  'event', the event in the calling session that will be triggered with the response;

Check with the RADIUS Accounting RFC L<http://www.faqs.org/rfcs/rfc2866.html> for what one may specify as 'type' and 'attributes'.

One can also pass arbitary data which will be passed back in the response event. It is advised that one uses an underscore prefix to avoid clashes with future versions.

=item C<shutdown>

Terminates the component.

=back

=head1 OUTPUT EVENTS

The component returns the specified event to all requests to the calling session. 

ARG0 will be a hashref, which contains the original parameters ( including any arbitary data ), plus either one of the following two keys:

  'response', will contain a hashref of RADIUS attributes returned by the RADIUS server;
  'timeout', indicates that the component timed out waiting for a response from the RADIUS server;
  'error', in lieu of a valid response, this will be defined with a brief description of what went wrong;

The component will only report an error if there is an error with communicating with the RADIUS server in some way. Please check
the contents of the 'response' hashref for the status of authenication requests etc.

=head1 BUGS

There are bound to be bugs in this. Please report any you find via C<bug-POE-Component-Client-RADIUS@rt.cpan.org>.

=head1 SEE ALSO

L<POE>

L<http://en.wikipedia.org/wiki/RADIUS>

L<http://www.faqs.org/rfcs/rfc2138.html>

L<http://www.faqs.org/rfcs/rfc2866.html>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
