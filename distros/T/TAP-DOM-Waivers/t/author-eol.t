
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/tap-waive',
    'lib/App/Prove/Plugin/Waivers.pm',
    'lib/TAP/DOM/Waivers.pm',
    'lib/TAP/DOM/Waivers/Formatter.pm',
    'lib/TAP/DOM/Waivers/Formatter/Session.pm',
    't/00-compile.t',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/failed_IPv6.tap',
    't/manifest.t',
    't/metawaiver.yml',
    't/metawaiverdesc.yml',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/simpletests.tap',
    't/waiver.yml',
    't/waivers.t',
    't/waivers_tapdomlike.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
