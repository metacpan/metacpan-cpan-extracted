use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
