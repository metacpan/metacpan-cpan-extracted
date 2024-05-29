package OpenSearch::Parameters::Cluster::GetDecommissionAwareness;
use Moose::Role;
use Moose::Util::TypeConstraints;

has 'attribute' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'path',
    required    => 0,
  }
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

1;
