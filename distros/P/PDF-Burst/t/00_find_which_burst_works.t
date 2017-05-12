#!/usr/bin/perl -w
use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::Burst ':all';
use warnings;

$PDF::Burst::DEBUG = 1;
sub spacer { printf STDERR "\n%s\n\n", '-'x60 }



my $works =0;

spacer();

if ( eval { ok_CAM_PDF() } ){

   ok( 1, "CAM::PDF burst works" );   
   $works++;
}
else {
   print STDERR "CAM::PDF burst does not work\n";
}

spacer();
if ( eval { ok_PDF_API2() } ){
   
   ok( 1, "PDF::API2 burst works" );
   $works++;
}
else {
   print STDERR "PDF::API2 burst does not work\n";
}

spacer();
if ( eval { ok_pdftk() } ){

   ok( 1, "pdftk burst works" );   
   $works++;
}
else {
   print STDERR "pdftk burst does not work\n";
}


spacer();
ok( $works, "found $works working method(s) to pdf burst");




sub ok_CAM_PDF {
   
   my $abs = './t/scan1.pdf';
   -f $abs or die("missing $abs");

   my @files = pdf_burst_CAM_PDF($abs);
   print STDERR "count files: ".scalar @files."\n";
   @files or return 0;

   for (@files) { -f $_ or return 0; }
   unlink $_ for @files;
   return 1;
}

sub ok_PDF_API2 {
   
   my $abs = './t/scan1.pdf';
   -f $abs or die("missing $abs");

   my @files = pdf_burst_PDF_API2($abs);
   print STDERR "count files: ".scalar @files."\n";
   @files or return 0;

   for (@files) { -f $_ or return 0; }
   unlink $_ for @files;
   return 1;
}



sub ok_pdftk {
   
   my $abs = './t/scan1.pdf';
   -f $abs or die("missing $abs");

   my @files = pdf_burst_pdftk($abs);
   print STDERR "count files: ".scalar @files."\n";
   @files or return 0;

   for (@files) { -f $_ or return 0; }
   unlink $_ for @files;
   return 1;
}



