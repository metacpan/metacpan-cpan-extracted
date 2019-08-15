package Music::Cadence;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Provide musical cadence chords

our $VERSION = '0.0300';

use Moo;
use Music::Chord::Note;
use Music::Scales;
use Music::ToRoman;

use strictures 2;
use namespace::clean;


sub cadence {
    my ( $self, %args ) = @_;

    my $cadence = [];

    $args{key}       ||= 'C';
    $args{scale}     ||= 'major';
    $args{type}      ||= 'perfect';
    $args{octave}    //= 0;
    $args{leading}   ||= 1;
    $args{variation} ||= 1;

    my @scale = get_scale_notes( $args{key}, $args{scale} );

    my $mcn = Music::Chord::Note->new;

    my $mtr = Music::ToRoman->new(
        scale_note => $args{key},
        scale_name => $args{scale},
        chords     => 0,
    );

    if ( $args{type} eq 'perfect' ) {
        $cadence = _generate_chord( $args{scale}, $scale[4], $args{octave}, $mtr, $mcn, $cadence );
        $cadence = _generate_chord( $args{scale}, $scale[0], $args{octave}, $mtr, $mcn, $cadence );
    }
    elsif ( $args{type} eq 'plagal' ) {
        $cadence = _generate_chord( $args{scale}, $scale[3], $args{octave}, $mtr, $mcn, $cadence );
        $cadence = _generate_chord( $args{scale}, $scale[0], $args{octave}, $mtr, $mcn, $cadence );
    }
    elsif ( $args{type} eq 'half' ) {
        $cadence = _generate_chord( $args{scale}, $scale[ $args{leading} - 1 ], $args{octave}, $mtr, $mcn, $cadence );
        $cadence = _generate_chord( $args{scale}, $scale[4], $args{octave}, $mtr, $mcn, $cadence );
    }
    elsif ( $args{type} eq 'deceptive' ) {
        $cadence = _generate_chord( $args{scale}, $scale[4], $args{octave}, $mtr, $mcn, $cadence );
        my $note = $args{variation} == 1 ? $scale[5] : $scale[3];
        $cadence = _generate_chord( $args{scale}, $note, $args{octave}, $mtr, $mcn, $cadence );
    }

    return $cadence;
}

sub _generate_chord {
    my ( $scale, $note, $octave, $mtr, $mcn, $cadence ) = @_;

    my %diminished = (
        ionian     => 'vii',
        major      => 'vii',
        dorian     => 'vi',
        phrygian   => 'v',
        lydian     => 'iv',
        mixolydian => 'iii',
        aeolian    => 'ii',
        minor      => 'ii',
        locrian    => 'i',
    );

    my $roman = $mtr->parse($note);
    my $type  = $roman =~ /^$diminished{$scale}$/ ? 'dim' : $roman =~ /^[a-z]/ ? 'm' : '';

    my @notes = $mcn->chord( $note . $type );

    @notes = map { $_ . $octave } @notes
        if $octave;

    push @$cadence, \@notes;

    return $cadence;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Cadence - Provide musical cadence chords

=head1 VERSION

version 0.0300

=head1 SYNOPSIS

  use Music::Cadence;

  my $mc = Music::Cadence->new;

  my $chords = $mc->cadence(
    key    => 'C',
    scale  => 'major',
    type   => 'perfect',
    octave => 4,
  ); # [['G4','B4','D4'], ['C4','E4','G4']]

  $chords = $mc->cadence(
    key     => 'C',
    scale   => 'major',
    type    => 'half',
    leading => 2,
    octave  => 0,
  ); # [['D','F','A'], ['G','B','D']]

=head1 DESCRIPTION

C<Music::Cadence> provides musical cadence chords.

* This module is a very naive implementation of the actual theory.
YMMV.

=head1 ATTRIBUTES

None.

=head1 METHODS

=head2 new

  $mc = Music::Cadence->new;

Create a new C<Music::Cadence> object.

=head2 cadence

  $chords = $mc->cadence;  # Use defaults

  $chords = $mc->cadence(
    key       => $key,        # Default: C
    scale     => $scale,      # Default: major
    type      => $type,       # Default: perfect
    leading   => $leading,    # Default: 1
    octave    => $octave,     # Default: 0
    variation => $variation,  # Default: 1
  );

Return an array reference of the chords of the cadence B<type> (and
B<leading> chord when B<type> is C<half>) based on the given B<key>
and B<scale> name.

The B<octave> is optional and if given, should be a number greater
than or equal to zero.

The B<variation> applies to the C<deceptive> cadence and determines
the final chord.  If given as C<1>, the C<vi> chord is used.  If given
as C<2>, the C<IV> chord is used.

Supported cadences are:

  perfect
  half
  plagal
  deceptive

Supported scales are:

  ionian / major
  dorian
  phrygian
  lydian
  mixolydian
  aeolian / minor
  locrian

The B<leading> chord is a number for each diatonic scale chord to use
for the first C<half> cadence chord.  So for the key of C<C major>
this is:

  CM: 1
  Dm: 2
  Em: 3
  FM: 4
  GM: 5
  Am: 6
  Bo: 7

=head1 SEE ALSO

The F<eg/cadence> and F<t/01-methods.t> files in this distribution.

L<Moo>

L<Music::Chord::Note>

L<Music::Scales>

L<Music::ToRoman>

L<https://en.wikipedia.org/wiki/Cadence>

L<https://www.musictheoryacademy.com/how-to-read-sheet-music/cadences/>

=head1 TO DO

Evaded cadence

Imperfect cadence

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
