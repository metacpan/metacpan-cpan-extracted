package Term::Completion::_readkey;

use strict;
use Term::ReadKey qw(ReadMode ReadKey GetTerminalSize);

sub set_raw_tty
{
  my __PACKAGE__ $this = shift;
  ReadMode 4, $this->{in} if -t $this->{in};
  1;
}

sub reset_tty
{
  my __PACKAGE__ $this = shift;
  ReadMode 0, $this->{in} if -t $this->{in};
  1;
}

sub get_key
{
  my __PACKAGE__ $this = shift;
  ReadKey(0, $this->{in});
}

if($^O =~ /interix|win/i) {
  require Term::Completion::_termsize;
  *get_term_size = \&Term::Completion::_termsize::get_term_size;
} else {
  *get_term_size = sub {
    my __PACKAGE__ $this = shift;
    if(defined $this->{columns} and defined $this->{rows}) {
      return($this->{columns},  $this->{rows});
    }
    my ($c,$r) = GetTerminalSize($this->{out});
    $c ||= $Term::Completion::DEFAULTS{columns};
    $r ||= $Term::Completion::DEFAULTS{rows};
    return (
      (defined $this->{columns} ? $this->{columns} : $c),
      (defined $this->{rows}    ? $this->{rows}    : $r)
    );
  };
}

1;

__END__

=head1 NAME

Term::Completion::_readkey - utility package for Term::Completion using Term::ReadKey

=head1 DESCRIPTION

This utility package contains few methods that are required for
L<Term::Completion> to put the terminal in "raw" mode and back.
This package uses L<Term::ReadKey> to accomplish this, which should
be portable across many systems.

=head2 Methods

=over 4

=item set_raw_tty()

Uses L<Term::ReadKey>'s C<ReadMode 4> to set the terminal into
"raw" mode, i.e. switch off the meaning of any control characters like
CRTL-C etc. Also the echo of characters is switched off, so that the
program has full control of what is typed and displayed.

Uses the "in" field of the L<Term::Completion> object to get the
input file handle.

=item reset_tty()

Resets the terminal to its previous state, using C<ReadMode 0>.

=item get_key()

Reads one byte from the input handle. Uses C<ReadKey>.

=item get_term_size()

Determine the terminal size with C<GetTerminalSize> and
return the list of columns and rows (two integers).

=back

=head1 AUTHOR

Marek Rouchal E<lt>marekr@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Marek Rouchal. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

L<Term::ReadKey>

=cut
