#!/usr/bin/env perl
# A value with get magic -- a tied cell, a tied scalar, a regex capture -- read
# as a value, not as undef.
#
# SvOK() asked before an SV's get magic has run sees what the SV held before
# FETCH, which for a tied cell or $1 is nothing.  Up to 0.3413 these read an
# argument or a cell that way:
#
# 1. The distribution functions' argument parser, dist_parse(): after
#    "10" =~ /(\d+)/, pt(2.5, $1) took $1 for an option name with no value and
#    croaked "'(undef)' was given with no value", where pt(2.5, 10) gives
#    0.984276577881696 and pt(2.5, df => $1) worked.
# 2. p_adjust() on a flat list: a tied p-value read as undef, which p_adjust()
#    counts as 1, so bonferroni on 0.01 .. 0.05 with the last one tied gave 1
#    for it where the plain list gives 0.25.
# 3. kruskal_test(): a tied cell, in either input form, was dropped as
#    missing -- H = 3.857 where the same plain data give 4.5.  In the x/g form
#    both slots were fetched before x's FETCH ran, so a FETCH that emptied g
#    left the g pointer reading the freed block, and perl segfaulted.
# 4. friedman_test(): a block with a tied cell read as incomplete and was
#    dropped; its buffers were freed by hand, so a FETCH that died leaked them.
# 5. aov() without a formula: a tied cell of a group was left out.
#
# Each expectation is the same call on plain data, so the cases are this
# module's own: R and SciPy have no tied cells.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(pt qt pchisq qchisq pf qf pbinom p_adjust kruskal_test friedman_test aov);

# A tied scalar that returns its value on every FETCH, and runs $code first
# when one is given.
{
	package Val;
	sub TIESCALAR { my ($class, $value, $code) = @_; return bless { v => $value, code => $code }, $class }
	sub FETCH {
		my $self = shift;
		if (my $code = delete $self->{code}) { $code->() }
		return $self->{v};
	}
	sub STORE { $_[0]{v} = $_[1] }
}
# A tied scalar whose FETCH dies.
{
	package Dies;
	sub TIESCALAR { return bless {}, shift }
	sub FETCH { die "FETCH died\n" }
	sub STORE {}
}

# 1. dist_parse(): positional parameters with get magic
{
	# [function, x, positional parameters]
	my @calls = (
		[\&pt,     2.5,  [10]],
		[\&qt,     0.9,  [10]],
		[\&pchisq, 3,    [4]],
		[\&qchisq, 0.5,  [4]],
		[\&pf,     3,    [2, 10]],
		[\&qf,     0.5,  [2, 10]],
		[\&pbinom, 3,    [10, 0.5]],
	);
	my @names = qw(pt qt pchisq qchisq pf qf pbinom);
	for my $c (0 .. $#calls) {
		my ($fn, $x, $par) = @{ $calls[$c] };
		my $want = $fn->($x, @$par);
		my $text = join ' ', @$par;
		my $pat  = join ' ', ('(\S+)') x @$par;
		my $got;
		$text =~ /^$pat$/ or die;
		lives_ok { $got = @$par == 1 ? $fn->($x, $1) : $fn->($x, $1, $2) }
			"$names[$c]: positional capture variables are values";
		is($got, $want, "$names[$c]: and give the plain call's answer");
		my @t;
		tie $t[$_], 'Val', $par->[$_] for 0 .. $#$par;
		is($fn->($x, @t), $want, "$names[$c]: positional tied scalars give the plain call's answer");
	}
}

# 2. p_adjust() on a flat list
for my $method (qw(holm hochberg hommel bonferroni BH BY none)) {
	my @plain = (0.01, 0.02, 0.03, 0.04, 0.05);
	my @tied  = @plain[0 .. 3];
	tie $tied[4], 'Val', 0.05;
	is_deeply([ p_adjust(\@tied, $method) ], [ p_adjust(\@plain, $method) ],
		"p_adjust $method: a tied p-value is its value, not undef");
}

# 3. kruskal_test()
{
	my $want = kruskal_test(h => { a => [1, 3, 2], b => [9, 8, 7, 10] })->{statistic};
	my %h = (a => [1, 3, 2], b => [9, 8, 7]);
	tie $h{b}[3], 'Val', 10;
	is(kruskal_test(h => \%h)->{statistic}, $want, 'kruskal_test h: a tied cell is counted');

	my @x = (1, 3, 2, 9, 8, 7);
	my @g = qw(a a a b b b b);
	tie $x[6], 'Val', 10;
	is(kruskal_test(x => \@x, g => \@g)->{statistic}, $want, 'kruskal_test x/g: a tied x is counted');

	@x = (1, 3, 2, 9, 8, 7, 10);
	@g = qw(a a a b b b);
	tie $g[6], 'Val', 'b';
	is(kruskal_test(x => \@x, g => \@g)->{statistic}, $want, 'kruskal_test x/g: a tied g is counted');

	# x's FETCH empties g before g's cell is read
	@x = (1, 3, 2, 9, 8, 7, 10);
	@g = qw(a a a b b b b);
	untie $x[0];
	tie $x[0], 'Val', 1, sub { @g = () };
	throws_ok { kruskal_test(x => \@x, g => \@g) } qr/observations|group/,
		'kruskal_test x/g: a FETCH that empties g leaves nothing to test, and croaks rather than reading freed memory';
}

# 4. friedman_test()
{
	my @plain = ([1, 2, 3], [2, 3, 1], [3, 1, 2], [1, 3, 2]);
	my $want  = friedman_test(\@plain);
	my @m     = map { [@$_] } @plain;
	tie $m[3][2], 'Val', 2;
	my $got = friedman_test(\@m);
	is($got->{n}, $want->{n}, 'friedman_test: a block with a tied cell is complete');
	is($got->{statistic}, $want->{statistic}, 'friedman_test: and gives the plain statistic');
	my @d = map { [@$_] } @plain;
	tie $d[2][1], 'Dies';
	no_leaks_ok { eval { friedman_test(\@d) } } 'friedman_test: no leak when a FETCH dies';
}

# 5. aov() without a formula
{
	my $want = aov({ a => [1, 3, 2], b => [9, 8, 7, 10] })->{Group};
	my %h = (a => [1, 3, 2], b => [9, 8, 7]);
	tie $h{b}[3], 'Val', 10;
	is_deeply(aov(\%h)->{Group}, $want, 'aov stacked: a tied cell is counted');
}

done_testing();
