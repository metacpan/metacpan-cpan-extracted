use strict;
use warnings;

package Printer::ESCPOS::Manual;

# PODNAME: Printer::ESCPOS::Manual
# ABSTRACT: Manual for Printing POS Receipts using L<Printer::ESCPOS>
#
# This file is part of Printer-ESCPOS
#
# This software is copyright (c) 2017 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '1.006'; # VERSION

1;

__END__

=pod

=head1 NAME

Printer::ESCPOS::Manual - Manual for Printing POS Receipts using L<Printer::ESCPOS>

=head1 VERSION

version 1.006

=head1 SYNOPSIS

=head2 BASIC USAGE

     use Printer::ESCPOS;
 
     # Create a Printer object, Initialize the printer.
     my $device = Printer::ESCPOS->new(
         driverType     => 'Serial'
         deviceFilePath => '/dev/ttyACM0'
     );
 
     # All Printers have their own initialization
     # recommendations(Cleaning buffers etc.). Run
     # this command to let the module do this for you.
     $device->printer->init();
 
 
     # Prepare some data to send to the printer using
     # formatting and text commands
     $device->printer->bold(1);
     $device->printer->text("Heading text\n");
     $device->printer->bold(0);
     $device->printer->text("Content here\n");
     $device->printer->text(". . .\n");
 
 
     # Add a cut paper command at the end to cut the receipt
     # This command will be ignored by your printer if it
     # doesn't have a paper cutter on it
     $device->printer->cutPaper();
 
 
     # Send the Prepared data to the printer.
     $device->printer->print();

=head1 PRINTING TO YOUR PRINTER IN THREE STEPS

L<Printer::ESCPOS> uses a three step mechanism for sending the data to the Printer i.e initialization, preparation of data to send to the printer, and finally sending the prepared data to the printer. Separation of preparation and printing steps allows L<Printer::ESCPOS> to deal with communication speed and buffer limitations found in most common ESCPOS printers.

=head2 INITIALIZATION

=head3 USB PRINTER

The B<USB> I<driverType> allows you to talk to a printer using its vendorId and productId as params.

     my $device = Printer::ESCPOS->new(
         driverType => 'USB',
         vendorId   => 0x1504,
         productId  => 0x0006,
     );

Optional parameters:

The driver uses a default I<endPoint> value of 0x01. To get valid values for I<endPoint> for your printer use the following command:

     shantanu@shantanu-G41M-ES2L:~$ sudo lsusb -vvv -d 1504:0006 | grep bEndpointAddress | grep OUT
             bEndpointAddress     0x01  EP 1 OUT

Replace 1504:0006 with your own printer's vendor id and product id in the above command

     my $device = Printer::ESCPOS->new(
         driverType => 'USB',
         vendorId   => 0x1504,
         productId  => 0x0006,
         endPoint   => 0x01,
     );

You may also specify USB device timeout, although default value(1000 ms) should be sufficient in most cases:

     my $device = Printer::ESCPOS->new(
         driverType => 'USB',
         vendorId   => 0x1504,
         productId  => 0x0006,
         endPoint   => 0x01,
         timeout    => 500,
     );

=head3 SERIAL PRINTER

The Mandatory parameters for a B<Serial> I<driverType> are I<driverType>( B<Serial> ) and I<deviceFilePath>
This is the preferred I<driverType> for connecting to a printer. This connection type is valid for printers connected over serial ports or for printers connected on physical USB ports but showing up as B<Serial> devices(check syslog when you connect the printer). Note that not all printers show up as Serial devices when connected on USB port.

     my $device = Printer::ESCPOS->new(
         driverType     => 'Serial',
         deviceFilePath => '/dev/ttyACM0',
     );

Optional parameters:

the driver uses 38400 as default baudrate. If necessary you can change this value by providing a I<baudrate> parameter.

     my $device = Printer::ESCPOS->new(
         driverType     => 'Serial',
         deviceFilePath => '/dev/ttyACM0',
         baudrate       => 9600,
     );

If your printer is not printing properly when connected on physical serial port try setting the flag I<serialOverUSB> to
B<0> to tell L<Printer::ESCPOS> to use special buffer management optimizations for physical serial ports

     my $device = Printer::ESCPOS->new(
         driverType     => 'Serial',
         deviceFilePath => '/dev/ttyACM0',
         baudrate       => 9600,
         serialOverUSB  => 0
     );

