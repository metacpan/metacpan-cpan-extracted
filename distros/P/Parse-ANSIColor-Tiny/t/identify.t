use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $p = new_ok($mod);

eq_or_diff [$p->identify('31')  ],           [qw(red)  ], 'simple color';
eq_or_diff [$p->identify('0032')],           [qw(green)], 'leading zeroes';
eq_or_diff [$p->identify('33;0')],           [qw(yellow clear)], 'color;clear';
eq_or_diff [$p->identify('0034;0035')],      [qw(blue magenta)], 'two zero-padded colors';
eq_or_diff [$p->identify('34;44', '45')],    [qw(blue on_blue on_magenta)], 'multiple args';
eq_or_diff [$p->identify('34', '44', '45')], [qw(blue on_blue on_magenta)], 'two zero-padded colors';
eq_or_diff [$p->identify('107', '166')],     [qw(on_bright_white)], 'ignore unknown';

eq_or_diff [$p->identify(undef)],      [qw(clear)], 'undef is like an empty string';
eq_or_diff [$p->identify('')],         [qw(clear)], 'empty means clear';
eq_or_diff [$p->identify('', '')],     [qw(clear clear)], 'two empties means two clears';
eq_or_diff [$p->identify(';')],        [qw(clear clear)], 'sole ";" is two clears';
eq_or_diff [$p->identify(';', '')],    [qw(clear clear clear)], 'sole ";" is two clears then blank';
eq_or_diff [$p->identify(';;')],       [qw(clear clear clear)], 'two ";" is three clears';
eq_or_diff [$p->identify('1;')],       [qw(bold  clear)], 'code;empty';
eq_or_diff [$p->identify(';1')],       [qw(clear bold )], 'empty;code';
eq_or_diff [$p->identify('31;;1')],    [qw(red clear bold)], 'code;empty;code';
eq_or_diff [$p->identify('31;;;1')],   [qw(red clear clear bold)], 'code;empty;empty;code';
eq_or_diff [$p->identify('31;;0;1')],  [qw(red clear clear bold)], 'code;empty;zero;code';
eq_or_diff [$p->identify('31;0;0;1')], [qw(red clear clear bold)], 'code;zero;zero;code';

eq_or_diff [$p->identify('31;39')],     [qw(   red       reset_foreground)], 'fg color, fg reset';
eq_or_diff [$p->identify('41;32;39')],  [qw(on_red green reset_foreground)], 'bg color, fg reset';
eq_or_diff [$p->identify('41;49')],     [qw(on_red       reset_background)], 'bg color, bg reset';

eq_or_diff [$p->identify('38;5;1')],     [qw(ansi1)], 'fg asni extended color';
eq_or_diff [$p->identify('48;5;15')],     [qw(on_ansi15)], 'bg ansi extended color';
eq_or_diff [$p->identify('38;5;124')],     [qw(rgb300)], 'fg extended color';

eq_or_diff [$p->identify('48;5;230')],     [qw(on_rgb554)], 'extended color, color codes';
eq_or_diff [$p->identify('38;5;64;0')],     [qw(rgb120 clear)], 'fg extended color;clear';
eq_or_diff [$p->identify('48;5;14;0;38;5;45')],     [qw(on_ansi14 clear rgb045)], 'bg extended color; clear; fg extended color;clear';
eq_or_diff [$p->identify('38;5;67;;38;5;86')],     [qw(rgb123 clear rgb154)], 'bg extended color; clear; fg extended color;clear';
eq_or_diff [$p->identify('48;5;13;')],     [qw(on_ansi13 clear)], 'fg extended color;clear';
eq_or_diff [$p->identify('48;5;0017;')],     [qw(on_rgb001 clear)], 'fg extended color with leading zeros;clear';

eq_or_diff [$p->identify('1;138;5;1')],     [qw(bold blink bold)], 'extra digit not an extended sequenc';

# regression tests {
eq_or_diff [$p->identify('38;5;009')],     [qw(ansi9) ], 'extended (00x)';
eq_or_diff [$p->identify('38;5;029')],     [qw(rgb021)], 'extended (0xx)';
eq_or_diff [$p->identify('38;5;209')],     [qw(rgb521)], 'extended (x0x)';
eq_or_diff [$p->identify('38;5;220')],     [qw(rgb540)], 'extended (xx0)';
eq_or_diff [$p->identify('38;5;200')],     [qw(rgb504)], 'extended (x00)';
# }

eq_or_diff [$p->identify('000;0001;00038;0005;000200;000')],     [qw(clear bold rgb504 clear)], 'three leading zeros';

done_testing;
