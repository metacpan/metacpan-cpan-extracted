package Music::Cadence;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Provide musical cadence chords

our $VERSION = '0.0401';

use Moo;
use Music::Chord::Note;
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


sub cadence {
    my ( $self, %args ) = @_;

    my $cadence = [];

    $args{key}       ||= $self->key;
    $args{scale}     ||= $self->scale;
    $args{octave}    //= $self->octave;
    $args{type}      ||= 'perfect';
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
        my $chord = _generate_chord( $args{scale}, $scale[4], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;

        $chord = _generate_chord( $args{scale}, $scale[0], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;
    }
    elsif ( $args{type} eq 'plagal' ) {
        my $chord = _generate_chord( $args{scale}, $scale[3], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;

        $chord = _generate_chord( $args{scale}, $scale[0], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;
    }
    elsif ( $args{type} eq 'half' ) {
        my $chord = _generate_chord( $args{scale}, $scale[ $args{leading} - 1 ], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;

        $chord = _generate_chord( $args{scale}, $scale[4], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;
    }
    elsif ( $args{type} eq 'deceptive' ) {
        my $chord = _generate_chord( $args{scale}, $scale[4], $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;

        my $note = $args{variation} == 1 ? $scale[5] : $scale[3];
        $chord = _generate_chord( $args{scale}, $note, $args{octave}, $mtr, $mcn );
        push @$cadence, $chord;
    }

    return $cadence;
}

sub _generate_chord {
    my ( $scale, $note, $octave, $mtr, $mcn ) = @_;

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

    # Figure out if the chord is diminished, minor, or major
    my $roman = $mtr->parse($note);
    my $type  = $roman =~ /^$diminished{$scale}$/ ? 'dim' : $roman =~ /^[a-z]/ ? 'm' : '';

    # Generate the chord notes
    my @notes = $mcn->chord( $note . $type );

    # Append the octave if requested
    @notes = map { $_ . $octave } @notes
        if $octave;

    return \@notes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Cadence - Provide musical cadence chords

=head1 VERSION

version 0.0401

=head1 SYNOPSIS

  use Music::Cadence;

  my $mc = Music::Cadence->new(
    key    => 'C',
    scale  => 'major',
    octave => 4,
  );

  my $chords = $mc->cadence( type => 'perfect' );
  # [['G4','B4','D4'], ['C4','E4','G4']]

  $chords = $mc->cadence(
    type    => 'half',
    leading => 2,
    octave  => 0,
  ); # [['D','F','A'], ['G','B','D']]

=head1 DESCRIPTION

C<Music::Cadence> provides musical cadence chords.

* This module is a naive implementation of the actual theory.  YMMV.
Patches welcome.

=head1 ATTRIBUTES

=head2 key

The key or tonal center to use.  Default: C<C>

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

The octave to append to chord notes.  Default: C<0> meaning "do not
append."

=head1 METHODS

=head2 new

  $mc = Music::Cadence->new;

Create a new C<Music::Cadence> object.

=head2 cadence

  $chords = $mc->cadence;  # Use defaults

  $chords = $mc->cadence(
    key       => $key,        # Default: C
    scale     => $scale,      # Default: major
    octave    => $octave,     # Default: 0
    type      => $type,       # Default: perfect
    leading   => $leading,    # Default: 1
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
