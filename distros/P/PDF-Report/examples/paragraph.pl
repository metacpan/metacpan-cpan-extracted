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

$pdf->centerString(0, $width, $height-40, "Paragraph");

$pdf->setFont('Helvetica');
$pdf->setSize(10);

my $text1= 
"A doctor, an architect, and a computer scientist were arguing about whose profession was the oldest.  In the course of their arguments, they got all the way back to the Garden of Eden, whereupon the doctor said, \"The medical profession is clearly the oldest, because Eve was made from Adam's rib, as the story goes, and that was a simply incredible surgical feat.\"";

my $text2=
        "The architect did not agree.  He said, \"But if you look at the Garden 
itself, in the beginning there was chaos and void, and out of that the Garden 
and the world were created.  So God must have been an architect.\"";

my $text3=
        "The computer scientist, who'd listened carefully to all of this, then 
commented, \"Yes, but where do you think the chaos came from?\"";

$pdf->addParagraph($text1, 30, $height-70, $width-60, 30, 25, 10);
$pdf->addParagraph($text2, 30, $height-100, $width-60, 20, 25, 10);
$pdf->addParagraph($text3, 30, $height-120, $width-60, 20, 25, 10);

my $outpdf = $0;
$outpdf =~ s/pl$/pdf/;
open(PDF, "> $outpdf") or die "Error opening $outpdf: $!\n";
print PDF $pdf->Finish();
close(PDF);
 
exit;
