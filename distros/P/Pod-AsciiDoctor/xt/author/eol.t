use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/pod2asciidoctor',
    'lib/Pod/AsciiDoctor.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-conversion.t',
    't/data/pod.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
