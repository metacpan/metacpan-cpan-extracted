#!/usr/bin/env perl
# filter() runs a col() predicate two ways: compiled to C from the {plan} the
# col object carries, or by calling its {code} closure once per row.  Which one
# runs must never change the answer, so every predicate here is asked both ways
# -- a col object stripped of its plan is the same predicate on the closure
# path -- and the two results are compared.
#
# The second half covers the row buffer the closure path reuses over a HoA
# frame: a predicate that keeps hold of the row (or of a cell of it, or that
# adds a key to it) must still see, and keep, one distinct row per input row.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# the same predicate with its plan removed: forces the closure path
sub noplan { bless { code => $_[0]{code} }, 'Stats::LikeR::col' }

sub both_ways {
	my ($frame, $pred, $name, @opts) = @_;
	my $compiled = filter($frame, $pred,          @opts);
	my $closure  = filter($frame, noplan($pred),  @opts);
	is_deeply($compiled, $closure, "compiled == closure: $name");
	return $compiled;
}

#--------
# a frame with every awkward cell type in it: floats, integers, numbers held as
# strings, words, the empty string, undef, and (in the AoH) a missing key
#--------
my %col = (
	x	=> [ 3, -1.5, '7', 0, '2.50', 'abc', undef, '', 1e9, -0, '0 but true' ],
	tag => [ 'b', 'a', 'B', '',  'ab', 'abc', undef, 'z', 'A', 'aa', 'b' ],
	n	=> [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ],
);
my $hoa = { %col };
my $aoh = [ map { my $i = $_;
		+{ map { my $v = $col{$_}[$i]; defined $v ? ($_ => $v) : () } keys %col }
	} 0 .. $#{ $col{n} } ];
my $hoh = { map { ("r$_" => $aoh->[$_]) } 0 .. $#$aoh };

my @preds = (
	[ 'num >'		 => col('x') >  0 ],
	[ 'num <'		 => col('x') <  0 ],
	[ 'num >='		 => col('x') >= 2.5 ],
	[ 'num <='		 => col('x') <= 2.5 ],
	[ 'num =='		 => col('x') == 7 ],
	[ 'num !='		 => col('x') != 7 ],
	[ 'num swapped'	 => 0 < col('x') ],
	[ 'num swapped >=' => 2.5 >= col('x') ],
	[ 'num vs string literal' => col('x') > '2.5' ],
	[ 'int column'	 => col('n') >= 6 ],
	[ 'int equality' => col('n') == 11 ],
	[ 'big literal'	 => col('x') >= 1e9 ],
	[ 'str eq'		 => col('tag') eq 'b' ],
	[ 'str ne'		 => col('tag') ne 'b' ],
	[ 'str lt'		 => col('tag') lt 'b' ],
	[ 'str gt'		 => col('tag') gt 'b' ],
	[ 'str le'		 => col('tag') le 'b' ],
	[ 'str ge'		 => col('tag') ge 'b' ],
	[ 'str swapped'	 => 'b' gt col('tag') ],
	[ 'str vs number' => col('n') eq '10' ],
	[ 'and'			 => (col('x') > 0) & (col('tag') lt 'c') ],
	[ 'or'			 => (col('x') > 6) | (col('tag') eq 'a') ],
	[ 'not'			 => !(col('x') > 0) ],
	[ 'nested'		 => (!(col('n') > 3) | (col('tag') eq 'A')) & (col('x') != 0) ],
	[ 'same column twice' => (col('x') > 0) & (col('x') < 5) ],
	[ 'unknown column'	  => col('nope') > 0 ],
	[ 'unknown column !=' => col('nope') ne 'x' ],
	[ 'keeps nothing'	  => col('n') > 1000 ],
	[ 'keeps everything'  => col('n') > -1 ],
);

for my $p (@preds) {
	my ($name, $pred) = @$p;
	both_ways($hoa, $pred, "HoA $name");
	both_ways($aoh, $pred, "AoH $name");
	both_ways($hoh, $pred, "HoH $name");
	both_ways($hoa, $pred, "HoA->AoH $name", 'output.type' => 'aoh');
	both_ways($aoh, $pred, "AoH->HoA $name", 'output.type' => 'hoa');
	both_ways($hoh, $pred, "HoH->AoH $name", 'output.type' => 'aoh');
	both_ways($hoh, $pred, "HoH->HoA $name", 'output.type' => 'hoa');
}

#--------
# a couple of answers spelled out, so the two paths agreeing on a wrong one
# would still be caught
#--------
is_deeply(filter($hoa, col('x') > 0)->{n}, [ 1, 3, 5, 9 ],
	"numeric: undef, the empty string, words and '0 but true' never match");
is_deeply(filter($hoa, col('tag') eq 'b')->{n}, [ 1, 11 ], 'string eq is case sensitive');
is_deeply(filter($hoa, 2.5 >= col('x'))->{n}, [ 2, 4, 5, 10, 11 ], 'swapped operand');
is_deeply(filter($hoa, col('nope') > 0)->{n}, [], 'a column the frame does not have keeps nothing');

#--------
# a plan is only built for what C reproduces exactly; the rest still works
#--------
{
	my $obj = col('x') > \1;					# a reference operand: no plan
	ok(!exists $obj->{plan}, 'reference operand carries no plan');
	ok(!exists +(col('tag')->match(qr/^a/))->{plan}, '->match carries no plan');
	ok(!exists +((col('x') > 0) & col('tag')->match(qr/^a/))->{plan},
		'a combination with an unplannable part carries no plan');
	ok(exists +((col('x') > 0) & (col('tag') eq 'a'))->{plan}, 'a plannable combination has one');
	is_deeply(filter($hoa, col('tag')->match(qr/^a/))->{n}, [ 2, 5, 6, 10 ], '->match still filters');
}

#--------
# undef and non-numeric operands keep the closure's warning behaviour
#--------
{
	my $u = col('x') > undef;
	ok(!exists $u->{plan}, 'an undef operand carries no plan');
	my $w = col('x') > 'abc';
	ok(!exists $w->{plan}, 'a non-numeric operand carries no plan');
}

#--------
# ragged HoA: the short column reads as undef past its end, both ways
#--------
{
	my $r = { a => [ 1, 2, 3, 4 ], b => [ 'x', 'y' ] };
	both_ways($r, col('a') > 1, 'ragged HoA numeric');
	both_ways($r, col('b') eq 'y', 'ragged HoA string');
	is_deeply(filter($r, col('a') > 2), { a => [ 3, 4 ], b => [ undef, undef ] },
		'ragged HoA: missing cells come out undef');
}

#--------
# unicode column names and values
#--------
{
	my $u = { "\x{e9}t\x{e9}" => [ 'caf\x{e9}', "\x{e9}", 'e' ], n => [ 1, 2, 3 ] };
	both_ways($u, col("\x{e9}t\x{e9}") eq "\x{e9}", 'utf8 column name and value');
	is_deeply(filter($u, col("\x{e9}t\x{e9}") eq "\x{e9}")->{n}, [ 2 ], 'utf8 eq matches');
}

#--------
# the output is a copy: writing to it must not reach the input frame
#--------
{
	my $in  = { a => [ 1, 2, 3 ], b => [ 'p', 'q', 'r' ] };
	my $out = filter($in, col('a') >= 2);
	$out->{a}[0] = 99;
	$out->{b}[0] = 'zz';
	is_deeply($in, { a => [ 1, 2, 3 ], b => [ 'p', 'q', 'r' ] }, 'HoA output is a copy of the input');

	my $o2 = filter($in, col('a') >= 2, 'output.type' => 'aoh');
	$o2->[0]{a} = 99;
	is_deeply($in->{a}, [ 1, 2, 3 ], 'HoA -> AoH output is a copy too');
}

#--------
# the row a closure predicate sees over a HoA frame: one per input row, and it
# stays the caller's if the caller keeps it
#--------
{
	my $f = { id => [ 1, 2, 3, 4 ], w => [ qw(a b c d) ] };

	my @seen;
	filter($f, sub { push @seen, $_[0]; 1 });
	is_deeply(\@seen, [ map { +{ id => $_ + 1, w => (qw(a b c d))[$_] } } 0 .. 3 ],
		'a predicate that keeps every row gets four distinct, correct rows');

	my @kept;
	my $r = filter($f, sub { push @kept, $_ if $_->{id} % 2; $_->{id} > 2 });
	is_deeply(\@kept, [ { id => 1, w => 'a' }, { id => 3, w => 'c' } ],
		'rows kept by the predicate itself are not overwritten by later rows');
	is_deeply($r, { id => [ 3, 4 ], w => [ 'c', 'd' ] }, 'and the filter result is still right');

	my @cells;
	filter($f, sub { push @cells, \$_[0]{w}; 1 });
	is_deeply([ map { $$_ } @cells ], [ qw(a b c d) ],
		'a reference to a single cell keeps that cell alive and unchanged');

	my @rows;
	filter($f, sub { ok(!exists $_[0]{extra}, "row $_[0]{id} starts clean");
	                 $_[0]{extra} = 1; push @rows, $_[0]; 1 });
	is(scalar @rows, 4, 'a predicate that adds a key still sees four rows');

	# HoA -> AoH: the rows handed back must be distinct from each other and from
	# anything the predicate kept
	my @saw;
	my $a = filter($f, sub { push @saw, $_[0]; 1 }, 'output.type' => 'aoh');
	is_deeply($a, [ map { +{ id => $_ + 1, w => (qw(a b c d))[$_] } } 0 .. 3 ],
		'HoA -> AoH gives one row hash per kept row');
	is_deeply(\@saw, $a, 'and the predicate saw those same rows');
	$a->[0]{id} = 99;
	is($a->[1]{id}, 2, 'output rows are separate hashes');
	is_deeply($f->{id}, [ 1, 2, 3, 4 ], 'the input frame is untouched');
}

#--------
# $_[1] is the row id on both paths (a col() predicate ignores it, a sub may not)
#--------
{
	my $f = [ { x => 1 }, { x => 2 }, { x => 3 } ];
	is_deeply(filter($f, sub { $_[1] == 1 }), [ { x => 2 } ], 'AoH: $_[1] is the row index');
}

#--------
# memory
#--------
unless ($INC{'Devel/Cover.pm'}) {
	my $LHA = { x => [ 1, 2, 3 ], y => [ qw(p q r) ] };
	my $LA	= [ { x => 1, y => 'p' }, { x => 2, y => 'q' } ];
	my $LH	= { a => { x => 1 }, b => { x => 2 } };
	no_leaks_ok { filter($LHA, col('x') > 1) }							'no leak: compiled HoA';
	no_leaks_ok { filter($LHA, col('x') > 1, 'output.type' => 'aoh') }	'no leak: compiled HoA -> aoh';
	no_leaks_ok { filter($LA,  (col('x') > 1) & (col('y') eq 'q')) }	'no leak: compiled AoH, two columns';
	no_leaks_ok { filter($LA,  col('x') > 1, 'output.type' => 'hoa') }	'no leak: compiled AoH -> hoa';
	no_leaks_ok { filter($LH,  col('x') > 1) }							'no leak: compiled HoH';
	no_leaks_ok { filter($LH,  col('x') > 1, 'output.type' => 'hoa') }	'no leak: compiled HoH -> hoa';
	no_leaks_ok { filter($LHA, sub { $_->{x} > 1 }) }					'no leak: reused row buffer';
	no_leaks_ok { my @k; filter($LHA, sub { push @k, $_[0]; 1 }) }		'no leak: row buffer kept by the predicate';
	no_leaks_ok { eval { filter($LHA, sub { die "x\n" }) } }			'no leak: row buffer, dying predicate';
}

done_testing;
