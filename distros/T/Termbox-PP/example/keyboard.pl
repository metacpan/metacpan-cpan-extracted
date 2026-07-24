#!perl
use 5.010;
use strict;
use warnings;

use Errno qw( EINTR );
use Getopt::Long qw( GetOptions );
use Pod::Usage;
use POSIX ();
use Unicode::EastAsianWidth::Detect qw( is_cjk_lang );

use lib '../lib', 'lib';
use Termbox::PP;
use Termbox qw( :all );

use constant {
  K_ESC => [
    {x=>1, y=>1, ch=>'E'}, 
    {x=>2, y=>1, ch=>'S'}, 
    {x=>3, y=>1, ch=>'C'}
  ],
  K_F1 => [
    {x=>6, y=>1, ch=>'F'}, 
    {x=>7, y=>1, ch=>'1'}
  ],
  K_F2 => [
    {x=>9,  y=>1, ch=>'F'}, 
    {x=>10, y=>1, ch=>'2'}
  ],
  K_F3 => [
    {x=>12, y=>1, ch=>'F'}, 
    {x=>13, y=>1, ch=>'3'}
  ],
  K_F4 => [
    {x=>15, y=>1, ch=>'F'},
    {x=>16, y=>1, ch=>'4'}
  ],
  K_F5 => [
    {x=>19, y=>1, ch=>'F'}, 
    {x=>20, y=>1, ch=>'5'}
  ],
  K_F6 => [
    {x=>22, y=>1, ch=>'F'}, 
    {x=>23, y=>1, ch=>'6'}
  ],
  K_F7 => [
    {x=>25, y=>1, ch=>'F'}, 
    {x=>26, y=>1, ch=>'7'}
  ],
  K_F8 => [
    {x=>28, y=>1, ch=>'F'}, 
    {x=>29, y=>1, ch=>'8'}
  ],
  K_F9 => [
    {x=>33, y=>1, ch=>'F'}, 
    {x=>34, y=>1, ch=>'9'}
  ],
  K_F10 => [
    {x=>36, y=>1, ch=>'F'}, 
    {x=>37, y=>1, ch=>'1'},
    {x=>38, y=>1, ch=>'0'}
  ],
  K_F11 => [
    {x=>40, y=>1, ch=>'F'},
    {x=>41, y=>1, ch=>'1'}, 
    {x=>42, y=>1, ch=>'1'}
  ],
  K_F12 => [
    {x=>44, y=>1, ch=>'F'}, 
    {x=>45, y=>1, ch=>'1'}, 
    {x=>46, y=>1, ch=>'2'}
  ],
  K_PRN => [
    {x=>50, y=>1, ch=>'P'}, 
    {x=>51, y=>1, ch=>'R'}, 
    {x=>52, y=>1, ch=>'N'}
  ],
  K_SCR => [
    {x=>54, y=>1, ch=>'S'}, 
    {x=>55, y=>1, ch=>'C'}, 
    {x=>56, y=>1, ch=>'R'}
  ],
  K_BRK => [
    {x=>58, y=>1, ch=>'B'}, 
    {x=>59, y=>1, ch=>'R'}, 
    {x=>60, y=>1, ch=>'K'}
  ],
  K_LED1        => [{x=>66, y=>1, ch=>'-'}],
  K_LED2        => [{x=>70, y=>1, ch=>'-'}],
  K_LED3        => [{x=>74, y=>1, ch=>'-'}],
  K_TILDE       => [{x=>1,  y=>4, ch=>'`'}],
  K_TILDE_SHIFT => [{x=>1,  y=>4, ch=>'~'}],
  K_1       => [{x=>4,  y=>4, ch=>'1'}],
  K_1_SHIFT => [{x=>4,  y=>4, ch=>'!'}],
  K_2       => [{x=>7,  y=>4, ch=>'2'}],
  K_2_SHIFT => [{x=>7,  y=>4, ch=>'@'}],
  K_3       => [{x=>10, y=>4, ch=>'3'}],
  K_3_SHIFT => [{x=>10, y=>4, ch=>'#'}],
  K_4       => [{x=>13, y=>4, ch=>'4'}],
  K_4_SHIFT => [{x=>13, y=>4, ch=>'$'}],
  K_5       => [{x=>16, y=>4, ch=>'5'}],
  K_5_SHIFT => [{x=>16, y=>4, ch=>'%'}],
  K_6       => [{x=>19, y=>4, ch=>'6'}],
  K_6_SHIFT => [{x=>19, y=>4, ch=>'^'}],
  K_7       => [{x=>22, y=>4, ch=>'7'}],
  K_7_SHIFT => [{x=>22, y=>4, ch=>'&'}],
  K_8       => [{x=>25, y=>4, ch=>'8'}],
  K_8_SHIFT => [{x=>25, y=>4, ch=>'*'}],
  K_9       => [{x=>28, y=>4, ch=>'9'}],
  K_9_SHIFT => [{x=>28, y=>4, ch=>'('}],
  K_0       => [{x=>31, y=>4, ch=>'0'}],
  K_0_SHIFT => [{x=>31, y=>4, ch=>')'}],
  K_MINUS           => [{x=>34, y=>4, ch=>'-'}],
  K_MINUS_SHIFT     => [{x=>34, y=>4, ch=>'_'}],
  K_EQUALS          => [{x=>37, y=>4, ch=>'='}],
  K_EQUALS_SHIFT    => [{x=>37, y=>4, ch=>'+'}],
  K_BACKSLASH       => [{x=>40, y=>4, ch=>'\\'}],
  K_BACKSLASH_SHIFT => [{x=>40, y=>4, ch=>'|'}],
  K_BACKSPACE => [
    {x=>44, y=>4, ch=>"\x{2190}"}, 
    {x=>45, y=>4, ch=>"\x{2500}"}, 
    {x=>46, y=>4, ch=>"\x{2500}"}
  ],
  K_INS => [
    {x=>50, y=>4, ch=>'I'}, 
    {x=>51, y=>4, ch=>'N'},
    {x=>52, y=>4, ch=>'S'}
  ],
  K_HOM => [
    {x=>54, y=>4, ch=>'H'}, 
    {x=>55, y=>4, ch=>'O'}, 
    {x=>56, y=>4, ch=>'M'}
  ],
  K_PGU => [
    {x=>58, y=>4, ch=>'P'}, 
    {x=>59, y=>4, ch=>'G'}, 
    {x=>60, y=>4, ch=>'U'}
  ],
  K_K_NUMLOCK => [{x=>65, y=>4, ch=>'N'}],
  K_K_SLASH   => [{x=>68, y=>4, ch=>'/'}],
  K_K_STAR    => [{x=>71, y=>4, ch=>'*'}],
  K_K_MINUS   => [{x=>74, y=>4, ch=>'-'}],
  K_TAB => [
    {x=>1, y=>6, ch=>'T'}, 
    {x=>2, y=>6, ch=>'A'}, 
    {x=>3, y=>6, ch=>'B'}
  ],
  K_q     => [{x=>6,  y=>6, ch=>'q'}],
  K_Q     => [{x=>6,  y=>6, ch=>'Q'}],
  K_w     => [{x=>9,  y=>6, ch=>'w'}],
  K_W     => [{x=>9,  y=>6, ch=>'W'}],
  K_e     => [{x=>12, y=>6, ch=>'e'}],
  K_E     => [{x=>12, y=>6, ch=>'E'}],
  K_r     => [{x=>15, y=>6, ch=>'r'}],
  K_R     => [{x=>15, y=>6, ch=>'R'}],
  K_t     => [{x=>18, y=>6, ch=>'t'}],
  K_T     => [{x=>18, y=>6, ch=>'T'}],
  K_y     => [{x=>21, y=>6, ch=>'y'}],
  K_Y     => [{x=>21, y=>6, ch=>'Y'}],
  K_u     => [{x=>24, y=>6, ch=>'u'}],
  K_U     => [{x=>24, y=>6, ch=>'U'}],
  K_i     => [{x=>27, y=>6, ch=>'i'}],
  K_I     => [{x=>27, y=>6, ch=>'I'}],
  K_o     => [{x=>30, y=>6, ch=>'o'}],
  K_O     => [{x=>30, y=>6, ch=>'O'}],
  K_p     => [{x=>33, y=>6, ch=>'p'}],
  K_P     => [{x=>33, y=>6, ch=>'P'}],
  K_LSQB  => [{x=>36, y=>6, ch=>'['}],
  K_LCUB  => [{x=>36, y=>6, ch=>'{'}],
  K_RSQB  => [{x=>39, y=>6, ch=>']'}],
  K_RCUB  => [{x=>39, y=>6, ch=>'}'}],
  K_ENTER => [
    {x=>43, y=>6, ch=>"\x{2591}"},
    {x=>44, y=>6, ch=>"\x{2591}"}, 
    {x=>45, y=>6, ch=>"\x{2591}"}, 
    {x=>46, y=>6, ch=>"\x{2591}"},
    {x=>43, y=>7, ch=>"\x{2591}"}, 
    {x=>44, y=>7, ch=>"\x{2591}"}, 
    {x=>45, y=>7, ch=>"\x{21B5}"}, 
    {x=>46, y=>7, ch=>"\x{2591}"},
    {x=>41, y=>8, ch=>"\x{2591}"}, 
    {x=>42, y=>8, ch=>"\x{2591}"}, 
    {x=>43, y=>8, ch=>"\x{2591}"},
    {x=>44, y=>8, ch=>"\x{2591}"},
    {x=>45, y=>8, ch=>"\x{2591}"}, 
    {x=>46, y=>8, ch=>"\x{2591}"},
  ],
  K_DEL => [
    {x=>50, y=>6, ch=>'D'}, 
    {x=>51, y=>6, ch=>'E'}, 
    {x=>52, y=>6, ch=>'L'}
  ],
  K_END => [
    {x=>54, y=>6, ch=>'E'}, 
    {x=>55, y=>6, ch=>'N'}, 
    {x=>56, y=>6, ch=>'D'}
  ],
  K_PGD => [
    {x=>58, y=>6, ch=>'P'}, 
    {x=>59, y=>6, ch=>'G'}, 
    {x=>60, y=>6, ch=>'D'}
  ],
  K_K_7 => [{x=>65, y=>6, ch=>'7'}],
  K_K_8 => [{x=>68, y=>6, ch=>'8'}],
  K_K_9 => [{x=>71, y=>6, ch=>'9'}],
  K_K_PLUS => [
    {x=>74, y=>6, ch=>' '}, 
    {x=>74, y=>7, ch=>'+'}, 
    {x=>74, y=>8, ch=>' '}
  ],
  K_CAPS => [
    {x=>1, y=>8, ch=>'C'}, 
    {x=>2, y=>8, ch=>'A'}, 
    {x=>3, y=>8, ch=>'P'}, 
    {x=>4, y=>8, ch=>'S'}
  ],
  K_a => [{x=>7,  y=>8, ch=>'a'}],
  K_A => [{x=>7,  y=>8, ch=>'A'}],
  K_s => [{x=>10, y=>8, ch=>'s'}],
  K_S => [{x=>10, y=>8, ch=>'S'}],
  K_d => [{x=>13, y=>8, ch=>'d'}],
  K_D => [{x=>13, y=>8, ch=>'D'}],
  K_f => [{x=>16, y=>8, ch=>'f'}],
  K_F => [{x=>16, y=>8, ch=>'F'}],
  K_g => [{x=>19, y=>8, ch=>'g'}],
  K_G => [{x=>19, y=>8, ch=>'G'}],
  K_h => [{x=>22, y=>8, ch=>'h'}],
  K_H => [{x=>22, y=>8, ch=>'H'}],
  K_j => [{x=>25, y=>8, ch=>'j'}],
  K_J => [{x=>25, y=>8, ch=>'J'}],
  K_k => [{x=>28, y=>8, ch=>'k'}],
  K_K => [{x=>28, y=>8, ch=>'K'}],
  K_l => [{x=>31, y=>8, ch=>'l'}],
  K_L => [{x=>31, y=>8, ch=>'L'}],
  K_SEMICOLON   => [{x=>34, y=>8, ch=>';'}],
  K_PARENTHESIS => [{x=>34, y=>8, ch=>':'}],
  K_QUOTE       => [{x=>37, y=>8, ch=>"'"}],
  K_DOUBLEQUOTE => [{x=>37, y=>8, ch=>'"'}],
  K_K_4 => [{x=>65, y=>8, ch=>'4'}],
  K_K_5 => [{x=>68, y=>8, ch=>'5'}],
  K_K_6 => [{x=>71, y=>8, ch=>'6'}],
  K_LSHIFT => [
    {x=>1, y=>10, ch=>'S'},
    {x=>2, y=>10, ch=>'H'}, 
    {x=>3, y=>10, ch=>'I'},
    {x=>4, y=>10, ch=>'F'}, 
    {x=>5, y=>10, ch=>'T'}
  ],
  K_z => [{x=>9,  y=>10, ch=>'z'}],
  K_Z => [{x=>9,  y=>10, ch=>'Z'}],
  K_x => [{x=>12, y=>10, ch=>'x'}],
  K_X => [{x=>12, y=>10, ch=>'X'}],
  K_c => [{x=>15, y=>10, ch=>'c'}],
  K_C => [{x=>15, y=>10, ch=>'C'}],
  K_v => [{x=>18, y=>10, ch=>'v'}],
  K_V => [{x=>18, y=>10, ch=>'V'}],
  K_b => [{x=>21, y=>10, ch=>'b'}],
  K_B => [{x=>21, y=>10, ch=>'B'}],
  K_n => [{x=>24, y=>10, ch=>'n'}],
  K_N => [{x=>24, y=>10, ch=>'N'}],
  K_m => [{x=>27, y=>10, ch=>'m'}],
  K_M => [{x=>27, y=>10, ch=>'M'}],
  K_COMMA     => [{x=>30, y=>10, ch=>','}],
  K_LANB      => [{x=>30, y=>10, ch=>'<'}],
  K_PERIOD    => [{x=>33, y=>10, ch=>'.'}],
  K_RANB      => [{x=>33, y=>10, ch=>'>'}],
  K_SLASH     => [{x=>36, y=>10, ch=>'/'}],
  K_QUESTION  => [{x=>36, y=>10, ch=>'?'}],
  K_RSHIFT => [
    {x=>42, y=>10, ch=>'S'}, 
    {x=>43, y=>10, ch=>'H'}, 
    {x=>44, y=>10, ch=>'I'},
    {x=>45, y=>10, ch=>'F'}, 
    {x=>46, y=>10, ch=>'T'}
  ],
  K_ARROW_UP => [
    {x=>54, y=>10, ch=>'('}, 
    {x=>55, y=>10, ch=>"\x{2191}"}, 
    {x=>56, y=>10, ch=>')'}
  ],
  K_K_1 => [{x=>65, y=>10, ch=>'1'}],
  K_K_2 => [{x=>68, y=>10, ch=>'2'}],
  K_K_3 => [{x=>71, y=>10, ch=>'3'}],
  K_K_ENTER => [
    {x=>74, y=>10, ch=>"\x{2591}"}, 
    {x=>74, y=>11, ch=>"\x{2591}"}, 
    {x=>74, y=>12, ch=>"\x{2591}"}
  ],
  K_LCTRL => [
    {x=>1, y=>12, ch=>'C'}, 
    {x=>2, y=>12, ch=>'T'}, 
    {x=>3, y=>12, ch=>'R'}, 
    {x=>4, y=>12, ch=>'L'}
  ],
  K_LWIN => [
    {x=>6, y=>12, ch=>'W'}, 
    {x=>7, y=>12, ch=>'I'},
    {x=>8, y=>12, ch=>'N'}
  ],
  K_LALT => [
    {x=>10, y=>12, ch=>'A'}, 
    {x=>11, y=>12, ch=>'L'}, 
    {x=>12, y=>12, ch=>'T'}
  ],
  K_SPACE => [
    {x=>14, y=>12, ch=>' '},
    {x=>15, y=>12, ch=>' '}, 
    {x=>16, y=>12, ch=>' '}, 
    {x=>17, y=>12, ch=>' '}, 
    {x=>18, y=>12, ch=>' '}, 
    {x=>19, y=>12, ch=>'S'},
    {x=>20, y=>12, ch=>'P'}, 
    {x=>21, y=>12, ch=>'A'},
    {x=>22, y=>12, ch=>'C'}, 
    {x=>23, y=>12, ch=>'E'}, 
    {x=>24, y=>12, ch=>' '}, 
    {x=>25, y=>12, ch=>' '}, 
    {x=>26, y=>12, ch=>' '}, 
    {x=>27, y=>12, ch=>' '}, 
    {x=>28, y=>12, ch=>' '},
  ],
  K_RALT => [
    {x=>30, y=>12, ch=>'A'}, 
    {x=>31, y=>12, ch=>'L'}, 
    {x=>32, y=>12, ch=>'T'}
  ],
  K_RWIN  => [
    {x=>34, y=>12, ch=>'W'}, 
    {x=>35, y=>12, ch=>'I'}, 
    {x=>36, y=>12, ch=>'N'}
  ],
  K_RPROP => [
    {x=>38, y=>12, ch=>'P'}, 
    {x=>39, y=>12, ch=>'R'}, 
    {x=>40, y=>12, ch=>'O'}, 
    {x=>41, y=>12, ch=>'P'}
  ],
  K_RCTRL => [
    {x=>43, y=>12, ch=>'C'}, 
    {x=>44, y=>12, ch=>'T'}, 
    {x=>45, y=>12, ch=>'R'}, 
    {x=>46, y=>12, ch=>'L'}
  ],
  K_ARROW_LEFT => [
    {x=>50, y=>12, ch=>'('}, 
    {x=>51, y=>12, ch=>"\x{2190}"}, 
    {x=>52, y=>12, ch=>')'}
  ],
  K_ARROW_DOWN => [
    {x=>54, y=>12, ch=>'('}, 
    {x=>55, y=>12, ch=>"\x{2193}"}, 
    {x=>56, y=>12, ch=>')'}
  ],
  K_ARROW_RIGHT => [
    {x=>58, y=>12, ch=>'('}, 
    {x=>59, y=>12, ch=>"\x{2192}"}, 
    {x=>60, y=>12, ch=>')'}
  ],
  K_K_0 => [
    {x=>65, y=>12, ch=>' '},
    {x=>66, y=>12, ch=>'0'},
    {x=>67, y=>12, ch=>' '}, 
    {x=>68, y=>12, ch=>' '}
  ],
  K_K_PERIOD => [{x=>71, y=>12, ch=>'.'}],
};

