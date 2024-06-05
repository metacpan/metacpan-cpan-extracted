package OpenSearch::Index::Create;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Moose;

with 'OpenSearch::Parameters::Index::Create';

has '_base' => (
  is       => 'rw',
  isa      => 'OpenSearch::Base',
  required => 0,
  lazy     => 1,
  default  => sub { OpenSearch::Base->instance; }
);

sub execute($self) {
  my $res = $self->_base->_put( $self, [ $self->index ] );
}

1;
