#!/bin/perl -w
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Tests for first()
#

use strict;
# use warnings;

use Set::Infinite qw($inf);
$| = 1;

my $neg_inf = -$inf;
my $test = 0;
my ($result, $errors);
my @a;
my $c;
my $span;
$b=$b;  # clear a warning

sub test {
	my ($header, $sub, $expected) = @_;
	$test++;
	#print "\t# $header \n";
    $result = eval $sub;
    $result = '' unless defined $result;
	if ("$expected" eq "$result") {
		print "ok $test - $header";
	}
	else {
		print "not ok $test\n    # $header\n"; # \n\t# expected \"$expected\" got \"$result\"";
		print "    # $sub expected \"$expected\" got \"$result\"  $@";
		$errors++;
	}
	print " \n";
}

print "1..42\n";
$| = 1;

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;

$a = Set::Infinite->new([10],[30]);
test ("until after,after", 
    '$a->until( [20],[40] )', "[10..20),[30..40)");
test ("until before,inside",
    '$a->until( [0],[20] )', "($neg_inf..0),[10..20),[30..$inf)");
test ("until out of sync",
    '$a->until( [-20],[0],[20],[40],[60] )', 
    # "($neg_inf..0),[10..20),[30..40)" );   # also correct
    "($neg_inf..-20),[-20..0),[10..20),[30..40)" );

test ("until nothing",
    '$a->until()',
    "[10..$inf)");
$a = Set::Infinite->new();
test ("since nothing",
    '$a->until(10)',
    "($neg_inf..10)");
test ("since nothing, again",
    '$a->until([10],[30])',
    # "($neg_inf..30)" );   # also correct
    "($neg_inf..10)" );
test ("since nothing until nothing",
    '$a->until()',
    "($neg_inf..$inf)");
 
# unbounded recurrences

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;

# $a = ...0,20,40,60... forever
$a = Set::Infinite->new( $neg_inf, $inf )
    ->quantize( quant => 20 )
    ->offset( mode => 'begin', value => [0,0] );
# $b = ...10,30,50,70... forever
$b = $a->offset( mode => 'begin', value => [10,10] );
# warn "a: ". $a->intersection(5,45);
# warn "b: ". $b->intersection(5,45);
test ("until unbounded recurrence",
    '$a->until( $b )->intersection(5,45)', 
    "[5..10),[20..30),[40..45]");
test ("until unbounded recurrence, later",
    '$a->until( $b )->intersection(15,55)',
    "[20..30),[40..50)");

# inverse function - start_set/end_set
#  Note: Tests should verify that intersection bactracking
#  (it splits the spans!) does not modify the start/end values.
test ("start_set - until unbounded recurrence",
    '$a->until( $b )->start_set->intersection(5,45)', 
    "20,40");
test ("end_set - until unbounded recurrence",
    '$a->until( $b )->end_set->intersection(5,45)', 
    "10,30");

# iterate with backtracking
test ("iterate - unbounded recurrence - doesn't need backtracking help",
    '$a->iterate( sub { { $_[0]->min + 3, $_[0]->max + 3 } } )->intersection(5,45)',
    "23,43");
test ("iterate - unbounded recurrence - with backtracking helper",
    '$a->iterate( sub { { $_[0]->min + 54, $_[0]->max + 54 } },   '. 
    '             backtrack_callback =>                           '.
    '                sub { $_[0]->new( $_[0]->min - 54, $_[0]->max - 54 ) }, '.
    '           )->intersection(5,45)                             ',
    "14,34");
test ("iterate - unbounded recurrence - with backtracking, easier syntax",
    '$a->iterate( sub { $_[0]->min + 54, $_[0]->max + 54 },   '.
    '             backtrack_callback =>                           '.
    '                sub { $_[0]->min - 54, $_[0]->max - 54 }, '.
    '           )->intersection(5,45)                             ',
    "14,34");

# intersected_spans
test ("intersected_spans - simple",
    '$a->until( $b )->intersected_spans(5,45)',
    "[0..10),[20..30),[40..50)");
