use strict;
use warnings;
use utf8;
use Test::More;

use Spellunker;

for (
    '~/',
    '~foo/',
    '~/bar',
    '~/bar/',
    '~/bar/baz',
    '/dev/tty',
    't/00_compile.t',
) {
    ok Spellunker::looks_like_file_path($_), $_;
}
ok !Spellunker::looks_like_file_path('UTF-8');

done_testing;

