use strict;
use warnings;

package Printer::ESCPOS;

# PODNAME: Printer::ESCPOS
# ABSTRACT: Interface for all thermal, dot-matrix and other receipt printers that support ESC-POS specification.
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
use Class::Load;
use Carp;
use Type::Tiny;
use aliased 'Printer::ESCPOS::Roles::Profile' => 'ESCPOSProfile';


has driverType => (
    is       => 'ro',
    required => 1,
);


has profile => (
    is      => 'ro',
    default => 'Generic',
);


has deviceFilePath => ( is => 'ro', );


has portName => ( is => 'ro', );


has deviceIP => ( is => 'ro', );


has devicePort => (
    is      => 'ro',
    default => '9100',
);


has baudrate => (
    is      => 'ro',
    default => 38400,
);


has serialOverUSB => (
    is      => 'ro',
    default => '1',
);


has vendorId => ( is => 'ro', );


has productId => ( is => 'ro', );


has endPoint => (
    is      => 'ro',
    default => 0x01,
);


has timeout => (
    is       => 'ro',
    required => 1,
    default  => 1000,
);

has _driver => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build__driver {
    my ($self) = @_;

    if ( $self->driverType eq 'File' ) {
        Class::Load::load_class('Printer::ESCPOS::Connections::File');
        return Printer::ESCPOS::Connections::File->new(
            deviceFilePath => $self->deviceFilePath, );
    }
    elsif ( $self->driverType eq 'Network' ) {
        Class::Load::load_class('Printer::ESCPOS::Connections::Network');
        return Printer::ESCPOS::Connections::Network->new(
            deviceIP   => $self->deviceIP,
            devicePort => $self->devicePort,
        );
    }
    elsif ( $self->driverType eq 'Serial' ) {
        Class::Load::load_class('Printer::ESCPOS::Connections::Serial');
        return Printer::ESCPOS::Connections::Serial->new(
            deviceFilePath => $self->deviceFilePath,
            baudrate       => $self->baudrate,
            serialOverUSB  => $self->serialOverUSB,
        );
    }
    elsif ( $self->driverType eq 'USB' ) {
        Class::Load::load_class('Printer::ESCPOS::Connections::USB');
        return Printer::ESCPOS::Connections::USB->new(
            productId => $self->productId,
            vendorId  => $self->vendorId,
            endPoint  => $self->endPoint,
            timeout   => $self->timeout,
        );
    }
}


has printer => ( is => 'lazy', );

sub _build_printer {
    my ($self) = @_;

    my $base  = __PACKAGE__ . "::Profiles::";
    my $class = $base . $self->profile;

    Class::Load::load_class($class);
    unless ( $class->does(ESCPOSProfile) ) {
        confess
"Class ${class} in ${base} does not implement the Printer::ESCPOS::Roles::Profile Interface";
    }
    my $object = $class->new( driver => $self->_driver, );

    $object->init();

    return $object;
}

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Printer::ESCPOS - Interface for all thermal, dot-matrix and other receipt printers that support ESC-POS specification.



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/shantanubhadoria/perl-Printer-ESCPOS"><img src="https://api.travis-ci.org/shantanubhadoria/perl-Printer-ESCPOS.svg?branch=build/master" alt="Travis status" /></a>
<a href="http://matrix.cpantesters.org/?dist=Printer-ESCPOS%201.006"><img src="http://badgedepot.code301.com/badge/cpantesters/Printer-ESCPOS/1.006" alt="CPAN Testers result" /></a>
<a href="http://cpants.cpanauthors.org/release/_/Printer-ESCPOS-1.006"><img src="http://badgedepot.code301.com/badge/kwalitee/_/Printer-ESCPOS/1.006" alt="Distribution kwalitee" /></a>
<a href="https://gratipay.com/shantanubhadoria"><img src="https://img.shields.io/gratipay/shantanubhadoria.svg" alt="Gratipay" /></a>
</p>

=end html

=head1 VERSION

version 1.006

=head1 SYNOPSIS

If you are just starting up with POS RECEIPT Printers, you must first refer to L<Printer::ESCPOS::Manual> to get started.

