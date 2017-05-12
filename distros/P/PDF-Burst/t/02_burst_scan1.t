use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::Burst 'pdf_burst';

$PDF::Burst::DEBUG = 1;


my $abs = './t/scan1.pdf';

ok -f $abs;

my @files = pdf_burst($abs);

my $count = scalar @files;

ok $count, "count is $count";

( ok -f $_ ) for @files;





