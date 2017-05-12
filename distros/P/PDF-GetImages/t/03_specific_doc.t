use Test::Simple 'no_plan';
use lib './lib';
use strict;

use PDF::GetImages 'pdfimages';

$PDF::GetImages::DEBUG=1;



my $abs_pdf = './t/testdocs/hdreceipt_page_0001.pdf';
-f $abs_pdf or die;

my $images;



ok( $images = pdfimages($abs_pdf), 'pdfimages() returns');
ok( ref $images eq 'ARRAY','pdfimages returns array ref');

my $count = scalar @$images;

ok( $count ,"pdfimages() array ref has scalar value ($count)");

for my $abs_img (@$images){
   ok(1," img: $abs_img.. removing..");
   unlink $abs_img;
}

