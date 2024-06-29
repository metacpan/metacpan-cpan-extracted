package OpenSearch::Parameters::Cluster::SetDecommissionAwareness;
use strict;
use warnings;
use feature qw(state);
use Types::Common::String qw(NonEmptyStr);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'attribute' => (
  is          => 'rw',
  isa         => NonEmptyStr,
  required    => 1,
);

has 'value' => (
  is          => 'rw',
  isa         => NonEmptyStr,
  required    => 1,
);

around [qw/attribute value/] => sub {
  my $orig = shift;
  my $self = shift;

  if (@_) {
    $self->$orig(@_);
    return ($self);
  }
  return ( $self->$orig );
};

sub api_spec {
  state $s = +{
    attribute => {
      encode_func => 'as_is',
      type        => 'path',
    },
    value => {
      encode_func => 'as_is',
      type        => 'path',
    }
  };
}

1;
