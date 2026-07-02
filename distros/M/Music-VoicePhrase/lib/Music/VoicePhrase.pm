package Music::VoicePhrase;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Construct a measured phrase of notes

our $VERSION = '0.0110';

use v5.36;
use Moo;
use strictures 2;
use Carp qw(croak);
use Music::Duration::Partition ();
use Music::Scales qw(get_scale_MIDI);
use Music::VoiceGen ();
use namespace::clean;


has base => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid note" unless $_[0] =~ /^[A-G][#b]?$/i },
    default => sub { 'C' },
);


has scale => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid scale name" unless $_[0] =~ /^\w+$/ },
    default => sub { 'major' },
);


has octave => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid octave" unless $_[0] =~ /^[0-9]$/ },
    default => sub { 0 },
);


has pitches => (
    is      => 'lazy',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    builder => '_build_pitches',
);

sub _build_pitches ($self) {
    my @pitches = (
        get_scale_MIDI($self->base, $self->octave, $self->scale),
        get_scale_MIDI($self->base, $self->octave + 1, $self->scale),
    );
    return \@pitches;
}


has intervals => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [-3, -2, -1, 1, 2, 3] },
);

has voice => (
    is      => 'lazy',
    builder => '_build_voice',
);

sub _build_voice ($self) {
    my $voice = Music::VoiceGen->new(
        pitches   => $self->pitches,
        intervals => $self->intervals,
    );
    return $voice;
}


has size => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid size" unless $_[0] =~ /^\d+$/ },
    default => sub { 4 },
);


has pool => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [qw(dhn hn qn)] },
);


has weights => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [1, 2, 2] },
);


has groups => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [0, 0, 0] },
);

has _rhythm => (
    is      => 'lazy',
    builder => '_build__rhythm',
);

sub _build__rhythm ($self) {
  my $mdp = Music::Duration::Partition->new(
      size    => $self->size,
      pool    => $self->pool,
      weights => $self->weights,
      groups  => $self->groups,
  );
}


has motif_num => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 4 },
);


has motifs => (
    is      => 'rw',
    lazy    => 1,
    builder => 'build_motifs',
);


has voices => (
    is      => 'rw',
    lazy    => 1,
    builder => 'build_voices',
);


has patch => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid patch" unless $_[0] =~ /^[0-9]+$/ },
    default => sub { 0 },
);


has queue => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [] },
);


has index => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 0 },
);


has note => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a valid note" unless ref $_[0] eq 'HASH' },
    default => sub { +{} },
);


has onsets => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [] },
);


has channel => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 0 },
);


has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


# sub BUILD ($self, $args) {
#     $self->_build_motifs;
# }


sub build_motifs ($self) {
    my @motifs = $self->_rhythm->motifs($self->motif_num);
    return \@motifs;
}


sub build_voices ($self) {
    my @voices = map { $self->voice->rand } $self->motifs->@*;
    return \@voices;
}


sub increment_index ($self) {
    $self->index($self->index + 1);
    return $self->index;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::VoicePhrase - Construct a measured phrase of notes

=head1 VERSION

version 0.0110

=head1 SYNOPSIS

  use Music::VoicePhrase ();

  my $mvp = Music::VoicePhrase->new;

  my $motifs = $mvp->motifs; # using defaults
  my $voices = $mvp->voices;

  $mvp->motif_num(6); # get fresh
  $motifs = $mvp->build_motifs;
  $voices = $mvp->build_voices;

=head1 DESCRIPTION

A C<Music::VoicePhrase> constructs a measured phrase of voices with
both pitch and rhythmic value.

This module is also equipped with a few handy attributes to make
real-time processing work. See the linked script in the
L</"SEE ALSO"> section.

=head1 ATTRIBUTES

=head2 base

  $base = $mvp->base;

Base scale note.

Default: C<C>

=head2 scale

  $scale = $mvp->scale;

Scale name known to the L<Music::Scales> module.

Default: C<major>

=head2 octave

  $octave = $mvp->octave;

Octave integer from C<0> to C<9>.

Default: C<0>

=head2 pitches

  $pitches = $mvp->pitches;

The allowed pitches in MIDI number format.

Default: 2 consecutive octaves given the B<base> note, B<scale> name,
and starting B<octave>.

=head2 intervals

  $intervals = $mvp->intervals;

Intervals that define the L<Music::VoiceGen> selection.

Default: [-3, -2, -1, 1, 2, 3]

=head2 size

  $size = $mvp->size;

Size of a measure.

Default: C<4>

=head2 pool

  $pool = $mvp->pool;

The pool of note durations, given in Perl L<MIDI> abbreviated
notation, that define the L<Music::Duration::Partition> phrase.

Default: ['dhn', 'hn', 'qn']

=head2 weights

  $weights = $mvp->weights;

Weights that define the L<Music::Duration::Partition> phrase.

Default: [ 1, 2, 2 ]

=head2 groups

  $groups = $mvp->groups;

Groups that define the L<Music::Duration::Partition> phrase.

Default: [ 0, 0, 0 ]

=head2 motif_num

  $motif_num = $mvp->motif_num;

The number of motifs to generate by the C<build_motifs()> method.

Default: C<4>

=head2 motifs

  $motifs = $mvp->motifs;

The rhythmic motifs given by L<Music::Duration::Partition>.

Default: C<4> motifs

=head2 voices

  $voices = $mvp->voices;

The pitches given by L<Music::VoiceGen>.

Default: C<4> voices

=head2 patch

  $patch = $mvp->patch;

Patch / synth program integer from C<0> to C<127>.

Default: C<0> (GM piano)

=head2 queue

  $queue = $mvp->queue;

Computed attribute for the priority queue used in real-time processing.

=head2 index

  $index = $mvp->index;
  $mvp->index($n);

Computed attribute for the queue index that is used in real-time processing.

Default: C<0>

=head2 note

  $note = $mvp->note;
  $mvp->note($n);

Computed attribute for the currently selected note that is used in real-time processing.

Default: C<{}>

=head2 onsets

  $onsets = $mvp->onsets;

Computed attribute for the note onsets used in real-time processing.

=head2 channel

  $channel = $mvp->channel;

The MIDI channel of the part.

Default: C<0>

=head2 verbose

  $verbose = $mvp->verbose;

Show progress.

Default: C<0>

=head1 METHODS

=head2 new

  $mvp = Music::VoicePhrase->new(%arguments);

Create a new C<Music::VoicePhrase> object.

=for Pod::Coverage BUILD

=head2 build_motifs

  $motifs = $mvp->build_motifs;

Build a fresh list of motifs based on the .

=head2 build_voices

  $voices = $mvp->build_voices;

Build a fresh list of voices based on the number of motifs.

=head2 increment_index

  $i = $mvp->increment_index;

Just add one to the B<index> attribute.

=head1 SEE ALSO

L<Moo>

L<Music::Duration::Partition>

L<Music::Scales>

L<Music::VoiceGen>

L<https://github.com/ology/Music/blob/master/tones-variation.pl>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
