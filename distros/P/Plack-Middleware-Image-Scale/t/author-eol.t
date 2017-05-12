
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
    'lib/Plack/Middleware/Image/Scale.pm',
    't/00-compile.t',
    't/00_compile.t',
    't/01_basic.t',
    't/02_responsetypes.t',
    't/03_invalid.t',
    't/04_size.t',
    't/05_format.t',
    't/10_args.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/lib/Test/Invocation/Arguments.pm',
    't/release-check-changes.t',
    't/release-cpan-changes.t',
    't/release-distmeta.t',
    't/release-meta-json.t',
    't/release-portability.t',
    't/release-synopsis.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
