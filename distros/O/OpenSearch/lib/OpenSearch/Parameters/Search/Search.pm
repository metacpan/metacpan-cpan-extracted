package OpenSearch::Parameters::Search::Search;
use strict;
use warnings;
use feature         qw(state);
use Types::Standard qw(Str Bool Int ArrayRef HashRef);
use Moo::Role;

#use OpenSearch::Filter::Source;

with 'OpenSearch::Parameters';

has 'index' => (
  is  => 'rw',
  isa => Str,
);

has 'sort' => (
  is  => 'rw',
  isa => ArrayRef [HashRef],
);

has 'version' => (
  is  => 'rw',
  isa => Bool,
);

has 'timeout' => (
  is  => 'rw',
  isa => Str,
);

has 'terminate_after' => (
  is  => 'rw',
  isa => Int,
);

has 'stats' => (
  is  => 'rw',
  isa => Str,
);

has '_source' => (
  is => 'rw',

  # TODO
  #isa         => 'OpenSearch::Filter::Source | Str',
  isa         => Str,
  description => {
    encode_func => 'as_is',
    type        => 'body',
  }
);

has 'size' => (
  is  => 'rw',
  isa => Int,
);

has 'seq_no_primary_term' => (
  is  => 'rw',
  isa => Bool,
);

has 'query' => (
  is  => 'rw',
  isa => HashRef,
);

has 'min_score' => (
  is  => 'rw',
  isa => Int,
);

has 'indices_boost' => (
  is  => 'rw',
  isa => ArrayRef [HashRef],
);

has 'from' => (
  is  => 'rw',
  isa => Int,
);

has 'explain' => (
  is  => 'rw',
  isa => Str,
);

has 'fields' => (
  is  => 'rw',
  isa => ArrayRef,
);

has 'docvalue_fields' => (
  is  => 'rw',
  isa => ArrayRef [HashRef],
);

has 'aggs' => (
  is  => 'rw',
  isa => HashRef,
);

has 'search_after' => (
  is  => 'rw',
  isa => ArrayRef,
);

has 'scroll_id' => (
  is  => 'rw',
  isa => Str,
);

has 'max_concurrent_shard_requests' => (
  is  => 'rw',
  isa => Int,
);

has 'stored_fields' => (
  is  => 'rw',
  isa => Bool,
);

has 'ignore_throttled' => (
  is  => 'rw',
  isa => Bool,
);

has 'allow_no_indices' => (
  is  => 'rw',
  isa => Bool,
);

has 'q' => (
  is  => 'rw',
  isa => Str,
);

has 'request_cache' => (
  is  => 'rw',
  isa => Bool,
);

has 'analyze_wildcard' => (
  is  => 'rw',
  isa => Bool,
);

has 'suggest_text' => (
  is  => 'rw',
  isa => Str,
);

has 'rest_total_hits_as_int' => (
  is  => 'rw',
  isa => Bool,
);

has 'routing' => (
  is  => 'rw',
  isa => Str,
);

# See https://github.com/localh0rst/OpenSearch-Perl/issues/8
has 'track_total_hits' => (
  is  => 'rw',
  isa => Str,
);

has 'cancel_after_time_interval' => (
  is  => 'rw',
  isa => Str,
);

has '_source_includes' => (
  is  => 'rw',
  isa => Str,
);

has 'pre_filter_shard_size' => (
  is  => 'rw',
  isa => Int,
);

has 'suggest_field' => (
  is  => 'rw',
  isa => Str,
);

has 'preference' => (
  is  => 'rw',
  isa => Str,
);

has 'suggest_size' => (
  is  => 'rw',
  isa => Int,
);

has 'default_operator' => (
  is  => 'rw',
  isa => Str,
);

has 'suggest_mode' => (
  is  => 'rw',
  isa => Str,
);

has 'allow_partial_search_results' => (
  is  => 'rw',
  isa => Bool,
);

has 'search_type' => (
  is  => 'rw',
  isa => Str,
);

has 'expand_wildcards' => (
  is  => 'rw',
  isa => Str,
);

has 'typed_keys' => (
  is  => 'rw',
  isa => Bool,
);

has 'ignore_unavailable' => (
  is  => 'rw',
  isa => Bool,
);

has 'df' => (
  is  => 'rw',
  isa => Str,
);

has 'batched_reduce_size' => (
  is  => 'rw',
  isa => Int,
);

has 'analyzer' => (
  is  => 'rw',
  isa => Str,
);