Printer::ESCPOS provides four different types of printer connections to talk to a ESCPOS printer.
As of v0.012 I<driverType> B<Serial>, B<Network>, B<File> and B<USB> are all implemented in this module. B<USB> I<driverType>
is not supported prior to v0.012.

=head2 USB Printer

B<USB> I<driverType> allows you to talk to your Printer using the I<vendorId> and I<productId> values for your printer.
These can be retrieved using lsusb command

     shantanu@shantanu-G41M-ES2L:~/github$ lsusb
     . . .
     Bus 003 Device 002: ID 1504:0006
     . . .

The output gives us the I<vendorId> 0x1504 and I<productId> 0x0006

For USB Printers L<Printer::ESCPOS> uses a default I<endPoint> of 0x01 and a default I<timeout> of
1000, however these can be specified manually in case your printer requires a different value.

     use Printer::ESCPOS;
 
     my $vendorId  = 0x1504;
     my $productId = 0x0006;
     my $device = Printer::ESCPOS->new(
         driverType     => 'USB',
         vendorId       => $vendorId,
         productId      => $productId,
     );
 
     use GD;
     my $img = newFromGif GD::Image('header.gif') || die "Error $!";
     $device->printer->image($img); # Takes a GD image object
 
     $device->printer->qr("Don't Panic!"); # Print a QR Code
 
     $device->printer->printAreaWidth(5000);
     $device->printer->text("Print Area Width Modified\n");
     $device->printer->printAreaWidth(); # Reset to default
     $device->printer->text("print area width reset\n");
     $device->printer->tab();
     $device->printer->underline(1);
     $device->printer->text("underline on\n");
     $device->printer->invert(1);
     $device->printer->text("Inverted Text\n");
     $device->printer->justification('right');
     $device->printer->text("Right Justified\n");
     $device->printer->upsideDown(1);
     $device->printer->text("Upside Down\n");
     $device->printer->cutPaper();
 
     $device->printer->print(); # Dispatch the above commands from module buffer to the Printer.

=head2 Network Printer

For Network Printers $port is 9100 in most cases but might differ depending on how
you have configured your printer

     use Printer::ESCPOS;
 
     my $printer_id = '192.168.0.10';
     my $port       = '9100';
     my $device = Printer::ESCPOS->new(
         driverType => 'Network',
         deviceIp   => $printer_ip,
         devicePort => $port,
     );
 
     # These commands won't actually send anything to the printer but will store all the
     # merged data including control codes to module buffer.
     $device->printer->printAreaWidth(7000);
     $device->printer->text("Print Area Width Modified\n");
     $device->printer->printAreaWidth(); # Reset to default
     $device->printer->text("print area width reset\n");
     $device->printer->tab();
     $device->printer->underline(1);
     $device->printer->text("underline on\n");
     $device->printer->invert(1);
     $device->printer->text("Inverted Text\n");
     $device->printer->justification('right');
     $device->printer->text("Right Justified\n");
     $device->printer->upsideDown(1);
     $device->printer->text("Upside Down\n");
     $device->printer->cutPaper();
 
     $device->printer->print(); # Dispatch the above commands from module buffer to the Printer.
                                # This command takes care of read text buffers for the printer.

=head2 Serial Printer

Use the B<Serial> I<driverType> for local printer connected on serial port(or a printer connected via
a physical USB port in USB to Serial mode), check syslog(Usually under E<sol>varE<sol>logE<sol>syslog)
for what device file was created for your printer when you connect it to your system(For
plug and play printers). You may also use a Windows port name like 'COM1', 'COM2' etc. as
deviceFilePath param when running this under windows. The Device::SerialPort claims to support this
syntax. (Drop me a email if you are able to make it work in windows as I have not tested it out yet)

     use Printer::ESCPOS;
     use Data::Dumper; # Just to get dumps of status functions supported for Serial driverType.
 
     my $path = '/dev/ttyACM0';
     $device = Printer::ESCPOS->new(
         driverType     => 'Serial',
         deviceFilePath => $path,
     );
 
     say Dumper $device->printer->printerStatus();
     say Dumper $device->printer->offlineStatus();
     say Dumper $device->printer->errorStatus();
     say Dumper $device->printer->paperSensorStatus();
 
     $device->printer->bold(1);
     $device->printer->text("Bold Text\n");
     $device->printer->bold(0);
     $device->printer->text("Bold Text Off\n");
 
     $device->printer->print();

