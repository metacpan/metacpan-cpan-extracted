use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::Stats::Basic;
use Test::PDL;

my $a = sequence 5;
is_pdl $a->stdv, pdl( 1.4142135623731 ), "standard deviation of $a";
is_pdl $a->stdv_unbiased, pdl( 1.58113883008419 ), "unbiased standard deviation of $a";
is_pdl $a->var, pdl( 2 ), "variance of $a";
is_pdl $a->var_unbiased, pdl( 2.5 ), "unbiased variance of $a";
is_pdl $a->se, pdl( 0.707106781186548 ), "standard error of $a";
is_pdl $a->ss, pdl( 10 ), "sum of squared deviations from the mean of $a";
is_pdl $a->skew, pdl( 0 ), "sample skewness of $a";
is_pdl $a->skew_unbiased, pdl( 0 ), "unbiased sample skewness of $a";
is_pdl $a->kurt, pdl( -1.3 ), "sample kurtosis of $a";
is_pdl $a->kurt_unbiased, pdl( -1.2 ), "unbiased sample kurtosis of $a";

is_pdl $_->ss, (($_ - $_->avg)**2)->sumover, "ss for $_" for
  pdl('[1 1 1 1 2 3 4 4 4 4 4 4]'),
  pdl('[1 2 2 2 3 3 3 3 4 4 5 5]'),
  pdl('[1 1 1 2 2 3 3 4 4 5 5 5]');

my $a_bad = sequence 6;
$a_bad->setbadat(-1);
is_pdl $a_bad->stdv, pdl( 1.4142135623731 ), "standard deviation of $a_bad";
is_pdl $a_bad->stdv_unbiased, pdl( 1.58113883008419 ), "unbiased standard deviation of $a_bad";
is_pdl $a_bad->var, pdl( 2 ), "variance of $a_bad";
is_pdl $a_bad->var_unbiased, pdl( 2.5 ), "unbiased variance of $a_bad";
is_pdl $a_bad->se, pdl( 0.707106781186548 ), "standard error of $a_bad";
is_pdl $a_bad->ss, pdl( 10 ), "sum of squared deviations from the mean of $a_bad";
is_pdl $a_bad->skew, pdl( 0 ), "sample skewness of $a_bad";
is_pdl $a_bad->skew_unbiased, pdl( 0 ), "unbiased sample skewness of $a_bad";
is_pdl $a_bad->kurt, pdl( -1.3 ), "sample kurtosis of $a_bad";
is_pdl $a_bad->kurt_unbiased, pdl( -1.2 ), "unbiased sample kurtosis of $a_bad";

my $b = pdl '0 0 0 1 1';
is_pdl $a->cov($b), pdl( 0.6 ), "sample covariance of $a and $b";
is_pdl $a->corr($b), pdl( 0.866025403784439 ), "Pearson correlation coefficient of $a and $b";
is_pdl $a->n_pair($b), indx( 5 ), "Number of good pairs between $a and $b";
is_pdl $a->corr($b)->t_corr( 5 ), pdl( 3 ), "t significance test of Pearson correlation coefficient of $a and $b";
is_pdl $a->corr_dev($b), pdl( 0.903696114115064 ), "correlation calculated from dev_m values of $a and $b";

my $b_bad = pdl 'BAD 0 0 1 1 1';
is_pdl $a_bad->cov($b_bad), pdl( 0.5 ), "sample covariance with bad data of $a_bad and $b_bad";
is_pdl $a_bad->corr($b_bad), pdl( 0.894427190999916 ), "Pearson correlation coefficient with bad data of $a_bad and $b_bad";
is_pdl $a_bad->n_pair($b_bad), indx( 4 ), "Number of good pairs between $a_bad and $b_bad with bad values taken into account";
is_pdl $a_bad->corr($b_bad)->t_corr( 4 ), pdl( 2.82842712474619 ), "t signifiance test of Pearson correlation coefficient with bad data of $a_bad and $b_bad";
is_pdl $a_bad->corr_dev($b_bad), pdl( 0.903696114115064 ), "correlation calculated from dev_m values with bad data of $a_bad and $b_bad";

my ($t, $df) = $a->t_test($b);
is_pdl $t, pdl( 2.1380899352994 ), "t-test between $a and $b - 't' output";
is_pdl $df, pdl( 8 ), "t-test between $a and $b - 'df' output";

($t, $df) = $a->t_test_nev($b);
is_pdl $t, pdl( 2.1380899352994 ), "t-test with non-equal variance between $a and $b - 't' output";
is_pdl $df, pdl( 4.94637223974763 ), "t-test with non-equal variance between $a and $b - 'df' output";

($t, $df) = $a->t_test_paired($b);
is_pdl $t, pdl( 3.13785816221094 ), "paired sample t-test between $a and $b - 't' output";
is_pdl $df, pdl( 4 ), "paired sample t-test between $a and $b - 'df' output";

($t, $df) = $a_bad->t_test($b_bad);
is_pdl $t, pdl( 1.87082869338697 ), "t-test with bad values between $a_bad and $b_bad - 't' output";
is_pdl $df, pdl( 8 ), "t-test with bad values between $a_bad and $b_bad - 'd' output";

($t, $df) = $a_bad->t_test_nev($b_bad);
is_pdl $t, pdl( 1.87082869338697 ), "t-test with non-equal variance with bad values between $a_bad and $b_bad - 't' output";
is_pdl $df, pdl( 4.94637223974763 ), "t-test with non-equal variance with bad values between $a_bad and $b_bad - 'df' output";

