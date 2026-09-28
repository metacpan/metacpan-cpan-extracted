#!/usr/bin/env perl
# The reductions run an argument's get magic, exactly once, before reading it.
#
# Found by List::Util 1.70's t/min.t (see t/min.max.sum.ListUtil.t), whose
# GETMAGIC block calls sum(0, $#list). A scalar whose value exists only after
# mg_get() -- $#array, a tied scalar whose FETCH has not run, a substr() lvalue
# -- has no value flags before then, and up to 0.321 every function below
# tested SvOK() first and croaked "undefined value at argument index N" on it.
# The same held for a tied *element* of an ordinary array in median(),
# skew(), kurtosis() and mode(), which read AvARRAY directly, and scale(),
# which skips undef and so silently returned one value fewer than it was given.
#
# The oracle is the same call with the magic taken out: f(1, 7, $tied) must
# equal f(1, 7, 3) when the tie fetches 3. That is a statement about the Perl
# surface rather than about any statistic, so there is no reference
# implementation to take values from.
#
# FETCH is counted as well as the answer, because a second FETCH is a second
# call into perl and, for a tie that computes its value, a different value.
# sd(), var() and scale() read a tied array or a tied element once per pass,
# which their comments document; everything else reads each value once.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(min max sum mean sd var median mode uniq scale skew kurtosis);

{
	package Counted;	# a tied scalar that counts its FETCHes
	our $n = 0;
	sub TIESCALAR { my $v = $_[1]; bless \$v }
	sub FETCH     { $n++; ${ $_[0] } }
	sub STORE     { }
}
{
	package CountedArray;	# a tied array that counts its FETCHes
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
	our $n = 0;
	sub FETCH { $n++; $_[0]->SUPER::FETCH($_[1]) }
}

# name => FETCHes per magical value that a correct implementation makes
my %passes = (
	min => 1, max => 1, sum => 1, mean => 1, sd => 2, var => 2, median => 1,
	mode => 1, uniq => 1, scale => 2, skew => 1, kurtosis => 1,
);
# the list-returning ones compare as lists; mode()'s order is hash order
my %sorted = (mode => 1);

# The result as an array ref, or the croak as a string, so that one failing
# case reports rather than ending the file. The arguments are passed on as @_,
# which aliases the caller's SVs: copying them into a `my @args` would run
# their get magic here, and the XSUB would never see a magical SV at all.
sub call {
	my $f = shift;
	no strict 'refs';
	my @r = eval { &{"Stats::LikeR::$f"}(@_) };
	return $@ if $@;
	return $sorted{$f} ? [sort { $a <=> $b } @r] : \@r;
}

for my $f (sort keys %passes) {
	subtest $f => sub {
		my @plain = (1, 7, 3, 2);	# kurtosis() needs four values
		my $want  = call($f, @plain);

		my @l = (1) x 4;	# $#l is 3
		is_deeply(call($f, 1, 7, $#l, 2), $want, '$#array as an argument');

		tie my $t, 'Counted', 3;
		$Counted::n = 0;
		is_deeply(call($f, 1, 7, $t, 2), $want, 'tied scalar, FETCH not yet run');
		# direct arguments are fetched once and copied, whatever the pass count
		is($Counted::n, 1, 'tied scalar argument fetched once');

		tie my $r, 'Counted', [@plain];
		$Counted::n = 0;
		is_deeply(call($f, $r), $want, 'tied scalar holding an array ref');
		is($Counted::n, 1, 'tied array ref fetched once');

		my $s = '1732';
		is_deeply(call($f, substr($s, 0, 1), 7, substr($s, 2, 1), 2), $want,
		          'substr() lvalues as arguments');

		my @a = (1, 7, undef, 2);	# undef until the tie's FETCH runs
		tie $a[2], 'Counted', 3;
		$Counted::n = 0;
		is_deeply(call($f, \@a), $want, 'tied element of a plain array');
		is($Counted::n, $passes{$f}, "tied element fetched $passes{$f} time(s)");

		tie my @ta, 'CountedArray';
		@ta = @plain;
		$CountedArray::n = 0;
		is_deeply(call($f, \@ta), $want, 'tied array');
		is($CountedArray::n, $passes{$f} * @plain, "tied array: $passes{$f} FETCH(es) per element");
	};
}

# The fast path must still reject what it rejected before
like(eval { sum(1, [2, 'abc']); 1 } ? '' : $@,
     qr/^sum: non-numeric value at array ref index 1 \(argument 1\)/, 'non-numeric element still croaks');
{
	tie my $u, 'Counted', undef;
	like(eval { sum(1, $u); 1 } ? '' : $@,
	     qr/^sum: undefined value at argument index 1/, 'a tie that fetches undef is still undef');
	my @a = (1, 2, 3);
	tie $a[1], 'Counted', 'abc';
	like(eval { median(\@a); 1 } ? '' : $@,
	     qr/^median: non-numeric value at array ref index 1 \(argument 0\)/,
	     'a tied element that fetches a non-number croaks');
}

done_testing();
