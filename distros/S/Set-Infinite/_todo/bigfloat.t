#/bin/perl
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Tests for Set::Infinite
# This is work in progress
#

BEGIN { $| = 1; print "1..74\n"; }
END {$test++; print "not ok $test\n" unless $loaded;}

use Set::Infinite;
$loaded = 1;
use Math::BigFloat;

my $errors = 0;
my $test = 0;


sub test {
	my ($header, $sub, $expected) = @_;
	$test++;
	print "\t# $header \n";
	$result = eval $sub;
	if ("$expected" eq "$result") {
		print "ok $test";
	}
	else {
		print "not ok $test\n\t# expected \"$expected\" got \"$result\"";
		$errors++;
	}
	print " \n";
}

sub stats {
	if ($errors) {
		print "\n\t# Errors: $errors\n";
	}
	else {
		print "\n\t# No errors.\n";
	}
}

Set::Infinite->type('Math::BigFloat');
Set::Infinite->real;

print "\t# Add element:\n";

$a = Set::Infinite->new(1,2);
$a = $a->union(3,4);
test (" (1,2) (3,4) : ",'$a',"[1...2.],[3...4.]");

print "\t# Parameter passing:\n";
test (" complement  : ",'$a->complement',"(-inf..1.),(2...3.),(4...inf)");
test (" complement   (1.5,2.5) : ",'$a->complement(1.5,2.5)',"[1...1.5),[3...4.]");
test (" union        (1.5,2.5) : ",'$a->union(1.5,2.5)',"[1...2.5],[3...4.]");
test (" intersection (1.5,2.5) : ",'$a->intersection(1.5,2.5)',"[1.5..2.]");
test (" intersects   (1.5,2.5) : ",'$a->intersects(1.5,2.5)',"1");

$a = Set::Infinite->new(Set::Infinite->new(1,2));
$a->add(3, 4);
$a->add(-1, 0);
$b = Set::Infinite->new($a);
$b->cleanup;
test ("Interval: (1,2) (3, 4) (-1, 0) : $b \n");

$a = $b;
$a->add(0, 1);
$a->add(7, 8);
$a->add(6, 7.5);
$a->cleanup;
test ("Interval: add (0, 1) (7, 8) (6, 7.5) : $a \n");

print "\t# Integer + cleanup:\n";

$a->integer;
$a->cleanup;
test ("Interval: integer",'$a',"[-1...4.],[6...8.]");

print "\t# Operations on open sets\n";
$a = Set::Infinite->new(1,'inf');
test ("set : ", '$a', "[1...inf)");
$a = $a->complement;
test ("[-inf,1) : ", '$a', "(-inf..1.)");
$b = $a;
test ("copy : ",'$b',"(-inf..1.)");
test ("complement : ",$a->complement,"");
test ("union [-1...0] : ", '$a->union(-1,0)', "(-inf..1.)");
test ("union [0...1]  : ", '$a->union(0,1)', "(-inf..1.]");
test ("union [1...2]  : ", '$a->union(1,2)', "(-inf..2.]");
test ("union [2...3]  : ", '$a->union(2,3)', "(-inf..1.),[2...3.]");
$b = Set::Infinite->new(-inf,1)->complement;
#test ("set : ", '$a, "");
$c = $a->union($b);
test ("union $b : ", '$c', "(-inf..1.),(1...inf)");
test ("  complement : ", '$c->complement',"1.");
test ("union $c [1...inf) ", '$c->union(1,inf)', "(-inf..inf)");
test ("union $b [1...inf) ", '$b->union(1,inf)', "[1...inf)");

print "\t# Testing 'null' and (0...0)\n";

$a = Set::Infinite->new();
test ("null : ",$a,"null");

$a = Set::Infinite->new('null');
test ("null : ",$a,"null");

$a = Set::Infinite->new(undef);
test ("null : ",$a,"null");

$a = Set::Infinite->new();
test ("(0,0) intersects to null : ",$a->intersects(0,0),"0");
test ("(0,0) intersection to null : ",$a->intersection(0,0),"null");

$a = Set::Infinite->new(0,0);
test ("(0,0) intersects to null : ",$a->intersects(),"0");
test ("(0,0) intersection to null : ",$a->intersection(),"null");

test ("(0,0) intersects to 0    : ",$a->intersects(0),"1");
test ("(0,0) intersection to 0    : ",$a->intersection(0),"0");

$a = Set::Infinite->new();
test ("(0,0) union to null : ",$a->union(0,0),"0");

$a = Set::Infinite->new(0,0);
test ("(0,0) union to null : ",$a->union(),"0");

$a = Set::Infinite->new(0,0);
test ("(0,0) intersects to (1,1) : ",$a->intersects(1,1),"0");
test ("(0,0) intersection to (1,1) : ",$a->intersection(1,1)->as_string,"null");


print "\t# New:\n";

