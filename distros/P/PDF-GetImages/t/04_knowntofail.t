use Test::Simple 'no_plan';
use lib './lib';
use strict;
use PDF::GetImages 'pdfimages';

$PDF::GetImages::DEBUG=1;

ok(1,'PDF::GetImages module loaded');


my $abs_pdf = './t/scan1BOGUS.pdf';

my $images;

ok( (!pdfimages($abs_pdf)), "pdfimages() does not return for $abs_pdf");

my $err = $PDF::GetImages::errstr;
ok( $err, "have errstr: $err");

print STDERR "\n   ---   part ii   ---\n";
print STDERR "known not to have images..\n\n\n";
my $abs_pdf1 = './t/noimages.pdf';

my $images1;

ok( ($images1 = pdfimages($abs_pdf1)), "pdfimages() returns for $abs_pdf1");

print STDERR "errstr? $PDF::GetImages::errstr\n";


ok( ref $images1 eq 'ARRAY', "pdfimages returned array ref");

my $count = scalar @$images1;
ok( $count ==0 , "the array ref had 0 items");