my $borderTopLeft = "\x{250C}";
my $borderTopRight = "\x{2510}";
my $borderBotomLeft = "\x{2514}";
my $borderBottomRight = "\x{2518}";
my $borderVertical = "\x{2500}";
my $borderHorizontal = "\x{2502}";
my $borderHorizontalLeftBar = "\x{251C}";
my $borderHorizontalRight = "\x{2524}";
my $boxShadow = "\x{2588}";

INIT {
  if (is_cjk_lang) {
    K_BACKSPACE->[0]->{ch} = '<';
    K_BACKSPACE->[1]->{ch} = '-';
    K_BACKSPACE->[2]->{ch} = '-';
    K_ARROW_UP->[1]->{ch} = '^';
    K_ARROW_DOWN->[1]->{ch} = 'v';
    K_ARROW_LEFT->[1]->{ch}  = '<';
    K_ARROW_RIGHT->[1]->{ch}  = '>';
    $borderTopLeft = '+';
    $borderTopRight = '+';
    $borderBotomLeft = '+';
    $borderBottomRight = '+';
    $borderVertical = '-';
    $borderHorizontal = '|';
    $borderHorizontalLeftBar = '+';
    $borderHorizontalRight = '+';
    $boxShadow = ' ';
  }
  if ($^O eq 'MSWin32') {
    # Consolas did not support Unicode-21B5
    K_ENTER->[5]->{ch} = "\x{2190}";
    K_ENTER->[6]->{ch} = "\x{2518}";
  }
}