=head3 NETWORK PRINTER

The Mandatory parameters for a B<Network> I<driverType> are I<driverType>( B<Network> ), I<deviceIP> and I<devicePort>
This is a I<driverType> for printers connected over a network.

     my $device = Printer::ESCPOS->new(
         driverType => 'Network',
         deviceIP   => '10.0.13.108',
         devicePort => '9100',
     );

=head3 BASIC DEVICE FILE Driver

The Mandatory parameters for a B<File> I<driverType> are I<driverType>( B<File> ) and I<deviceFilePath>
This Driver is included for those instances when your printing needs are simple(You don't want to check the printer for
printer status etc. and are only interested in pushing data to the printer for printing) and B<Serial> driver type is
just refusing to work altogether. In this I<driverType> the data is written directly to the printer device file and from
there sent to the printer. This is the basic text method for ESCPOS printers and it almost always works but it doesn't
allow you to read Printer Status which might not be a deal breaker for most people. This I<driverType> can also be used
for Printers which connect on USB ports but don't show up as Serial devices in syslog

     my $device = Printer::ESCPOS->new(
         driverType     => 'File',
         deviceFilePath => '/dev/usb/lp0',
     );

=head2 PREPARING FORMATTED TEXT FOR PRINTER

In all the methods described below its assumed that variable C<<< $device >>> has been initialized using the appropriate
connection to the printer with one of the driverTypes mentioned above.
The following methods prepare the text and text formatting data to be sent to the printer.

=head3 qr

Prints a qr code to the printer. In Generic profile, this creates a QR Code image using LE<lt>GD::Barcode::QRcodeE<gt>. A native
implementation may be created using a printer model specific profile.

     $device->printer->qr('Print this QR Code');
     $device->printer->qr('WIFI:T:WPA;S:ShantanusWifi;P:wifipasswordhere;;')  # Create a QR code for connecting to a Wifi

You may also pass in optional QR Code format parameters like Ecc, Version and moduleSize. Read more about these params
at L<http://www.qrcode.com/en/about/version.html>.

     my $ecc = 'L'; # Default value
     my $version = 5; # Default value
     my $moduleSize = 3; # Default value
     $device->printer->qr("Don't Panic!", $ecc, $version, $moduleSize);

You may also call align() before calling qr() to set alignment on the page.

=head3 utf8ImagedText

     use utf8;
 
     $device->printer->utf8ImagedText("Hello World",
       fontFamily => "Rubik",
       fontStyle => "Normal",
       fontSize => 25,
       lineHeight => 40
     );

This method uses native fonts to print utf8 compatible characters including international wide characters. This method
is slower than direct text printing but it allows exceptional styling options allowing you to print text using system
fonts in a wide range of font sizes and styles with many more choices than what a thermal printer otherwise provides.

In the background this function uses L<Pango> and L<Cairo> libraries to create a one line image from a given font styles,
font family in a given font size. Note that you must not use this method to print more than a single line at a time.
When you want to print the next line call this method again to print to the next line.

I<string>: String to be printed in the line.

I<fontFamily> (optional, default B<'Purisa'>): Font family to use. On linux systems with font config installed use the
following command to choose from the list of available fonts:

     fc-list | sed 's/.*:\(.*,\|\s\)\(.*\):.*/\2/'

You may also install more fonts from https:E<sol>E<sol>fonts.google.comE<sol> to your system fonts( copy the font to E<sol>usrE<sol>shareE<sol>fonts )

I<fontStyle> (optional, default B<'Normal'>): Font style like Bold, Normal, Italic etc.

I<fontSize> (optional, default B<20>): Font size

I<lineHeight> (optional, default B<42>): Line Height in pixels, make sure this is bigger than the font height in pixels for your chosen font size.

I<paperWidth> (optional, default B<500>): This is set to 500 pixels by default as this is the most common width for receipt printers. Change this
as per your printer specs.

=head3 image

Prints a GD image object to the printer

     use GD;
 
     my $img = newFromGif GD::Image('header.gif') || die "Error $!";
     $device->printer->image($img);

=head3 text

