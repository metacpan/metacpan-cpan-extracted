use strict;
use warnings;

package Printer::ESCPOS::Profiles::Generic;

# PODNAME: Printer::ESCPOS::Profiles::Generic
# ABSTRACT: Generic Profile for Printers for L<Printer::ESCPOS>. Most common functions are included here.
#
# This file is part of Printer-ESCPOS
#
# This software is copyright (c) 2017 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '1.006'; # VERSION

# Dependencies
use 5.010;
use Moo;
with 'Printer::ESCPOS::Roles::Profile';
use Carp;
use Scalar::Util::Numeric qw(isint);
use GD::Barcode::QRcode;

use Pango;
use utf8;
use File::Temp;

use constant {
    _ESC => "\x1b",
    _GS  => "\x1d",
    _DLE => "\x10",
    _FS  => "\x1c",

    # Level 2 Constants
    _FF  => "\x0c",
    _SP  => "\x20",
    _EOT => "\x04",
    _DC4 => "\x14",
};


sub init {
    my ($self) = @_;

    $self->driver->print( _ESC . '@' );
}


sub enable {
    my ( $self, $n ) = @_;

    if ( $n == 1 ) {
        $self->driver->print( _ESC . '=' . chr(1) );
    }
    elsif ( $n == 0 ) {
        $self->driver->print( _ESC . '=' . chr(2) );
    }
    else {
        confess "Invalid parameter please use '0' or '1'";
    }
}


sub qr {
    my ( $self, $string, $ecc, $version, $moduleSize ) = @_;
    $ecc        ||= 'L';
    $version    ||= 5;
    $moduleSize ||= 3;

    my %eccAllowedValues;
    @eccAllowedValues{qw(L M Q H)} = ();
    confess "Ecc must be one of 'L', 'M', 'Q' or 'H'"
      unless ( exists $eccAllowedValues{$ecc} );
    confess "Version must be between 1 to 40"
      unless ( $version <= 40 and $version >= 1 and $version =~ /\d?\d/ );
    confess "Module size must be between a positive integer"
      unless ( isint $moduleSize == 1 );

    my $qrImage =
      GD::Barcode::QRcode->new( $string,
        { Ecc => $ecc, Version => $version, ModuleSize => $moduleSize } )
      ->plot();
    $self->image($qrImage);
}


sub utf8ImagedText {
    my ( $self, $string, %params ) = @_;
    my $fontFamily = $params{fontFamily} // "Purisa";
    my $fontStyle  = $params{fontStyle}  // "Normal";
    my $fontSize   = $params{fontSize}   // 20;
    my $lineHeight = $params{lineHeight} // 42;
    my $paperWidth = $params{paperWidth} // 500;

    my $surface =
      Cairo::ImageSurface->create( 'argb32', $paperWidth, $lineHeight );
    my $cr = Cairo::Context->create($surface);
    $cr->set_antialias('none');
    $cr->set_source_rgb( 255, 255, 255 );
    $cr->paint();
    $cr->set_source_rgb( 0, 0, 0 );
    my $layout = Pango::Cairo::create_layout($cr);
    $layout->set_text($string);
    my $font =
      Pango::FontDescription->from_string("$fontFamily $fontStyle $fontSize");
    $layout->set_font_description($font);

    Pango::Cairo::show_layout( $cr, $layout );
    my $tempdir = File::Temp::tempdir();
    $surface->write_to_png( $tempdir . '/cairopangoprinterimage.png' );
    my $img = newFromPng GD::Image( $tempdir . '/cairopangoprinterimage.png' )
      || die "Error $!";
    $self->image($img);
}


sub image {
    my ( $self, $img ) = @_;
    my $paddingLeft  = '';
    my $paddingRight = '';

    if ( $img->width > 512 ) {
        carp
'Width is greater than 512 pixels and could be truncated at print time';
    }
    if ( $img->height > 255 ) {
        confess 'Height is greater than 255 pixels';
    }

    my @padding = $self->_pad_image_size( $img->width );
    for ( 1 .. $padding[0] ) {
        $paddingLeft .= '0';
    }
    for ( 1 .. $padding[1] ) {
        $paddingRight .= '0';
    }

    my $pixelLine = '';
    my $switch    = 0;
    my @imageSize = ( 0, 0 );
    for my $y ( 0 .. $img->height - 1 ) {
        $imageSize[1]++;
        $pixelLine .= $paddingLeft;
        $imageSize[0] += $padding[0];
        for my $x ( 0 .. $img->width - 1 ) {
            $imageSize[0]++;
            my $index         = $img->getPixel( $x, $y );
            my @rgb           = $img->rgb($index);
            my $imageColour   = $rgb[0] + $rgb[1] + $rgb[2];
            my $imagePattern  = "1X0";
            my $patternLength = length $imagePattern;
            $switch = ( $switch - 1 ) * (-1);
            for my $x ( 1 .. $patternLength ) {

                if ( $imageColour <= ( 255 * 3 / $patternLength * $x ) ) {
                    my $patternAtX = substr( $imagePattern, $x - 1, 1 );
                    if ( $patternAtX eq 'X' ) {
                        $pixelLine .= $switch;
                    }
                    else {
                        $pixelLine .= $patternAtX;
                    }
                    last;
                }
                elsif (
                    $imageColour > ( 255 * 3 / $patternLength * $patternLength )
                    and $imageColour <= ( 255 * 3 ) )
                {
                    $pixelLine .= substr( $imagePattern, -1, 1 );
                    last;
                }
            }
        }
        $pixelLine .= $paddingRight;
        $imageSize[0] += $padding[1];
    }
    $self->_print_image( $pixelLine, \@imageSize );
}

