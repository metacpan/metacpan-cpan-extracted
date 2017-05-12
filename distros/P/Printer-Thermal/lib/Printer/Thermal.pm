use strict;
use warnings;

package Printer::Thermal;

# PODNAME: Printer::Thermal
# ABSTRACT: Interface for Thermal and some dot-matrix and inkjet Printers that support ESC-POS specification (Deprecated) - Use L<Printer::ESCPOS> instead
#
# This file is part of Printer-Thermal
#
# This software is copyright (c) 2015 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.29'; # VERSION

# Dependencies
use 5.010;
use Moose;
use POSIX;

use Device::SerialPort;
use IO::File;
use IO::Socket;
use Time::HiRes qw(usleep);


has usb_device_path => (
    is  => 'ro',
    isa => 'Str',
);


has serial_device_path => (
    is  => 'ro',
    isa => 'Str',
);


has device_ip => (
    is  => 'ro',
    isa => 'Str',
);


has device_port => (
    is  => 'ro',
    isa => 'Int',
);


has baudrate => (
    is      => 'ro',
    isa     => 'Int',
    default => 38400,
);


has read_char_time => (
    is      => 'ro',
    isa     => 'Int',
    default => 30,
);


has read_const_time => (
    is      => 'ro',
    isa     => 'Int',
    default => 3000,
);


has black_threshold => (
    is      => 'ro',
    isa     => 'Int',
    default => 48,
);


has alpha_threshold => (
    is      => 'ro',
    isa     => 'Int',
    default => 127,
);


has heatTime => (
    is      => 'ro',
    isa     => 'Int',
    default => 120,
);


has heatInterval => (
    is      => 'ro',
    isa     => 'Int',
    default => 50,
);


has heatingDots => (
    is      => 'ro',
    isa     => 'Int',
    default => 7,
);


has printer => (
    is         => 'ro',
    lazy_build => 1,
);


has print_string => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);


has font => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);


has underline => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);


has emphasized => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);


has double_height => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);


has double_width => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

my $_ESC = chr(27);
my $_GS  = chr(29);

sub _build_printer {
    my ($self) = @_;
    my $printer;
    if ( $self->serial_device_path ) {
        $printer = Device::SerialPort->new( $self->serial_device_path );
        $printer->baudrate( $self->baudrate );
    }
    elsif ( $self->usb_device_path ) {
        $printer = new IO::File ">>" . $self->usb_device_path;
    }
    else {
        $printer = IO::Socket::INET->new(
            Proto    => "tcp",
            PeerAddr => $self->device_ip,
            PeerPort => $self->device_port,
            Timeout  => 1,
        ) or die " Can't connect to printer";
    }
    $printer->write($_ESC);
    $printer->write( chr(64) );    # @ initialize
    $printer->write($_ESC);
    $printer->write( chr(55) );    # 7 - print settings
    $printer->write( chr( $self->heatingDots ) )
      ;    # Heating dots (20=balance of darkness vs no jams) default = 20

# Description of print density from page 23 of the manual:
# DC2 # n Set printing density
# Decimal: 18 35 n
# D4..D0 of n is used to set the printing density. Density is 50% + 5% * n(D4-D0) printing density.
# D7..D5 of n is used to set the printing break time. Break time is n(D7-D5)*250us.
    my $printDensity   = 15;  # 120% (? can go higher, text is darker but fuzzy)
    my $printBreakTime = 15;  # 500 uS
    $printer->write($_GS);
    $printer->write( chr(40) );
    $printer->write( chr(78) );
    return $printer;
}


sub print {
    my ($self) = @_;
    my $printer = $self->printer;
    my @chunks;
    my $string = $self->print_string;
    my $n      = 100;                   # Size of each chunk in bytes
    @chunks = unpack "a$n" x ( ( length($string) / $n ) - 1 ) . "a*", $string;
    for my $chunk (@chunks) {
        $printer->write($chunk);
        usleep(2000);
    }
    $self->print_string("");
}


