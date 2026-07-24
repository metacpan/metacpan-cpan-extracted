#!perl
use 5.010;
use strict;
use warnings;

use Getopt::Long qw( GetOptions );
use Pod::Usage;

use lib '../lib', 'lib';
use Termbox::PP;
use Termbox qw( :all );

sub draw_ramp { # void ()
  for (my $i = 0; $i < 256; $i++) {
		my $row = int(($i + 2) / 8) + 3;
		my $col = (($i + 2) % 8) * 4;
		my $text = sprintf("%03d", $i);
    for (my $j = 0; $j < 3; $j++) {
      my $ch = substr($text, $j, 1);
      tb_set_cell($col+$j, $row, $ch, $i+1, TB_DEFAULT);
      tb_set_cell($col+$j+36, $row, $ch, TB_DEFAULT, $i+1);
    }
  }
  tb_present();
  return;
}

sub main { # $ ()
  my $rv = tb_init();
  if ($rv != TB_OK) {
    die tb_strerror($rv);
  }
  tb_set_input_mode(TB_INPUT_ESC);
  tb_set_output_mode(TB_OUTPUT_256);

  draw_ramp();

  my $ev = Termbox::Event->new();
  do {
    tb_poll_event($ev);
  } while ($ev->type != TB_EVENT_KEY);
  tb_shutdown();
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

256ramp.pl - sample script that prints many colors on console/tty.

=head1 SYNOPSIS

  perl example/256ramp.pl

Exit by pressing any key.

=head1 DESCRIPTION

This gives a table of the 256-color-set,
both the foreground and background variants.
It is ordered to produce many color ramps.

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