sub _pad_image_size {
    my ( $self, $width ) = @_;

    if ( $width % 32 == 0 ) {
        return ( 0, 0 );
    }
    else {
        my $border = 32 - ( $width % 32 );
        if ( $border % 2 == 0 ) {
            return ( $border / 2, $border / 2 );
        }
        else {
            return ( $border / 2 - .5, $border / 2 + .5 );
        }
    }
}

sub _print_image {
    my ( $self, $pixelLine, $imageSize ) = @_;

    $self->driver->write( _GS . "v\x30\x00" );
    my $buffer = sprintf(
        "%02X%02X%02X%02X",
        (
            ( ( $imageSize->[0] / $imageSize->[1] ) / 8 ), 0, $imageSize->[1],
            0
        )
    );
    $self->driver->write( pack( "H*", $buffer ) );

    $buffer = "";
    my $i     = 0;
    my $count = 0;
    while ( $i < length($pixelLine) ) {
        my $octalString = oct( "0b" . substr( $pixelLine, $i, 8 ) );
        $buffer .= sprintf( "%02X", $octalString );
        $i += 8;
        $count++;
        if ( $count % 4 == 0 ) {
            $self->driver->write( pack( "H*", $buffer ) );
            $buffer = "";
            $count  = 0;
        }
    }
}


sub printAreaWidth {
    my ( $self, $width ) = @_;

    confess
"Width must be a integer between 0 and 65535 in printAreaWidth(). Invalid value '$width'.
        Usage: \n\t\$device->printer->printAreaWidth(\$width)\n"
      unless ( isint $width == 1 and $width <= 65535 and $width >= 1 );

    my $nH = $width >> 8;
    my $nL = $width - ( $nH << 8 );

    $self->driver->write( _GS . 'W' . chr($nL) . chr($nH) );
}


sub tabPositions {
    my ( $self, @positions ) = @_;
    my $pos = '';

    for (@positions) {
        confess "Tab position must be a positive integer. Invalid value '$_'.
        Usage: \n\t\$device->printer->tabPositions(4,8,16 ...)\n"
          unless isint $_ == 1;
    }

    $pos .= chr($_) for @positions;
    $self->driver->write( _ESC . 'D' . $pos . chr(0) );
}


sub tab {
    my ($self) = @_;

    $self->driver->write("\t");
}


sub lf {
    my ($self) = @_;

    $self->driver->write("\n");
}


sub ff {
    my ($self) = @_;

    $self->driver->write("\x0c");
}


sub cr {
    my ($self) = @_;

    $self->driver->write("\x0d");
}


sub cancel {
    my ($self) = @_;

    $self->driver->write("\x18");
}


sub font {
    my ( $self, $font ) = @_;
    $font ||= 'a';

    my %fontMap = (
        a => "\x00",
        b => "\x01",
        c => "\x02",
    );

    confess "Invalid value for font '$font'. Use 'a', 'b' or 'c'.
        Usage: \n\t\$device->printer->font('a')\n"
      unless exists $fontMap{$font};

    $self->fontStyle($font);
    if ( $self->usePrintMode && $font ne 'c' ) {
        $self->_updatePrintMode;
    }
    else {
        $self->driver->write( _ESC . 'M' . $fontMap{$font} );
    }
}


sub bold {
    my ( $self, $bold ) = @_;
    $bold ||= 0;

    confess "Invalid value for bold '$bold'. Use '0' or '1'.
        Usage: \n\t\$device->printer->bold(1)\n"
      unless ( $bold == 1 or $bold == 0 );

    $self->emphasizedStatus($bold);
    if ( $self->usePrintMode ) {
        $self->_updatePrintMode;
    }
    else {
        $self->driver->write( _ESC . 'E' . int($bold) );
    }
}


