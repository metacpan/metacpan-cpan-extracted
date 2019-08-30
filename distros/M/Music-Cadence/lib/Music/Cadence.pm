package Music::Cadence;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Provide musical cadence chords

our $VERSION = '0.0900';

use Moo;
use Music::Chord::Note;
use Music::Chord::Positions;
use Music::Note;
use Music::Scales;
use Music::ToRoman;

use strictures 2;
use namespace::clean;


has key => (
    is      => 'ro',
    default => sub { 'C' },
);


has scale => (
    is      => 'ro',
    default => sub { 'major' },
);


has octave => (
    is      => 'ro',
    default => sub { 0 },
);


has format => (
    is      => 'ro',
    default => sub { 'isobase' },
);


sub cadence {
    my ( $self, %args ) = @_;

    my $cadence = [];

    $args{key}       ||= $self->key;
    $args{scale}     ||= $self->scale;
    $args{octave}    //= $self->octave;
    $args{type}      ||= 'perfect';
    $args{leading}   ||= 1;
    $args{variation} ||= 1;
    $args{inversion} //= 0;

    die 'unknown leader' if $args{leading} < 1 or $args{leading} > 7;

    my @scale = get_scale_notes( $args{key}, $args{scale} );

    my $mcn = Music::Chord::Note->new;

    my $mtr = Music::ToRoman->new(
        scale_note => $args{key},
        scale_name => $args{scale},
        chords     => 0,
    );

    if ( $args{type} eq 'perfect' ) {
        my $chord = $self->_generate_chord( $args{scale}, $scale[4], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $args{scale}, $scale[0], $args{octave}, $mtr, $mcn );
        my $top = $chord->[0];
        if ( $self->format eq 'midinum' ) {
            $top += 12;
        }
        else {
            if ( $top =~ /^(.+?)(\d+)$/ ) {
                my $note   = $1;
                my $octave = $2;
                $top = $note . ++$octave;
            }
        }
        push @$chord, $top;
        push @$cadence, $chord;
    }
    elsif ( $args{type} eq 'imperfect' && $args{inversion} ) {
        my $chord = $self->_generate_chord( $args{scale}, $scale[4], $args{octave}, $mtr, $mcn );
        $chord = $self->_invert_chord( $chord, $args{inversion}->{1}, $args{octave} )
            if $args{inversion}->{1};
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $args{scale}, $scale[0], $args{octave}, $mtr, $mcn );
        $chord = $self->_invert_chord( $chord, $args{inversion}->{2}, $args{octave} )
            if $args{inversion}->{2};
        push @$cadence, $chord;
    }
    elsif ( $args{type} eq 'imperfect' ) {
        my $note = $args{variation} == 1 ? $scale[4] : $scale[6];
        my $chord = $self->_generate_chord( $args{scale}, $note, $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $args{scale}, $scale[0], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;
    }
    elsif ( $args{type} eq 'plagal' ) {
        my $chord = $self->_generate_chord( $args{scale}, $scale[3], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $args{scale}, $scale[0], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;
    }
    elsif ( $args{type} eq 'half' ) {
        my $chord = $self->_generate_chord( $args{scale}, $scale[ $args{leading} - 1 ], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $args{scale}, $scale[4], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;
    }
    elsif ( $args{type} eq 'deceptive' ) {
        my $chord = $self->_generate_chord( $args{scale}, $scale[4], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;

        my $note = $args{variation} == 1 ? $scale[5] : $scale[3];
        $chord = $self->_generate_chord( $args{scale}, $note, $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;
    }
    else {
        die 'unknown cadence';
    }

    return $cadence;
}

sub _invert_chord {
    my ( $self, $chord, $inversion, $octave ) = @_;

    my $mcp = Music::Chord::Positions->new;

    if ( $self->format eq 'midinum' ) {
        $chord = $mcp->chord_inv( $chord, inv_num => $inversion );
    }
    else {
        # Perform these gymnastics to convert from named notes to inverted named notes
        my $notes = $chord;

        $notes = [ grep { s/\d+// } @$notes ]
            if $octave;

        my @pitches = map { Music::Note->new( $_ . -1, 'ISO' )->format('midinum') } @$notes;

        my $inverted = $mcp->chord_inv( \@pitches, inv_num => $inversion );

        $notes = [ map { Music::Note->new( $_, 'midinum' )->format('isobase') } @$inverted ];

        $notes = [ map { $_ . $octave } @$notes ]
            if $octave;

        $chord = $notes;
    }

    return $chord;
}

sub _generate_chord {
    my ( $self, $scale, $note, $octave, $mtr, $mcn ) = @_;

    # Know what chords should be diminished
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

    die 'unknown scale' unless exists $diminished{$scale};

    # Figure out if the chord is diminished, minor, or major
    my $roman = $mtr->parse($note);
    my $type  = $roman =~ /^$diminished{$scale}$/ ? 'dim' : $roman =~ /^[a-z]/ ? 'm' : '';

    # Generate the chord notes
    my @notes = $mcn->chord( $note . $type );

    if ( $self->format eq 'midi' ) {
        for ( @notes ) {
            s/#/s/;
            s/b/f/;
        }
    }
    elsif ( $self->format eq 'midinum' ) {
        @notes = map { Music::Note->new( $_ . $octave, 'ISO' )->format('midinum') } @notes;
    }
    elsif ( $self->format ne 'isobase' ) {
        die 'unknown format';
    }

    # Append the octave if requested
    @notes = map { $_ . $octave } @notes
        if $octave && $self->format ne 'midinum';

    return \@notes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Cadence - Provide musical cadence chords

=head1 VERSION

version 0.0900

=head1 SYNOPSIS

  use Music::Cadence;

  my $mc = Music::Cadence->new;

  my $chords = $mc->cadence;
  # [['G','B','D'], ['C','E','G','C']]

  $mc = Music::Cadence->new( octave => 4 );

  $chords = $mc->cadence;
  # [['G4','B4','D4'], ['C4','E4','G4','C5']]

  $chords = $mc->cadence(
    type    => 'half',
    leading => 2,
    octave  => 0,
  ); # [['D','F','A'], ['G','B','D']]

  $mc = Music::Cadence->new(
    key    => 'C#',
    octave => 5,
  );

  $chords = $mc->cadence;
  # [['G#5','C5','D#5'], ['C#5','F5','G#5','C#6']]

  $mc = Music::Cadence->new(
    key    => 'C#',
    octave => 5,
    format => 'midi',
  );

  $chords = $mc->cadence;
  # [['Gs5','C5','Ds5'], ['Cs5','F5','Gs5','Cs6']]

  $mc = Music::Cadence->new(
    key    => 'C',
    octave => 4,
    format => 'midinum',
  );

  $chords = $mc->cadence;
  # [[67,71,62], [60,64,67,72]]

  $mc = Music::Cadence->new;

  $chords = $mc->cadence(
    octave    => 4,
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
  );
  # [['B4','D4','G4'], ['E4','G4','C4']]

=head1 DESCRIPTION

C<Music::Cadence> provides a pair of musical cadence chords.

These chords are usually added to the end of a musical phrase, and
are used to suggest a sense of anticipation, pause, finality, etc.

B<*> This module is a naive implementation of the actual theory.
Currently, only chords of 3 notes are generated.  YMMV.  Patches
welcome.

=head1 ATTRIBUTES

=head2 key

The key or tonal center to use.  Default: C<C>

Examples: C<G#>, C<Eb>

=head2 scale

The scale to use.  Default: C<major>

Supported scales are:

  ionian / major
  dorian
  phrygian
  lydian
  mixolydian
  aeolian / minor
  locrian

=head2 octave

The octave to either append to named chord notes (for C<midi> or
C<isobase> format) or to determine the correct C<midinum> note number.

Default: C<0>

If the B<format> is C<midi> or C<isobase>, setting this to C<0> means
"do not append."

The C<midinum> range for this attribute is from C<-1> to C<10>.

=head2 format

The output format to use.  Default: C<isobase> (i.e. "bare note
names")

If C<midi>, convert sharp C<#> to C<s> and flat C<b> to C<f> after
chord generation.

If C<midinum>, convert notes to their numerical MIDI equivalents.

=head1 METHODS

=head2 new

  $mc = Music::Cadence->new;  # Use defaults

  $mc = Music::Cadence->new(  # Override defaults
    key    => $key,
    scale  => $scale,
    octave => $octave,
    format => $format,
  );

Create a new C<Music::Cadence> object.

=head2 cadence

  $chords = $mc->cadence;     # Use defaults

  $chords = $mc->cadence(     # Override defaults
    key       => $key,        # Default: C
    scale     => $scale,      # Default: major
    octave    => $octave,     # Default: 0
    type      => $type,       # Default: perfect
    leading   => $leading,    # Default: 1
    variation => $variation,  # Default: 1
    inversion => $inversion,  # Default: 0
  );

Return an array reference of the chords of the cadence B<type> based
on the given B<key> and B<scale> name.

Supported cadences are:

  deceptive
  half
  imperfect
  perfect
  plagal

The B<variation> applies to the C<deceptive> and C<imperfect> cadences.

If the B<type> is C<deceptive>, the B<variation> determines the final
chord.  If it is set to C<1>, the C<vi> chord is used.  For C<2>, the
C<IV> chord is used.

If the B<type> is C<imperfect> and there is no B<inversion>, the
B<variation> determines the kind of C<perfect> cadence generated.  For
C<1>, the highest voice is not the tonic.  For C<2>, the fifth chord
is replaced with the seventh.  So in a major key, the C<V> chord would
be replaced with the C<vii diminished> chord.

For an C<imperfect> cadence, if the B<inversion> is set to a hash
reference of numbered keys, the values are the types of inversions to
apply to the chords of the cadence.  For example:

  inversion => { 1 => 2, 2 => 1 },

Says, "Apply the second inversion to the first chord of the cadence,
and apply the first inversion to the second chord."

To B<not> apply an inversion to an inverted imperfect cadence chord,
either do not include the numbered chord in the hash reference, or
set its value to C<0> zero.

The B<leading> chord is a number (1-7) for each diatonic scale chord
to use for the first C<half> cadence chord.  For the key of C<C major>
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

L<Music::Chord::Positions>

L<Music::Note>

L<Music::Scales>

L<Music::ToRoman>

L<https://en.wikipedia.org/wiki/Cadence>

L<https://www.musictheoryacademy.com/how-to-read-sheet-music/cadences/>

=head1 TO DO

Evaded cadence

Imperfect inverted cadence (2nd variation)

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
