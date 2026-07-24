#!perl
use 5.010;
use strict;
use warnings;

use Getopt::Long qw( GetOptions );
use Pod::Usage;

use lib '../lib', 'lib';
use Termbox::PP;
use Termbox qw( :all );

sub main { # $ ()
  tb_init();

  my ($i, $j);
  my ($fg, $bg);
  my @colorRange = (
    TB_DEFAULT,
    TB_BLACK,
    TB_RED,
    TB_GREEN,
    TB_YELLOW,
    TB_BLUE,
    TB_MAGENTA,
    TB_CYAN,
    TB_WHITE,
    TB_BLACK    | TB_BRIGHT,
    TB_RED      | TB_BRIGHT,
    TB_GREEN    | TB_BRIGHT,
    TB_YELLOW   | TB_BRIGHT,
    TB_BLUE     | TB_BRIGHT,
    TB_MAGENTA  | TB_BRIGHT,
    TB_CYAN     | TB_BRIGHT,
    TB_WHITE    | TB_BRIGHT,
  );

  my ($row, $col);
  my $text;
  do { $i = 0; for $fg (@colorRange) {
    do { $j = 0; for $bg (@colorRange) {
      $row = $i + 1;
      $col = $j * 8;
      tb_printf($col, $row+0, $fg, $bg, " %02d/%02d ", $i, $j);
      q/* 
      tb_print($col, $row+1, $fg, $bg, " on ");
      tb_printf($col, $row+2, $fg, $bg, " %2d ", $bg);
      */ if 0;
      # warn("$text\n", $col, $row);
    } continue { $j++ }};
  } continue { $i++ }};
  do { $j = 0; for $bg (@colorRange) {
    tb_print($j*8, 0, TB_DEFAULT, $bg, "       ");
    tb_print($j*8, $i+2, TB_DEFAULT, $bg, "       ");
  } continue { $j++ }};

  tb_print(15, $i+4, TB_DEFAULT, TB_DEFAULT,
    "Press any key to close...");
  tb_present();
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

16colortest.pl - an app that demonstrate 16 colors on console/tty.

=head1 SYNOPSIS

  perl example/16colortest.pl

Exit by pressing any key.

=head1 DESCRIPTION

This program can demonstrate the 16 basic colors available
for foreground and background.

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
