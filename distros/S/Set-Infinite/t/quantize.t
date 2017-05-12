#/bin/perl -w
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Tests for Set::Infinite::Quantize
#


use strict;
# use warnings;

use Set::Infinite; 

# $Set::Infinite::TRACE = 1;

my $test = 0;
my ($result, $errors);

sub test {
	my ($header, $sub, $expected) = @_;
	$test++;
	#print "\t# $header \n";
	$result = eval $sub;
	if ("$expected" eq "$result") {
		print "ok $test";
	}
	else {
		print "not ok $test"; # \n\t# expected \"$expected\" got \"$result\"";
		print "\n\t# $sub expected \"$expected\" got \"$result\" $@";
		$errors++;
	}
	print " \n";
}


print "1..17\n";

#print "1: \n";
$a = Set::Infinite->new([1,3]);
#print join (" ",@{$a->quantize(quant => 1)}),"\n";

# $a = $a->quantize(quant => 1);
# @a = $a->list;
# exit;

test ( '', ' join (" ", $a->quantize(quant => 1)->list ) ',
	"[1..2) [2..3) [3..4)");

#print "25: \n";
$a = Set::Infinite->new([315,434], [530,600]);
#print join (" ",@{$a->quantize(quant => 25)}),"\n";
test ( '', ' join (" ", $a->quantize(quant => 25)->list ) ',
	"[300..325) [325..350) [350..375) [375..400) [400..425) [425..450) [525..550) [550..575) [575..600) [600..625)");



my (@a);

#print "25: \n";
@a = Set::Infinite->new([315,434], [530,600])->quantize(quant=>25)->list;
# tie @a, 'Set::Infinite::Quantize', 25, [315,434], [530,600];
#print join (" ",@a),"\n";
print "not " unless join (" ",@a) eq "[300..325) [325..350) [350..375) [375..400) [400..425) [425..450) [525..550) [550..575) [575..600) [600..625)";
print "ok 3\n";

#print "25: \n";
# tie @a, 'Set::Infinite::Quantize', 25, 315,434;
@a = Set::Infinite->new([315,434])->quantize(quant=>25)->list;
#print join (" ",@a),"\n";
print "not " unless join (" ",@a) eq "[300..325) [325..350) [350..375) [375..400) [400..425) [425..450)";
print "ok 4\n";

# tie @a, 'Set::Infinite::Quantize', 25, 300,434;
@a = Set::Infinite->new([300,434])->quantize(quant=>25)->list;
#print join (" ",@a),"\n";
print "not " unless join (" ",@a) eq "[300..325) [325..350) [350..375) [375..400) [400..425) [425..450)";
print "ok 5\n";

# tie @a, 'Set::Infinite::Quantize', 25, 315,450;
@a = Set::Infinite->new([315,450])->quantize(quant=>25)->list;
#print join (" ",@a),"\n";
print "not " unless join (" ",@a) eq "[300..325) [325..350) [350..375) [375..400) [400..425) [425..450) [450..475)";
print "ok 6\n";

# tie @a, 'Set::Infinite::Quantize', 25, 300,450;
@a = Set::Infinite->new([300,450])->quantize(quant=>25)->list;
#print join (" ",@a),"\n";
print "not " unless join (" ",@a) eq "[300..325) [325..350) [350..375) [375..400) [400..425) [425..450) [450..475)";
print "ok 7\n";

# recursive test
$a = Set::Infinite->new([1,3]);
# print "r: ", $a->quantize(quant => 1)->quantize(quant => 1), "\n";
print "not " unless join (" ", $a->quantize(quant => 1)->quantize(quant => 1)->list ) eq 
	"[1..2) [2..3) [3..4)";
print "ok 8\n";

$test = 8;


# open set
$a = Set::Infinite->new(1,5);
test ( '', ' $a->quantize ',
	"[1..2),[2..3),[3..4),[4..5),[5..6)");

$a = $a->complement(5);
# print "open set $a\n";
test ( '', ' $a->quantize ',
	"[1..2),[2..3),[3..4),[4..5)");

$a = $a->complement(1);
# print "open set $a\n";
test ( '', ' $a->quantize ',
	"[1..2),[2..3),[3..4),[4..5)");


# open set, real
$a = Set::Infinite->new(1.1,5.1);
test ( '', ' $a->quantize ',
	"[1..2),[2..3),[3..4),[4..5),[5..6)");

$a = $a->complement(5.1);
# print "open set $a\n";
test ( '', ' $a->quantize ',
	"[1..2),[2..3),[3..4),[4..5),[5..6)");

$a = $a->complement(1.1);
# print "open set $a\n";
test ( '', ' $a->quantize ',
	"[1..2),[2..3),[3..4),[4..5),[5..6)");

# open integer set
$a = Set::Infinite->new(1,5)->integer;
test ( '', ' $a->quantize ',
	"[1..2),[2..3),[3..4),[4..5),[5..6)");

$a = $a->complement(5);
# print "open set $a\n";
test ( '', ' $a->quantize ',
	"[1..2),[2..3),[3..4),[4..5)");

$a = $a->complement(1);
# print "open set $a\n";
test ( '', ' $a->quantize ',
	"[2..3),[3..4),[4..5)");

1;
