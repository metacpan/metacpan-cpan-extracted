use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::GetImages;


opendir(DIR,'./t/testdocs') or die;
my @f = grep { /\.pdf/i } readdir DIR;
closedir DIR;
scalar @f or die;


for (@f){
   my $abs = "./t/testdocs/$_";
   ok( 1, $abs );

   my $imgs = PDF::GetImages::pdfimages($abs);

   ok ( scalar @$imgs );

   print STDERR " image $_\n" for @$imgs;
   print STDERR "\n\n\n";

}







