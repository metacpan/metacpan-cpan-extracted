package Music::Chord::Progression::T;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Generate transposed chord progressions

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use Carp qw(croak);
use Data::Dumper::Compact qw(ddc);
use Music::Chord::Note ();
use Music::Chord::Namer qw(chordname);
use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(Music-MelodicDevice-Transposition); # local author libs
use Music::MelodicDevice::Transposition ();
use namespace::clean;

with 'Music::PitchNum';


has base_note => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid note" unless $_[0] =~ /^[A-G][#b]?$/ },
    default => sub { 'C' },
);


has base_octave => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid octave" unless $_[0] =~ /^[1-8]$/ },
    default => sub { 4 },
);


has chord_quality => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid quality" unless $_[0] =~ /^\w*$/ },
    default => sub { '' },
);


has base_chord => (
    is => 'lazy',
);

sub _build_base_chord {
    my ($self) = @_;
    my $cn = Music::Chord::Note->new;
    my @chord = $cn->chord_with_octave(
        $self->base_note . $self->chord_quality,
        $self->base_octave
    );
    return \@chord;
}


has format => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid format" unless $_[0] =~ /^(?:ISO|midinum)$/ },
    default => sub { 'ISO' },
);


has semitones => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid number of semitones" unless $_[0] =~ /^[1-9]\d*$/ },
    default => sub { 7 },
);


has max => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid maximum" unless $_[0] =~ /^[1-9]\d*$/ },
    default => sub { 4 },
);


has transform => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid transform" unless ref $_[0] eq 'ARRAY' || $_[0] =~ /^[1-9]\d*$/ },
    default => sub { 4 },
);


has mdt => (
    is => 'lazy',
);

sub _build_mdt {
    return Music::MelodicDevice::Transposition->new;
}


has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