$a = Set::Infinite->new(1,2);
$b = Set::Infinite->new([4,5],[7,8]);
$x = Set::Infinite->new(10,11);
$c = Set::Infinite->new($x);
# <removed!> $d = Set::Infinite->new( a => 13, b => 14 );
#print "\t#  a : $a\n b : $b\n c : $c\n";  # d : $d\n";
$abcd = ' ';
$abcd = Set::Infinite->new([$a],[$b],[$c]);
#print " abcd $abcd\n";
test ("abcd",'$abcd',"[1...2.],[4...5.],[7...8.],[10...11.]");

print "\t# Contains\n";
$a = Set::Infinite->new([3,6],[12,18]);
test ("set : ", '$a', "[3...6.],[12...18.]");
test ("contains (4,5) : ", '$a->contains(4,5)', "1");
test ("contains (3,5) : ", '$a->contains(3,5)', "1");
test ("contains (2,5) : ", '$a->contains(2,5)', "0");
test ("contains (4,15) : ", '$a->contains(4,15)', "0");
test ("contains (15,16) : ", '$a->contains(15,16)', "1");
test ("contains (4,5),(15,16) : ", '$a->contains([4,5],[15,16])', "1");
test ("contains (4,5),(15,20) : ", '$a->contains([4,5],[15,20])', "0");



print "\t# Intersects:\n";

$a = Set::Infinite->new(2,1);
test ("Interval:",'$a',"[1...2.]");
test ("intersects 2.5 : ", '$a->intersects(2.5)', "0");
test ("intersects 1.5 : ", '$a->intersects(1.5)', "1");
test ("intersects 0.5 : ", '$a->intersects(0.5)', "0");
test ("intersects 0.1 ... 0.3 : ", '$a->intersects(Set::Infinite->new(0.1,0.3))', "0");
test ("intersects 0.1 ... 1.3 : ", '$a->intersects(Set::Infinite->new(0.1,1.3))', "1");
test ("intersects 1.1 ... 1.3 : ", '$a->intersects(Set::Infinite->new(1.1,1.3))', "1");
test ("intersects 1.1 ... 2.3 : ", '$a->intersects(Set::Infinite->new(1.1,2.3))', "1");
test ("intersects 2.1 ... 2.3 : ", '$a->intersects(Set::Infinite->new(2.1,2.3))', "0");
test ("intersects 0.0 ... 4.0 : ", '$a->intersects(Set::Infinite->new(0.0,4.0))', "1");

print "\t# Other:\n";

test ("Union 2.0 : ", '$a->union(2.0)', "[1...2.]");
test ("Union 2.5 ", '$a->union(2.5)', "[1...2.],2.5");
test ("Union 2.0 ... 2.5 : ", '$a->union(Set::Infinite->new(2.0,2.5))', "[1...2.5]");
test ("Union 0.5 ... 1.5 : ", '$a->union(Set::Infinite->new(0.5,1.5))', "[.5..2.]");
test ("Union 3.0 ... 4.0 : ", '$a->union(Set::Infinite->new(3.0,4.0))', "[1...2.],[3...4.]");
test ("Union 0.0 ... 4.0 5 ... 6 : ", '$a->union(Set::Infinite->new([0.0,4.0],[5.0,6.0]))', "[0...4.],[5...6.]");

$a = Set::Infinite->new(2,1);
test ("Interval",'$a',"[1...2.]");
test ("intersection 2.5 : ", '$a->intersection(2.5)', "null");
test ("intersection 1.5 : ", '$a->intersection(1.5)', "1.5");
test ("intersection 0.5 : ", '$a->intersection(0.5)', "null");
test ("intersection 0.1 ... 0.3 : ", '$a->intersection(Set::Infinite->new(0.1,0.3))', "null");
test ("intersection 0.1 ... 1.3 : ", '$a->intersection(Set::Infinite->new(0.1,1.3))', "[1...1.3]");
test ("intersection 1.1 ... 1.3 : ", '$a->intersection(Set::Infinite->new(1.1,1.3))', "[1.1..1.3]");
test ("intersection 1.1 ... 2.3 : ", '$a->intersection(Set::Infinite->new(1.1,2.3))', "[1.1..2.]");
test ("intersection 2.1 ... 2.3 : ", '$a->intersection(Set::Infinite->new(2.1,2.3))', "null");
test ("Union 5.5 : ", '$a->union(5.5)', "[1...2.],5.5");
test ("intersection 0.0 ... 4.0 5 ... 6 : ", '$a->intersection(Set::Infinite->new([0.0,4.0],[5.0,6.0]))', "[1...2.]");

$a = Set::Infinite->new(2,1,4,5);
$b = Set::Infinite->new(2.1,1.1,4.1,5.1);
test ("intersection $a with $b", '$a->intersection($b)', "[1.1..2.],[4.1..5.]");
test ("size of $b is : ", '$b->size', "2.");
test ("span of $b is : ", '$b->span', "[1.1..5.1]");

tie $a, 'Set::Infinite', [1,2], [9,10];
test ("tied: ",'$a',"[1...2.],[9...10.]");

stats;
1;
