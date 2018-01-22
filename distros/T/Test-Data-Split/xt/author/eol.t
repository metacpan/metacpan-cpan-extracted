use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/Data/Split.pm',
    'lib/Test/Data/Split/Backend/Hash.pm',
    'lib/Test/Data/Split/Backend/ValidateHash.pm',
    't/00-compile.t',
    't/lib/DataSplitHashTest.pm',
    't/lib/DataSplitValidateHashTest1.pm',
    't/lib/DataSplitValidateHashTest2.pm',
    't/run.t',
    't/validate-hash-1.t',
    't/validate-hash-2.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
