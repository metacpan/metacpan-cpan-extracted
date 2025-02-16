package Music::Cadence;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Generate musical cadence chords

our $VERSION = '0.1511';

use Moo;
use strictures 2;
use Data::Dumper::Compact qw(ddc);
use List::Util qw(any);
use Music::Chord::Note ();
use Music::Chord::Positions ();
use Music::Note ();
use Music::Scales qw(get_scale_notes);
use Music::ToRoman ();
use namespace::clean;

with('Music::PitchNum');


has verbose => (
    is      => 'ro',
    default => sub { 0 },
);


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


has picardy => (
    is      => 'ro',
    default => sub { 0 },
);


sub cadence {
    my ( $self, %args ) = @_;

    my $cadence = [];

    my $key       = $args{key}       || $self->key;
    my $scale     = $args{scale}     || $self->scale;
    my $octave    = $args{octave}    // $self->octave;
    my $picardy   = $args{picardy}   || $self->picardy;
    my $type      = $args{type}      || 'perfect';
    my $leading   = $args{leading}   || 1;
    my $variation = $args{variation} || 1;
    my $inversion = $args{inversion} || 0;

    die 'unknown leader' if $leading < 1 or $leading > 7;

    my @scale_notes = get_scale_notes( $key, $scale );

    if ( $type eq 'perfect' ) {
        my $chord = $self->_generate_chord( $key, $scale, $scale_notes[4], $octave );
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[0], $octave );
        # Add another top note, but an octave above
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
        print ddc($top) if $self->verbose;
        push @$chord, $top;
        print ddc($chord) if $self->verbose;
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
        print ddc($chord) if $self->verbose;
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[0], $octave );
        print ddc($chord) if $self->verbose;
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
        print ddc($chord) if $self->verbose;
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[0], $octave );
        $chord = $self->_invert_chord( $chord, $inversion->{2}, $octave );
        print ddc($chord) if $self->verbose;
        push @$cadence, $chord;
    }
    elsif ( $type eq 'plagal' ) {
        my $chord = $self->_generate_chord( $key, $scale, $scale_notes[3], $octave );
        print ddc($chord) if $self->verbose;
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[0], $octave );
        print ddc($chord) if $self->verbose;
        push @$cadence, $chord;
    }
    elsif ( $type eq 'half' ) {
        my $chord = $self->_generate_chord( $key, $scale, $scale_notes[ $leading - 1 ], $octave );
        $chord = $self->_invert_chord( $chord, $inversion->{1}, $octave )
            if $inversion && $inversion->{1};
        print ddc($chord) if $self->verbose;
        push @$cadence, $chord;

        $chord = $self->_generate_chord( $key, $scale, $scale_notes[4], $octave );
        $chord = $self->_invert_chord( $chord, $inversion->{2}, $octave )
            if $inversion && $inversion->{2};
        print ddc($chord) if $self->verbose;
        push @$cadence, $chord;
    }
    elsif ( $type eq 'deceptive' ) {
        my $chord = $self->_generate_chord( $key, $scale, $scale_notes[4], $octave );
        print ddc($chord) if $self->verbose;
        push @$cadence, $chord;

        my $note = $variation == 1 ? $scale_notes[5] : $scale_notes[3];
        $chord = $self->_generate_chord( $key, $scale, $note, $octave );
        print ddc($chord) if $self->verbose;
        push @$cadence, $chord;
    }
    else {
        die 'unknown cadence';
    }

    if ( $picardy ) {
        if ( $self->format eq 'midinum' ) {
            $cadence->[1][1]++;
        }
        else {
            my $note = Music::Note->new( $cadence->[1][1], $self->format );
            my $num  = $note->format('midinum');
            $num++;
            $note = Music::Note->new( $num, 'midinum' );
            $cadence->[1][1] = $note->format( $self->format );
        }
    }

    return $cadence;
}

