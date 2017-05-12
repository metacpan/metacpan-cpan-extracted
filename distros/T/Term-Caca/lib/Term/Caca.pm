package Term::Caca;
BEGIN {
  $Term::Caca::AUTHORITY = 'cpan:YANICK';
}
#ABSTRACT: perl interface for libcaca (Colour AsCii Art library)

use 5.10.0;
use strict;
use warnings;
no warnings qw/ uninitialized /;

use parent qw/ Exporter DynaLoader /;

our $VERSION = '1.2.0';

Term::Caca->bootstrap($VERSION);

use Carp;
use Method::Signatures;
use Const::Fast;
use List::MoreUtils qw/ uniq /;

use Term::Caca::Event::Key::Press;
use Term::Caca::Event::Key::Release;
use Term::Caca::Event::Mouse::Motion;
use Term::Caca::Event::Mouse::Button::Press;
use Term::Caca::Event::Mouse::Button::Release;
use Term::Caca::Event::Resize;
use Term::Caca::Event::Quit;


our @EXPORT_OK;
our %EXPORT_TAGS;



const our %COLORS => (
  BLACK              => 0,
  BLUE               => 1,
  GREEN              => 2,
  CYAN               => 3,
  RED                => 4,
  MAGENTA            => 5,
  BROWN              => 6,
  LIGHTGRAY          => 7,
  DARKGRAY           => 8,
  LIGHTBLUE          => 9,
  LIGHTGREEN         => 10,
  LIGHTCYAN          => 11,
  LIGHTRED           => 12,
  LIGHTMAGENTA       => 13,
  YELLOW             => 14,
  WHITE              => 15,
  DEFAULT            => 16,
  TRANSPARENT        => 32,
);

const our $BLACK              => 0;
const our $BLUE               => 1;
const our $GREEN              => 2;
const our $CYAN               => 3;
const our $RED                => 4;
const our $MAGENTA            => 5;
const our $BROWN              => 6;
const our $LIGHTGRAY          => 7;
const our $DARKGRAY           => 8;
const our $LIGHTBLUE          => 9;
const our $LIGHTGREEN         => 10;
const our $LIGHTCYAN          => 11;
const our $LIGHTRED           => 12;
const our $LIGHTMAGENTA       => 13;
const our $YELLOW             => 14;
const our $WHITE              => 15;
const our $DEFAULT            => 16;
const our $TRANSPARENT        => 32;

$EXPORT_TAGS{colors} = [ map { '$'.$_ } keys %COLORS ];
push @EXPORT_OK, '@COLORS', @{$EXPORT_TAGS{colors}};



const our %EVENTS => (
    NO_EVENT =>          0x0000,
    KEY_PRESS =>     0x0001,
    KEY_RELEASE =>   0x0002,
    MOUSE_PRESS =>   0x0004,
    MOUSE_RELEASE => 0x0008,
    MOUSE_MOTION =>  0x0010,
    RESIZE =>        0x0020,
    QUIT =>          0x0040,
    ANY_EVENT =>           0xffff,
);

const our $NO_EVENT =>          0x0000;
const our $KEY_PRESS =>     0x0001;
const our $KEY_RELEASE =>   0x0002;
const our $MOUSE_PRESS =>   0x0004;
const our $MOUSE_RELEASE => 0x0008;
const our $MOUSE_MOTION =>  0x0010;
const our $RESIZE =>        0x0020;
const our $QUIT =>          0x0040;
const our $ANY_EVENT =>           0xffff;

$EXPORT_TAGS{events} = [ map { '$'.$_ } keys %EVENTS ];
push @EXPORT_OK, '@EVENTS', @{$EXPORT_TAGS{events}};

push @{$EXPORT_TAGS{all}}, uniq map { @$_ } values %EXPORT_TAGS;


sub driver_list {
    return @{ _caca_get_display_driver_list() };
}


sub drivers {
    my %list = @{ _caca_get_display_driver_list() };
    return keys %list;
}


sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  my %arg = @_;

  $self->{display} = $arg{driver} 
                        ? _create_display_with_driver($arg{driver}) 
                        : _create_display();

  croak "couldn't create display" unless $self->{display};

  $self->{canvas}  = _get_canvas($self->{display});

  return $self;
}

method display {
    return $self->{display};
}

method canvas {
    return $self->{canvas};
}


method set_title ( $title ) {
  _set_display_title($self->display, $title);

  return $self;
}


method refresh {
  _refresh($self->display);
  return $self;
}


method set_refresh_delay ( $seconds ) {
  _set_delay($self->display,int( $seconds * 1_000_000 ));
  return $self;
}


method rendering_time {
  return _get_delay($self->display)/1_000_000;
}


method clear () {
  _clear($self->canvas);
  return $self;
}


method canvas_size {
    my @d = ( $self->canvas_width, $self->canvas_height );

    return wantarray ? @d : \@d;
}


method canvas_width {
  return _get_width($self->canvas);
}


method canvas_height {
  return _get_height($self->canvas);
}



method mouse_position {
    my @pos = ( _get_mouse_x( $self->display ), _get_mouse_y( $self->display ) );
    return wantarray ? @pos : \@pos;
}

#
sub get_mouse_x {
# my ($self) = @_;
  return _get_mouse_x();
}

#
sub get_mouse_y {
# my ($self) = @_;
  return _get_mouse_y();
}


# TODO: troff seems to trigger a segfault
my @export_formats = qw/ caca ansi text html html3 irc ps svg tga /;


