use lib qw(../lib);
use PDF::Report;

my $pdf = new PDF::Report(
                          PageSize => "LETTER", 
                          PageOrientation => "portrait",
                          undef => undef
                         );

$pdf->setFont('Helvetica');
$pdf->setSize(12);
my ($width, $height) = $pdf->getPageDimensions();
my $y1 = $height - 30;
my $x1 = 30;

$pdf->newpage();

# Add some text with rotate, and let's throw in some color for the fun of it
$pdf->addRawText("This is some text of a different color, rotated.", 
                 $x1+200, $y1-300, 'green', '', '', 315);

my $outpdf = $0;
$outpdf =~ s/pl$/pdf/;
open(PDF, "> $outpdf") or die "Error opening $outpdf: $!\n";
print PDF $pdf->Finish;
close(PDF);

exit;
