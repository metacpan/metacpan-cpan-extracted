use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::OCR2;
use LEOCHARRE::Dir 'lsfa';

my $short = $ARGV[0] eq '-d' ? 1 : 0;

$PDF::OCR2::DEBUG = 1;
$PDF::OCR2::Page::DEBUG = 1;

my @pdfs = sort { (stat $a)[7] <=> (stat $b)[7] } grep { /\.pdf/i } lsfa('./t/leodocs');

warn("pdfs are: @pdfs\n");



for my $abs (@pdfs){
   my ($txt,$pages_count,$pdf,$txt_length);

   printf STDERR "\n%s\n",'-'x60;
   ok( $abs , "abs: $abs");
   

   ok( $pdf = PDF::OCR2->new($abs), "instanced new()") or die;
  
   ok( $pages_count = $pdf->pages_count,"pages_count() $pages_count");

   ok( $txt = $pdf->text, "text()");   
   warn("$txt\n");

   ok($txt_length = $pdf->text_length, "text_length() $txt_length");
   
   $short and exit;

}





