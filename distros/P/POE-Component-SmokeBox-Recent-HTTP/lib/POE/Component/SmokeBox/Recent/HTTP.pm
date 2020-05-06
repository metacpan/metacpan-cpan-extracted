package POE::Component::SmokeBox::Recent::HTTP;
$POE::Component::SmokeBox::Recent::HTTP::VERSION = '1.54';
#ABSTRACT: an extremely minimal HTTP client

use strict;
use warnings;
use POE qw(Filter::HTTP::Parser Component::Client::DNS);
use Net::IP::Minimal qw(ip_get_version);
use Test::POE::Client::TCP;
use Carp qw(carp croak);
use HTTP::Request;
use URI;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  croak( "You must provide the 'uri' parameter and it must a URI object and a supported scheme\n" )
	unless $opts{uri} and $opts{uri}->isa('URI')
	and $opts{uri}->scheme and $opts{uri}->scheme =~ /^http$/
	and $opts{uri}->host;
  my $options = delete $opts{options};
  $opts{prefix} = 'http_' unless $opts{prefix};
  $opts{prefix} .= '_' unless $opts{prefix} =~ /\_$/;
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
    object_states => [
	$self => { map { ($_,"_$_" ) } qw(web_socket_failed web_connected web_input web_disconnected) },
	$self => [qw(
		_start
		_resolve
		_response
		_connect
		_shutdown
		_timeout
	)],
     ],
     heap => $self,
     ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub _start {
  my ($kernel,$sender,$self) = @_[KERNEL,SENDER,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $kernel == $sender and !$self->{session} ) {
	croak "Not called from another POE session and 'session' wasn't set\n";
  }
  my $sender_id;
  if ( $self->{session} ) {
    if ( my $ref = $kernel->alias_resolve( $self->{session} ) ) {
	$sender_id = $ref->ID();
    }
    else {
	croak "Could not resolve 'session' to a valid POE session\n";
    }
  }
  else {
    $sender_id = $sender->ID();
  }
  $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  $self->{sender_id} = $sender_id;

  $self->{_resolver} = POE::Component::Client::DNS->spawn(
	Alias => 'Resolver-' . $self->{session_id},
  );

  $self->{address} = $self->{uri}->host;
  $self->{port}    = $self->{uri}->port;

  $kernel->yield( '_resolve' );
  return;
}

sub _resolve {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  if ( ip_get_version( $self->{address} ) ) {
     # It is an address already
     $kernel->yield( '_connect', $self->{address} );
     return;
  }
  my $resp = $self->{_resolver}->resolve(
     host 	=> $self->{address},
     context 	=> { },
     event	=> '_response',
  );
  $kernel->yield( '_response', $resp ) if $resp;
  return;
}

sub _response {
  my ($kernel,$self,$resp) = @_[KERNEL,OBJECT,ARG0];
  if ( $resp->{error} and $resp->{error} ne 'NOERROR' ) {
     $kernel->yield( 'web_socket_failed', $resp->{error} );
     return;
  }
  my @answers = $resp->{response}->answer;
  foreach my $answer ( $resp->{response}->answer() ) {
     next if $answer->type !~ /^A/;
     $kernel->yield( '_connect', $answer->rdatastr );
     return;
  }
  $kernel->yield( 'web_socket_failed', 'Could not resolve address' );
  return;
}

sub _connect {
  my ($self,$address) = @_[OBJECT,ARG0];
  $self->{web} = Test::POE::Client::TCP->spawn(
	address     => $address,
	port        => $self->{port} || 80,
	prefix      => 'web',
	autoconnect => 1,
	filter	    => POE::Filter::HTTP::Parser->new( type => 'client' ),
  );
  return;
}

