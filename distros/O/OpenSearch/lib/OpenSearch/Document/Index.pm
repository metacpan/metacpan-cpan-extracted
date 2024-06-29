package OpenSearch::Document::Index;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use feature qw(signatures);
no warnings qw(experimental::signatures);

with 'OpenSearch::Parameters::Document::Index';

has '_base' => (
  is       => 'rw',
  isa      => InstanceOf['OpenSearch::Base'],
  required => 1,
);

sub execute($self) {
  my $method = $self->id ? '_put' : '_post';
  my $res    = $self->_base->$method( $self,
    [ $self->index, ( $self->create ? '_create' : '_doc' ), ( $self->id ? $self->id : () ) ] );
}


1;
