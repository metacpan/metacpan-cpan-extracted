#!/usr/bin/perl
#
use strict;
use PDF::API2;

my $file_in = $ARGV[0];

my $prepend = $ARGV[1];
$prepend ||= 'out';

my $pdf_in = PDF::API2->open($file_in) or die;

my $count = $pdf_in->pages;

for my $i ( 0 .. ( $count - 1 )){
   my $_i = ($i+1);

   my $file_out = "$file_in.$_i.pdf";

   my $pdf_out = PDF::API2->new or die;

   $pdf_out->importpage( $pdf_in, $_i ) or die;

   $pdf_out->saveas($file_out) or die;
   
   print STDERR "saved $file_out\n";


}


exit;