sub _web_connected {
  my $self = $_[OBJECT];
  my $req = HTTP::Request->new( GET => $self->{uri}->path_query );
  $req->protocol( 'HTTP/1.1' );
  $req->header( 'Host', $self->{address} . ( $self->{port} ne '80' ? ":$self->{port}" : '' ) );
  $req->user_agent( sprintf( 'POE-Component-SmokeBox-Recent-HTTP/%s (perl; N; POE; en; rv:%f)', $POE::Component::SmokeBox::Recent::HTTP::VERSION, $POE::Component::SmokeBox::Recent::HTTP::VERSION ) );
  $self->{web}->send_to_server( $req );
  $poe_kernel->delay( '_timeout', $self->{timeout} || 60 );
  return;
}

sub _timeout {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->_send_event( $self->{prefix} . 'timeout', "Timed out connection after " . ( $self->{timeout} || 60 ) . " seconds." );
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
  $kernel->yield( '_shutdown' );
  return;
}

sub _web_socket_failed {
  my ($kernel,$self,@errors) = @_[KERNEL,OBJECT,ARG0..$#_];
  $self->_send_event( $self->{prefix} . 'sockerr', @errors );
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
  $kernel->yield( '_shutdown' );
  return;
}

sub _web_input {
  my ($kernel,$self,$resp) = @_[KERNEL,OBJECT,ARG0];
  $kernel->delay( '_timeout' );
  $self->_send_event( $self->{prefix} . 'response', $resp );
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
  $self->{web}->shutdown();
  delete $self->{web};
  return;
}

sub _web_disconnected {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->yield( '_shutdown' );
  return;
}

sub _send_event {
  my $self = shift;
  $poe_kernel->post( $self->{sender_id}, @_ );
  return;
}

sub _shutdown {
  my $self = $_[OBJECT];
  $poe_kernel->delay( '_timeout' );
  $self->{web}->shutdown() if $self->{web};
  $self->{_resolver}->shutdown() if $self->{_resolver};
  delete $self->{web};
  delete $self->{_resolver};
  return;
}

'Get me that file, sucker'

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Recent::HTTP - an extremely minimal HTTP client

=head1 VERSION

version 1.54

=head1 SYNOPSIS

  # Obtain the RECENT file from a given CPAN mirror.
   use strict;
   use warnings;
   use File::Spec;
   use POE qw(Component::SmokeBox::Recent::HTTP);
   use URI;

   my $url = shift || die "You must provide a url parameter\n";

   my $uri = URI->new( $url );

   die "Unsupported scheme\n" unless $uri->scheme and $uri->scheme eq 'http';

   $uri->path( File::Spec::Unix->catfile( $uri->path(), 'RECENT' ) );

   POE::Session->create(
      package_states => [
   	main => [qw(_start http_sockerr http_timeout http_response)],
      ]
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     POE::Component::SmokeBox::Recent::HTTP->spawn(
   	uri => $uri,
     );
     return;
   }

   sub http_sockerr {
     warn join ' ', @_[ARG0..$#_];
     return;
   }

   sub http_timeout {
     warn $_[ARG0], "\n";
     return;
   }

   sub http_response {
     my $http_response = $_[ARG0];
     print $http_response->as_string;
     return;
   }

=head1 DESCRIPTION

POE::Component::SmokeBox::Recent::HTTP is the small helper module used by L<POE::Component::SmokeBox::Recent> to
do HTTP client duties.

It only implements a simple request with no following of redirections and connection keep-alive, etc.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of parameters:

  'uri', a URI object for the URL you wish to retrieve, mandatory;
  'session', optional if the poco is spawned from within another session;
  'prefix', specify an event prefix other than the default of 'http';
  'timeout', specify a timeout in seconds, default is 60;

=back

=head1 OUTPUT EVENTS

The component sends the following events. If you have changed the C<prefix> option in C<spawn> then substitute C<http>
with the event prefix that you specified.

=over

=item C<http_sockerr>

Generated if there is a problem connecting to the given HTTP host/address. C<ARG0> contains the name of the operation that failed. C<ARG1> and C<ARG2> hold numeric and string values for C<$!>, respectively.

=item C<http_timeout>

Triggered if we don't get a response from the HTTP server.

=item C<http_response>

Emitted when the transfer has finished. C<ARG0> will be a L<HTTP::Response> object. It is up to you to check the status, etc. of the
response.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
