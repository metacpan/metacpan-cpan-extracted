package OpenSearch::Search::Search;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use feature qw(signatures);
no warnings qw(experimental::signatures);

with 'OpenSearch::Parameters::Search::Search';

has '_base' => (
  is       => 'rw',
  isa      => InstanceOf['OpenSearch::Base'],
  required => 1,
);

sub execute($self) {
  my $res = $self->_base->_get( $self, [ ( $self->index // () ),, '_search' ] );
}


1;
