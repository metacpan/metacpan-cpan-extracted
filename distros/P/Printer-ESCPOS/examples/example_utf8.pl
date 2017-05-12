use strict;
use warnings;

use 5.010;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Printer::ESCPOS;
use Data::Dumper;

my $printer_network = Printer::ESCPOS->new(
    driverType => 'Network',
    deviceIP   => '10.0.13.108',
    devicePort => '9100',
);

$printer_network->printer->init();

$printer_network->printer->utf8ImagedText("Asfadaf");
$printer_network->printer->lf();
$printer_network->printer->lf();
$printer_network->printer->lf();
$printer_network->printer->lf();
$printer_network->printer->cutPaper( feed => '0');
$printer_network->printer->print();
