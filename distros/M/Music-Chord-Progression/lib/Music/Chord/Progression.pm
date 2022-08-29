package Music::Chord::Progression;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Create network transition chord progressions

our $VERSION = '0.0604';

use Carp qw(croak);
use Data::Dumper::Compact qw(ddc);
use Graph::Directed;
use Music::Chord::Note;
use Music::Scales qw(get_scale_notes);
use Moo;
use strictures 2;
use namespace::clean;


has max => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 8 },
);


has net => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a hashref" unless ref $_[0] eq 'HASH' },
    default => sub {
      { 1 => [qw( 1 2 3 4 5 6 )],
        2 => [qw( 3 4 5 )],
        3 => [qw( 1 2 4 6 )],
        4 => [qw( 1 3 5 6 )],
        5 => [qw( 1 4 6 )],
        6 => [qw( 1 2 4 5 )],
        7 => [] }
    },
);


has chord_map => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an arrayref" unless ref $_[0] eq 'ARRAY' },
    default => sub { ['', 'm', 'm', '', '', 'm', 'dim'] },
);


has scale_name => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid string" if ref $_[0] },
    default => sub { 'major' },
);


has scale_note => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid note" unless $_[0] =~ /^[A-G][#b]?$/ },
    default => sub { 'C' },
);


has scale => (
    is        => 'lazy',
    init_args => undef,
);

sub _build_scale {
    my ($self) = @_;
    my @scale = get_scale_notes($self->scale_note, $self->scale_name);
    print 'Scale: ', ddc(\@scale) if $self->verbose;
    return \@scale;
}


has octave => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid octave" unless $_[0] =~ /^-?\d+$/ },
    default => sub { 4 },
);


has tonic => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid setting" unless $_[0] =~ /^-?[01]$/ },
    default => sub { 1 },
);


has resolve => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid setting" unless $_[0] =~ /^-?[01]$/ },
    default => sub { 1 },
);


has substitute => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


has sub_cond => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid coderef" unless ref($_[0]) eq 'CODE' },
    default => sub { return sub { int rand 4 == 0 } },
);


has flat => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


has graph => (
    is        => 'lazy',
    init_args => undef,
);

sub _build_graph {
  my ($self) = @_;
    my $g = Graph::Directed->new;
    for my $posn (keys %{ $self->net }) {
        for my $p (@{ $self->net->{$posn} }) {
            $g->add_edge($posn, $p);
        }
    }
    return $g;
}


has phrase => (
    is        => 'rw',
    init_args => undef,
);


has chords => (
    is        => 'rw',
    init_args => undef,
);



has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


