
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Search/Elasticsearch/Client/7_0.pm',
    'lib/Search/Elasticsearch/Client/7_0/Bulk.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Autoscaling.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/CCR.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Cat.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Cluster.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/DanglingIndices.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/DataFrame.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/DataFrameTransformDeprecated.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Enrich.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Eql.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Graph.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/ILM.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Indices.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Ingest.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/License.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/ML.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Migration.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Monitoring.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Nodes.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Rollup.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/SQL.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/SSL.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/SearchableSnapshots copy.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Security.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Slm.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Snapshot.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Tasks.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Transform.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/Watcher.pm',
    'lib/Search/Elasticsearch/Client/7_0/Direct/XPack.pm',
    'lib/Search/Elasticsearch/Client/7_0/Role/API.pm',
    'lib/Search/Elasticsearch/Client/7_0/Role/Bulk.pm',
    'lib/Search/Elasticsearch/Client/7_0/Role/Scroll.pm',
    'lib/Search/Elasticsearch/Client/7_0/Scroll.pm',
    'lib/Search/Elasticsearch/Client/7_0/TestServer.pm',
    't/Client_7_0/00_print_version.t',
    't/Client_7_0/10_live.t',
    't/Client_7_0/20_fork_httptiny.t',
    't/Client_7_0/21_fork_lwp.t',
    't/Client_7_0/23_fork_netcurl.t',
    't/Client_7_0/30_bulk_add_action.t',
    't/Client_7_0/31_bulk_helpers.t',
    't/Client_7_0/32_bulk_flush.t',
    't/Client_7_0/33_bulk_errors.t',
    't/Client_7_0/34_bulk_cxn_errors.t',
    't/Client_7_0/40_scroll.t',
    't/Client_7_0/60_auth_httptiny.t',
    't/Client_7_0/61_auth_lwp.t',
    't/Client_7_0/62_auth_netcurl.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/lib/LogCallback.pl',
    't/lib/MockCxn.pm',
    't/lib/bad_cacert.pem',
    't/lib/default_cxn.pl',
    't/lib/es_sync.pl',
    't/lib/es_sync_auth.pl',
    't/lib/es_sync_fork.pl',
    't/lib/index_test_data.pl',
    't/lib/index_test_data_7.pl'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
