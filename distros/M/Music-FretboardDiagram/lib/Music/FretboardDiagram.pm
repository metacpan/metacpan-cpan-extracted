package Music::FretboardDiagram;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Draw fretboard chord diagrams

our $VERSION = '0.1313';

use Moo;
use strictures 2;
use namespace::clean;

use Carp 'croak';
use Imager ();
use List::SomeUtils 'first_index';
use Music::Chord::Namer 'chordname';

use constant WHITE => 'white';
use constant BLACK => 'black';
use constant TAN   => 'tan';


has chord => (
    is => 'rw',
);


has position => (
    is      => 'rw',
    isa     => \&_positive_int,
    default => sub { 1 },
);


has absolute => (
    is      => 'ro',
    isa     => \&_boolean,
    default => sub { 0 },
);


has strings => (
    is      => 'ro',
    isa     => \&_positive_int,
    default => sub { 6 },
);


has frets => (
    is      => 'ro',
    isa     => \&_positive_int,
    default => sub { 5 },
);


has size => (
    is      => 'ro',
    isa     => \&_positive_int,
    default => sub { 30 },
);


has outfile => (
    is      => 'rw',
    default => sub { 'chord-diagram' },
);


has type => (
    is      => 'ro',
    default => sub { 'png' },
);


has font => (
    is      => 'ro',
    default => sub { '/usr/share/fonts/truetype/freefont/FreeMono.ttf' },
);


has tuning => (
    is      => 'ro',
    default => sub { [qw/E B G D A E/] },
);


has horiz => (
    is      => 'ro',
    isa     => \&_boolean,
    default => sub { 0 },
);


has image => (
    is      => 'ro',
    isa     => \&_boolean,
    default => sub { 0 },
);


has string_color => (
    is      => 'ro',
    default => sub { 'blue' },
);


has fret_color => (
    is      => 'ro',
    default => sub { 'darkgray' },
);


has dot_color => (
    is      => 'ro',
    default => sub { 'black' },
);


has showname => (
    is      => 'rw',
    default => sub { 1 },
);


has verbose => (
    is      => 'ro',
    isa     => \&_boolean,
    default => sub { 0 },
);


has fretboard => (
    is       => 'ro',
    init_arg => undef,
);


sub BUILD {
    my ( $self, $args ) = @_;

    $self->chord( [ [ $self->position, $self->chord ] ] )
        unless ref $self->chord;

    croak 'chord length and string number differ'
        if $self->chord && length( $self->chord->[0][1] ) != $self->strings;

    my @scale = qw/C Db D Eb E F Gb G Ab A Bb B/;

    # Make a scale position index corresponding to the given tuning
    my @index = map { my $t = $_; first_index { $t eq $_ } @scale } @{ $self->tuning };

    my %notes;

    my $string = 0;
    for my $i ( @index ) {
        # Make a scale note list for the string
        $notes{++$string} = [ map { $scale[ ($i + $_) % @scale ] } 0 .. @scale - 1 ];
    }

    $self->{fretboard} = \%notes;
}


