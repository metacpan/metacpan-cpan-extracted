package Music::ScaleNote;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Manipulate the position of a note in a scale

our $VERSION = '0.0905';

use Moo;
use strictures 2;
use Carp qw(croak);
# use Data::Dumper::Compact qw( ddc );
use List::SomeUtils qw( first_index );
use MIDI::Util qw(midi_format);
use Music::Note ();
use Music::Scales qw( get_scale_nums );
use namespace::clean;


has scale_note => (
    is      => 'ro',
    default => sub { 'C' },
);


has scale_name => (
    is      => 'ro',
    default => sub { 'major' },
);

has _scale => (
    is      => 'lazy',
    builder => '_build__scale',
);
sub _build__scale {
    my ($self) = @_;
    my @base = get_scale_nums( $self->scale_name );
    my @scale;
    for my $i (0 .. 10) {
        for my $degree (@base) {
            push @scale, $degree + ($i * 12)
        }
    }
    print "@scale\n" if $self->verbose;
    return \@scale;
}


has note_format => (
    is      => 'ro',
    default => sub { 'midinum' },
);


has offset => (
    is      => 'ro',
    isa     => sub { die 'Not a negative or positive integer' unless $_[0] =~ /^-?\d+$/ },
    default => sub { 1 },
);


has flat => (
    is      => 'ro',
    default => sub { 0 },
);


has verbose => (
    is      => 'ro',
    default => sub { 0 },
);


sub get_offset {
    my ( $self, %args ) = @_;

    my $name   = $args{note_name}   || $self->scale_note;
    my $format = $args{note_format} || $self->note_format;
    my $offset = $args{offset}      || $self->offset;
    my $flat   = $args{flat}        || $self->flat;

    croak 'note_name, note_format or offset not provided'
        unless $name || $format || $offset;

    my $note = Music::Note->new( $name, $format );

    croak "Note not defined for $name and $format!" unless $note->format($format) eq $name;

    my $octave = $note->octave;

    $note->en_eq('flat') if $flat && $note->format('isobase') =~ /#/;

    printf "Given note: %s, Format: %s, ISO: %s, Offset: %d\n",
        $name, $format, $note->format('ISO'), $offset
        if $self->verbose;

    my $posn = first_index { $note->format('midinum') == $_ } @{ $self->_scale };
    if ( $posn >= 0 ) {
        printf "\tPosition: %d, Offset position: %d\n", $posn, $posn + $offset
            if $self->verbose;
    }
    else {
        croak 'Scale position not defined!';
    }

    my $n = $self->_scale->[ $posn + $offset ];
    $note = Music::Note->new( $n, 'midinum' );

    $note->en_eq('flat') if $flat && $note->format('ISO') =~ /#/;

    printf "\tOctave: %d, ISO: %s, Formatted: %s\n",
        $octave, $note->format('ISO'), $note->format($format)
        if $self->verbose;

    return $note;
}


