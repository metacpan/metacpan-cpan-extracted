use lib qw(../lib);
use PDF::Report;

my $pdf = new PDF::Report(
                          PageSize => [5.5*72, 8.5*72], # Custom page size 
                          PageOrientation => "portrait"
                         );

$pdf->setFont('Helvetica');
$pdf->setSize(12);
my ($width, $height) = $pdf->getPageDimensions();
my $y1 = $height - 30;
my $x1 = 30;

for (1 .. 4) {
  $pdf->newpage();
}

my $outpdf = $0;
$outpdf =~ s/pl$/pdf/;
open(PDF, "> $outpdf") or die "Error opening $outpdf: $!\n";
print PDF $pdf->Finish(\&footer);
close(PDF);

exit;

sub footer {
  my $pages = $pdf->pages;

  $pdf->setFont("Times-roman");
  $pdf->setSize(8);
  for (1 .. $pages) {
    $pdf->openpage($_);
    $pdf->centerString($x1, $width-30, 10, "$_ out of $pages pages");
  }
}
