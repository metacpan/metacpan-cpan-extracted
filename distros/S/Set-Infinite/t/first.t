#/bin/perl -w
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

print "1..24\n";
$| = 1;

# try _quantize_span

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;

$a = Set::Infinite->new([15,18])->quantize;
$span = $a->_quantize_span;
test ("quantize-span", '"$span"', "[15..19)");

$a = Set::Infinite->new([$neg_inf,10],[15,18])->quantize;
$span = $a->_quantize_span;
test ("quantize-span", '"$span"', "($neg_inf..11),[15..19)");

$a = Set::Infinite->new([$neg_inf,10],[15,18])->quantize( quant => 2 );
$c = $a->union(30,34)->quantize;
$span = $c->_quantize_span;
test ("quantize-span", '"$span"', "($neg_inf..12),[14..20),[30..35)");

$a = Set::Infinite->new(30,34)->quantize->span;
test ("span", '"$a"', "[30..35)");

$Set::Infinite::TRACE = 0;
$Set::Infinite::PRETTY_PRINT = 0;

# first

$a = Set::Infinite->new([1,2],[4,5],[7,8]);
@a = $a->first;
test ("first, tail", '"@a"', '[1..2] [4..5],[7..8]');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[4..5] [7..8]');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[7..8]');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '');

# complement

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
$a = Set::Infinite->new(25,$inf)->quantize;
test ("quantize/complement", '$a->complement->first', "($neg_inf..25)");
# $Set::Infinite::TRACE = 0;

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
@a = $a->complement->first;
test ("first, tail 1", '"$a[0]"', "($neg_inf..25)");
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail 2", '"$a[0]"', '');   # complement is empty between quantize() elements
# $Set::Infinite::TRACE = 0;

$a = Set::Infinite->new(25,$inf)->quantize->complement->complement(10,11);

# $a = Set::Infinite->new(25,$inf)->quantize; warn $a;
# $a = $a->complement; warn $a;
# $a = $a->complement(10,11); warn $a;
@a = $a->first;
# warn "1-first,tail= @a";
@a = $a[0]->first;
# warn "2-first,tail= @a";

test ("quantize/complement", '$a->first', "($neg_inf..10)");
@a = $a->first;
test ("first, tail", '"$a[0]"', "($neg_inf..10)");
# $Set::Infinite::TRACE = 1;
@a = defined $a[1] ? $a[1]->first : ();
# $Set::Infinite::TRACE = 0;
test ("first, tail", '"$a[0]"', '(11..25)');   
@a = defined $a[1] ? $a[1]->first : ("");
test ("first, tail", '"$a[0]"', '');   # complement is empty between quantize() elements


# TODO: last
# $a = Set::Infinite->new($neg_inf,25)->quantize;
# test ("quantize/complement", '$a->complement->last', "[26..$inf)");


# select

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
$a = Set::Infinite->new([25,$inf])->quantize;
# warn $a;
$b = $a->select(by => [2,3]);
# warn $b;
@a = $b->first;
test ("first, tail", '"@a"', '[27..28) [28..29)');    ### 15
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[28..29)');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '');
$Set::Infinite::TRACE = 0;
$Set::Infinite::PRETTY_PRINT = 0;


# find '2nd' using complement/first 
test ("2nd", ' $b->complement( $b->first )->first ', '[28..29)');  ### 18

# @a = $a->first;
# warn "first, tail is @a";
# warn "first of $b is ".$b->first;

my $skip = <<'__SKIP__';
$c = $a->select(by => [2,3], count => 2, freq => 5 );
@a = $c->first;
test ("first, tail", '"@a"', '[27..28) [28..29),[32..33),[33..34)');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[28..29) [32..33),[33..34)');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[32..33) [33..34)');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[33..34)');
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '');

# TODO: test with negative values
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
# warn "select by=[2,3] freq=5 $a";
$c = $a->select(by => [2,3], freq => 5 );
@a = $c->first;
test ("first, tail", '"@a"', '[27..28) Too complex');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[28..29) Too complex');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[32..33) Too complex');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[33..34) Too complex');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[37..38) Too complex');
__SKIP__

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
# count
$a = Set::Infinite->new([25,$inf])->quantize;
# warn $a;
$b = $a->select(count => 2);
# warn $b;
@a = $b->first;
test ("first, tail", '"@a"', '[25..26) [26..27)');   ### 19
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[26..27)');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '');
$Set::Infinite::TRACE = 0;

$skip = <<'__SKIP__';
# freq+count
$a = Set::Infinite->new([25,$inf])->quantize;
# warn $a;
$b = $a->select(count => 2, freq => 5);
# warn $b;
@a = $b->first;
test ("first, tail", '"@a"', '[25..26) [30..31)');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[30..31)');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '');

# freq
$a = Set::Infinite->new([25,$inf])->quantize;
# warn $a;
$b = $a->select(freq => 5);
# warn $b;
@a = $b->first;
test ("first, tail", '"@a"', '[25..26) Too complex');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[30..31) Too complex');
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', '[35..36) Too complex');
__SKIP__

# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
$a = Set::Infinite->new($neg_inf,15)->quantize->complement(15);
@a = $a->first;
test ("first, tail", '"@a"', "($neg_inf..15) (15..16)");
@a = defined $a[1] ? $a[1]->first : ();
test ("first, tail", '"@a"', "(15..16)");

1;
