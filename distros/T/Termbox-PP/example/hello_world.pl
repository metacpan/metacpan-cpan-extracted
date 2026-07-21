#!perl
use 5.010;
use strict;
use warnings;

use Getopt::Long qw( GetOptions );
use Pod::Usage;

use lib '../lib', 'lib';
use Termbox::PP;

sub main { # $ ()
  my $err = Termbox::tb_init();
  if ($err) {
    warn Termbox::tb_strerror($err);
    return 1;
  }

  Termbox::tb_print(2, 2, Termbox::TB_RED, Termbox::TB_DEFAULT, 
    "Hello terminal!");
  Termbox::tb_present();

  sleep(1);
  Termbox::tb_shutdown();
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

hello_world.pl - sample script that usually prints "Hello terminal!"

=head1 SYNOPSIS

  perl example/hello_world.pl

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

=item * Copyright (c) 2021 by termbox developers

=item * Author J. Schneider E<lt>L<http://github.com/brickpool>E<gt>

=item * MIT license

=back

=cut
