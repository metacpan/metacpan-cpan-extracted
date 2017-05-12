package POE::Component::Server::SimpleHTTP::Response;
$POE::Component::Server::SimpleHTTP::Response::VERSION = '2.26';
#ABSTRACT: Emulates a HTTP::Response object, used for SimpleHTTP

use strict;
use warnings;

use base qw( HTTP::Response );

use Moose;
extends qw(HTTP::Response Moose::Object );

has '_WHEEL' => (
  is => 'rw',
);

has 'connection' => (
  is => 'ro',
  writer => 'set_connection',
);

has 'STREAM_SESSION' => (
  is => 'rw',
);

has 'STREAM' => (
  is => 'rw',
);

has 'STREAM_DONE' => (
  is => 'ro',
  default => sub { 0 },
  writer => 'set_stream_done',
  init_arg => undef,
);

has 'IS_STREAMING' => (
  is => 'ro',
  writer => 'set_streaming',
);

has 'DONT_FLUSH' => (
  is => 'rw',
  isa => 'Bool',
);

sub new {
   my $class = shift;

   # Get the Wheel ID
   my $wid = shift;

   # Get the Connection object
   my $conn = shift;

   # Make sure we got the wheel ID!
   if ( !defined $wid ) {
      die 'Did not get a Wheel ID!';
   }

   my $self = $class->SUPER::new(@_);

   return $class->meta->new_object(
          __INSTANCE__ => $self,
          _WHEEL => $wid,
	  connection => $conn,
    );
}

sub stream {
   my $self = shift;
   my %opt = (@_);

   no strict 'refs';

   if ( $opt{event} ne '' ) {
      $self->STREAM_SESSION( $opt{'session'} || undef );
      $self->STREAM( $opt{'event'} );
      $self->DONT_FLUSH( $opt{'dont_flush'} );
   }
   else {
      $self->STREAM( shift );
   }
}

no Moose;

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

# End of module
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::SimpleHTTP::Response - Emulates a HTTP::Response object, used for SimpleHTTP

=head1 VERSION

version 2.26

=head1 SYNOPSIS

	use POE::Component::Server::SimpleHTTP::Response;
	my $response = POE::Component::Server::SimpleHTTP::Response->new( $wheel_id, $connection );

	print $response->connection->remote_ip;

=head1 DESCRIPTION

	This module is used as a drop-in replacement, because we need to store the wheel ID + connection object for the response.

	Use $response->connection to get the SimpleHTTP::Connection object

=head2 EXPORT

Nothing.

=for Pod::Coverage stream

=head1 SEE ALSO

	L<POE::Component::Server::SimpleHTTP>

	L<POE::Component::Server::SimpleHTTP::Connection>

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Apocalypse, Chris Williams, Eriam Schaffter, Marlon Bailey and Philip Gwyn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
