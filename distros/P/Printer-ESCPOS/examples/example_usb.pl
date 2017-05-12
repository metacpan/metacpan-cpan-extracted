use strict;
use warnings;

use 5.010;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Printer::ESCPOS;
use Data::Dumper;

my $printer_usb = Printer::ESCPOS->new(
    driverType     => 'USB',
    vendorId       => 0x1504,
    productId      => 0x0006,
);

$printer_usb->printer->init();


$printer_usb->printer->barcode(
    barcode     => 'SHANTANU BHADORIA',
);
$printer_usb->printer->usePrintMode(0);

$printer_usb->printer->printNVImage(0);
$printer_usb->printer->drawerKickPulse();

$printer_usb->printer->lf();
$printer_usb->printer->text("print width nH = 1 & nL = 0 for next line");
$printer_usb->printer->printAreaWidth( nL => 0, nH => 1);
$printer_usb->printer->text("blah blah blah blah blah blah blah blah blah blah blah");
$printer_usb->printer->printAreaWidth(); # Reset to default
$printer_usb->printer->text("print are width nL = 200 & nH = 0 for next line");
$printer_usb->printer->printAreaWidth( nL => 200, nH => 0);
$printer_usb->printer->text("blah blah blah blah blah blah blah blah blah blah blah");
$printer_usb->printer->printAreaWidth(); # Reset to default

$printer_usb->printer->tab();
$printer_usb->printer->text("tab position default\n");
$printer_usb->printer->tabPositions(30);
$printer_usb->printer->tab();
$printer_usb->printer->text("tab position 30\n");
$printer_usb->printer->tabPositions(8);
$printer_usb->printer->tab();
$printer_usb->printer->text("tab position 9\n");
$printer_usb->printer->text("Two line feeds next . . ");
$printer_usb->printer->lf();
$printer_usb->printer->lf();

$printer_usb->printer->underline(1);
$printer_usb->printer->text("underline on\n");
$printer_usb->printer->underline(2);
$printer_usb->printer->text("underline with double thickness on\n");
$printer_usb->printer->underline(0);

$printer_usb->printer->invert(1);
$printer_usb->printer->text("Inverted Text\n");
$printer_usb->printer->invert(0);

$printer_usb->printer->text("char height and width\n");
for my $width ( 0 .. 2 ) {
    for my $height ( 0 .. 2 ) {
        $printer_usb->printer->fontWidth( $width );
        $printer_usb->printer->fontHeight( $height );
        $printer_usb->printer->text("h:$height w:$width\n");
    }
}
$printer_usb->printer->fontWidth( 0 );
$printer_usb->printer->fontHeight( 0 );

$printer_usb->printer->bold(0);
$printer_usb->printer->text("default[font(a) de-emphasized] ");

$printer_usb->printer->bold(1);
$printer_usb->printer->text("Emphasized\n ");
$printer_usb->printer->bold(0);

$printer_usb->printer->doubleStrike(1);
$printer_usb->printer->text("Double Strike\n ");
$printer_usb->printer->doubleStrike(0);

$printer_usb->printer->justify('right');
$printer_usb->printer->text("Right Justified");
$printer_usb->printer->justify('center');
$printer_usb->printer->text("Center Justified");
$printer_usb->printer->justify('left');

$printer_usb->printer->upsideDown(1);
$printer_usb->printer->text("Upside Down");
$printer_usb->printer->upsideDown(0);

$printer_usb->printer->font("b");
$printer_usb->printer->text("font b\n");
$printer_usb->printer->font("a");

for (0 .. 3){
    $printer_usb->printer->charSpacing($_ * 10);
    $printer_usb->printer->text("\nchar spacing " . $_ * 10);
}
$printer_usb->printer->charSpacing(0);
$printer_usb->printer->lineSpacing(0);
$printer_usb->printer->text("\n* BEGIN: line spacing 0\n");
$printer_usb->printer->text("line spacing 0\n");
$printer_usb->printer->lineSpacing(64);
$printer_usb->printer->text("* BEGIN: line spacing 64\n");
$printer_usb->printer->text("line spacing 64\n");
$printer_usb->printer->lineSpacing(128);
$printer_usb->printer->text("* BEGIN: line spacing 128\n");
$printer_usb->printer->text("line spacing 128\n");

$printer_usb->printer->lineSpacing(200);
$printer_usb->printer->text("* BEGIN: line spacing 200\n");
$printer_usb->printer->text("line spacing 200\n");
$printer_usb->printer->lineSpacing(0);

$printer_usb->printer->lf();
$printer_usb->printer->lf();
$printer_usb->printer->lf();

$printer_usb->printer->text("Cut paper without feed");
$printer_usb->printer->cutPaper( feed => '0');
$printer_usb->printer->text("Cut paper with feed");
$printer_usb->printer->cutPaper( feed => '1');
$printer_usb->printer->print();

