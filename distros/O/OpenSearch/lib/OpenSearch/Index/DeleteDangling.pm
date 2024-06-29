package OpenSearch::Index::DeleteDangling;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use feature qw(signatures);
no warnings qw(experimental::signatures);

with 'OpenSearch::Parameters::Index::DeleteDangling';

has '_base' => (
  is       => 'rw',
  isa      => InstanceOf['OpenSearch::Base'],
  required => 1,
);

sub execute($self) {
  my $res = $self->_base->_delete( $self, [ '_dangling', $self->index_uuid ] );
}


1;
