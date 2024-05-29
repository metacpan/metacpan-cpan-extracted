use strict;
use Test::More 0.98;
use Test::Pod::Coverage;

pod_coverage_ok( 'OpenSearch', { also_private => [qr/^[A-Z_]+$/], }, 'OpenSearch seems to be documented' );

#pod_coverage_ok(
#  'OpenSearch::Cluster',
#  { also_private => [qr/^[A-Z_]+$/], },
#  'OpenSearch::Cluster seems to be documented'
#);
#pod_coverage_ok(
#  'OpenSearch::Cluster::Allocation',
#  { also_private => [qr/^[A-Z_]+$/], },
#  'OpenSearch::Cluster::Allocation seems to be documented'
#);
#pod_coverage_ok(
#  'OpenSearch::Cluster::Health',
#  { also_private => [qr/^[A-Z_]+$/], },
#  'OpenSearch::Cluster::Health seems to be documented'
#);
#pod_coverage_ok(
#  'OpenSearch::Cluster::Settings',
#  { also_private => [qr/^[A-Z_]+$/], },
#  'OpenSearch::Cluster::Settings seems to be documented'
#);
#pod_coverage_ok(
#  'OpenSearch::Cluster::Stats',
#  { also_private => [qr/^[A-Z_]+$/], },
#  'OpenSearch::Cluster::Stats seems to be documented'
#);

done_testing;

