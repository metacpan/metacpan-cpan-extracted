use strict;
use Test::More 0.98;
use Test::Pod::Coverage;

pod_coverage_ok( 'OpenSearch', { also_private => [qr/^[A-Z_]+$/], }, 'OpenSearch seems to be documented' );

pod_coverage_ok(
  'OpenSearch::Cluster',
  { also_private => [qr/^[A-Z_]+$/], },
  'OpenSearch::Cluster seems to be documented'
);

#pod_coverage_ok(
#  'OpenSearch::Remote',
#{ also_private => [qr/^[A-Z_]+$/], },
#'OpenSearch::Remote seems to be documented'
#);

pod_coverage_ok(
  'OpenSearch::Search',
  { also_private => [qr/^[A-Z_]+$/], },
  'OpenSearch::Search seems to be documented'
);

pod_coverage_ok( 'OpenSearch::Index', { also_private => [qr/^[A-Z_]+$/], },
  'OpenSearch::Index seems to be documented' );

pod_coverage_ok(
  'OpenSearch::Document',
  { also_private => [qr/^[A-Z_]+$/], },
  'OpenSearch::Document seems to be documented'
);

#pod_coverage_ok(
#  'OpenSearch::Security',
#{ also_private => [qr/^[A-Z_]+$/], },
#'OpenSearch::Security seems to be documented'
#);

done_testing;

