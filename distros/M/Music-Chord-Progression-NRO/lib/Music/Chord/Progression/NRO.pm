package Music::Chord::Progression::NRO;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Generate Neo-Riemann chord progressions

our $VERSION = '0.0203';

use Moo;
use strictures 2;
use Carp qw(croak);
use Data::Dumper::Compact qw(ddc);
use Music::NeoRiemannianTonnetz ();
use Music::Chord::Note ();
use Music::Chord::Namer qw(chordname);
use namespace::clean;

with 'Music::PitchNum';


has base_note => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid note" unless $_[0] =~ /^[A-G][#b]?$/ },
    default => sub { 'C' },
);


has base_octave => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid octave" unless $_[0] =~ /^\d+$/ },
    default => sub { 4 },
);


has base_scale => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid scale" unless $_[0] =~ /^(?:major|minor)$/ },
    default => sub { 'major' },
);


has format => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid format" unless $_[0] =~ /^(?:ISO|midinum)$/ },
    default => sub { 'ISO' },
);


has max => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid maximum" unless $_[0] =~ /^\d+$/ },
    default => sub { 8 },
);


has transform => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid transform" unless ref $_[0] eq 'ARRAY' || $_[0] =~ /^\d+$/ },
    default => sub { 4 },
);


has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


has nrt => (
    is => 'lazy',
);

sub _build_nrt {
    return Music::NeoRiemannianTonnetz->new;
}


has base_chord => (
    is => 'lazy',
);

sub _build_base_chord {
    my ($self) = @_;
    my $cn = Music::Chord::Note->new;
    my $quality = $self->base_scale eq 'major' ? '' : 'm';
    my @chord = $cn->chord_with_octave($self->base_note . $quality, $self->base_octave);
    return \@chord;
}


sub generate {
    my ($self) = @_;

    my @base = map { s/^([A-G][#b]?)\d/$1/r } @{ $self->base_chord }; # for chord-name
    my @pitches = map { $self->pitchnum($_) } @{ $self->base_chord };
    my $notes = \@pitches;

    my @generated;
    push @generated, $self->format eq 'ISO' ? $self->base_chord : \@pitches;

    my $i = 1;
    print "$i. X: ", ddc($notes), '   ', ddc($self->base_chord), '   ', scalar chordname(@base), "\n"
        if $self->verbose;

    my @transform = $self->_build_transform;

    for my $token (@transform) {
        $i++;

        my $transformed = $self->_build_transformed($token, \@pitches, $notes);

        my @notes = map { $self->pitchname($_) } @$transformed;
        @base = map { s/^([A-G][#b]?)\d/$1/r } @notes; # for chord-name

        push @generated, $self->format eq 'ISO' ? \@notes : $transformed;

        print "$i. $token: ", ddc($transformed), '   ', ddc(\@notes), '   ', scalar chordname(@base), "\n"
            if $self->verbose;

        $notes = $transformed;
    }

    return \@generated;
}


sub circular {
    my ($self) = @_;

    my @base = map { s/^([A-G][#b]?)\d/$1/r } @{ $self->base_chord }; # for chord-name
    my @pitches = map { $self->pitchnum($_) } @{ $self->base_chord };
    my $notes = \@pitches;

    my @transform = $self->_build_transform;

    my @generated;
    my $posn = 0;

    for my $i (1 .. $self->max) {
        my $token = $transform[ $posn % @transform ];

        my $transformed = $self->_build_transformed($token, \@pitches, $notes);

        my @notes = map { $self->pitchname($_) } @$transformed;
        @base = map { s/^([A-G][#b]?)\d/$1/r } @notes; # for chord-name

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

sub _build_transform {
    my ($self) = @_;
    my @transform;
    if (ref $self->transform eq 'ARRAY') {
        @transform = @{ $self->transform };
    }
    elsif ($self->transform =~ /^\d+$/) {
        my @nro = qw(L P R N S H PRL);
        @transform = map { $nro[ int rand @nro ] } 1 .. $self->transform - 1;
    }
    return @transform;
}

sub _build_transformed {
    my ($self, $token, $pitches, $notes) = @_;
    my $transformed;
    if ($token =~ /^X$/) {
        $transformed = $pitches; # no transformation
    }
    else {
        my $task = $self->nrt->taskify_tokens($token) if length $token > 1;
        my $tx = defined $task ? $task : $token;
        $transformed = $self->nrt->transform($tx, $notes);
    }
    return $transformed;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Chord::Progression::NRO - Generate Neo-Riemann chord progressions

=head1 VERSION

version 0.0203

=head1 SYNOPSIS

  use Music::Chord::Progression::NRO ();

  my $nro = Music::Chord::Progression::NRO->new;

  my $chords = $nro->generate;

  $chords = $nro->circular;

=head1 DESCRIPTION

C<Music::Chord::Progression::NRO> Generates Neo-Riemann chord progressions.

=head1 ATTRIBUTES

=head2 base_note

  $base_note = $nro->base_note;

The initial note on which the progression starts.

Default: C<C>

=head2 base_octave

  $base_octave = $nro->base_octave;

The initial octave on which the progression starts.

Default: C<4>

=head2 base_scale

  $base_scale = $nro->base_scale;

The major or minor quality of the initial chord.

Default: C<major>

=head2 format

  $format = $nro->format;

The format of the returned results as either named C<ISO> notes or C<midinum> integers.

Default: C<ISO>

=head2 max

  $max = $nro->max;

The maximum number of circular transformations to make.

Default: C<8>

=head2 transform

  $transform = $nro->transform;

The array-reference of Neo-Riemann transformations that define the chord progression.

Please see the L<Music::NeoRiemannianTonnetz> module for the allowed transformations.

This can also be given as an integer, which defines the number of random transformations to perform.

Additionally the "non-transformation", C<X> is allowed to return the the initial chord.

Default: C<4>

=head2 verbose

  $verbose = $nro->verbose;

Show progress.

Default: C<0>

=head2 nrt

  $nrt = $nro->nrt;

The L<Music::NeoRiemannianTonnetz> object.

=head2 base_chord

  $base_chord = $nro->base_chord;

The chord given by the B<base_note>, B<base_octave>, and the B<base_scale>.

=head1 METHODS

=head2 new

  $nro = Music::Chord::Progression::NRO->new(verbose => 1);

Create a new C<Music::Chord::Progression::NRO> object.

=for Pod::Coverage BUILD

=head2 generate

  $chords = $nro->generate;

Generate a series of transformed chords.

=head2 circular

  $chords = $nro->circular;

Generate a series of transformed chords based on a circular array of transformations.

The F<eg/nro-chain> program puts it this way:

"Use a circular list ("necklace") of Neo-Riemannian transformations,
plus "X" meaning "make no transformation." Starting at position zero
move forward or backward along the necklace, transforming the current
chord..."

=head1 SEE ALSO

The F<t/01-methods.t> file

L<Carp>

L<Data::Dumper::Compact>

L<Moo>

L<Music::NeoRiemannianTonnetz>

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
