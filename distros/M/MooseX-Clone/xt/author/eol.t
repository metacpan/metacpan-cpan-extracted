use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooseX/Clone.pm',
    'lib/MooseX/Clone/Meta/Attribute/Trait/Clone.pm',
    'lib/MooseX/Clone/Meta/Attribute/Trait/Clone/Base.pm',
    'lib/MooseX/Clone/Meta/Attribute/Trait/Clone/Std.pm',
    'lib/MooseX/Clone/Meta/Attribute/Trait/Copy.pm',
    'lib/MooseX/Clone/Meta/Attribute/Trait/NoClone.pm',
    'lib/MooseX/Clone/Meta/Attribute/Trait/StorableClone.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_basic.t',
    't/02_auto_deref.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