sub write {
    my ( $self, $string ) = @_;
    $self->print_string( $self->print_string . $string );
}


sub left_margin {
    my ( $self, $nl, $nh ) = @_;
    $self->linefeed();
    $self->write($_GS);
    $self->write( chr(76) );
    $self->write( chr($nl) );
    $self->write( chr($nh) );
}


sub reset {
    my ($self) = @_;
    my $printer = $self->printer;
    $printer->write($_ESC);
    $printer->write( chr(64) );
}


sub right_side_character_spacing {
    my ( $self, $spacing ) = @_;
    if ( $spacing <= 255 && $spacing >= 0 ) {
        $self->write($_ESC);
        $self->write( chr(32) );
        $self->write( chr($spacing) );
    }
}


sub horiz_tab {
    my ($self) = @_;
    $self->write( chr(9) );
}


sub line_spacing {
    my ( $self, $value ) = @_;
    if ( $value
        && ( $value <= 255 && $value >= 0 ) )
    {
        $self->write($_ESC);
        $self->write( chr(51) );
        $self->write( chr($value) );
    }
    else {
        #reset to default spacing
        $self->write($_ESC);
        $self->write( chr(50) );
    }
}


sub linefeed {
    my ($self) = @_;
    $self->write( chr(10) );
}


sub justify {
    my ( $self, $align ) = @_;
    my $pos = 0;
    if ( $align eq "L" ) {
        $pos = 0;
    }
    elsif ( $align eq "C" ) {
        $pos = 1;
    }
    elsif ( $align eq "R" ) {
        $pos = 2;
    }
    $self->write($_ESC);
    $self->write( chr(97) );
    $self->write( chr($pos) );
}


sub bold_off {
    my ($self) = @_;
    $self->emphasized(0);
    $self->_apply_printmode();
}


sub bold_on {
    my ($self) = @_;
    $self->emphasized(1);
    $self->_apply_printmode();
}


sub doublestrike_off {
    my ($self) = @_;
    $self->write($_ESC);
    $self->write( chr(71) );
    $self->write( chr(0) );
}


sub doublestrike_on {
    my ($self) = @_;
    $self->write($_ESC);
    $self->write( chr(71) );
    $self->write( chr(1) );
}


sub emphasize_off {
    my ($self) = @_;
    $self->write($_ESC);
    $self->write( chr(69) );
    $self->write( chr(0) );
}


sub emphasize_on {
    my ($self) = @_;
    $self->write($_ESC);
    $self->write( chr(69) );
    $self->write( chr(255) );
}


sub font_size {
    my ( $self, $size ) = @_;
    $self->write($_GS);
    $self->write( chr(33) );
    $self->write( chr($size) );
}


sub font_size_esc {
    my ( $self, $size ) = @_;
    $self->write($_ESC);
    $self->write( chr(33) );
    $self->write( chr($size) );
}


sub font_b {
    my ($self) = @_;

    #$self->write($_ESC);
    #$self->write(chr(77));
    #$self->write(chr(1));
    $self->font(1);
    $self->_apply_printmode();
}


sub font_a {
    my ($self) = @_;

    #$self->write($_ESC);
    #$self->write(chr(77));
    #$self->write(chr(0));
    $self->font(0);
    $self->_apply_printmode();
}

sub _apply_printmode {
    my ($self)        = @_;
    my $font          = $self->font;
    my $underline     = $self->underline;
    my $emphasized    = $self->emphasized;
    my $double_height = $self->double_height;
    my $double_width  = $self->double_width;
    my $value =
      $font +
      ( $emphasized * 8 ) +
      ( $double_height * 16 ) +
      ( $double_width * 32 ) +
      ( $underline * 128 );
    $self->write($_ESC);
    $self->write( chr(33) );
    $self->write( chr($value) );
}


sub underline_off {
    my ($self) = @_;

    #$self->write($_ESC);
    #$self->write(chr(45));
    #$self->write(chr(0));
    $self->underline(0);
    $self->_apply_printmode();
}


