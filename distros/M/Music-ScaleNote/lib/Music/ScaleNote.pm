package Music::ScaleNote;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Manipulate the position of a note in a scale

our $VERSION = '0.0704';

use strictures 2;
use Carp qw(croak);
use List::Util qw( first );
use Moo;
use Music::Note ();
use Music::Scales qw(get_scale_notes);
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

    my $rev;  # Going in reverse?

    my $note = Music::Note->new( $name, $format );

    my $equiv;
    if ( $note->format('isobase') =~ /b/ || $note->format('isobase') =~ /#/ ) {
        $equiv = Music::Note->new( $name, $format );
        $equiv->en_eq( $note->format('isobase') =~ /b/ ? 'sharp' : 'flat' );
    }

    printf "Given note: %s, ISO: %s/%s, Offset: %d\n",
        $name, $note->format('ISO'), ( $equiv ? $equiv->format('ISO') : '' ), $offset
        if $self->verbose;

    my @scale = get_scale_notes( $self->scale_note, $self->scale_name );
    print "\tScale: @scale\n"
        if $self->verbose;

    if ( $offset < 0 ) {
        $rev++;
        $offset = abs $offset;
        @scale  = reverse @scale;
    }

    my $posn = first {
        ( $scale[$_] eq $note->format('isobase') )
        ||
        ( $equiv && $scale[$_] eq $equiv->format('isobase') )
    } 0 .. $#scale;

    if ( defined $posn ) {
        printf "\tPosition: %d\n", $posn
            if $self->verbose;
        $offset += $posn;
    }
    else {
        croak 'Scale position not defined!';
    }

    my $octave = $note->octave;
    my $factor = int( $offset / @scale );

    if ( $rev ) {
        $octave -= $factor;
    }
    else {
        $octave += $factor;
    }

    $note = Music::Note->new( $scale[ $offset % @scale ] . $octave, 'ISO' );

    if ( $flat && $note->format('isobase') =~ /#/ ) {
        $note->en_eq('flat');
    }

    printf "\tNew offset: %d, octave: %d, ISO: %s, Formatted: %s\n",
        $offset, $octave, $note->format('ISO'), $note->format($format)
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

    if ( $flat && $note->format('isobase') =~ /#/ ) {
        $note->en_eq('flat');
    }

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

version 0.0704

=head1 SYNOPSIS

  use Music::ScaleNote;

  my $msn = Music::ScaleNote->new(
    scale_note  => 'C',
    scale_name  => 'pminor',
    note_format => 'ISO',
    offset      => 1,
    verbose     => 1,
  );

  my $note = $msn->get_offset( note_name => 'C4' );
  print $note->format('ISO'), "\n"; # D#4

  $msn = Music::ScaleNote->new(
    scale_note => 'C',
    scale_name => 'major',
  );

  $note = $msn->get_offset(
    note_name   => 60,
    note_format => 'midinum',
    offset      => -1,
  );
  print $note->format('midinum'), "\n"; # 58

  $note = $msn->step(
    note_name => 'D3',
    steps     => -1,
    flat      => 1,
  );
  print $note->format('ISO'), "\n"; # Db3

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

Boolean indicating that we want a sharp resulting note flat instead.
This exchanges a sharp note for its enharmonic equivalent flat.

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

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
