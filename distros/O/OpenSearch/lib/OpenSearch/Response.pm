package OpenSearch::Response;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str Bool Int);
use feature qw(signatures);
no warnings qw(experimental::signatures);

has '_response' => ( is => 'rw', required => 1 );
has 'success'   => ( is => 'rw', isa      => Bool, required => 0 );
has 'message'   => ( is => 'rw', isa      => Str,  required => 0 );
has 'error'     => ( is => 'rw', required => 0 );
has 'code'      => ( is => 'rw', isa      => Int, required => 0 );
has 'data'      => ( is => 'rw', required => 0 );

sub BUILD( $self, @rest ) {
  $self->success( $self->_response->code >= 200 && $self->_response->code < 300 );

  $self->code( $self->_response->code );
  $self->message( $self->_response->message );
  $self->data( $self->_response->json );

  if ( !$self->success && ( $self->data && $self->data->{error} ) ) {
    $self->error( $self->data->{error} );
  }

}

1;
