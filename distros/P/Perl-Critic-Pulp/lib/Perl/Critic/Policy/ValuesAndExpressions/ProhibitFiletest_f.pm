# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


package Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f;
use 5.006;
use strict;
use warnings;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Perl::Critic::Pulp;

our $VERSION = 95;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => 'PPI::Token::Operator';

sub violates {
  my ($self, $elem, $document) = @_;

  return if ($elem->content ne '-f');
  return $self->violation ("Don't use the -f file test", '', $elem);
}

1;
__END__

=for stopwords seekable filename Ryde

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f - don't use the -f file test

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you not to use the C<-f> file test because doing so is
usually wrong or unnecessarily restrictive.  On that basis this policy is
under the "bugs" theme, see L<Perl::Critic/POLICY THEMES>.

=over 4

=item C<-f> is not the opposite of C<-d>

If you're traversing a tree and want to distinguish files from directories
to descend into then C<-d> should be used so device files or pipes can be
processed.

    if (-f $filename) {      # bad
      process ($filename);
    } else {
      descend ($filename);
    }

    if (-d $filename) {      # better
      descend ($filename);
    } else {
      process ($filename);
    }

=item C<-f> doesn't mean readable/writable/seekable

Char specials and named pipes are perfectly good for reading and writing,
and char specials can support seeking.  Demanding C<-f> is an unnecessary
restriction.  You might only ever use ordinary files normally, but there's
no need to prevent someone else running it on a tape drive, F</dev/null>,
etc.  You always have to test each C<seek()> etc for success anyway, and
that will tell you if a file is seekable.

    seek HANDLE, 123, 0
      or die "Cannot seek: $!";

=item C<-e> is better than C<-f>

A few inflexible functions or operations may not have good "file not found"
behaviour and may force you to check for a file before invoking.  Using
C<-e> is better than C<-f> since as described above it doesn't unnecessarily
disallow device files.

    if (-f $filename) {      # bad
      require $filename;
    }

    if (-e $filename) {      # better
      require $filename;
    }

=item C<-f> before opening is a race condition

Testing a filename before opening is bad.  Any test before opening is
useless because the file can change or be removed in between the test and
the open.

    if (-f $filename) {               # bad
      open HANDLE, '<', $filename
    }

If you want to know if the file can be opened then open the file!  The error
return from C<open()> must be checked, so a test beforehand only duplicates
that, and is an opportunity to wrongly presume what the system or the user's
permissions can or can't do.

When opening C<ENOENT> will say if there was no such file, or C<EISDIR> if
it's in fact a directory.

    if (! open HANDLE, '<', $filename) {  # better
      if ($! == POSIX::ENOENT()) {
        ...
      }
    }

If you really do want to enquire into the nature of the file, in order to
only accept ordinary files, then open first and then C<-f> on the handle.
But that's unusual except for an archiving or backup program.

Incidentally, for error message in C<$!> is normally the best thing to
print.  It can be slightly technical, but its wording will at least be
familiar from other programs and will be translated into the user's locale
language.

=back

=head2 Disabling

Most uses of C<-f> tend to shell script style code written in Perl.  In the
shell it's usually not possible to do better than such tests (though C<-d>
or C<-e> is generally still better than C<-f>), but in Perl it is.

A blanket prohibition like this policy is harsh, but is meant as a building
block or at least to make you think carefully whether C<-f> is really right.
As always though you can disable C<ProhibitFiletest_f> from your
F<.perlcriticrc> in the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-ValuesAndExpressions::ProhibitFiletest_f]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<perlfunc/open>,
L<POSIX/ERRNO>,
L<Errno>,
L<errno(3)>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses>.

=cut
