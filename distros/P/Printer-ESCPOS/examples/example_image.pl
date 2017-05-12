use strict;
use warnings;

use 5.010;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Printer::ESCPOS;
use GD;
use Data::Dumper;

my $printer_usb = Printer::ESCPOS->new(
    driverType => 'USB',
    vendorId   => 0x1504,
    productId  => 0x0006,
    endPoint   => 0x01
);
my $img = newFromGif GD::Image('examples/header.gif') || die "undo $!";
$printer_usb->printer->image($img);
$printer_usb->printer->print();
