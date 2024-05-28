package OpenSearch::Parameters::Document::Index;
use Moose::Role;
use Moose::Util::TypeConstraints;
enum 'DocumentOpType'      => [qw(index create)];
enum 'DocumentRefresh'     => [qw(true false wait_for)];
enum 'DocumentVersionType' => [qw(internal external external_gte)];

has 'index' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'path',
    required    => 1,
  }
);

# create if _doc does not exist
has 'create' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'path',
    required    => 0,
  }
);

has 'id' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'path',
    required    => 0,
  }
);

has 'doc' => (
  is          => 'rw',
  isa         => 'HashRef',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 1,
  }
);

has 'if_seq_no' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'if_primary_term' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'op_type' => (
  is          => 'rw',
  isa         => 'DocumentOpType',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'pipeline' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'routing' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'refresh' => (
  is          => 'rw',
  isa         => 'DocumentRefresh',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'timeout' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'version' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'version_type' => (
  is          => 'rw',
  isa         => 'DocumentVersionType',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'wait_for_active_shards' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'require_alias' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

around [
  qw/
    index create id doc if_seq_no if_primary_term op_type pipeline routing refresh timeout
    version version_type wait_for_active_shards require_alias
    /
] => sub {
  my $orig = shift;
  my $self = shift;

  if (@_) {
    $self->$orig(@_);
    return ($self);
  }
  return ( $self->$orig );
};

1;
