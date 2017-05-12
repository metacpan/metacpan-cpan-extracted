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

$y1-=70;

foreach my $ext (qw(jpg gif tif png pnm)) {
  $pdf->addImgScaled("image.$ext", 250, $y1, 1);
  $y1-=70;
}
$y1-=70;
$pdf->addImgScaled("image.jpg", 250, $y1, 2);

my $outpdf = $0;
$outpdf =~ s/pl$/pdf/;
open(PDF, "> $outpdf") or die "Error opening $outpdf: $!\n";
print PDF $pdf->Finish;
close(PDF);

exit;