sub _invert_chord {
    my ( $self, $chord, $inversion, $octave ) = @_;

    my $mcp = Music::Chord::Positions->new;

    if ( $self->format eq 'midinum' ) {
        $chord = $mcp->chord_inv( $chord, inv_num => $inversion );
    }
    else { # Perform these gymnastics to convert named notes to inverted named notes:
        # Strip the octave if present
        $chord = [ map { s/\d+//; $_ } @$chord ]
            if $octave;

        # Convert the chord into pitch-class representation
        my $pitches = [ map { $self->pitchnum( $_ . -1 ) } @$chord ];

        # Do the inversion!
        $pitches = $mcp->chord_inv( $pitches, inv_num => $inversion );

        # Convert the pitch-classes back to named notes
        $chord = [ map { $self->pitchname($_) } @$pitches ];

        # Clean-up the chord
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

    # Get the notes of the chord (without an octave)
    my @notes = $mcn->chord( $note . $type );

    if ( $self->format eq 'midi' ) {
        # Convert the sharps and flats
        for ( @notes ) {
            s/#/s/;
            s/b/f/;
        }
    }
    elsif ( $self->format eq 'midinum' ) {
        # Convert the notes to midinum format
        @notes = map { $self->pitchnum( $_ . $octave ) } @notes;
    }
    elsif ( $self->format ne 'isobase' ) {
        die 'unknown format';
    }

    # Append the octave if defined and the format is not midinum
    @notes = map { $_ . $octave } @notes
        if $octave && $self->format ne 'midinum';

    return \@notes;
}


sub remove_notes {
    my ($self, $indices, $chord) = @_;
    my @chord;
    for my $n (0 .. @$chord - 1) {
        next if any { $n == $_ } @$indices;
        push @chord, $chord->[$n];
    }
    return \@chord;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Cadence - Generate musical cadence chords

=head1 VERSION

version 0.1511

=head1 SYNOPSIS

  use Music::Cadence;

  my $mc = Music::Cadence->new;
  my $chords = $mc->cadence;
  # [G B D], [C E G C]

  $mc = Music::Cadence->new(octave => 4);

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

  $mc = Music::Cadence->new(format => 'midinum');

  $chords = $mc->cadence(octave => 4);
  # [67 71 62], [60 64 67 72]

  $chords = $mc->cadence(octave => -1);
  # [7 11 2], [0 4 7 12] <- pitch-classes!

  $mc = Music::Cadence->new(seven => 1);

  $chords = $mc->cadence;
  # [G B D F], [C E G A# C]

  $chords = $mc->cadence(
    type   => 'evaded',
    octave => 4,
  );
  # [F4 G5 B5 D5], [E4 G4 A#4 C5]

  my $altered = $mc->remove_notes([1,2], [qw(Gs5 C5 Ds5)]);
  # [Gs5]

=head1 DESCRIPTION

C<Music::Cadence> generates a pair of musical cadence chords.

These chords are often added to the end of a musical phrase, and are
used to suggest a sense of anticipation, pause, finality, etc.

=head1 ATTRIBUTES

=head2 verbose

  $verbose = $mc->verbose;

Show progress.

Default: C<0>

=head2 key

  $key = $mc->key;

The key or tonal center to use, in C<isobase> format.

Default: C<C>

Examples: C<G#>, C<Eb>

=head2 scale

  $scale = $mc->scale;

The modal scale to use.

Default: C<major>

Supported scales are the diatonic modes:

  ionian / major
  dorian
  phrygian
  lydian
  mixolydian
  aeolian / minor
  locrian

=head2 octave

  $octave = $mc->octave;

The octave to either append to named chord notes, or to determine the
correct C<midinum> note number.

Default: C<0>

If the B<format> is C<midi> or the default, setting this to C<0> means
"do not append."  Setting it to a positive integer renders the note in
C<ISO> format.

The C<midinum> range for this attribute should an integer from C<-1>
to C<9> (giving note numbers C<0> to C<127>).

=head2 format

  $format = $mc->format;

The output format to use.

Default: C<isobase> (i.e. "bare note names")

If C<midi>, convert sharp C<#> to C<s> and flat C<b> to C<f> after
chord generation.

If C<midinum>, convert notes to their numerical MIDI equivalents.

=head2 seven

  $seven = $mc->seven;

If set, use seventh chords of four notes instead of diatonic triads.

Default: C<0>

=head2 picardy

  $picardy = $mc->picardy;

If set, use the "Picardy third" for the final chord.

This effectively raises the second note of the final chord by one
half-step.

Default: C<0>

=head1 METHODS

=head2 new

  $mc = Music::Cadence->new; # Use defaults
  $mc = Music::Cadence->new( # Override defaults
    key     => $key,
    scale   => $scale,
    octave  => $octave,
    format  => $format,
    seven   => $seven,
    picardy => $picardy,
  );

Create a new C<Music::Cadence> object.

=head2 cadence

  $chords = $mc->cadence;     # Use defaults
  $chords = $mc->cadence(     # Override defaults
    key       => $key,        # See above
    scale     => $scale,      # "
    octave    => $octave,     # "
    picardy   => $picardy,    # "
    type      => $type,       # Default: perfect
    leading   => $leading,    # Default: 1
    variation => $variation,  # Default: 1
    inversion => $inversion,  # Default: 0
  );

Return an array reference of the chords of the cadence B<type> based
on the given B<key> and B<scale> name, etc.

Supported cadences are:

  deceptive
  evaded
  half
  imperfect
  perfect
  plagal

And "authentic" cadence is either perfect or imperfect.

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

  1: C maj
  2: D min
  3: E min
  4: F maj
  5: G maj
  6: A min
  7: B dim

If an B<inversion> is defined for the C<half> cadence, the chords are
inverted as described above for the C<imperfect> cadence.

The C<evaded> cadence applies inversions to seventh chords.  The
default is to invert the first chord by the third inversion and the
second by the first inversion.

=head3 Handy Summary

 1. Deceptive -> V-vi or V-IV
    variation
        1: final chord = vi
        2: final chord = IV

 2. Evaded -> inverted V-I 7th chords
    inversion
        1: 1st, 2nd, or 3rd applied to first chord
        2: "                           second chord

 3. Half -> <leading>-V and possibly inverted
    leading: first chord = 1-7
    inversion
        as above (3rd inversion only for 7th chords)

 4. Imperfect -> V-I or vii-I or V-I inverted
    variation (no inversion)
        1: first chord = V
        2: first chord = vii
    inversion (variation ignored)
        as above (3rd inversion only for 7th chords)

 5. Perfect -> V-I + tonic added an octave above

 6. Plagal -> IV-I

=head2 remove_notes

  $altered = $mc->remove_notes(\@indices, \@chord);

Remove the given indices from the given chord.

=head1 SEE ALSO

The F<eg/*> and F<t/*> programs in this distribution

L<List::Util>

L<Moo>

L<Music::Chord::Note>

L<Music::Chord::Positions>

L<Music::Note>

L<Music::Scales>

L<Music::ToRoman>

L<https://en.wikipedia.org/wiki/Cadence>

L<https://www.musictheoryacademy.com/how-to-read-sheet-music/cadences/>

L<https://www.musictheory.net/lessons/55>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