sub underline_on {
    my ($self) = @_;

    #$self->write($_ESC);
    #$self->write(chr(45));
    #$self->write(chr(1));
    $self->underline(1);
    $self->_apply_printmode();
}


sub inverse_off {
    my ($self) = @_;
    $self->write($_GS);
    $self->write( chr(66) );
    $self->write( chr(0) );
}


sub inverse_on {
    my ($self) = @_;
    $self->write($_GS);
    $self->write( chr(66) );
    $self->write( chr(1) );
}


sub barcode_height {
    my ( $self, $height ) = @_;
    $self->write($_GS);
    $self->write( chr(104) );
    $self->write( chr($height) );
}


sub print_barcode {
    my ( $self, $type, $string ) = @_;
    $self->write($_GS);
    $self->write( chr(107) );
    $self->write( chr(65) );
    $self->write( chr($type) );
    $self->write($string);
}


sub print_text {
    my ( $self, $msg, $chars_per_line ) = @_;
    if ($chars_per_line) {
        my $le = length($msg);
        my @substrings;
        push @substrings, substr $msg, 0, $chars_per_line, '' while length $msg;
        $self->write( join "\n", @substrings );
    }
    else {
        $self->write($msg);
    }
}


sub print_bitmap {
    my ( $self, $pixels, $w, $h, $output_png ) = @_;
    my $counter = 0;
    if ($output_png) {
    }
    $self->linefeed();
    $self->write($_GS);
    $self->write( chr(118) );
    $self->write( chr(48) );
    $self->write( chr(48) );
    $self->write( chr(50) );
    $self->write( chr(50) );
}


sub color_1 {
    my ( $self, $color ) = @_;
    $self->linefeed();
    $self->write($_ESC);
    $self->write( chr(114) );
    $self->write( chr(0) );
}


sub color_2 {
    my ( $self, $color ) = @_;
    $self->linefeed();
    $self->write($_ESC);
    $self->write( chr(114) );
    $self->write( chr(1) );
}


sub cutpaper {
    my ($self) = @_;
    $self->linefeed();
    $self->write($_GS);
    $self->write( chr(86) );
    $self->write( chr(0) );
    $self->write( chr(255) );
}


sub open_cash_drawer {
    my ($self) = @_;
    $self->write($_ESC);
    $self->write( chr(112) );
    $self->write( chr(0) );
    $self->write( chr(50) );
    $self->write( chr(250) );
}


