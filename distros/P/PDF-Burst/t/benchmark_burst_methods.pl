use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::Burst ':all';

#$PDF::Burst::DEBUG = 1;

my $iterations = 50;
my $abs_pdf = './t/trees14pgs.pdf';
my $works =0;

if ( eval { ok_CAM_PDF() } ){

   ok( 1, "CAM::PDF burst works" );
   
   for ( 1 .. $iterations ){
      ok_CAM_PDF();
   }

   $works++;
}
else {
   print STDERR "CAM::PDF burst does not work\n";
}



if ( eval { ok_PDF_API2() } ){
   
   ok( 1, "PDF::API2 burst works" );

   for ( 1 .. $iterations ){
      ok_PDF_API2();
   }
   $works++;
}
else {
   print STDERR "PDF::API2 burst does not work\n";
}



if ( ok_pdftk() ){
   
   ok( 1, "pdftk works" );

   for ( 1 .. $iterations ){
      ok_pdftk();
   }
   $works++;
}
else {
   print STDERR "pdftk burst does not work\n";
}


$works or die("no methods work");








sub ok_pdftk {
   
   my $which = `which pdftk`;
   chomp $which;
   $which=~/\/pdftk$/ or return 0;

   system('pdftk', 'burst', 'output', '_page_') == 0 
      or return 0;

}


sub ok_CAM_PDF {
   
   my $abs = $abs_pdf;
   -f $abs or die("missing $abs");

   my @files = pdf_burst_CAM_PDF($abs);
   @files or return 0;

   for (@files) { -f $_ or return 0; }
   return 1;
}

sub ok_PDF_API2 {
   
   my $abs = $abs_pdf;
   -f $abs or die("missing $abs");

   my @files = pdf_burst_PDF_API2($abs);
   @files or return 0;

   for (@files) { -f $_ or return 0; }
   return 1;
}