test ("intersected_spans - semi-bounded - first",
    '$a->until( $b )->intersected_spans(5,$inf)->first',
    "[0..10)");
test ("intersected_spans - semi-bounded - first",
    '$a->until( $b )->intersected_spans(5,$inf)->last',
    "$inf");
test ("intersected_spans - semi-bounded - last",
    '$a->until( $b )->intersected_spans(-$inf,45)->last',
    "[40..50)");
test ("intersected_spans - unbounded - first",
    '$a->until( $b )->intersected_spans($a)->intersection(5,45)',
    "[5..10),[20..30),[40..45]");
test ("intersected_spans - span-set",
    '$a->until( $b )->intersected_spans( [5,25], [65,85] )',
    "[0..10),[20..30),[60..70),[80..90)");
test ("intersected_spans - span-set",
    '$a->until( $b )->intersection(0,100)->intersected_spans( [5,25], [65,85] )',
    "[0..10),[20..30),[60..70),[80..90)");
test ("intersected_spans - bounded to unbounded",
    '$a->until( $b )->intersection(0,50)->intersected_spans($a)',
    "[0..10),[20..30),[40..50)");
test ("intersected_spans - half-open interval",
    '$a->until( $b )->intersected_spans( Set::Infinite->new({ a=>5,
        open_begin=>1, b=>45, open_end=>0 }) )',
    "[0..10),[20..30),[40..50)");
test ("intersected_spans - half-open interval",
    '$a->until( $b )->intersected_spans( Set::Infinite->new({ a=>5,
        open_begin=>0, b=>45, open_end=>1 }) )',
    "[0..10),[20..30),[40..50)");
test ("intersected_spans - bounded LHS with half-open interval",
    'Set::Infinite->new([0,20],[30,50],[60,80])->intersected_spans(
        Set::Infinite->new({ a=>5, open_begin=>1, b=>45, open_end=>0 }) )',
    "[0..20],[30..50]");
test ("intersected_spans - bounded LHS with half-open interval",
    'Set::Infinite->new([0,20],[30,50],[60,80])->intersected_spans(
        Set::Infinite->new({ a=>5, open_begin=>0, b=>45, open_end=>1 }) )',
    "[0..20],[30..50]");


# let's test if contains() works properly with unbounded recurrences
# because we'll need that

test ("contains - unbounded recurrence",
    '$a->contains( 20 )', 1 ); 
test ("doesn't contain - unbounded recurrence",
    '$a->contains( 15 )', 0 );

# intersection with small sets is heavily used by backtracking code
# when checking timezones

test ("until - intersection - small set",
    '$a->until( $b )->intersection(22,28)',
    "[22..28]");
test ("until - non-intersection - small set",
    '$a->until( $b )->intersection(32,38)',
    "");

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
test ("until - contains - small set",
    '$a->until( $b )->contains(22,28)',
    "1");
$Set::Infinite::TRACE = 0;
$Set::Infinite::PRETTY_PRINT = 0;
test ("until - doesn't contain - small set",
    '$a->until( $b )->contains(32,38)',
    "0");

# first, min, max

test ("until - first",
    '$a->until( $b )->intersection(32,$inf)->first',
    "[40..50)");
test ("until - first",
    '($a->until( $b )->intersection(32,$inf)->first)[1]->first',
    "[60..70)");
test ("until - last",
    '$a->until( $b )->intersection(-$inf,32)->last',
    "[20..30)");
test ("until - last",
    '($a->until( $b )->intersection(-$inf,32)->last)[1]->last',
    "[0..10)");

test ("until - min",
    '$a->until( $b )->intersection(32,$inf)->min',
    "40");
test ("until - max",
    '$a->until( $b )->intersection(-$inf,32)->max',
    "30");

# start-set == end-set

test ("until - first",
    '$a->until( $a )->intersection(32,$inf)->first',
    "[32..40)");
test ("until - last",
    '$a->until( $a )->intersection(-$inf,32)->last',
    "[20..32]");

test ("until - min",
    '$a->until( $a )->intersection(32,$inf)->min',
    "32");
test ("until - max",
    '$a->until( $a )->intersection(-$inf,32)->max',
    "32");


1;
