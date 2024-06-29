package OpenSearch::Parameters::Cluster::Stats;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'nodes' => (
  is          => 'rw',
  # TODO: may work if encode_func is applied to path arguments
  #isa         => InstanceOf['OpenSearch::Filter::Nodes'] | Str,
  isa         => Str
);

around [qw/nodes/] => sub {
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
    nodes => {
      encode_func => 'as_is',
      type        => 'path',
    }
  };
}

1;
