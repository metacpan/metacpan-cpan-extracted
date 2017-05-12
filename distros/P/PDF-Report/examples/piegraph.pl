use lib qw(../lib);
use PDF::Report;

my $pdf = new PDF::Report(
                          PageSize => "letter",
                          PageOrientation => "portrait",
                          undef => undef
                         );

$pdf->newpage(1);
$pdf->setFont('Helvetica-bold');
$pdf->setSize(16);
my ($width, $height) = $pdf->getPageDimensions();

$pdf->centerString(0, $width, $height-40, "Big Pie Graph");

my @data = qw(2 4 3 2 3 5 2 4 2 3 4 5 3 4 3 5 4 2 4 3 4);
my @labels;
for (0 .. $#data) {
  push(@labels, "label" . $_);  
} 
$pdf->drawPieGraph($width/2, $height-200, 100, \@data, \@labels);

my $outpdf = $0;
$outpdf =~ s/pl$/pdf/;
open(PDF, "> $outpdf") or die "Error opening $outpdf: $!\n";
print PDF $pdf->Finish();
close(PDF);
 
exit;
