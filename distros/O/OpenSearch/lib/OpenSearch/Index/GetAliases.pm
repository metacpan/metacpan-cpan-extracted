package OpenSearch::Index::GetAliases;
use strict;
use warnings;
use feature qw(signatures);
use Moose;

#with 'OpenSearch::Parameters::Index::GetAliases';

has '_base' => (
  is       => 'rw',
  isa      => 'OpenSearch::Base',
  required => 0,
  lazy     => 1,
  default  => sub { OpenSearch::Base->instance; }
);

sub execute($self) {
  my $res = $self->_base->_get( $self, ['_aliases'] );
}

1;
