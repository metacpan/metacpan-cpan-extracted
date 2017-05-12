use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Path/Router.pm',
    'lib/Path/Router/Route.pm',
    'lib/Path/Router/Route/Match.pm',
    'lib/Path/Router/Shell.pm',
    'lib/Path/Router/Types.pm',
    'lib/Test/Path/Router.pm',
    't/00-compile.t',
    't/001_basic.t',
    't/002_w_optional.t',
    't/003_messy_paths.t',
    't/004_match_test.t',
    't/005_match_test_w_optional.t',
    't/006_match_w_targets.t',
    't/007_match_exact_urls.t',
    't/008_uri_for.t',
    't/009_include_other_router.t',
    't/010_example_cat_chained_URIs.t',
    't/011_incorrect_validation_warning.t',
    't/012_ambiguous_routes.t',
    't/013_false_path_components.t',
    't/014_test_path_router.t',
    't/100_bug.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