my $combos = [
  {keys=>[K_TILDE, K_2, K_SPACE, K_LCTRL, K_RCTRL]},
  {keys=>[K_A, K_LCTRL, K_RCTRL]},
  {keys=>[K_B, K_LCTRL, K_RCTRL]},
  {keys=>[K_C, K_LCTRL, K_RCTRL]},
  {keys=>[K_D, K_LCTRL, K_RCTRL]},
  {keys=>[K_E, K_LCTRL, K_RCTRL]},
  {keys=>[K_F, K_LCTRL, K_RCTRL]},
  {keys=>[K_G, K_LCTRL, K_RCTRL]},
  {keys=>[K_H, K_BACKSPACE, K_LCTRL, K_RCTRL]},
  {keys=>[K_I, K_TAB, K_LCTRL, K_RCTRL]},
  {keys=>[K_J, K_LCTRL, K_RCTRL]},
  {keys=>[K_K, K_LCTRL, K_RCTRL]},
  {keys=>[K_L, K_LCTRL, K_RCTRL]},
  {keys=>[K_M, K_ENTER, K_K_ENTER, K_LCTRL, K_RCTRL]},
  {keys=>[K_N, K_LCTRL, K_RCTRL]},
  {keys=>[K_O, K_LCTRL, K_RCTRL]},
  {keys=>[K_P, K_LCTRL, K_RCTRL]},
  {keys=>[K_Q, K_LCTRL, K_RCTRL]},
  {keys=>[K_R, K_LCTRL, K_RCTRL]},
  {keys=>[K_S, K_LCTRL, K_RCTRL]},
  {keys=>[K_T, K_LCTRL, K_RCTRL]},
  {keys=>[K_U, K_LCTRL, K_RCTRL]},
  {keys=>[K_V, K_LCTRL, K_RCTRL]},
  {keys=>[K_W, K_LCTRL, K_RCTRL]},
  {keys=>[K_X, K_LCTRL, K_RCTRL]},
  {keys=>[K_Y, K_LCTRL, K_RCTRL]},
  {keys=>[K_Z, K_LCTRL, K_RCTRL]},
  {keys=>[K_LSQB, K_ESC, K_3, K_LCTRL, K_RCTRL]},
  {keys=>[K_4, K_BACKSLASH, K_LCTRL, K_RCTRL]},
  {keys=>[K_RSQB, K_5, K_LCTRL, K_RCTRL]},
  {keys=>[K_6, K_LCTRL, K_RCTRL]},
  {keys=>[K_7, K_SLASH, K_MINUS_SHIFT, K_LCTRL, K_RCTRL]},
  {keys=>[K_SPACE]},
  {keys=>[K_1_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_DOUBLEQUOTE, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_3_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_4_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_5_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_7_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_QUOTE]},
  {keys=>[K_9_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_0_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_8_SHIFT, K_K_STAR, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_EQUALS_SHIFT, K_K_PLUS, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_COMMA]},
  {keys=>[K_MINUS, K_K_MINUS]},
  {keys=>[K_PERIOD, K_K_PERIOD]},
  {keys=>[K_SLASH, K_K_SLASH]},
  {keys=>[K_0, K_K_0]},
  {keys=>[K_1, K_K_1]},
  {keys=>[K_2, K_K_2]},
  {keys=>[K_3, K_K_3]},
  {keys=>[K_4, K_K_4]},
  {keys=>[K_5, K_K_5]},
  {keys=>[K_6, K_K_6]},
  {keys=>[K_7, K_K_7]},
  {keys=>[K_8, K_K_8]},
  {keys=>[K_9, K_K_9]},
  {keys=>[K_PARENTHESIS, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_SEMICOLON]},
  {keys=>[K_LANB, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_EQUALS]},
  {keys=>[K_RANB, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_QUESTION, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_2_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_A, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_B, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_C, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_D, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_E, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_F, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_G, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_H, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_I, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_J, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_K, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_L, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_M, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_N, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_O, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_P, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_Q, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_R, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_S, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_T, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_U, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_V, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_W, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_X, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_Y, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_Z, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_LSQB]},
  {keys=>[K_BACKSLASH]},
  {keys=>[K_RSQB]},
  {keys=>[K_6_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_MINUS_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_TILDE]},
  {keys=>[K_a]},
  {keys=>[K_b]},
  {keys=>[K_c]},
  {keys=>[K_d]},
  {keys=>[K_e]},
  {keys=>[K_f]},
  {keys=>[K_g]},
  {keys=>[K_h]},
  {keys=>[K_i]},
  {keys=>[K_j]},
  {keys=>[K_k]},
  {keys=>[K_l]},
  {keys=>[K_m]},
  {keys=>[K_n]},
  {keys=>[K_o]},
  {keys=>[K_p]},
  {keys=>[K_q]},
  {keys=>[K_r]},
  {keys=>[K_s]},
  {keys=>[K_t]},
  {keys=>[K_u]},
  {keys=>[K_v]},
  {keys=>[K_w]},
  {keys=>[K_x]},
  {keys=>[K_y]},
  {keys=>[K_z]},
  {keys=>[K_LCUB, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_BACKSLASH_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_RCUB, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_TILDE_SHIFT, K_LSHIFT, K_RSHIFT]},
  {keys=>[K_8, K_BACKSPACE, K_LCTRL, K_RCTRL]},
];

