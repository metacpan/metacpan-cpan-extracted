package Sort::filevercmp;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.001';

our @EXPORT = 'filevercmp';
our @EXPORT_OK = 'fileversort';

sub filevercmp ($$) { _filevercmp(_parse($_[0]), _parse($_[1])) }

sub fileversort {
  my @parsed = map { _parse($_) } @_;
  return @_[sort { _filevercmp($parsed[$a], $parsed[$b]) } 0..$#_];
}

# Parse strings into metadata
sub _parse {
  my ($name) = @_;
  $name = '' unless defined $name;
  
  return { name => $name, special => 1 } if $name eq '' or $name eq '.' or $name eq '..';
  
  my %meta;
  $meta{name} = $name;
  
  $meta{hidden} = $name =~ s/^\.//;
  
  my (@prefix_parts, @all_parts);
  
  # Parse name into pairs of non-digit and digit parts
  my $with_suffix = $name;
  while ($with_suffix =~ s/^([^0-9]*)([0-9]*)// and (length $1 or length $2)) {
    push @all_parts, $1, $2;
  }
  
  $meta{all_parts} = \@all_parts;
  
  # Parse name into pairs without suffix
  my $prefix = $name;
  if ($prefix =~ s/(?:\.[A-Za-z~][A-Za-z0-9~]*)*$//) {
    my $without_suffix = $prefix;
    while ($without_suffix =~ s/^([^0-9]*)([0-9]*)// and (length $1 or length $2)) {
      push @prefix_parts, $1, $2;
    }
  } else {
    @prefix_parts = @all_parts;
  }
  
  $meta{prefix} = $prefix;
  $meta{prefix_parts} = \@prefix_parts;
  
  return \%meta;
}

# tilde sorts first even before end of string, then letters, then everything else
sub _lexorder {
  my ($char) = @_;
  return 0 if $char =~ m/\A[0-9]\z/;
  return ord $char if $char =~ m/\A[a-zA-Z]\z/;
  return -1 if $char eq '~';
  return ord($char) + ord('z') + 1;
}

sub _lexcmp {
  my ($alex, $blex) = @_;
  my @achars = split '', $alex;
  my @bchars = split '', $blex;
  while (@achars or @bchars) {
    my ($achar, $bchar) = (shift(@achars), shift(@bchars));
    my $aord = defined $achar ? _lexorder($achar) : 0;
    my $bord = defined $bchar ? _lexorder($bchar) : 0;
    my $charcmp = $aord <=> $bord;
    return $charcmp if $charcmp;
  }
  return 0;
}

# Based on verrevcmp() from GNU filevercmp
sub _verrevcmp {
  my @aparts = @{$_[0] || []};
  my @bparts = @{$_[1] || []};
  while (@aparts or @bparts) {
    # Lexical part
    my ($alex, $blex) = (shift(@aparts), shift(@bparts));
    $alex = '' unless defined $alex;
    $blex = '' unless defined $blex;
    my $lexcmp = _lexcmp($alex, $blex);
    return $lexcmp if $lexcmp;
    
    # Numeric part
    my ($anum, $bnum) = (shift(@aparts), shift(@bparts));
    $anum = 0 unless defined $anum and length $anum;
    $bnum = 0 unless defined $bnum and length $bnum;
    my $numcmp = $anum <=> $bnum;
    return $numcmp if $numcmp;
  }
  return 0;
}

# Based on filevercmp() from GNU filevercmp
sub _filevercmp {
  my ($first, $second) = @_;
  return 0 if $first->{name} eq $second->{name};
  
  # Special files go first (empty string, ., or ..)
  return $first->{name} cmp $second->{name}
    if $first->{special} and $second->{special};
  return -1 if $first->{special};
  return 1 if $second->{special};
  
  # Hidden files go before unhidden
  return -1 if $first->{hidden} and !$second->{hidden};
  return 1 if !$first->{hidden} and $second->{hidden};
  
  # Compare parts, including suffixes only if prefixes are equal
  if ($first->{prefix} eq $second->{prefix}) {
    return _verrevcmp($first->{all_parts}, $second->{all_parts});
  } else {
    return _verrevcmp($first->{prefix_parts}, $second->{prefix_parts});
  }
}

1;

=head1 NAME

Sort::filevercmp - Sort version strings as in GNU filevercmp

=head1 SYNOPSIS

  use Sort::filevercmp;
  my @sorted = sort filevercmp 'foo-bar-1.2a.tar.gz', 'foo-bar-1.10.zip';
  my $cmp = filevercmp 'a1b2c3.tar', 'a1b2c3.tar~';
  say $cmp ? $cmp < 0 ? 'First name' : 'Second name' : 'Names are equal';
  
  # Pre-parse list for faster sorting
  use Sort::filevercmp 'fileversort';
  my @sorted = fileversort @filenames;

=head1 DESCRIPTION

Perl implementation of the C<filevercmp> function from
L<gnulib|https://www.gnu.org/software/gnulib/>. C<filevercmp> is used by the
L<sort(1)> (C<-V> option) and L<ls(1)> (C<-v> option) GNU coreutils commands
for "natural" sorting of strings (usually filenames) containing mixed version
numbers and filename suffixes.

=head1 FUNCTIONS

=head2 filevercmp

  my $cmp = filevercmp $string1, $string2;
  my @sorted = sort filevercmp @strings;

Takes two strings and returns -1 if the first string sorts first, 1 if the
second string sorts first, or 0 if the strings sort equivalently. Can be passed
to L<sort|perlfunc/"sort"> directly as a comparison function. Exported by
default.

=head2 fileversort

  my @sorted = fileversort @strings;

Takes a list of strings and sorts them according to L</"filevercmp">. The
strings are pre-parsed so it may be more efficient than using L</"filevercmp">
as a sort comparison function. Exported by request.

=head1 ALGORITHM

The sort algorithm works roughly as follows:

=over

=item 1

Empty strings, C<.>, and C<..> go first

=item 2

Hidden files (strings beginning with C<.>) go next, and are sorted among
themselves according to the remaining rules

=item 3

Each string is split into sequences of non-digit characters and digit (C<0-9>)
characters, ignoring any filename suffix as matched by the regex
C</(?:\.[A-Za-z~][A-Za-z0-9~]*)*$/>, unless the strings to be compared are
equal with the suffixes removed.

=item 4

The first non-digit sequence of the first string is compared lexically with
that of the second string, with letters (C<a-zA-Z>) sorting first and other
characters sorting after, ordered by character ordinals. The tilde (C<~>)
character sorts before all other characters, even the end of the sequence.
Continue if the non-digit sequences are lexically equal.

=item 5

The first digit sequence of the first string is compared numerically with that
of the second string, ignoring leading zeroes. Continue if the digit sequences
are numerically equal.

=item 6

Repeat steps 4 and 5 with the remaining sequences.

=back

=head1 CAVEATS

This sort algorithm ignores the current locale, and has unique rules for
lexically sorting the non-digit components of the strings, designed for sorting
filenames. There are better options for general version string sorting; see
L</"SEE ALSO">.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

=over

=item *

L<version> - for comparing Perl version strings

=item *

L<Sort::Versions> - for comparing standard version strings

=item *

L<Sort::Naturally> - locale-sensitive natural sorting of mixed strings

=back
