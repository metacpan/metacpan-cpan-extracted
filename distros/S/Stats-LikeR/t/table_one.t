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
is_approx($age->{p_value}, t_test(\@ageA,\@ageB)->{p_value}, 'age p-value matches t_test');

# categorical: header carries the chi-squared p; level rows carry n (%).
my $sex_hdr = row_for($t1, 'sex', '');
is($sex_hdr->{type}, 'categorical', 'sex classified categorical');
is($sex_hdr->{test}, 'chi-squared', 'sex uses chi-squared');
is_approx($sex_hdr->{p_value}, chisq_test([[2,4],[3,2]])->{'p.value'}, 'sex p-value matches chisq_test');

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
is_approx($par->[0]{p_value}, aov(\%hoa,'val ~ arm')->{arm}{'Pr(>F)'}, 'ANOVA p matches aov');
is($np->[0]{test}, 'kruskal-wallis', '3 groups nonparametric => Kruskal-Wallis');
is_approx($np->[0]{p_value},
	kruskal_test([5.1,4.9,6.2,6.1,6.9,7.2,8,9,10],[qw(A A A B B B C C C)])->{p_value},
	'Kruskal p matches kruskal_test');

# no 'by' => single Overall column, no p-values
my $overall = table_one(\@rows);
ok(defined row_for($overall,'age')->{Overall}, 'no-by: Overall column present');
ok(!defined row_for($overall,'age')->{p_value}, 'no-by: no p-value');

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

done_testing();
