package Music::GuitarChordDiagram;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Draw Guitar Chord Diagrams

our $VERSION = '0.0200';

use Moo;
use strictures 2;
use namespace::clean;

use Imager;
use Music::Chord::Namer 'chordname';


has chord => (
    is => 'rw',
);


has position => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a positive integer" unless $_[0] =~ /^[1-9]\d*$/ },
    default => sub { 1 },
);


has string_num => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a positive integer" unless $_[0] =~ /^[1-9]\d*$/ },
    default => sub { 6 },
);


has fret_num => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a positive integer" unless $_[0] =~ /^[1-9]\d*$/ },
    default => sub { 5 },
);


has size => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a positive integer" unless $_[0] =~ /^[1-9]\d*$/ },
    default => sub { 30 },
);


has outfile => (
    is      => 'ro',
    default => sub { 'chord-diagram' },
);


has font => (
    is      => 'ro',
    default => sub { '/opt/X11/share/fonts/TTF/VeraMono.ttf' },
);


has notes => (
    is      => 'ro',
    default => sub {
        {
            1 => [qw/E F  Gb G  Ab A Bb B  C  Db D Eb/],
            2 => [qw/B C  Db D  Eb E F  Gb G  Ab A Bb/],
            3 => [qw/G Ab A  Bb B  C Db D  Eb E  F Gb/],
            4 => [qw/D Eb E  F  Gb G Ab A  Bb B  C Db/],
            5 => [qw/A Bb B  C  Db D Eb E  F  Gb G Ab/],
            6 => [qw/E F  Gb G  Ab A Bb B  C  Db D Eb/],
        }
    },
);


has verbose => (
    is      => 'ro',
    default => sub { 0 },
);