sub doubleStrike {
    my ( $self, $doubleStrike ) = @_;
    $doubleStrike ||= 0;

    confess "Invalid value for doubleStrike '$doubleStrike'. Use '0' or '1'.
        Usage: \n\t\$device->printer->doubleStrike(1)\n"
      unless ( $doubleStrike == 1 or $doubleStrike == 0 );

    $self->driver->write( _ESC . 'G' . int($doubleStrike) );
}


sub underline {
    my ( $self, $underline ) = @_;
    $underline ||= 0;

    confess "Invalid value for underline '$underline'. Use '0', '1' or '2'.
        Usage: \n\t\$device->printer->underline(1)\n"
      unless ( $underline == 2 or $underline == 1 or $underline == 0 );

    $self->underlineStatus($underline);
    if ( $self->usePrintMode ) {
        $self->_updatePrintMode;
    }
    else {
        $self->driver->write( _ESC . '-' . $underline );
    }
}


sub invert {
    my ( $self, $invert ) = @_;
    $invert ||= 0;

    confess "Invalid value for invert '$invert'. Use '0' or '1'.
        Usage: \n\t\$device->printer->invert(1)\n"
      unless ( $invert == 1 or $invert == 0 );

    $self->driver->write( _GS . 'B' . chr($invert) );
}


sub color {
    my ( $self, $color ) = @_;
    $color ||= 0;

    confess "Invalid value for color '$color'. Use '0' or a positive integer.
        Usage: \n\t\$device->printer->color(1)\n" unless ( isint $color >= 0 );

    $self->driver->write( _ESC . 'r' . chr($color) );
}


sub justify {
    my ( $self, $justify ) = @_;
    $justify ||= 'left';
    my %jmap = (
        left   => 0,
        center => 1,
        right  => 2,
        full   => 3,
    );

    confess
"Invalid value for justify '$justify'. Use 'full', 'left', 'center' or 'right'.
        Usage: \n\t\$device->printer->justify('left')\n"
      unless ( exists $jmap{$justify} );

    $self->driver->write( _ESC . 'a' . int( $jmap{ lc $justify } ) );
}


sub upsideDown {
    my ( $self, $upsideDown ) = @_;
    $upsideDown ||= 0;

    confess "Invalid value for upsideDown '$upsideDown'. Use '0' or '1'.
        Usage: \n\t\$device->printer->upsideDown(1)\n"
      unless ( $upsideDown == 1 or $upsideDown == 0 );

    $self->lf();
    $self->driver->write( _ESC . '{' . int($upsideDown) );
}


sub fontHeight {
    my ( $self, $height ) = @_;
    $height ||= 0;
    my $width = $self->widthStatus;

    confess
"Invalid value for fontHeight '$height'. Use a integer between '0' and '7'.
        Usage: \n\t\$device->printer->fontHeight(5)\n"
      unless ( isint $height >= 0 and $height <= 7 );

    $self->heightStatus($height);
    if ( $self->usePrintMode ) {
        $self->_updatePrintMode;
    }
    else {
        $self->driver->write( _GS . '!' . chr( $width << 4 | $height ) );
    }
}


sub fontWidth {
    my ( $self, $width ) = @_;
    $width ||= 0;
    my $height = $self->heightStatus;

    confess
      "Invalid value for fontWidth '$width'. Use a integer between '0' and '7'.
        Usage: \n\t\$device->printer->fontWidth(5)\n"
      unless ( isint $width >= 0 and $width <= 7 );

    $self->widthStatus($width);
    if ( $self->usePrintMode ) {
        $self->_updatePrintMode;
    }
    else {
        $self->driver->write(
            _GS . '!' . chr( int($width) << 4 | int($height) ) );
    }
}


sub charSpacing {
    my ( $self, $charSpacing ) = @_;
    $charSpacing ||= 0;

    confess
"Invalid value for charSpacing '$charSpacing'. Use a integer between '0' and '255'.
        Usage: \n\t\$device->printer->charSpacing(5)\n"
      unless ( isint $charSpacing >= 0 and $charSpacing <= 255 );

    $self->driver->write( _ESC . _SP . chr($charSpacing) );
}


sub lineSpacing {
    my ( $self, $lineSpacing, $commandSet ) = @_;
    $lineSpacing ||= 30;
    $commandSet  ||= '3';

    if ( $commandSet eq '+' or $commandSet eq '3' ) {
        confess
"Invalid value for lineSpacing '$lineSpacing'. Use a integer between '0' and '255' with this commandSet.
            Usage: \n\t\$device->printer->lineSpacing(5, 'A')\n"
          unless ( isint $lineSpacing >= 0 and $lineSpacing <= 255 );
    }
    elsif ( $commandSet eq 'A' ) {
        confess
"Invalid value for lineSpacing '$lineSpacing'. Use a integer between '0' and '85' with commandSet 'A'.
            Usage: \n\t\$device->printer->lineSpacing(5, 'A')\n"
          unless ( isint $lineSpacing >= 0 and $lineSpacing <= 85 );
    }
    else {
        confess
          "Invalid value for commandSet '$commandSet'. Use 'A', '3' or '+'.
            Usage: \n\t\$device->printer->lineSpacing(5, 'A')\n";
    }

    $self->driver->write( _ESC . $commandSet . chr($lineSpacing) );
}


