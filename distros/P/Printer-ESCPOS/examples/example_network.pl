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


$printer_network->printer->barcode(
    barcode     => 'SHANTANU BHADORIA',
);
$printer_network->printer->usePrintMode(0);

$printer_network->printer->printNVImage(0);
$printer_network->printer->drawerKickPulse();

$printer_network->printer->utf8ImagedText("Asfadaf");
$printer_network->printer->lf();
$printer_network->printer->text("print width nH = 1 & nL = 0 for next line");

$printer_network->printer->tab();
$printer_network->printer->text("tab position default\n");
$printer_network->printer->tabPositions(30);
$printer_network->printer->tab();
$printer_network->printer->text("tab position 30\n");
$printer_network->printer->tabPositions(8);
$printer_network->printer->tab();
$printer_network->printer->text("tab position 9\n");
$printer_network->printer->text("Two line feeds next . . ");
$printer_network->printer->lf();
$printer_network->printer->lf();

$printer_network->printer->underline(1);
$printer_network->printer->text("underline on\n");
$printer_network->printer->underline(2);
$printer_network->printer->text("underline with double thickness on\n");
$printer_network->printer->underline(0);

$printer_network->printer->invert(1);
$printer_network->printer->text("Inverted Text\n");
$printer_network->printer->invert(0);

$printer_network->printer->text("char height and width\n");
for my $width ( 0 .. 2 ) {
    for my $height ( 0 .. 2 ) {
        $printer_network->printer->fontWidth( $width );
        $printer_network->printer->fontHeight( $height );
        $printer_network->printer->text("h:$height w:$width\n");
    }
}
$printer_network->printer->fontWidth( 0 );
$printer_network->printer->fontHeight( 0 );

$printer_network->printer->bold(0);
$printer_network->printer->text("default[font(a) de-emphasized] ");

$printer_network->printer->bold(1);
$printer_network->printer->text("Emphasized\n ");
$printer_network->printer->bold(0);

$printer_network->printer->doubleStrike(1);
$printer_network->printer->text("Double Strike\n ");
$printer_network->printer->doubleStrike(0);

$printer_network->printer->justify('right');
$printer_network->printer->text("Right Justified");
$printer_network->printer->justify('center');
$printer_network->printer->text("Center Justified");
$printer_network->printer->justify('left');

$printer_network->printer->upsideDown(1);
$printer_network->printer->text("Upside Down");
$printer_network->printer->upsideDown(0);

$printer_network->printer->font("b");
$printer_network->printer->text("font b\n");
$printer_network->printer->font("a");

for (0 .. 3){
    $printer_network->printer->charSpacing($_ * 10);
    $printer_network->printer->text("\nchar spacing " . $_ * 10);
}
$printer_network->printer->charSpacing(0);
$printer_network->printer->lineSpacing(0);
$printer_network->printer->text("\n* BEGIN: line spacing 0\n");
$printer_network->printer->text("line spacing 0\n");
$printer_network->printer->lineSpacing(64);
$printer_network->printer->text("* BEGIN: line spacing 64\n");
$printer_network->printer->text("line spacing 64\n");
$printer_network->printer->lineSpacing(128);
$printer_network->printer->text("* BEGIN: line spacing 128\n");
$printer_network->printer->text("line spacing 128\n");

$printer_network->printer->lineSpacing(200);
$printer_network->printer->text("* BEGIN: line spacing 200\n");
$printer_network->printer->text("line spacing 200\n");
$printer_network->printer->lineSpacing(0);

$printer_network->printer->lf();
$printer_network->printer->lf();
$printer_network->printer->lf();

$printer_network->printer->text("Cut paper without feed");
$printer_network->printer->cutPaper( feed => '0');
$printer_network->printer->text("Cut paper with feed");
$printer_network->printer->cutPaper( feed => '1');
$printer_network->printer->print();
