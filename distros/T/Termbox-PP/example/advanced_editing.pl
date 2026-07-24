#!perl
use 5.010;
use strict;
use warnings;

use Getopt::Long qw( GetOptions );
use Pod::Usage;
use threads;

use lib '../lib', 'lib';
use Termbox::PP;

use constant TRUE => !!1;

my $letters = ['o', 'x', 'i', 'n', 'u', 's', ' '];

my $color = 0;

sub main { # $ ()
  my $rv = Termbox::tb_init();

  if ($rv != Termbox::TB_OK) {
    warn Termbox::tb_strerror($rv);
    return 1;
  }

  my $cell = Termbox::Cell->new();
  my ($w, $h) = (Termbox::tb_width(), Termbox::tb_height());
  for (my $x = 0; $x < $w; $x++) {
    for (my $y = 0; $y < $h; $y++) {
      Termbox::tb_get_cell($x, $y, TRUE, \$cell);
      Termbox::tb_set_cell($x, $y, $letters->[int(rand(scalar(@$letters)))], 
        $cell->fg, $cell->bg);
    }
  }
  Termbox::tb_present();

  threads->create( \&bgthread )->detach();

  my $ev = Termbox::Event->new();
  for (;;) {
    Termbox::tb_poll_event($ev);
    if ($ev->type == Termbox::TB_EVENT_KEY) {
      if ($ev->ch == ord('q') || $ev->key == Termbox::TB_KEY_ESC) {
        last;
      } elsif ($ev->ch == ord('h') || $ev->key == Termbox::TB_KEY_ARROW_LEFT) {
        $color--;
      } elsif ($ev->ch == ord('l') || $ev->key == Termbox::TB_KEY_ARROW_RIGHT) {
        $color++;
      }
      while ($color < 0) {
        $color += 9;
      }
      $color %= 9;
      fillbg($color);
      Termbox::tb_present();
    }
  }

  Termbox::tb_shutdown();
  return 0;
}

sub fillbg { # void ($bg)
  my ($bg) = @_;
  my ($w, $h) = (Termbox::tb_width(), Termbox::tb_height());
  my $cell = Termbox::Cell->new();
  for (my $x = 0; $x < $w; $x++) {
    for (my $y = 0; $y < $h; $y++) {
      Termbox::tb_get_cell($x, $y, TRUE, \$cell);
      Termbox::tb_set_cell($x, $y, chr $cell->ch, $cell->fg, $bg);
    }
  }
  return;
}

sub bgthread { # void ()
  my $cell = Termbox::Cell->new();
  for (;;) {
    my ($w, $h) = (Termbox::tb_width(), Termbox::tb_height());
    for (my $x = 0; $x < $w; $x++) {
      for (my $y = 0; $y < $h; $y++) {
        Termbox::tb_get_cell($x, $y, 1, \$cell);
        Termbox::tb_set_cell($x, $y, chr $cell->ch, int(rand(9)), $cell->bg);
      }
    }
    Termbox::tb_present();
    sleep 1;
  }
  return;
}

exit do {
  GetOptions('help|?' => \my $help, 'man' => \my $man) or pod2usage(2);
  pod2usage(1) if $help;
  pod2usage(-exitval => 0, -verbose => 2) if $man;
  main($#ARGV, $0, @ARGV);
};

__END__

=head1 NAME

advanced_editing.pl - sample script for the Termbox library

=head1 SYNOPSIS

  perl example/advanced_editing.pl

=head1 DESCRIPTION

A number of colored letters are displayed.
You can change the background color using the arrow keys.
the foreground color changes randomly over time.

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
