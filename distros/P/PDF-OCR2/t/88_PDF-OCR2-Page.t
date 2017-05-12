use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::OCR2::Page;
use Cwd;
my $cwd = cwd();
$PDF::OCR2::Page::DEBUG = 1;

$PDF::OCR2::CHECK_PDF = 1;

# -----------------------------------------------------------------------
ok_part('ONE THAT DOESNT WORK');
my $bogus = PDF::OCR2::Page->new({ abs_pdf => './blabla' }); # not there
### $bogus
ok ! $bogus,'bogus returns none' ;




# -----------------------------------------------------------------------
ok_part('empty one');
$PDF::OCR2::CHECK_PDF = 0;
$bogus = PDF::OCR2::Page->new({ abs_pdf => './t/empty_example.pdf' });
ok $bogus,'can instance empty pdf if CHECK_PDF is off';

$PDF::OCR2::CHECK_PDF = 1;
$bogus = PDF::OCR2::Page->new({ abs_pdf => './t/empty_example.pdf' });
ok ! $bogus,'canot instance empty pdf if CHECK_PDF is on';



ok( ! eval { $bogus->abs_images } , 'but calling a method bonks out');


# -----------------------------------------------------------------------
ok_part('diff instance, via arg not anon hash');

ok( PDF::OCR2::Page->new("$cwd/t/leodocs/hdreceipt.pdf"),
   'can instance via abs path');

ok( PDF::OCR2::Page->new("./t/leodocs/hdreceipt.pdf"),
   'can instance via rel path ./t/');

ok( PDF::OCR2::Page->new("t/leodocs/hdreceipt.pdf"),
   'can instance via rel path t/');

# ---------------------------------------------------------------------
ok_part("THIS ONE IS THERE");

my $abs_pdf = "$cwd/t/leodocs/hdreceipt.pdf";

-f $abs_pdf or die("not on disk $abs_pdf");

my $i;
ok( $i = PDF::OCR2::Page->new( { abs_pdf => $abs_pdf }),"instanced $abs_pdf") or die;
$i->errstr;
ok 1, 'errstr()';


ok $i, 'instanced' or die;

#ok $i->abs_pdf('./t/leodocs/hdreceipt.pdf'),'abs_pdf';

ok $i->abs_pdf,'abs_pdf()';

ok_part('IMAGES');

ok $i->abs_images, 'abs_images()';

my @imgs = $i->abs_images;

ok( scalar @imgs);

ok $i->abs_images_count == 1;

ok $_,$_ for @imgs;





# ---------------------------------------------------------------------
ok_part('EXTRACTING');
my $firstimg;

ok( $firstimg = $i->_text_from_image($imgs[0]), "_text_from_image() got text out");

#### $firstimg

my $allimgs;
ok $allimgs = $i->_text_from_images, "_text_from_images()";

#### $allimgs

if( my $pdftext = $i->_text_from_pdf ){
   print STDERR "_text_from_pdf yes\n";

   #### $pdftext
}
else {
   print STDERR "_text_from_pdf no\n";
}

my $alltext;
ok $alltext = $i->text, 'text()';


#### $alltext

### @PDF::OCR2::Page::TRASH



# ---------------------------------------------------------------------
#ok_part('tuition');
#$PDF::OCR2::Page::DEBUG = 1;

#my $b = PDF::OCR2::Page->new( { abs_pdf => "$cwd/t/leodocs/tuition.pdf" });
#my $textt= $b->text;

#print STDERR "TEXT:\n\n$textt\n";


#ok( $textt=~/Heights/, "text out has 'Heights'") or die('cant get normal text out?!');











sub ok_part {
   printf STDERR "\n\n===========================\n%s\n===========================\n\n",uc("@_");
}




