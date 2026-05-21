# Synopsis

Get basic R statistical functions working in Perl as if they were part of List::Util, like `min`, `max`, `sum`, etc.
I've used Artificial Intelligence tools such as Claude, Gemini, and Grok to write this as well as using my own gray matter.
There are other similar tools on CPAN, but I want speed and a form like List::Util, which I've gotten here with the help of AI, which often required many attempts to do correctly.
This is meant to call subroutines directly through eXternal Subroutines (XS) for performance and portability.

There **are** other modules on CPAN that can do **PARTS** of this, but this works the way that I **want** it to.

# Functions/Subroutines

## aov

    aov(
    {
        yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
        ctrl  => [1,     1,   1,   0,   0,   0]
    },
    'yield ~ ctrl');

which returns

    {
        ctrl        {
            Df          1,
            "F value"   25.6000000000001,
            "Mean Sq"   1.70666666666667,
            Pr(>F)      0.00718232855871859,
            "Sum Sq"    1.70666666666667
        },
        Residuals   {
            Df          4,
            "Mean Sq"   0.0666666666666665,
            "Sum Sq"    0.266666666666666
       }
    }

You can also perform Two-Way ANOVA with categorical interactions using the `*` operator. The parser will implicitly evaluate the main effects alongside the interaction:

    my $res_2way = aov($data_2way, 'len ~ supp * dose');

It is robust against rank deficiency; collinear terms will gracefully receive 0 degrees of freedom and 0 sum of squares, matching R's behavior.

## chisq_test

    my @test_data = ([762, 327, 468], [484, 239, 477]);
    my $test_data = chisq_test(\@test_data);

which outputs:

    {
    data.name   "Perl ArrayRef",
    expected    [
        [0] [
                [0] 703.671381936888,
                [1] 319.645266594124,
                [2] 533.683351468988
            ],
        [1] [
                [0] 542.328618063112,
                [1] 246.354733405876,
                [2] 411.316648531012
            ]
    ],
    method      "Pearson's Chi-squared test",
    observed    [
        [0] [
                [0] 762,
                [1] 327,
                [2] 468
            ],
        [1] [
                [0] 484,
                [1] 239,
                [2] 477
            ]
    ],
    p.value     2.95358918321176e-07,
    parameter   {
        df   2
    },
    statistic   {
        X-squared   30.0701490957547
    }
    }

It also supports 1D arrays for Goodness of Fit tests:

    my $chisq_1d = chisq_test([10, 20, 30]);

For 2x2 matrices, Yates' Continuity Correction is applied automatically, exactly like in R.

## cor

    cor($array1, $array2, $method = 'pearson'),

that is, `pearson` is the default and will be used if `$method` is not specified.

Just like R, `pearson`, `spearman`, and `kendall` are available

If you provide an array of arrays (a matrix), `cor` will compute the correlation matrix automatically. 

## cor_test

    my $result = cor_test(
    		'x'         => $x,
    		'y'         => $y,
    		alternative => 'two.sided'
    		method      => 'pearson',
    		continuity  => 1
    	);

`cor_test` safely handles `undef` (or `NA`) values seamlessly by computing over pairwise complete observations. 

## cov

    cov($array1, $array2, 'pearson')

or

    cov($array1, $array2, 'spearman')

or

    cov($array1, $array2, 'kendall')

## fisher_test

### array reference entry

    my $array_data = [
    	[10, 2],
    	[3, 15]
    ];
    my $res1 = fisher_test($array_data);

which returns a hash reference:

    {
    alternative   "two.sided",
    conf_int      [
        [0] 2.75338278824932,
        [1] 301.462337971516
    ],
    estimate      {
        "odds ratio"   21.3053175567504
    },
    method        "Fisher's Exact Test for Count Data",
    p_value       0.00053672411914343
    }

### hash reference entry

    $ft = fisher_test( {
        Guess => {
            Milk => 3, Tea => 1
        },
        Truth => {
            Milk => 1, Tea => 3
        }
    });

I have the p-value calculated very precisely, but there are some inexactness (approximately 1% for the confidence intervals) which I couldn't rectify.  The answers are very close to R besides the p-value, where they are identical.

## glm

