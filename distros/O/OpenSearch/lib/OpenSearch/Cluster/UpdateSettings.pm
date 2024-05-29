package OpenSearch::Cluster::UpdateSettings;
use strict;
use warnings;
use feature qw(signatures);
use Moose;

with 'OpenSearch::Parameters::Cluster::UpdateSettings';

has '_base' => (
  is       => 'rw',
  isa      => 'OpenSearch::Base',
  required => 0,
  lazy     => 1,
  default  => sub { OpenSearch::Base->instance; }
);

sub execute($self) {
  my $res = $self->_base->_put( $self, [ '_cluster', 'settings' ] );
}

1;