my $func_combos = [
  {keys=>[K_F1]},
  {keys=>[K_F2]},
  {keys=>[K_F3]},
  {keys=>[K_F4]},
  {keys=>[K_F5]},
  {keys=>[K_F6]},
  {keys=>[K_F7]},
  {keys=>[K_F8]},
  {keys=>[K_F9]},
  {keys=>[K_F10]},
  {keys=>[K_F11]},
  {keys=>[K_F12]},
  {keys=>[K_INS]},
  {keys=>[K_DEL]},
  {keys=>[K_HOM]},
  {keys=>[K_END]},
  {keys=>[K_PGU]},
  {keys=>[K_PGD]},
  {keys=>[K_ARROW_UP]},
  {keys=>[K_ARROW_DOWN]},
  {keys=>[K_ARROW_LEFT]},
  {keys=>[K_ARROW_RIGHT]},
];

sub print_tb { # void ($x, $y, $fg, $bg, $msg)
  my ($x, $y, $fg, $bg, $msg) = @_;
  foreach my $c (split //, $msg) {
    tb_set_cell($x, $y, $c, $fg, $bg);
    $x++;
  }
}

sub printf_tb { # void ($x, $y, $fg, $bg, $format, @args)
  my ($x, $y, $fg, $bg, $format, @args) = @_;
  my $s = sprintf($format, @args);
  print_tb($x, $y, $fg, $bg, $s);
  return;
}