takes a hash of an array as input

    my %tooth_growth = (
    	dose => [qw(0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0
    1.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5
    0.5 0.5 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0
    2.0 2.0 2.0)],
    	len  => [qw(4.2 11.5  7.3  5.8  6.4 10.0 11.2 11.2  5.2  7.0 16.5 16.5 15.2 17.3 22.5
    17.3 13.6 14.5 18.8 15.5 23.6 18.5 33.9 25.5 26.4 32.5 26.7 21.5 23.3 29.5
    15.2 21.5 17.6  9.7 14.5 10.0  8.2  9.4 16.5  9.7 19.7 23.3 23.6 26.4 20.0
    25.2 25.8 21.2 14.5 27.3 25.5 26.4 22.4 24.5 24.8 30.9 26.4 27.3 29.4 23.0)],
    	supp => [qw(VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC
    VC VC VC VC VC OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ
    OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ)]
    );

    my $glm_teeth = glm(
    	data    => \%tooth_growth,
    	formula => 'len ~ dose + supp',
    	family  => 'gaussian'
    );

I'm not completely confident that this is working perfectly, though I've gotten this subroutine to work for simple cases.

In addition to the `gaussian` default, it fully supports logistic regression using the `binomial` family parameter via Iteratively Reweighted Least Squares (IRLS):

    my $glm_bin = glm(formula => 'am ~ wt + hp', data => \%mtcars, family => 'binomial');

## hist

Computes the histogram of the given data values, operating in single $O(N)$ pass performance. It returns the bin counts, computed breaks, midpoints, and density. 

    my $res = hist([1, 2, 2, 3, 3, 3, 4, 4, 5], breaks => 4);

If `breaks` is not explicitly provided, it defaults to calculating the number of bins using Sturges' formula.

## kruskal_test

