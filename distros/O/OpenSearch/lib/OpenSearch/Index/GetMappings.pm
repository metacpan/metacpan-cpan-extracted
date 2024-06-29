package OpenSearch::Index::GetMappings;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use feature qw(signatures);
no warnings qw(experimental::signatures);

with 'OpenSearch::Parameters::Index::GetMappings';

has '_base' => (
  is       => 'rw',
  isa      => InstanceOf['OpenSearch::Base'],
  required => 1,
);

sub execute($self) {
  my $res =
    $self->_base->_get( $self, [ $self->index, '_mapping', ( $self->field ? ( 'field', $self->field ) : () ) ] );
}


1;