sub selectDefaultLineSpacing {
    my ($self) = @_;
    $self->driver->write( _ESC . '2' );
}


sub printPosition {
    my ( $self, $length, $height ) = @_;

    confess
      "Invalid value for length '$length'. Use a integer between '0' and '255'.
        Usage: \n\t\$device->printer->printPosition(5, 6)\n"
      unless ( isint $length >= 0 and $length <= 255 );
    confess
      "Invalid value for length '$height'. Use a integer between '0' and '255'.
        Usage: \n\t\$device->printer->printPosition(5, 6)\n"
      unless ( isint $height >= 0 and $height <= 255 );

    $self->driver->write( _ESC . '$' . chr($length) . chr($height) );
}


sub leftMargin {
    my ( $self, $leftMargin ) = @_;

    confess
"Invalid value for leftMargin '$leftMargin'. Use a integer between '0' and '255'.
        Usage: \n\t\$device->printer->leftMargin(30)\n"
      unless ( isint $leftMargin >= 0 and $leftMargin <= 255 );

    my $nH = $leftMargin >> 8;
    my $nL = $leftMargin - ( $nH << 8 );

    $self->driver->write( _GS . 'L' . chr($nL) . chr($nH) );
}


sub rot90 {
    my ( $self, $rotate ) = @_;

    confess "Invalid value for rot90 '$rotate'. Use '0' or '1'.
        Usage: \n\t\$device->printer->rot90(1)\n"
      unless ( $rotate == 1 or $rotate == 0 );

    $self->driver->write( _ESC . 'V' . chr($rotate) );
}

# This is a redundant function in ESCPOS which updates the printer
sub _updatePrintMode {
    my ($self) = @_;
    my %fontMap = (
        a => 0,
        b => 1,
    );

    my $value =
        $fontMap{ $self->fontStyle } . '00'
      . $self->emphasizedStatus
      . ( $self->heightStatus ? '1' : '0' )
      . ( $self->widthStatus  ? '1' : '0' ) . '0'
      . $self->underlineStatus;
    $self->driver->write( _ESC . '!' . pack( "b*", $value ) );
}

# BEGIN: BARCODE functions


sub barcode {
    my ( $self, %params ) = @_;

    my %map = (
        none          => 0,
        above         => 1,
        below         => 2,
        aboveandbelow => 3,
    );

    $self->driver->write(
        _GS . 'H' . chr( $map{ $params{HRIPosition} || 'below' } ) );

    %map = (
        a => 0,
        b => 1,
    );
    $self->driver->write( _GS . 'f' . chr( $map{ $params{font} || 'b' } ) );

    $self->driver->write( _GS . 'h' . chr( $params{height} || 50 ) );

    $self->driver->write( _GS . 'w' . chr( $params{width} || 2 ) );

    %map = (
        'UPC-A' => 0,
        'UPC-B' => 1,
        JAN13   => 2,
        JAN8    => 3,
        CODE39  => 4,
        ITF     => 5,
        CODABAR => 6,
        CODE93  => 7,
        CODE128 => 8,
    );
    $params{system} ||= 'CODE93';

    if ( exists $map{ $params{system} } ) {
        $self->driver->write( _GS . 'k'
              . chr( $map{ $params{system} } + 65 )
              . chr( length $params{barcode} )
              . $params{barcode} );
    }
    else {
        confess "Invalid system in barcode";
    }
}

# END: BARCODE functions

# BEGIN: Bitmap printing methods


sub printNVImage {
    my ( $self, $flag ) = @_;

    $self->driver->write( _FS . 'p' . chr(1) . chr($flag) );
}


sub printImage {
    my ( $self, $flag ) = @_;

    $self->driver->write( _GS . '/' . chr($flag) );
}

# END: Bitmap printing methods

# BEGIN: Peripheral and cutter Control Commands


sub cutPaper {
    my ( $self, %params ) = @_;
    $params{feed} ||= 0;

    $self->lf();
    if ( $params{feed} == 0 ) {
        $self->driver->write( _GS . 'V' . chr(1) );
    }
    else {
        $self->driver->write( _GS . 'V' . chr(66) . chr(0) );
    }

}


sub drawerKickPulse {
    my ( $self, $pin, $time ) = @_;
    $pin  = defined $pin  ? $pin  : 0;
    $time = defined $time ? $time : 8;

    $self->driver->write( _DLE . _DC4 . "\x01" . chr($pin) . chr($time) );
}

