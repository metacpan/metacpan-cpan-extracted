use Test::Simple 'no_plan';
use lib './lib';
use strict;

use PDF::GetImages 'pdfimages';

$PDF::GetImages::DEBUG=1;

ok(1,'PDF::GetImages module loaded');


my $abs_pdf = './t/scan1.pdf';

my $images;


ok( $images = pdfimages($abs_pdf), 'pdfimages() returns');
ok( ref $images eq 'ARRAY','pdfimages returns array ref');

my $count = scalar @$images;

ok( $count ,"pdfimages() array ref has scalar value ($count)");

for my $abs_img (@$images){
   ok(1," img: $abs_img");
   unlink $abs_img;
}



# TEST 2.. ANOTHER DIR



require File::Path;

my $abs_dir = './t/altdir';
File::Path::rmtree($abs_dir);
mkdir $abs_dir;

my $_images;
ok( $_images = pdfimages($abs_pdf,$abs_dir),"pdfimages() using alternate dir");

for(@$_images){
   ok($_=~/$abs_dir/,"images saved in $abs_dir");
   last;

}








# TEST 3 FORCE  JPG
require File::Which;
if ( File::Which::which('convert')){
   
   ok(1,'testing FORCE_JPG');
   $PDF::GetImages::FORCE_JPG=1;

   my $abs_d = './t/jpgdir';
   File::Path::rmtree($abs_d);
   mkdir $abs_d;


   my $images;
   ok( $images = pdfimages($abs_pdf,$abs_d),"pdfimages(0 returns with FORCE_JPG on");

   for my $img (@$images){
      ok($img=~/\.jpg$/," $img is a jpg");   
   }

}
