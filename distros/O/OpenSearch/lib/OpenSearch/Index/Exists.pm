package OpenSearch::Index::Exists;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Moose;

with 'OpenSearch::Parameters::Index::Exists';

has '_base' => (
  is       => 'rw',
  isa      => 'OpenSearch::Base',
  required => 0,
  lazy     => 1,
  default  => sub { OpenSearch::Base->instance; }
);

sub execute($self) {
  my $res = $self->_base->_head( $self, [ $self->index ] );
}

1;
