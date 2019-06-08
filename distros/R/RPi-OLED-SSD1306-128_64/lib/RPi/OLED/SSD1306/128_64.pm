package RPi::OLED::SSD1306::128_64;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '2.3603';

require XSLoader;
XSLoader::load('RPi::OLED::SSD1306::128_64', $VERSION);

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK;

# UNIMPLEMENTED FUNCTIONS

# ssd1306_startscrollright
# ssd1306_startscrollleft
# ssd1306_startscrolldiagleft
# ssd1306_startscrolldiagright
# ssd1306_stopscroll

@EXPORT_OK = qw(
    ssd1306_begin
    ssd1306_clearDisplay
    ssd1306_display
    ssd1306_dim
    ssd1306_invertDisplay

    ssd1306_setTextSize
    ssd1306_drawChar
    ssd1306_drawString
    ssd1306_drawPixel
    ssd1306_fillRect
    ssd1306_drawFastVLine
    ssd1306_drawFastHLine
);

our %EXPORT_TAGS;

$EXPORT_TAGS{all} = [@EXPORT_OK];

use constant {
    SSD1306_SWITCHCAPVCC => 0x2,
};

my $oled;

sub new {
    return $oled if defined $oled;

    my ($class, $i2c_addr, $display_splash_screen) = @_;

    $display_splash_screen //= 0;

    $i2c_addr //= 0x3C;

    ssd1306_begin(SSD1306_SWITCHCAPVCC, $i2c_addr);

    if ($display_splash_screen){
        ssd1306_display();
        select(undef, undef, undef, 0.1);
    }

    ssd1306_clearDisplay();

    my $self = bless {}, $class;
    $oled = $self;
    return $self;
}
sub clear {
    my ($self) = @_;
    ssd1306_clearDisplay();
    ssd1306_display();

    return 1;
}
sub display {
    my ($self) = @_;
    ssd1306_display();
    return 1;
}
sub text_size {
    my ($self, $size) = @_;

    if ($size !~ /^\d+$/){
        croak "size parameter must be an integer";
    }

    ssd1306_setTextSize($size);

    return 1;
}
sub string {
    my ($self, $str, $display) = @_;
    ssd1306_drawString($str);
    ssd1306_display() if $display;
    return 1;
}
sub rect {
    my ($self, $x, $y, $w, $h, $colour) = @_;

    $colour //= 1;

    if ($x < 0 || $x > 127){
        croak "X must be between 0 and 127";
    }
    if ($y < 0 || $y > 63){
        croak "y must be between 0 and 63";
    }
    if ($w < 0 || $w > 128){
        croak "width must be between 0 and 128";
    }
    if ($h < 0 || $h > 64){
        croak "height must be between 0 and 64";
    }

    ssd1306_fillRect($x, $y, $w, $h, $colour);

    return 1;
}
sub char {
    my ($self, $x, $y, $char, $size, $colour) = @_;

    $colour //= 1;
    $size //= 2;

    ssd1306_drawChar($x, $y, $char, $colour, $size);

    return 1;
}
sub pixel {
    my ($self, $x, $y, $colour) = @_;

    $colour //= 1;

    if ($x < 0 || $x > 127){
        croak "X must be between 0 and 127";
    }
    if ($y < 0 || $y > 63){
        croak "Y must be betwen 0 and 63";
    }

    ssd1306_drawPixel($x, $y, $colour);

    return 1;
}
sub horizontal_line {
    my ($self, $x, $y, $w, $colour) = @_;

    $colour //= 1;

    ssd1306_drawFastHLine($x, $y, $w, $colour);

    return 1;
}
sub vertical_line {
    my ($self, $x, $y, $h, $colour) = @_;

    $colour //= 1;

    ssd1306_drawFastVLine($x, $y, $h, $colour);

    return 1;
}
sub dim {
    my ($self, $bool) = @_;

    $bool //= 0;

    if ($bool < 0 || $bool > 1){
        croak "dim() requires either 1 or 0 sent in";
    }

    ssd1306_dim($bool);

    return 1;
}
sub invert_display {
    my ($self, $bool) = @_;

    $bool //= 0;

    if ($bool < 0 || $bool > 1){
        croak "invert_display() requires either 1 or 0 sent in";
    }

    ssd1306_invertDisplay($bool);

    return 1;
}

1;
__END__

=head1 NAME

RPi::OLED::SSD1306::128_64 - Interface to the SSD1306-esque 128x64 OLED displays

=head1 DESCRIPTION

Provides the ability to use the 128x64 SSD1306 type OLED displays.

This distribution requires wiringPi version 2.36+ to be installed.

=head1 METHODS

=head2 new([$i2c_addr])

Instantiates and returns a new L<< RPi::OLED::SSD1306::128x64 >> object.

Note that this module is a singleton; if you've already instantiated a new
OLED device object, it will be returned if C<new()> is called again.

Parameters:

    $i2c_addr

Optional, Integer. The I2C address of your OLED screen. Defaults to C<0x3C>,
which is extremely common.

=head2 clear

Wipes the display clean, and sets the cursor to the top-left position on the
screen.

