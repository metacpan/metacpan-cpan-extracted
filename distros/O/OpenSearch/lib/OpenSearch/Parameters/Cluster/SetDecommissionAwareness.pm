package OpenSearch::Parameters::Cluster::SetDecommissionAwareness;
use Moose::Role;
use Moose::Util::TypeConstraints;

has 'attribute' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'path',
    required    => 1,
  }
);

has 'value' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'path',
    required    => 1,
  }
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

1;
