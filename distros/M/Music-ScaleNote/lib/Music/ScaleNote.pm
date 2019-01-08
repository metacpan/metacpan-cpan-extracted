package Music::ScaleNote;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Manipulate the position of a note in a scale

our $VERSION = '0.0500';

use Carp;
use Moo;
use strictures 2;
use namespace::clean;

use List::Util qw( first );
use Music::Note;
use Music::Scales;


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


has verbose => (
    is      => 'ro',
    default => sub { 0 },
);


sub get_offset {
    my ( $self, %args ) = @_;

    $args{note_format} ||= $self->note_format;
    $args{offset}      ||= $self->offset;

    croak 'note_name, note_format or offset not provided'
        unless $args{note_name} || $args{note_format} || $args{offset};

    my $rev;  # Going in reverse?

    my $note = Music::Note->new( $args{note_name}, $args{note_format} );

    my $equiv;
    if ( $note->format('isobase') =~ /b/ || $note->format('isobase') =~ /#/ ) {
        $equiv = Music::Note->new( $args{note_name}, $args{note_format} );
        $equiv->en_eq( $note->format('isobase') =~ /b/ ? 'sharp' : 'flat' );
    }

    warn sprintf "Given note: %s, ISO: %s/%s, Offset: %d\n",
        $args{note_name}, $note->format('ISO'), ( $equiv ? $equiv->format('ISO') : '' ), $args{offset}
        if $self->verbose;

    my @scale = get_scale_notes( $self->scale_note, $self->scale_name );
    warn "\tScale: @scale\n"
        if $self->verbose;

    if ( $args{offset} < 0 ) {
        $rev++;
        $args{offset} = abs $args{offset};
        @scale  = reverse @scale;
    }

    my $posn = first {
        ( $scale[$_] eq $note->format('isobase') )
        ||
        ( $equiv && $scale[$_] eq $equiv->format('isobase') )
    } 0 .. $#scale;

    if ( defined $posn ) {
        warn sprintf "\tPosition: %d\n", $posn
            if $self->verbose;
        $args{offset} += $posn;
    }
    else {
        warn "Scale position not defined!\n";
    }

    my $octave = $note->octave;
    my $factor = int( $args{offset} / @scale );

    if ( $rev ) {
        $octave -= $factor;
    }
    else {
        $octave += $factor;
    }

    $note = Music::Note->new( $scale[ $args{offset} % @scale ] . $octave, 'ISO' );

    warn sprintf "\tNew offset: %d, ISO: %s, Formatted: %s\n",
        $args{offset}, $note->format('ISO'), $note->format( $args{note_format} )
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

version 0.0500

=head1 SYNOPSIS

  use Music::ScaleNote;
  use Music::Note;

  my $msn = Music::ScaleNote->new(
    scale_note => 'C',
    scale_name => 'pminor',
    verbose    => 1,
  );

  my $note = $msn->get_offset( note_name => 'C4' );

  print $note->format('ISO'), "\n"; # D#4

=head1 DESCRIPTION

A C<Music::ScaleNote> object manipulates the position of a note in a scale.

Given a B<scale_name>, a B<scale_note>, a starting B<note_name>, the
B<note_format>, and a scale position B<offset>, this module computes the new
note.

So for scale C<C D# F G A#> (C pentatonic minor), note name C<C4> (given the
ISO format), and offset C<1> (move one note to the right), this module will
return C<D#4>.

For offset C<-1>, C<A#3> is returned.

The B<note_format> determines how the B<note_name> is given, and the default is
C<ISO>.

=head1 ATTRIBUTES

=head2 scale_note

This is the name of the note that starts the given scale.

Default: C<C>

=head2 scale_name

This is the name of the scale to use.

Please see L<Music::Scales/SCALES> for the possible names.

Default: C<major>

=head2 note_format

The format as given by L<Music::Note/STYLES>.  If given in the constructor, this
is used as the default in the B<get_offset> method.

Default: C<ISO>

=head2 offset

The integer offset of a new scale position.  If given in the constructor, this
is used as the default in the B<get_offset> method.

Default: C<1>

=head2 verbose

Show the progress of the B<get_offset> method.

Default: C<0>

=head1 METHODS

=head2 new()

  $msn = Music::ScaleNote->new(
    scale_note  => $scale_start_note,
    scale_name  => $scale_name,
    verbose     => $boolean,
    note_format => $format,
    offset      => $integer,
  );

Create a new C<Music::ScaleNote> object.

=head2 get_offset()

  $note = $msn->get_offset(
    note_name   => $formatted_note_name,
    note_format => $format,
    offset      => $integer,
  );

Return a new L<Music::Note> object based on the given B<note_name>,
B<note_format> and B<offset>.

=head1 SEE ALSO

L<Moo>

L<List::Util>

L<Music::Note>

L<Music::Scales>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