=head2 File(Direct to Device File) Printer

A B<File> I<driverType> is similar to the B<Serial> I<driverType> in all functionality except that it
doesn't support the status functions for the printer. i.e. you will not be able to use
printerStatus, offlineStatus, errorStatus or paperSensorStatus functions

     use Printer::ESCPOS;
 
     my $path = '/dev/usb/lp0';
     $device = Printer::ESCPOS->new(
         driverType     => 'File',
         deviceFilePath => $path,
     );
 
     $device->printer->bold(1);
     $device->printer->text("Bold Text\n");
     $device->printer->bold(0);
     $device->printer->text("Bold Text Off\n");
 
     $device->printer->print();

=head1 DESCRIPTION

You can use this module for all your ESC-POS Printing needs. If some of your printer's functions are not included, you
may extend this module by adding specialized funtions for your printer in it's own subclass. Refer to
L<Printer::ESCPOS::Roles::Profile> and L<Printer::ESCPOS::Profiles::Generic>

=head1 ATTRIBUTES

=head2 driverType

"Required attribute". The driver type to use for your printer. This can be B<File>, B<Network>, B<USB> or B<Serial>.
If you choose B<File> or B<Serial> driver, you must provide the I<deviceFilePath>,
for B<Network> I<driverType> you must provide the I<printerIp> and I<printerPort>,
For B<USB> I<driverType> you must provide I<vendorId> and I<productId>.

USB driver type:

    my $vendorId  = 0x1504;
    my $productId = 0x0006;
    my $device = Printer::ESCPOS->new(
        driverType => 'USB'
        vendorId   => $vendorId,
        productId  => $productId,
    );

Network driver type:

    my $printer_id = '192.168.0.10';
    my $port       = '9100';
    my $device = Printer::ESCPOS->new(
        driverType => 'Network',
        deviceIp   => $printer_ip,
        devicePort => $port,
    );

Serial driver type:

    my $path = '/dev/ttyACM0';
    $device = Printer::ESCPOS->new(
        driverType     => 'Serial',
        deviceFilePath => $path,
    );

File driver type:

    my $path = '/dev/usb/lp0';
    $device = Printer::ESCPOS->new(
        driverType     => 'File',
        deviceFilePath => $path,
    );

=head2 profile

There are minor differences in ESC POS printers across different brands and models in terms of specifications and extra
features. For using special features of a particular brand you may create a sub class in the name space
Printer::ESCPOS::Profiles::* and load your profile here. I would recommend extending the Generic
Profile( L<Printer::ESCPOS::Profiles::Generic> ).
Use the following classes as examples.
L<Printer::ESCPOS::Profiles::Generic>
L<Printer::ESCPOS::Profiles::SinocanPSeries>

Note that your driver class will have to implement the Printer::ESCPOS::Roles::Profile Interface. This is a L<Moo::Role>
and can be included in your class with the following line.

    use Moo;
    with 'Printer::ESCPOS::Roles::Profile';

By default the generic profile is loaded but if you have written your own Printer::ESCPOS::Profile::* class and want to
override the generic class pass the I<profile> Param during object creation.

    my $device = Printer::ESCPOS->new(
        driverType => 'Network',
        deviceIp   => $printer_ip,
        devicePort => $port,
        profile    => 'USERCUSTOM'
    );

The above $device object will use the Printer::ESCPOS::Profile::USERCUSTOM profile.

=head2 deviceFilePath

File path for UNIX device file. e.g. "/dev/ttyACM0", or port name for Win32 (untested) like 'COM1', COM2' etc. This is a
mandatory parameter if you are using B<File> or B<Serial> I<driverType>. I haven't had a chance to test this on windows
so if you are able to successfully use this with a serial port on windows, drop me a email to let me know that I got it
right :)

