# Copyright 2009, 2010, 2011, 2014 Kevin Ryde

# This file is part of POSIX-Wide.
#
# POSIX-Wide is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# POSIX-Wide is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with POSIX-Wide.  If not, see <http://www.gnu.org/licenses/>.


# Possible funcs:
#   asctime()
#   ctime()
#       Believe always ascii day/month, or at least that's what glibc gives.
#
# Different:
#   strcoll()
#   strxfrm()


package POSIX::Wide;
use 5.008;
use strict;
use warnings;
use POSIX ();
use Encode;
use Encode::Locale;  # has 'locale' from its initial 0.01 release

our $VERSION = 10;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(localeconv perror strerror strftime tzname
                    $ERRNO $EXTENDED_OS_ERROR);
# not yet ...
# our %EXPORT_TAGS = (all => \@EXPORT_OK);

use POSIX::Wide::ERRNO;
tie (our $ERRNO, 'POSIX::Wide::ERRNO');

use POSIX::Wide::EXTENDED_OS_ERROR;
tie (our $EXTENDED_OS_ERROR, 'POSIX::Wide::EXTENDED_OS_ERROR');


our @LOCALECONV_STRING_FIELDS = (qw(decimal_point
                                    thousands_sep
                                    int_curr_symbol
                                    currency_symbol
                                    mon_decimal_point
                                    mon_thousands_sep
                                    positive_sign
                                    negative_sign));

# POSIX.xs of perl 5.10.1 has mon_thousands_sep conditionalized, so allow
# for it and maybe other fields to not exist.
#
# POSIX.xs omits fields which are empty strings "", so for example when
# positive_sign is an empty string (which is usual in an English locale)
# there's no such field in the POSIX::localeconv() return.
#
sub localeconv {
  my $l = POSIX::localeconv();
  foreach my $key (@LOCALECONV_STRING_FIELDS) {
    if (exists $l->{$key}) {
      $l->{$key} = _to_wide($l->{$key});
    }
  }
  return $l;
}

# STDERR like POSIX/perror.al
sub perror {
  if (@_) { print STDERR @_,': '; }
  print STDERR strerror($!),"\n";
}

sub strerror {
  return _to_wide (POSIX::strerror ($_[0]));
}

# \020-\176 is printable ascii
# only basic control chars are allows through to strftime, in particular Esc
# is excluded in case the locale is shift-jis etc and it means something
sub strftime {
  (my $fmt = shift) =~ s{(%[\020-\176\t\n\r\f\a]*)}
                        { _to_wide(POSIX::strftime($1,@_)) }ge;
  return $fmt;
}

sub tzname {
  return map {_to_wide($_)} POSIX::tzname();
}

sub _to_wide {
  my ($str) = @_;
  if (utf8::is_utf8($str)) { return $str; }

  # netbsd langinfo(CODESET) returns "646" meaning ISO-646, ie. ASCII.  Must
  # put that through resolve_alias() to turn it into "ascii".
  #
  return Encode::decode ('locale', $str, Encode::FB_CROAK());
}

1;
__END__

=for stopwords POSIX charset Eg funcs hashref errno MacOS VMS POSIX-Wide Ryde utf8

=head1 NAME

POSIX::Wide -- POSIX functions returning wide-char strings

=head1 SYNOPSIS

 use POSIX::Wide;
 print POSIX::Wide::strerror(2),"\n";
 print POSIX::Wide::strftime("%a %d-%b\n",localtime());

=head1 DESCRIPTION

This is a few of the C<POSIX> module functions adapted to return Perl
wide-char strings instead of locale charset byte strings.  This is good if
working with wide-chars internally (and converting on I/O).

The locale charset is determined by L<Encode::Locale>.

=head1 EXPORTS

Nothing is exported by default, but each of the functions and the C<$ERRNO>
and C<$EXTENDED_OS_ERROR> variables can be imported in usual C<Exporter>
style.  Eg.

    use POSIX::Wide 'strftime', '$ERRNO';

There's no C<:all> tag, as not sure if it would best import just the new
funcs, or get everything from C<POSIX>.

=head1 FUNCTIONS

