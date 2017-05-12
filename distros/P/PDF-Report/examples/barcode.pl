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

$pdf->centerString(0, $width, $height-40, "Barcodes");

my $x = $width/3;
my $y = $height-150; 
my @types = qw(3of9 code128 ean13 codabar 2of5int);

my @codes = qw(010203045678909 ABCDEFabcdef012345 010203045678909 
               384318530034967067 384318530034967067);

my @scale = qw(.9 .5 .75 1 .8);

$pdf->setFont('Helvetica');
$pdf->setSize(10);

my $next_line = 120;

foreach my $nbr (0 .. $#types) {
  if ($y < 50) {
   $pdf->newpage(1);
   $y = $height - 80;
  }
  if (($types[$nbr] eq '3of9ext') or ($types[$nbr] eq '3of9extchk')) {
    $ext = 90506;
  } 
  $pdf->centerString(0, $width, $y+85, $types[$nbr]);
  $pdf->drawBarcode($x, $y, $scale[$nbr], 1,
                   $types[$nbr], $codes[$nbr], $ext, 
                   10, 10, 50, 10, ' ', undef, 8, undef);
  $y-=$next_line;
  $ext = "";
}

my $outpdf = $0;
$outpdf =~ s/pl$/pdf/;
open(PDF, "> $outpdf") or die "Error opening $outpdf: $!\n";
print PDF $pdf->Finish();
close(PDF);

exit;
