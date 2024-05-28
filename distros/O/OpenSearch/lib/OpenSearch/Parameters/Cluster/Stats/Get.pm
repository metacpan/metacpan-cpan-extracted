package OpenSearch::Parameters::Cluster::Stats::Get;
use Moose::Role;
use OpenSearch::Filter::Nodes;

has 'nodes' => (
  is          => 'rw',
  isa         => 'OpenSearch::Filter::Nodes | Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'path',
    required    => 0,
  }
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

1;
