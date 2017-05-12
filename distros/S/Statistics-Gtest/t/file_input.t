# Before `make install' is performed this script should be runnable with 
# `make test'. After `make install' it should work as `perl file_input.t'

#########################
use Test::More; 
use Statistics::Gtest;
#########################

my $twothreefile = "t/2x3int.txt";
my $onefourfile = "t/1x4int.txt";

my @file_objects = (
	{ 'obj' => $twothreefile,
	  'ex' => [2, 2, 3, 90, 60, 50, 40, 150, 1, 0, 
	  qr/\A1\.01451388/,
	  qr/\A13\.0444952/, 
	  qr/\A13\.233821/, 
	  qr/\A6\.6169108/,
	  [[30, 24, 36],[20,16,24]] ] },
	{ 'obj' => $onefourfile,
	  'ex' => [3, 1, 4, 177, undef, 34, 45, 177, 1, 2,
	  qr/\A1\.0047080/,
	  qr/\A(?:-4|0)/, 
	  qr/\A(?:-4|0)/, 
	  qr/\A(?:-2|0)/,
	  [34, 45, 32, 66] ] },
	);

plan tests => scalar (@file_objects) * 17; 
foreach my $t (@file_objects) {
	my $g = new Statistics::Gtest($t->{'obj'}); 
	ok(defined $g, 'Constructor'); 
	ok($g->isa('Statistics::Gtest'), 'Object is correct class'); 
	is($g->getDF(), $t->{'ex'}->[0], 'getDF()'); 
	is($g->getRowNum(), $t->{'ex'}->[1], 'getRowNum()'); 
	is($g->getColNum(), $t->{'ex'}->[2], 'getColNum()'); 
	is($g->rowSum(0), $t->{'ex'}->[3], 'RowSum(0)'); 
	is($g->rowSum(1), $t->{'ex'}->[4], 'RowSum(1)'); 
	is($g->colSum(0), $t->{'ex'}->[5], 'ColSum(0)'); 
	is($g->colSum(1), $t->{'ex'}->[6], 'ColSum(1)'); 
	is($g->getSumTotal(), $t->{'ex'}->[7], 'SumTotal()'); 
	is($g->{'intrinsic'}, $t->{'ex'}->[8], "hypothesis type = 1"); 
	is($g->{'tabletype'}, $t->{'ex'}->[9], "tabletype"); 
	like($g->getQ(), $t->{'ex'}->[10], "Williams Q re"); 
	like($g->getRawG(), $t->{'ex'}->[12], "Raw G"); 
	like($g->getG(), $t->{'ex'}->[11], "Corrected G"); 
	like($g->{'logsum'}, $t->{'ex'}->[13], "logsum");
	is_deeply($g->getExpected(),$t->{'ex'}->[14], "getExpected");
}

