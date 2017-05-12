use lib qw(../lib);
use PDF::Report;

my $file = $ARGV[0];
print "Pass me a PDF file." if ! -e $file;

my $pdf = new PDF::Report(
                          File => $file,
                          undef => undef
                         );

$pdf->openpage(1);

$pdf->setFont('Helvetica');
$pdf->setSize(12);

my ($pageW, $pageH) = $pdf->getPageDimensions();
$pdf->shadeRect(30, $pageH-5, 200, $pageH-30, 'grey');
$pdf->addRawText("Document opened successfully", 32, $pageH-22, 'red');

my $outpdf = $0;
$outpdf =~ s/pl$/pdf/;
open(PDF, "> $outpdf") or die "Error opening $outpdf: $!\n";
print PDF $pdf->Finish();
close(PDF);
 
exit;
