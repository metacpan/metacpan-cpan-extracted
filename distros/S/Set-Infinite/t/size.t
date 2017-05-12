#/bin/perl -w
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Tests for Set::Infinite::Quantize
# This is work in progress
#

use strict;
# use warnings;

use Set::Infinite qw($inf);

my $test = 0;
my ($result, $errors);
my $set;

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

print "1..14\n";
$| = 1;

$set = Set::Infinite->new([10,12]);
test ( 'new', '"$set"', '[10..12]');
test ("count", '$set->count', 1);
$set = $set->union( 14,16 );
test ("count", '$set->count', 2);
$set = $set->integer;
test ("integer size",  '$set->size',  6);
$set = $set->real;
test ("real size",  '$set->size',  4);

$set = Set::Infinite->new([10,11]);
test ( 'new', '"$set"', '[10..11]');
$set = $set->integer;
test ("integer size",  '$set->size',  2);
$set = $set->real;
test ("real size",  '$set->size',  1);

$set = Set::Infinite->new([10,10]);
test ( 'new', '"$set"', '10');
$set = $set->integer;
test ("integer size",  '$set->size',  1);
$set = $set->real;
test ("real size",  '$set->size',  0);

$set = Set::Infinite->new([10,11]);
$set = $set->complement( 11 );
test ( 'new', '"$set"', '[10..11)');
$set = $set->integer;
test ("integer size",  '$set->size',  0);
$set = $set->real;
test ("real size",  '$set->size',  1);

1;
