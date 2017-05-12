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
--- input: []
--- expected: []

===
--- input: ["a"]
--- expected: ["a",]

===
--- input: ["a\""]
--- expected: ["a\"",]

===
--- input: {x => "y"}
--- expected: {"x"=>"y",}

===
--- input: [0]
--- expected: [0,]

===
--- input: ["\$x"]
--- expected: ["\$x",]

===
--- input: ["\@x"]
--- expected: ["\@x",]

===
--- input: ["\\x"]
--- expected: ["\\x",]

===
--- input: undef
--- expected: undef

===
--- input: [undef]
--- expected: [undef,]

===
--- input: \1
--- expected: \(1)

===
--- input: \\1
--- expected: \(\(1))

===
--- input: bless([9], 'X')
--- expected: bless([9,],"X")

===
--- input: bless({a=>9}, 'X')
--- expected: bless({"a"=>9,},"X")

===
--- input: bless(\(do {my $o=1}), 'X')
--- expected: bless(\(do {my $o=1}),"X")

