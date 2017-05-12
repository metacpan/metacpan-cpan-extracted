package Plack::Middleware::GNUTerryPratchett;

# ABSTRACT: Adds automatically an X-Clacks-Overhead header.

use strict;
use warnings;
use Plack::Util;

our $VERSION = '0.01';

use parent qw/Plack::Middleware/;

sub call {
  my $self = shift;
  my $res  = $self->app->(@_);  

  $self->response_cb( 
    $res, 
    sub {   
      my $res     = shift;
      my $headers = $res->[1]; 
      return if ( Plack::Util::header_exists( $headers, 'X-Clacks-Overhead' ) );
      Plack::Util::header_set( $headers, 'X-Clacks-Overhead', 'GNU Terry Pratchett' );
      return;
    }
  );
}

1;

=pod

=head1 NAME

Plack::Middleware::GNUTerryPratchett - Adds automatically an X-Clacks-Overhead header.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = builder {
    enable "Plack::Middleware::GNUTerryPratchett";
    sub {[ '200', ['Content-Type' => 'text/html'], ['hello world']] }
  };

=head1 DESCRIPTION

Plack::Middleware::GNUTerryPratchett adds automatically an X-Clacks-Overhead header.

In Terry Pratchett's Discworld series, the clacks are a series of semaphore towers loosely based on the concept of the telegraph. Invented by an artificer named Robert Dearheart, the towers could send messages "at the speed of light" using standardized codes. Three of these codes are of particular import:

B<G>: send the message on

B<N>: do not log the message

B<U>: turn the message around at the end of the line and send it back again
When Dearheart died, his name was inserted into the overhead of the clacks with a "GNU" in front of it to memorialize him forever (or for at least as long as the clacks are standing.)

For more information: L<http://www.gnuterrypratchett.com/>

=head1 AUTHOR

Tiago Peczenyj <tiago.peczenyj@gmail.com>

=cut
