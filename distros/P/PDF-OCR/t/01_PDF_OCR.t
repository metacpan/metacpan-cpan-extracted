use Test::Simple 'no_plan';
use File::Which 'which';
use lib './lib';
use PDF::OCR;
use Cwd;

ok(1,'loaded PDF::OCR');


### Testing Image OCR Tesseract and PDF GetImages

# use Smart::Comments '###';
	



my $pdf = './t/scan1.pdf';


my $p;
ok( $p = PDF::OCR->new($pdf),"instanced for $pdf");

my $images;
ok( $images = $p->abs_images,'abs_images()');
### $images



map { ok(1," image $_") } @$images;

ok( scalar @$images,'abs_images has count') or die;



ok( $p->abs_images_count, 'abs_imges_count()');

ok( scalar @$images,'pdfimages');


for (@$images){
   
	my $ocr = $p->get_ocr($_);
	ok($ocr,'get_ocr');

   ### ---
   ### $ocr
   ### ---
	
}


my $ocrall = $p->get_ocr;
ok($ocrall,"ocr all [[[ $ocrall ]]]\n\n");

