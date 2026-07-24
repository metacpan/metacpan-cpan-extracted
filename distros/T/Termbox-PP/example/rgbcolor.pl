#!perl
use 5.010;
use strict;
use warnings;

use Errno qw( EINTR );
use Getopt::Long qw( GetOptions );
use Pod::Usage;

use lib '../lib', 'lib';
use Termbox::PP;;
use Termbox qw( :all );

use constant {
  TRUE  => !!1,
  FALSE => !!0,
};

my $fgR = 150;
my $fgG = 100;
my $fgB = 50;

my $bgR = 50;
my $bgG = 100;
my $bgB = 150;

my $currentBold = TRUE;
my $currentUnderline = FALSE;
my $currentReverse = FALSE;
my $currentRGB = Termbox::TB_OPT_ATTR_W > 32;
my $currentCursive = FALSE;
my $currentHidden = FALSE;
my $currentBlink = FALSE;
my $currentDim = FALSE;

my $boolLabel = [];

use constant preview => " Here is some example text ";
use constant padding => "                           ";

use constant coldef => TB_DEFAULT;

sub RGBToAttribute {
  my ($r, $g, $b) = @_;
  return TB_HI_BLACK if $r == 0 && $g == 0 && $b == 0;
  return ($r << 16) | ($g << 8) | $b;
}

sub redraw_all { # void ()
  tb_print(20, 1, coldef, coldef, " - Current Settings - ");

  my ($r, $g, $b);
  $r = sprintf("%3d", $fgR);
  $g = sprintf("%3d", $fgG);
  $b = sprintf("%3d", $fgB);
  tb_print(4, 3, coldef, coldef, "Foreground Red:");
  tb_print(5, 4, coldef, coldef, "[h] $r [l]");
  tb_print(4, 5, coldef, coldef, "Foreground Green:");
  tb_print(5, 6, coldef, coldef, "[j] $g [k]");
  tb_print(4, 7, coldef, coldef, "Foreground Blue:");
  tb_print(5, 8, coldef, coldef, "[u] $b [i]");

  $r = sprintf("%3d", $bgR);
  $g = sprintf("%3d", $bgG);
  $b = sprintf("%3d", $bgB);
  tb_print(23, 3, coldef, coldef, "Background Red:");
  tb_print(24, 4, coldef, coldef, "[H] $r [L]");
  tb_print(23, 5, coldef, coldef, "Background Green:");
  tb_print(24, 6, coldef, coldef, "[J] $g [K]");
  tb_print(23, 7, coldef, coldef, "Background Blue:");
  tb_print(24, 8, coldef, coldef, "[U] $b [I]");

  my ($bold, $ul, $rev, $rgb, $cur, $hid, $blink, $dim);
  $bold = $boolLabel->[$currentBold];
  $ul = $boolLabel->[$currentUnderline];
  $rev = $boolLabel->[$currentReverse];
  $rgb = $boolLabel->[$currentRGB];
  $cur = $boolLabel->[$currentCursive];
  $hid = $boolLabel->[$currentHidden];
  $blink = $boolLabel->[$currentBlink];
  $dim = $boolLabel->[$currentDim];

  tb_print(42, 3, coldef, coldef, "Bold:");
  tb_print(43, 4, coldef, coldef, "$bold [w]");
  tb_print(42, 5, coldef, coldef, "Underline:");
  tb_print(43, 6, coldef, coldef, "$ul [a]");
  tb_print(42, 7, coldef, coldef, "Reverse:");
  tb_print(43, 8, coldef, coldef, "$rev [s]");
  tb_print(42, 9, coldef, coldef, "Full RGB:");
  tb_print(43, 10, coldef, coldef, "$rgb [t]");
  tb_print(54, 3, coldef, coldef, "Cursive:");
  tb_print(55, 4, coldef, coldef, "$cur [d]");
  tb_print(54, 5, coldef, coldef, "Hidden:");
  tb_print(55, 6, coldef, coldef, "$hid [e]");
  tb_print(54, 7, coldef, coldef, "Blink:");
  tb_print(55, 8, coldef, coldef, "$blink [r]");
  tb_print(54, 9, coldef, coldef, "Dim:");
  tb_print(55, 10, coldef, coldef, "$dim [f]");

  tb_print(20, 12, coldef, coldef, "Quit with [q] or [ESC]");
  tb_print(6, 13, coldef, coldef, "Note that RGB may be incompatible with other modifiers");

  my ($fg, $bg);
  if (Termbox::TB_OPT_ATTR_W > 32 && $currentRGB) {
    tb_set_output_mode(TB_OUTPUT_TRUECOLOR());
    $fg = RGBToAttribute($fgR, $fgG, $fgB);
    $bg = RGBToAttribute($bgR, $bgG, $bgB);
  } else {
    tb_set_output_mode(TB_OUTPUT_NORMAL);
    $fg = TB_RED;
    $bg = TB_DEFAULT;
  }
  my $tfg = $fg; # tfg are the attributes that should be applied to the text
  if ($currentBold) {
    $tfg |= TB_BOLD;
  }
  if ($currentUnderline) {
    $tfg |= TB_UNDERLINE;
  }
  if ($currentReverse) {
    $fg |= TB_REVERSE;
    $tfg |= TB_REVERSE;
  }
  if ($currentCursive) {
    $tfg |= TB_ITALIC;
  }
  if (Termbox::TB_OPT_ATTR_W == 64 && $currentHidden) {
    $fg |= TB_INVISIBLE();
    $tfg |= TB_INVISIBLE();
  }
  if ($currentBlink) {
    $fg |= TB_BLINK;
    $tfg |= TB_BLINK;
  }
  if ($currentDim) {
    $fg |= TB_DIM;
    $tfg |= TB_DIM;
  }
  tb_print(18, 15, $fg, $bg, padding);
  tb_print(18, 16, $tfg, $bg, preview);
  tb_print(18, 17, $fg, $bg, padding);

  tb_present();
  return;
}