Sends raw text to the printer.

     $device->printer->text("Hello Printer::ESCPOS\n")

=head3 printAreaWidth

Sets the Print area width specified by width which is a int between B<0> to B<65535>

     $device->printer->printAreaWidth( 255 );

Note: If you are using Printer::ESCPOS version prior to v1.* Please check documentation for older version of this module
the nL and nH syntax for this method.

=head3 tabPositions

Sets horizontal tab positions for tab stops. Upto 32 tab positions can be set in most receipt printers.

     $device->printer->tabPositions( 5, 9, 13 );

=over

=item *

Default tab positions are usually in intervals of 8 chars (9, 17, 25) etc.

=back

=head3 tab

moves the cursor to next horizontal tab position like a C<<< "\t" >>>. This command is ignored unless the next horizontal tab
position has been set. You may substitute this command with a C<<< "\t" >>> as well.

This

     $device->printer->text("blah blah");
     $device->printer->tab();
     $device->printer->text("blah2 blah2");

is same as this

     $device->printer->text("blah blah\tblah2 blah2");

=head3 lf

line feed. Moves to the next line. You can substitute this method with C<<< "\n" >>> in your print or text method e.g. :

This

     $device->printer->text("blah blah");
     $device->printer->lf();
     $device->printer->text("blah2 blah2");

is same as this

     $device->printer->text("blah blah\nblah2 blah2");

=head3 font

Set Font style, you can pass B<a>, B<b> or B<c>. Many printers don't support style B<c> and only have two supported styles.

     $device->printer->font('a');
     $device->printer->text('Writing in Font A');
     $device->printer->font('b');
     $device->printer->text('Writing in Font B');

=head3 bold

Set bold mode B<0> for off and B<1> for on. Also called emphasized mode in some printer manuals

     $device->printer->bold(1);
     $device->printer->text("This is Bold Text\n");
     $device->printer->bold(0);
     $device->printer->text("This is not Bold Text\n");

=head3 doubleStrike

Set double-strike mode B<0> for off and B<1> for on

     $device->printer->doubleStrike(1);
     $device->printer->text("This is Double Striked Text\n");
     $device->printer->doubleStrike(0);
     $device->printer->text("This is not Double Striked  Text\n");

=head3 underline

set underline, B<0> for off, B<1> for on and B<2> for double thickness

     $device->printer->underline(1);
     $device->printer->text("This is Underlined Text\n");
     $device->printer->underline(2);
     $device->printer->text("This is Underlined Text with thicker underline\n");
     $device->printer->underline(0);
     $device->printer->text("This is not Underlined Text\n");

=head3 invert

Reverse whiteE<sol>black printing mode pass B<0> for off and B<1> for on

     $device->printer->invert(1);
     $device->printer->text("This is Inverted Text\n");
     $device->printer->invert(0);
     $device->printer->text("This is not Inverted Text\n");

=head3 color

Most thermal printers support just one color, black. Some ESCPOS printers(especially dot matrix) also support a second
color, usually red. In many models, this only works when the color is set at the beginning of a new line before any text
is printed. Pass B<0> or B<1> to switch between the two colors.

     $device->printer->lf();
     $device->printer->color(0); #black
     $device->printer->text("black");
     $device->printer->lf();
     $device->printer->color(1); #red
     $device->printer->text("Red");
     $device->printer->print();

=head3 justify

Set Justification. Options B<left>, B<right> and B<center>

     $device->printer->justify( 'right' );
     $device->printer->text("This is right justified");

=head3 upsideDown

Sets Upside Down Printing onE<sol>off (pass B<0> or B<1>)

     $device->printer->upsideDownPrinting(1);
     $device->printer->text("This text is upside down");

=head3 fontHeight

Set font height. Only supports B<0> or B<1> for printmode set to 1, supports values B<0>, B<1>, B<2>, B<3>, B<4>, B<5>, B<6> and
B<7> for non-printmode state (default)

     $device->printer->fontHeight(1);
     $device->printer->text("double height\n");
     $device->printer->fontHeight(2);
     $device->printer->text("triple height\n");
     $device->printer->fontHeight(3);
     $device->printer->text("quadruple height\n");
     . . .

=head3 fontWidth