sub draw_key { # void (\@keys, $fg, $bg)
  my ($keys, $fg, $bg) = @_;
  foreach my $k (@$keys) {
    tb_set_cell($k->{x}+2, $k->{y}+4, $k->{ch}, $fg, $bg);
  }
  return;
}

sub draw_keyboard { # void ()
  tb_set_cell(0, 0, $borderTopLeft, TB_WHITE, TB_DEFAULT);
  tb_set_cell(79, 0, $borderTopRight, TB_WHITE, TB_DEFAULT);
  tb_set_cell(0, 23, $borderBotomLeft, TB_WHITE, TB_DEFAULT);
  tb_set_cell(79, 23, $borderBottomRight, TB_WHITE, TB_DEFAULT);

  for (my $i = 1; $i < 79; $i++) {
    tb_set_cell($i, 0, $borderVertical, TB_WHITE, TB_DEFAULT);
    tb_set_cell($i, 23, $borderVertical, TB_WHITE, TB_DEFAULT);
    tb_set_cell($i, 17, $borderVertical, TB_WHITE, TB_DEFAULT);
    tb_set_cell($i, 4, $borderVertical, TB_WHITE, TB_DEFAULT);
  }
  for (my $i = 1; $i < 23; $i++) {
    tb_set_cell(0, $i, $borderHorizontal, TB_WHITE, TB_DEFAULT);
    tb_set_cell(79, $i, $borderHorizontal, TB_WHITE, TB_DEFAULT);
  }
  tb_set_cell(0, 17, $borderHorizontalLeftBar, TB_WHITE, TB_DEFAULT);
  tb_set_cell(79, 17, $borderHorizontalRight, TB_WHITE, TB_DEFAULT);
  tb_set_cell(0, 4, $borderHorizontalLeftBar, TB_WHITE, TB_DEFAULT);
  tb_set_cell(79, 4, $borderHorizontalRight, TB_WHITE, TB_DEFAULT);
  for (my $i = 5; $i < 17; $i++) {
    tb_set_cell(1, $i, $boxShadow, TB_YELLOW, TB_YELLOW);
    tb_set_cell(78, $i, $boxShadow, TB_YELLOW, TB_YELLOW);
  }

  draw_key(K_ESC, TB_WHITE, TB_BLUE);
  draw_key(K_F1, TB_WHITE, TB_BLUE);
  draw_key(K_F2, TB_WHITE, TB_BLUE);
  draw_key(K_F3, TB_WHITE, TB_BLUE);
  draw_key(K_F4, TB_WHITE, TB_BLUE);
  draw_key(K_F5, TB_WHITE, TB_BLUE);
  draw_key(K_F6, TB_WHITE, TB_BLUE);
  draw_key(K_F7, TB_WHITE, TB_BLUE);
  draw_key(K_F8, TB_WHITE, TB_BLUE);
  draw_key(K_F9, TB_WHITE, TB_BLUE);
  draw_key(K_F10, TB_WHITE, TB_BLUE);
  draw_key(K_F11, TB_WHITE, TB_BLUE);
  draw_key(K_F12, TB_WHITE, TB_BLUE);
  draw_key(K_PRN, TB_WHITE, TB_BLUE);
  draw_key(K_SCR, TB_WHITE, TB_BLUE);
  draw_key(K_BRK, TB_WHITE, TB_BLUE);
  draw_key(K_LED1, TB_WHITE, TB_BLUE);
  draw_key(K_LED2, TB_WHITE, TB_BLUE);
  draw_key(K_LED3, TB_WHITE, TB_BLUE);

  draw_key(K_TILDE, TB_WHITE, TB_BLUE);
  draw_key(K_1, TB_WHITE, TB_BLUE);
  draw_key(K_2, TB_WHITE, TB_BLUE);
  draw_key(K_3, TB_WHITE, TB_BLUE);
  draw_key(K_4, TB_WHITE, TB_BLUE);
  draw_key(K_5, TB_WHITE, TB_BLUE);
  draw_key(K_6, TB_WHITE, TB_BLUE);
  draw_key(K_7, TB_WHITE, TB_BLUE);
  draw_key(K_8, TB_WHITE, TB_BLUE);
  draw_key(K_9, TB_WHITE, TB_BLUE);
  draw_key(K_0, TB_WHITE, TB_BLUE);
  draw_key(K_MINUS, TB_WHITE, TB_BLUE);
  draw_key(K_EQUALS, TB_WHITE, TB_BLUE);
  draw_key(K_BACKSLASH, TB_WHITE, TB_BLUE);
  draw_key(K_BACKSPACE, TB_WHITE, TB_BLUE);
  draw_key(K_INS, TB_WHITE, TB_BLUE);
  draw_key(K_HOM, TB_WHITE, TB_BLUE);
  draw_key(K_PGU, TB_WHITE, TB_BLUE);
  draw_key(K_K_NUMLOCK, TB_WHITE, TB_BLUE);
  draw_key(K_K_SLASH, TB_WHITE, TB_BLUE);
  draw_key(K_K_STAR, TB_WHITE, TB_BLUE);
  draw_key(K_K_MINUS, TB_WHITE, TB_BLUE);

  draw_key(K_TAB, TB_WHITE, TB_BLUE);
  draw_key(K_q, TB_WHITE, TB_BLUE);
  draw_key(K_w, TB_WHITE, TB_BLUE);
  draw_key(K_e, TB_WHITE, TB_BLUE);
  draw_key(K_r, TB_WHITE, TB_BLUE);
  draw_key(K_t, TB_WHITE, TB_BLUE);
  draw_key(K_y, TB_WHITE, TB_BLUE);
  draw_key(K_u, TB_WHITE, TB_BLUE);
  draw_key(K_i, TB_WHITE, TB_BLUE);
  draw_key(K_o, TB_WHITE, TB_BLUE);
  draw_key(K_p, TB_WHITE, TB_BLUE);
  draw_key(K_LSQB, TB_WHITE, TB_BLUE);
  draw_key(K_RSQB, TB_WHITE, TB_BLUE);
  draw_key(K_ENTER, TB_WHITE, TB_BLUE);
  draw_key(K_DEL, TB_WHITE, TB_BLUE);
  draw_key(K_END, TB_WHITE, TB_BLUE);
  draw_key(K_PGD, TB_WHITE, TB_BLUE);
  draw_key(K_K_7, TB_WHITE, TB_BLUE);
  draw_key(K_K_8, TB_WHITE, TB_BLUE);
  draw_key(K_K_9, TB_WHITE, TB_BLUE);
  draw_key(K_K_PLUS, TB_WHITE, TB_BLUE);

  draw_key(K_CAPS, TB_WHITE, TB_BLUE);
  draw_key(K_a, TB_WHITE, TB_BLUE);
  draw_key(K_s, TB_WHITE, TB_BLUE);
  draw_key(K_d, TB_WHITE, TB_BLUE);
  draw_key(K_f, TB_WHITE, TB_BLUE);
  draw_key(K_g, TB_WHITE, TB_BLUE);
  draw_key(K_h, TB_WHITE, TB_BLUE);
  draw_key(K_j, TB_WHITE, TB_BLUE);
  draw_key(K_k, TB_WHITE, TB_BLUE);
  draw_key(K_l, TB_WHITE, TB_BLUE);
  draw_key(K_SEMICOLON, TB_WHITE, TB_BLUE);
  draw_key(K_QUOTE, TB_WHITE, TB_BLUE);
  draw_key(K_K_4, TB_WHITE, TB_BLUE);
  draw_key(K_K_5, TB_WHITE, TB_BLUE);
  draw_key(K_K_6, TB_WHITE, TB_BLUE);

  draw_key(K_LSHIFT, TB_WHITE, TB_BLUE);
  draw_key(K_z, TB_WHITE, TB_BLUE);
  draw_key(K_x, TB_WHITE, TB_BLUE);
  draw_key(K_c, TB_WHITE, TB_BLUE);
  draw_key(K_v, TB_WHITE, TB_BLUE);
  draw_key(K_b, TB_WHITE, TB_BLUE);
  draw_key(K_n, TB_WHITE, TB_BLUE);
  draw_key(K_m, TB_WHITE, TB_BLUE);
  draw_key(K_COMMA, TB_WHITE, TB_BLUE);
  draw_key(K_PERIOD, TB_WHITE, TB_BLUE);
  draw_key(K_SLASH, TB_WHITE, TB_BLUE);
  draw_key(K_RSHIFT, TB_WHITE, TB_BLUE);
  draw_key(K_ARROW_UP, TB_WHITE, TB_BLUE);
  draw_key(K_K_1, TB_WHITE, TB_BLUE);
  draw_key(K_K_2, TB_WHITE, TB_BLUE);
  draw_key(K_K_3, TB_WHITE, TB_BLUE);
  draw_key(K_K_ENTER, TB_WHITE, TB_BLUE);

  draw_key(K_LCTRL, TB_WHITE, TB_BLUE);
  draw_key(K_LWIN, TB_WHITE, TB_BLUE);
  draw_key(K_LALT, TB_WHITE, TB_BLUE);
  draw_key(K_SPACE, TB_WHITE, TB_BLUE);
  draw_key(K_RCTRL, TB_WHITE, TB_BLUE);
  draw_key(K_RPROP, TB_WHITE, TB_BLUE);
  draw_key(K_RWIN, TB_WHITE, TB_BLUE);
  draw_key(K_RALT, TB_WHITE, TB_BLUE);
  draw_key(K_ARROW_LEFT, TB_WHITE, TB_BLUE);
  draw_key(K_ARROW_DOWN, TB_WHITE, TB_BLUE);
  draw_key(K_ARROW_RIGHT, TB_WHITE, TB_BLUE);
  draw_key(K_K_0, TB_WHITE, TB_BLUE);
  draw_key(K_K_PERIOD, TB_WHITE, TB_BLUE);

  printf_tb(33, 1, TB_MAGENTA | TB_BOLD, TB_DEFAULT, "Keyboard demo!");
  printf_tb(21, 2, TB_MAGENTA, TB_DEFAULT, 
    "(press CTRL+X and then CTRL+Q to exit)");
  printf_tb(15, 3, TB_MAGENTA, TB_DEFAULT, 
    "(press CTRL+X and then CTRL+C to change input mode)");

  my $inputmode = tb_set_input_mode(0);
  my $inputmode_str = '';

  if ($inputmode & TB_INPUT_ESC) {
    $inputmode_str = "TB_INPUT_ESC";
  }
  if ($inputmode & TB_INPUT_ALT) {
    $inputmode_str = "TB_INPUT_ALT";
  }
  if ($inputmode & TB_INPUT_MOUSE) {
    $inputmode_str .= "|TB_INPUT_MOUSE";
  }
  printf_tb(3, 18, TB_WHITE, TB_DEFAULT, "Input mode: %s", $inputmode_str);
  return;
}

