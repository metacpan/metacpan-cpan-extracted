package OpenSearch::Parameters::Cluster::AllocationExplain;
use Moose::Role;

has 'current_node' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'index' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'primary' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'body',
    required    => 0,
  }
);

has 'shard' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'include_disk_info' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

has 'include_yes_decisions' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

around [qw/current_node index primary shard include_disk_info include_yes_decisions/] => sub {
  my $orig = shift;
  my $self = shift;

  if (@_) {
    $self->$orig(@_);
    return ($self);
  }
  return ( $self->$orig );
};

1;
