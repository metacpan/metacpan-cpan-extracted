package OpenSearch::Parameters::Cluster::SetRoutingAwareness;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str HashRef);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'attribute' => (
  is          => 'rw',
  isa         => Str,
);

has '_version' => (
  is          => 'rw',
  isa         => Str,
);

has 'weights' => (
  is          => 'rw',
  isa         => HashRef,
);

around [qw/attribute weights _version/] => sub {
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
    _version => {
      encode_func => 'as_is',
      type        => 'body',
    },
    weights => {
      encode_func => 'as_is',
      type        => 'body',
    }
  };
}

1;
