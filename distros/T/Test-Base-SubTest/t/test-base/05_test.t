use strict;
use warnings;
use utf8;
use Test::Base::SubTest;

filters {
    code => [qw/eval/],
};

my $i = 0;
run {
    my $block = shift;
    if (++$i == 1) {
        is_deeply $block->code, +{ a => 'b' };
    } else {
        is scalar  $block->code, 'X';
        is_deeply [$block->code], [qw/X Y/];
    }
};

is  $i, 2;

done_testing;
__DATA__

===
--- code: +{ a => 'b' }

===
--- code
(
    'X' => 'Y'
)
