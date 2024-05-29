package OpenSearch::Parameters::Search::Search;
use Moose::Role;
use OpenSearch::Filter::Source;

#use Moose::Util::TypeConstraints;

#enum 'HealthWaitForStatus'   => [qw/green yellow red/];

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

has 'sort' => (
  is          => 'rw',
  isa         => 'ArrayRef[HashRef]',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'version' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
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
    type        => 'body',
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

has 'stats' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has '_source' => (
  is          => 'rw',
  isa         => 'OpenSearch::Filter::Source | Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'size' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'seq_no_primary_term' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
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

has 'indices_boost' => (
  is          => 'rw',
  isa         => 'ArrayRef[HashRef]',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'from' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'explain' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'fields' => (
  is          => 'rw',
  isa         => 'ArrayRef',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'docvalue_fields' => (
  is          => 'rw',
  isa         => 'ArrayRef[HashRef]',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'aggs' => (
  is          => 'rw',
  isa         => 'HashRef',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'search_after' => (
  is          => 'rw',
  isa         => 'ArrayRef',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'scroll_id' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'body',
    required    => 0,
  }
);

has 'max_concurrent_shard_requests' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'stored_fields' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

has 'ignore_throttled' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
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

has 'q' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'request_cache' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
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

has 'suggest_text' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'rest_total_hits_as_int' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
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

has 'track_total_hits' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'cancel_after_time_interval' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has '_source_includes' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'pre_filter_shard_size' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'suggest_field' => (
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

has 'suggest_size' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
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

has 'suggest_mode' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'allow_partial_search_results' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

has 'search_type' => (
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

has 'typed_keys' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
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

has 'batched_reduce_size' => (
  is          => 'rw',
  isa         => 'Int',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
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

has '_source_excludes' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

has 'track_scores' => (
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

has 'ccs_minimize_roundtrips' => (
  is          => 'rw',
  isa         => 'Bool',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'encode_bool',
    type        => 'url',
    required    => 0,
  }
);

has 'scroll' => (
  is          => 'rw',
  isa         => 'Str',
  metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
  description => {
    encode_func => 'as_is',
    type        => 'url',
    required    => 0,
  }
);

around [
  qw/
    index sort version timeout terminate_after stats _source size seq_no_primary_term
    query min_score indices_boost from explain fields docvalue_fields aggs
    search_after scroll_id max_concurrent_shard_requests stored_fields ignore_throttled
    allow_no_indices q request_cache analyze_wildcard suggest_text rest_total_hits_as_int
    routing track_total_hits cancel_after_time_interval _source_includes pre_filter_shard_size
    suggest_field preference suggest_size default_operator suggest_mode allow_partial_search_results
    search_type expand_wildcards typed_keys ignore_unavailable df batched_reduce_size analyzer
    _source_excludes track_scores lenient ccs_minimize_roundtrips scroll
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
