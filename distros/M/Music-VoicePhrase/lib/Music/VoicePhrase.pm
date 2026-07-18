package Music::VoicePhrase;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Construct measured phrases of notes

our $VERSION = '0.0127';

use v5.36;
use Moo;
use strictures 2;
use Carp qw(croak);
use Music::Duration::Partition ();
use Music::Scales qw(get_scale_MIDI);
use Music::VoiceGen ();
use namespace::clean;


has base => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a valid note" unless $_[0] =~ /^[A-G][#b]?$/i },
    default => sub { 'C' },
);


has index => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 0 },
);


has scale => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a valid scale name" unless $_[0] =~ /^\w+$/ },
    default => sub { 'major' },
);


has octave => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a valid octave" unless $_[0] =~ /^[0-9]$/ },
    default => sub { 0 },
);


has pitches => (
    is      => 'rw',
    lazy    => 1,
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    builder => '_build_pitches',
);

sub _build_pitches ($self) {
    my @pitches = (
        get_scale_MIDI($self->base, $self->octave, $self->scale),
        get_scale_MIDI($self->base, $self->octave + 1, $self->scale),
    );
    say 'Built pitches: ', join ' ', @pitches if $self->verbose;
    return \@pitches;
}


has intervals => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [-3, -2, -1, 1, 2, 3] },
);

has voice => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_voice',
    clearer => 'clear_voice',
);

sub _build_voice ($self) {
    my $voice = Music::VoiceGen->new(
        pitches   => $self->pitches,
        intervals => $self->intervals,
        verbose   => $self->verbose,
    );
    say "Built voice: $voice" if $self->verbose;
    return $voice;
}


has size => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a valid size" unless $_[0] =~ /^[\d.]+$/ },
    default => sub { 4 },
);


has pool => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [qw(dhn hn qn)] },
);


has weights => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [1, 2, 2] },
);


has groups => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [0, 0, 0] },
);

has _rhythm => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build__rhythm',
);

sub _build__rhythm ($self) {
  my $mdp = Music::Duration::Partition->new(
      size    => $self->size,
      pool    => $self->pool,
      weights => $self->weights,
      groups  => $self->groups,
      verbose => $self->verbose,
  );
  say "Built rhythm generator: $mdp" if $self->verbose;
  return $mdp;
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
    clearer => 'clear_motifs',
);


has voices => (
    is      => 'rw',
    lazy    => 1,
    builder => 'build_voices',
);


has metadata => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a hash-ref" unless ref $_[0] eq 'HASH' },
    default => sub { +{} },
);


has verbose => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


has name => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a valid part name" unless defined $_[0] },
    default => sub { 'part' },
);


has patch => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a valid patch" unless $_[0] =~ /^[0-9]+$/ },
    default => sub { 0 },
);


has gate => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a valid gate" unless $_[0] =~ /^[0-9.-]+$/ && $_[0] >= 0 && $_[0] <= 2 },
    default => sub { 1 },
);


has volume => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 100 },
);


has queue => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref $_[0] eq 'ARRAY' },
    default => sub { [] },
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


has rest_prob => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a valid probability" unless $_[0] =~ /^[\d.]+$/ },
    default => sub { 0 },
);


# sub BUILD ($self, $args) {
#     $self->_build_motifs;
# }


sub build_motifs ($self) {
    my @motifs = $self->_rhythm->motifs($self->motif_num);
    say "Built motifs: @motifs" if $self->verbose;
    return \@motifs;
}


