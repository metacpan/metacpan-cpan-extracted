package Music::Chord::Progression::Transform;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Generate transformed chord progressions

our $VERSION = '0.0304';

use Moo;
use strictures 2;
use Algorithm::Combinatorics qw(variations);
use Carp qw(croak);
use Data::Dumper::Compact qw(ddc);
use Music::NeoRiemannianTonnetz ();
use Music::Chord::Note ();
use Music::Chord::Namer qw(chordname);
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
    is       => 'lazy',
    init_arg => undef,
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
    default => sub { 'midinum' },
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

    # get the pitch-nums of the base_chord - static and mutable
    my ($pitches, $notes) = $self->_get_pitches;

    # get either the defined transformations or a random set
    my @transforms = $self->_build_transform;

    $self->_initial_conditions(@transforms) if $self->verbose;

    my @chords;
    my @generated;
    my $i = 0;

    for my $token (@transforms) {
        $i++;

        # perform the transformation
        my $transformed = $self->_build_chord($token, $pitches, $notes);

        my @notes = map { $self->pitchname($_) } @$transformed; # for ISO
        my @base = map { s/^([A-G][#b]?)\d/$1/r } @notes; # for chord-name

        # tally what has been generated
        push @generated, $self->format eq 'ISO' ? \@notes : $transformed;

        my $chord = _sanitize_chordname(@base);
        push @chords, $chord;

        printf "%d. %s: %s   %s   %s\n",
            $i, $token,
            ddc($transformed), ddc(\@notes),
            $chord
            if $self->verbose;

        # "increment" our pitches
        $notes = $transformed;
    }

    return \@generated, \@transforms, \@chords;
}


sub circular {
    my ($self) = @_;

    # get the pitch-nums of the base_chord - static and mutable
    my ($pitches, $notes) = $self->_get_pitches;

    # get either the defined transformations or a random set
    my @transforms = $self->_build_transform;

    $self->_initial_conditions(@transforms) if $self->verbose;

    my @chords;
    my @generated;
    my $posn = 0;

    for my $i (1 .. $self->max) {
        my $token = $transforms[ $posn % @transforms ];

        # perform the transformation
        my $transformed = $self->_build_chord($token, $pitches, $notes);

        my @notes = map { $self->pitchname($_) } @$transformed; # for ISO
        my @base = map { s/^([A-G][#b]?)\d/$1/r } @notes; # for chord-name

        # tally what has been generated
        push @generated, $self->format eq 'ISO' ? \@notes : $transformed;

        my $chord = _sanitize_chordname(@base);
        push @chords, $chord;

        printf "%d. %s (%d): %s   %s   %s\n",
            $i, $token, $posn % @transforms,
            ddc($transformed), ddc(\@notes),
            $chord
            if $self->verbose;

        # "increment" our pitches
        $notes = $transformed;

        # move left or right at random
        $posn = int rand 2 ? $posn + 1 : $posn - 1;
    }

    return \@generated, \@transforms, \@chords;
}

sub _sanitize_chordname {
    my (@notes) = @_;

    my $chord = chordname(@notes);

    # fix mangled/unknown chordnames
    $chord =~ s/\s+//;
    $chord =~ s/o/dim/;
    $chord =~ s/maj/M/;
    $chord =~ s/sus7/7sus4/;
    $chord =~ s/7adda5/7(#5)/;
    $chord =~ s/7addb2/7(b9,13)/;
    $chord =~ s/9add13/7(9,13)/;
    $chord =~ s/7addm10/7(#9)/;
    $chord = $1 . $2 if $chord =~ /^(.+)\/(\d+)$/;
    # ...and there are probably more to come...

    return $chord;
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
        my @transforms = qw(O I);

        if (grep { $_ eq 'T' } @{ $self->allowed }) {
            push @transforms, (map { 'T' . $_ } 1 .. $self->semitones);  # positive
            push @transforms, (map { 'T-' . $_ } 1 .. $self->semitones); # negative
        }
        if (grep { $_ eq 'N' } @{ $self->allowed }) {
            if ($self->chord_quality eq 7) {
                push @transforms, qw(
                  S23 S32 S34 S43 S56 S65
                  C32     C34         C65
                );
            }
            else {
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
        }

        @t = map { $transforms[ int rand @transforms ] }
            1 .. $self->transforms;
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
        my $task = $self->_nrt->taskify_tokens($token)
            if length $token > 1 && $token !~ /\d/;
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

version 0.0304

=head1 SYNOPSIS

  use Music::Chord::Progression::Transform ();

  my $prog = Music::Chord::Progression::Transform->new;

  $prog = Music::Chord::Progression::Transform->new(
    transforms => [qw(L R P T6 R S T-6)],
  );

  my ($generated, $transforms, $chords) = $prog->generate;

  ($generated, $transforms, $chords) = $prog->circular;

  # midi
  use MIDI::Util qw(setup_score);
  my $score = setup_score();
  $score->n('wn', @$_) for @$generated;
  $score->write_score('transform.mid');

=head1 DESCRIPTION

The C<Music::Chord::Progression::Transform> module generates transposed
and Neo-Riemann chord progressions.

=head1 ATTRIBUTES

=head2 base_note

  $base_note = $prog->base_note;

The initial C<isobase>, capitalized note on which the progression
starts (but may be immediately transformed by the first operation).

Default: C<C> (but may be C<C#>, C<Db>, etc.)

=head2 base_octave

  $base_octave = $prog->base_octave;

The initial note octave on which the progression starts.

Default: C<4>

=head2 chord_quality

  $chord_quality = $prog->chord_quality;

The quality or "flavor" of the initial chord.

For Neo-Riemann operations on triads, the quality must be either major
(C<''>) or minor (C<'m'>). For seventh chords, use a quality of C<7>.
For transposition operations, anything goes.

Please see the L<Music::Chord::Note> module for a list of the known
chords, like C<m> for "minor" or C<7> for a seventh chord, etc.

Default: C<''> (major)

=head2 base_chord

  $base_chord = $prog->base_chord;

The initial chord given by the B<base_note>, B<base_octave>, and the
B<chord_quality>.

This is computed and not a constructor attribute.

=head2 format

  $format = $prog->format;

The format of the returned results, as either named C<ISO> notes or
C<midinum> integers.

Default: C<midinum>

=head2 semitones

  $semitones = $transpose->semitones;

The number of positive and negative semitones for a transposition
transformation.  That is, this is a +/- bound on the C<T>
transformations.

Default: C<7> (a perfect 5th)

=head2 max

  $max = $prog->max;

The number of I<circular> transformations to make.

Default: C<4>

=head2 allowed

  $allowed = $prog->allowed;

The allowed transformations. Currently this is either C<T>
for transposition, C<N> for Neo-Riemannian, or both.

Default: C<T,N>

=head2 transforms

  $transforms = $prog->transforms;

The array-reference of C<T#> transposed and Neo-Riemann
transformations that define the chord progression.

The C<T#> transformations are a series of transposition operations,
where C<#> is a positive or negative number between +/- B<semitones>.

For Neo-Riemann transformations, please see the
L<Music::NeoRiemannianTonnetz> module for the allowed operations.

Additionally the following "non-transformation" operations are
included: C<O> returns to the initial chord, and C<I> is the identity
that leaves the current chord untouched.

This can also be given as an integer, which defines the number of
random transformations to perform.

Default: C<4>

=head2 verbose

  $verbose = $prog->verbose;

Show progress.

Default: C<0>

=head1 METHODS

=head2 new

  $prog = Music::Chord::Progression::Transform->new; # use defaults

  $prog = Music::Chord::Progression::Transform->new( # override defaults
    base_note     => 'Bb',
    base_octave   => 5,
    chord_quality => '7b5',
    format        => 'ISO',
    max           => 12,
    allowed       => ['T'],
    transforms    => [qw(O T1 T2 T3)],
  );

Create a new C<Music::Chord::Progression::Transform> object.

=head2 generate

  ($generated, $transforms, $chords) = $prog->generate;

Generate a I<linear> series of transformed chords.

=head2 circular

  ($generated, $transforms, $chords) = $prog->circular;

Generate a I<circular> series of transformed chords.

This method defines movement around a circular list ("necklace") of
chord transformations.  Starting at position zero, move forward or
backward along the necklace, transforming the current chord.

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

This software is Copyright (c) 2023-2024 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
