use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Package/Strictures.pm',
    'lib/Package/Strictures/Register.pm',
    'lib/Package/Strictures/Registry.pm',
    't/00-compile/lib_Package_Strictures_Register_pm.t',
    't/00-compile/lib_Package_Strictures_Registry_pm.t',
    't/00-compile/lib_Package_Strictures_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-01-nostrictures.t',
    't/01-02-strictures.t',
    't/01-03-loadfile.t',
    't/01-poc-lib/Example.pm',
    't/strictures.ini'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