sub draw {
    my ($self) = @_;

    if ( $self->horiz ) {
        return $self->_draw_horiz;
    }

    my $SPACE = $self->size;

    my $frets = $self->frets + 1;
    my $font;

    # Setup a new image
    my $i = Imager->new(
        xsize => $SPACE + $self->strings * $SPACE,
        ysize => $SPACE + $frets * $SPACE,
    );
    $i->box( filled => 1, color => WHITE );

    if ( -e $self->font ) {
        $font = Imager::Font->new( file => $self->font );
    }
    else {
        warn 'WARNING: Font ', $self->font, " not found\n";
    }

    # Draw the horizontal fret lines
    for my $fret ( 0 .. $frets - 1 ) {
        $i->line(
            color => $self->fret_color,
            x1    => $SPACE,
            y1    => $SPACE + $fret * $SPACE,
            x2    => $SPACE + ($self->strings - 1) * $SPACE,
            y2    => $SPACE + $fret * $SPACE,
            aa    => 1,
            endp  => 1
        );

        # Indicate the neck position
        if ( $fret == 1 ) {
            $i->string(
                font  => $font,
                text  => $self->position,
                color => BLACK,
                x     => $SPACE / 4,
                y     => $SPACE * 2 + $SPACE / 4,
                size  => $SPACE / 2,
                aa    => 1,
            );
        }

        if ( $self->_fret_match($fret) ) {
            $i->circle(
                color => TAN,
                r     => $SPACE / 8,
                x     => $SPACE * $self->strings / 2 + $SPACE / 2,
                y     => $SPACE + $fret * $SPACE + $SPACE / 2,
            ) if ( $SPACE + $fret * $SPACE + $SPACE / 2 ) < ( $SPACE * $frets );
        }
    }

    # Draw the vertical string lines
    for my $string ( 0 .. $self->strings - 1 ) {
        $i->line(
            color => $self->string_color,
            x1    => $SPACE + $string * $SPACE,
            y1    => $SPACE,
            x2    => $SPACE + $string * $SPACE,
            y2    => $SPACE + ($frets - 1) * $SPACE,
            aa    => 1,
            endp  => 1
        );
    }

    for my $spec ( @{ $self->chord } ) {
        my ( $posn, $chord ) = @$spec;

        my @chord;

        # Draw the note/mute markers
        my $string = $self->strings;
        for my $note ( split //, $chord ) {
            if ( $note =~ /-/ ) {
                $string--;
                next;
            }

            if ( $note =~ /[xX]/ ) {
                warn "X at 0,$string\n" if $self->verbose;

                $i->string(
                    font  => $font,
                    text  => 'X',
                    color => BLACK,
                    x     => $SPACE + ($self->strings - $string) * $SPACE - $SPACE / 6,
                    y     => $SPACE - 2,
                    size  => $SPACE / 2,
                    aa    => 1,
                );
            }
            elsif ( $note =~ /[oO0]/ ) {
                my $temp = $self->fretboard->{$string}[0];
                push @chord, $temp;

                warn "O at 0,$string = $temp\n" if $self->verbose;

                $i->string(
                    font  => $font,
                    text  => 'O',
                    color => BLACK,
                    x     => $SPACE + ($self->strings - $string) * $SPACE - $SPACE / 6,
                    y     => $SPACE - 2,
                    size  => $SPACE / 2,
                    aa    => 1,
                );
            }
            else {
                my $temp = $self->_note_at($string, $note);
                push @chord, $temp;

                warn "Dot at $note,$string = $temp\n" if $self->verbose;

                my $y = $self->absolute
                    ? $SPACE + $SPACE / 2 + ($posn - 1 + $note - 1) * $SPACE
                    : $SPACE + $SPACE / 2 + ($note - 1) * $SPACE;

                $i->circle(
                    color => $self->dot_color,
                    r     => $SPACE / 5,
                    x     => $SPACE + ($self->strings - $string) * $SPACE,
                    y     => $y,
                ) if $y >= $SPACE && $y <= $SPACE * $frets;
            }

            # Decrement the current string number
            $string--;
        }

        # Print the chord name if requested
        if ( $self->showname ) {
            my $chord_name = $self->showname eq '1' ? chordname(@chord) : $self->showname;
            warn "Chord = $chord_name\n" if $self->verbose;
            $i->string(
                font  => $font,
                text  => $chord_name,
                color => BLACK,
                x     => $SPACE,
                y     => ($frets + 1) * $SPACE - $SPACE / 3,
                size  => $SPACE / 2,
                aa    => 1,
            );
        }
    }

    if ( $self->image ) {
        return $i;
    }
    else {
        $self->_output_image($i);
    }
}