=over 4

=item C<$str = POSIX::Wide::localeconv ($format, ...)>

Return a hashref of locale information

    { decimal_point => ...,
      grouping      => ...
    }

Text field values are wide chars.  Non-text fields like C<grouping> and
number fields like C<frac_digits> are unchanged.

=item C<$str = POSIX::Wide::perror ($message)>

Print C<$message> and errno string C<$!> to C<STDERR>, with wide-chars for
the errno string.

    $message: $!\n

=item C<$str = POSIX::Wide::strerror ($errno)>

Return a descriptive string for a given C<$errno> number.

=item C<$str = POSIX::Wide::strftime ($format, $sec, $min, $hour, $mday, $mon, $year, ...)>

Format a string of date-time parts.  C<$format> and the return are wide-char
strings.

The current implementation passes ASCII parts of C<$format>, including the
"%" formatting directives, to strftime().  This means C<$format> can include
characters which might not exist in the locale charset.

=item C<($std_name, $dst_name) = POSIX::Wide::tzname ()>

Return the C<tzname[]> strings for standard time and daylight savings time
as wide char strings.

The POSIX spec is that these should only have characters from the "portable
character set", so normally the plain bytes of C<POSIX::tzname> should
suffice.  C<POSIX::Wide::tzname> can be used if someone might be creative in
their C<TZ> setting.

=back

=head1 VARIABLES

=over 4

=item C<$num = $POSIX::Wide::ERRNO + 0>

=item C<$str = "$POSIX::Wide::ERRNO">

A magic dual string+number variable like C<$!> but giving the string form as
wide-chars (see L<perlvar/$ERRNO>).

=item C<$num = $POSIX::Wide::EXTENDED_OS_ERROR + 0>

=item C<$str = "$POSIX::Wide::EXTENDED_OS_ERROR">

A magic dual string+number variable like C<$^E> but giving the string form
as wide-chars (see L<perlvar/$EXTENDED_OS_ERROR>).

The current implementation assumes C<$^E> is locale bytes (if it isn't
already wide).  This is true of POSIX but not absolutely sure for MacOS and
VMS.

=back

=head1 CONFIGURATION

=over 4

=item C<@LOCALECONV_STRING_FIELDS>

An array of the field names from C<localeconv()> which are converted to
wide-char strings, if the fields exist.  Currently these are

    decimal_point
    thousands_sep
    int_curr_symbol
    currency_symbol
    mon_decimal_point
    mon_thousands_sep
    positive_sign
    negative_sign

The C<POSIX> module omits from its return any fields which are empty
strings, and apparently there's no C<mon_thousands_sep> in some early DJGPP.

=back

=head1 WITH C<Errno::AnyString>

Custom error strings set into C<$!> by L<Errno::AnyString> work with all of
C<strerror()>, C<perror()> and C<$ERRNO> above.  Custom error numbers
registered with C<Errno::AnyString> can be turned into strings with
C<strerror()> too.

Any non-ASCII in such a string should be locale bytes the same as normal
C<$!> strings.  If C<$!> is already a wide character string then
<POSIX::Wide> will return it unchanged.  Whether wide strings from C<$!>
would well with other code is another matter.

=head1 OTHER WAYS TO DO IT

C<Glib::Utils> C<strerror()> gives a wide char string similar to
C<POSIX::Wide::strerror()> above if you're using Glib.

Glib also has a C<g_date_strftime()>, which is not wrapped as of Perl-Glib
1.220, giving a utf8 C<strftime()> similar to C<POSIX::Wide::strftime()>
above, but only for a date, not a date and time together.

=head1 SEE ALSO

L<POSIX>, L<Encode::Locale>, L<Glib::Utils> (which includes a wide
C<strsig()>)

=head1 HOME PAGE

L<http://user42.tuxfamily.org/posix-wide/index.html>

=head1 LICENSE

POSIX-Wide is Copyright 2008, 2009, 2010, 2011, 2014 Kevin Ryde

POSIX-Wide is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

POSIX-Wide is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
POSIX-Wide.  If not, see L<http://www.gnu.org/licenses/>.

=cut