sub step {
    my ( $self, %args ) = @_;

    my $name   = $args{note_name}   || $self->scale_note;
    my $format = $args{note_format} || $self->note_format;
    my $steps  = $args{steps}       || 1;
    my $flat   = $args{flat}        || $self->flat;

    my $note = Music::Note->new( $name, $format );
    my $num  = $note->format('midinum');

    printf "Given note: %s, ISO: %s, Formatted: %d\n",
        $name, $note->format('ISO'), $num
        if $self->verbose;

    $num += $steps;
    $note = Music::Note->new( $num, 'midinum' );
    $note->en_eq('flat') if $flat && $note->format('isobase') =~ /#/;

    printf "\tNew steps: %d, ISO: %s, Formatted: %s\n",
        $steps, $note->format('ISO'), $note->format( $self->note_format )
        if $self->verbose;

    return $note;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::ScaleNote - Manipulate the position of a note in a scale

=head1 VERSION

version 0.0905

=head1 SYNOPSIS

  use Music::ScaleNote;

  my $msn = Music::ScaleNote->new(
    scale_note  => 'C',
    scale_name  => 'major',
    note_format => 'isobase',
  );
  my $note = $msn->get_offset; # using defaults
  print $note->format('ISO'), "\n"; # D4

  $msn = Music::ScaleNote->new( scale_note => 60 );
  $note = $msn->get_offset;
  print $note->format('midinum'), "\n"; # 62

  $note = $msn->get_offset(
    note_name => $note->format('midinum'),
    offset    => -1,
  );
  print $note->format('midinum'), "\n"; # 60

  $note = $msn->get_offset(
    note_name => $note->format('midinum'),
    offset    => -2,
  );
  print $note->format('midinum'), "\n"; # 57

  $note = $msn->step(
    note_name   => 'Eb3',
    note_format => 'ISO',
    steps       => -2,
    flat        => 1,
  );
  print $note->format('ISO'), "\n"; # Db3

=head1 DESCRIPTION

A C<Music::ScaleNote> object manipulates the position of a note in a
scale. Its methods return a L<Music::Note> object.

Given a B<scale_name>, a B<scale_note>, a starting B<note_name>, the
B<note_format>, and a scale position B<offset>, the new note is
computed.

So for scale C<C D# F G A#> (C pentatonic minor), note name C<C4>
(in ISO format), and offset C<1> (move one scale step to the right),
the note C<D#4> is returned. For an offset of C<-1>, the note C<A#3>
is returned.

This module also provides a C<step> method that returns the new note a
given number of half-B<steps> away from a given B<note_name>.

=head1 ATTRIBUTES

=head2 scale_note

This is the C<isobase> name of the note (with no octave) that starts
the scale.

Default: C<C>

Examples: C<D>, C<G#>, C<Eb>

=head2 scale_name

This is the name of the scale to use.

Please see L<Music::Scales/SCALES> for the possibilities.

Default: C<major>

=head2 note_format

This is used to tell the module what the type of B<scale_note> is.

Please see the formats in L<Music::Note/STYLES>. This is used in the
B<get_offset()> method.

Default: C<midinum>

=head2 offset

The integer offset of a new scale position.  If set in the
constructor, this is used in the B<get_offset()> method.

Default: C<1>

=head2 flat

Boolean indicating that we want only flat notes, not sharps, if the
B<note_format> is set to anything other than C<midinum>.

Default: C<0>

=head2 verbose

Show the progress of the B<get_offset> method.

Default: C<0>

=head1 METHODS

=head2 new

  $msn = Music::ScaleNote->new;  # Use defaults
  $msn = Music::ScaleNote->new(  # Override defaults
    scale_note  => $scale_start_note,
    scale_name  => $scale_name,
    note_format => $format,
    offset      => $integer,
    flat        => $flat,
    verbose     => $boolean,
  );

Create a new C<Music::ScaleNote> object.

=head2 get_offset

  $note = $msn->get_offset;
  $note = $msn->get_offset( # Override defaults
    note_name   => $note_name,
    note_format => $format,
    offset      => $integer,
    flat        => $flat,
  );

Return a new L<Music::Note> object based on the optional B<note_name>,
B<note_format>, and B<offset> parameters.

If the B<note_name> is not recognized, a default of C<60> (middle-C)
is used.

=head2 step

  $note = $msn->step( note_name => $note_name );

  $note = $msn->step(
    note_name => $note_name,
    steps     => $halfsteps,
    flat      => $flat,
  );

Return a new L<Music::Note> object based on the B<note_name> and
number of half-B<steps> - either a positive or negative integer.

Default step: C<1>

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*.pl> files in this distribution.

L<List::SomeUtils>

L<MIDI::Util>

L<Moo>

L<Music::Note>

L<Music::Scales>

Example usage:

L<https://github.com/ology/Music/blob/master/hilbert-notes>

L<https://github.com/ology/Music/blob/master/lindenmayer-midi>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
