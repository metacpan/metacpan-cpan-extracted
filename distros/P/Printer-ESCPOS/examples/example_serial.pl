use strict;
use warnings;

use 5.010;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Printer::ESCPOS;
use Data::Dumper;

my $printer_serial = Printer::ESCPOS->new(
    driverType     => 'Serial',
    deviceFilePath => '/dev/ttyACM0',
);

say Dumper $printer_serial->printer->printerStatus();
say Dumper $printer_serial->printer->offlineStatus();
say Dumper $printer_serial->printer->errorStatus();
say Dumper $printer_serial->printer->paperSensorStatus();

$printer_serial->printer->barcode(
    barcode     => 'SHANTANU BHADORIA',
);
$printer_serial->printer->usePrintMode(0);

$printer_serial->printer->printNVImage(0);
$printer_serial->printer->drawerKickPulse();

$printer_serial->printer->lf();
$printer_serial->printer->text("print width nH = 1 & nL = 0 for next line");
$printer_serial->printer->printAreaWidth( nL => 0, nH => 1);
$printer_serial->printer->text("blah blah blah blah blah blah blah blah blah blah blah");
$printer_serial->printer->printAreaWidth(); # Reset to default
$printer_serial->printer->text("print are width nL = 200 & nH = 0 for next line");
$printer_serial->printer->printAreaWidth( nL => 200, nH => 0);
$printer_serial->printer->text("blah blah blah blah blah blah blah blah blah blah blah");
$printer_serial->printer->printAreaWidth(); # Reset to default

$printer_serial->printer->tab();
$printer_serial->printer->text("tab position default\n");
$printer_serial->printer->tabPositions(30);
$printer_serial->printer->tab();
$printer_serial->printer->text("tab position 30\n");
$printer_serial->printer->tabPositions(8);
$printer_serial->printer->tab();
$printer_serial->printer->text("tab position 9\n");
$printer_serial->printer->text("Two line feeds next . . ");
$printer_serial->printer->lf();
$printer_serial->printer->lf();

$printer_serial->printer->underline(1);
$printer_serial->printer->text("underline on\n");
$printer_serial->printer->underline(2);
$printer_serial->printer->text("underline with double thickness on\n");
$printer_serial->printer->underline(0);

$printer_serial->printer->invert(1);
$printer_serial->printer->text("Inverted Text\n");
$printer_serial->printer->invert(0);

$printer_serial->printer->text("char height and width\n");
for my $width ( 0 .. 2 ) {
    for my $height ( 0 .. 2 ) {
        $printer_serial->printer->fontWidth( $width );
        $printer_serial->printer->fontHeight( $height );
        $printer_serial->printer->text("h:$height w:$width\n");
    }
}
$printer_serial->printer->fontWidth( 0 );
$printer_serial->printer->fontHeight( 0 );

$printer_serial->printer->bold(0);
$printer_serial->printer->text("default[font(a) de-emphasized] ");

$printer_serial->printer->bold(1);
$printer_serial->printer->text("Emphasized\n ");
$printer_serial->printer->bold(0);

$printer_serial->printer->doubleStrike(1);
$printer_serial->printer->text("Double Strike\n ");
$printer_serial->printer->doubleStrike(0);

$printer_serial->printer->justify('right');
$printer_serial->printer->text("Right Justified");
$printer_serial->printer->justify('center');
$printer_serial->printer->text("Center Justified");
$printer_serial->printer->justify('left');

$printer_serial->printer->upsideDown(1);
$printer_serial->printer->text("Upside Down");
$printer_serial->printer->upsideDown(0);

$printer_serial->printer->font("b");
$printer_serial->printer->text("font b\n");
$printer_serial->printer->font("a");

for (0 .. 3){
    $printer_serial->printer->charSpacing($_ * 10);
    $printer_serial->printer->text("\nchar spacing " . $_ * 10);
}
$printer_serial->printer->charSpacing(0);
$printer_serial->printer->lineSpacing(0);
$printer_serial->printer->text("\n* BEGIN: line spacing 0\n");
$printer_serial->printer->text("line spacing 0\n");
$printer_serial->printer->lineSpacing(64);
$printer_serial->printer->text("* BEGIN: line spacing 64\n");
$printer_serial->printer->text("line spacing 64\n");
$printer_serial->printer->lineSpacing(128);
$printer_serial->printer->text("* BEGIN: line spacing 128\n");
$printer_serial->printer->text("line spacing 128\n");

$printer_serial->printer->lineSpacing(200);
$printer_serial->printer->text("* BEGIN: line spacing 200\n");
$printer_serial->printer->text("line spacing 200\n");
$printer_serial->printer->lineSpacing(0);

$printer_serial->printer->lf();
$printer_serial->printer->lf();
$printer_serial->printer->lf();

$printer_serial->printer->text("Cut paper without feed");
$printer_serial->printer->cutPaper( feed => '0');
$printer_serial->printer->text("Cut paper with feed");
$printer_serial->printer->cutPaper( feed => '1');
$printer_serial->printer->print();


