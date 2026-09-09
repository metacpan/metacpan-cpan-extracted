use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $p = new_ok($mod);

sub identifies {
  my ($codes, $exp, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  eq_or_diff [ $p->identify($codes) ], $exp, $desc;
}

sub normalizes {
  my ($attr, $exp, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  eq_or_diff [ $p->normalize(@$attr) ], $exp, $desc;
}

sub reverses {
  my ($attr, $exp, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  eq_or_diff [ $p->process_reverse(@$attr) ], $exp, $desc;
}

sub parses {
  my ($string, $exp, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  note $string;
  eq_or_diff $p->parse($string), $exp, $desc;
}

# identify

identifies '38;2;255;136;0',  [qw(r255g136b0)],       'fg true color';
identifies '48;2;0;10;20',    [qw(on_r0g10b20)],      'bg true color';
identifies '38;2;0;0;0',      [qw(r0g0b0)],           'fg black true color';
identifies '48;2;255;255;255',[qw(on_r255g255b255)],  'bg white true color';

identifies '38;2;007;010;255', [qw(r7g10b255)],   'leading zeros in components';
identifies '0038;0002;00;0;0', [qw(r0g0b0)],      'leading zeros everywhere';

identifies '1;38;2;10;20;30',        [qw(bold r10g20b30)],   'attribute then true color';
identifies '38;2;1;2;3;48;2;4;5;6',  [qw(r1g2b3 on_r4g5b6)], 'fg and bg true color';
identifies '38;2;1;2;3;0',           [qw(r1g2b3 clear)],     'true color then clear';
identifies '38;2;1;2;3;;48;2;4;5;6', [qw(r1g2b3 clear on_r4g5b6)], 'true color; empty; true color';
identifies '38;5;9;48;2;1;2;3',      [qw(ansi9 on_r1g2b3)],  '256 fg and true color bg';
identifies '38;2;1;2;3;39',          [qw(r1g2b3 reset_foreground)], 'true color then fg reset';

identifies '38;2;256;0;0',     [],                    'component over 255 is not a color';
identifies '1;38;2;300;0;0;4', [qw(bold underline)],  'out of range color dropped, neighbors kept';
identifies '138;2;1;2;3',      [qw(dark bold dark)],  'extra digit is not a true color sequence';

# normalize

normalizes [qw(red r1g2b3)],           [qw(r1g2b3)],  'true color overwrites named fg';
normalizes [qw(r1g2b3 green)],         [qw(green)],   'named fg overwrites true color';
normalizes [qw(r1g2b3 r4g5b6)],        [qw(r4g5b6)],  'true color overwrites true color';
normalizes [qw(r1g2b3 r1g2b3)],        [qw(r1g2b3)],  'duplicate true color';
normalizes [qw(on_blue on_r1g2b3)],    [qw(on_r1g2b3)], 'true color overwrites named bg';
normalizes [qw(r1g2b3 on_r4g5b6)],     [qw(r1g2b3 on_r4g5b6)], 'fg and bg true color';
normalizes [qw(bold r1g2b3 clear)],    [],            'clear removes true color';

normalizes [qw(r1g2b3 reset_foreground)],            [],              'true color fg, fg reset';
normalizes [qw(on_r1g2b3 green reset_foreground)],   [qw(on_r1g2b3)], 'true color bg, fg reset';
normalizes [qw(on_r1g2b3 reset_background)],         [],              'true color bg, bg reset';
normalizes [qw(r1g2b3 on_green reset_background)],   [qw(r1g2b3)],    'true color fg, bg reset';

# process_reverse

reverses [qw(bold r1g2b3 reverse)],    [qw(bold on_r1g2b3 black)],    'true color fg reversed';
reverses [qw(bold on_r1g2b3 reverse)], [qw(bold r1g2b3 on_white)],    'true color bg reversed';
reverses [qw(r1g2b3 on_r4g5b6 reverse)], [qw(on_r1g2b3 r4g5b6)],      'both true colors swapped';

eq_or_diff
  [ new_ok($mod, [foreground => 'r1g2b3', background => 'r4g5b6'])
      ->process_reverse(qw(bold reverse)) ],
  [qw(bold on_r1g2b3 r4g5b6)],
  'true color defaults reversed';

# parse

parses "x\e[38;2;255;0;0mred\e[0mplain",
  [
    [ [           ], 'x'     ],
    [ ['r255g0b0' ], 'red'   ],
    [ [           ], 'plain' ],
  ],
  'parsed a true color string';

parses "x\e[38;2;110;0;1;48;2;2;0;112mboth\e[49mfg\e[39mnone",
  [
    [ [], 'x' ],
    [ [qw(r110g0b1 on_r2g0b112)], 'both' ],
    [ [qw(r110g0b1)], 'fg' ],
    [ [], 'none' ],
  ],
  'reset foreground and background with true colors';

parses "\e[1mbold\e[38;2;9;9;9mtrue\e[31mnamed",
  [
    [ [qw(bold)],          'bold'  ],
    [ [qw(bold r9g9b9)],   'true'  ],
    [ [qw(bold red)],      'named' ],
  ],
  'true color inherited and then overwritten';

$p = new_ok($mod, [auto_reverse => 1]);

parses "\e[38;2;1;2;3mfg\e[7mrev",
  [
    [ [qw(r1g2b3)],           'fg'  ],
    [ [qw(on_r1g2b3 black)],  'rev' ],
  ],
  'auto_reverse with a true color';

done_testing;
