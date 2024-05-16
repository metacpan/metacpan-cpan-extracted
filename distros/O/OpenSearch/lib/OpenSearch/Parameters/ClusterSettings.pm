package OpenSearch::Parameters::ClusterSettings;
use Moose::Role;

# Request Body is always preferred!
with
  "OpenSearch::Parameters::URL::flat_settings",
  "OpenSearch::Parameters::URL::include_defaults",
  "OpenSearch::Parameters::URL::cluster_manager_timeout",
  "OpenSearch::Parameters::URL::timeout",
  "OpenSearch::Parameters::Body::cluster_settings",
;

1;