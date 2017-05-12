#/bin/perl -w
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;

use Set::Infinite qw($inf);

my $test = 0;
my ($result, $errors);
my @a;
my $c;

sub test {
	my ($header, $sub, $expected) = @_;
	$test++;
	#print "\t# $header \n";
	$result = eval $sub;
    $result = '' unless defined $result;
	if ("$expected" eq "$result") {
		print "ok $test";
	}
	else {
		print "not ok $test"; # \n\t# expected \"$expected\" got \"$result\"";
		print "\n\t# $sub expected \"$expected\" got \"$result\"  $@";
		$errors++;
	}
	print " \n";
}

print "1..12\n";
$| = 1;

$a = Set::Infinite->new([1,25]);
test ( '', 
  ' $a->quantize(quant=>1)->select( by => [0,2,-2,-1] ) ', 
  '[1..2),[3..4),[24..25),[25..26)');
test ( '',
  ' $a->quantize(quant=>1)->select( count => 3 ) ',
  '[1..2),[2..3),[3..4)');
test ( '',
  ' $a->quantize(quant=>1)->select( by => [0,2,-2,-1], count => 3 ) ',
  '[1..2),[3..4),[24..25)');
test ( '',
  ' $a->quantize(quant=>1)->select( by => [0,20,-20,-1], count => 3 ) ',
  '[1..2),[6..7),[21..22)');


$a = Set::Infinite->new(-$inf,25);
test ( '',
  ' $a->quantize(quant=>1)->select( by => [0,2,-2,-1] ) ',
  -$inf . ",[24..25),[25..26)");
test ( '',
  ' $a->quantize(quant=>1)->select( count => 3 ) ',
  -$inf . "" );
test ( '',
  ' $a->quantize(quant=>1)->select( by => [0,2,-2,-1], count => 3 ) ',
  -$inf . ",[24..25),[25..26)");
test ( '',
  ' $a->quantize(quant=>1)->select( by => [0,20,-20,-1], count => 3 ) ',
  -$inf . ",[6..7),[25..26)");


$a = Set::Infinite->new(25,$inf);
test ( '',
  ' $a->quantize(quant=>1)->select( by => [0,2,-2,-1] ) ',
  "[25..26),[27..28),$inf");
test ( '',
  ' $a->quantize(quant=>1)->select( count => 3 ) ',
  "[25..26),[26..27),[27..28)");
test ( '',
  ' $a->quantize(quant=>1)->select( by => [0,2,-2,-1], count => 3 ) ',
  "[25..26),[27..28),$inf");
test ( '',
  ' $a->quantize(quant=>1)->select( by => [0,20,-20,-1], count => 3 ) ',
  "[25..26),[45..46),$inf");

$a = $a;  # clear warnings

1;
