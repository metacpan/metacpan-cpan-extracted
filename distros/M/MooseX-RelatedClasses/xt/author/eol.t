use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooseX/RelatedClasses.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/all_in_namespace.t',
    't/basic.t',
    't/blank_namespace.t',
    't/custom-decamelization.t',
    't/desnaking-with-doublecolon.t',
    't/funcs.pm',
    't/lib/Test/Class/__WONKY__.pm',
    't/lib/Test/Class/__WONKY__/One.pm',
    't/lib/Test/Class/__WONKY__/Sub/One.pm',
    't/multiple.t',
    't/sugar.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
