use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Statocles/AppRole/ExtraFeeds.pm',
    't/00-compile/lib_Statocles_AppRole_ExtraFeeds_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/blog_app.t',
    't/blog_app_paged.t',
    't/lib/KENTNL/Utils.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
