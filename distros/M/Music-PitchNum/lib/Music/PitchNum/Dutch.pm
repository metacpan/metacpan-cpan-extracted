# -*- Perl -*-
#
# Pitch name conversion compatible with Lilypond default or "\language
# nederlands" (the default!) is set. See instead German.pm of this
# distribution if you instead need "\language deutsch" support.
#
# Run perldoc(1) on this file for additional documentation.

package Music::PitchNum::Dutch;

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
  0  => 'c',
  1  => 'des',
  2  => 'd',
  3  => 'ees',
  4  => 'e',
  5  => 'f',
  6  => 'ges',
  7  => 'g',
  8  => 'aes',
  9  => 'a',
  10 => 'bes',
  11 => 'b',
);

##############################################################################
#
# METHODS

sub pitchname {
  my ( $self, $number, %params ) = @_;
  die "need a number for pitchname\n" if !looks_like_number $number;

  $params{ignore_octave} //= 0;

  my $note = $NUM2NOTE{ $number % 12 };

  if ( !$params{ignore_octave} ) {
    my $octave = floor( $number / 12 ) - 1;
    if ( $octave > 3 ) {
      $note .= (q{'}) x ( $octave - 3 );
    } elsif ( $octave < 3 ) {
      $note .= (q{,}) x ( 3 - $octave );
    }
  }

  return $note;
}

sub pitchnum {
  my ( $self, $name ) = @_;

  # already a pitch number, but nix the decimal foo
  return int $name if looks_like_number $name;

  my $pitchnum;

  # octave indication only follows accidental, accidental only after note
  # plus complication for "as", "ases", "es", "eses" special cases
  if (
    $name =~ m/ (?<note> [A-Ga-g] )
       (?<chrome> es(?:es)? | is(?:is)? | (?<=[AEae]) s(?:es)? )?
       (?<octave> [,]{1,10}|[']{1,10} )?
       /x
    ) {
    my $octave = $+{octave};
    my $chrome = $+{chrome};
    my $note   = $+{note};

    $pitchnum = $NOTE2NUM{ uc $note } + 12 * 4;

    if ( defined $octave ) {
      $pitchnum += 12 * length($octave) * ( $octave =~ m/[,]/ ? -1 : 1 );
    }

    if ( defined $chrome ) {
      if ( $chrome =~ m/^s/ ) {    # as/ases klugery
        $chrome = "e$chrome";
      }
      $chrome =~ tr/s//d;
      $pitchnum += length($chrome) * ( $chrome =~ m/e/ ? -1 : 1 );
    }
  }

  return $pitchnum;
}

1;
__END__

##############################################################################
#
# DOCS

=head1 NAME

Music::PitchNum::Dutch - note name and pitch number roles for lilypond

=head1 SYNOPSIS

  package MyCleverOckeghem;
  use Moo;
  with('Music::PitchNum::Dutch');
  ...

Then elsewhere:

  use MyCleverOckeghem;
  my $x = MyCleverOckeghem->new;

  $x->pitchname(72);      # c''
  $x->pitchname(71);      # b'
  $x->pitchname(70);      # bes'
  $x->pitchname(69);      # a'

  $x->pitchnum(q{aes'});  # 68
  $x->pitchnum(q{g'});    # 67
  $x->pitchnum(q{b'});    # 70
  $x->pitchnum(q{a'});    # 69

  $x->pitchname(72, ignore_octave => 1); # c

=head1 DESCRIPTION

A L<Music::PitchNum> implementation for the default lilypond note name
syntax ("nederlands").

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

Returns the pitch number for the given note name, or C<undef> if the
note could not be parsed. Note that the parser is quite permissive, see
L</"Known Issues">.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-music-pitchnum at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-PitchNum>.

Patches might best be applied towards:

L<https://github.com/thrig/Music-PitchNum>

=head2 Known Issues

The parser is too lax, in that it will parse invalid input such as
C<cses'''> as pitch number 48 on account of the leading C<c>.

=head1 SEE ALSO

L<Music::PitchNum>, C<ly-fu> of L<App::MusicTools>

=head2 REFERENCES

=over 4

=item *

L<http://lilypond.org/doc/v2.18/Documentation/web/manuals> - LilyPond Notation
Reference, "Note names in other languages"

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