Returns C<< 1 >> on success.

=head2 text_size($size)

By default, we use the smallest text size (C<1>) when displaying characters to
the OLED. You can increase or decrease the text size with this call.

Parameters:

    $size

Mandatory, Integer: A number to increase or decrease the font size to. Any
number is valid, but be realistic... this screen is only 128x64 pixels.

Returns C<< 1 >> on success.

=head2 display

Draws whatever you've put into the buffer to the screen. All calls that add
to the buffer (eg: C<rect()>, C<string()>, C<pixel()>, C<char()> etc) require
a call to this method after you've filled the buffer.

=head2 string($str, [$display])

Send a string to the display for printing.

Parameters:

    $str

Mandatory, String: The string you want put into the buffer for display.

    $display

Optional, Bool: All calls for displaying something to the screen require an
additional call to C<< display() >>. Send in a positive value (C<1>) as the
second parameter to this call and we'll call display automatically for you.

Returns C<< 1 >> on success.

=head2 rect($x, $y, $w, $h, $colour)

Prepares a rectangle for display on the screen. To actually display the
rectangle, a subsequent call to C<display()> is required.

Parameters:

    $x

Mandatory, Integer: The X-axis (horizontal) position from the left of the screen
to begin drawing the rectangle.

    $y

Mandatory, Integer: The Y-axis (vertical) position from the top of the screen to
begin drawing the rectangle.

    $w

Mandatory, Integer: How many pixels wide to draw the rect.

    $h

Mandatory, Integer: How many pixels tall (from the top) to draw the rect.

    $colour

Optional, Bool: By default, we use C<1> which is standard colour (white). Send
in C<0> and we'll use black, which will effectively wipe out whatever was on
the display in the area of the rectangle.

Returns C<< 1 >> on success.

=head2 char($x, $y, $char, $size, $colour)

Creates a buffer with a single ASCII char. As with other buffer calls, a call
to C<display()> is required once you're ready to display the buffer.

Parameters:

    $x

Mandatory, Integer: The X-axis (horizontal) position from the left of the screen
to begin drawing the char.

    $y

Mandatory, Integer: The Y-axis (vertical) position from the top of the screen to
begin drawing the char.

    $char

Mandatory, Integer: The integer representation of the ASCII char to draw. Valid
values are C<0-255>.

    $size

Optional, Integer: The size of the char on the screen. Defaults to C<2>.

    $colour

Optional, Bool: By default, we use C<1> which is standard colour (white). Send
in C<0> and we'll use black, which will effectively wipe out whatever was on
the display in the area of the char.

Returns C<< 1 >> on success.

=head2 pixel($x, $y, $colour)

Draw a single pixel to the screen.

Parameters:

    $x

Mandatory, Integer: The X-axis (horizontal) position from the left of the screen
to place the pixel.

    $y

Mandatory, Integer: The Y-axis (vertical) position from the top of the screen to
place the pixel.

    $colour

Optional, Bool: By default, we use C<1> which is standard colour (white). Send
in C<0> and we'll use black, which will effectively wipe out whatever was on
the display in the area of the pixel.

Returns C<< 1 >> on success.

=head2 horizontal_line($x, $y, $w, $colour)

Draw a single pixel wide horizontal line.

Parameters:

    $x

Mandatory, Integer: The X-axis (horizontal) position from the left of the screen
to begin drawing the horizontal line.

    $y

Mandatory, Integer: The Y-axis (vertical) position from the top of the screen to
begin drawing the horizontal line.

    $w

Mandatory, Integer: How many pixels wide to draw the horizontal line.

    $colour

Optional, Bool: By default, we use C<1> which is standard colour (white). Send
in C<0> and we'll use black, which will effectively wipe out whatever was on
the display in the area of the rectangle.

Returns C<1> on success.

=head2 vertical_line($x, $y, $h, $colour)

Draw a single-pixel wide vertical line.

Parameters:

    $x

Mandatory, Integer: The X-axis (horizontal) position from the left of the screen
to begin drawing the vertical line.

    $y

Mandatory, Integer: The Y-axis (vertical) position from the top of the screen to
begin drawing the vertical line.

    $w

Mandatory, Integer: How many pixels tall to draw the vertical line.

    $colour

Optional, Bool: By default, we use C<1> which is standard colour (white). Send
in C<0> and we'll use black, which will effectively wipe out whatever was on
the display in the area of the rectangle.

Returns C<1> on success.

=head2 dim($bool)

The screen has two brightness levels, dim and full.

Parameters:

    $bool

Optional, Bool: Send in C<1> to dim the display, and C<0> to turn it to its
maximum brightness. Defaults to C<0> if not sent in.

Returns C<1> on success.

=head2 invert_display($bool)

By default, the screen background is black, and anything you draw will be
white. Inverting the screen will reverse those two colours.

Parameters:

    $bool

Optional, Bool: C<1> will invert the screen (black on white background), and
C<0> will set it back to normal (white on black background). Defaults to C<0> if
not sent in.

Returns C<1> on success.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Steve Bertrand.

BSD License
