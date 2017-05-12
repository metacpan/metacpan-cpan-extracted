use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Module/Data.pm',
    't/00-compile/lib_Module_Data_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_basic.t',
    't/02_version.t',
    't/03_fake_system.t',
    't/03_t/lib/VERSION/ARCH-linux/.keep',
    't/03_t/lib/VERSION/ARCH-linux/Test/A.pm',
    't/03_t/lib/VERSION/ARCH-linux/Test/B.pm',
    't/03_t/lib/VERSION/ARCH-linux/Test/C.pm',
    't/03_t/lib/VERSION/Test/A.pm',
    't/03_t/lib/VERSION/Test/B.pm',
    't/03_t/lib/VERSION/Test/C.pm',
    't/03_t/lib/VERSION/Test/D.pm',
    't/03_t/lib/site_perl/VERSION/ARCH-linux/.keep',
    't/03_t/lib/site_perl/VERSION/ARCH-linux/Test/A.pm',
    't/03_t/lib/site_perl/VERSION/Test/A.pm',
    't/03_t/lib/site_perl/VERSION/Test/B.pm',
    't/tlib/Whitelist.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
