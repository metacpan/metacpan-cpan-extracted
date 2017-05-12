use Test::Simple 'no_plan';
use strict;
use lib './lib';
use PDF::Burst 'pdf_burst';

$PDF::Burst::DEBUG = 1;



# one we know fails 
ok( ! pdf_burst('./t/bogus.pdf'),'pdf_burst() on bogus fails' );
ok($PDF::Burst::errstr, "and the error: $PDF::Burst::errstr");


ok( ! pdf_burst('./t/bowswww../../gus.pdf'),'pdf_burst() on bogus fails' );
ok($PDF::Burst::errstr, "and the error: $PDF::Burst::errstr");



