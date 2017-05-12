#/bin/perl -w
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Tests for Set::Infinite::Quantize/Select
# This is work in progress
#

use strict;
# use warnings;

my $test = 0;
my ($result, $errors);

# $Set::Infinite::TRACE = 1;

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
		print "\n\t# $sub \n\t# expected \"$expected\" \n\t#      got \"$result\"";
		$errors++;
	}
	print " \n";
}

sub stats {
	if ($errors) {
		#print "\n\t# Errors: $errors\n";
	}
	else {
		#print "\n\t# No errors.\n";
	}
}

use Set::Infinite;
# use Set::Infinite::Quantize;


print "1..8\n";

#print "1: \n";
$a = Set::Infinite->new([1,3],[30,40]);
test ( "Joined array: ", ' join ("", $a->quantize ) ',
 "[1..2),[2..3),[3..4),[30..31),[31..32),[32..33),[33..34),[34..35),[35..36),[36..37),[37..38),[38..39),[39..40),[40..41)");
test ( "Union with object: ", ' $a->quantize( quant => 2 )->union(9,10) ',
 # "[0..4),[9..10],[30..42)");    # also correct
 "[0..2),[2..4),[9..10],[30..32),[32..34),[34..36),[36..38),[38..40),[40..42)" );

#$a = Set::Infinite->new([1],[4],[6],[7]);
#test ( '', ' $a->select( freq => 2 )->union() ',
#  "1,6");

# NOTE: no longer passes this test since quantize() removes 'undef' values
# $a = Set::Infinite->new([1,4],[6,7]);
# test ( '', ' $a->quantize( quant => 0.5 )->select( freq => 2, by => [1] )->union() ',
#   "[1.5..2),[2.5..3),[3.5..4),[6.5..7)");

$a = Set::Infinite->new([1,9],[20,25]);
 
test (  "offset: ", '$a->offset( mode => "offset", value => [4,-4] )->union',
  "5");
test (  "begin:  ", '$a->offset( mode => "begin", value => [-1,1] )',
  "[0..2],[19..21]");
test (  "begin:  ", '$a->offset( mode => "circle", value => [0,1,-1,0] )',
  "[1..2],[8..9],[20..21],[24..25]");
test (  "end:    ", '$a->offset( mode => "end", value => [-1,1] )',
  "[8..10],[24..26]");
test (  "end:    ", '$a->offset( mode => "end", value => [-1,1, 2,3] )',
  "[8..10],[11..12],[24..26],[27..28]");

$a = Set::Infinite->new([20,100]);
# print "a = $a\n";
# $a->quantize(10)->iterate( sub { my $x = shift; print $x," & "; } );
# print "\n";
test ( "iterate", 
	'$a->quantize(quant=>10)->iterate( sub { my $x = shift; return $x; } )',
	'[20..110)');

# "This event happens from 13:00 to 14:00 every Tuesday, unless that Tuesday is the 15th of the month."

# $a->quantize('weeks')->offset('begin', tuesday,wednesday)->offset('begin',13:00,14:00) # tuesdays 13:00 to 14:00
# $a->quantize('months')->offset('begin',15days,16days)->     # 15th of the month
# ->complement
# ->intersection

1;