=head2 portName

Win32 serial port name

=head2 deviceIP

Contains the IP address of the device when its a network printer. The module creates L<IO:Socket::INET> object to
connect to the printer. This can be passed in the constructor.

=head2 devicePort

Contains the network port of the device when its a network printer. The module creates L<IO:Socket::INET> object to
connect to the printer. This can be passed in the constructor.

=head2 baudrate

When used as a local serial device you can set the I<baudrate> of the printer too. Default (38400) will usually work,
but not always.

=head2 serialOverUSB

Set this value to 1 if you are connecting your printer using the USB Cable but it shows up as a serial device and you
are using the B<Serial> driver.

=head2 vendorId

This is a required param for B<USB> I<driverType>. It contains the USB printer's Vendor ID when using B<USB>
I<driverType>. Use lsusb command to get this value for your printer.

=head2 productId

This is a required param for B<USB> I<driverType>. It contains the USB printer's product Id when using B<USB>
I<driverType>. Use lsusb command to get this value for your printer.

=head2 endPoint

This is a optional param for B<USB> I<driverType>. It contains the USB endPoint for L<Device::USB> to write to if the
value is not 0x01 for your printer. Get it using the following command:

    shantanu@shantanu-G41M-ES2L:~$ sudo lsusb -vvv -d 1504:0006 | grep bEndpointAddress | grep OUT
            bEndpointAddress     0x01  EP 1 OUT

Replace 1504:0006 with your own printer's vendor id and product id in the above command.

=head2 timeout

Timeout for bulk write functions for the USB printer. Optional param.

=head2 printer

Use this attribute to send commands to the printer

    $device->printer->setFont('a');
    $device->printer->text("blah blah blah\n");

=head1 USAGE

Refer to the following manual to get started with L<Printer::ESCPOS>

=over

=item *

L<Printer::ESCPOS::Manual>

=back

=head2 Quick usage summary in steps:

=over

=item 1.

Create a device object $device by providing parameters for one of the supported printer types. Call
$device-E<gt>printer-E<gt>init to initialize the printer.

=item 2.

call text() and other Text formatting functions on $device-E<gt>printer for the data to be sent to the printer. Make sure
to end it all with a linefeed $device-E<gt>printer-E<gt>lf().

=item 3.

Then call the print() method to dispatch the sequences from the module buffer to the printer

=back

     $device->printer->print()

Note: While you may call print() after every single command code, this is not advisable as some printers tend to choke
up if you send them too many print commands in quick succession. To avoid this, aggregate the data to be sent to the
printer with text() and other text formatting functions and then send it all in one go using print() at the very end.

=head1 NOTES

=over

=item *

In Serial mode if the printer prints out garbled characters instead of proper text, try specifying the baudrate
parameter when you create the printer object. The default baudrate is set at 38400

=back

     $device = Printer::ESCPOS->new(
         driverType     => 'Serial',
         deviceFilePath => $path,
         baudrate       => 9600,
     );

=over

=item *

For ESC-P codes refer the guide from Epson L<http://support.epson.ru/upload/library_file/14/esc-p.pdf>

=back

=head1 SEE ALSO

=over

=item *

L<Printer::ESCPOS::Manual>

=item *

L<Printer::ESCPOS::Profiles::Generic>

=item *

L<Printer::ESCPOS::Profiles::SinocanPSeries>

=item *

L<Printer::ESCPOS::Roles::Profile>

=item *

L<Printer::ESCPOS::Roles::Connection>

=item *

L<Printer::ESCPOS::Connections::USB>

=item *

L<Printer::ESCPOS::Connections::Serial>

=item *

L<Printer::ESCPOS::Connections::Network>

=item *

L<Printer::ESCPOS::Connections::File>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/perl-printer-escpos/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/perl-printer-escpos>

  git clone git://github.com/shantanubhadoria/perl-printer-escpos.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 CONTRIBUTORS

=for stopwords Dominic Sonntag Shantanu Bhadoria

=over 4

=item *

Dominic Sonntag <dominic@s5g.de>

=item *

Shantanu Bhadoria <shantanu att cpan dott org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
