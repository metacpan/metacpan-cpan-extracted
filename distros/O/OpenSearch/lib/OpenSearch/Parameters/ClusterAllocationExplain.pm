package OpenSearch::Parameters::ClusterAllocationExplain;
use Moose::Role;

# Request Body is always preferred!
with
  "OpenSearch::Parameters::URL::include_yes_decisions",
  "OpenSearch::Parameters::URL::include_disk_info",
  "OpenSearch::Parameters::Body::current_node",
  "OpenSearch::Parameters::Body::index",
  "OpenSearch::Parameters::Body::primary",
  "OpenSearch::Parameters::Body::shard",
;

1;