sub _draw_horiz {
    my ($self) = @_;

    my $SPACE = $self->size;

    my $frets = $self->frets + 1;
    my $font;

    # Setup a new image
    my $i = Imager->new(
        ysize => $SPACE + $self->strings * $SPACE,
        xsize => $SPACE + $frets * $SPACE,
    );
    $i->box( filled => 1, color => WHITE );

    if ( -e $self->font ) {
        $font = Imager::Font->new( file => $self->font );
    }
    else {
        warn 'WARNING: Font ', $self->font, " not found\n";
    }

    # Draw the vertical fret lines
    for my $fret ( 0 .. $frets - 1 ) {
        $i->line(
            color => $self->fret_color,
            y1    => $SPACE,
            x1    => $SPACE + $fret * $SPACE,
            y2    => $SPACE + ($self->strings - 1) * $SPACE,
            x2    => $SPACE + $fret * $SPACE,
            aa    => 1,
            endp  => 1
        );

        # Indicate the neck position
        if ( $fret == 1 ) {
            $i->string(
                font  => $font,
                text  => $self->position,
                color => BLACK,
                y     => $SPACE / 2 + $SPACE / 5,
                x     => $SPACE * 2 - $SPACE / 5,
                size  => $SPACE / 2,
                aa    => 1,
            );
        }

        if ( $self->_fret_match($fret) ) {
            $i->circle(
                color => TAN,
                r     => $SPACE / 8,
                y     => $SPACE * $self->strings / 2 + $SPACE / 2,
                x     => $SPACE + $fret * $SPACE + $SPACE / 2,
            ) if ( $SPACE + $fret * $SPACE + $SPACE / 2 ) < ( $SPACE * $frets );
        }
    }

    # Draw the horizontal string lines
    for my $string ( 0 .. $self->strings - 1 ) {
        $i->line(
            color => $self->string_color,
            y1    => $SPACE + $string * $SPACE,
            x1    => $SPACE,
            y2    => $SPACE + $string * $SPACE,
            x2    => $SPACE + ($frets - 1) * $SPACE,
            aa    => 1,
            endp  => 1
        );
    }

    for my $spec ( @{ $self->chord } ) {
        my ( $posn, $chord ) = @$spec;

        my @chord;

        # Draw the note/mute markers
        my $string = 1;
        for my $note ( reverse split //, $chord ) {
            if ( $note =~ /-/ ) {
                $string++;
                next;
            }

            if ( $note =~ /[xX]/ ) {
                warn "X at fret:0, string:$string\n" if $self->verbose;

                $i->string(
                    font  => $font,
                    text  => 'X',
                    color => BLACK,
                    y     => $SPACE + ($string - 1) * $SPACE + $SPACE / 4,
                    x     => $SPACE - $SPACE / 2,
                    size  => $SPACE / 2,
                    aa    => 1,
                );
            }
            elsif ( $note =~ /[oO0]/ ) {
                my $temp = $self->fretboard->{$string}[0];
                unshift @chord, $temp;

                warn "O at fret:0, string:$string = $temp\n" if $self->verbose;

                $i->string(
                    font  => $font,
                    text  => 'O',
                    color => BLACK,
                    y     => $SPACE + ($string - 1) * $SPACE + $SPACE / 4,
                    x     => $SPACE - $SPACE / 2,
                    size  => $SPACE / 2,
                    aa    => 1,
                );
            }
            else {
                my $temp = $self->_note_at($string, $note);
                unshift @chord, $temp;

                warn "Dot at fret:$note, string:$string = $temp\n" if $self->verbose;

                my $x = $self->absolute
                    ? $SPACE + $SPACE / 2 + ($posn - 1 + $note - 1) * $SPACE
                    : $SPACE + $SPACE / 2 + ($note - 1) * $SPACE;

                $i->circle(
                    color => $self->dot_color,
                    r     => $SPACE / 5,
                    x     => $x,
                    y     => $SPACE + ($string - 1) * $SPACE,
                ) if $x >= $SPACE && $x <= $SPACE * $frets;
            }

            # Increment the current string number
            $string++;
        }

        # Print the chord name if requested
        if ( $self->showname ) {
            my $chord_name = $self->showname eq '1' ? chordname(@chord) : $self->showname;
            warn "Chord = $chord_name\n" if $self->verbose;
            $i->string(
                font  => $font,
                text  => $chord_name,
                color => BLACK,
                x     => $SPACE,
                y     => ($self->strings + 1) * $SPACE - $SPACE / 3,
                size  => $SPACE / 2,
                aa    => 1,
            );
        }
    }

    if ( $self->image ) {
        return $i;
    }
    else {
        $self->_output_image($i);
    }
}

