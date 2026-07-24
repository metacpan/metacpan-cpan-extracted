#!perl
use 5.010;
use strict;
use warnings;

use Errno qw( EINTR );
use Getopt::Long qw( GetOptions );
use Pod::Usage;
use Unicode::EastAsianWidth;
use utf8;

use lib '../lib', 'lib';
use Termbox::PP;
use Termbox qw( :all );
use Terminal::WCWidth qw( wcswidth );

use constant {
  TRUE  => !!1,
  FALSE => !!0,
};

use constant chars => "nnnnnnnnnbbbbbbbbbuuuuuuuuuBBBBBBBBB";

our $output_mode = TB_OUTPUT_NORMAL;

sub tb_attribute { 0+$_[0] }

sub next_char { # $ ($current)
  my ($current) = @_;
  $current++;
  if ($current >= length(chars)) {
    return 0;
  }
  return $current;
}

sub print_combinations_table { # void ($sx, $sy, \@attrs)
  my ($sx, $sy, $attrs) = @_;
  my $bg;
  my $current_char = 0;
  my $y = $sy;

  state $all_attrs = [
    0,
    TB_BOLD,
    TB_UNDERLINE,
    TB_BOLD | TB_UNDERLINE,
  ];

  my $draw_line = sub {
    my $x = $sx;
    foreach my $a (@$all_attrs) {
      for (my $c = TB_DEFAULT; $c <= TB_WHITE; $c++) {
        my $fg = $a | $c;
        tb_set_cell($x, $y, substr(chars, $current_char, 1), $fg, $bg);
        $current_char = next_char($current_char);
        $x++;
      }
    }
  };

  foreach my $a (@$all_attrs) {
    for (my $c = TB_DEFAULT; $c <= TB_WHITE; $c++) {
      $bg = $a | $c;
      $draw_line->();
      $y++;
    }
  }
  return;
}

sub print_wide { # void ($x, $y, $s)
  my ($x, $y, $s) = @_;
  state $red = FALSE;
  foreach my $r (split //, $s) {
    my $c = TB_DEFAULT;
    if ($red) {
      $c = TB_RED;
    }
    tb_set_cell($x, $y, $r, TB_DEFAULT, $c);
    my $w = wcswidth($r);
    if ($w <= 0 || $w == 2 && $r =~ /\p{InEastAsianAmbiguous}/) {
      $w = 1;
    }
    $x += $w;

    $red = !$red;
  }
  return;
}

use constant hello_world => "こんにちは世界!";

