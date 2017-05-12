package Term::Completion::_stty;

use strict;
use Carp;
use base qw(Term::Completion::_termsize);

# initialize the stty program
our @PATH;
unless(@PATH) {
 @PATH = qw(/bin /usr/bin);
}
our ($stty, $tty_raw_noecho, $tty_restore);
foreach my $p (@PATH) {
  my $s = "$p/stty";
  if (-x $s) {
    $stty = $s;
    $tty_raw_noecho = "$s raw -echo";
    $tty_restore    = "$s -raw echo";
  }
}
unless(defined $stty) {
  croak "Cannot initialize ".__PACKAGE__.", no stty executable found in @PATH";
}

sub set_raw_tty
{
  my __PACKAGE__ $this = shift;

  # Attempt to save the current stty state, to be restored later
  if (defined $stty && !defined $this->{tty_saved_state}) {
    $this->{tty_saved_state} = qx($stty -g 2>/dev/null);
    if ($?) {
      # stty -g not supported
      $this->{tty_saved_state} = undef;
    } else {
      $this->{tty_saved_state} =~ s/\s+$//g;
    }
  }

  # run stty to set the mode
  system $tty_raw_noecho if defined $tty_raw_noecho;
  1;
}

sub reset_tty
{
  my __PACKAGE__ $this = shift;
  # do our best to restore the terminal state
  if (defined $this->{tty_saved_state}) {
    # use the saved state
    system qq($stty '$this->{tty_saved_state}' 2>/dev/null);
    if ($?) {
      # error - fall back
      system $tty_restore;
    }
  }
  elsif(defined $tty_restore) {
    system $tty_restore;
  }
  1;
}

sub get_key
{
  my __PACKAGE__ $this = shift;
  getc($this->{in});
}

1;

__END__

=head1 NAME

Term::Completion::_stty - utility package for Term::Completion using stty

=head1 DESCRIPTION

This utility package contains few methods that are required for
L<Term::Completion> to put the terminal in "raw" mode and back.
This package uses the C<stty> utility, which however is probably
only available on UNIX.

This is basically a copy from the original L<Term::Complete> and
provided for compatibility reasons. Instead of this, the
L<Term::Completion::_POSIX> implementation should be used.

=head2 Methods

=over 4

=item set_raw_tty()

Uses C<stty raw -echo> to set the terminal into
"raw" mode, i.e. switch off the meaning of any control characters like
CRTL-C etc. Also the echo of characters is switched off, so that the
program has full control of what is typed and displayed.

Before doing that, tries to capture the terminal's current
state with C<stty -g> and stores that for later use.

Will work on STDIN and ignore what was set as the input handle
in L<Term::Completion>.

=item reset_tty()

Resets the terminal to its previous state, using the saved state.
If that's unavailable, fall back to C<stty -raw echo>.

=item get_key()

Reads one byte from the input handle. Uses standard getc(), 
see also L<perlfunc/getc>.

=back

=head1 AUTHOR

Marek Rouchal E<lt>marekr@cpan.orgE<gt>

Reused code from L<Term::Complete> which is part of the Perl core
distribution.

=head1 COPYRIGHT

Copyright (c) 2009, Marek Rouchal. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

L<Term::Complete>

=cut