sub generate {
    my ($self) = @_;

    my ($pitches, $notes) = $self->_get_pitches;

    my @transform = $self->_build_transform;

    $self->_initial_conditions(@transform) if $self->verbose;

    my @generated;
    my $i = 0;

    for my $token (@transform) {
        $i++;

        my $transformed = $self->_build_chord($token, $pitches, $notes);

        my @notes = map { $self->pitchname($_) } @$transformed;
        my @base = map { s/^([A-G][#b]?)\d/$1/r } @notes; # for chord-name

        push @generated, $self->format eq 'ISO' ? \@notes : $transformed;

        printf "%d. %s: %s   %s   %s\n",
            $i, $token,
            ddc($transformed), ddc(\@notes),
            scalar chordname(@base)
            if $self->verbose;

        $notes = $transformed;
    }

    return \@generated;
}


sub circular {
    my ($self) = @_;

    my ($pitches, $notes) = $self->_get_pitches;

    my @transform = $self->_build_transform;

    $self->_initial_conditions(@transform) if $self->verbose;

    my @generated;
    my $posn = 0;

    for my $i (1 .. $self->max) {
        my $token = $transform[ $posn % @transform ];

        my $transformed = $self->_build_chord($token, $pitches, $notes);

        my @notes = map { $self->pitchname($_) } @$transformed;
        my @base = map { s/^([A-G][#b]?)\d/$1/r } @notes; # for chord-name

        push @generated, $self->format eq 'ISO' ? \@notes : $transformed;

        printf "%d. %s (%d): %s   %s   %s\n",
            $i, $token, $posn % @transform,
            ddc($transformed), ddc(\@notes),
            scalar chordname(@base)
            if $self->verbose;

        $notes = $transformed;

        $posn = int rand 2 ? $posn + 1 : $posn - 1;
    }

    return \@generated;
}

sub _get_pitches {
    my ($self) = @_;
    my @pitches = map { $self->pitchnum($_) } @{ $self->base_chord };
    return \@pitches, [ @pitches ];
}

sub _initial_conditions {
    my ($self, @transform) = @_;
    printf "Initial: %s%s %s\nTransforms: %s\n",
        $self->base_note, $self->base_octave, $self->chord_quality,
        join(',', @transform);
}

sub _build_transform {
    my ($self) = @_;

    my @transform;

    if (ref $self->transform eq 'ARRAY') {
        @transform = @{ $self->transform };
    }
    elsif ($self->transform =~ /^\d+$/) {
        @transform = ('I', map { 'T' . int(rand $self->semitones + 1) } 1 .. $self->transform - 1);
    }

    return @transform;
}

sub _build_chord {
    my ($self, $token, $pitches, $notes) = @_;

    my $chord = [];

    if ($token =~ /^I$/) {
        $chord = $pitches; # no transformation
    }
    else {
        (my $semitones = $token) =~ s/^T(-?\d+)$/$1/;
        $chord = $self->mdt->transpose($semitones, $notes);
    }

    return $chord;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Chord::Progression::T - Generate transposed chord progressions

=head1 VERSION

version 0.0100

=head1 SYNOPSIS

  use MIDI::Util qw(setup_score midi_format);
  use Music::Chord::Progression::T ();

  my $transpose = Music::Chord::Progression::T->new;
  my $chords = $transpose->generate;
  $chords = $transpose->circular;

  # render a midi file
  my $score = setup_score();
  $score->n('wn', midi_format(@$_)) for @$chords;
  $score->write_score('transpose.mid');

=head1 DESCRIPTION

The C<Music::Chord::Progression::T> module generates transposed chord
progressions.

=head1 ATTRIBUTES

=head2 base_note

  $base_note = $transpose->base_note;

The initial C<isobase>, capitalized note on which the progression starts.

Default: C<C>

=head2 base_octave

  $base_octave = $transpose->base_octave;

The initial note octave on which the progression starts.

Default: C<4>

=head2 chord_quality

  $chord_quality = $transpose->chord_quality;

The quality or "flavor" of the initial chord.

Please see the L<Music::Chord::Note> module for a list of the known
chords, like C<m> for "minor" or C<7> for a 7th chord, etc.

Default: C<''> (major)

=head2 base_chord

  $base_chord = $transpose->base_chord;

The chord given by the B<base_note>, B<base_octave>, and the B<chord_quality>.

=head2 format

  $format = $transpose->format;

The format of the returned results, as either named C<ISO> notes or C<midinum> integers.

Default: C<ISO>

=head2 semitones

  $semitones = $transpose->semitones;

The number of semitones of which a transformation can be made.

Default: C<7> (a perfect 5th)

=head2 max

  $max = $transpose->max;

The maximum number of I<circular> transformations to make.

Default: C<4>

=head2 transform

  $transform = $transpose->transform;

The array-reference of C<T> transformations that define the chord
progression. These transformations are a series of C<T#> operations,
where the C<#> is a number between B<1> and the number of B<semitones>
defined.

Additionally the "non-transformation", C<I> is allowed to return the
the initial chord.

This attribute can be given as an integer, which defines the number of
random transformations to perform.

Default: C<4>

=head2 mdt

  $mdt = $transpose->mdt;

The L<Music::MelodicDevice::Transposition> object.

=head2 verbose

  $verbose = $transpose->verbose;

Show progress.

Default: C<0>

=head1 METHODS

=head2 new

  $transpose = Music::Chord::Progression::T->new; # use defaults

  $transpose = Music::Chord::Progression::T->new( # override defaults
    base_note     => 'Bb',
    base_octave   => 5,
    chord_quality => 'minor',
    format        => 'midinum',
    semitones     => 11,
    max           => 12,
    transform     => [qw(I T4 T2 T6)],
  );

Create a new C<Music::Chord::Progression::T> object.

=head2 generate

  $chords = $transpose->generate;

Generate a I<linear> series of transformed chords.

=head2 circular

  $chords = $transpose->circular;

Generate a series of transformed chords based on a I<circular> list of
transformations (a "necklace").

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> files

L<Carp>

L<Data::Dumper::Compact>

L<Moo>

L<Music::Chord::Note>

L<Music::Chord::Namer>

L<Music::MelodicDevice::Transposition>

L<https://viva.pressbooks.pub/openmusictheory/chapter/neo-riemannian-triadic-progressions/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
