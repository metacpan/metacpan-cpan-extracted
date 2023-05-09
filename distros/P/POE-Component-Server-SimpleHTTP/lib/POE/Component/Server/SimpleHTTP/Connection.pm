# Declare our package
package POE::Component::Server::SimpleHTTP::Connection;
$POE::Component::Server::SimpleHTTP::Connection::VERSION = '2.30';
#ABSTRACT: Stores connection information for SimpleHTTP

use strict;
use warnings;

use Socket (qw( AF_INET AF_INET6 AF_UNIX inet_ntop sockaddr_family
   unpack_sockaddr_in unpack_sockaddr_in6 unpack_sockaddr_un ));
use POE;

use Moose;

has dead => (
  is => 'rw',
  isa => 'Bool',
  default => 0,
);

has ssl => (
  is => 'rw',
  isa => 'Bool',
  default => 0,
);

has sslcipher => (
  is => 'rw',
  default => undef,
);

has remote_ip => (
  is => 'ro',
);

has remote_port => (
  is => 'ro',
);

has remote_addr => (
  is => 'ro',
);

has local_ip => (
  is => 'ro',
);

has local_port => (
  is => 'ro',
);

has local_addr => (
  is => 'ro',
);

has ID => (
  is => 'rw',
);

has OnClose => (
  is => 'ro',
  default => sub { { } },
);

sub BUILDARGS {
   my $class = shift;

   my $self = { };

   my $socket = shift;

   eval {
      my $family;
      ( $family, $self->{'remote_port'}, $self->{'remote_addr'},
         $self->{'remote_ip'}
      ) = $class->get_sockaddr_info( getpeername($socket) );

      ( $family, $self->{'local_port'}, $self->{'local_addr'},
         $self->{'local_ip'}
      ) = $class->get_sockaddr_info( getsockname($socket) );
   };

   if ($@) {
      return undef;
   }

   return $self;
}

sub _on_close {
   my ( $self, $sessionID, $state, @args ) = @_;
   if ($state) {
      $self->OnClose->{$sessionID} = [ $state, @args ];
      $poe_kernel->refcount_increment( $sessionID, __PACKAGE__ );
   }
   else {
      my $data = delete $self->OnClose->{$sessionID};
      $poe_kernel->refcount_decrement( $sessionID, __PACKAGE__ ) if $data;
   }
}

sub DEMOLISH {
   my ($self) = @_;
   while ( my ( $sessionID, $data ) = each %{ $self->OnClose || {} } ) {
      $poe_kernel->call( $sessionID, @$data );
      $poe_kernel->refcount_decrement( $sessionID, __PACKAGE__ );
   }
}

sub get_sockaddr_info {
   my $class = shift;
   my $sockaddr = shift;

   my $family = sockaddr_family( $sockaddr );
   my ( $port, $address, $straddress );
   if ( $family == AF_INET ) {
      ( $port, $address ) = unpack_sockaddr_in( $sockaddr );
      $straddress = inet_ntop( $family, $address );
   } elsif ( $family == AF_INET6 ) {
      ( $port, $address ) = unpack_sockaddr_in6( $sockaddr );
      $straddress = inet_ntop( $family, $address );
   } elsif ( $family == AF_UNIX ) {
      $address = unpack_sockaddr_un( $sockaddr );
      $straddress = $address // '<local>';
      $port = undef;
   } else {
      $address = $port = undef;
      $straddress = '<unknown>';
   }
   return ( $family, $address, $port, $straddress );
}

no Moose;

__PACKAGE__->meta->make_immutable;

# End of module
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::SimpleHTTP::Connection - Stores connection information for SimpleHTTP

=head1 VERSION

version 2.30

=head1 SYNOPSIS

	use POE::Component::Server::SimpleHTTP::Connection;
	my $connection = POE::Component::Server::SimpleHTTP::Connection->new( $socket );

	# Print some stuff
	print $connection->remote_port;

=head1 DESCRIPTION

	This module simply holds some information from a SimpleHTTP connection.

=head2 METHODS

	my $connection = POE::Component::Server::SimpleHTTP::Connection->new( $socket );

	$connection->remote_ip();	# Returns remote address as a string ( 1.1.1.1 or 2000::1 )
	$connection->remote_port();	# Returns remote port
	$connection->remote_addr();	# Returns true remote address, consult the L<Socket> POD
	$connection->local_addr();	# Returns true local address, same as above
	$connection->local_ip();	# Returns remote address as a string ( 1.1.1.1 or 2000::1 )
	$connection->local_port();	# Returns local port
	$connection->dead();		# Returns a boolean value whether the socket is closed or not
	$connection->ssl();		# Returns a boolean value whether the socket is SSLified or not
	$connection->sslcipher();	# Returns the SSL Cipher type or undef if not SSL
	$connection->ID();          # unique ID of this connection

=head2 EXPORT

Nothing.

=for Pod::Coverage DEMOLISH get_sockaddr_info

=head1 SEE ALSO

L<POE::Component::Server::SimpleHTTP>,
L<POE::Component::Server::SimpleHTTP::Response>

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Apocalypse, Chris Williams, Eriam Schaffter, Marlon Bailey and Philip Gwyn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
