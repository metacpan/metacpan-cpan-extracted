package Music::Chord::Progression;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Create network transition chord progressions

our $VERSION = '0.0003';

use Data::Dumper::Compact qw(ddc);
use Graph::Directed;
use Music::Scales qw(get_scale_notes);
use Music::Chord::Note;

use Moo;
use strictures 2;
use namespace::clean;


has max => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 8 },
);


has net => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a hashref" unless ref $_[0] eq 'HASH' },
    default => sub {
        {
            1 => [qw(1 2 3 4 5 6)],
            2 => [qw(3 5)],
            3 => [qw(2 4 6)],
            4 => [qw(1 2 3 5)],
            5 => [qw(1)],
            6 => [qw(2 4)],
        };
    },
);


has chords => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a arrayref" unless ref $_[0] eq 'ARRAY' },
    default => sub { ['', 'm', 'm', '', '', 'm'] },
);


has scale_name => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid string" if ref $_[0] },
    default => sub { 'major' },
);


has scale_note => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid string" if ref $_[0] },
    default => sub { 'C' },
);


has octave => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid octave" unless $_[0] =~ /^-?\d+$/ },
    default => sub { 4 },
);


has tonic => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 1 },
);


has resolve => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 1 },
);


has flat => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


has graph => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid graph" unless ref($_[0]) =~ /^Graph/ },
    default => sub { Graph::Directed->new },
);


has verbose => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


sub generate {
    my ($self) = @_;

    # Build the graph
    for my $posn (keys %{ $self->net }) {
        for my $p (@{ $self->net->{$posn} }) {
            $self->graph->add_edge($posn, $p);
        }
    }
    print 'Graph: ' . $self->graph, "\n" if $self->verbose;

    # Create a random progression
    my @progression;
    my $v;
    for my $n (1 .. $self->max) {
        if ($n == 1) {
            $v = $self->tonic ? 1 : (keys %{ $self->net })[int rand keys %{ $self->net }];
        }
        elsif ($n == $self->max) {
            $v = $self->resolve ? 1 : (keys %{ $self->net })[int rand keys %{ $self->net }];
        }
        else {
            $v = $self->graph->random_successor($v);
        }
        push @progression, $v;
    }
    print "Progression: @progression\n" if $self->verbose;

    my @scale = get_scale_notes($self->scale_note, $self->scale_name);

    my @phrase = map { $scale[$_ - 1] . $self->chords->[$_ - 1] } @progression;
    print "Phrase: @phrase\n" if $self->verbose;

    # Add octaves to the chord notes
    my $mcn = Music::Chord::Note->new;
    my @notes;
    for my $chord (@phrase) {
        my @chord = $mcn->chord_with_octave($chord, $self->octave);
        push @notes, \@chord;
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
        for my $chord (@notes) {
            for my $note (@$chord) {
                $note =~ s/^([A-G]#)(\d+)$/$equiv{$1}$2/ if $note =~ /#/;
            }
        }
    }
    print 'Notes: ', ddc(\@notes) if $self->verbose;

    return \@notes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Chord::Progression - Create network transition chord progressions

=head1 VERSION

version 0.0003

=head1 SYNOPSIS

  use Music::Chord::Progression;

  my $prog = Music::Chord::Progression->new;

  my $notes = $prog->generate;

=head1 DESCRIPTION

C<Music::Chord::Progression> creates network transition chord
progressions.

=head1 ATTRIBUTES

=head2 max

The maximum number of chords to generate.

Default: C<8>

=head2 net

The network transitions between chords of the progression.

Default:

  { 1 => [qw( 1 2 3 4 5 6 )],
    2 => [qw( 3 5 )],
    3 => [qw( 2 4 6 )],
    4 => [qw( 1 2 3 5 )],
    5 => [qw( 1 )],
    6 => [qw( 2 4 )] }

=head2 chords

The chord name parts of each scale position.

The number of items in this list must be equal and correspond to the
number of keys in the B<net>.

Default: C<[ '', 'm', 'm', '', '', 'm' ]>

=head2 scale_name

The name of the scale.

Default: C<major>

=head2 scale_note

The name of the scale starting note.

Default: C<C>

=head2 octave

The octave number of the scale.

Default: C<4>

=head2 tonic

Whether to start the progression with the tonic chord or not.

Default: C<1>

=head2 resolve

Whether to end the progression with the tonic chord or not.

Default: C<1>

=head2 flat

Whether to use flats instead of sharps in the chords or not.

Default: C<0>

=head2 graph

The network transition graph.

Default: C<Graph::Directed>

=head2 verbose

Show the progress of the B<generate> method.

=head1 METHODS

=head2 new

  $prog = Music::Chord::Progression->new;
  $prog = Music::Chord::Progression->new(
    net        => { 1 => [...], ... },
    chords     => ['m','','m','m','',''],
    scale_name => 'minor',
    scale_note => 'A',
    octave     => 5,
  );

Create a new C<Music::Chord::Progression> object.

=head2 generate

Generate a new chord progression.

=head1 SEE ALSO

L<Data::Dumper::Compact>

L<Graph::Directed>

L<Moo>

L<Music::Chord::Note>

L<Music::Scales>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