Set font width. Only supports B<0> or B<1> for printmode set to 1, supports values B<0>, B<1>, B<2>, B<3>, B<4>, B<5>, B<6> and
B<7> for non-printmode state (default)

     $device->printer->fontWidth(1);
     $device->printer->text("double width\n");
     $device->printer->fontWidth(2);
     $device->printer->text("triple width\n");
     $device->printer->fontWidth(3);
     $device->printer->text("quadruple width\n");
     . . .

=head3 charSpacing

Sets character spacing. Takes a value between 0 and 255

     $device->printer->charSpacing(5);
     $device->printer->text("Blah Blah Blah\n");
     $device->printer->print();

=head3 lineSpacing

Sets the line spacing i.e the spacing between each line of printout.

     $device->printer->lineSpacing($spacing);

=over

=item *

0 E<lt>= $spacing E<lt>= 255

=back

=head3 selectDefaultLineSpacing

Reverts to default line spacing for the printer

     $device->printer->selectDefaultLineSpacing();

=head3 printPosition

Sets the distance from the beginning of the line to the position at which characters are to be printed.

     $device->printer->printPosition( $length, $height );

=over

=item *

0 E<lt>= $length E<lt>= 255

=item *

0 E<lt>= $height E<lt>= 255

=back

=head3 leftMargin

Sets the left margin for printing. Set the left margin at the beginning of a line. The printer ignores any data
preceding this command on the same line in the buffer.

In page mode sets the left margin to leftMargin x (horizontal motion unit) from the left edge of the printable area

Left Margin, range: 0 to 65535. If the margin exceeds the printable area, the left margin is automatically set to the
maximum value of the printable area.

     $device->printer->leftMargin($leftMargin);

=head3 rot90

Rotate printout by 90 degrees

     $device->printer->rot90(1);
     $device->printer->text("This is rotated 90 degrees\n");
     $device->printer->rot90(0);
     $device->printer->text("This is not rotated 90 degrees\n");

=head3 barcode

This method prints a barcode to the printer. This can be bundled with other text formatting commands at the appropriate
point where you would like to print a barcode on your print out. takes argument I<barcode> as the barcode value.

In the simplest form you can use this command as follows:

     #Default barcode printed in code93 system with a width of 2 and HRI Chars printed below the barcode
     $device->printer->barcode(
         barcode     => 'SHANTANU BHADORIA',
     );

However there are several customizations available including barcode I<system>, I<font>, I<height> etc.

     my $hripos = 'above';
     my $font   = 'a';
     my $height = 100;
     my $system = 'UPC-A';
     $device->printer->barcode(
         HRIPosition => $hripos,        # Position of Human Readable characters
                                        # 'none','above','below','aboveandbelow'
         font        => $font,          # Font for HRI characters. 'a' or 'b'
         height      => $height,        # no of dots in vertical direction
         system      => $system,        # Barcode system
         width       => 2               # 2:0.25mm, 3:0.375mm, 4:0.5mm, 5:0.625mm, 6:0.75mm
         barcode     => '123456789012', # Check barcode system you are using for allowed
                                        # characters in barcode
     );
     $device->printer->barcode(
         system      => 'CODE39',
         HRIPosition => 'above',
         barcode     => '*1-I.I/ $IA*',
     );
     $device->printer->barcode(
         system      => 'CODE93',
         HRIPosition => 'above',
         barcode     => 'Shan',
     );

Available barcode I<systems>:

=over

=item *

UPC-A

=item *

UPC-C

=item *

JAN13

=item *

JAN8

=item *

CODE39

=item *

ITF

=item *

CODABAR

=item *

CODE93

=item *

CODE128

=back

=head3 printNVImage

Prints bit image stored in Non-Volatile (NV) memory of the printer.

     $device->printer->printNVImage($flag);

=over

=item *

$flag = 0 # Normal width and Normal Height

=item *

$flag = 1 # Double width and Normal Height

=item *

$flag = 2 # Normal width and Double Height

=item *

$flag = 3 # Double width and Double Height

=back

=head3 printImage

Prints bit image stored in Volatile memory of the printer. This image gets erased when printer is reset.

     $device->printer->printImage($flag);

=over

=item *

$flag = 0 # Normal width and Normal Height

=item *

$flag = 1 # Double width and Normal Height

=item *

