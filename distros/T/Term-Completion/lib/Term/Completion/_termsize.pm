package Term::Completion::_termsize;

use strict;

my $get_term_size;

# try to load Term::Size
if( eval { require Term::Size; 1; } && !$@) {
  $get_term_size = sub {
    return Term::Size::chars($_[0]);
  };
}
# we try poor man's ioctl - stolen from perlfaq8
else {
  eval { require 'sys/ioctl.ph'; 1; };
  eval { require 'sys/termios.ph'; 1; };
  if(defined &TIOCGWINSZ) {
    $get_term_size = sub {
      my $winsize = '';
      unless(ioctl($_[0], &TIOCGWINSZ, $winsize) =~ /^0/) {
        return;
      }
      my ($row, $col, $xpixel, $ypixel) = unpack('S4', $winsize);
      return($col,$row);
    };
  } else {
    # we don't have a way to get the terminal size
    $get_term_size = sub {
      return (undef, undef);
    }
  }
}

sub get_term_size
{
  my __PACKAGE__ $this = shift;
  my ($c,$r);
  if(defined $get_term_size) {
    ($c,$r) = &$get_term_size($this->{out});
  } else {
    ($c,$r) = ($Term::Completion::DEFAULTS{columns},
               $Term::Completion::DEFAULTS{rows});
  }
  return (
    (defined $this->{columns} ? $this->{columns} : $c),
    (defined $this->{rows}    ? $this->{rows}    : $r)
  );
}

1;

__END__

=head1 NAME

Term::Completion::_termsize - utility package to determine terminal size

=head1 DESCRIPTION

This utility package contains a method that is required for
L<Term::Completion> to determine the size (columns, rows) of
the current terminal window.
This package uses L<Term::Size> if available, and tries to
fall back on the L<perlfunc/ioctl> and some header files if not.

=head2 Methods

=over 4

=item get_term_size()

Return the terminal size as a list of columns and rows.

=back

=head1 AUTHOR

Marek Rouchal E<lt>marekr@cpan.orgE<gt>

Reused code from L<perlfaq8/"How do I get the screen size?">.

=head1 COPYRIGHT

Copyright (c) 2009, Marek Rouchal. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

L<Term::Size>, L<perlfaq8>

=cut

