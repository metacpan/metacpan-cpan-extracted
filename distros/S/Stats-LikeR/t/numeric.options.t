#!/usr/bin/env perl
# A numeric option or positional argument that is not a number croaks.
#
# t_test([1,2,3,4], mu => "abc") warned and ran as mu = 0 (R stops with
# "invalid 'mu' argument"), conf_level => "abc" ran as a level of 0, and
# pt("abc", 5) answered pt(0, 5): SvNV() reads a string that is not a number
# as 0 and an XSUB's SvNV() warns only under the caller's `use warnings`.
# Every site now goes through sv_num_opt() (XS) or looks_like_number() (Perl).
#
# The expectations are the module's own contract, not a reference's: R's
# equivalent is an error for each of these, which is all there is to take.
# Not covered here: boolean-or-number options (scale's center and scale accept
# words), and data vectors, where a string that is not a number is a missing
# value by design.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;
use Test::Exception;
use File::Temp ();

my @x = (2.1, 3.4, 1.9, 5.5, 4.2, 3.8, 2.7, 4.9);
my @y = (1.1, 2.4, 3.9, 2.5, 3.2, 1.8, 2.2, 3.9);
my @aoh = map { { y => $y[$_], x => $x[$_], g => ($_ % 2), c => ($_ % 3) } } 0 .. 7;
my %surv = (time => [1 .. 7], status => [1, 1, 0, 1, 1, 1, 1], x => [1, 3, 2, 5, 4, 7, 6]);
my @s = ([1, 0.9, 0.8, 0.1, 0.2], [1, 1, 0, 0, 0]);
my (undef, $xlsx) = File::Temp::tempfile(SUFFIX => ".xlsx", TMPDIR => 1, UNLINK => 1);

# [ function, [fixed args], [options to set to "abc"] ]
my @cases = (
	[t_test       => [\@x],                      [qw(mu conf_level)]],
	[t_test       => [\@x, \@y],                 [qw(mu conf_level)]],
	[wilcox_test  => [\@x, \@y],                 [qw(mu conf_level tol_root)]],
	[var_test     => [\@x, \@y],                 [qw(ratio conf_level)]],
	[cor_test     => [\@x, \@y],                 [qw(conf_level)]],
	[prop_test    => [[15, 25], [50, 50]],       [qw(conf_level)]],
	[fisher_test  => [[[10, 5], [3, 12]]],       [qw(conf_level)]],
	[roc          => [@s],                       [qw(conf_level)]],
	[bedroc       => [@s],                       [qw(alpha)]],
	[auroc        => [@s],                       [qw(cutoff active_frac)]],
	[logrank_test => [[1 .. 6], [1, 1, 0, 1, 1, 1], [1, 1, 1, 2, 2, 2]], [qw(rho)]],
	[survfit      => [[1 .. 6], [1, 1, 0, 1, 1, 1]], [qw(conf_level)]],
	[glm          => [formula => 'y ~ x', data => \@aoh], [qw(conf_level epsilon maxit)]],
	[lmer         => [formula => 'y ~ x + (1|g)', data => \@aoh], [qw(conf_level)]],
	[coxph        => [formula => 'Surv(time,status)~x', data => \%surv], [qw(conf_level eps maxit iter_max)]],
	[dnorm        => [0],                        [qw(mean sd)]],
	[pnorm        => [0],                        [qw(mean sd)]],
	[qnorm        => [0.3],                      [qw(mean sd)]],
	[pt           => [1.5, 5],                   [qw(df)]],
	[qt           => [0.3, 5],                   [qw(df)]],
	[pchisq       => [1.5, 5],                   [qw(df)]],
	[qchisq       => [0.3, 5],                   [qw(df)]],
	[pf           => [1.5, 3, 5],                [qw(df1 df2)]],
	[pbinom       => [3, 10, 0.5],               [qw(size prob)]],
	[ptukey       => [3, 3, 10],                 [qw(nranges)]],
	[qtukey       => [0.9, 3, 10],               [qw(nranges)]],
	[prcomp       => [{a => [1, 2, 3, 4, 5], b => [2, 1, 4, 3, 6]}], [qw(tol rank)]],
	[age_standardize => [[1, 2], [3, 4], [1, 1]], [qw(conf_level per)]],
	[table_one    => [[{a => 1, g => 1}, {a => 2, g => 2}]], [qw(digits pct_digits)]],
	[epi_2x2      => [[[10, 5], [3, 12]]],       [qw(conf_level)]],
	[binom_test   => [7, 20],                    [qw(p conf_level)]],
	[density      => [\@x],                     [qw(adjust n cut ext from to)]],
	[bw_sj        => [\@x],                     [qw(lower upper tol)]],
	[bw_ucv       => [\@x],                     [qw(lower upper tol)]],
	[power_t_test => [n => 20, delta => 1],      [qw(n delta sd sig_level tol)]],
	[power_t_test => [n => 20, power => 0.9],    [qw(power)]],
	[wilcox_test  => [\@x, \@y],                 [qw(edgeworth)]],
	[write_table  => [[{a => 1}], $xlsx],        [qw(xlsx_freeze_rows xlsx_freeze_cols)]],
);
for my $c (@cases) {
	my ($f, $args, $opts) = @$c;
	no strict 'refs';
	my $fn = \&{"Stats::LikeR::$f"};
	lives_ok { $fn->(@$args) } "$f: the baseline call works"
		or next;
	for my $o (@$opts) {
		throws_ok { $fn->(@$args, $o => "abc") } qr/\Q$o\E.*not a number|not a number/,
			"$f $o => 'abc' croaks";
	}
}

