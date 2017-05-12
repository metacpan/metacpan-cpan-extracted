use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $p = new_ok($mod);

my @colors = qw( black red green yellow blue magenta cyan white );

my @colors256 = (
  (map { "ansi$_" } 0 .. 15),
  do {
    my @c;
    for my $r (0 .. 5) {
        for my $g (0 .. 5) {
            push(@c, map { "rgb$r$g$_" } 0 .. 5);
        }
    }
    @c;
  },
  (map { "grey$_" } 0 .. 23),
);


eq_or_diff
  [$p->colors],
  [@colors, @colors256],
  'color names';

eq_or_diff
  [$p->foreground_colors],
  [
    @colors,
    (map { "bright_$_" } @colors),
    @colors256,
  ],
  'fg colors';

eq_or_diff
  [$p->background_colors],
  [
    (map { "on_$_" } @colors),
    (map { "on_bright_$_" } @colors),
    (map { "on_$_" } @colors256),
  ],
  'bg colors';

# test the default colors

$p = new_ok($mod, []);
is $p->{background}, 'on_black', 'default black background';
is $p->{foreground}, 'white',    'default white foreground';

$p = new_ok($mod, [background => 'blue', foreground => 'yellow']);
is $p->{background}, 'on_blue', 'fix background';
is $p->{foreground}, 'yellow',  'set foreground';

$p = new_ok($mod, [background => 'on_blue', foreground => 'on_yellow']);
is $p->{background}, 'on_blue', 'set background';
is $p->{foreground}, 'yellow',  'fix foreground';

done_testing;
