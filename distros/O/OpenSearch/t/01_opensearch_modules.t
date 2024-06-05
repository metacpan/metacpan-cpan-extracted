use strict;
use Test::More 0.98;
use Data::Dumper;

plan skip_all => 'To test Modules, set OS_HOST, OS_USER, OS_PASS, OS_INDEX in ENV'
  unless $ENV{OS_HOST} && $ENV{OS_USER} && $ENV{OS_PASS} && $ENV{OS_INDEX};

my $host  = $ENV{OS_HOST};
my $user  = $ENV{OS_USER};
my $pass  = $ENV{OS_PASS};
my $index = $ENV{OS_INDEX};

print Dumper \%ENV;

use OpenSearch;

my $os = OpenSearch->new(
  user            => $user,
  pass            => $pass,
  hosts           => [$host],
  secure          => 1,
  allow_insecure  => 1,
  async           => 0,
  pool_count      => 10,
  max_connections => 50,
);

my $index_api  = $os->index;
my $search_api = $os->search;

my $doc_api     = $os->document;
my $cluster_api = $os->cluster;
my $remote_api  = $os->remote;

# Test the objects
isa_ok $os,         'OpenSearch',         'OpenSearch object created';
isa_ok $index_api,  'OpenSearch::Index',  'Index object created';
isa_ok $search_api, 'OpenSearch::Search', 'Search object created';

isa_ok $doc_api,     'OpenSearch::Document', 'Document object created';
isa_ok $cluster_api, 'OpenSearch::Cluster',  'Cluster object created';
isa_ok $remote_api,  'OpenSearch::Remote',   'Remote object created';

isa_ok $cluster_api->health, 'OpenSearch::Response', 'Sync returns OpenSearch::Response object';

# Switch to async
$os->base->async(1);
my $promise = $cluster_api->health;

isa_ok $promise, 'Mojo::Promise', 'Async returns Mojo::Promise object';

$promise->then( sub {
  my $res = shift;
  isa_ok $res, 'OpenSearch::Response', 'Async returns OpenSearch::Response object';
} )->wait;

done_testing;

