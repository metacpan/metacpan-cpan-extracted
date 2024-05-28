package OpenSearch::Parameters::Cluster::Settings::Set;
use Moose::Role;

has 'flat_settings' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

has 'cluster_manager_timeout' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
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

has 'persistent' => (
  is          => 'rw',
  isa         => 'HashRef',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 1,
    forced_body => 1
  }
);

has 'transient' => (
  is          => 'rw',
  isa         => 'HashRef',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 1,
    forced_body => 1
  }
);
around [qw/flat_settings cluster_manager_timeout timeout persistent transient/] => sub {
  my $orig = shift;
  my $self = shift;

  if (@_) {
    $self->$orig(@_);
    return ($self);
  }
  return ( $self->$orig );
};

1;
