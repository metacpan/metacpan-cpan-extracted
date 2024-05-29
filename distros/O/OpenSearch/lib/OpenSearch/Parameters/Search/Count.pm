package OpenSearch::Parameters::Search::Count;
use Moose::Role;
use OpenSearch::Filter::Source;

has 'index' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'path',
    required    => 0,
  }
);

has 'allow_no_indices' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

has 'analyzer' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'analyze_wildcard' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

has 'default_operator' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'df' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'expand_wildcards' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'ignore_unavailable' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

has 'lenient' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

has 'min_score' => (
  is          => 'rw',
  isa         => 'Int',
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
    type        => 'url',
    required    => 0,
  }
);

has 'preference' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'terminate_after' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'query' => (
  is          => 'rw',
  isa         => 'HashRef',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

around [
  qw/
    index allow_no_indices analyzer analyze_wildcard default_operator df
    expand_wildcards ignore_unavailable lenient min_score routing preference
    terminate_after query
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
