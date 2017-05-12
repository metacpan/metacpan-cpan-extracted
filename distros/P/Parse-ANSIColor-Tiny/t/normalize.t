use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $p = new_ok($mod);

eq_or_diff [$p->normalize(qw(red))],                         [qw(red)], 'simple fg color';
eq_or_diff [$p->normalize(qw(red green))],                   [qw(green)], 'overwrite fg color';
eq_or_diff [$p->normalize(qw(green red))],                   [qw(red)], 'overwrite fg color';
eq_or_diff [$p->normalize(qw(on_blue on_green))],            [qw(on_green)], 'overwrite bg color';
eq_or_diff [$p->normalize(qw(on_green on_blue))],            [qw(on_blue)], 'overwrite bg color';
eq_or_diff [$p->normalize(qw(green on_blue))],               [qw(green on_blue)], 'fg and bg color';
eq_or_diff [$p->normalize(qw(green on_blue red on_white))],  [qw(red on_white)], 'overwrite fg and bg color';
eq_or_diff [$p->normalize(qw(bold red on_white))],           [qw(bold red on_white)], 'other attribute, fg and bg color';
eq_or_diff [$p->normalize(qw(bold underline red on_white))], [qw(bold underline red on_white)], 'other attributes, fg and bg color';
eq_or_diff [$p->normalize(qw(bold underline red clear))],    [qw()], 'clear all';
eq_or_diff [$p->normalize(qw(bold underline clear yellow))], [qw(yellow)], 'clear previous';
eq_or_diff [$p->normalize(qw(red reverse))],                 [qw(red reverse)], 'reverse';
eq_or_diff [$p->normalize(qw(red reverse reverse_off))],     [qw(red)], 'reverse_off';
eq_or_diff [$p->normalize(qw(red reverse_off))],             [qw(red)], 'ignore reverse_off without reverse';

eq_or_diff [$p->normalize(qw(   red       reset_foreground))], [qw()],       'fg color, fg reset';
eq_or_diff [$p->normalize(qw(on_red green reset_foreground))], [qw(on_red)], 'bg color, fg reset';
eq_or_diff [$p->normalize(qw(on_red       reset_background))], [qw()],       'bg color, bg reset';

done_testing;