method export( :$format = 'caca' ) {

    croak "format '$format' not supported" unless $format ~~ @export_formats;

    my $export = _export( $self->canvas, $format eq 'text' ? 'ansi' : $format );

    $export =~ s/\e\[?.*?[\@-~]//g if $format eq 'text';
    
    return $export;
}




method set_ansi_color( $foreground, $background ) {
    _set_ansi_color( $self->canvas, $foreground, $background );

    return $self;
}


method set_color( $foreground, $background ) {
    if ( exists $COLORS{uc $foreground} ) {
        return $self->set_ansi_color( 
            map { $COLORS{uc $_} } $foreground, $background 
        );
    }

    _set_color( $self->canvas, map { _arg_to_color( $_ ) } $foreground, $background );

    return $self;
}

sub _arg_to_color {
    my $arg = shift;

    return hex $arg unless ref $arg;

    return hex sprintf "%x%x%x%x", @$arg;
}


sub get_feature {
  my ($self, $feature) = @_;
  $feature ||= 0;
  return _get_feature($feature);
}

#
sub set_feature {
  my ($self, $feature) = @_;
  $feature ||= 0;
  _get_feature($feature);
}

#
sub get_feature_name {
  my ($self, $feature) = @_;
  $feature ||= 0;
  return _get_feature_name($feature);
}

sub DESTROY {
    my $self = shift;
  _free_display( $self->{display} ) if $self->{display};
}


method text ( $coord, $text ) {
    length $text > 1 
        ? _putstr( $self->canvas, @$coord, $text )
        : _putchar( $self->canvas, @$coord, $text );        

    return $self;
}


method char ( $coord, $char ) {
    _putchar( $self->canvas, @$coord, substr $char, 0, 1 );

    return $self;
}


method line ( $pa, $pb, :$char = undef ) {
    defined ( $char ) 
    ?  _draw_line($self->canvas, @$pa, @$pb, $char)
    : _draw_thin_line($self->canvas,  @$pa, @$pb );

    return $self;
}


method polyline( $points, :$char = undef, :$close = 0 ) {
    my @x = map { $_->[0] } @$points;
    my @y = map { $_->[1] } @$points;
    my $n = @x - !$close;

    $char ? _draw_polyline( $self->canvas, \@x, \@y, $n, $char )
          : _draw_thin_polyline( $self->canvas, \@x, \@y, $n );

    return $self;
}


method circle ( $center, $radius, :$char = undef, :$fill = undef ) {
    $char //= $fill;

    my @args = ( $self->canvas, @$center, $radius );

    if ( not defined $char ) {
        _draw_thin_ellipse( @args, $radius );
    }
    else {
        if ( defined $fill ) {
            _fill_ellipse( @args, $radius, $char );
        }
        else {
            _draw_circle( @args, $char );
        }
    }

  return $self;
}


method ellipse ( $center, $rx, $ry, :$char = undef, :$fill = undef ) {
    $char //= $fill;

    if ( defined $fill ) {
        _fill_ellipse($self->canvas,@$center,$rx,$ry,$char);
    }
    elsif( defined $char ) {
        _draw_ellipse($self->canvas,@$center,$rx,$ry,$char);
    }
    else {
        _draw_thin_ellipse($self->canvas,@$center,$rx,$ry);
    }

  return $self;
}



method box  ( $center, $width, $height, :$char = undef, :$fill = undef ){
  $char //= $fill;

  my @args = ( $self->canvas, @$center, $width, $height );

  if ( defined $fill ) {
    _fill_box(@args, $char);
  }
  elsif( defined $char ) {
    _draw_box(@args, $char);
  }
  else {
    _draw_thin_box(@args);
  }

  return $self;
}


method triangle  ( $pa, $pb, $pc, :$char = undef, :$fill = undef ){
  $char //= $fill;

  my @args = ( $self->canvas, @$pa, @$pb, @$pc );

  if ( defined $fill ) {
    _fill_triangle(@args, $char);
  }
  elsif( defined $char ) {
    _draw_triangle(@args, $char);
  }
  else {
    _draw_thin_triangle(@args);
  }

  return $self;
}


method wait_for_event ( :$mask = $ANY_EVENT, :$timeout = 0 ) {
  my $event = _get_event( $self->display, $mask, int($timeout*1_000_000), defined wantarray )
      or return;

  given ( _get_event_type( $event ) ) {
    when ( $KEY_PRESS ) {
        return Term::Caca::Event::Key::Press->new( event => $event );
    }
    when ( $KEY_RELEASE ) {
        return Term::Caca::Event::Key::Release->new( event => $event );
    }
    when ( $MOUSE_MOTION ) {
        return Term::Caca::Event::Mouse::Motion->new( event => $event );
    }
    when ( $MOUSE_PRESS ) {
        return Term::Caca::Event::Mouse::Button::Press->new( event => $event );
    }
    when ( $MOUSE_RELEASE ) {
        return Term::Caca::Event::Mouse::Button::Release->new( event => $event );
    }
    when ( $RESIZE ) {
        return Term::Caca::Event::Resize->new( event => $event );
    }
    when ( $QUIT ) {
        return Term::Caca::Event::Quit->new( event => $event );
    }
    default {
        return;
    }
  }

}

'end of Term::Caca';



=pod

=head1 NAME

Term::Caca - perl interface for libcaca (Colour AsCii Art library)

=head1 VERSION

version 1.2.0

=head1 SYNOPSIS

  use Term::Caca;

  my $caca = Term::Caca->new;
  $caca->text( [5, 5], "pwn3d");
  $caca->refresh;
  sleep 3;

=head1 DESCRIPTION

C<Term::Caca> is an API for the ASCII drawing library I<libcaca>.

This version of C<Term::Caca> is compatible with the I<1.x> version of 
the libcaca library (development has been made against version 
0.99.beta17 of the library).

# exports

=head1 EXPORTS

    use Term::Caca qw/ :all /;          # import all 
    # or
    use Term::Caca qw/ :colors /;       # import specific group 
    # or
    use Term::Caca qw/ $LIGHTRED /;     # import specific constant 

=head2 COLORS

    use Term::Caca qw/ :colors /;           # import all colors
    # or 
    use Term::Caca qw/ $WHITE $LIGHTRED /;  # import specific colors
    # or 
    use Term::Caca qw/ %COLORS /;           # import colors as a hash
    # or
    print $Term::Caca::COLORS{WHITE}        # use original array directly

The color constants used by C<set_ansi_color()>. The available colors are

  BLACK       BLUE        GREEN       CYAN          RED                 
  MAGENTA     BROWN       LIGHTGRAY   DARKGRAY      LIGHTBLUE           
  LIGHTGREEN  LIGHTCYAN   LIGHTRED    LIGHTMAGENTA  YELLOW              
  WHITE       DEFAULT     TRANSPARENT         

=head2 EVENTS

    use Term::Caca qw/ :events /;                 # import all events
    # or 
    use Term::Caca qw/ $NO_EVENT $KEY_RELEASE /;  # import specific events
    # or 
    use Term::Caca qw/ %EVENTS /;                 # import events as a hash
    # or
    print $Term::Caca::EVENTS{MOUSE_PRESS}        # use original array directly

The event constants used by the mask of C<wait_for_event()>. The available
events are

    NO_EVENT    ANY_EVENT
    KEY_PRESS   KEY_RELEASE
    MOUSE_PRESS MOUSE_RELEASE   MOUSE_MOTION
    RESIZE      QUIT

=head1 CLASS METHODS

=head3 driver_list 

Returns an hash which keys are the available display drivers
and the values their descriptions.

=head3 drivers 

Returns the list of available drivers.

=head1 METHODS

=head2 Constructor

=head3 new

Instantiates a Term::Caca object. 

The optional argument I<driver> can be passed to select a specific display
driver. If it's not given, the best available driver will be used.

=head2 Display and Canvas

=head3 set_title( $title )

Sets the window title to I<$title>. 

Returns the invocant I<Term::Caca> object.

=head3 refresh

Refreshes the display.

Returns the invocant I<Term::Caca> object.

=head3 set_refresh_delay( $seconds )

Sets the refresh delay in seconds. The refresh delay is used by                                                                
C<refresh> to achieve constant framerate.

If the time is zero, constant framerate is disabled. This is the
default behaviour.                                                                                                                 

Returns the invocant I<Term::Caca> object.

=head3 rendering_time()

Returns the average rendering time, which is measured as the time between
two C<refresh()> calls, in seconds. If constant framerate is enabled via
C<set_refresh_delay()>, the average rendering time will be close to the 
requested delay even if the real rendering time was shorter.                                   

=head3 clear()

Clears the canvas using the current background color.

Returns the invocant object.

=head3 canvas_size

Returns the width and height of the canvas,
as a list in an array context, as a array ref
in a scalar context.

=head2 canvas_width

Returns the canvas width.

=head3 canvas_height

Returns the canvas height.

=head3 mouse_position 

Returns the position of the mouse. In a list context, returns
the I<x>, I<y> coordinates, in a scalar context returns them as an
array ref.

This function is not reliable if the ncurses or S-Lang                                                            
drivers are being used, because mouse position is only detected when                                                               
the mouse is clicked. Other drivers such as X11 work well.

=head2 Import/Export

=head3 import( $drawing, :$format => 'auto' )

Imports the drawing. The supported formats are

=over

=item "auto": try to guess the format.

=item "caca": native libcaca files.

=item "ansi": ANSI art (CP437 charset with ANSI colour codes).

=item "text": ASCII text file.

=item "utf8": UTF-8 text with ANSI color codes.

=back

=head3 export( :$format = 'caca' )

Returns the canvas in the given format.

Supported formats are

=over

=item "caca": native libcaca files.

=item "ansi": ANSI art (CP437 charset with ANSI colour codes).

=item "text": ASCII text file.

=item "html": an HTML page with CSS information.

=item "html3": an HTML table that should be compatible with most navigators, including textmode ones.

=item "irc": UTF-8 text with mIRC colour codes.

=item "ps": a PostScript document.

=item "svg": an SVG vector image.

=item "tga": a TGA image.

=back

=head2 Colors

=head3 set_ansi_color( $foreground, $background )

Sets the foreground and background colors used by primitives,
using colors as defined by C<%COLORS>.

    $t->set_ansi_color( $LIGHTRED, $WHITE );

Returns the invocant object.

=head3 set_color( $foreground, $background ) 

Sets the foreground and background colors used by primitives. 

Each color is an array ref to a ARGB (transparency + RGB) set of values,
all between 0 and 15. Alternatively, they can be given as a string of the direct
hexadecimal value.

    # red on white
    $t->set_color( [ 15, 15, 0, 0 ], 'ffff' );

Returns the invocant object.

=head2 Text

=head3 text( \@coord, $text )

Prints I<$text> at the given coordinates.

Returns the invocant C<Term::Caca> object.

=head3 char( \@coord, $char )

Prints the character I<$char> at the given coordinates.
If I<$char> is a string of more than one character, only
the first character is printed.

Returns the invocant C<Term::Caca> object.

=head2 Primitives Drawing

=head3 line( \@point_a, \@point_b, :$char = undef )

Draws a line from I<@point_a> to I<@point_b>
using the character I<$char> or, if undefined,
ascii art.

Returns the invocant object.

=head3 polyline( \@points, :$char = undef , :$close = 0 ) 

Draws the polyline defined by I<@points>, where each point is an array ref
of the coordinates. E.g.

    $t->polyline( [ [ 0,0 ], [ 10,15 ], [ 20, 15 ] ] );

The lines are drawn using I<$char> or, if not specified, using ascii art.

If I<$close> is true, the end point of the polyline will 
be connected to the first point.

Returns the invocant I<Term::Caca> object.

=head3 circle( \@center, $radius, :$char = '*', :$fill = undef )

Draws a circle centered at I<@center> with a radius
of I<$radius> using the character I<$char> or, if not defined,
ascii art. if I<$fill> is set to true, the circle is filled with I<$char>
as well.

If I<$fill> is defined but I<$char> is not, I<$fill> will be taken as
the filling character. I.e.,

    $c->circle( [10,10], 5, char => 'x', fill => 1 );
    # equivalent to 
    $c->circle( [10,10], 5, fill => 'x' );

Returns the invocant object.

=head3 ellipse( \@center, $radius_x, $radius_y, :$char = undef, :$fill = undef)

Draws an ellipse centered at I<@center> with an x-axis
radius of I<$radius_x> and a y-radius of I<$radius_y>
using the character I<$char> or, if not defined, ascii art.

If I<$fill> is defined but I<$char> is not, I<$fill> will be taken as
the filling character.

Returns the invocant object.

=head3 box( \@top_corner, $width, $height, :$char => undef, :$fill => undef )

Draws a rectangle of dimensions I<$width> and
I<$height> with its upper-left corner at I<@top_corner>,
using the character I<$char> or, if not defined, ascii art. 

If I<$fill> is defined but I<$char> is not, I<$fill> will be taken as
the filling character.

Returns the invocant object.

=head3 triangle( \@point_a, \@point_b, \@point_c, :$char => undef, :$fill => undef )

Draws a triangle defined by the three given points
using the character I<$char> or, if not defined, ascii art. 

If I<$fill> is defined but I<$char> is not, I<$fill> will be taken as
the filling character.

Returns the invocant object.

=head2 Event Handling

=head3 wait_for_event( :$mask = $ANY_EVENT, :$timeout = 0 )

Waits and returns a C<Term::Caca::Event> object matching the mask.

C<$timeout> is in seconds. If set to 0, the method returns immediatly and,
if no event was found, returns nothing. If C<$timeout> is negative,
the method waits forever for an event matching the mask.

    # wait for 5 seconds for a key press or the closing of the window
    my $event = $t->wait_for_event( 
        mask => $KEY_PRESS | $QUIT, 
        timeout => 5 
    );

    say "user is idle" unless defined $event;

    exit if $event->isa( 'Term::Caca::Event::Quit' );

    say "user typed ", $event->char;

=head1 SEE ALSO

libcaca - L<http://caca.zoy.org/>

L<Term::Kaka|Term::Kaka>

=head1 AUTHORS

=over 4

=item *

John Beppu <beppu@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by John Beppu.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut


__END__


