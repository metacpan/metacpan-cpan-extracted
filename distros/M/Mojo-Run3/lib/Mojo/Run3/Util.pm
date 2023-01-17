package Mojo::Run3::Util;
use Mojo::Base 'Exporter';

use POSIX ();

our @EXPORT_OK = qw(stty_set);

our %STTY_FLAGS;
$STTY_FLAGS{$_} = 'attr'  for qw(TCIFLUSH TCIOFF TCIOFLUSH TCION TCOFLUSH TCOOFF TCOON TCSADRAIN TCSAFLUSH TCSANOW);
$STTY_FLAGS{$_} = 'cc'    for qw(VEOF VEOL VERASE VINTR VKILL VQUIT VSUSP VSTART VSTOP VMIN VTIME NCCS);
$STTY_FLAGS{$_} = 'cflag' for qw(CLOCAL CREAD CS5 CS6 CS7 CS8 CSIZE CSTOPB HUPCL PARENB PARODD);
$STTY_FLAGS{$_} = 'iflag' for qw(BRKINT ICRNL IGNBRK IGNCR IGNPAR INLCR INPCK ISTRIP IXOFF IXON PARMRK);
$STTY_FLAGS{$_} = 'lflag' for qw(ECHO ECHOE ECHOK ECHONL ICANON IEXTEN ISIG NOFLSH TOSTOP);
$STTY_FLAGS{$_} = 'oflag' for qw(OPOST);

sub stty_set {
  my ($fileno, @flags) = @_;
  $fileno = fileno($fileno) if ref $fileno;

  my $termios = POSIX::Termios->new;
  for my $flag (@flags) {
    my $unset = $flag =~ s/^-//;
    my $group = $STTY_FLAGS{$flag};
    my ($getter, $setter) = ("get$group", "set$group");
    my $curr = $termios->$getter // 0;
    $termios->$setter($unset ? ($curr & (~POSIX->$flag)) : ($curr | POSIX->$flag));
  }
}

1;

=encoding utf8

=head1 NAME

Mojo::Run3::Util - Utilities for Mojo::Run3

=head1 SYNOPSIS

  use Mojo::Run3::Util qw(stty_set);

  my $run3 = Mojo::Run3->new(driver => {stdin => 'pty', stdout => 'pipe'});
  $run3->once(spawn => sub ($run3) {
    stty_set $run3->handle('stdin'), qw(TCSANOW -ECHO);
  });

  $run3->run_p(sub { exec qw(/usr/bin/ls -l /tmp) })->wait;

=head1 DESCRIPTION

L<Mojo::Run3::Util> contains some utility functions that might be useful for
L<Mojo::Run3>.

=head1 EXPORTED FUNCTIONS

=head2 stty_set

  stty_set $fh, @flags;
  stty_set $fh, qw(TCSANOW -ECHO);

Used to change the L<POSIX> termios flags for a filehandle. Instead of using
L<POSIX/POSIX::Termios> constants you must pass in the names of the constants
instead. A minus will unset the flag.

Currently supported flags:

  Family  | Flag names
  --------|----------------------------------------------------------------------------------
  attr    | TCIFLUSH TCIOFF TCIOFLUSH TCION TCOFLUSH TCOOFF TCOON TCSADRAIN TCSAFLUSH TCSANOW
  c_cc    | VEOF VEOL VERASE VINTR VKILL VQUIT VSUSP VSTART VSTOP VMIN VTIME NCCS
  c_cflag | CLOCAL CREAD CS5 CS6 CS7 CS8 CSIZE CSTOPB HUPCL PARENB PARODD
  c_iflag | BRKINT ICRNL IGNBRK IGNCR IGNPAR INLCR INPCK ISTRIP IXOFF IXON PARMRK
  c_lflag | ECHO ECHOE ECHOK ECHONL ICANON IEXTEN ISIG NOFLSH TOSTOP
  c_oflag | OPOST

=head1 SEE ALSO

L<Mojo::Run3>, L<IO::Stty>, L<IO::Termios>.

=cut