$flag = 2 # Normal width and Double Height

=item *

$flag = 3 # Double width and Double Height

=back

=head3 cutPaper

Cuts the paper, if I<feed> is set to B<0> then printer doesnt feed paper to cutting position before cutting it. The
default behavior is that the printer doesn't feed paper to cutting position before cutting. One pre-requisite line feed
is automatically executed before paper cut though.

     $device->printer->cutPaper( feed => 0 )

While not strictly a text formatting option, in receipt printer the cut paper instruction is sent along with the rest of
the text and text formatting data and the printer cuts the paper at the appropriate points wherever this command is
used.

=head3 drawerKickPulse

Trigger drawer kick. Used to open cash drawer connected to the printer. In some use cases it may be used to trigger
other devices by close contact.

     $device->printer->drawerKickPulse( $pin, $time );

=over

=item *

$pin is either 0( for pin 2 ) and 1( for pin5 ) default value is 0

=item *

$time is a value between 1 to 8 and the pulse duration in multiples of 100ms. default value is 8

=back

For default values use without any params to kick drawer pin 2 with a 800ms pulse

     $device->printer->drawerKickPulse();

Again like cutPaper command this is obviously not a text formatting command but this command is sent along with the rest
of the text and text formatting data and the printer sends the pulse at the appropriate points wherever this command is
used. While originally designed for triggering a cash drawer to open, in practice this port can be used for all sorts of
devices like pulsing light, or sound alarm etc.

=head2 PRINTING

=head3 print

Once Initialization is done and the formatted text for printing is prepared using the above commands, its time to send
these commands to printer. This is a single easy step.

     $device->printer->print();

Why an extra print step to send this data to the printer?
This is necessary because many printers have difficulty handling large amount of print data sent across in a single
large stream. Separating the preparation of data from transmission of data to the printer allows L<Printer::ESCPOS> to do
some buffer management and optimization in the way the entire data is sent to the printer with tiny timed breaks between
chunks of data for a reliable printer output.

=head2 GETTING PRINTER HEALTH STATUS

The B<Serial> I<driverType> allows reading of printer health, paper and other status parameters from the printer.
At the moment there are following commands available for getting printer status.

=head3 printerStatus

Returns printer status in a hashref.

     return {
         drawer_pin3_high            => $flags[5],
         offline                     => $flags[4],
         waiting_for_online_recovery => $flags[2],
         feed_button_pressed         => $flags[1],
     };

=head3 offlineStatus

Returns a hashref for paper cover closed status, feed button pressed status, paper end stop status, and a aggregate
error status either of which will prevent the printer from processing a printing request.

     return {
         cover_is_closed     => $flags[5],
         feed_button_pressed => $flags[4],
         paper_end           => $flags[2],
         error               => $flags[1],
     };

=head3 errorStatus

Returns hashref with error flags for auto_cutter_error, unrecoverable error and auto-recoverable error

     return {
         auto_cutter_error     => $flags[4],
         unrecoverable_error   => $flags[2],
         autorecoverable_error => $flags[1],
     };

=head3 paperSensorStatus

Gets printer paper Sensor status. Returns a hashref with four sensor statuses. Two paper near end sensors and two paper
end sensors for printers supporting this feature. The exact returned status might differ based on the make of your
printer. If any of the flags is set to 1 it implies that the paper is out or near end.

     return {
         paper_roll_near_end_sensor_1 => $flags[5],
         paper_roll_near_end_sensor_2 => $flags[4],
         paper_roll_status_sensor_1 => $flags[2],
         paper_roll_status_sensor_2 => $flags[1],
     };

=head3 inkStatusA

Only available for dot-matrix and other ink consuming printers. Gets printer ink status for inkA(usually black ink).
Returns a hashref with ink statuses.

     return {
         ink_near_end          => $flags[5],
         ink_end               => $flags[4],
         ink_cartridge_missing => $flags[2],
         cleaning_in_progress  => $flags[1],
     };

=head3 inkStatusB

Only available for dot-matrix and other ink consuming printers. Gets printer ink status for inkB(usually red ink).
Returns a hashref with ink statuses.

     return {
         ink_near_end          => $flags[5],
         ink_end               => $flags[4],
         ink_cartridge_missing => $flags[2],
     };

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
