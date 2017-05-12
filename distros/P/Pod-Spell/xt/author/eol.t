use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/podspell',
    'lib/Pod/Spell.pm',
    'lib/Pod/Wordlist.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/debug.t',
    't/fix_21.t',
    't/get-stopwords.t',
    't/text-block.t',
    't/utf8.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