Essentially the test determines if all groups have the same median (same distribution) (an excellent review is at https://library.virginia.edu/data/articles/getting-started-with-the-kruskal-wallis-test)

Performs a Kruskal-Wallis rank sum test, see 
https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/kruskal.test

### R-like array entry

    my @xk = (2.9, 3.0, 2.5, 2.6, 3.2); # normal subjects
    my @yk = (3.8, 2.7, 4.0, 2.4);      # with obstructive airway disease
    my @zk = (2.8, 3.4, 3.7, 2.2, 2.0); # with asbestosis
    my @x = (@xk, @yk, @zk);
    my @g = (
    	(map {'Normal subjects'} 0..4),
    	(map {'Subjects with obstructive airway disease'} 0..3),
    	map {'Subjects with asbestosis'} 0..4
    );
    my $t0 = Time::HiRes::time();
    my $kt = kruskal_test(\@x, \@g);
    my $t1 = Time::HiRes::time();
    printf("Kruskal calculation in %g seconds.\n", $t1-$t0);
    p $kt;

### hash of array entry

I feel that this is better, and more easily read, than what you get in R:

    my %x = (
    'normal.subjects' => [2.9, 3.0, 2.5, 2.6, 3.2],
    'obs. airway disease' => [3.8, 2.7, 4.0, 2.4],
    'asbestosis' => [2.8, 3.4, 3.7, 2.2, 2.0]
    );
    $t0 = Time::HiRes::time();
    $kt = kruskal_test(\%x);
    $t1 = Time::HiRes::time();
    printf("Kruskal calculation via HoA in %g seconds.\n", $t1-$t0);
    p $kt;

## ks_test

The Kolmogorov-Smirnov test, which tests whether or not two arrays/lists of data are part of the same distribution is implemented simply:

    $ks = ks_test(\@x, \@y, alternative => 'greater');

returning a hash reference.

Also, a single array can be tested against a normal distribution:

    $ks = ks_test($ksx, 'pnorm');

The p-value precision is about 1e-8, which I want to improve, but am not sure how.

## lm

This is the linear models function.

    $lm = lm(formula =>  'mpg ~ wt + hp', data => $mtcars);

where `$mtcars` is a hash of hashes

`lm` also supports generating interaction terms directly within the formula using the `*` operator:

    my $lm = lm(formula => 'mpg ~ wt * hp^2', data => \%mtcars);

If your data contains missing numbers (`NA` or `undef`), `lm` handles listwise deletion dynamically to ensure mathematical integrity before fitting.

the dot operator also works:

    $lm = lm(formula => 'y ~ .', data => $dot_data);

## matrix

    my $mat1 = matrix(
    	data => [1..6],
    	nrow => 2
    );

You can also pass `byrow => 1` if you want the matrix populated row-wise instead of column-wise.

## max

    max(1,2,3);
    
or

    my @arr = 1..8;
    max(@arr, 4, 5)

as of version 0.02, max will die if any undefined values are provided

## mean

    mean(1,2,3);
    
or

    my @arr = 1..8;
    mean(@arr, 4, 5)

or

    mean([1,1], [2,2]) # 1.5

as of version 0.02, mean will die if any undefined values are provided

## median

works like mean, taking array references and arrays:

    median( $test_data[$i][0] )

as of version 0.02, median will die if any undefined values are provided

## min

    min(1,2,3);
    
or

    my @arr = 1..8;
    min(@arr, 4, 5)

as of version 0.02, min will die if any undefined values are provided

## p_adjust

Returns array of false-discovery-rate-corrected p-values, where methods available are "holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr"

    my @q = p_adjust(\@pvalues, $method);

## power_t_test

    $test_data = power_t_test(
    	n	=> 30,	delta     => 0.5, 
    	sd	=> 1.0, sig_level => 0.05
    );

It also allows configuring the test type (`type => 'one.sample'`, `'two.sample'`, `'paired'`) and alternative hypothesis (`alternative => 'one.sided'`). You can also pass `strict => 1` to strictly evaluate both tails of the distribution.

## quantile

Calculates sample quantiles using R's continuous Type 7 interpolation. 

    my $quantile = quantile('x' => [1..99], probs => [0.05, 0.1, 0.25]);

If the `probs` parameter is omitted, it behaves identically to R by defaulting to the 0, 25, 50, 75, and 100 percentiles (`c(0, .25, .5, .75, 1)`). The returned hash keys match R's standardized naming convention (e.g., `"25%"`, `"33.3%"`).

## rbinom

Create a binomial distribution of numbers

    my $binom = rbinom( n => $n, prob => 0.5, size => 9);

It hooks directly into Perl's internal PRNG system, respecting `srand()` seeds. 

## read_table

I've tried to make this as simple as possible, trying to follow from R:

    my $test_data = read_table('t/HepatitisCdata.csv');

output types can be AOH (aoa), HOA (hoa), HOH (hoh)

    read_table($filename, 'output.type' => 'aoh');

    read_table($filename, 'output.type' => 'hoa');

and, like Text::CSV_XS, filters can be applied in order to save RAM on big files:

    $test_data = read_table(
        't/HepatitisCdata.csv',
        filter => {
            Sex => sub {$_ eq 'f'} # where "Sex" is the column name, and "$_" is the value for that column
        },
        'output.type' => 'aoh'
    );

## rnorm

Make a normal distribution of numbers, with pre-set mean `mean`, standard deviation `sd`, and number `n`.

    my ($rmean, $sd, $n) = (10, 2, 9999);
    my $normals = rnorm( n => $n, mean => $rmean, sd => $sd);

## runif

### named arguments

Make a distribution of approximately uniform distribution

    my $unif = runif( n => $n, min => 0, max => 1);

where `n` is the number of items, the values are between `min` and `max`

### positional args

this is to match R's behavior:

    runif( 9 )

will make 9 numbers in [0,1]

    runif(9, 0, 99)

will match `n`, `min`, and `max` respectively

## sample

take a sample of hash or array slices.

    my $h = sample(\%h, 4); # take 4 hash keys and their values into $h

or, alternatively, with arrays:

    my $arr = sample(\@arr, 3); # take 3 indices of an array

## scale

    my @scaled_results = scale(1..5);

You can also pass an options hash to disable centering or scaling:

    my @scaled_results = scale(1..5, { center => false, scale => true });

It fully supports matrix operations. By passing an array of arrays, `scale` processes the data column by column independently:

    my $scaled_mat = scale([[1, 2], [3, 4], [5, 6]]);

## sd

    my $stdev = sd(2,4,4,4,5,5,7,9);

Correct answer is 2.1380899352994

`sd` can accept both array references as well as arrays:

    my $stdev = sd([2,4,4,4,5,5,7,9]);

As of version 0.02, sd will croak/die if any undefined values are provided.

## seq

Works as closely as I can to R's seq, which is very similar to Perl's `for` loops.  Returns an array, not an array reference.

### Example 1: Standard integer sequence

    say 'seq(1, 5):';
    my @seq = seq(1, 5);
    say join(', ', @seq), "\n";

    say 'seq(1, 2, 0.25):';
    @seq = seq(1, 2, 0.25);

### Example 2: Fractional steps

    say 'seq(1, 2, 0.25):';
    @seq = seq(1, 2, 0.25);
    say join(", ", @seq), "\n";
    for (my $idx = 2; $idx >= 1; $idx -= 0.25) { # count down to pop
    	is_approx(pop @seq, $idx, "seq item $idx with fractional step");
    }

### Example 3: Negative steps

    say 'seq(10, 5, -1):';
    @seq = seq(10, 5, -1);
    say join(", ", @seq), "\n";
    for (my $idx = 5; $idx <= 10; $idx++) { # count down to pop
        is_approx(pop @seq, $idx, "seq item $idx with negative step");
    }

## shapiro_test

tests to see if an array reference is normally distributed, returns a p-value and a statistic

    my $shapiro = shapiro_test(
    	[1..5]
    );

and returns the hash reference:

    {
    p.value     0.589650577093106,
    p_value     0.589650577093106,
    statistic   0.960870680168535,
    W           0.960870680168535
    }

## sum

returns sum, but using both arrays and array references.

    my $test_data = [1..8];
    sum($test_data)

which I prefer, compared to List::Util's required casting into an array:

    sum(@{ $test_data });

which is shorter and much easier to read

as of version 0.02, `sum` will cause the script to die if any undefined values are provided

## t_test

There are 1-sample and 2-sample t-tests:

    my $t_test = t_test( $test_data[$i][$j], mu => mean( $test_data[$i][$j] ));

or 2-sample:

    $t_test = t_test(
    	$test_data[3][0],
    	$test_data[3][1],
	    paired => true
    );

returns a hash reference, which looks like:

    conf_int     => [
        -0.06672889, 0.25672889
    ],
    df        => 5,
    estimate  => 0.095,
    p_value   => 0.19143688433660,
    statistic => 1.50996688705414

the two groups compared can be specified, though not necessarily, as `x` and `y`, just like in R:

    $t_test = t_test(
    	'x' => test_data[3][0],
    	'y' => $test_data[3][1],
	    paired => true
    );

## var

as simple as possible:

    var(2, 4, 5, 8, 9)

as of version 0.02, `var` will die if any undefined values are provided

like `min`, `max`, etc., `var` can accept array references, to make code simpler:

    my $ref = \@arr;
    var($ref) = var(@arr)

## var_test

As described by R: Performs an F test to compare the variances of two samples from normal populations

    use Stats::LikeR;
    use Time::HiRes;

    my @x = (2.9, 3.0, 2.5, 2.6, 3.2);
    my @y = (3.8, 2.7, 4.0, 2.4);
    my @z = (2.8, 3.4, 3.7, 2.2, 2.0);

    my $t0 = Time::HiRes::time();
    my $vt = var_test(\@x, \@y);
    my $t1 = Time::HiRes::time();
    printf("var_tests in %g seconds.\n", $t1-$t0);

also, conf_level can be set:

    $vt = var_test(\@xk, \@yk, conf_level => 0.99);

as well as a ratio (from R: the hypothesized ratio of the population variances of `x` and `y`:

    $test_data = var_test(\@xk, \@yk, ratio => 2);

## wilcox_test

    $test_data = wilcox_test(
    	[1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
    	[0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
    );

It fully supports paired tests (`paired => true`) and can calculate exact p-values (the default for `N < 50` without ties). If ties are encountered, it automatically switches to an approximation with continuity correction.

## write_table

mimics R's "write.table", with data as first argument to subroutine, and output file as second

    write_table(\@data_aoh, $tmp_file, sep => "\t", 'row.names' => true);

You can also precisely filter and reorder which columns are written by passing an array reference to `col.names`:

    write_table(\@data, $tmp_file, sep => "\t", 'col.names' => ['c', 'a']);

undefined variables are printed as `NA` by default, but can be set as you wish using `undef.val`

    write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan')

# changes

## 0.06

Changed compiler options so that Solaris will work

signed integers changed to unsigned in `glm`

Added restrict keywords to `power_t_test`, and made `int` to `unsigned int`

## 0.05

Leak testing for `sample`

removal of Data::Printer dependency for easier CPAN testing

switched several `unsigned int` variable to `I32` so that clang doesn't complain

added restrict keyword for `sample`

## 0.04

addition of `sample` function

GNU source, to maximize compatibility and ease installation

removal of JSON dependency to ease installation

## 0.03

Compatibility back to Perl 5.10

## 0.02

back-compatible to Perl 5.10, instead of original 5.40, ensuring more people can use it

added var_test

mean, min, sum, median, var, and max die with undefined values, and print the offending indices

"group_stats" added to aov, for TukeyHSD in the future

"cor" dies when given data with standard deviation of 0

var_test added

`write_table` now has `undef.val` option, which shows how undefined values are printed to tables, which is `NA` by default.

