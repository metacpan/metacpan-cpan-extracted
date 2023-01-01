
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Search/Elasticsearch/Client/8_0/Async.pm',
    'lib/Search/Elasticsearch/Client/8_0/Async/Bulk.pm',
    'lib/Search/Elasticsearch/Client/8_0/Async/Scroll.pm',
    'lib/Search/Elasticsearch/Client/8_0/Direct/AsyncSearch.pm',
    't/Client_8_0_Async/00_print_version.t',
    't/Client_8_0_Async/10_live.t',
    't/Client_8_0_Async/20_fork_aehttp.t',
    't/Client_8_0_Async/21_fork_mojo.t',
    't/Client_8_0_Async/30_bulk_add_action.t',
    't/Client_8_0_Async/31_bulk_helpers.t',
    't/Client_8_0_Async/32_bulk_flush.t',
    't/Client_8_0_Async/33_bulk_errors.t',
    't/Client_8_0_Async/34_bulk_cxn_errors.t',
    't/Client_8_0_Async/40_scroll.t',
    't/Client_8_0_Async/60_auth_aehttp.t',
    't/Client_8_0_Async/61_auth_mojo.t',
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
    't/lib/index_test_data.pl',
    't/lib/index_test_data_7.pl'
);

notabs_ok($_) foreach @files;
done_testing;
