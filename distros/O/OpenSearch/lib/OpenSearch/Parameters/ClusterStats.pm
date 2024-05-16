package OpenSearch::Parameters::ClusterStats;
use Moose::Role;

# Request Body is always preferred!
with
  "OpenSearch::Parameters::URL::nodes",
;

1;