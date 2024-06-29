package OpenSearch::Index::GetAliases;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use feature qw(signatures);
no warnings qw(experimental::signatures);

#with 'OpenSearch::Parameters::Index::GetAliases';

has '_base' => (
  is       => 'rw',
  isa      => InstanceOf['OpenSearch::Base'],
  required => 1,
);

sub execute($self) {
  my $res = $self->_base->_get( $self, ['_aliases'] );
}

# TODO: remove this when parameter package is done
sub api_spec {
  +{};
}

1;