sub _fret_match {
    my ($self, $fret) = @_;
    return ( $self->position + $fret == 3 )
        || ( $self->position + $fret == 5 )
        || ( $self->position + $fret == 7 )
        || ( $self->position + $fret == 9 )
        || ( $self->position + $fret == 12 )
        || ( $self->position + $fret == 15 )
        || ( $self->position + $fret == 17 )
        || ( $self->position + $fret == 19 )
        || ( $self->position + $fret == 21 )
        || ( $self->position + $fret == 24 );
}

sub _note_at {
    my ($self, $string, $n) = @_;
    return $self->fretboard->{$string}[ ($self->position + $n - 1) % @{ $self->fretboard->{1} } ];
}

sub _output_image {
    my ($self, $img) = @_;
    my $name = $self->outfile . '.' . $self->type;
    $img->write( type => $self->type, file => $name )
        or croak "Can't save $name: ", $img->errstr;
}

sub _positive_int {
    my ($arg) = @_;
    croak "$arg is not a positive integer" unless $arg =~ /^[1-9]\d*$/;
}

sub _boolean {
    my ($arg) = @_;
    croak "$arg is not a Boolean value" unless $arg =~ /^[10]$/;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Music::FretboardDiagram - Draw fretboard chord diagrams

=head1 VERSION

version 0.1313

=head1 SYNOPSIS

  use Music::FretboardDiagram;

  my $dia = Music::FretboardDiagram->new(
    chord    => 'xx0232',
    frets    => 5,     # the default
    position => 1,     # the default
    outfile  => 'Dmajor',
    type     => 'png', # the default
  );

  $dia = Music::FretboardDiagram->new(
    chord    => [[1,'022000'], [2,'--1342'], [7,'-13321']], # Em chords
    frets    => 13,
    absolute => 1,
    size     => 50, # relative units, not pixels
    horiz    => 1,
    showname => 'Em',
    outfile  => 'fretboard',
    font     => '/path/to/TTF/font.ttf',
    verbose  => 1,
  );

  $dia->chord('x02220');          # set a new chord
  $dia->position(7);              # set a new position
  $dia->outfile('mystery-chord'); # set a new filename
  $dia->showname('Xb dim');       # "X flat diminished"

  $dia->draw;

=head1 DESCRIPTION

A C<Music::FretboardDiagram> object draws fretboard chord diagrams
including neck position and chord name annotations for guitar,
ukulele, banjo, etc.

=for html Here are examples of a vertical guitar diagram and a horizontal
ukulele diagram:
<br>
<img src="https://raw.githubusercontent.com/ology/Music-FretboardDiagram/master/chord-diagram.png">
<img src="https://raw.githubusercontent.com/ology/Music-FretboardDiagram/master/ukulele.png">
<br>

=head1 ATTRIBUTES

=head2 chord

  $dia->chord('xx0232');
  $dia->chord([[1,'022000'], [2,'--1342'], [7,'-13321']]);
  $chord = $dia->chord;

A required chord given as a string or array reference of
specifications.

For a chord string, non-zero digits represent frets, C<x> (or C<X>)
indicates a muted string, C<0> (or C<o> or C<O>) indicates an open
string, and a dash (C<->) means skip to the next string.

For an array-ref of chord specifications, the first element is the
chord position, and the second is the chord string.

Chord string examples at position 1:

  C: x32010
  D: xx0232
  E: 022100
  F: xx3211
  G: 320003
  A: x02220
  B: x24442

  Cm: x3101x
  Dm: xx0231
  Em: 022000
  Am: x02210

  C7: x32310
  D7: xx0212
  E7: 020100
  G7: 320001
  A7: x02020
  B7: x21202

  etc.

=head2 position

  $dia->position(3);
  $position = $dia->position;

The neck position of a chord to be diagrammed.  This number is
rendered to the left of the first fret in vertical mode.  When drawing
horizontally, the position is rendered above the first fret.

Default: C<1>

=head2 absolute

  $absolute = $dia->absolute;

Use an absolute neck position for rendering a chord on a full length
fretboard.

If not set, the chord will be rendered relative to the first fret.

Default: C<0>

=head2 strings

  $strings = $dia->strings;

The number of strings.

Default: C<6>

=head2 frets

  $frets = $dia->frets;

The number of frets.

Default: C<5>

=head2 size

  $size = $dia->size;

The relative size of the diagram.  The smallest visible diagram is
B<size> = C<6>.  (This is B<not> a measure of pixels.)

Default: C<30>

=head2 outfile

  $dia->outfile('chord-042');
  $outfile = $dia->outfile;

The image file name minus the extension.

Default: C<chord-diagram>

=head2 type

  $type = $dia->type;

The image file extension.

Default: C<png>

=head2 font

  $font = $dia->font;

The (TTF) font.

Default: C</usr/share/fonts/truetype/freefont/FreeMono.ttf>

=head2 tuning

  $tuning = $dia->tuning;

An arrayref of the string tuning.  The order of the notes is from
highest string (1st) to lowest (6th).  For accidental notes, use flat
(C<b>), not sharp (C<#>).

Default: C<[ E B G D A E ]>

=head2 horiz

  $horiz = $dia->horiz;

Draw the diagram horizontally.  That is, with the first string at the
top and the 6th string at the bottom, and frets numbered from left to
right.

Default: C<0>

=head2 image

  $image = $dia->image;

Boolean to return the image from the B<draw> method instead of writing
it to a file.

Default: C<0>

=head2 string_color

  $string_color = $dia->string_color;

The diagram string color.

Default: C<blue>

=head2 fret_color

  $fret_color = $dia->fret_color;

The diagram fret color.

Default: C<darkgray>

=head2 dot_color

  $dot_color = $dia->dot_color;

The diagram finger position dot color.

Default: C<black>

=head2 showname

  $dia->showname(0);        # Do not show chord names
  $dia->showname(1);        # Show computed names
  $dia->showname('Xb dim'); # Show a custom name
  $showname = $dia->showname;

Show a chord name or not.

Sometimes the computed chord name is not accurate or desired.  In
those cases, either set the B<showname> to a string of your choosing,
or to C<0> for no chord name.

Default: C<1>

=head2 verbose

  $verbose = $dia->verbose;

Monitor the progress of the diagram construction.

Default: C<0>

=head2 fretboard

  $fretboard = $dia->fretboard;

A hashref of the string notes.  This is a computed attribute based on
the given B<tuning>.

=head1 METHODS

=head2 new

  $dia = Music::FretboardDiagram->new(
    chord        => $chord,
    position     => $position,
    strings      => $strings,
    frets        => $frets,
    size         => $size,
    tuning       => $tuning,
    font         => $font,
    showname     => $showname,
    horiz        => $horiz,
    image        => $image,
    string_color => $string_color,
    fret_color   => $fret_color,
    dot_color    => $dot_color,
    outfile      => $outfile,
    type         => $type,
    verbose      => $verbose,
  );

Create a new C<Music::FretboardDiagram> object.

=for Pod::Coverage BUILD

=head2 draw

  $dia->draw;
  $image = $dia->draw; # if the image attr is set

Render the requested chord diagram as an image file of the given
B<type>.

If the B<image> attribute is set, return the image object instead of
writing to a file.

=head1 THANK YOU

Paweł Świderski for the horizontal drawing and webservice suggestions

=head1 SEE ALSO

The F<eg/> files in this distribution

L<Imager>

L<List::SomeUtils>

L<Moo>

L<Music::Chord::Namer>

Similar modules:

L<GD::Tab::Guitar> and L<GD::Tab::Ukulele>

L<Music::Image::Chord>

For a B<real> chord analyzer:

L<https://www.oolimo.com/guitarchords/analyze>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
