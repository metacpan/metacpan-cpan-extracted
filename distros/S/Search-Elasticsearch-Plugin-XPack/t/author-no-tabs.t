
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
    'lib/Search/Elasticsearch/Plugin/XPack.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/1_0.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/1_0/Role/API.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/1_0/Watcher.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/2_0.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/2_0/Graph.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/2_0/License.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/2_0/Role/API.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/2_0/Shield.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/2_0/Watcher.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/5_0.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/5_0/Graph.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/5_0/License.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/5_0/Role/API.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/5_0/Security.pm',
    'lib/Search/Elasticsearch/Plugin/XPack/5_0/Watcher.pm',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