sub build_voices ($self) {
    my @voices = map { $self->voice->rand } $self->motifs->@*;
    say "Built voices: @voices" if $self->verbose;
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

Music::VoicePhrase - Construct measured phrases of notes

=head1 VERSION

version 0.0127

=head1 SYNOPSIS

  use Music::VoicePhrase ();

  my $mvp = Music::VoicePhrase->new;

  # or also with external processing metadata:
  my %metadata = (key => 'value!', color => 'hot-pink');
  $mvp = Music::VoicePhrase->new(metadata => \%metadata);
  $mvp->metadata(\%metadata);
  my $value = $mvp->metadata->{key}; # ghetto access - ugh

  my $motifs = $mvp->motifs; # using defaults
  my $voices = $mvp->voices;

  # get fresh:
  $motifs = $mvp->build_motifs;
  $voices = $mvp->build_voices;

=head1 DESCRIPTION

A C<Music::VoicePhrase> constructs a measured phrase of voices with
both pitch and rhythmic values.

This module is also equipped with handy attributes to make real-time
processing work. See the linked phrase generator app in the
L</"SEE ALSO"> section.

=head1 ATTRIBUTES

=head2 base

  $base = $mvp->base;

Base scale note.

Default: C<C>

=head2 index

  $index = $mvp->index;
  $mvp->index($n);

A handy index!

Default: C<0>

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

Pitches that define the L<Music::VoiceGen> selection. (This is just
an array-ref of midi-numbers.)

Default: 2 consecutive octaves given the B<base> note, B<scale> name,
and starting B<octave>.

=head2 intervals

  $intervals = $mvp->intervals;

Intervals that define the L<Music::VoiceGen> selection.

Default: [-3, -2, -1, 1, 2, 3]

=head2 size

  $size = $mvp->size;

The number of beats in a phrase. This is usually an integer like C<4>
beats for a measure. But it can also be a float, as the
L<Music::Duration::Partition> module takes fractional numbers to
represent odd meters.

For instance size C<2.5> represents C<5/8> time. Because a size of <5>
represents C<5/4> time.

Default: C<4>

=head2 pool

  $pool = $mvp->pool;

The pool of note durations, given in Perl L<MIDI> abbreviated
notation, that define a L<Music::Duration::Partition> phrase.

Default: ['dhn', 'hn', 'qn']

=head2 weights

  $weights = $mvp->weights;

Weights that define a L<Music::Duration::Partition> phrase.

Default: [ 1, 2, 2 ]

=head2 groups

  $groups = $mvp->groups;

Groups that define a L<Music::Duration::Partition> phrase.

Default: [ 0, 0, 0 ]

=head2 motif_num

  $motif_num = $mvp->motif_num;

The number of motifs to generate by the C<build_motifs()> method.

Default: C<4>

=head2 motifs

  $motifs = $mvp->motifs;

The rhythmic motifs generated by the L<Music::Duration::Partition>
module.

Default: C<4> motifs

=head2 voices

  $voices = $mvp->voices;

The pitches that are generated by the L<Music::VoiceGen> C<rand()> method.

Default: C<4> voices

=head2 metadata

  $metadata = $mvp->metadata;
  $key = $mvp->metadata->{key}
  $mvp->metadata(\%data);
  $mvp->metadata->{key} = 'Value!';

Extra, named C<key/value> things! No fancy get/set methods - sorry!

Default: C<{}> (nothing extra)

=head2 verbose

  $verbose = $mvp->verbose;

Show progress.

Default: C<0>

=head1 Extra

These attributes are used in real-time processing, etc.

=head2 name

  $name = $mvp->name;

Name for the given part.

Default: C<'part'>

=head2 patch

  $patch = $mvp->patch;

Patch / synth program integer from C<0> to C<127>.

Default: C<0> (GM piano)

=head2 gate

  $gate = $mvp->gate;

A possibly fractional amount representing how long a note-length is
between C<0> and C<2>. A C<0> value means that the note is not played.
A C<2> means the note is to be held twice as long.

Default: C<1> (unity)

=head2 volume

  $volume = $mvp->volume;
  $mvp->volume($n);

A value from C<0> to C<127>.

Default: C<100>

=head2 queue

  $queue = $mvp->queue;

The priority queue list of notes to play or stop.

=head2 note

  $note = $mvp->note;
  $mvp->note($n);

The currently selected note hash.

Default: C<{}>

=head2 onsets

  $onsets = $mvp->onsets;

A list of note onsets.

=head2 channel

  $channel = $mvp->channel;

The MIDI channel of the part.

Default: C<0>

=head2 rest_prob

  $rest_prob = $mvp->rest_prob;
  $mvp->rest_prob($n);

A value of C<0> means there is no resting. A 20% chance of a rest
would be C<0.2>. A value of C<1> means "only rest." Ha!

Default: C<0>

=head1 METHODS

=head2 new

  $mvp = Music::VoicePhrase->new(%arguments);

Create a new C<Music::VoicePhrase> object.

=for Pod::Coverage BUILD

=head2 build_motifs

  $motifs = $mvp->build_motifs;

Build a fresh list of motifs based on the C<motif_num> attribute.

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

L<https://github.com/ology/Phrase-Generator>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