# End Peripheral Control Commands

# BEGIN: Printer STATUS methods


sub printerStatus {
    my ($self) = @_;

    my @flags =
      split( //,
        unpack( "B*", $self->driver->read( _DLE . _EOT . "\x01", 255 ) ) );
    return {
        drawer_pin3_high            => $flags[5],
        offline                     => $flags[4],
        waiting_for_online_recovery => $flags[2],
        feed_button_pressed         => $flags[1],
    };
}


sub offlineStatus {
    my ($self) = @_;

    my @flags =
      split( //,
        unpack( "B*", $self->driver->read( _DLE . _EOT . "\x02", 255 ) ) );
    return {
        cover_is_closed     => $flags[5],
        feed_button_pressed => $flags[4],
        paper_end           => $flags[2],
        error               => $flags[1],
    };
}


sub errorStatus {
    my ($self) = @_;

    my @flags =
      split( //,
        unpack( "B*", $self->driver->read( _DLE . _EOT . "\x03", 255 ) ) );
    return {
        auto_cutter_error     => $flags[4],
        unrecoverable_error   => $flags[2],
        autorecoverable_error => $flags[1],
    };
}


sub paperSensorStatus {
    my ($self) = @_;

    my @flags =
      split( //,
        unpack( "B*", $self->driver->read( _DLE . _EOT . "\x04", 255 ) ) );
    return {
        paper_roll_near_end_sensor_1 => $flags[5],
        paper_roll_near_end_sensor_2 => $flags[4],
        paper_roll_status_sensor_1   => $flags[2],
        paper_roll_status_sensor_2   => $flags[1],
    };
}


sub inkStatusA {
    my ($self) = @_;

    my @flags = split(
        //,
        unpack(
            "B*", $self->driver->read( _DLE . _EOT . "\x07" . "\x01", 255 )
        )
    );
    return {
        ink_near_end          => $flags[5],
        ink_end               => $flags[4],
        ink_cartridge_missing => $flags[2],
        cleaning_in_progress  => $flags[1],
    };
}


sub inkStatusB {
    my ($self) = @_;

    my @flags = split(
        //,
        unpack(
            "B*", $self->driver->read( _DLE . _EOT . "\x07" . "\x02", 255 )
        )
    );
    return {
        ink_near_end          => $flags[5],
        ink_end               => $flags[4],
        ink_cartridge_missing => $flags[2],
    };
}

# END: Printer STATUS methods

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Printer::ESCPOS::Profiles::Generic - Generic Profile for Printers for L<Printer::ESCPOS>. Most common functions are included here.

=head1 VERSION

version 1.006

=head1 METHODS

=head2 init

Initializes the Printer. Clears the data in print buffer and resets the printer to the mode that was in effect when the
power was turned on. This function is automatically called on creation of printer object.

=head2 enable

Enables/Disables the printer with a '_ESC =' command (Set peripheral device). When disabled, the printer ignores all
commands except enable() or other real-time commands.

Pass B<1> to enable, pass B<0> to disable

    $device->printer->enable(0) # disabled
    $device->printer->enable(1) # enabled

=head2 qr

Prints a qr code to the printer. In Generic profile, this creates a QR Code image using L<GD::Barcode::QRcode>. A native
implementation may be created using a printer model specific profile.

    $device->printer->qr('Print this QR Code');
    $device->printer->qr('WIFI:T:WPA;S:ShantanusWifi;P:wifipasswordhere;;')  # Create a QR code for connecting to a Wifi

You may also pass in optional QR Code format parameters like Ecc, Version and moduleSize. Read more about these params
at L<http://www.qrcode.com/en/about/version.html>.

I<string>: String to be printed as QR code.

I<ecc> (optional, default B<'L'>): error correction level. There are four available error correction schemes in QR codes.

=over

=item *

Level B<L> - up to 7% damage

=item *

Level B<M> - up to 15% damage

=item *

Level B<Q> - up to 25% damage

=item *

Level B<H> - up to 30% damage

=back

I<version> (optional, default B<5>): The symbol versions of QR Code range from Version B<1> to Version B<40>. Each
version has a different module configuration or number of modules. (The module refers to the black and white dots that
make up QR Code.)

Each QR Code symbol version has the maximum data capacity according to the amount of data, character type and error
correction level. In other words, as the amount of data increases, more modules are required to comprise QR Code,
resulting in larger QR Code symbols.

I<moduleSize> (optional, default B<3>): width of each module in pixels.

    my $ecc = 'L'; # Default value
    my $version = 5; # Default value
    my $moduleSize = 3; # Default value
    $device->printer->qr("Don't Panic!", $ecc, $version, $moduleSize);

You may also call align() before calling qr() to set alignment on the page.

