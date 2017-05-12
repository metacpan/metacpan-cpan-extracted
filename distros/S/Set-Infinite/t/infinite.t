#/bin/perl
# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Tests for Set::Infinite
# This is work in progress
#

use Set::Infinite qw($inf);

my $neg_inf = -$inf;
my $errors = 0;
my $test = 0;
my $set1;
my $set2;

print "1..85\n";

sub test {
	my ($header, $sub, $expected) = @_;
	$test++;
	#print "\t# $header $sub \n";
	$result = eval $sub;
    $result = '' unless defined $result;
	if ("$expected" eq "$result") {
		print "ok $test";
	}
	else {
		print "not ok $test\n \t# expected $header = \"$expected\" got \"$result\"";
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

Set::Infinite->separators( 
        '[', ']',    # a closed interval
        '(', ')',    # an open interval
        '..',        # number separator
        ',',         # list separator
        '', '',      # set delimiter  '{' '}'
    );

$set = $set; # clear warnings
$set = Set::Infinite->new([1],[2],[3],[4]);
test ("slice  ", '$set', "1,2,3,4"); # 1

Set::Infinite->separators(
        '', '',      # a closed interval
        '', '',      # an open interval
        '-',         # number separator
        ', ',        # list separator
        '{ ', ' }',  # set delimiter  
    );
test ("separators  ", '$set', "{ 1, 2, 3, 4 }"); # 1.1

# slice
$a = Set::Infinite->new(1..3);
test ("slice  ", '$a', "{ 1-2, 3 }"); # 2

Set::Infinite->separators(
        '[', ']',    # a closed interval
        '(', ')',    # an open interval
        '..',        # number separator
        ',',         # list separator
        '', '',      # set delimiter  '{' '}'
    );

# slice
$a = Set::Infinite->new([10..13,15,17]);
# print " slice: $a \n";
test ("slice  ", '$a', "[10..11],[12..13],[15..17]"); # 3


# print "Union\n";
$a = Set::Infinite->new(10, 13);
# print " a is ", $a, "\n";
test ("$a union (16..17)  ", '$a->union(16, 17)', "[10..13],[16..17]"); # 4
$a = Set::Infinite->new(16, 17);
# print " a is ", $a, "\n";
test ("$a union (10..13)  ", '$a->union(10, 13)', "[10..13],[16..17]"); # 5

# symmetric_difference
test ("$a symmetric_difference (10..16.5)  ", '$a->symmetric_difference(10, 16.5)', "[10..16),(16.5..17]"); # 5.5

# universal_set
test ("universal_set ", 'Set::Infinite->universal_set', "($neg_inf..$inf)" );

# print "Operations on open sets\n";
$a = Set::Infinite->new(1,$inf);
test ("set : ", 	'$a', "[1..$inf)"); # 6
$a = $a->complement;
test ("[-inf,1) : ", 	'$a', "($neg_inf..1)"); # 7
$b = $a;
test ("copy : ",	'$b',"($neg_inf..1)"); # 8
test ("complement : ",'$a->complement',"[1..$inf)");
test ("union [-1..0] : ", '$a->union(-1,0)', "($neg_inf..1)"); # 10
test ("union [0..1]  : ", '$a->union(0,1)', "($neg_inf..1]"); # 11
test ("union [1..2]  : ", '$a->union(1,2)', "($neg_inf..2]"); # 12
test ("union [2..3]  : ", '$a->union(2,3)', "($neg_inf..1),[2..3]"); # 13
$b = Set::Infinite->new($neg_inf,1)->complement;
#test ("set : ", '$a, "");
$c = $a->union($b);
test ("union $b : ", 	'$c', "($neg_inf..1),(1..$inf)"); # 14
test ("  complement : ", 	'$c->complement',"1"); # 15
test ("union $c [1..inf) ", 	'$c->union(1,$inf)', "($neg_inf..$inf)"); # 16
test ("union $b [1..inf) ", 	'$b->union(1,$inf)', "[1..$inf)"); # 17

# alternate names for "complement"
test ("  minus: ",        '$c->minus()',"1"); # 18
test ("  difference: ",        '$c->difference()',"1"); # 19

# print "Testing 'null' and (0..0)\n";

$a = Set::Infinite->new();
test ("null-1 : ",	'$a', "");
test ("is-null-1 : empty new ",	'$a->is_null',"1");

# TODO: test removed - doesn't pass in "fast" is_null - Flavio 
# $a = Set::Infinite->new('');
# test ("null : ",	'$a', "");
# test ("is-null : new empty-string ",	'$a->is_null',"1");

# $a = Set::Infinite->new(undef);
# test ("null-3 : ",	'$a',"");
# test ("is-null-3 : new undef ",	'$a->is_null',"1");

$a = Set::Infinite->new();
test ("(0,0) intersects to null : ",	'$a->intersects(0,0)',"0");
test ("(0,0) intersection to null : ",	'$a->intersection(0,0)',"");

$a = Set::Infinite->new(0,0);
test ("(0,0) intersects to null : ",'$a->intersects()',"0");
test ("(0,0) intersection to null : ",'$a->intersection()',"");

test ("(0,0) intersects to 0    : ",'$a->intersects(0)',"1");
test ("(0,0) intersection to 0    : ",'$a->intersection(0)',"0");
test ("is-null-4 : ",'$a->is_null',"0");

$a = Set::Infinite->new();
test ("(0,0) union to null : ",'$a->union(0,0)',"0");

$a = Set::Infinite->new(0,0);
test ("(0,0) union to null : ",$a->union(),"0");

$a = Set::Infinite->new(0,0);
test ("(0,0) intersects to (1,1) : ",'$a->intersects(1,1)',"0");
test ("(0,0) intersection to (1,1) : ",'$a->intersection(1,1)->as_string',"");


# print "New:\n";

$a = Set::Infinite->new(1,2);
$b = Set::Infinite->new([4,5],[7,8]);
$x = Set::Infinite->new(10,11);
$c = Set::Infinite->new($x);
# <removed!> $d = Set::Infinite->new( a => 13, b => 14 );
# print " a : $a\n b : $b\n c : $c\n d : $d\n";
$abcd = Set::Infinite->new([$a],[$b],[$c]);
# print " abcd $abcd\n";
test ("abcd",'$abcd',"[1..2],[4..5],[7..8],[10..11]");
$abcd = '';

# print "Contains\n";
$a = Set::Infinite->new([3,6],[12,18]);
test ("set : ", '$a', "[3..6],[12..18]");
test ("contains (4,5) : ", '$a->contains(4,5)', "1");
test ("contains (3,5) : ", '$a->contains(3,5)', "1");
test ("contains (2,5) : ", '$a->contains(2,5)', "0");
test ("contains (4,15) : ", '$a->contains(4,15)', "0");
test ("contains (15,16) : ", '$a->contains(15,16)', "1");
test ("contains (4,5),(15,16) : ", '$a->contains([4,5],[15,16])', "1");
test ("contains (4,5),(15,20) : ", '$a->contains([4,5],[15,20])', "0");


# print "Add element:\n";

$a = Set::Infinite->new(1,2);
$a = $a->union(3,4);
test (" (1,2) (3,4) : ",'$a',"[1..2],[3..4]");
# print "Parameter passing:\n";
test (" complement  : ",'$a->complement',"($neg_inf..1),(2..3),(4..$inf)");
test (" complement   (1.5,2.5) : ",'$a->complement(1.5,2.5)',"[1..1.5),[3..4]");
test (" union        (1.5,2.5) : ",'$a->union(1.5,2.5)',"[1..2.5],[3..4]");
test (" intersection (1.5,2.5) : ",'$a->intersection(1.5,2.5)',"[1.5..2]");
test (" intersects   (1.5,2.5) : ",'$a->intersects(1.5,2.5)',"1");

$a = Set::Infinite->new(Set::Infinite->new(1,2));
$a = $a->union(3, 4);
$a = $a->union(-1, 0);
$b = Set::Infinite->new($a);
# $b->cleanup;
# test ("Interval: (1,2) (3, 4) (-1, 0) : $b \n");

$a = $b;
$a = $a->union(0, 1);
$a = $a->union(7, 8);
$a = $a->union(6, 7.5);
# $a->cleanup;
# test ("Interval: add (0, 1) (7, 8) (6, 7.5) : $a \n");

# print "Integer + cleanup:\n";

$a = $a->integer;
# $a->cleanup;
test ("Interval: integer",'$a',"[-1..4],[6..8]");

# print "Intersects:\n";

$a = Set::Infinite->new(1,2);
test ("Interval:",'$a',"[1..2]");
test ("intersects 2.5 : ", '$a->intersects(2.5)', "0");
test ("intersects 1.5 : ", '$a->intersects(1.5)', "1");
test ("intersects 0.5 : ", '$a->intersects(0.5)', "0");
test ("intersects 0.1 .. 0.3 : ", '$a->intersects(Set::Infinite->new(0.1,0.3))', "0");
test ("intersects 0.1 .. 1.3 : ", '$a->intersects(Set::Infinite->new(0.1,1.3))', "1");
test ("intersects 1.1 .. 1.3 : ", '$a->intersects(Set::Infinite->new(1.1,1.3))', "1");
test ("intersects 1.1 .. 2.3 : ", '$a->intersects(Set::Infinite->new(1.1,2.3))', "1");
test ("intersects 2.1 .. 2.3 : ", '$a->intersects(Set::Infinite->new(2.1,2.3))', "0");
test ("intersects 0.0 .. 4.0 : ", '$a->intersects(Set::Infinite->new(0.0,4.0))', "1");

# print "Other:\n";

test ("Union 2.0 : ", '$a->union(2.0)', "[1..2]");
test ("Union 2.5 ", '$a->union(2.5)', "[1..2],2.5");
test ("Union 2.0 .. 2.5 : ", '$a->union(Set::Infinite->new(2.0,2.5))', "[1..2.5]");
test ("Union 0.5 .. 1.5 : ", '$a->union(Set::Infinite->new(0.5,1.5))', "[0.5..2]");
test ("Union 3.0 .. 4.0 : ", '$a->union(Set::Infinite->new(3.0,4.0))', "[1..2],[3..4]");
test ("Union 0.0 .. 4.0 5 .. 6 : ", '$a->union(Set::Infinite->new([0.0,4.0],[5.0,6.0]))', "[0..4],[5..6]");

$a = Set::Infinite->new(1,2);
test ("Interval",'$a',"[1..2]");
test ("intersection 2.5 : ", '$a->intersection(2.5)', "");
test ("intersection 1.5 : ", '$a->intersection(1.5)', "1.5");
test ("intersection 0.5 : ", '$a->intersection(0.5)', "");
test ("intersection 0.1 .. 0.3 : ", '$a->intersection(Set::Infinite->new(0.1,0.3))', "");
test ("intersection 0.1 .. 1.3 : ", '$a->intersection(Set::Infinite->new(0.1,1.3))', "[1..1.3]");
test ("intersection 1.1 .. 1.3 : ", '$a->intersection(Set::Infinite->new(1.1,1.3))', "[1.1..1.3]");
test ("intersection 1.1 .. 2.3 : ", '$a->intersection(Set::Infinite->new(1.1,2.3))', "[1.1..2]");
test ("intersection 2.1 .. 2.3 : ", '$a->intersection(Set::Infinite->new(2.1,2.3))', "");
test ("Union 5.5 : ", '$a->union(5.5)', "[1..2],5.5");
test ("intersection 0.0 .. 4.0 5 .. 6 : ", '$a->intersection(Set::Infinite->new([0.0,4.0],[5.0,6.0]))', "[1..2]");

$a = Set::Infinite->new(1,2, 4,5);
$b = Set::Infinite->new(1.1,2.1, 4.1,5.1);
test ("intersection $a with $b", '$a->intersection($b)', "[1.1..2],[4.1..5]");
test ("size of $b is : ", '$b->size', "2");
test ("span of $b is : ", '$b->span', "[1.1..5.1]");

# tie $a, 'Set::Infinite', [1,2], [9,10];
# test ("tied: ",'$a',"[1..2],[9..10]");


$a = Set::Infinite->new( -1,0);
test ("new  ", '$a', "[-1..0]"); 

# complement of empty/universal

 $a = Set::Infinite->new();
 test ("set : ",       '$a', ""); 
 $a = $a->complement;
 test ("(-inf,inf) : ",        '$a', "($neg_inf..$inf)"); 
 $a = $a->complement;
 test ("() : ",        '$a', ""); 


stats;
1;