($t, $df) = $a_bad->t_test_paired($b_bad);
is_pdl $t, pdl( 4.89897948556636 ), "paired sample t-test with bad values between $a_bad and $b_bad - 't' output";
is_pdl $df, pdl( 3 ), "paired sample t-test with bad values between $a_bad and $b_bad - 'df' output";

{
  my ($data, $idv, $ido) = rtable(\*DATA, {V=>0});
  is_pdl $data, pdl '
   [  5 BAD BAD   2 BAD   5 BAD   9   4 BAD BAD BAD   5 BAD]
   [  7 BAD   3   7   0 BAD   0   8 BAD   0   3   0 BAD   0]
   [BAD BAD BAD BAD BAD   1 BAD   1 BAD BAD BAD BAD   1 BAD]
   [BAD BAD BAD BAD BAD   0 BAD   5 BAD BAD BAD BAD   0 BAD]
   [BAD BAD   0 BAD   2 BAD   0 BAD BAD   0   0   2 BAD   0]
  ';
}

{
  my $a = pdl '
  0.045 0.682 0.290 0.024 0.598 0.321 0.772 0.375 0.237 0.811;
  0.356 0.094 0.925 0.139 0.701 0.849 0.689 0.109 0.240 0.847;
  0.822 0.492 0.351 0.860 0.400 0.243 0.313 0.011 0.437 0.480
';
  is_pdl $a->cov_table, $a->cov($a->dummy(1)), 'cov_table';
  $a->setbadat(4,0);
  is_pdl $a->cov_table, $a->cov($a->dummy(1)), 'cov_table bad val';
}

{
  my $a = pdl '
  0.045 0.682 0.290 0.024 0.598 0.321 0.772 0.375 0.237 0.811;
  0.356 0.094 0.925 0.139 0.701 0.849 0.689 0.109 0.240 0.847;
  0.822 0.492 0.351 0.860 0.400 0.243 0.313 0.011 0.437 0.480
';
  is_pdl $a->corr_table, $a->corr($a->dummy(1)), "Square Pearson correlation table";
  $a->setbadat(4,0);
  is_pdl $a->corr_table, $a->corr($a->dummy(1)), "Square Pearson correlation table with bad data";
}

{
  my $a = pdl([0,1,2,3,4], [0,0,0,0,0]);
  $a = $a->setvaltobad(0);
  ok $a->stdv->nbad, "Bad value input to stdv makes the stdv itself bad";
}

SKIP: {
  eval { require PDL::Core; require PDL::GSL::CDF; };
  skip 'no PDL::GSL::CDF', 1 if $@;
  my $x = pdl(1, 2);
  my $n = pdl(2, 10);
  my $p = .5;
  is_pdl binomial_test( $x,$n,$p ), pdl(0.75, 0.9892578125), 'binomial_test';
}

{
    my $a = sequence 10, 2;
    my $factor = sequence(10) > 4;
    my $ans = pdl( [[0..4], [10..14]], [[5..9], [15..19]] );
    my ($a_, $l) = $a->group_by($factor);
    is_pdl $a_, $ans, 'group_by single factor equal n';
    is_deeply $l, [0, 1], 'group_by single factor label';

    $a = sequence 10,2;
    $factor = qsort sequence(10) % 3;
    $ans = pdl( [1.5, 11.5], [5, 15], [8, 18] );
    is_pdl $a->group_by($factor)->average, $ans, 'group_by single factor unequal n';

    $a = sequence 10;
    my @factors = ( [qw( a a a a b b b b b b )], [qw(0 1 0 1 0 1 0 1 0 1)] );
    $ans = pdl '[ 0 2 BAD; 1 3 BAD ], [ 4 6 8; 5 7 9 ]';
    ($a_, $l) = $a->group_by( @factors );
    is_pdl $a_, $ans, 'group_by multiple factors';
    is_deeply $l, [[qw(a_0 a_1)], [qw( b_0 b_1 )]], 'group_by multiple factors label';
}


{
    my @a = qw(a a b b c c);
    my $a = PDL::Stats::Basic::code_ivs( \@a );
    my $ans = pdl( 0,0,1,1,2,2 );
    is_pdl $a, $ans, 'code_ivs';

    $a[-1] = undef;
    my $a_bad = PDL::Stats::Basic::code_ivs( \@a );
    my $ans_bad = pdl '0 0 1 1 2 BAD';
    is_pdl $a_bad, $ans_bad, 'code_ivs with missing value undef correctly coded';

    $a[-1] = 'BAD';
    $a_bad = PDL::Stats::Basic::code_ivs( \@a );
    is_pdl $a_bad, $ans_bad, 'code_ivs with missing value BAD correctly coded';
}

done_testing();

__DATA__
999	90	91	92	93	94	
70	5	7	-999	-999	-999	
711	trying
71	-999	3	-999	-999	0	
72	2	7	-999	-999	-999	
73	-999	0	-999	-999	2	
74	5	-999	1	0	-999	
75	-999	0	-999	-999	0	
76	9	8	1	5	-999	
77	4	-999	-999	-999	-999	
78	-999	0	-999	-999	0	
79	-999	3	-999	-999	0	
80	-999	0	-999	-999	2	
81	5	-999	1	0	-999	
82	-999	0	-999	-999	0	