sub funckeymap { # $string ($k)
  my ($k) = @_;
  state $fcmap = [
    "CTRL+2, CTRL+~",
    "CTRL+A",
    "CTRL+B",
    "CTRL+C",
    "CTRL+D",
    "CTRL+E",
    "CTRL+F",
    "CTRL+G",
    "CTRL+H, BACKSPACE",
    "CTRL+I, TAB",
    "CTRL+J",
    "CTRL+K",
    "CTRL+L",
    "CTRL+M, ENTER",
    "CTRL+N",
    "CTRL+O",
    "CTRL+P",
    "CTRL+Q",
    "CTRL+R",
    "CTRL+S",
    "CTRL+T",
    "CTRL+U",
    "CTRL+V",
    "CTRL+W",
    "CTRL+X",
    "CTRL+Y",
    "CTRL+Z",
    "CTRL+3, ESC, CTRL+[",
    "CTRL+4, CTRL+\\",
    "CTRL+5, CTRL+]",
    "CTRL+6",
    "CTRL+7, CTRL+/, CTRL+_",
    "SPACE",
  ];
  state $fkmap = [
    "F1",
    "F2",
    "F3",
    "F4",
    "F5",
    "F6",
    "F7",
    "F8",
    "F9",
    "F10",
    "F11",
    "F12",
    "INSERT",
    "DELETE",
    "HOME",
    "END",
    "PGUP",
    "PGDN",
    "ARROW UP",
    "ARROW DOWN",
    "ARROW LEFT",
    "ARROW RIGHT",
    "SHIFT+TAB",
  ];

  if ($k == TB_KEY_CTRL_8) {
    return "CTRL+8, BACKSPACE 2" # 0x7F
  } elsif ($k >= TB_KEY_BACK_TAB && $k <= 0xffff) {
    return $fkmap->[0xffff-$k];
  } elsif ($k <= TB_KEY_SPACE) {
    return $fcmap->[$k];
  }
  return "UNKNOWN"
}

