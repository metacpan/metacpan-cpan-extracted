package Music::Chord::Progression::Transform;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Generate transformed chord progressions

our $VERSION = '0.0106';

use Moo;
use strictures 2;
use Algorithm::Combinatorics qw(variations);
use Carp qw(croak);
use Data::Dumper::Compact qw(ddc);
use Music::NeoRiemannianTonnetz ();
use Music::Chord::Note ();
use Music::Chord::Namer qw(chordname);
use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(Music-MelodicDevice-Transposition); # local author lib
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


has allowed => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not valid" unless ref $_[0] eq 'ARRAY' },
    default => sub { [qw(T N)] },
);


has transforms => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid transform" unless ref $_[0] eq 'ARRAY' || $_[0] =~ /^[1-9]\d*$/ },
    default => sub { 4 },
);


has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

has _nrt => (
    is => 'lazy',
);

sub _build__nrt {
    return Music::NeoRiemannianTonnetz->new;
}

has _mdt => (
    is => 'lazy',
);

sub _build__mdt {
    return Music::MelodicDevice::Transposition->new;
}


sub generate {
    my ($self) = @_;

    my ($pitches, $notes) = $self->_get_pitches;

    my @transforms = $self->_build_transform;

    $self->_initial_conditions(@transforms) if $self->verbose;

    my @generated;
    my $i = 0;

    for my $token (@transforms) {
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

    my @transforms = $self->_build_transform;

    $self->_initial_conditions(@transforms) if $self->verbose;

    my @generated;
    my $posn = 0;

    for my $i (1 .. $self->max) {
        my $token = $transforms[ $posn % @transforms ];

        my $transformed = $self->_build_chord($token, $pitches, $notes);

        my @notes = map { $self->pitchname($_) } @$transformed;
        my @base = map { s/^([A-G][#b]?)\d/$1/r } @notes; # for chord-name

        push @generated, $self->format eq 'ISO' ? \@notes : $transformed;

        printf "%d. %s (%d): %s   %s   %s\n",
            $i, $token, $posn % @transforms,
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
    my ($self, @transforms) = @_;
    printf "Initial: %s%s %s\nTransforms: %s\n",
        $self->base_note, $self->base_octave, $self->chord_quality,
        join(',', @transforms);
}

sub _build_transform {
    my ($self) = @_;

    my @t; # the transformations to return

    if (ref $self->transforms eq 'ARRAY') {
        @t = @{ $self->transforms };
    }
    elsif ($self->transforms =~ /^\d+$/) {
        my @transforms;

        if (grep { $_ eq 'T' } @{ $self->allowed }) {
            push @transforms, (map { 'T' . $_ } 1 .. $self->semitones);  # positive
            push @transforms, (map { 'T-' . $_ } 1 .. $self->semitones); # negative
        }
        if (grep { $_ eq 'N' } @{ $self->allowed }) {
            my @alphabet = qw(P R L);
            push @transforms, @alphabet;

            my $iter = variations(\@alphabet, 2);
            while (my $v = $iter->next) {
                push @transforms, join('', @$v);
            }

            $iter = variations(\@alphabet, 3);
            while (my $v = $iter->next) {
                push @transforms, join('', @$v);
            }
        }

        @t = ('O',
            map { $transforms[ int rand @transforms ] }
                1 .. $self->transforms - 1
        );
    }

    return @t;
}

sub _build_chord {
    my ($self, $token, $pitches, $notes) = @_;

    my $chord;

    if ($token =~ /^O$/) {
        $chord = $pitches; # return to the original chord
    }
    elsif ($token =~ /^I$/) {
        $chord = $notes; # no transformation
    }
    elsif ($token =~ /^T(-?\d+)$/) {
        my $semitones = $1;
        $chord = $self->_mdt->transpose($semitones, $notes);
    }
    else {
        my $task = $self->_nrt->taskify_tokens($token) if length $token > 1;
        my $op = defined $task ? $task : $token;

        $chord = $self->_nrt->transform($op, $notes);
    }

    return $chord;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Chord::Progression::Transform - Generate transformed chord progressions

=head1 VERSION

version 0.0106

=head1 SYNOPSIS

  use MIDI::Util qw(setup_score midi_format);
  use Music::Chord::Progression::Transform ();

  my $transform = Music::Chord::Progression::Transform->new;

  my $chords = $transform->generate;
  $chords = $transform->circular;

  # render a midi file
  my $score = setup_score();
  $score->n('wn', midi_format(@$_)) for @$chords;
  $score->write_score('transform.mid');

=head1 DESCRIPTION

The C<Music::Chord::Progression::Transform> module generates transposed
and Neo-Riemann chord progressions.

=head1 ATTRIBUTES

=head2 base_note

  $base_note = $transform->base_note;

The initial C<isobase>, capitalized note on which the progression starts.

Default: C<C>

=head2 base_octave

  $base_octave = $transform->base_octave;

The initial note octave on which the progression starts.

Default: C<4>

=head2 chord_quality

  $chord_quality = $transform->chord_quality;

The quality or "flavor" of the initial chord.

For Neo-Riemann operations on triads, the quality must be either major
(C<''>) or minor (C<'m'>). For seventh chords, use a quality of C<7>.
For transposition operations, anything goes.

Please see the L<Music::Chord::Note> module for a list of the known
chords, like C<m> for "minor" or C<7> for a seventh chord, etc.

Default: C<''> (major)

=head2 base_chord

  $base_chord = $transform->base_chord;

The chord given by the B<base_note>, B<base_octave>, and the
B<chord_quality>.

=head2 format

  $format = $transform->format;

The format of the returned results, as either named C<ISO> notes or
C<midinum> integers.

Default: C<ISO>

=head2 semitones

  $semitones = $transpose->semitones;

The number of semitones of which a transposition transformation can be
made.

Default: C<7> (a perfect 5th)

=head2 max

  $max = $transform->max;

The maximum number of I<circular> transformations to make.

Default: C<4>

=head2 allowed

  $allowed = $transform->allowed;

The allowed transformations. Currently this is either C<T>
(transposition), C<N> Neo-Riemann, or both.

Default: C<T N>

=head2 transforms

  $transforms = $transform->transforms;

The array-reference of C<T#> transposed and Neo-Riemann
transformations that define the chord progression.

The C<T#> transformations are a series of transposition operations,
where C<#> is a positive or negative number between +/- B<semitones>.

For Neo-Riemann transformations, please see the
L<Music::NeoRiemannianTonnetz> module for the allowed operations.

Additionally the "non-transformation" operations are included: C<O>
returns to the initial chord, and C<I> is the identity that leaves the
current chord untouched.

This can also be given as an integer, which defines the number of
random transformations to perform.

Default: C<4>

=head2 verbose

  $verbose = $transform->verbose;

Show progress.

Default: C<0>

=head1 METHODS

=head2 new

  $transform = Music::Chord::Progression::Transform->new; # use defaults

  $transform = Music::Chord::Progression::Transform->new( # override defaults
    base_note     => 'Bb',
    base_octave   => 5,
    chord_quality => '7',
    format        => 'midinum',
    max           => 12,
    allowed       => ['T'],
    transforms    => [qw(O T1 T2 T3)],
  );

Create a new C<Music::Chord::Progression::Transform> object.

=head2 generate

  $chords = $transform->generate;

Generate a I<linear> series of transformed chords.

=head2 circular

  $chords = $transform->circular;

Generate a series of transformed chords based on a I<circular> list of
transformations.

This method defines movement over a circular list ("necklace") of
chord transformations, including C<O>, which means "return to the
original chord", and C<I> which means to "make no transformation."
Starting at position zero, move forward or backward along the
necklace, transforming the current chord.

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> files

L<Carp>

L<Data::Dumper::Compact>

L<Moo>

L<Music::MelodicDevice::Transposition>

L<Music::NeoRiemannianTonnetz>

L<Music::Chord::Note>

L<Music::Chord::Namer>

L<https://viva.pressbooks.pub/openmusictheory/chapter/neo-riemannian-triadic-progressions/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