=head2 utf8ImagedText

    use utf8;

    $device->printer->utf8ImagedText("Hello World\x{8A9E}",
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

You may also install more fonts from https://fonts.google.com/ to your system fonts( copy the font to /usr/share/fonts )

I<fontStyle> (optional, default B<'Normal'>): Font style like Bold, Normal, Italic etc.

I<fontSize> (optional, default B<20>): Font size

I<lineHeight> (optional, default B<42>): Line Height in pixels, make sure this is bigger than the font height in pixels for your chosen font size.

I<paperWidth> (optional, default B<500>): This is set to 500 pixels by default as this is the most common width for receipt printers. Change this
as per your printer specs.

=head2 image

Prints a image to the printer. Takes a L<GD> Image object as input. <Maximum printable image dimensions are 512x255

I<image>: L<GD> image object for the image to be printed.

    use GD;

    my $image = newFromGif GD::Image('header.gif') || die "Error $!";
    $device->printer->image($image);

You may also call align() before calling qr() to set alignment on the page.

=head2 printAreaWidth

Sets the Print area width specified by width.

    width x basic calculated pitch

I<width>: width is a 16 bits value range, i.e. int between B<0> to B<65535> specifying print area width in basic
calculated pitch. This command is effective only when processed at the beginning of the line when standard mode is being
used. Printable area width setting is effective until init is executed, the printer is reset, or the power is turned
off.

    $device->printer->printAreaWidth( $width );

Note: If you are using Printer::ESCPOS version prior to v1.* Please check documentation for older version of this module
the nL and nH syntax for this method.

=head2 tabPositions

Sets horizontal tab positions for tab stops. Upto 32 tab positions can be set in most receipt printers.

I<tabPositions>: a list of positions for tab().

    $device->printer->tabPositions( 5, 9, 13 );

    for my $plu (@plus) {
        $device->printer->text($plu->{quantity});
        $device->printer->tab();
        $device->printer->text(' x ' . $plu->{name});
        $device->printer->tab();
        $device->printer->text('$' . $plu->{price});
    }

This would print a well aligned receipt like so:

    10 x Guiness Beer              $24.00
    2  x Pizza                     $500.50
    1  x Tandoori Chicken          $50.20

Common tab positions are usually in intervals of 8 chars (9, 17, 25) etc.

=head2 tab

moves the cursor to next horizontal tab position like a "\t". This command is ignored unless the next horizontal tab
position has been set. You may substitute this command with a "\t" as well.

This

    $device->printer->text("blah blah");
    $device->printer->tab();
    $device->printer->text("blah2 blah2");

is same as this

    $device->printer->text("blah blah\tblah2 blah2");

=head2 lf

line feed. Moves to the next line. You can substitute this method with {"\n"} in your print or write method e.g. :

This

    $device->printer->text("blah blah");
    $device->printer->lf();
    $device->printer->text("blah2 blah2");

is same as this

    $device->printer->text("blah blah\nblah2 blah2");

=head2 ff

When in page mode, print data in the buffer and return back to standard mode

=head2 cr

Print and carriage return

When automatic line feed is enabled this method works the same as lf , else it is ignored.

=head2 cancel

Cancel (delete) page data in page mode

=head2 font

Set Font style, you can pass *a*, *b* or *c*. Many printers don't support style *c* and only have two supported styles.

I<font> (optional, default 'a'): Font to set for the printer

    $device->printer->font('a');
    $device->printer->text('Writing in Font A');
    $device->printer->font('b');
    $device->printer->text('Writing in Font B');

=head2 bold

Set bold mode *0* for off and *1* for on. Also called emphasized mode in some printer manuals

I<bold> (optional, default 0): 1 or 0 to set or unset bold.

    $device->printer->bold(1);
    $device->printer->text("This is Bold Text\n");
    $device->printer->bold(0);
    $device->printer->text("This is not Bold Text\n");

=head2 doubleStrike

Set double-strike mode *0* for off and *1* for on

I<doubleStrike> (optional, default 0): 1 or 0 to doubleStrike or unset doubleStrike.

    $device->printer->doubleStrike(1);
    $device->printer->text("This is Double Striked Text\n");
    $device->printer->doubleStrike(0);
    $device->printer->text("This is not Double Striked  Text\n");

=head2 underline

Set underline, *0* for off, *1* for on and *2* for double thickness

I<underline> (optional, default 0): 1 or 0 to underline or unset underline.

    $device->printer->underline(1);
    $device->printer->text("This is Underlined Text\n");
    $device->printer->underline(2);
    $device->printer->text("This is Underlined Text with thicker underline\n");
    $device->printer->underline(0);
    $device->printer->text("This is not Underlined Text\n");

=head2 invert

Reverse white/black printing mode pass *0* for off and *1* for on

I<invert> (optional, default 0): 1 or 0 to invert or unset invert.

    $device->printer->invert(1);
    $device->printer->text("This is Inverted Text\n");
    $device->printer->invert(0);
    $device->printer->text("This is not Inverted Text\n");

=head2 color

Most thermal printers support just one color, black. Some ESCPOS printers(especially dot matrix) also support a second
color, usually red. A few rarer models also support upto 7 different colors. In many models, this only works when the
color is set at the beginning of a new line before any text is printed. Pass *0* or *1* to switch between the two
colors.

I<color> (optional, default 0): color number 0, 1 ...

    $device->printer->lf();
    $device->printer->color(0); #black
    $device->printer->text("black");
    $device->printer->lf();
    $device->printer->color(1); #red
    $device->printer->text("Red");
    $device->printer->print();

=head2 justify

Set Justification. Options B<full>, B<left>, B<right> and B<center>

I<justify> (optional, default 'left'): B<full>, B<left>, B<right> or B<center>

    $device->printer->justify( 'right' );
    $device->printer->text("This is right justified");

=head2 upsideDown

Sets Upside Down Printing on/off (pass *0* or *1*)

I<upsideDown> (optional, default 0): B<0> or B<1>

    $device->printer->upsideDownPrinting(1);
    $device->printer->text("This text is upside down");

=head2 fontHeight

Set font height. Only supports *0* or *1* for printmode set to 1, supports values *0*, *1*, *2*, *3*, *4*, *5*, *6* and
*7* for non-printmode state (default)

I<height> (optional, default 0): B<0> to B<7>

    $device->printer->fontHeight(1);
    $device->printer->text("double height\n");
    $device->printer->fontHeight(2);
    $device->printer->text("triple height\n");
    $device->printer->fontHeight(3);
    $device->printer->text("quadruple height\n");
    . . .

=head2 fontWidth

Set font width. Only supports *0* or *1* for printmode set to 1, supports values *0*, *1*, *2*, *3*, *4*, *5*, *6* and
*7* for non-printmode state (default)

I<width> (optional, default 0): B<0> to B<7>

    $device->printer->fontWidth(1);
    $device->printer->text("double width\n");
    $device->printer->fontWidth(2);
    $device->printer->text("triple width\n");
    $device->printer->fontWidth(3);
    $device->printer->text("quadruple width\n");
    . . .

=head2 charSpacing

Sets character spacing takes a value between 0 and 255

I<charSpacing> (optional, default 0): B<0> to B<255>

    $device->printer->charSpacing(5);
    $device->printer->text("Blah Blah Blah\n");
    $device->printer->print();

=head2 lineSpacing

Sets line spacing i.e the spacing between each line of printout. Note that some printers may not support all
command sets for setting a line spacing. The most commonly available I<commandSet>('3') is used by default.

I<lineSpacing>: ranges from 0 to 255 when commandSet is '+' or '3',

Line spacing is set to lineSpacing/360 of an inch if commandSet is '+', lineSpacing/180 of an inch if commandSet is '3'
and lineSpacing/60 of an inch if commandSet is 'A' (default: 30)

I<commandSet>: ESCPOS provides three alternate commands for setting line spacing i.e. '+', '3', 'A' (default : '3').

    $device->printer->lineSpacing($lineSpacing); # Use default commandSet '3'
    $device->printer->lineSpacing($lineSpacing, $commandSet);

=head2 selectDefaultLineSpacing

Reverts to default line spacing for the printer

    $device->printer->selectDefaultLineSpacing();

=head2 printPosition

Sets the distance from the beginning of the line to the position at which characters are to be printed.

I<length>: ranges from 0 to 255

I<height>: ranges from 0 to 255

    $device->printer->printPosition( $length, $height );

* 0 <= $length <= 255
* 0 <= $height <= 255

=head2 leftMargin

Sets the left margin for printing. Set the left margin at the beginning of a line. The printer ignores any data
preceding this command on the same line in the buffer.

In page mode sets the left margin to leftMargin x (horizontal motion unit) from the left edge of the printable area

I<leftMargin>: Left Margin, range: B<0> to B<65535>. If the margin exceeds the printable area, the left margin is
automatically set to the maximum value of the printable area.

    $device->printer->leftMargin($leftMargin);

Note: If you are using Printer::ESCPOS version prior to v1.* Please check documentation for older version of this module
the nL and nH syntax for this method.

=head2 rot90

Rotate printout by 90 degrees

I<rotate> (optional, default 0): B<0> or B<1>

    $device->printer->rot90(1);
    $device->printer->text("This is rotated 90 degrees\n");
    $device->printer->rot90(0);
    $device->printer->text("This is not rotated 90 degrees\n");

=head2 barcode

This method prints a barcode to the printer. This can be bundled with other text formatting commands at the appropriate
point where you would like to print a barcode on your print out. takes argument ~barcode~ as the barcode value.

In the simplest form you can use this command as follows:

    #Default barcode printed in code93 system with a width of 2 and HRI Chars printed below the barcode
    $device->printer->barcode(
        barcode     => 'SHANTANU BHADORIA',
    );

However there are several customizations available including barcode ~system~, ~font~, ~height~ etc.

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

I<HRIPosition> (optional, default 'below'): 'none', 'above', 'below', 'aboveandbelow'

I<font> (optional, default 'b'): 'a' or 'b'

I<height> (optional, default 50): height integer between 0 and 255

I<width> (optional, default 50): width integer between 0 and 255

I<system> (optional, default 'CODE93'): B<UPC-A>, B<UPC-B>, B<JAN13>, B<JAN8>, B<CODE39>, B<ITF>, B<CODABAR>, B<CODE93>,
B<CODE128>

I<barcode>: String to print as barcode.

=head2 printNVImage

Prints bit image stored in Non-Volatile (NV) memory of the printer.

    $device->printer->printNVImage($flag);

I<flag>: height and width

* $flag = 0 # Normal width and Normal Height
* $flag = 1 # Double width and Normal Height
* $flag = 2 # Normal width and Double Height
* $flag = 3 # Double width and Double Height

=head2 printImage

Prints bit image stored in Volatile memory of the printer. This image gets erased when printer is reset.

    $device->printer->printImage($flag);

* $flag = 0 # Normal width and Normal Height
* $flag = 1 # Double width and Normal Height
* $flag = 2 # Normal width and Double Height
* $flag = 3 # Double width and Double Height

=head2 cutPaper

Cuts the paper,

I<feed> (optional, default 0): if ~feed~ is set to B<0> then printer doesnt feed paper to cutting position before
cutting it. The default behavior is that the printer doesn't feed paper to cutting position before cutting. One
pre-requisite line feed is automatically executed before paper cut though.

    $device->printer->cutPaper( feed => 0 )

While not strictly a text formatting option, in receipt printer the cut paper instruction is sent along with the rest of
the text and text formatting data and the printer cuts the paper at the appropriate points wherever this command is
used.

=head2 drawerKickPulse

Trigger drawer kick. Used to open cash drawer connected to the printer. In some use cases it may be used to trigger
other devices by close contact.

    $device->printer->drawerKickPulse( $pin, $time );

I<pin> (optional, default 0): $pin is either 0( for pin 2 ) and 1( for pin5 )

I<pin> (optional, default 8): $time is a value between 1 to 8 and the pulse duration in multiples of 100ms.

For default values use without any params to kick drawer pin 2 with a 800ms pulse

    $device->printer->drawerKickPulse();

Again like cutPaper command this is obviously not a text formatting command but this command is sent along with the rest
of the text and text formatting data and the printer sends the pulse at the appropriate points wherever this command is
used. While originally designed for triggering a cash drawer to open, in practice this port can be used for all sorts of
devices like pulsing light, or sound alarm etc.

=head2 printerStatus

Returns printer status in a hashref.

    return {
        drawer_pin3_high            => $flags[5],
        offline                     => $flags[4],
        waiting_for_online_recovery => $flags[2],
        feed_button_pressed         => $flags[1],
    };

=head2 offlineStatus

Returns a hashref for paper cover closed status, feed button pressed status, paper end stop status, and a aggregate
error status either of which will prevent the printer from processing a printing request.

    return {
        cover_is_closed     => $flags[5],
        feed_button_pressed => $flags[4],
        paper_end           => $flags[2],
        error               => $flags[1],
    };

=head2 errorStatus

Returns hashref with error flags for auto_cutter_error, unrecoverable error and auto-recoverable error

    return {
        auto_cutter_error     => $flags[4],
        unrecoverable_error   => $flags[2],
        autorecoverable_error => $flags[1],
    };

=head2 paperSensorStatus

Gets printer paper Sensor status. Returns a hashref with four sensor statuses. Two paper near end sensors and two paper
end sensors for printers supporting this feature. The exact returned status might differ based on the make of your
printer. If any of the flags is set to 1 it implies that the paper is out or near end.

    return {
        paper_roll_near_end_sensor_1 => $flags[5],
        paper_roll_near_end_sensor_2 => $flags[4],
        paper_roll_status_sensor_1 => $flags[2],
        paper_roll_status_sensor_2 => $flags[1],
    };

=head2 inkStatusA

Only available for dot-matrix and other ink consuming printers. Gets printer ink status for inkA(usually black ink).
Returns a hashref with ink statuses.

    return {
        ink_near_end          => $flags[5],
        ink_end               => $flags[4],
        ink_cartridge_missing => $flags[2],
        cleaning_in_progress  => $flags[1],
    };

=head2 inkStatusB

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
