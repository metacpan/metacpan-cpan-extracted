# -*- Perl -*-
#
# Pitch number roles using the American Standard Pitch Notation (ASPN)
# format, or something probably close enough.
#
# Run perldoc(1) on this file for additional documentation.

package Music::PitchNum::ASPN;

use 5.010000;
use Moo::Role;
use POSIX qw/floor/;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '0.09';

my %NOTE2NUM = (
  C => 0,
  D => 2,
  E => 4,
  F => 5,
  G => 7,
  A => 9,
  B => 11,
);

my %NUM2NOTE = (
  0  => 'C',
  1  => 'C#',
  2  => 'D',
  3  => 'D#',
  4  => 'E',
  5  => 'F',
  6  => 'F#',
  7  => 'G',
  8  => 'G#',
  9  => 'A',
  10 => 'A#',
  11 => 'B',
);

##############################################################################
#
# METHODS

sub pitchname {
  my ( $self, $number, %params ) = @_;
  die "need a number for pitchname\n" if !looks_like_number $number;

  $params{ignore_octave} //= 0;

  return $NUM2NOTE{ $number % 12 }
    . ( $params{ignore_octave} ? '' : ( floor( $number / 12 ) - 1 ) );
}

sub pitchnum {
  my ( $self, $name ) = @_;

  # already a pitch number, but nix the decimal foo
  return int $name if looks_like_number $name;

  my $pitchnum;

  # Only sharps, as the Young article only has those. Use the main
  # module for looser pitch name matching.
  if ( $name =~ m/ (?<note>[A-G]) (?<chrome>[#])? (?<octave>-?[0-9]{1,2}) /x ) {
    $pitchnum = 12 * ( $+{octave} + 1 ) + $NOTE2NUM{ $+{note} };
    $pitchnum++ if defined $+{chrome};
  }

  return $pitchnum;
}

1;
__END__

##############################################################################
#
# DOCS

=head1 NAME

Music::PitchNum::ASPN - note name and pitch number roles for ASPN notation

=head1 SYNOPSIS

  package MyCleverMod;
  use Moo;
  with('Music::PitchNum::ASPN');
  ...

Then elsewhere:

  use MyCleverMod;
  my $x = MyCleverMod->new;

  $x->pitchname(69);    # A4
  $x->pitchname(70);    # A#4
  $x->pitchnum('A');    # 69
  $x->pitchnum('A#');   # 70

  $x->pitchname(69, ignore_octave => 1); # A

=head1 DESCRIPTION

A L<Music::PitchNum> implementation specifically for the American
Standard Pitch Notation (ASPN), also known as the scientific notation.

This module is expected to be used as a Role from some other module;
L<Moo::Role> may be informative.

=head1 METHODS

=over 4

=item B<pitchname> I<pitchnumber>

Returns the pitch name for the given integer, though will throw an
exception if passed something that is not a number.

This method accepts an optional I<ignore_octave> parameter that if true
will strip the octave information from the pitch name.

=item B<pitchnum> I<pitchname>

Returns the pitch number for the given ASPN note name, or C<undef> if
the note could not be parsed. Only the note names C<A-G> (and not the
lower case forms), optional C<#> for sharp, and the octave number are
parsed by this module; other forms will (or should) not match.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-music-pitchnum at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-PitchNum>.

Patches might best be applied towards:

L<https://github.com/thrig/Music-PitchNum>

=head2 Known Issues

None known for the ASPN notation support, though this is a very limited
format with only one accidental style (a single C<#> for sharp) and a
mandatory octave number.

=head1 SEE ALSO

L<Music::PitchNum>

=head2 REFERENCES

Young, R. W. (1939). "Terminology for Logarithmic Frequency Units". The Journal
of the Acoustical Society of America 11 (1): 134-000.
Bibcode:1939ASAJ...11..134Y. doi:10.1121/1.1916017.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
