#/bin/perl -w
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Tests for last()
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
		print "not ok $test\n    # $header\n"; # \n\t# expected \"$expected\" got \"$result\"";
		print "    # $sub expected \"$expected\" got \"$result\"  $@";
		$errors++;
	}
	print " \n";
}

# print "1..40\n";
$| = 1;

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;

$a = Set::Infinite->new([1,2],[4,5],[7,8]);
@a = $a->last;
test ("last, tail", '"@a"', '[7..8] [1..2],[4..5]');
@a = defined $a[1] ? $a[1]->last : ();
test ("last, tail", '"@a"', '[4..5] [1..2]');
@a = defined $a[1] ? $a[1]->last : ();
test ("last, tail", '"@a"', '[1..2]');
@a = defined $a[1] ? $a[1]->last : ();
test ("last, tail", '"@a"', '');

# complement

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
$a = Set::Infinite->new($neg_inf, 25)->quantize;
test ("quantize/complement", '$a->complement->last', "[26..$inf)");
# $Set::Infinite::TRACE = 0;

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
@a = $a->complement->last;
test ("last, tail 1", '"$a[0]"', "[26..$inf)");
@a = defined $a[1] ? $a[1]->last : ();
test ("last, tail 2", '"$a[0]"', '');   # complement is empty between quantize() elements
# $Set::Infinite::TRACE = 0;

$a = Set::Infinite->new($neg_inf,5)->quantize->complement->complement(10,11);

# $a = Set::Infinite->new(5,$inf)->quantize; warn $a;
# $a = $a->complement; warn $a;
# $a = $a->complement(10,11); warn $a;
@a = $a->last;
# warn "1-last,tail= @a";
@a = $a[0]->last;
# warn "2-first,tail= @a";

test ("quantize/complement", '$a->last', "(11..$inf)");
@a = $a->last;
test ("last, tail", '"$a[0]"', "(11..$inf)");
# $Set::Infinite::TRACE = 1;
@a = defined $a[1] ? $a[1]->last : ();
# $Set::Infinite::TRACE = 0;
test ("last, tail", '"$a[0]"', '[6..10)');   
@a = defined $a[1] ? $a[1]->last : ("");
test ("last, tail", '"$a[0]"', '');   # complement is empty between quantize() elements

# select

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
$a = Set::Infinite->new([25,$inf])->quantize;
# warn $a;
$b = $a->select(by => [2,3]);
# warn $b;
@a = $b->last;
test ("last, tail", '"@a"', '[28..29) [27..28)');
@a = defined $a[1] ? $a[1]->last : ();
test ("last, tail", '"@a"', '[27..28)');
@a = defined $a[1] ? $a[1]->last : ();
test ("last, tail", '"@a"', '');
$Set::Infinite::TRACE = 0;
$Set::Infinite::PRETTY_PRINT = 0;


# find '2nd' using complement/last 
test ("2nd", ' $b->complement( $b->last )->last ', '[27..28)');

# @a = $a->last;
# warn "last, tail is @a";
# warn "last of $b is ".$b->last;

#$c = $a->select(by => [2,3], count => 2, freq => 5 );
#@a = $c->last;
#test ("last, tail", '"@a"', '[33..34) [27..28),[28..29),[32..33)');
#@a = defined $a[1] ? $a[1]->last : ();
#test ("last, tail", '"@a"', '[32..33) [27..28),[28..29)');
#@a = defined $a[1] ? $a[1]->last : ();
#test ("last, tail", '"@a"', '[28..29) [27..28)');
#@a = defined $a[1] ? $a[1]->last : ();
#test ("last, tail", '"@a"', '[27..28)');
## $Set::Infinite::TRACE = 1;
## $Set::Infinite::PRETTY_PRINT = 1;
#@a = defined $a[1] ? $a[1]->last : ();
#test ("last, tail", '"@a"', '');

# TODO: test with negative values
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
# warn "select by=[2,3] freq=5 $a";
#$c = $a->select(by => [2,3], freq => 5 );
#@a = $c->last;

#if ( !defined $a[0] ) {
#    print "1..20\n";
#    print "  # TODO: fail last() of select()\n";
#    exit (0);
#}

#test ("last, tail", '"@a"', '[27..28) Too complex');
#@a = defined $a[1] ? $a[1]->last : ();
#test ("last, tail", '"@a"', '[28..29) Too complex');
#@a = defined $a[1] ? $a[1]->last : ();
#test ("last, tail", '"@a"', '[32..33) Too complex');
#@a = defined $a[1] ? $a[1]->last : ();
#test ("last, tail", '"@a"', '[33..34) Too complex');
#@a = defined $a[1] ? $a[1]->last : ();
#test ("last, tail", '"@a"', '[37..38) Too complex');

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
# count
$a = Set::Infinite->new([25,$inf])->quantize;
# warn $a;
$b = $a->select(count => 2);
# warn $b;
@a = $b->last;
test ("last, tail", '"@a"', '[26..27) [25..26)');
@a = defined $a[1] ? $a[1]->last : ();
test ("last, tail", '"@a"', '[25..26)');
@a = defined $a[1] ? $a[1]->last : ();
test ("last, tail", '"@a"', '');
$Set::Infinite::TRACE = 0;


# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
$a = Set::Infinite->new($neg_inf,15)->quantize->complement(15);
@a = $a->last;
test ("last, tail", '"@a"', "(15..16) ($neg_inf..15)");
@a = defined $a[1] ? $a[1]->last : ();
test ("last, tail", '"@a"', "($neg_inf..15)");

print "1..20\n";

1;