sub test {
    my ($self) = @_;
    $self->write("Write Stuff before linefeed");

    $self->left_margin( 1, 0 );
    $self->write("Set left margin 1,0");
    $self->left_margin( 20, 0 );
    $self->write("Set left margin 20,0");
    $self->left_margin( 1, 0 );

    #$self->barcode_height(68);
    #$self->print_barcode();

    $self->right_side_character_spacing(1);
    $self->write("Rgt chr space: 1 space");
    $self->right_side_character_spacing(8);
    $self->write(" 8 space");
    $self->right_side_character_spacing(0);
    $self->linefeed();

    $self->horiz_tab();
    $self->write("Tab before this line");
    $self->linefeed();

    $self->write("Part of this line ");
    $self->bold_on();
    $self->write("is bold");
    $self->bold_off();
    $self->linefeed();

    $self->write("default ");
    $self->doublestrike_on();
    $self->write("doublestrike on ");
    $self->doublestrike_off();
    $self->write("doublestrike off");
    $self->linefeed();

    $self->write("default ");
    $self->emphasize_on();
    $self->write("emphasize on ");
    $self->emphasize_off();
    $self->write("emphasize off");
    $self->linefeed();

    $self->write("default ");
    $self->font_b();
    $self->write("font b ");
    $self->font_a();
    $self->write("font a");
    $self->linefeed();

    $self->write("default ");
    $self->underline_on();
    $self->write("underline on");
    $self->underline_off();
    $self->write(" underline off");
    $self->linefeed();

    $self->write("default ");
    $self->inverse_on();
    $self->write("inverse on");
    $self->inverse_off();
    $self->write(" inverse off");
    $self->linefeed();

    $self->write("This line is in default color");
    $self->color_2();
    $self->write("This line is in color 2");
    $self->color_1();
    $self->write("This line is in color 1");
    $self->linefeed();

    $self->print_text("Sizes");
    $self->linefeed();
    $self->font_size(0);
    $self->print_text("Size 0");
    $self->linefeed();
    $self->font_size(16);
    $self->print_text("Size 16");
    $self->linefeed();
    $self->font_size(32);
    $self->print_text("Size 32");
    $self->linefeed();
    $self->font_size(48);
    $self->print_text("Size 48");
    $self->linefeed();
    $self->font_size(64);
    $self->print_text("Size 64");
    $self->linefeed();
    $self->font_size(80);
    $self->print_text("Size 80");
    $self->linefeed();
    $self->font_size(96);
    $self->print_text("Size 96");
    $self->linefeed();
    $self->font_size(112);
    $self->print_text("Size 112");
    $self->linefeed();
    $self->font_size(200);
    $self->print_text("Max 200");
    $self->linefeed();
    $self->font_size(255);
    $self->print_text("Max 255");
    $self->linefeed();
    $self->font_size(0);

    $self->print_text("ESC Sizes");
    $self->linefeed();
    $self->font_size_esc(0);
    $self->print_text("Size 0");
    $self->linefeed();
    $self->font_size_esc(16);
    $self->print_text("Size 16");
    $self->linefeed();
    $self->font_size_esc(32);
    $self->print_text("Size 32");
    $self->linefeed();
    $self->font_size_esc(48);
    $self->print_text("Size 48");
    $self->linefeed();
    $self->font_size(0);

    $self->print_string("");

    $self->write("default ");
    $self->font_b();
    $self->write("font b ");
    $self->font_a();
    $self->write("font a");

    $self->write("default ");
    $self->underline_on();
    $self->write("underline on");
    $self->underline_off();
    $self->write(" underline off");
    $self->linefeed();

    $self->linefeed();
    $self->linefeed();
    $self->linefeed();
    $self->linefeed();
    $self->linefeed();
    $self->linefeed();

    $self->cutpaper();

    $self->print();
    $self->bold_on();
    $self->print_text("line is bold\n");
    $self->bold_off();
    $self->font_b( 1, 0, 0 );
    $self->print_text("line is fontB\n");
    $self->print_text("Part of this is different font\n");
    $self->font_size(0);
    $self->print_text("Sizes\n");
    $self->font_size(16);
    $self->print_text("Sizes\n");
    $self->font_size(32);
    $self->print_text("Sizes\n");
    $self->font_size(48);
    $self->print_text("Sizes\n");
    $self->font_size(64);
    $self->print_text("Sizes\n");
    $self->font_size(80);
    $self->print_text("Sizes\n");
    $self->font_size(96);
    $self->print_text("Sizes\n");
    $self->font_size(112);
    $self->print_text("Sizes\n");
    $self->font_size(0);
    $self->font_a( 0, 0, 0 );
    $self->print_text("Part of this ");
    $self->emphasize_on();
    $self->print_text("line is Emphasized\n");
    $self->emphasize_off();
    $self->print_text("Part of this ");
    $self->doublestrike_on();
    $self->print_text("line is double striked\n");
    $self->doublestrike_off();
    $self->print_text("Part of this ");
    $self->inverse_on();
    $self->print_text("line is Inverted\n");
    $self->inverse_off();
    $self->justify("R");
    $self->print_text("right justified\r");
    $self->justify("C");
    $self->print_text("centered\r");
    $self->justify("L");    # justify("L") works too
    $self->print_text("left justified\r");
    $self->linefeed();
    $self->linefeed();
    $self->linefeed();
    $self->linefeed();

    #$self->print_string("");
    $self->linefeed();
    $self->color_2();
    $self->print_text("Part of this\n");
    $self->color_1();
    $self->print_text("is in a different color\n");
    $self->color_2();
    $self->print_text("is in a different color\n");
    $self->linefeed();

    #$self->print_string("");
    $self->write($_ESC);
    $self->write( chr(30) );
    $self->write( chr(67) );
    $self->write( chr(48) );
    $self->linefeed();
    $self->write($_ESC);
    $self->write( chr(52) );
    $self->linefeed();
    $self->print_text("is in a different color\n");
    $self->linefeed();
    $self->write($_ESC);
    $self->write( chr(53) );
    $self->linefeed();
    $self->print_text("is in a different color\n");
    $self->linefeed();
    $self->write($_ESC);
    $self->write( chr(52) );
    $self->linefeed();
    $self->print_text("is in a different color\n");
    $self->linefeed();
    $self->linefeed();
    $self->linefeed();
    $self->linefeed();
    $self->linefeed();
    $self->cutpaper();
    $self->print();

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Printer::Thermal - Interface for Thermal and some dot-matrix and inkjet Printers that support ESC-POS specification (Deprecated) - Use L<Printer::ESCPOS> instead

=head1 VERSION

version 0.29

=head1 SYNOPSIS

   use Printer::Thermal;
 
   #For Network Printers $port is 9100 in most cases but might differ depending on how you have configured your printer
   $printer = Printer::Thermal->new(device_ip=>$printer_ip,device_port=>$port);
 
   #These commands won't actually send anything to the printer but it will store all the merged data including control codes to send to printer in $printer->print_string variable.
   $printer->write("Blah Blah \nReceipt Details\nFooter");
   $printer->bold_on();
   $printer->write("Bold Text");
   $printer->bold_off();
   $printer->print(); ##Sends the above set of code to the printer. Clears the buffer text in module.
 
   #For local printer connected on serial port, check syslog(Usually under /var/log/syslog) for what device file was created for your printer when you connect it to your system(For plug and play printers).
   my $path = '/dev/ttyACM0';
   $printer = Printer::Thermal->new(serial_device_path=$path);
   $printer->write("Blah Blah \nReceipt Details\nFooter");
   $printer->bold_on();
   $printer->write("Bold Text");
   $printer->bold_off();
   $printer->print();
 
   #For local printer connected on usb port, check syslog(Usually under /var/log/syslog) for what device file was created for your printer when you connect it to your system(For plug and play printers).
   my $path = '/dev/usb/lp0';
   $printer = Printer::Thermal->new(usb_device_path=$path);
   $printer->write("Blah Blah \nReceipt Details\nFooter");
   $printer->bold_on();
   $printer->write("Bold Text");
   $printer->bold_off();
   $printer->print();

=head1 DESCRIPTION

This Module is deprecated in favour of L<Printer::ESCPOS>, which is the shiny new successor to this module. L<Printer::Thermal> will continue to work and might receive occasional support and bug fixes but no new features. Read the See Also section for reasons on why I deprecated L<Printer::Thermal> in favour of a new namespace instead of upgrading the existing module. For those who are already using L<Printer::Thermal>, have simple needs and are happy with what this module provides, they can avoid the switch to L<Printer::ESCPOS> as that module does not have a interface compatible with L<Printer::Thermal> and might involve some work switching over. If you are starting a new project or if you want the support for brand new features like printing logos etc., then you must use L<Printer::ESCPOS>.

For ESC-P codes refer the guide from Epson http:E<sol>E<sol>support.epson.ruE<sol>uploadE<sol>library_fileE<sol>14E<sol>esc-p.pdf

=head1 ATTRIBUTES

=head2 usb_device_path

This variable contains the path for the printer device file when connected as a usb device on UNIX-like systems. I haven't added support for Windows and it probably wont work in doz as a local printer without some modifications. Feel free to try it out and let me know what happens. This must be passed in the constructor

=head2 serial_device_path

This variable contains the path for the printer device file when connected as a serial device on UNIX-like systems. I haven't added support for Windows and it probably wont work in doz as a local printer without some modifications. Feel free to try it out and let me know what happens. This must be passed in the constructor

=head2 device_ip

Contains the IP address of the device when its a network printer. The module creates IO:Socket::INET object to connect to the printer. This can be passed in the constructor.

=head2 device_port

Contains the network port of the device when its a network printer. The module creates IO:Socket::INET object to connect to the printer. This can be passed in the constructor.

=head2 baudrate

When used as a local serial device you can set the baudrate of the printer too. Default (38400) will usually work, but not always. 

This param may be specified when creating printer object to make sure it works properly.

$printer = Printer::Thermal->new(serial_device_path => '/dev/ttyACM0', baudrate => 9600);

=head2 read_char_time

*DECRECATED*

=head2 read_const_time

*DECRECATED*

=head2 black_threshold 

Black ink threshold, This param may be specified when creating the printer object. Default is 48.

=head2 alpha_threshold 

Alpha threshold, This param may be specified when creating the printer object. Default is 127.

=head2 heatTime

Heating time to set for Supported Thermal Printers, this affects dot intensity.

This param may be specified when creating the printer object. Default is 120

=head2 heatInterval

This param may be specified when creating the printer object. Default is 50

=head2 heatingDots

This param may be specified when creating the printer object. Default is 7

=head2 printer

This is the direct device handle to the printer, You must almost never use this.
Unless you are hacking through the module. If you are using this you must send me
a bug report on why you had to use this.

You can access it with $printer->printer

=head2 print_string

This contains the string in the module buffer that will be sent to the printer when you call $printer->print();

my $print_string = $printer->print_string

=head2 font

Set ESC-POS Font

=head2 underline

Set/unset underline property

=head2 emphasized

Set/unset emphasized property

=head2 double_height

set unset double height property

=head2 double_width

set unset double width property

=head1 METHODS

=head2 print

$printer->print()
Sends the accumulated commands to the printer. All commands below need to be followed by a print() to send the data from buffer to the printer. You may call more than one printer command and then call print to send them all to printer together.
The following bunch of commands print a text to a printer, move down one line, and cut the receipt paper.

    $printer->write("hello Printer\n");
    $printer->linefeed();
    $printer->cutpaper();
    $printer->print(); # Sends the all the commands before this to the printer in one go. 

=head2 write

$printer->write("some text\n")
Writes a bunch of text that you pass here to the module buffer. 
Note that this will not be passed to the printer till you call $printer->print()

=head2 left_margin

$printer->left_margin($nl,$nh)
Sets the left margin code to the printer. takes two single byte parameters, $nl and $nh.
To determine the value of these two bytes, use the INT and MOD conventions. INT indicates the integer (or whole number) part of a number, while MOD indicates the
remainder of a division operation.
For example, to break the value 520 into two bytes, use the following two equations:
nH = INT 520/256
nL = MOD 520/256

=head2 reset

Resets the printer 

=head2 right_side_character_spacing

Takes a one byte number, spacing as a parameter

=head2 horiz_tab

Adds a horizontal tab character like a \t to the print string.

=head2 line_spacing

Allows you to set the line spacing for the printer.

=head2 linefeed

Sends a new line character, i.e carriage return and line feed

=head2 justify

$alignment can be either 'L','C' or 'R' for left center and right justified printing

=head2 bold_off

Turns bold printing off

=head2 bold_on

Turns bold printing on

=head2 doublestrike_off

Turns doublestrike on characters off

=head2 doublestrike_on

Turns doublestrike on characters on

=head2 emphasize_off

Turns off emphasize(read ESC-POS documentation)

=head2 emphasize_on

Turns on emphasize(read ESC-POS documentation)

=head2 font_size

Defined Region
0 <= n <= 255
However, 1 <= vertical direction magnification ratio <= 8, 1 <= horizontal direction magnification ratio <= 8
Initial Value n=0
Function Specifies the character size (magnification ratio in the vertical and horizontal directions).

=head2 font_size_esc

Set ESC specified font size

    $printer->font_size_esc($size);

=head2 font_b

Switches printing to font b

=head2 font_a

Switches printing to font a

=head2 underline_off

Switches off underline

=head2 underline_on

Switches on underline

=head2 inverse_off

Switches off inverse text

=head2 inverse_on

Switches on inverse text

=head2 barcode_height

Sets barcode height

=head2 print_barcode

$printer->print_barcode($type,$string)
Prints barcode

=head2 print_text

$printer->print_text($msg,$chars_per_line);
Prints some text defined by msg. If chars_per_line is defined, inserts newlines after the given amount. Use normal '\n' line breaks for empty lines.

=head2 print_bitmap

To be done: This function is not implemented yet.

=head2 color_1

Prints in first color for dual color printers

=head2 color_2

Prints in second color for dual color printers

=head2 cutpaper

Cuts the paper. Most Thermal receipt printers support the facility to cut the receipt using this command once printing is done.

=head2 open_cash_drawer

Opens the Cash Drawer connected to the thermal printer.

=head2 test

Prints a bunch of test strings to see if your printer is working fine/connected properly. Don't worry if some things like emphasized and double strike looks the same, it happened with my printer too.

=head1 NOTES

=over

=item *

If the printer prints out garbled characters instead of proper text, try specifying the baudrate parameter when creating printer object when you create the printer object(not for network or USB printers)

=back

     $printer = Printer::Thermal->new(serial_device_path => '/dev/ttyACM0', baudrate => 9600);

=head1 USAGE

=over

=item *

This Module offers a object oriented interface to ESC-POS Printers. 

=item *

Create a printer object by providing parameters for one of the three types of 
printers supported.

=item *

then call formatting options or write() text to printer object in sequence. 

=item *

Then call the print() method to dispatch the sequences from the module buffer 
to the printer. 

=back

Note: While you may call print() after every single command code, this is not advisable as some printers tend to choke up if you send them too many commands too quickly.

=head1 SEE ALSO

L<Printer::ESCPOS> is the new module that will take over the Perl support for ESC-POS receipt printers. Why did I choose to deprecate L<Printer::Thermal> for L<Printer::ESCPOS> instead of upgrading it? Read on if you are curious

=over

=item *

When I started writing L<Printer::Thermal> I was working with Thermal printers for my own requirements and wanted to write something that would work with all Thermal Printers. As I discovered after a couple of releases of L<Printer::Thermal>, the ESC-POS specification is a broad command specification for POS printers and it has nothing to do with the print technology itself thermal or others, so the name of the module was a big misnomer and it led to lot of confusion as to question of what the module was actually for.

=item *

L<Printer::Thermal> module was only intended for supporting thermal printers but it worked quiet well with other printer types. The way receipt printers work there was no reason to have a module specifically for thermal printers. So this Printer::Thermal name started to make me uneasy.

=item *

There are those have minimal printing needs from their POS printers, they are already using L<Printer::Thermal> and are happy with it. There is no reason for them to switch over unless they start a new project. For newer users it makes sense to start with a module that will have future supports and adds a wider range of flexible functions for ESC-POS Printers.

=item *

Last but not the least important reason, I wanted to make two things user-expandable: Printer connection(USB, Serial, Network etc.) and Printer Model Profiles(As I discovered that while most printer had more or less common command codes, They all had their own feature sets which borrowed most commands from a subset of ESCPOS. So I wanted users to be able to create their own profiles of supported commands to allow community effort for expansion of module functionality. Adding these two to existing module would have broken backward compatibility. L<Printer::ESCPOS> will have better interfaces for users to add their own connection types and printer profiles.

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/perl-printer-thermal/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/perl-printer-thermal>

  git clone git://github.com/shantanubhadoria/perl-printer-thermal.git

=head1 AUTHOR

Shantanu Bhadoria (shantanu@cpan.org)

=head1 CONTRIBUTOR

=for stopwords Shantanu Bhadoria

Shantanu Bhadoria <shantanu att cpan dott org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
