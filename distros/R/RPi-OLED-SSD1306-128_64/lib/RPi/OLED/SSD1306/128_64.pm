package RPi::OLED::SSD1306::128_64;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '3.1802';

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
    my ($class, $i2c_addr, $display_splash_screen) = @_;

    $i2c_addr             //= 0x3C;
    $display_splash_screen //= 1;

    # Singleton: only one panel object exists. A second new() returns the live
    # one, but warn if it asks for a different address or splash setting - those
    # can't take effect on the already-initialized display, and silently
    # ignoring them hides the mistake.
    if (defined $oled){
        if ($i2c_addr != $oled->{i2c_addr}
            || $display_splash_screen != $oled->{splash}){
            warn "RPi::OLED::SSD1306::128_64: new() is a singleton; returning "
               . "the existing display (addr "
               . sprintf('0x%02X', $oled->{i2c_addr})
               . ") and ignoring the new address/splash arguments\n";
        }
        return $oled;
    }

    ssd1306_begin(SSD1306_SWITCHCAPVCC, $i2c_addr);

    if ($display_splash_screen){
        ssd1306_display();
        select(undef, undef, undef, 0.1);
    }

    ssd1306_clearDisplay();

    my $self = bless { i2c_addr => $i2c_addr, splash => $display_splash_screen }, $class;
    $oled = $self;
    return $self;
}
sub clear {
    my ($self) = @_;
    ssd1306_clearDisplay();
    ssd1306_display();

    return 1;
}
sub clear_buffer {
    my ($self) = @_;

    # Zero the in-memory framebuffer and home the cursor WITHOUT pushing to the
    # panel (unlike clear(), which also calls display()). Pairing this with a
    # single display() lets a caller rebuild and push a whole frame in one
    # write, so a continuously-refreshing screen updates with no blank flash.
    ssd1306_clearDisplay();

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
        croak "Y must be between 0 and 63";
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

=head1 SYNOPSIS

    use RPi::OLED::SSD1306::128_64;

    # The panel defaults to I2C address 0x3C
    my $oled = RPi::OLED::SSD1306::128_64->new;

    $oled->text_size(1);

    # Draw text and push it to the screen. A trailing 1 on string() calls
    # display() for you; "\n" starts a new line, and long lines wrap.
    $oled->string("Hello, OLED!\nline two", 1);

    # Drawing primitives fill the in-memory buffer; call display() to show them
    $oled->clear;
    $oled->rect(0, 0, 40, 20, 1);           # filled rectangle
    $oled->horizontal_line(0, 32, 128, 1);  # a horizontal line
    $oled->pixel(64, 40, 1);                # a single pixel
    $oled->display;

    # Flicker-free continuous refresh: rebuild the whole frame in the buffer
    # each pass, then push it once (no blank flash between frames)
    while (1) {
        $oled->clear_buffer;                     # zero buffer + home cursor
        $oled->string(sprintf("tick %d", time)); # draw (no auto-display)
        $oled->display;                          # single push to the panel
        select(undef, undef, undef, 0.2);
    }

    $oled->clear;   # blank the panel when done

=head1 DESCRIPTION

Provides the ability to use the 128x64 SSD1306 type OLED displays.

This distribution requires wiringPi version 3.18+ to be installed (the
canonical minimum for the whole RPi:: family is published as
C<WIRINGPI_MIN_VERSION> in L<RPi::Const>, which this distribution's
C<Makefile.PL> consumes).

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

=head2 clear_buffer

Zeroes the in-memory framebuffer and homes the cursor, but does B<not> push the
result to the panel (unlike L</clear>, which also refreshes the screen). Pair it
with a single L</display> to rebuild and draw a whole frame in one write - handy
for a continuously-updating screen, where clearing straight to the panel each
frame would flicker.

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

=head1 TECHNICAL INFORMATION

The bus work lives in the bundled C layer (C<ssd1306_i2c.c>, a port of
the Adafruit SSD1306 library); the Perl methods draw into a 1KB
framebuffer on the Pi and push it to the panel over I2C.

=head2 DEVICE SPECIFICS

    - SSD1306: 128x64 monochrome OLED controller/driver
    - Graphics RAM is 1KB, arranged as 8 pages of 128 bytes; each byte
      is a vertical strip of 8 pixels
    - This driver mirrors that RAM in a Pi-side buffer: the draw calls
      only touch the buffer, and display() pushes all 1024 bytes out
    - I2C address 0x3C (the module default), or 0x3D with the SA0 line
      strapped high
    - I2C clocks up to 400kHz (t_cycle 2.5us minimum); the Pi's default
      100kHz works fine
    - Logic supply 1.65-3.3V; the higher OLED panel voltage is made by
      the chip's internal charge pump, switched on during init
    - The bare chip also speaks SPI and parallel buses; I2C breakout
      boards hardwire the interface-select pins

Wiring a typical 4-pin I2C breakout: VCC to 3.3V, GND to ground, SDA to
GPIO 2 (pin 3), SCL to GPIO 3 (pin 5). C<i2cdetect -y 1> shows the panel
at C<0x3C>.

=head2 COMMAND SET

Every byte sent to the chip is framed by a control byte (see
L</ON THE WIRE>) marking it as either a command or display data - there
are no addressable registers. The commands this driver uses:

    0xAE / 0xAF   Display off / on
    0x81 xx       Contrast (init sets 0xCF; dim() sends 0x00)
    0xA4          Resume displaying the RAM contents
    0xA6 / 0xA7   Normal / inverted video (invert_display())
    0x20 00       Memory addressing mode: horizontal, auto-wrapping
    0x21 s e      Column address window (display() uses 0-127)
    0x22 s e      Page address window (display() uses 0-7)
    0x40+n        Display start line (init: line 0)
    0xA1          Segment remap - X flip (init)
    0xC8          COM scan direction - Y flip (init)
    0xA8 3F       Multiplex ratio: 64 rows
    0xD3 00       Display offset: none
    0xD5 80       Display clock divide ratio / oscillator
    0xD9 F1       Precharge periods
    0xDA 12       COM pins layout for 128x64
    0xDB 40       VCOMH deselect level
    0x8D 14       Charge pump on
    0x2E          Deactivate scroll

C<new()> runs the whole bring-up sequence above; after that the only
traffic is the odd contrast/invert command and display() pushes.

=head2 ON THE WIRE

The C layer writes through the kernel's C</dev/i2c-1>, and every frame
is three bytes: the chip address, a control byte, then one payload byte.
The control byte is C<0x00> for a command and C<0x40> for display data
(bit 6 is D/C#, bit 7 is Co):

    S = START    P = STOP    A = ACK (receiver pulls SDA low)

A command - here 0xAF (display on) at address 0x3C, which is C<0x78> on
the wire:

    +---+------+---+------+---+------+---+---+
    | S | 0x78 | A | 0x00 | A | 0xAF | A | P |
    +---+------+---+------+---+------+---+---+
         addr+W     Control    Command
         (0x3C)     = command

The framebuffer streams out in a single transaction - one 0x40 control
byte (Co = 0, so every byte after it is display data), then all 1024
buffer bytes, before the STOP:

    +---+------+---+------+---+------+-- --+------+---+---+
    | S | 0x78 | A | 0x40 | A | 0xFF | ... | 0x00 | A | P |
    +---+------+---+------+---+------+-- --+------+---+---+
         addr+W     Control    1024 data bytes, eight
                    = data     vertical pixels each

A full display() is six command frames (resetting the column and page
windows to 0-127 / 0-7) followed by that one 1025-byte data transaction
- about 0.09s per refresh at the Pi's default 100kHz, which is bus-bound
(raise C<dtparam=i2c_arm_baudrate> to go faster). Earlier releases sent a
control+data frame per byte (~1024 transactions, ~0.3s); the driver now
streams the whole buffer after a single control byte, falling back to the
byte-by-byte path only if an adapter caps the single transfer.

=head2 DATASHEET

The Solomon Systech SSD1306 datasheet (rev 1.1) is distributed with this
software as F<docs/datasheet/SSD1306.pdf>. It covers the command set, the
GDDRAM layout, the I2C control byte framing, and the charge pump this
driver enables.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2026 Steve Bertrand.

BSD License
