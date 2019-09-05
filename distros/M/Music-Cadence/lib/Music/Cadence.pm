package Music::Cadence;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Generate musical cadence chords

our $VERSION = '0.1307';

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


has seven => (
    is      => 'ro',
    default => sub { 0 },
);


sub cadence {
    my ( $self, %args ) = @_;

    my $cadence = [];

    my $key       = $args{key} || $self->key;
    my $scale     = $args{scale} || $self->scale;
    my $octave    = $args{octave} // $self->octave;
    my $type      = $args{type} || 'perfect';
    my $leading   = $args{leading} || 1;
    my $variation = $args{variation} || 1;
    my $inversion = $args{inversion} || 0;

    die 'unknown leader' if $leading < 1 or $leading > 7;

    my @scale_notes = get_scale_notes( $key, $scale );

    if ( $type eq 'perfect' ) {
        my $chord = $self->_generate_chord( $key, $scale, $scale_notes[4], $octave );
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[0], $octave );
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
    elsif ( $type eq 'imperfect' && $inversion ) {
        my $chord = $self->_generate_chord( $key, $scale, $scale_notes[4], $octave );
        $chord = $self->_invert_chord( $chord, $inversion->{1}, $octave )
            if $inversion->{1};
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[0], $octave );
        $chord = $self->_invert_chord( $chord, $inversion->{2}, $octave )
            if $inversion->{2};
        push @$cadence, $chord;
    }
    elsif ( $type eq 'imperfect' ) {
        my $note = $variation == 1 ? $scale_notes[4] : $scale_notes[6];
        my $chord = $self->_generate_chord( $key, $scale, $note, $octave );
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[0], $octave );
        push @$cadence, $chord;
    }
    elsif ( $type eq 'evaded' && $self->seven ) {
        if ( $inversion ) {
            $inversion->{1} = 3
                unless defined $inversion->{1};
            $inversion->{2} = 1
                unless defined $inversion->{2};
        }
        else {
            $inversion = { 1 => 3, 2 => 1 };
        }

        my $chord = $self->_generate_chord( $key, $scale, $scale_notes[4], $octave );
        $chord = $self->_invert_chord( $chord, $inversion->{1}, $octave );
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[0], $octave );
        $chord = $self->_invert_chord( $chord, $inversion->{2}, $octave );
        push @$cadence, $chord;
    }
    elsif ( $type eq 'plagal' ) {
        my $chord = $self->_generate_chord( $key, $scale, $scale_notes[3], $octave );
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[0], $octave );
        push @$cadence, $chord;
    }
    elsif ( $type eq 'half' ) {
        my $chord = $self->_generate_chord( $key, $scale, $scale_notes[ $leading - 1 ], $octave );
        $chord = $self->_invert_chord( $chord, $inversion->{1}, $octave )
            if $inversion && $inversion->{1};
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[4], $octave );
        $chord = $self->_invert_chord( $chord, $inversion->{2}, $octave )
            if $inversion && $inversion->{2};
        push @$cadence, $chord;
    }
    elsif ( $type eq 'deceptive' ) {
        my $chord = $self->_generate_chord( $key, $scale, $scale_notes[4], $octave );
        push @$cadence, $chord;

        my $note = $variation == 1 ? $scale_notes[5] : $scale_notes[3];
        $chord = $self->_generate_chord( $key, $scale, $note, $octave );
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
        # Perform gymnastics to convert named notes to inverted named notes
        $chord = [ map { s/\d+//; $_ } @$chord ]
            if $octave;

        my $pitches = [ map { Music::Note->new( $_ . -1, 'ISO' )->format('midinum') } @$chord ];

        $pitches = $mcp->chord_inv( $pitches, inv_num => $inversion );

        $chord = [ map { Music::Note->new( $_, 'midinum' )->format('ISO') } @$pitches ];

        for ( @$chord ) {
            if ( $octave ) {
                s/-1/$octave/;
                s/0/$octave + 1/e;
            }
            else {
                s/-1//;
                s/0//;
            }

            if ( $self->format eq 'midi' ) {
                s/#/s/;
                s/b/f/;
            }
        }
    }

    return $chord;
}

sub _generate_chord {
    my ( $self, $key, $scale, $note, $octave ) = @_;

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

    my $mtr = Music::ToRoman->new(
        scale_note => $key,
        scale_name => $scale,
        chords     => 0,
    );

    # Figure out if the chord is diminished, minor, or major
    my $roman = $mtr->parse($note);
    my $type  = $roman =~ /^$diminished{$scale}$/ ? 'dim' : $roman =~ /^[a-z]/ ? 'm' : '';

    $type .= 7
        if $self->seven;

    my $mcn = Music::Chord::Note->new;

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

    @notes = map { $_ . $octave } @notes
        if $octave && $self->format ne 'midinum';

    return \@notes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Cadence - Generate musical cadence chords

=head1 VERSION

version 0.1307

=head1 SYNOPSIS

  use Music::Cadence;

  my $mc = Music::Cadence->new;

  my $chords = $mc->cadence;
  # [G B D], [C E G C]

  $mc = Music::Cadence->new( octave => 4 );

  $chords = $mc->cadence;
  # [G4 B4 D4], [C4 E4 G4 C5]

  $chords = $mc->cadence(
    type    => 'half',
    octave  => 0,
    leading => 2,
  );
  # [D F A], [G B D]

  $chords = $mc->cadence(
    type      => 'imperfect',
    inversion => { 1 => 1, 2 => 1 },
  );
  # [B4 D4 G5], [E4 G4 C5]

  $mc = Music::Cadence->new(
    key    => 'C#',
    octave => 5,
  );

  $chords = $mc->cadence;
  # [G#5 C5 D#5], [C#5 F5 G#5 C#6]

  $mc = Music::Cadence->new(
    key    => 'C#',
    octave => 5,
    format => 'midi',
  );

  $chords = $mc->cadence;
  # [Gs5 C5 Ds5], [Cs5 F5 Gs5 Cs6]

  $mc = Music::Cadence->new( format => 'midinum' );

  $chords = $mc->cadence( octave => 4 );
  # [67 71 62], [60 64 67 72]

  $chords = $mc->cadence( octave => -1 );
  # [7 11 2], [0 4 7 12]

  $mc = Music::Cadence->new( seven => 1 );

  $chords = $mc->cadence;
  # [G B D F], [C E G A# C]

  $chords = $mc->cadence(
    type   => 'evaded',
    octave => 4,
  );
  # [F4 G5 B5 D5], [E4 G4 A#4 C5]

=head1 DESCRIPTION

C<Music::Cadence> generates a pair of musical cadence chords.

These chords are usually added to the end of a musical phrase, and
are used to suggest a sense of anticipation, pause, finality, etc.

=head1 ATTRIBUTES

=head2 key

The key or tonal center to use, in C<isobase> format.

Default: C<C>

Examples: C<G#>, C<Eb>

=head2 scale

The modal scale to use.  Default: C<major>

Supported scales are:

  ionian / major
  dorian
  phrygian
  lydian
  mixolydian
  aeolian / minor
  locrian

=head2 octave

The octave to either append to named chord notes, or to determine the
correct C<midinum> note number.

Default: C<0>

If the B<format> is C<midi> or the default, setting this to C<0> means
"do not append."  Setting it to a positive integer renders the note in
C<ISO> format.

The C<midinum> range for this attribute should an integer from C<-1>
to C<9> (giving note numbers C<0> to C<127>).

=head2 format

The output format to use.

Default: C<isobase> (i.e. "bare note names")

If C<midi>, convert sharp C<#> to C<s> and flat C<b> to C<f> after
chord generation.

If C<midinum>, convert notes to their numerical MIDI equivalents.

=head2 seven

If set, use seventh chords of four notes instead of diatonic triads.

Default: C<0>

=head1 METHODS

=head2 new

  $mc = Music::Cadence->new;  # Use defaults

  $mc = Music::Cadence->new(  # Override defaults
    key    => $key,
    scale  => $scale,
    octave => $octave,
    format => $format,
    seven  => $seven,
  );

Create a new C<Music::Cadence> object.

=head2 cadence

  $chords = $mc->cadence;     # Use defaults

  $chords = $mc->cadence(     # Override defaults
    key       => $key,        # See above
    scale     => $scale,      # "
    octave    => $octave,     # "
    type      => $type,       # Default: perfect
    leading   => $leading,    # Default: 1
    variation => $variation,  # Default: 1
    inversion => $inversion,  # Default: 0
  );

Return an array reference of the chords of the cadence B<type> based
on the given B<key> and B<scale> name.

Supported cadences are:

  deceptive
  evaded
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

This means, "Apply the second inversion to the first chord of the
cadence, and apply the first inversion to the second chord."

For seventh chords (of 4 notes), the third inversion can be applied.

To B<not> apply an inversion to an inverted imperfect cadence chord,
either do not include the numbered chord in the hash reference, or
set its value to C<0> zero.

The B<leading> chord is a number (1-7) for the scale chord to use for
the first C<half> cadence chord.  For the key of C<C major> this is:

  CM: 1
  Dm: 2
  Em: 3
  FM: 4
  GM: 5
  Am: 6
  Bo: 7

If an B<inversion> is defined for the C<half> cadence, the chords are
inverted as described above for the C<imperfect> cadence.

The C<evaded> cadence applies inversions to seventh chords.  The
default (with no B<inversion> defined) is to invert the first chord by
the third inversion and the second by the first inversion.

=head1 SEE ALSO

The F<eg/cadence>, F<eg/synopsis>, F<t/01-methods.t> and
F<t/02-methods.t> files in this distribution.

L<Moo>

L<Music::Chord::Note>

L<Music::Chord::Positions>

L<Music::Note>

L<Music::Scales>

L<Music::ToRoman>

L<https://en.wikipedia.org/wiki/Cadence>

L<https://www.musictheoryacademy.com/how-to-read-sheet-music/cadences/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
