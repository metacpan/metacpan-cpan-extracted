use strict;
use warnings;

use 5.010;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Printer::ESCPOS;
use Data::Dumper;

my $printer_file = Printer::ESCPOS->new(
    driverType     => 'File',
    deviceFilePath => '/dev/usb/lp0',
);

$printer_file->printer->init();

$printer_file->printer->barcode(
    barcode     => 'SHANTANU BHADORIA',
);
$printer_file->printer->usePrintMode(0);

$printer_file->printer->printNVImage(0);
$printer_file->printer->drawerKickPulse();

$printer_network->printer->lf();
$printer_network->printer->write("print width nH = 1 & nL = 0 for next line");
$printer_network->printer->printAreaWidth( nL => 0, nH => 1);
$printer_network->printer->write("blah blah blah blah blah blah blah blah blah blah blah");
$printer_network->printer->printAreaWidth(); # Reset to default
$printer_network->printer->write("print are width nL = 200 & nH = 0 for next line");
$printer_network->printer->printAreaWidth( nL => 200, nH => 0);
$printer_network->printer->write("blah blah blah blah blah blah blah blah blah blah blah");
$printer_network->printer->printAreaWidth(); # Reset to default

$printer_network->printer->tab();
$printer_network->printer->write("tab position default\n");
$printer_network->printer->tabPositions(30);
$printer_network->printer->tab();
$printer_network->printer->write("tab position 30\n");
$printer_network->printer->tabPositions(8);
$printer_network->printer->tab();
$printer_network->printer->write("tab position 9\n");
$printer_network->printer->write("Two line feeds next . . ");
$printer_network->printer->lf();
$printer_network->printer->lf();

$printer_network->printer->underline(1);
$printer_network->printer->write("underline on\n");
$printer_network->printer->underline(2);
$printer_network->printer->write("underline with double thickness on\n");
$printer_network->printer->underline(0);

$printer_network->printer->invert(1);
$printer_network->printer->write("Inverted Text\n");
$printer_network->printer->invert(0);

$printer_network->printer->write("char height and width\n");
for my $width ( 0 .. 2 ) {
    for my $height ( 0 .. 2 ) {
        $printer_network->printer->width( $width );
        $printer_network->printer->height( $height );
        $printer_network->printer->write("h:$height w:$width\n");
    }
}
$printer_network->printer->width( 0 );
$printer_network->printer->height( 0 );

$printer_network->printer->emphasized(0);
$printer_network->printer->write("default[font(a) de-emphasized] ");

$printer_network->printer->emphasized(1);
$printer_network->printer->write("Emphasized\n ");
$printer_network->printer->emphasized(0);

$printer_network->printer->doubleStrike(1);
$printer_network->printer->write("Double Strike\n ");
$printer_network->printer->doubleStrike(0);

$printer_network->printer->justification('right');
$printer_network->printer->write("Right Justified");
$printer_network->printer->justification('center');
$printer_network->printer->write("Center Justified");
$printer_network->printer->justification('left');

$printer_network->printer->upsideDown(1);
$printer_network->printer->write("Upside Down");
$printer_network->printer->upsideDown(0);

$printer_network->printer->font("b");
$printer_network->printer->write("font b\n");
$printer_network->printer->font("a");

for (0 .. 3){
    $printer_network->printer->charSpacing($_ * 10);
    $printer_network->printer->write("\nchar spacing " . $_ * 10);
}
$printer_network->printer->charSpacing(0);
$printer_network->printer->lineSpacing(0);
$printer_network->printer->write("\n* BEGIN: line spacing 0\n");
$printer_network->printer->write("line spacing 0\n");
$printer_network->printer->lineSpacing(64);
$printer_network->printer->write("* BEGIN: line spacing 64\n");
$printer_network->printer->write("line spacing 64\n");
$printer_network->printer->lineSpacing(128);
$printer_network->printer->write("* BEGIN: line spacing 128\n");
$printer_network->printer->write("line spacing 128\n");

$printer_network->printer->lineSpacing(200);
$printer_network->printer->write("* BEGIN: line spacing 200\n");
$printer_network->printer->write("line spacing 200\n");
$printer_network->printer->lineSpacing(0);

$printer_network->printer->lf();
$printer_network->printer->lf();
$printer_network->printer->lf();

$printer_network->printer->write("Cut paper without feed");
$printer_network->printer->cutPaper( feed => '0');
$printer_network->printer->write("Cut paper with feed");
$printer_network->printer->cutPaper( feed => '1');
$printer_network->printer->print();

