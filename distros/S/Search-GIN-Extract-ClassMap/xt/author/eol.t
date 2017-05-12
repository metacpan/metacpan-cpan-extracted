use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Search/GIN/Extract/ClassMap.pm',
    'lib/Search/GIN/Extract/ClassMap/Does.pm',
    'lib/Search/GIN/Extract/ClassMap/Isa.pm',
    'lib/Search/GIN/Extract/ClassMap/Like.pm',
    'lib/Search/GIN/Extract/ClassMap/Role.pm',
    'lib/Search/GIN/Extract/ClassMap/Types.pm',
    't/00-compile/lib_Search_GIN_Extract_ClassMap_Does_pm.t',
    't/00-compile/lib_Search_GIN_Extract_ClassMap_Isa_pm.t',
    't/00-compile/lib_Search_GIN_Extract_ClassMap_Like_pm.t',
    't/00-compile/lib_Search_GIN_Extract_ClassMap_Role_pm.t',
    't/00-compile/lib_Search_GIN_Extract_ClassMap_Types_pm.t',
    't/00-compile/lib_Search_GIN_Extract_ClassMap_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/02-Init.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