sub draw {
    my ($self) = @_;

    my $WHITE = 'white';
    my $BLUE  = 'blue';
    my $BLACK = 'black';
    my $SPACE = $self->size;

    my @chord;

    # Setup a new image
    my $i = Imager->new(
        xsize => $SPACE + $self->string_num * $SPACE - $self->string_num,
        ysize => $SPACE + $self->fret_num * $SPACE - $self->fret_num,
    );
    my $font = Imager::Font->new( file => $self->font );
    $i->box( filled => 1, color => $WHITE );

    # Draw the vertical string lines
    for my $string (0 .. $self->string_num - 1) {
        $i->line(
            color => $BLUE,
            x1    => $SPACE + $string * $SPACE,
            y1    => $SPACE,
            x2    => $SPACE + $string * $SPACE,
            y2    => $SPACE + ($self->fret_num - 1) * $SPACE,
            aa    => 1,
            endp  => 1
        );
    }
 
    # Draw the horizontal fret lines
    for my $fret ( 0 .. $self->fret_num - 1 ) {
        $i->line(
            color => $BLUE,
            x1    => $SPACE,
            y1    => $SPACE + $fret * $SPACE,
            x2    => $SPACE + ($self->string_num - 1) * $SPACE,
            y2    => $SPACE + $fret * $SPACE,
            aa    => 1,
            endp  => 1
        );

        # Indicate the neck position
        if ( $fret == 1 ) {
            $i->string(
                font  => $font,
                text  => $self->position,
                color => $BLACK,
                x     => $SPACE / 2,
                y     => $SPACE * 2 + $SPACE / 4,
                size  => $SPACE / 2,
                aa    => 1,
            );
        }
    }

    # Draw the note/mute markers
    my $string = $self->string_num;

    for my $note ( split //, $self->chord ) {
        if ( $note =~ /[xX]/ ) {
            print "X at 0,$string\n" if $self->verbose;

            $i->string(
                font  => $font,
                text  => 'X',
                color => $BLACK,
                x     => $SPACE + ($self->string_num - $string) * $SPACE - $SPACE / 6,
                y     => $SPACE - 2,
                size  => $SPACE / 2,
                aa    => 1,
            );
        }
        elsif ( $note =~ /[oO0]/ ) {
            my $temp = $self->notes->{$string}[0];
            push @chord, $temp;
            print "O at 0,$string = $temp\n" if $self->verbose;

            $i->string(
                font  => $font,
                text  => 'O',
                color => $BLACK,
                x     => $SPACE + ($self->string_num - $string) * $SPACE - $SPACE / 6,
                y     => $SPACE - 2,
                size  => $SPACE / 2,
                aa    => 1,
            );
        }
        else {
            my $temp = $self->notes->{$string}[$self->position + $note - 1];
            push @chord, $temp;
            print "Dot at $note,$string = $temp\n" if $self->verbose;

            $i->circle(
                color => $BLACK,
                r     => $SPACE / 5,
                x     => $SPACE + ($self->string_num - $string) * $SPACE,
                y     => $SPACE + $SPACE / 2 + ($note - 1) * $SPACE,
            );
        }

        # Decrement the current string number
        $string--;
    }

    # Print the chord name
    $i->string(
        font  => $font,
        text  => scalar(chordname(@chord)),
        color => $BLACK,
        x     => $SPACE,
        y     => $SPACE + $self->fret_num * $SPACE - $self->fret_num - $SPACE / 4,
        size  => $SPACE / 2,
        aa    => 1,
    );

    # Output the image
    my $type = 'png';
    my $name = $self->outfile . '.' . $type;
    $i->write( type => $type, file => $name )
        or die "Can't save $name: ", $i->errstr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::GuitarChordDiagram - Draw Guitar Chord Diagrams

=head1 VERSION

version 0.0200

=head1 SYNOPSIS

  use Music::GuitarChordDiagram;

  my $dia = Music::GuitarChordDiagram->new(
    chord      => 'x02220',
    position   => 1,
    string_num => 6,
    fret_num   => 5,
    size       => 30,
    outfile    => 'chord-diagram',
    font       => '/path/to/TTF/font.ttf',
    notes      => { 1 => [qw/D Eb E F .../], 2 => [qw/.../], },
    verbose    => 1,
  );

  $dia->draw();

=head1 DESCRIPTION

A C<Music::GuitarChordDiagram> object draws guitar chord diagrams including neck
position and chord name annotations.

=for html <br><img src="https://raw.githubusercontent.com/ology/Music-GuitarChordDiagram/master/chord-diagram.png"><br>

=head1 ATTRIBUTES

=head2 chord

  $dia->chord('xx0232');
  $chord = $dia->chord;

A guitar chord given in string format, where non-zero digits represent
frets, C<x> (or C<X>) indicates a muted string and C<0> (or C<o> or C<O>)
indicates an open string.  The order of the strings is C<654321> from lowest to
highest.

Examples:

  c: x32010
  d: xxO232
  e: 022100
  f: xx3211
  g: 210002
  a: x02220
  b: xx4442
 
  cm: xx5543
  dm: xx0231
  em: 022000
  fm: xx3111
  gm: xx5333
  am: x02210
  bm: xx4432
 
  c7: x32310
  d7: xx0212
  e7: 020100
  f7: xx1211
  g7: 320001
  a7: x02020
  b7: x21202

=head2 position

  $position = $dia->position;

The neck position of a chord to be diagrammed.  This number is rendered to the
left of the first fret.

Default: 1

=head2 string_num

  $string_num = $dia->string_num;

The number of strings.

Default: 6

=head2 fret_num

  $fret_num = $dia->fret_num;

The number of frets.

Default: 5

=head2 size

  $size = $dia->size;

The relative size of the diagram.

Default: 30

=head2 outfile

  $outfile = $dia->outfile;

The image file name minus the (PNG) extension.

Default: chord-diagram

=head2 font

  $font = $dia->font;

The TTF font to use when rendering the diagram.

Default: /opt/X11/share/fonts/TTF/VeraMono.ttf

=head2 notes

  $notes = $dia->notes;

A hashref of string keys and note list values to use in computing the chord.

Default:

  1 => [ E F  Gb G  Ab A Bb B  C  Db D Eb ]
  2 => [ B C  Db D  Eb E F  Gb G  Ab A Bb ]
  3 => [ G Ab A  Bb B  C Db D  Eb E  F Gb ]
  4 => [ D Eb E  F  Gb G Ab A  Bb B  C Db ]
  5 => [ A Bb B  C  Db D Eb E  F  Gb G Ab ]
  6 => [ E F  Gb G  Ab A Bb B  C  Db D Eb ]

=head2 verbose

  $verbose = $dia->verbose;

Monitor the progress of the diagram construction.

Default: 0

=head1 METHODS

=head2 new()

  $dia = Music::GuitarChordDiagram->new(%arguments);

Create a new C<Music::GuitarChordDiagram> object.

=head2 draw()

  $dia->draw;

Render the requested chord diagram as a PNG image.

=head1 SEE ALSO

L<Imager>

L<Moo>

L<Music::Chord::Namer>

Similar modules:

L<Music::Image::Chord>

L<GD::Tab::Guitar>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
