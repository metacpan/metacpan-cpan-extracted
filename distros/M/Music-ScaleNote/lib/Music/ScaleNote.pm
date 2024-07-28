package Music::ScaleNote;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Manipulate the position of a note in a scale

our $VERSION = '0.0803';

use Moo;
use strictures 2;
use Carp qw(croak);
use Array::Circular ();
use List::SomeUtils qw( first_index );
use Music::Note ();
use Music::Scales qw( get_scale_notes );
use namespace::clean;


has scale_note => (
    is      => 'ro',
    default => sub { 'C' },
);


has scale_name => (
    is      => 'ro',
    default => sub { 'major' },
);


has note_format => (
    is      => 'ro',
    default => sub { 'ISO' },
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

    my $name   = $args{note_name};
    my $format = $args{note_format} || $self->note_format;
    my $offset = $args{offset} || $self->offset;
    my $flat   = $args{flat} || $self->flat;

    croak 'note_name, note_format or offset not provided'
        unless $name || $format || $offset;

    my $note = Music::Note->new( $name, $format );
    $note->en_eq('flat') if $flat && $note->format('isobase') =~ /#/;

    printf "Given note: %s, Format: %s, ISO: %s, Offset: %d\n",
        $name, $format, $note->format('ISO'), $offset
        if $self->verbose;

    my @scale = get_scale_notes( $self->scale_note, $self->scale_name );
    if ( $flat ) {
        for ( @scale ) {
            if ( $_ =~ /#/ ) {
                my $equiv = Music::Note->new( $_, $format );
                $equiv->en_eq('flat');
                $_ = $equiv->format('isobase');
            }
        }
    }
    print "\tScale: @scale\n"
        if $self->verbose;

    my $ac = Array::Circular->new( @scale );

    my $posn = first_index { $note->format('isobase') eq $_ } @scale;
    if ( $posn >= 0 ) {
        printf "\tPosition: %d\n", $posn
            if $self->verbose;
        $ac->index( $posn );
    }
    else {
        croak 'Scale position not defined!';
    }

    $ac->next( $offset );

    my $octave = $note->octave;
    $octave += $ac->loops;

    $note = Music::Note->new( $ac->current . $octave, 'ISO' );

    printf "\tOctave: %d, ISO: %s, Formatted: %s\n",
        $octave, $note->format('ISO'), $note->format($format)
        if $self->verbose;

    return $note;
}


sub step {
    my ( $self, %args ) = @_;

    my $name  = $args{note_name};
    my $steps = $args{steps} || 1;
    my $flat  = $args{flat} || $self->flat;

    croak 'note_name not provided'
        unless $name;

    my $note = Music::Note->new( $name, $self->note_format );
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

version 0.0803

=head1 SYNOPSIS

  use Music::ScaleNote;

  my $msn = Music::ScaleNote->new(
    scale_note  => 'C',
    scale_name  => 'pminor',
    note_format => 'ISO',
    offset      => 1,
    verbose     => 1,
  );

  my $note = $msn->get_offset(note_name => 'C4');
  say $note->format('ISO'); # D#4

  $msn = Music::ScaleNote->new(
    scale_note => 'C',
    scale_name => 'major',
  );

  $note = $msn->get_offset(
    note_name   => 60,
    note_format => 'midinum',
    offset      => -1,
  );
  say $note->format('midinum'); # 58

  $note = $msn->step(
    note_name => 'D3',
    steps     => -1,
    flat      => 1,
  );
  say $note->format('ISO'); # Db3

=head1 DESCRIPTION

A C<Music::ScaleNote> object manipulates the position of a note in a
scale.

Given a B<scale_name>, a B<scale_note>, a starting B<note_name>, the
B<note_format>, and a scale position B<offset>, the new note is
computed.

So for scale C<C D# F G A#> (C pentatonic minor), note name C<C4>
(in ISO format), and offset C<1> (move one scale step to the right),
the note C<D#4> is returned.

For an offset of C<-1>, the note C<A#3> is returned.

This module also provides a C<step> method that returns the new note a
given number of half-B<steps> away from a given B<note_name>.

=head1 ATTRIBUTES

=head2 scale_note

This is the isobase name of the note (with no octave) that starts the
scale.

Default: C<C>

Examples: C<G#>, C<Eb>

=head2 scale_name

This is the name of the scale to use.

Please see L<Music::Scales/SCALES> for the possibilities.

Default: C<major>

If the B<scale_name> is not recognized, the default is used.

=head2 note_format

The format as given by L<Music::Note/STYLES>.  If set in the
constructor, this is used in the B<get_offset> method.

Default: C<ISO>

If the B<note_format> is not recognized, the default is used.

This is used in conjunction with the B<note_name> to determine the
L<Music::Note> in the B<get_offset> method.

=head2 offset

The integer offset of a new scale position.  If set in the
constructor, this is used in the B<get_offset> method.

Default: C<1>

=head2 flat

Boolean indicating that we want only flat notes, not sharps.

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
    verbose     => $boolean,
    note_format => $format,
    offset      => $integer,
    flat        => $flat,
  );

Create a new C<Music::ScaleNote> object.

=head2 get_offset

  $note = $msn->get_offset( note_name => $note_name );

  $note = $msn->get_offset(  # Override defaults
    note_name   => $note_name,
    note_format => $format,
    offset      => $integer,
    flat        => $flat,
  );

Return a new L<Music::Note> object based on the required B<note_name>,
and optional B<note_format> and B<offset> parameters.

If the B<note_name> is not recognized, a default of C<C> is used.

For formats of C<isobase>, C<ISO> and C<midi>, the B<note_name> can be
given as a "bare note name" or a note-octave name.  But for the
C<midinum> format, the B<note_name> must be given as a MIDI note
number.

Be aware that if the B<note_name> is given as a "bare note" (with no
octave), and the B<format> is C<ISO>, the octave returned will be C<4>
by default.  For B<format> of C<midinum> and the B<note_name> being a
letter, a nonsensical result will be returned.  This mixing up of
format and note name is B<not> how to use this module.

=head2 step

  $note = $msn->step( note_name => $note_name );

  $note = $msn->step(
    note_name => $note_name,
    steps     => $halfsteps,
    flat      => $flat,
  );

Return a new L<Music::Note> object based on the required B<note_name>
and number of half-B<steps> - either a positive or negative integer.

Default steps: 1

=head1 SEE ALSO

The F<t/01-methods.t> file in this distribution.

L<List::Util>

L<Moo>

L<Music::Note>

L<Music::Scales>

Example usage:

L<https://github.com/ology/Music/blob/master/hilbert-notes>

L<https://github.com/ology/Music/blob/master/lindenmayer-midi>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2024 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