has '_source_excludes' => (
  is  => 'rw',
  isa => Str,
);

has 'track_scores' => (
  is  => 'rw',
  isa => Bool,
);

has 'lenient' => (
  is  => 'rw',
  isa => Bool,
);

has 'ccs_minimize_roundtrips' => (
  is  => 'rw',
  isa => Bool,
);

has 'scroll' => (
  is  => 'rw',
  isa => Str,
);

has 'highlight' => (
  is  => 'rw',
  isa => HashRef,
);

has 'profile' => (
  is  => 'rw',
  isa => Bool,
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
    _source_excludes track_scores lenient ccs_minimize_roundtrips scroll highlight profile
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

sub api_spec {
  state $s = +{
    index => {
      encode_func => 'as_is',
      type        => 'path',
    },
    sort => {
      encode_func => 'as_is',
      type        => 'body',
    },
    version => {
      encode_func => 'encode_bool',
      type        => 'body',
    },
    timeout => {
      encode_func => 'as_is',
      type        => 'body',
    },
    terminate_after => {
      encode_func => 'as_is',
      type        => 'body',
    },
    stats => {
      encode_func => 'as_is',
      type        => 'body',
    },
    _source => {
      encode_func => 'as_is',
      type        => 'body',
    },
    size => {
      encode_func => 'as_is',
      type        => 'body',
    },
    seq_no_primary_term => {
      encode_func => 'encode_bool',
      type        => 'body',
    },
    query => {
      encode_func => 'as_is',
      type        => 'body',
    },
    min_score => {
      encode_func => 'as_is',
      type        => 'body',
    },
    indices_boost => {
      encode_func => 'as_is',
      type        => 'body',
    },
    from => {
      encode_func => 'as_is',
      type        => 'body',
    },
    explain => {
      encode_func => 'as_is',
      type        => 'body',
    },
    fields => {
      encode_func => 'as_is',
      type        => 'body',
    },
    docvalue_fields => {
      encode_func => 'as_is',
      type        => 'body',
    },
    aggs => {
      encode_func => 'as_is',
      type        => 'body',
    },
    search_after => {
      encode_func => 'as_is',
      type        => 'body',
    },
    scroll_id => {
      encode_func => 'as_is',
      type        => 'body',
    },
    max_concurrent_shard_requests => {
      encode_func => 'as_is',
      type        => 'url',
    },
    stored_fields => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    ignore_throttled => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    allow_no_indices => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    q => {
      encode_func => 'as_is',
      type        => 'url',
    },
    request_cache => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    analyze_wildcard => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    suggest_text => {
      encode_func => 'as_is',
      type        => 'url',
    },
    rest_total_hits_as_int => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    routing => {
      encode_func => 'as_is',
      type        => 'url',
    },
    track_total_hits => {
      encode_func => 'as_is',
      type        => 'url',
    },
    cancel_after_time_interval => {
      encode_func => 'as_is',
      type        => 'url',
    },
    _source_includes => {
      encode_func => 'as_is',
      type        => 'url',
    },
    pre_filter_shard_size => {
      encode_func => 'as_is',
      type        => 'url',
    },
    suggest_field => {
      encode_func => 'as_is',
      type        => 'url',
    },
    preference => {
      encode_func => 'as_is',
      type        => 'url',
    },
    suggest_size => {
      encode_func => 'as_is',
      type        => 'url',
    },
    default_operator => {
      encode_func => 'as_is',
      type        => 'url',
    },
    suggest_mode => {
      encode_func => 'as_is',
      type        => 'url',
    },
    allow_partial_search_results => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    search_type => {
      encode_func => 'as_is',
      type        => 'url',
    },
    expand_wildcards => {
      encode_func => 'as_is',
      type        => 'url',
    },
    typed_keys => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    ignore_unavailable => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    df => {
      encode_func => 'as_is',
      type        => 'url',
    },
    batched_reduce_size => {
      encode_func => 'as_is',
      type        => 'url',
    },
    analyzer => {
      encode_func => 'as_is',
      type        => 'url',
    },
    _source_excludes => {
      encode_func => 'as_is',
      type        => 'url',
    },
    track_scores => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    lenient => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    ccs_minimize_roundtrips => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    scroll => {
      encode_func => 'as_is',
      type        => 'url',
    },
    highlight => {
      encode_func => 'as_is',
      type        => 'body',
    },
    profile => {
      encode_func => 'encode_bool',
      type        => 'body',
    },
  };
}

1;