# see https://stackoverflow.com/a/670588
sub OnLeavingScope::DESTROY { ${$_[0]}->() }

sub main { # $ ()
  $boolLabel->[FALSE] = "Off";
  $boolLabel->[TRUE] = "On ";

  my $rv = tb_init();
  if ($rv != TB_OK) {
    die tb_strerror($rv);
  }
  my $defer = bless \\&tb_shutdown, 'OnLeavingScope';
  tb_set_input_mode(TB_INPUT_ESC);

  redraw_all();
mainloop:
  for (;;) {
    my $ev = Termbox::Event->new();
    $rv = tb_poll_event($ev);
    if ($rv == TB_OK) {
      if ($ev->type == TB_EVENT_KEY) {
        switch: for ($ev->key) {
          case: $_ == TB_KEY_ESC and do {
            last mainloop;
          };
          default: {
            local $_;
            switch: for ($ev->ch) {
              case: $_ == ord('q') || $_ == ord('Q') and do {
                last mainloop;
              };
              case: $_ == ord('h') and do {
                $fgR--;
                $fgR %= 256;
                last;
              };
              case: $_ == ord('l') and do {
                $fgR++;
                $fgR %= 256;
                last;
              };
              case: $_ == ord('j') and do {
                $fgG--;
                $fgG %= 256;
                last;
              };
              case: $_ == ord('k') and do {
                $fgG++;
                $fgG %= 256;
                last;
              };
              case: $_ == ord('u') and do {
                $fgB--;
                $fgB %= 256;
                last;
              };
              case: $_ == ord('i') and do {
                $fgB++;
                $fgB %= 256;
                last;
              };
              case: $_ == ord('H') and do {
                $bgR--;
                $bgR %= 256;
                last;
              };
              case: $_ == ord('L') and do {
                $bgR++;
                $bgR %= 256;
                last;
              };
              case: $_ == ord('J') and do {
                $bgG--;
                $bgG %= 256;
                last;
              };
              case: $_ == ord('K') and do {
                $bgG++;
                $bgG %= 256;
                last;
              };
              case: $_ == ord('U') and do {
                $bgB--;
                $bgB %= 256;
                last;
              };
              case: $_ == ord('I') and do {
                $bgB++;
                $bgB %= 256;
                last;
              };
              case: $_ == ord('w') || $_ == ord('W') and do {
                $currentBold = !$currentBold;
                last;
              };
              case: $_ == ord('a') || $_ == ord('A') and do {
                $currentUnderline = !$currentUnderline;
                last;
              };
              case: $_ == ord('s') || $_ == ord('S') and do {
                $currentReverse = !$currentReverse;
                last;
              };
              case: $_ == ord('t') || $_ == ord('T') and do {
                $currentRGB = !$currentRGB;
                last;
              };
              case: $_ == ord('d') || $_ == ord('D') and do {
                $currentCursive = !$currentCursive;
                last;
              };
              case: $_ == ord('e') || $_ == ord('E') and do {
                $currentHidden = !$currentHidden;
                last;
              };
              case: $_ == ord('r') || $_ == ord('R') and do {
                $currentBlink = !$currentBlink;
                last;
              };
              case: $_ == ord('f') || $_ == ord('F') and do {
                $currentDim = !$currentDim;
                last;
              };
            }
          }
        }
      }
    } else {
      die tb_strerror($rv) 
        unless $rv == TB_ERR_NO_EVENT || ($rv == TB_ERR_POLL && $! == EINTR);
    }
    redraw_all();
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

rgbcolor.pl - sample script that demonstrate RGB colors on console/tty.

=head1 SYNOPSIS

  perl example/rgbcolor.pl

=head1 DESCRIPTION

This example should demonstrate the functionality of full rgb-support, 
as well as the ability to combine rgb colors and (multiple) attributes.

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
