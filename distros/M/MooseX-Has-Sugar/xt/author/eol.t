use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooseX/Has/Sugar.pm',
    'lib/MooseX/Has/Sugar/Minimal.pm',
    'lib/MooseX/Has/Sugar/Saccharin.pm',
    't/00-compile/lib_MooseX_Has_Sugar_Minimal_pm.t',
    't/00-compile/lib_MooseX_Has_Sugar_Saccharin_pm.t',
    't/00-compile/lib_MooseX_Has_Sugar_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/04_values.t',
    't/05_is.t',
    't/06_attr_required.t',
    't/07_attr_lazy_build.t',
    't/08_saccharin.t',
    't/09_saccharin.t',
    't/10_saccharin.t',
    't/lib/T10Saccharin/TestPackage.pm',
    't/lib/T4Values/AMinimal.pm',
    't/lib/T4Values/BDeclare.pm',
    't/lib/T4Values/CDeclareRo.pm',
    't/lib/T4Values/DEverything.pm',
    't/lib/T4Values/EMixed.pm',
    't/lib/T4Values/TestCant.pm',
    't/lib/T5Is/TestPackage.pm',
    't/lib/T6AttrRequired/TestPackage.pm',
    't/lib/T7AttrLazyBuild/TestPackage.pm',
    't/lib/T8Saccharin/TestPackage.pm',
    't/lib/T9Saccharin/TestPackage.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
