package Term::Completion::_POSIX;

use strict;
use POSIX qw(:termios_h);
use base qw(Term::Completion::_termsize);

# we use POSIX termios to set the 'raw' tty properties

sub set_raw_tty
{
  my __PACKAGE__ $this = shift;

  # check if is a TTY
  return unless -t $this->{in};

  my $fd = fileno($this->{in});
  my $termios = ($this->{_termios} ||= POSIX::Termios->new($fd));

  # now we want 'raw' mode with echo off
  # according to IO::Stty this is in detail:
  # -ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr
  # -icrnl -ixon -ixoff -opost -isig -icanon min 1 time 0 -echo

  # according to Solaris' stty:
  # cs8 -icanon min 1 time 0 -isig -xcase -inpck -opost -echo

  # Linux?
  my   $set_ccflags = CS8;
  my $unset_ciflags = IGNBRK | BRKINT | IGNPAR | PARMRK | INPCK | ISTRIP | INLCR | IGNCR | ICRNL | IXON | IXOFF;
  my $unset_clflags = ISIG | ICANON | ECHO;
  my $unset_coflags = OPOST;

  # get & save the original values:
  $termios->getattr();
  my $c_cflag = $this->{_tty_cflag} = $termios->getcflag;
  my $c_iflag = $this->{_tty_iflag} = $termios->getiflag;
  my $c_lflag = $this->{_tty_lflag} = $termios->getlflag;
  my $c_oflag = $this->{_tty_oflag} = $termios->getoflag;
  $this->{_tty_vmin} = $termios->getcc(VMIN);
  $this->{_tty_vtime} = $termios->getcc(VTIME);

  # now set the values
  $c_cflag |= $set_ccflags;
  $c_iflag &= ~$unset_ciflags;
  $c_lflag &= ~$unset_clflags;
  $c_oflag &= ~$unset_coflags;

  $termios->setcflag($c_cflag);
  $termios->setiflag($c_iflag);
  $termios->setlflag($c_lflag);
  $termios->setoflag($c_oflag);
  $termios->setcc(VMIN,1); # 1
  $termios->setcc(VTIME,0); # 0
  $termios->setattr($fd, TCSANOW);
  1;
}

sub reset_tty
{
  my __PACKAGE__ $this = shift;
  return unless -t $this->{in};
  my $fd = fileno($this->{in});
  my $termios = delete $this->{_termios};
  $termios->setcflag($this->{_tty_cflag});
  $termios->setiflag($this->{_tty_iflag});
  $termios->setlflag($this->{_tty_lflag});
  $termios->setoflag($this->{_tty_oflag});
  $termios->setcc(VMIN, $this->{_tty_vmin});
  $termios->setcc(VTIME, $this->{_tty_vtime});
  $termios->setattr($fd, TCSANOW);
  delete $this->{grep(/^_tty_/, keys %$this)};
  1;
}

sub get_key
{
  my __PACKAGE__ $this = shift;
  getc($this->{in});
}

1;

__END__

=for stopwords Schutz Solaris CTRL

=head1 NAME

Term::Completion::_POSIX - utility package for Term::Completion using POSIX termios

=head1 DESCRIPTION

This utility package contains few methods that are required for
L<Term::Completion> to put the terminal in "raw" mode and back.
This package uses POSIX termios to accomplish this, which should
be portable across many UNIX-like systems. It was successfully
tested on Solaris and Linux.

=head2 Methods

=over 4

=item set_raw_tty()

Uses L<POSIX/"POSIX::Termios"> and related methods to set the terminal into
"raw" mode, i.e. switch off the meaning of any control characters like
CTRL-C etc. Also the echo of characters is switched off, so that the
program has full control of what is typed and displayed.

Uses the "in" field of the L<Term::Completion> object to get the
input file handle. Won't do anything if this is not a TTY. See also
L<perlfunc/-X>.

=item reset_tty()

Resets the terminal to its previous state, which was saved in the
object's fields (C<_tty_XXX>).

=item get_key()

Reads one byte from the input handle. Internally uses
L<perlfunc/getc>.

=back

=head1 AUTHOR

Marek Rouchal E<lt>marekr@cpan.orgE<gt>

Some ideas were borrowed from L<IO::Stty> by Austin Schutz

=head1 COPYRIGHT

Copyright (c) 2009, Marek Rouchal. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

L<POSIX>, L<IO::Stty>

=cut
