package OpenSearch::Parameters::ClusterHealth;
use Moose::Role;

# Request Body is always preferred!
with
  "OpenSearch::Parameters::URL::expand_wildcards",
  "OpenSearch::Parameters::URL::level",
  "OpenSearch::Parameters::URL::awareness_attribute",
  "OpenSearch::Parameters::URL::local",
  "OpenSearch::Parameters::URL::cluster_manager_timeout",
  "OpenSearch::Parameters::URL::timeout",
  "OpenSearch::Parameters::URL::wait_for_active_shards",
  "OpenSearch::Parameters::URL::wait_for_nodes",
  "OpenSearch::Parameters::URL::wait_for_events",
  "OpenSearch::Parameters::URL::wait_for_no_relocating_shards",
  "OpenSearch::Parameters::URL::wait_for_no_initializing_shards",
  "OpenSearch::Parameters::URL::wait_for_status",
  "OpenSearch::Parameters::Path::index",
;

1;