sub pretty_print_press { # void (\%ev)
  my ($ev) = @_;
  printf_tb(3, 19, TB_WHITE,  TB_DEFAULT, "Key: ");
  printf_tb(8, 19, TB_YELLOW, TB_DEFAULT, "decimal: %d", $ev->key);
  printf_tb(8, 20, TB_GREEN,  TB_DEFAULT, "hex:     0x%X", $ev->key);
  printf_tb(8, 21, TB_CYAN,   TB_DEFAULT, "octal:   0%o", $ev->key);
  printf_tb(8, 22, TB_RED,    TB_DEFAULT, "string:  %s", 
           $ev->ch ? '' : funckeymap($ev->key));

  printf_tb(54, 19, TB_WHITE,  TB_DEFAULT, "Char: ");
  printf_tb(60, 19, TB_YELLOW, TB_DEFAULT, "decimal: %d", $ev->ch);
  printf_tb(60, 20, TB_GREEN,  TB_DEFAULT, "hex:     0x%X", $ev->ch);
  printf_tb(60, 21, TB_CYAN,   TB_DEFAULT, "octal:   0%o", $ev->ch);
  printf_tb(60, 22, TB_RED,    TB_DEFAULT, "string:  %s", 
           $ev->ch ? chr($ev->ch) : '');

  printf_tb(54, 18, TB_WHITE, TB_DEFAULT, "Modifier: %s%s%s%s",
          ($ev->mod & TB_MOD_CTRL)   ? 'C' : ' ',
          ($ev->mod & TB_MOD_ALT)    ? 'A' : ' ',
          ($ev->mod & TB_MOD_SHIFT)  ? 'S' : ' ',
          ($ev->mod & TB_MOD_MOTION) ? 'M' : ' ');

  return;
}

sub pretty_print_resize { # void (\%ev)
  my ($ev) = @_;
  printf_tb(3, 19, TB_WHITE, TB_DEFAULT, 
    "Resize event: %d x %d", $ev->w, $ev->h);
  return;
}

