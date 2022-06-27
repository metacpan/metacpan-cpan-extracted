use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooseX/LocalAttribute.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/classaccessor.t',
    't/classic.t',
    't/lib/Tester.pm',
    't/lib/Tester/ClassAccessor.pm',
    't/lib/Tester/Classic.pm',
    't/lib/Tester/Mo.pm',
    't/lib/Tester/MojoBase.pm',
    't/lib/Tester/Moo.pm',
    't/lib/Tester/Moose.pm',
    't/lib/Tester/Mouse.pm',
    't/lib/Tester/ObjectPad.pm',
    't/lib/Tester/UtilH2O.pm',
    't/mo.t',
    't/mojobase.t',
    't/moo.t',
    't/moose.t',
    't/mouse.t',
    't/objectpad.t',
    't/utilh2o.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
