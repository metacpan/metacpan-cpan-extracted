package OpenSearch::Document::Index;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Moose;

with 'OpenSearch::Parameters::Document::Index';

has '_base' => (
  is       => 'rw',
  isa      => 'OpenSearch::Base',
  required => 0,
  lazy     => 1,
  default  => sub { OpenSearch::Base->instance; }
);

sub execute($self) {
  my $method = $self->id ? '_put' : '_post';
  my $res    = $self->_base->$method( $self,
    [ $self->index, ( $self->create ? '_create' : '_doc' ), ( $self->id ? $self->id : () ) ] );
}

1;
