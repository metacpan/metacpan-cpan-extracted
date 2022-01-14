#! /usr/bin/perl
use Test2::V0;

use String::Eertree;

my @examples = (
    [redivider => qw[ r redivider e edivide d divid i ivi v ]],
    [deific    => qw[ d e i ifi f c ]],
    [rotors    => qw[ r rotor o oto t s ]],
    [challenge => qw[ c h a l ll e n g ]],
    [champion  => qw[ c h a m p i o n ]],
    [christmas => qw[ c h r i s t m a ]],
    [abbcabc   => qw[ a b c bb ]],
    [xabcxc    => qw[ x a b c cxc ]],
    [referee   => qw[ r e f ee efe ere refer ]],
    ['a' x 100 => map 'a' x $_, 1 .. 100],
);

plan scalar @examples;

my $i = 1;
for my $example (@examples) {
    my $tree = 'String::Eertree'->new(string => $example->[0]);
    is [$tree->uniq_palindromes],
        bag { item($_) for @$example[1 .. $#$example]; end() },
        length($example->[0]) > 20 ? substr($example->[0], 0, 20) . '...'
                                   : $example->[0];
}