sub draw_all { # void ()
  tb_clear();

  switch: for ($output_mode) {
    case: $_ == TB_OUTPUT_NORMAL and do {
      print_combinations_table(1, 1, [0, TB_BOLD]);
      print_combinations_table(2+length(chars), 1, [TB_REVERSE]);
      print_wide(2+length(chars), 11, hello_world);
      last;
    };
    case: $_ == TB_OUTPUT_GRAYSCALE and do {
      for (my $y = 0; $y < 26; $y++) {
        for (my $x = 0; $x < 26; $x++) {
          tb_set_cell($x, $y, 'n',
            tb_attribute($x+1),
            tb_attribute($y+1));
          tb_set_cell($x+27, $y, 'b',
            tb_attribute($x+1) | TB_BOLD,
            tb_attribute(26-$y));
          tb_set_cell($x+54, $y, 'u',
            tb_attribute($x+1) | TB_UNDERLINE,
            tb_attribute($y+1));
        }
        tb_set_cell(82, $y, 'd',
          tb_attribute($y+1),
          TB_DEFAULT);
        tb_set_cell(83, $y, 'd',
          TB_DEFAULT,
          tb_attribute(26-$y));
      }
      last;
    };
    case: $_ == TB_OUTPUT_216 and do {
      for (my $r = 0; $r < 6; $r++) {
        for (my $g = 0; $g < 6; $g++) {
          for (my $b = 0; $b < 6; $b++) {
            my $y = $r;
            my $x = $g + 6*$b;
            my $c1 = tb_attribute(1 + $r*36 + $g*6 + $b);
            my $bg = tb_attribute(1 + $g*36 + $b*6 + $r);
            my $c2 = tb_attribute(1 + $b*36 + $r*6 + $g);
            my $bc1 = $c1 | TB_BOLD;
            my $uc1 = $c1 | TB_UNDERLINE;
            my $bc2 = $c2 | TB_BOLD;
            my $uc2 = $c2 | TB_UNDERLINE;
            tb_set_cell($x, $y, 'n', $c1, $bg);
            tb_set_cell($x, $y+6, 'b', $bc1, $bg);
            tb_set_cell($x, $y+12, 'u', $uc1, $bg);
            tb_set_cell($x, $y+18, 'B', $bc1 | $uc1, $bg);
            tb_set_cell($x+37, $y, 'n', $c2, $bg);
            tb_set_cell($x+37, $y+6, 'b', $bc2, $bg);
            tb_set_cell($x+37, $y+12, 'u', $uc2, $bg);
            tb_set_cell($x+37, $y+18, 'B', $bc2 | $uc2, $bg);
          }
          my $c1 = tb_attribute(1 + $g*6 + $r*36);
          my $c2 = tb_attribute(6 + $g*6 + $r*36);
          tb_set_cell(74+$g, $r, 'd', $c1, TB_DEFAULT);
          tb_set_cell(74+$g, $r+6, 'd', $c2, TB_DEFAULT);
          tb_set_cell(74+$g, $r+12, 'd', TB_DEFAULT, $c1);
          tb_set_cell(74+$g, $r+18, 'd', TB_DEFAULT, $c2);
        }
      }
      last;
    };
    case: $_ == TB_OUTPUT_256 and do {
      for (my $y = 0; $y < 4; $y++) {
        for (my $x = 0; $x < 8; $x++) {
          for (my $z = 0; $z < 8; $z++) {
            my $bg = tb_attribute(1 + $y*64 + $x*8 + $z);
            my $c1 = tb_attribute(256 - $y*64 - $x*8 - $z);
            my $c2 = tb_attribute(1 + $y*64 + $z*8 + $x);
            my $c3 = tb_attribute(256 - $y*64 - $z*8 - $x);
            my $c4 = tb_attribute(1 + $y*64 + $x*4 + $z*4);
            my $bold = $c2 | TB_BOLD;
            my $under = $c3 | TB_UNDERLINE;
            my $both = $c1 | TB_BOLD | TB_UNDERLINE;
            tb_set_cell($z+8*$x, $y, ' ', 0, $bg);
            tb_set_cell($z+8*$x, $y+5, 'n', $c4, $bg);
            tb_set_cell($z+8*$x, $y+10, 'b', $bold, $bg);
            tb_set_cell($z+8*$x, $y+15, 'u', $under, $bg);
            tb_set_cell($z+8*$x, $y+20, 'B', $both, $bg);
          }
        }
      }
      for (my $x = 0; $x < 12; $x++) {
        for (my $y = 0; $y < 2; $y++) {
          my $c1 = tb_attribute(233 + $y*12 + $x);
          tb_set_cell(66+$x, $y, 'd', $c1, TB_DEFAULT);
          tb_set_cell(66+$x, 2+$y, 'd', TB_DEFAULT, $c1);
        }
      }
      for (my $x = 0; $x < 6; $x++) {
        for (my $y = 0; $y < 6; $y++) {
          my $c1 = tb_attribute(17 + $x*6 + $y*36);
          my $c2 = tb_attribute(17 + 5 + $x*6 + $y*36);
          tb_set_cell(66+$x, 6+$y, 'd', $c1, TB_DEFAULT);
          tb_set_cell(66+$x, 12+$y, 'd', $c2, TB_DEFAULT);
          tb_set_cell(72+$x, 6+$y, 'd', TB_DEFAULT, $c1);
          tb_set_cell(72+$x, 12+$y, 'd', TB_DEFAULT, $c2);
        }
      }
      last;
    };
  }

  tb_present();
  return;
}

my $available_modes = [
  TB_OUTPUT_NORMAL,
  TB_OUTPUT_GRAYSCALE,
  TB_OUTPUT_216,
  TB_OUTPUT_256,
];

my $output_mode_index = 0;

sub switch_output_mode { # void ($direction)
  my ($direction) = @_;
  $output_mode_index += $direction;
  if ($output_mode_index < 0) {
    $output_mode_index = scalar(@$available_modes) - 1;
  } elsif ($output_mode_index >= scalar(@$available_modes)) {
    $output_mode_index = 0;
  }
  $output_mode = $available_modes->[$output_mode_index];
  tb_set_output_mode($output_mode);
  tb_clear();
  tb_present();
  return;
}

# see https://stackoverflow.com/a/670588
sub OnLeavingScope::DESTROY { ${$_[0]}->() }

sub main { # $ ()
  my $err = tb_init();
  if ($err != 0) {
    die $!;
  }
  my $defer = bless \\&tb_shutdown, 'OnLeavingScope';

  draw_all();

loop:
  for (;;) {
    my $ev = Termbox::Event->new();
    my $rv = tb_poll_event($ev); 
    if ($rv == TB_OK) {
      switch: for ($ev->type) {
        case: $_ == TB_EVENT_KEY and do {
          local $_;
          switch: for ($ev->key) {
            case: $_ == TB_KEY_ESC and do {
              last loop;
            };
            case: $_ == TB_KEY_ARROW_UP || $_ == TB_KEY_ARROW_RIGHT and do {
              switch_output_mode(1);
              draw_all();
              last;
            };
            case: $_ == TB_KEY_ARROW_DOWN || $_ == TB_KEY_ARROW_LEFT and do {
              switch_output_mode(-1);
              draw_all();
              last;
            };
          }
          last;
        };
        case: $_ == TB_EVENT_RESIZE and do {
          draw_all();
          last;
        };
      }
    } else {
      die tb_strerror($rv) 
        unless $rv == TB_ERR_NO_EVENT || ($rv == TB_ERR_POLL && $! == EINTR);
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

output.pl - sample script that shows the termbox output modes.

=head1 SYNOPSIS

  perl example/output.pl

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
