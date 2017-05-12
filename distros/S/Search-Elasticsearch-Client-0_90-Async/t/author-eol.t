
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
    'lib/Search/Elasticsearch/Client/0_90/Async.pm',
    'lib/Search/Elasticsearch/Client/0_90/Async/Bulk.pm',
    'lib/Search/Elasticsearch/Client/0_90/Async/Scroll.pm',
    't/Client_0_90_Async/00_print_version.t',
    't/Client_0_90_Async/10_live.t',
    't/Client_0_90_Async/15_conflict.t',
    't/Client_0_90_Async/20_fork_aehttp.t',
    't/Client_0_90_Async/21_fork_mojo.t',
    't/Client_0_90_Async/30_bulk_add_action.t',
    't/Client_0_90_Async/31_bulk_helpers.t',
    't/Client_0_90_Async/32_bulk_flush.t',
    't/Client_0_90_Async/33_bulk_errors.t',
    't/Client_0_90_Async/34_bulk_cxn_errors.t',
    't/Client_0_90_Async/40_scroll.t',
    't/Client_0_90_Async/50_reindex.t',
    't/Client_0_90_Async/60_auth_aehttp.t',
    't/Client_0_90_Async/61_auth_mojo.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/lib/LogCallback.pl',
    't/lib/MockAsyncCxn.pm',
    't/lib/MockAsyncTransport.pm',
    't/lib/bad_cacert.pem',
    't/lib/default_async_cxn.pl',
    't/lib/default_cxn.pl',
    't/lib/es_async.pl',
    't/lib/es_async_auth.pl',
    't/lib/es_async_fork.pl',
    't/lib/es_sync.pl',
    't/lib/index_test_data.pl'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
