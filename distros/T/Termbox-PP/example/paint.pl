#!perl
use 5.010;
use strict;
use warnings;

use Getopt::Long qw( GetOptions );
use Pod::Usage;
use utf8;

use lib '../lib', 'lib';
use Termbox::PP;

my $curCol = 0;
my $curChar = 0;
my $backbuf = [];
my ($bbw, $bbh);

my $chars = [ ' ', '░', '▒', '▓', '█' ];
my $colors = [
  Termbox::TB_BLACK,
  Termbox::TB_RED,
  Termbox::TB_GREEN,
  Termbox::TB_YELLOW,
  Termbox::TB_BLUE,
  Termbox::TB_MAGENTA,
  Termbox::TB_CYAN,
  Termbox::TB_WHITE,
];

sub updateAndDrawButtons { # void (\$current, $x, $y, $mx, $my, $n, \&attrf)
  my ($current, $x, $y, $mx, $my, $n, $attrf) = @_;
  my ($lx, $ly) = ($x, $y);
  for (my $i = 0; $i < $n; $i++) {
    if ($lx <= $mx && $mx <= $lx+3 && $ly <= $my && $my <= $ly+1) {
      $$current = $i;
    }
    my ($ch, $fg, $bg) = $attrf->($i);
    Termbox::tb_set_cell($lx+0, $ly+0, $ch, $fg, $bg);
    Termbox::tb_set_cell($lx+1, $ly+0, $ch, $fg, $bg);
    Termbox::tb_set_cell($lx+2, $ly+0, $ch, $fg, $bg);
    Termbox::tb_set_cell($lx+3, $ly+0, $ch, $fg, $bg);
    Termbox::tb_set_cell($lx+0, $ly+1, $ch, $fg, $bg);
    Termbox::tb_set_cell($lx+1, $ly+1, $ch, $fg, $bg);
    Termbox::tb_set_cell($lx+2, $ly+1, $ch, $fg, $bg);
    Termbox::tb_set_cell($lx+3, $ly+1, $ch, $fg, $bg);
    $lx += 4;
  }
  ($lx, $ly) = ($x, $y);
  for (my $i = 0; $i < $n; $i++) {
    if ($$current == $i) {
      my $fg = Termbox::TB_RED | Termbox::TB_BOLD;
      my $bg = Termbox::TB_DEFAULT;
      Termbox::tb_set_cell($lx+0, $ly+2, '^', $fg, $bg);
      Termbox::tb_set_cell($lx+1, $ly+2, '^', $fg, $bg);
      Termbox::tb_set_cell($lx+2, $ly+2, '^', $fg, $bg);
      Termbox::tb_set_cell($lx+3, $ly+2, '^', $fg, $bg);
    }
    $lx += 4;
  }
  return;
}

sub update_and_redraw_all { # void ($mx, $my)
  my ($mx, $my) = @_;
  Termbox::tb_clear();
  if ($mx != -1 && $my != -1) {
    $backbuf->[$bbw*$my+$mx] = bless [
      $chars->[$curChar],     # ch
      $colors->[$curCol],     # fg
      Termbox::TB_DEFAULT,    # bg
    ] => 'Termbox::Cell';
  }
  copy: {
    my $cells = Termbox::tb_cell_buffer();
    @{$cells->[$_]} = @{$backbuf->[$_]} for 0..$#$cells;
  }
  my $h = Termbox::tb_height();
  updateAndDrawButtons(\$curChar, 0, 0, $mx, $my, scalar(@$chars), sub {
    return ($chars->[shift], Termbox::TB_DEFAULT, Termbox::TB_DEFAULT);
  });
  updateAndDrawButtons(\$curCol, 0, $h-3, $mx, $my, scalar(@$colors), sub {
    return (' ', Termbox::TB_DEFAULT, $colors->[shift]);
  });
  Termbox::tb_present();
  return;
}

sub reallocBackBuffer { # void ($w, $h)
  my ($w, $h) = @_;
  ($bbw, $bbh) = ($w, $h);
  $backbuf = [ map { Termbox::Cell->new() } 1..$w*$h ];
  $_->[0] = ' ' foreach @$backbuf;
  return;
}

# see https://stackoverflow.com/a/670588
sub OnLeavingScope::DESTROY { ${$_[0]}->() }

sub main { # $ ()
  my $rv = Termbox::tb_init();
  if ($rv != Termbox::TB_OK) {
    die Termbox::tb_strerror($rv);
  }
  #my $defer = bless \\&Termbox::tb_shutdown, 'OnLeavingScope';
  Termbox::tb_set_input_mode(Termbox::TB_INPUT_ESC | Termbox::TB_INPUT_MOUSE);
  reallocBackBuffer(Termbox::tb_width(), Termbox::tb_height());
  update_and_redraw_all(-1, -1);

  my $ev = Termbox::Event->new();
mainloop:
  for (;;) {
    my ($mx, $my) = (-1, -1);
    Termbox::tb_poll_event($ev); 
    switch: for ($ev->type) {
      case: Termbox::TB_EVENT_KEY == $_ and do {
        if ($ev->key == Termbox::TB_KEY_ESC) {
          last mainloop
        }
        last;
      };
      case: Termbox::TB_EVENT_MOUSE == $_ and do {
        if ($ev->key == Termbox::TB_KEY_MOUSE_LEFT) {
          ($mx, $my) = ($ev->x, $ev->y);
        }
        last;
      };
      case: Termbox::TB_EVENT_RESIZE == $_ and do {
        reallocBackBuffer($ev->w, $ev->h);
        last;
      };
    }
    update_and_redraw_all($mx, $my);
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

paint.pl - sample script for the Termbox::Go module!

=head1 SYNOPSIS

  perl example/paint.pl

=head1 DESCRIPTION

This is a Termbox::Go example script, see L<Termbox::Go> for details.

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
