#!perl
use 5.010;
use strict;
use warnings;

use Errno qw( EINTR );
use Getopt::Long qw( GetOptions );
use Pod::Usage;

use lib '../lib', 'lib';
use Termbox::PP;
use Termbox qw( :all );
use Time::HiRes;

sub draw { # void ()
  my ($w, $h) = (tb_width(), tb_height());
  tb_clear();
  for (my $y = 0; $y < $h; $y++) {
    for (my $x = 0; $x < $w; $x++) {
      tb_set_cell($x, $y, ' ', TB_DEFAULT, int(rand(8)+1));
    }
  }
  tb_present();
  return;
}

# see https://stackoverflow.com/a/670588
sub OnLeavingScope::DESTROY { ${$_[0]}->() }

sub main { # $ ()
  my $rv = tb_init();
  if ($rv != TB_OK) {
    die tb_strerror($rv);
  }
  my $defer = bless \\&tb_shutdown, 'OnLeavingScope';
  
  my $ev = Termbox::Event->new();

  draw();
loop:
  for (;;) {
    my $rv = tb_peek_event($ev, 0);
    switch: for ($rv) {
      case: TB_OK == $_ and do {
        if ($ev->type == TB_EVENT_KEY && $ev->key == TB_KEY_ESC) {
          last loop;
        }
        last;
      };
      case: TB_ERR_NO_EVENT == $_ and do {
        draw();
        Time::HiRes::sleep(10/1000);
        last;
      };
      case: TB_ERR_POLL == $_ and do {
        last if $! == EINTR;
      };
      default: {
        die tb_strerror($rv);
      }
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

random_output.pl - sample script that prints random colors on console/tty.

=head1 SYNOPSIS

  perl example/random_output.pl

Quit with ESC.

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
