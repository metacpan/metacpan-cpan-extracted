package OpenSearch::Parameters::Cluster::GetRoutingAwareness;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str Bool Int);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'attribute' => (
  is          => 'rw',
  isa         => Str,
);

around [qw/attribute/] => sub {
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
    }
  };
}

1;
