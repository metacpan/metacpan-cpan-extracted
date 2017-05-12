use strict;
use warnings;
use Test::More;
use Test::Base::Less;
use PLON;

filters {
    input => ['eval'],
};

my $plon = PLON->new();
for my $block (blocks) {
    subtest $block->expected, sub {
        my $got = $plon->encode($block->input);
        is $got, $block->expected;
        is_deeply eval($got), $block->input;
        is_deeply $plon->decode($got), $block->input;

        {
            # decode with eval
            my $dat = eval "use utf8;$got";
            ok !$@ or diag $@;
            is_deeply $dat, $block->input;
        }
     };
}

done_testing;

__DATA__

===
--- input: ["a\nb"]
--- expected: ["a\nb",]

===
--- input: ["a\tb"]
--- expected: ["a\tb",]

===
--- input: ["a\fb"]
--- expected: ["a\fb",]

===
--- input: ["a\r\b\a\eb"]
--- expected: ["a\r\b\a\eb",]


