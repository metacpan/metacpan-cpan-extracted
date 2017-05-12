# -*- Perl -*-
#
# Musical note name and pitch number utility roles, mostly motivated by
# not wanting to drag in my huge and crufty Music::LilyPondUtil module
# just to figure out what pitch number fis'' is, and providing for such
# as a Role. Also an excuse for me to learn more about Roles as part of
# a Moo rewrite of various modules.
#
# Run perldoc(1) on this file for additional documentation.

package Music::PitchNum;

use 5.010000;
use Moo::Role;
use POSIX qw/floor/;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '0.09';

# These (or an ignore_octave attribute) did not fly as attributes, as
# then Music::Canon and other modules started barfing with "Constructor
# for Music::Canon has been inlined and cannot be updated" from an
# completely undocumented Method::Generate::Constructor module.
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

  my ( $octave, $note, $chrome );
SIRLEXALOT: {
    last SIRLEXALOT
      if $name =~ m/\G \z /cgx
      or ( defined $octave and defined $note and defined $chrome );

    # Leading ,C as allowed by Helmholtz
    if ( !defined $octave and $name =~ m/ \G ( [,]{1,10} ) /cgx ) {
      $octave = $1;
      redo SIRLEXALOT;
    }

    # Simple note name support; insensitive, so supporting ABC notation not
    # possible here; see ::German for H support, as this just matches A through
    # G, and does not match solfege or the like.
    if ( !defined $note
      and $name =~
      m/ \G (?: (?<note>[A-G])(?<multi>\k<note>{1,10}) | (?<note>[A-Ga-g])) /cgx ) {
      $note = $NOTE2NUM{ uc $+{note} };
      # Optional "English multiple C notation" where C, is written CC (only for
      # upper case as need to sometimes match "f" as "flat" as an accidental).
      if ( defined $+{multi} and !defined $octave ) {
        $octave = (',') x length $+{multi};
      }
      redo SIRLEXALOT;
    }

    if ( defined $note
      and !defined $octave ) {

      if ( $name =~ m/ \G ( [+-]?[0-9]{1,2} ) /cgx ) {
        # ASPN octave number (hard: C4 is in no way relative to anything)
        $octave = $1;
        redo SIRLEXALOT;
      }
      if ( $name =~ m/ \G ( [,']{1,10} ) /cgx ) {
        # Post-note a''' or b,, octave indications (soft; might be relative
        # to something).
        $octave = $1;
        redo SIRLEXALOT;
      }
    }

    # Accidental (NOTE there is no microtonal support, e.g. lilypond beh);
    # flat, sharp, doubleflat, doublesharp in various forms, mostly taken from
    # MIDI::Simple and the "Note names in other languages" section of the
    # lilypond notation documentation.
    if ( defined $note and !defined $chrome ) {
      my @howmany;
      if ( @howmany = $name =~ m/ \G (ess|es|flat|[bf]) /cgx ) {
        $chrome = -1 * @howmany;
        redo SIRLEXALOT;
      } elsif ( @howmany = $name =~ m/ \G (iss|is|sharp|[#dks]) /cgx ) {
        $chrome = @howmany;
        redo SIRLEXALOT;
      }
    }

    # nothing matched; nom something and try again at new position
    if ( $name =~ m/ \G (?: \s+ | . ) /cgsx ) {
      redo SIRLEXALOT;
    }
  }
  return if !defined $note;

  my $pitchnum;

  if ( defined $octave and looks_like_number $octave ) {
    # "hard" octave
    $pitchnum = int( 12 * $octave + 12 + $note );

  } else {
    # calculate the "hard" octave given the context...

    $octave //= '';    # equivalent to C3 under ASPN, if not relative
    my $sign = ( $octave =~ m/,/ ) ? -1 : 1;
    $octave = int( $sign * length $octave );

    # TODO support $relative as additional argument, but that's extra
    # complication (and too much work for just getting the module out the
    # door), as then must deal with which direction the tritone goes (see
    # Music::LilyPondUtil).
    #if ( defined $relative ) {
    #  ...
    $pitchnum = int( 12 * $octave + 48 + $note );
  }

  $pitchnum += $chrome if defined $chrome;

  return $pitchnum;
}

1;
__END__

##############################################################################
#
# DOCS

=head1 NAME

Music::PitchNum - note name and pitch number utility roles

=head1 SYNOPSIS

  package MyCleverModule;
  use Moo;
  with('Music::PitchNum');
  ...

Then elsewhere:

  use MyCleverModule;
  my $x = MyCleverModule->new;

  $x->pitchname(69);    # A4
  $x->pitchnum('A4');   # 69

  $x->pitchname(69, ignore_octave => 1);    # A

Or, to dynamically select what module is used at object construction
time, consider:

  package MyCleverModule;
  use Moo;

  sub BUILD {
    my ( $self, $param ) = @_;
    with( exists $param->{pitchstyle} ?
      $param->{pitchstyle} : 'Music::PitchNum' );
  }

  package main;

  my $x = MyCleverModule->new( pitchstyle => 'Music::PitchNum::ABC' );
  print $x->pitchname(69);

See also the C<eg/> and C<t/> directories of the distribution of this
module for example code, or look on metacpan for modules that depend on
this module.

=head1 DESCRIPTION

=over 4

"One need but glance at the various notations for a single tone to be
convinced that there is a sorrowful lack of agreement in usage."
-- R. W. Young. "Terminology for Logarithmic Frequency Units"

=back

This module provides utility music pitch name and number routines; that
is, an easy way to obtain pitch numbers from various pitch name formats
(Helmholtz, or in particular what C<lilypond> uses, what L<MIDI::Simple>
accepts, and the American Standard Pitch Notation (ASPN)). The resulting
pitch numbers are integers (as used by the MIDI standard), though this
module does not restrict the range of the pitch numbers as MIDI does
(support for black hole pressure waves was a design goal).

This module is somewhat catholic in what it accepts; alternatives are
the variety of sub-modules that support only the named notation system;
the L<Music::PitchNum::German> implementation, in particular, is Helmholtz-
based, though with "H" representing B natural and "B" as B flat as is
necessary for BACH motif support. Not supported by this particular
module include the ABC notation, solfege note names, and various other
International formats. There is also no microtonal support, and the
traditional Western 12-tone chromatic scale is used as the basis for the
resulting pitch numbers. Also, the parsing of the notes is limited to
just the note name, octave indication, and accidental, and in no way
supports rhythmic elements or the like.

This module is expected to be used as a Role from some other module;
L<Moo::Role> may be informative.

=head1 METHODS

=over 4

=item B<pitchname> I<pitchnumber>

Returns a pitch name for the pitch number provided in the ASPN format.
Will C<die> if passed something that does not look like a number.

  ->pitchname(59);       # B3
  ->pitchname(60);       # C4
  ->pitchname(61);       # C#4

This method accepts an optional I<ignore_octave> parameter that if true
will strip the octave information from the pitch name.

  ->pitchname(59, ignore_octave => 1); # B

=item B<pitchnum> I<pitchname>

Returns the pitch number for the given pitch, or C<undef> if nothing was
parsed from the input. Anything that already looks like a number will be
returned by way of a trip through the C<int> function.

  ->pitchnum(q{D4b});    # 61
  ->pitchnum(q{Db4});    # 61
  ->pitchnum(q{cis'});   # 61
  ->pitchnum(q{bisis});  # 61

The accidentals supported are quite varied, and may be doubled to
produce the corresponding doubleflat or doublesharp. The allowed list
includes the flats C<b>, C<es>, C<ess>, C<f>, or C<flat> or the sharps
C<s>, C<is>, C<iss>, C<sharp>, C<#>, C<d>, or C<k>. These can be mixed
with the note names A through G, and either the ASPN octave number (4
for middle C) or the Helmholtz-derived C<,> or C<'> indicators as used
in C<lilypond>.

English multiple C notation is supported with upper case note names for
the octaves below the C below middle C:

  ->pitchnum('C');       # 48
  ->pitchnum('CC');      # 36
  ->pitchnum('CCC');     # 24

In general, the first matching element wins, so if something silly like
C<CCC''4> were specified, the English match happens first (as that
occurs while matching the note name) and then the other octave
indicators are ignored. Other implementations may desire a tighter match
or to throw errors on such absurdities.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-music-pitchnum at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-PitchNum>.

Patches might best be applied towards:

L<https://github.com/thrig/Music-PitchNum>

=head2 Known Issues

Matching the fancy flat symbol (or the double-flat, or double-sharp) is
not yet supported. Use C<##> or C<b> or C<bb> for those in the
meantime, or the various other ASCII forms allowed. Doubtless other
things besides.

=head1 SEE ALSO

How the resulting pitch names or numbers are used is of no concern to
this module, though see L<MIDI::Simple> or L<Music::Scala> or
L<Music::LilyPondUtil> for means to convert the numbers into MIDI
events, frequencies, or a form suitable to pass to lilypond.

L<Moo> and L<Moo::Role> would be good reads for programmers using
this module.

L<Music::PitchNum::ABC>, L<Music::PitchNum::ASPN>,
L<Music::PitchNum::Dutch>, L<Music::PitchNum::German>

=head2 REFERENCES

=over 4

=item *

L<http://lilypond.org/doc/v2.18/Documentation/web/manuals> - LilyPond Notation
Reference, "Note names in other languages"

=item *

L<http://www.dolmetsch.com/musictheory1.htm#helmholtz>

=item *

Young, R. W. (1939). "Terminology for Logarithmic Frequency Units". The Journal
of the Acoustical Society of America 11 (1): 134-000.
Bibcode:1939ASAJ...11..134Y. doi:10.1121/1.1916017.

=item *

L<https://xkcd.com/927/>

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
