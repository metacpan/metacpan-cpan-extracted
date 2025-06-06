use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooX/StrictConstructor.pm',
    'lib/MooX/StrictConstructor/Role/BuildAll.pm',
    'lib/MooX/StrictConstructor/Role/Constructor.pm',
    'lib/MooX/StrictConstructor/Role/Constructor/Base.pm',
    'lib/MooX/StrictConstructor/Role/Constructor/Late.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