my $counter = 0;

sub pretty_print_mouse { # void (\%ev)
  my ($ev) = @_;
  printf_tb(3, 19, TB_WHITE, TB_DEFAULT, 
    "Mouse event: %d x %d", $ev->x, $ev->y);
  my $button = '';
  switch: for ($ev->key) {
    case: TB_KEY_MOUSE_LEFT == $_ and do {
      $button = "MouseLeft: %d";
      last;
    };
    case: TB_KEY_MOUSE_MIDDLE == $_ and do {
      $button = "MouseMiddle: %d";
      last;
    };
    case: TB_KEY_MOUSE_RIGHT == $_ and do {
      $button = "MouseRight: %d";
      last;
    };
    case: TB_KEY_MOUSE_WHEEL_UP == $_ and do {
      $button = "MouseWheelUp: %d";
      last;
    };
    case: TB_KEY_MOUSE_WHEEL_DOWN == $_  and do {
      $button = "MouseWheelDown: %d";
      last;
    };
    case: TB_KEY_MOUSE_RELEASE == $_  and do {
      $button = "MouseRelease: %d";
      last;
    };
  }
  if ($ev->mod & TB_MOD_MOTION) {
    $button .= "*";
  }
  $counter++;
  printf_tb(43, 19, TB_WHITE, TB_DEFAULT, "Key: ");
  printf_tb(48, 19, TB_YELLOW, TB_DEFAULT, $button, $counter);
  return;
}

sub dispatch_press { # void (\%ev)
  my ($ev) = @_;
  if ($ev->mod & TB_MOD_ALT) {
    draw_key(K_LALT, TB_WHITE, TB_RED);
    draw_key(K_RALT, TB_WHITE, TB_RED);
  }
  if ($ev->mod & TB_MOD_CTRL) {
    draw_key(K_LCTRL, TB_WHITE, TB_RED);
    draw_key(K_RCTRL, TB_WHITE, TB_RED);
  }
  if ($ev->mod & TB_MOD_SHIFT) {
    draw_key(K_LSHIFT, TB_WHITE, TB_RED);
    draw_key(K_RSHIFT, TB_WHITE, TB_RED);
  }

  my $k;
  if ($ev->key >= TB_KEY_ARROW_RIGHT) {
    $k = $func_combos->[0xFFFF-$ev->key]
  } elsif ($ev->ch < 128) {
    if ($ev->ch == 0 && $ev->key < 128) {
      $k = $combos->[$ev->key]
    } else {
      $k = $combos->[$ev->ch]
    }
  }
  unless (defined($k) && exists($k->{keys})) {
    return
  }

  my $keys = $k->{keys};
  for (@$keys) {
    draw_key($_, TB_WHITE, TB_RED);
  }
  return;
}

# see https://stackoverflow.com/a/670588
sub OnLeavingScope::DESTROY { ${$_[0]}->() }

sub main { # $ ()

  POSIX::setlocale(&POSIX::LC_ALL, "") if $^O ne 'MSWin32';

  my $ret = tb_init();
  if ($ret) {
    warn sprintf("tb_init() failed with error code %d\n", $ret);
    return 1;
  }
  my $defer = bless \\&tb_shutdown, 'OnLeavingScope';

  tb_set_input_mode(TB_INPUT_ESC | TB_INPUT_MOUSE);
  my $ev = Termbox::Event->new();

  tb_clear();
  draw_keyboard();
  tb_present();
  my $inputmode = 0;
  my $ctrlxpressed = !!0;

loop:
  while (1) {
    $ret = tb_poll_event($ev);

    if ($ret != TB_OK) {
      if ($ret == TB_ERR_POLL && $! == EINTR) {
        # poll was interrupted, maybe by a signal; try again
        next;
      }
      # some other error occurred; bail
      last;
    }

    switch: for ($ev->type) {
      case: TB_EVENT_KEY == $_ and do {
        if ($ev->key == TB_KEY_CTRL_Q && $ctrlxpressed) {
          last loop;
        }
        if ($ev->key == TB_KEY_CTRL_C && $ctrlxpressed) {
          my @chmap = (
            TB_INPUT_ESC | TB_INPUT_MOUSE,
            TB_INPUT_ALT | TB_INPUT_MOUSE,
            TB_INPUT_ESC,
            TB_INPUT_ALT,
          );
          $inputmode++;
          if ($inputmode >= @chmap) {
            $inputmode = 0;
          }
          tb_set_input_mode($chmap[$inputmode]);
        }
        $ctrlxpressed = $ev->key == TB_KEY_CTRL_X;

        tb_clear();
        draw_keyboard();
        dispatch_press($ev);
        pretty_print_press($ev);
        tb_present();
        last;
      };
      case: TB_EVENT_RESIZE == $_ and do {
        tb_clear();
        draw_keyboard();
        pretty_print_resize($ev);
        tb_present();
        last;
      };
      case: TB_EVENT_MOUSE == $_ and do {
        tb_clear();
        draw_keyboard();
        pretty_print_mouse($ev);
        tb_present();
        last;
      };
      default: {
        last;
      };
    }
  }
  return 0;
}

exit do {
  GetOptions('help|?' => \my $help, 'man' => \my $man) or pod2usage(2);
  pod2usage(1) if $help;
  pod2usage(-exitval => 0, -verbose => 2) if $man;
  main($#ARGV, $0, @ARGV);
};

__END__

=head1 NAME

keyboard.pl - sample script that prints the keyboard layout on console/tty.

=head1 SYNOPSIS

  perl example/keyboard.pl

Press CTRL+X and then CTRL+Q to exit

Press CTRL+X and then CTRL+C to change input mode

=head1 DESCRIPTION

This is a Termbox::PP example script, see L<Termbox::PP> for details.

=head1 OPTIONS

=over

=item B<--help|?>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 CREDITS

=over

=item * Copyright (c) 2012 by termbox-go authors

=item * Author J. Schneider E<lt>L<http://github.com/brickpool>E<gt>

=item * MIT license

=back

=cut
