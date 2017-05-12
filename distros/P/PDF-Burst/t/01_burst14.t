use Test::Simple 'no_plan';
use strict;
use lib './lib';
use warnings;
use PDF::Burst 'pdf_burst';

$PDF::Burst::DEBUG = 1;

ok( $PDF::Burst::BURST_METHOD, "burst method is '$PDF::Burst::BURST_METHOD'");
ok( @PDF::Burst::BURST_METHODS, "Burst methods are: @PDF::Burst::BURST_METHODS");




my @outfiles;
ok( @outfiles = pdf_burst('./t/trees14pgs.pdf'),"pdf_burst() returns")
   or warn(" # # # $0,  pdf_burst() fails.. error: $PDF::Burst::errstr");



my $outfiles_count = 0;
@outfiles and ( $outfiles_count = scalar @outfiles );



ok($outfiles_count, "got outfiles count: $outfiles_count");
ok($outfiles_count == 14, "got outfiles count: $outfiles_count, should be 14");




