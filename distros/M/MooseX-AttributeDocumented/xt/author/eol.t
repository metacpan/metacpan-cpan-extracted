use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Moose/Meta/Attribute/Custom/Trait/Documented.pm',
    'lib/MooseX/AttributeDocumented.pm',
    'lib/MooseX/AttributeDocumented/Meta/Attribute/Trait/Documented.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