# positional arguments
throws_ok { Stats::LikeR::pnorm("abc") }            qr/pnorm: error: x is not a number/, 'pnorm("abc")';
throws_ok { Stats::LikeR::pnorm(["abc"]) }          qr/pnorm: error: x is not a number/, 'pnorm(["abc"])';
throws_ok { Stats::LikeR::dnorm(["abc"]) }          qr/dnorm: error: x is not a number/, 'dnorm(["abc"])';
throws_ok { Stats::LikeR::pt("abc", 5) }            qr/pt: error: x is not a number/,    'pt("abc", 5)';
throws_ok { Stats::LikeR::pt(1.5, "abc") }          qr/pt: error: 'df' is not a number/, 'pt(1.5, "abc")';
throws_ok { Stats::LikeR::pt(1.5, dff => 5) }       qr/pt: error: 'df' is not a number/, 'a misspelled option name is not a number';
throws_ok { Stats::LikeR::ptukey("abc", 3, 10) }    qr/ptukey: error: q is not a number/, 'ptukey q';
throws_ok { Stats::LikeR::ptukey(3, "abc", 10) }    qr/ptukey: error: nmeans is not a number/, 'ptukey nmeans';
throws_ok { Stats::LikeR::qtukey(0.9, 3, "abc") }   qr/qtukey: error: df is not a number/, 'qtukey df';
throws_ok { Stats::LikeR::seq("abc", 5) }           qr/seq: error: from is not a number/, 'seq from';
throws_ok { Stats::LikeR::seq(1, "abc") }           qr/seq: error: to is not a number/, 'seq to';
throws_ok { Stats::LikeR::seq(1, 5, "abc") }        qr/seq: error: by is not a number/, 'seq by';

# what is still accepted: numeric strings, whitespace, Inf, undef x, objects
{
	my $r = Stats::LikeR::t_test(\@x, mu => " 1.5 ", conf_level => "0.9");
	my $ref = Stats::LikeR::t_test(\@x, mu => 1.5, conf_level => 0.9);
	is($r->{statistic}, $ref->{statistic}, 'numeric strings with space are numbers');
	lives_ok { Stats::LikeR::wilcox_test(\@x, \@y, mu => "1e-1", conf_level => "0.9") } 'exponent string';
	is(Stats::LikeR::pnorm("Inf"), 1, 'pnorm("Inf")');
	is(Stats::LikeR::pnorm(0, mean => "0", sd => "1"), 0.5, 'pnorm numeric string options');
	ok(Stats::LikeR::pt(" 1.5 ", "5") == Stats::LikeR::pt(1.5, 5), 'pt numeric strings');
	is_deeply([Stats::LikeR::seq("1", "3", "1")], [1, 2, 3], 'seq numeric strings');
	ok(Stats::LikeR::pnorm([undef])->[0] != Stats::LikeR::pnorm([undef])->[0], 'undef element is still NaN');
	lives_ok { Stats::LikeR::t_test(\@x, conf_level => bless({}, 'Num')) } 'object overloading 0+ is a number';
}

# an object overloading its numeric conversion (package statements, not blocks: 5.10)
{
	package Num; use overload '0+' => sub { 0.9 }, fallback => 1;
	package main;
}

done_testing();
