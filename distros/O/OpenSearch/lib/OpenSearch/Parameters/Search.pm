package OpenSearch::Parameters::Search;
use Moose::Role;

# Request Body is always preferred!
with
  "OpenSearch::Parameters::Body::version",
  "OpenSearch::Parameters::Body::size",
  "OpenSearch::Parameters::Body::_source",
  "OpenSearch::Parameters::Body::from",
  "OpenSearch::Parameters::Body::explain",
  "OpenSearch::Parameters::Body::indices_boost",
  "OpenSearch::Parameters::Body::query",
  "OpenSearch::Parameters::Body::fields",
  "OpenSearch::Parameters::Body::stats",
  "OpenSearch::Parameters::Body::terminate_after",
  "OpenSearch::Parameters::Body::seq_no_primary_term",
  "OpenSearch::Parameters::Body::timeout",
  "OpenSearch::Parameters::Body::docvalue_fields",
  "OpenSearch::Parameters::Body::min_score",
  "OpenSearch::Parameters::Body::sort",

  # Pagination. Not documented in Search API
  "OpenSearch::Parameters::Body::search_after",

  "OpenSearch::Parameters::URL::max_concurrent_shard_requests",
  "OpenSearch::Parameters::URL::stored_fields",
  "OpenSearch::Parameters::URL::ignore_throttled",
  "OpenSearch::Parameters::URL::allow_no_indices",
  "OpenSearch::Parameters::URL::q",
  "OpenSearch::Parameters::URL::request_cache",
  "OpenSearch::Parameters::URL::analyze_wildcard",
  "OpenSearch::Parameters::URL::suggest_text",
  "OpenSearch::Parameters::URL::rest_total_hits_as_int",
  "OpenSearch::Parameters::URL::routing",
  "OpenSearch::Parameters::URL::track_total_hits",
  "OpenSearch::Parameters::URL::cancel_after_time_interval",
  "OpenSearch::Parameters::URL::_source_includes",
  "OpenSearch::Parameters::URL::pre_filter_shard_size",
  "OpenSearch::Parameters::URL::suggest_field",
  "OpenSearch::Parameters::URL::preference",
  "OpenSearch::Parameters::URL::suggest_size",
  "OpenSearch::Parameters::URL::default_operator",
  "OpenSearch::Parameters::URL::suggest_mode",
  "OpenSearch::Parameters::URL::allow_partial_search_results",
  "OpenSearch::Parameters::URL::search_type",
  "OpenSearch::Parameters::URL::expand_wildcards",
  "OpenSearch::Parameters::URL::typed_keys",
  "OpenSearch::Parameters::URL::ignore_unavailable",
  "OpenSearch::Parameters::URL::df",
  "OpenSearch::Parameters::URL::batched_reduce_size",
  "OpenSearch::Parameters::URL::analyzer",
  "OpenSearch::Parameters::URL::_source_excludes",
  "OpenSearch::Parameters::URL::track_scores",
  "OpenSearch::Parameters::URL::lenient",
  "OpenSearch::Parameters::URL::ccs_minimize_roundtrips",
  "OpenSearch::Parameters::URL::scroll",

  #"OpenSearch::Parameters::URL::sort", # According to search_after, sort can be used in body...
  "OpenSearch::Parameters::Path::index",;

1;
