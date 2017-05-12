use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Pod/Eventual/Reconstruct.pm',
    'lib/Pod/Eventual/Reconstruct/LazyCut.pm',
    't/00-compile/lib_Pod_Eventual_Reconstruct_LazyCut_pm.t',
    't/00-compile/lib_Pod_Eventual_Reconstruct_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-reconstruct/basic.t',
    't/02-lazycut/basic.t',
    't/02-lazycut/grep.t',
    't/02-lazycut/grep2.t',
    't/lib/EventPipe.pm',
    't/lib/EventPipe/Lazy.pm',
    't/lib/EventsToList.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