sub generate {
    my ($self) = @_;

    croak 'chord_map length must equal number of net keys'
        unless @{ $self->chord_map } == keys %{ $self->net };

    print 'Graph: ' . $self->graph, "\n" if $self->verbose;

    # Create a random progression
    my @progression;
    my $v; # Vertex
    for my $n (1 .. $self->max) {
        $v = $self->_next_successor($n, $v);
        push @progression, $v;
    }
    print 'Progression: ', ddc(\@progression) if $self->verbose;

    my @chord_map = @{ $self->chord_map };

    if ($self->substitute) {
        my $i = 0;
        for my $chord (@chord_map) {
            my $substitute = $self->sub_cond->() ? $self->substitution($chord) : $chord;
            if ($substitute eq $chord && $i < @progression && $self->sub_cond->()) {
                $progression[$i] .= 't'; # Indicate that we should tritone substitute
            }
            $chord = $substitute;
            $i++;
        }
    }
    print 'Chord map: ', ddc(\@chord_map) if $self->verbose;

    my @phrase = map { $self->_tt_sub(\@chord_map, $_) } @progression;
    $self->phrase(\@phrase);
    print 'Phrase: ', ddc($self->phrase) if $self->verbose;

    # Add octaves to the chords
    my $mcn = Music::Chord::Note->new;
    my @chords;
    for my $chord (@phrase) {
        my @chord = $mcn->chord_with_octave($chord, $self->octave);
        push @chords, \@chord;
    }

    if ($self->flat) {
        my %equiv = (
            'C#' => 'Db',
            'D#' => 'Eb',
            'E#' => 'F',
            'F#' => 'Gb',
            'G#' => 'Ab',
            'A#' => 'Bb',
            'B#' => 'C',
        );
        for my $chord (@chords) {
            for my $note (@$chord) {
                $note =~ s/^([A-G]#)(\d+)$/$equiv{$1}$2/ if $note =~ /#/;
            }
        }
    }

    $self->chords(\@chords);
    print 'Chords: ', ddc($self->chords) if $self->verbose;

    return \@chords;
}

sub _next_successor {
    my ($self, $n, $v) = @_;

    $v //= 1;

    my $s;

    if ($n == 1) {
        if ($self->tonic == 0) {
            $s = $self->graph->random_successor(1);
        }
        elsif ($self->tonic == 1) {
            $s = 1;
        }
        else {
            $s = $self->_full_keys;
        }
    }
    elsif ($n == $self->max) {
        if ($self->resolve == 0) {
            $s = $self->graph->random_successor($v) || $self->_full_keys;
        }
        elsif ($self->resolve == 1) {
            $s = 1;
        }
        else {
            $s = $self->_full_keys;
        }
    }
    else {
        $s = $self->graph->random_successor($v);
    }

    return $s;
}

sub _full_keys {
    my ($self) = @_;
    my @keys = grep { keys @{ $self->net->{$_} } > 0 } keys %{ $self->net };
    return $keys[int rand @keys];
}

sub _tt_sub {
    my ($self, $chord_map, $n) = @_;

    my $note;

    if ($n =~ /t/) {
        my @fnotes = get_scale_notes('C', 'chromatic', 0, 'b');
        my @snotes = get_scale_notes('C', 'chromatic');
        my %ftritone = map { $fnotes[$_] => $fnotes[($_ + 6) % @fnotes] } 0 .. $#fnotes;
        my %stritone = map { $snotes[$_] => $snotes[($_ + 6) % @snotes] } 0 .. $#snotes;

        $n =~ s/t//;
        $note = $ftritone{ $self->scale->[$n - 1] } || $stritone{ $self->scale->[$n - 1] };
        print 'Tritone: ', $self->scale->[$n - 1], " => $note\n" if $self->verbose;
    }
    else {
        $note = $self->scale->[$n - 1];
    }

    $note .= $chord_map->[$n - 1];
    print "Note: $note\n" if $self->verbose;

    return $note;
}


sub substitution {
    my ($self, $chord) = @_;

    my $substitute = $chord;

    if ($chord eq '' || $chord eq 'm') {
        my $roll = int rand 2;
        $substitute = $roll == 0 ? $chord . 'M7' : $chord . 7;
    }
    elsif ($chord eq 'dim' || $chord eq 'aug') {
        $substitute = $chord . 7;
    }
    elsif ($chord eq '-5' || $chord eq '-9') {
        $substitute = "7($chord)";
    }
    elsif ($chord eq 'M7') {
        my $roll = int rand 3;
        $substitute = $roll == 0 ? 'M9' : $roll == 1 ? 'M11' : 'M13';
    }
    elsif ($chord eq '7') {
        my $roll = int rand 3;
        $substitute = $roll == 0 ? '9' : $roll == 1 ? '11' : '13';
    }
    elsif ($chord eq 'm7') {
        my $roll = int rand 3;
        $substitute = $roll == 0 ? 'm9' : $roll == 1 ? 'm11' : 'm13';
    }

    print qq|Substitute: "$chord" => "$substitute"\n| if $self->verbose && $substitute ne $chord;

    return $substitute;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Chord::Progression - Create network transition chord progressions

=head1 VERSION

version 0.0604

=head1 SYNOPSIS

  use Music::Chord::Progression;
  use MIDI::Util qw(setup_score midi_format);

  my $prog = Music::Chord::Progression->new;

  my $chord_type = $prog->substitution('m'); # m7 or mM7

  my $progression = $prog->generate;

  my $score = setup_score();
  for my $chord (@$progression) {
      $score->n('wn', midi_format(@$chord));
  }

=head1 DESCRIPTION

C<Music::Chord::Progression> creates network transition chord
progressions.

This module can also perform limited jazz chord substitutions, if
requested in the constructor.

=head1 ATTRIBUTES

=head2 max

The number of chords to generate in a phrase.

Default: C<8>

=head2 net

The network transitions between chords of the progression.

The keys must start with C<1> and be contiguous to the end.

Ending on C<12> keys all the notes of the chromatic scale.  Ending on
C<7> represents diatonic notes, given the B<scale_name>.

If you do not wish a scale note to be chosen, include it among the
keys, but do not refer to it and do not give it any neighbors.  Thus,
in the first example, the 7th degree of the scale will never be chosen.

Default:

  { 1 => [qw( 1 2 3 4 5 6 )],
    2 => [qw( 3 4 5 )],
    3 => [qw( 1 2 4 6 )],
    4 => [qw( 1 3 5 6 )],
    5 => [qw( 1 4 6 )],
    6 => [qw( 1 2 4 5 )],
    7 => [] }

A contrived chromatic example where each note connects to every note:

  { 1  => [1 .. 12],
    2  => [1 .. 12],
    3  => [1 .. 12],
    4  => [1 .. 12],
    5  => [1 .. 12],
    6  => [1 .. 12],
    7  => [1 .. 12],
    8  => [1 .. 12],
    9  => [1 .. 12],
    10 => [1 .. 12],
    11 => [1 .. 12],
    12 => [1 .. 12],
  }

=head2 chord_map

The chord names of each scale position.

The number of items in this list must be equal to the number of keys
in the B<net>.

Default: C<[ '', 'm', 'm', '', '', 'm', 'dim' ]>

Here C<''> refers to the major chord and C<'m'> means minor.

Alternative example:

  [ 'M7', 'm7', 'm7', 'M7', '7', 'm7', 'dim7' ]

The known chord names are listed in the source of L<Music::Chord::Note>.

=head2 scale_name

The name of the scale.

Default: C<major>

Please see L<Music::Scales/SCALES> for the allowed scale names.

=head2 scale_note

The (uppercase) name of the scale starting note with an optional C<#>
or C<b> accidental.

Default: C<C>

=head2 scale

The scale notes.  This is a computed attribute.

Default: C<[C D E F G A B]>

=head2 octave

The octave of the scale.

Default: C<4>

=head2 tonic

Set the start of the progression.

If this is given as C<1> the tonic chord starts the progression.  If
given as C<0> a neighbor of the tonic is chosen.  If given as C<-1> a
random B<net> key is chosen.

Default: C<1>

=head2 resolve

Set the end the progression.

If this is given as C<1> the tonic chord ends the progression.  If
given as C<0> a neighbor of the last chord is chosen.  If given as
C<-1> a random B<net> key is chosen.

Default: C<1>

=head2 substitute

Perform jazz chord substitution.

Default: C<0>

Rules:

=over 4

=item Any chord can be changed to a dominant

=item Any dominant chord can be changed to a 9, 11, or 13

=item Any chord can be changed to a chord a tritone away

=back

=head2 sub_cond

The subroutine to determine if a chord substitution should happen.

Default: C<sub { int rand 4 == 0 }> (25% of the time)

=head2 flat

Use flats instead of sharps in the generated chords.

Default: C<0>

=head2 graph

The network transition L<Graph> object.  This is a computed attribute.

Default: C<Graph::Directed-E<gt>new>

=head2 phrase

The generated phrase of named chords.  This is a computed attribute.

=head2 chords

The generated phrase of individual note chords.  This is a computed
attribute.

=head2 verbose

Show the progress and chosen values.

=head1 METHODS

=head2 new

  $prog = Music::Chord::Progression->new; # Use the defaults

  $prog = Music::Chord::Progression->new( # Override the defaults
    max        => 4,
    net        => { 1 => [...], ... 7 => [...] },
    chord_map  => ['m','dim','','m','m','',''],
    scale_name => 'minor',
    scale_note => 'A',
    octave     => 5,
    tonic      => 0,
    resolve    => -1,
    flat       => 1,
    substitute => 1,
    verbose    => 1,
  );

Create a new C<Music::Chord::Progression> object.

=head2 generate

  $chords = $prog->generate;

Generate a fresh chord progression and set the B<phrase> and B<chords>
attributes.

=head2 substitution

  $substitute = $prog->substitution($chord_type);

Perform a jazz substitution on the given the chord type.

=head1 SEE ALSO

The F<t/01-methods.t> test and F<eg/*> example files

L<Carp>

L<Data::Dumper::Compact>

L<Graph>

L<Moo>

L<Music::Chord::Note>

L<Music::Scales>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
