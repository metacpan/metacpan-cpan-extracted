#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;

sub is_approx {
	my ($got, $expected, $name, $eps) = @_;
	$eps //= 1e-7;
	if (abs($got - $expected) <= $eps) { pass("$name: within $eps"); return 1; }
	fail($name); diag("  got: $got\n  expected: $expected");
	return 0;
}

# helper: fetch the row for a variable/level
sub row_for {
	my ($t1, $var, $level) = @_;
	$level //= '';
	for my $r (@$t1) { return $r if $r->{variable} eq $var && ($r->{level}//'') eq $level }
	return undef;
}

my @rows = (
	{arm=>"A",age=>50,sex=>"M"},{arm=>"A",age=>55,sex=>"F"},{arm=>"A",age=>60,sex=>"M"},
	{arm=>"A",age=>52,sex=>"F"},{arm=>"A",age=>58,sex=>"M"},
	{arm=>"B",age=>45,sex=>"F"},{arm=>"B",age=>48,sex=>"F"},{arm=>"B",age=>40,sex=>"M"},
	{arm=>"B",age=>44,sex=>"F"},{arm=>"B",age=>47,sex=>"M"},{arm=>"B",age=>43,sex=>"F"},
);
my @ageA = (50,55,60,52,58);
my @ageB = (45,48,40,44,47,43);

my $t1 = table_one(\@rows, by => "arm");

# continuous: mean (sd) per group must match mean()/sd() exactly, and the
# p-value must match a direct t_test.
my $age = row_for($t1, 'age');
is($age->{type}, 'continuous', 'age classified continuous');
is($age->{A}, sprintf('%.2f (%.2f)', mean(\@ageA), sd(\@ageA)), 'age group A summary');
is($age->{B}, sprintf('%.2f (%.2f)', mean(\@ageB), sd(\@ageB)), 'age group B summary');
is($age->{Overall}, sprintf('%.2f (%.2f)', mean([@ageA,@ageB]), sd([@ageA,@ageB])), 'age overall summary');
is($age->{test}, 't-test', 'age uses t-test (2 groups)');
is_approx($age->{'p_value'}, t_test(\@ageA,\@ageB)->{'p_value'}, 'age p-value matches t_test');

# categorical: header carries the chi-squared p; level rows carry n (%).
my $sex_hdr = row_for($t1, 'sex', '');
is($sex_hdr->{type}, 'categorical', 'sex classified categorical');
is($sex_hdr->{test}, 'chi-squared', 'sex uses chi-squared');
# this table's expected counts are all under 5, so chisq_test warns about the
# approximation exactly as R does; table_one keeps that warning to itself
{
	local $SIG{__WARN__} = sub {
		warn @_ unless $_[0] =~ /Chi-squared approximation may be incorrect/;
	};
	is_approx($sex_hdr->{'p_value'}, chisq_test([[2,4],[3,2]])->{'p_value'}, 'sex p-value matches chisq_test');
}

my $sexM = row_for($t1, 'sex', 'M');
my $sexF = row_for($t1, 'sex', 'F');
is($sexM->{A}, '3 (60.0%)', 'sex=M count in A');
is($sexM->{B}, '2 (33.3%)', 'sex=M count in B');
is($sexF->{A}, '2 (40.0%)', 'sex=F count in A');
is($sexF->{Overall}, '6 (54.5%)', 'sex=F overall count');

# >2 groups: ANOVA (parametric) and Kruskal (nonparametric)
my %hoa = (arm => [qw(A A A B B B C C C)], val => [5.1,4.9,6.2,6.1,6.9,7.2,8,9,10]);
my $par = table_one(\%hoa, by => "arm");
my $np  = table_one(\%hoa, by => "arm", nonparametric => 1);
is($par->[0]{test}, 'anova', '3 groups parametric => ANOVA');
is_approx($par->[0]{'p_value'}, aov(\%hoa,'val ~ arm')->{arm}{'Pr(>F)'}, 'ANOVA p matches aov');
is($np->[0]{test}, 'kruskal-wallis', '3 groups nonparametric => Kruskal-Wallis');
is_approx($np->[0]{'p_value'},
	kruskal_test([5.1,4.9,6.2,6.1,6.9,7.2,8,9,10],[qw(A A A B B B C C C)])->{'p_value'},
	'Kruskal p matches kruskal_test');

# no 'by' => single Overall column, no p-values
my $overall = table_one(\@rows);
ok(defined row_for($overall,'age')->{Overall}, 'no-by: Overall column present');
ok(!defined row_for($overall,'age')->{'p_value'}, 'no-by: no p-value');

# type override + digits
my $ov = table_one(\@rows, by => "arm", types => { age => 'categorical' }, digits => 1);
is(row_for($ov,'age')->{type}, 'categorical', 'types override forces categorical');

# vars selection
my $only = table_one(\@rows, by => "arm", vars => ['age']);
is(scalar(grep { $_->{variable} eq 'sex' } @$only), 0, 'vars limits which columns appear');

# error paths
dies_ok { table_one(\@rows, by => 'nope') }       'unknown by column dies';
dies_ok { table_one(\@rows, vars => ['ghost']) }  'unknown var dies';
dies_ok { table_one(\@rows, bogus => 1) }         'unknown option dies';

# Regressions, each of which failed on 0.3217.

# A continuous variable whose test cannot run gets no p-value, as a categorical
# one already did; t_test() dying on it used to take the whole table down.
{
	my %df = (arm  => [qw(a a a b b b)], age => [30, 41, 52, 33, 40, 47],
	          dose => [(5) x 6], lone => [1, 2, 3, 4, undef, undef]);
	for my $np (0, 1) {
		my $t;
		lives_ok { $t = table_one(\%df, by => 'arm', nonparametric => $np) }
			"nonparametric => $np: a constant column and a group of one do not die";
		ok(!defined row_for($t, 'lone')->{'p_value'}, "nonparametric => $np: a group of one has no p-value")
			unless $np;    # wilcox_test() runs on n = 1 against 3
		ok(defined row_for($t, 'age')->{'p_value'}, "nonparametric => $np: the other rows still have theirs");
	}
	my $t = table_one(\%df, by => 'arm');
	ok(!defined row_for($t, 'dose')->{'p_value'}, 'a constant column has no t-test p-value');
	ok(!defined row_for($t, 'dose')->{test}, '...and no test label');
	is(row_for($t, 'dose')->{a}, '5.00 (0.00)', '...but still its summary');
}

# A group may not share its name with an output column: a group named 'test'
# used to be overwritten by the label 't-test', and one named 'Overall'
# overwrote the column that summarises every row.
for my $name (qw(test Overall p_value variable level type)) {
	my %df = (arm => [ ($name) x 3, ('control') x 3 ], age => [30, 41, 52, 33, 40, 47]);
	throws_ok { table_one(\%df, by => 'arm') }
		qr/^table_one: the 'arm' column has a group named '\Q$name\E', which is also the name of an output column$/m,
		"a group named '$name' is refused";
}

# A type that is neither 'continuous' nor 'categorical' is refused; 'numeric'
# used to be taken as categorical, a row per distinct value.
throws_ok { table_one(\@rows, by => 'arm', types => { age => 'numeric' }) }
	qr/\ntable_one: error: the type of 'age' must be 'continuous' or 'categorical', not 'numeric'$/m,
	"types => { age => 'numeric' } is refused";
throws_ok { table_one(\@rows, types => { age => undef }) }
	qr/not 'undef'/, 'an undef type is refused';

# A `by` column shorter than the frame reads as NA past its end, as every other
# column already did; it used to die on perl's own "uninitialized" warning.
{
	my $t = table_one({ arm => [qw(a a b)], x => [1, 2, 3, 4] }, by => 'arm');
	is(row_for($t, 'x')->{NA}, '4.00 (0.00)', 'a short by column: the row past its end is group NA');
}

# More than two groups: the ANOVA p-value comes from oneway_test(var_equal => 1)
# unless a group has one observation, which it refuses and aov() does not.
{
	my %df = (arm => [qw(A A A B B B C)], val => [5.1, 4.9, 6.2, 6.1, 6.9, 7.2, 8]);
	my $t = table_one(\%df, by => 'arm');
	is($t->[0]{test}, 'anova', 'a group of one among three: still an ANOVA');
	is_approx($t->[0]{'p_value'}, aov(\%df, 'val ~ arm')->{arm}{'Pr(>F)'},
		'...whose p-value is aov()\'s', 1e-12);
}

# A categorical column shorter than the frame lists its rows past the end as
# NA.  They were counted, so the percentages already used them, but no NA row
# was listed.
{
	my $t = table_one({ arm => [qw(a a b b)], sex => [qw(F M F)] }, by => 'arm');
	my $na = row_for($t, 'sex', 'NA');
	ok(defined $na, 'a short categorical column has an NA row');
	is($na->{b}, '1 (50.0%)', '...counting the row past its end');
}

# Numeric levels sort as numbers, with NA last: a string sort put 10 between 1
# and 2.  Other levels keep the string sort.
{
	my %df = (stage => [1, 2, 10, 2, 1, 10, 3, undef], arm => [qw(a a a b b b b b)]);
	my $t = table_one(\%df, by => 'arm', vars => ['stage'], types => { stage => 'categorical' });
	is_deeply([ map { $_->{level} } @$t ], [ '', 1, 2, 3, 10, 'NA' ], 'numeric levels in numeric order, NA last');
	$t = table_one({ s => [qw(b a NA c)] }, types => { s => 'categorical' });
	is_deeply([ map { $_->{level} } @$t ], [ '', qw(NA a b c) ], 'string levels keep the string order');
}

# A call-form error prints table_one's argparse-style help screen (from
# lib/Stats/LikeR/Usage.pm), with the error itself on the last line.
{
	my $err = do { local $@; eval { table_one([ { a => 1 } ], bogus => 1); 1 } ? '' : $@ };
	like($err, qr/\Ausage: table_one\(/, 'table_one: a call-form error opens with the usage line');
	is($err, Stats::LikeR::_usage_text('table_one') . "table_one: error: unknown argument(s): bogus\n",
		'table_one: the help screen, then the error on the last line');
}
done_testing();
