# Synopsis

Get basic statistical functions working in Perl as if they were part of List::Util, like `min`, `max`, `sum`, etc.
I've used Artificial Intelligence tools such as Claude, Gemini, and Grok to write this as well as using my own gray matter.
There are other similar tools on CPAN, but I want speed and a form like List::Util, which I've gotten here with the help of AI, which often required many attempts to do correctly.
This is meant to call subroutines directly through eXternal Subroutines (XS) for performance and portability.

There **are** other modules on CPAN that can do **PARTS** of this, but this works the way that I **want** it to.

# Functions/Subroutines

## add_data

Add data to a hash

    $data = { 'Jack Smith' => { age => 30 } };
    $n = { 
        'Jack Smith' => { dept => 'Engineering' },             # Update existing (Hash)
        'Jane Doe'   => { age => 25, dept => 'Sales' },        # Add new (Hash)
        'Bob Brown'  => [ 'age', 40, 'dept', 'IT' ],           # Add new (Array)
        'Invalid'    => 'Not a reference'                      # Edge case safety
    };
    add_data($data, $n); # will add data to 'Jack Smith', as well as new keys for Jane and Bob.

this is the equivalent of adding new rows, as well as `ljoin`, which is described below.

where the resulting hash-of-hash looks like:

    {
        1st   {
            a   "A",
            b   "B"
        },
        2nd   {
            a   "C",
            b   "D"
        }
    }

### no pivot key/row name

with no pivot key, each array index becomes a hash key, which is less useful, but necessary for completeness.  The same `@aoh` above becomes:

    {
        0   {
            a   "A",
            b   "B",
            r   "1st" (dualvar: 1)
        },
        1   {
            a   "C",
            b   "D",
            r   "2nd" (dualvar: 2)
        }
    }

## aov

Warning: assumes normal distribution

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

### Input Parameters

| Parameter | Type | Default | Description | Example |
| --- | --- | --- | --- | --- |
| `data_sv` | `HashRef` | `ArrayRef` | *(Required)* | The dataset to analyze. Accepts a Hash of Arrays (HoA) or Array of Hashes (AoH). If no formula is provided, it must be an HoA to allow automatic stacking (mimicking R's `stack()` on a named list). |
| `formula_sv` | `String` | `undef` | A symbolic description of the model to be fitted. If omitted, the formula automatically defaults to `'Value ~ Group'` and the input data is stacked. | `'yield ~ N * P'` |

### Output Variables

The function returns a single `HashRef` containing the evaluated statistical results. Because the keys map dynamically to the terms parsed from your formula, the structure will vary based on your inputs.

| Parameter | Type | Default | Description | Example |
| --- | --- | --- | --- | --- |
| *(Term Name)* | `HashRef` | `undef` | A nested hash for each independent term in the formula (e.g., `'Group'`, `'N:P'`), containing its ANOVA table statistics. | `{'Df' => 1, 'Sum Sq' => 14.2, 'Mean Sq' => 14.2, 'F value' => 25.81, 'Pr(>F)' => 0.0004}` |
| `Residuals` | `HashRef` | `undef` | A nested hash containing the residual (error) statistics for the fitted model. | `{'Df' => 10, 'Sum Sq' => 5.5, 'Mean Sq' => 0.55}` |
| `group_stats` | `HashRef` | `undef` | A nested hash containing descriptive statistics (`mean` and `size` / count) for every column evaluated in the original unstacked data structure. | `{'mean' => {'A' => 2.1, 'B' => 5.4}, 'size' => {'A' => 10, 'B' => 10}}` |

### omitting formula

As of version 0.07, in the case of an omitted formula, stacking is done:

    aov(
    {
        yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
        ctrl  => [1,     1,   1,   0,   0,   0]
    },
    );

is the equivalent of:

    yield <- c(5.5, 5.4, 5.8, 4.5, 4.8, 4.2)
    ctrl <- c(1,     1,   1,   0,   0,   0)
    
    # Combine them into a named list (the R equivalent of your hash)
    my_list <- list(yield = yield, ctrl = ctrl)
    
    # Convert the list into a "long" dataframe
    # This creates two columns: "values" and "ind" (the group name)
    my_data <- stack(my_list)

    # Rename columns for clarity (optional but good practice)
    colnames(my_data) <- c("Value", "Group")
    anova_model <- aov(Value ~ Group, data = my_data)
    summary(anova_model)

in R

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

## dnorm

gives the density of the normal distribution, with the specified mean and standard deviation.

In other words, the predicted height of the value `x`, given a mean, standard deviation, and whether or not to use a log value.

returns a single scalar/number if a single value is given, otherwise returns an array reference.

Usage:

    dnorm(4) # assumes a mean of 0 and standard deviation of 1

but default mean, standard deviation, and log can be passed as parameters:

    $x = dnorm(0, mean => 0, sd => 2, 'log' => 0);

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

In addition to the `gaussian` default, it fully supports logistic regression using the `binomial` family parameter via Iteratively Reweighted Least Squares (IRLS):

    my $glm_bin = glm(formula => 'am ~ wt + hp', data => \%mtcars, family => 'binomial');

### Input Parameters

| Parameter | Type | Default | Description | Example |
| --- | --- | --- | --- | --- |
| `formula` | `String` | *None (Required)* | A symbolic description of the model to be fitted. Supports operators like `+`, `:`, `*`, `^`, and `-1` (to remove the intercept). | `'am ~ wt + hp'`, `'y ~ x - 1'` |
| `data` | `HashRef` or `ArrayRef` | *None (Required)* | The dataset containing the variables used in the formula. Accepts either a Hash of Arrays (HoA) or an Array of Hashes (AoH). | `\%mtcars`, `[{x => 1, y => 2}, ...]` |
| `family` | `String` | `'gaussian'` | A description of the error distribution and link function to be used in the model. Currently supports `'gaussian'` (identity link) and `'binomial'` (logit link). | `'binomial'` |

### Output variables

| Variable | Type | Description | Example |
| --- | --- | --- | --- |
| `aic` | `Double` | Akaike's Information Criterion for the fitted model. | `123.45` |
| `boundary` | `Integer (Boolean)` | `1` if the fitted values computationally reached the `0` or `1` boundary (specific to the binomial family), `0` otherwise. | `0` |
| `coefficients` | `HashRef` | A hash mapping the expanded model term names to their estimated coefficient values. | `{'Intercept' => 1.5, 'wt' => -0.5}` |
| `converged` | `Integer (Boolean)` | `1` if the Iteratively Reweighted Least Squares (IRLS) algorithm converged within the maximum iterations, `0` otherwise. | `1` |
| `deviance` | `Double` | The residual deviance of the fitted model. | `15.2` |
| `deviance.resid` | `HashRef` | A hash mapping data row names to their computed deviance residuals. | `{'Mazda RX4' => 0.12}` |
| `df.null` | `Integer` | The residual degrees of freedom for the null model. | `31` |
| `df.residual` | `Integer` | The residual degrees of freedom for the fitted model. | `30` |
| `family` | `String` | The statistical family used to fit the model. | `"gaussian"` |
| `fitted.values` | `HashRef` | A hash mapping data row names to the fitted mean values (the model's predictions on the scale of the response). | `{'Mazda RX4' => 0.85}` |
| `iter` | `Integer` | The number of IRLS iterations performed before convergence or hitting the iteration limit. | `4` |
| `null.deviance` | `Double` | The deviance for the null model (a baseline model containing only an intercept, or an offset of 0 if the intercept is removed). | `43.5` |
| `rank` | `Integer` | The numeric rank of the fitted linear model (the number of estimated, non-aliased parameters). | `2` |
| `summary` | `HashRef` | A nested hash mapping each term to its detailed summary statistics, including `Estimate`, `Std. Error`, `t value` / `z value`, and `Pr(>|t|)` / `Pr(>|z|)`. Aliased parameters return `"NaN"`. | `{'wt' => {'Estimate' => -0.5, 'Std. Error' => 0.1, ...}}` |
| `terms` | `ArrayRef` | An ordered list of the expanded term names included in the model matrix. | `['Intercept', 'wt', 'hp']` |

## group_by

Take a hash of arrays, hash of hashes, or array of hashes, and group a column by another column.

    my $aoh_data = [
        { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
        { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
        { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
        { 'Gender' => 'Female' } # Intentional missing target value
    ];

as well as

    $hoh_data = {
        'Patient_A' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
        'Patient_B' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
        'Patient_C' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
        'Patient_D' => { 'Gender' => 'Female' }, # Intentional missing target value
        'Patient_E' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => undef } # Explicit undef
        };

and

    my $hoa_data = {
        'Gender'                       => ['Male', 'Female', 'Male', 'Female'],
        'Testosterone, total (nmol/L)' => [22.1,   2.5,      19.4,   undef   ]
    };

then run the function thus:

    group_by( $hoa_data, 'Testosterone, total (nmol/L)', 'Gender');

The output can be thought of like a hash, with the first string broken down by the second.

all become the hash of arrays:

    {
        Female   [
            [0] 1.8
        ],
        Male     [
            [0] 18.2,
            [1] 20.5
        ]
    }

returns an empty array of hashes if neither target nor group keys are found.

### Filtering

Data can be further broken down with filter/subs like in `read_table`:

    my $testosterone = group_by($d, # group testosterone by "Gender"
        'Testosterone, total (nmol/L)',
        'Gender',
        { 'Race/Hispanic origin w/ NH Asian' => sub { $_ eq $n } },
        { 'Testosterone, total (nmol/L)' => sub { $_ ne 'NA' } } # filter
    );

where each filter filters on the columns, e.g. second hash keys.

## hist

Computes the histogram of the given data values, operating in single $O(N)$ pass performance. It returns the bin counts, computed breaks, midpoints, and density. 

    my $res = hist([1, 2, 2, 3, 3, 3, 4, 4, 5], breaks => 4);

If `breaks` is not explicitly provided, it defaults to calculating the number of bins using Sturges' formula.

## kruskal_test

Essentially the test determines if all groups have the same median (same distribution) (an excellent review is at https://library.virginia.edu/data/articles/getting-started-with-the-kruskal-wallis-test)

Performs a Kruskal-Wallis rank sum test, see 
https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/kruskal.test

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

## ks_test

The Kolmogorov-Smirnov test, which tests whether or not two arrays/lists of data are part of the same distribution is implemented simply:

    $ks = ks_test(\@x, \@y, alternative => 'greater');

returning a hash reference.

Also, a single array can be tested against a normal distribution:

    $ks = ks_test($ksx, 'pnorm');

The p-value precision is about 1e-8, which I want to improve, but am not sure how.

## ljoin

Consider a hash: `$h{$row}{$col}`, and another hash `$i{$row}{$col}`.
`ljoin` will add information for `$col` in `%i` for each `$row` to `%h`, where `$row` exists in both `%h` and `%i`

For example,

    {
    "Jack Smith"   {
        age   30
    }
    }

and a second hash,
    {
        "Jack Smith"   {
            dept   "Engineering"
        },
        "Jane Doe"     {
            age   25
        }
    }

in this case, running `ljoin(\%h, \%i)` will modify \%h to result:

    {
    "Jack Smith"   {
        age    30,
        dept   "Engineering"
    }
    }

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

As of version 0.10, parameters do not need to be named, so that `matrix` works more like R:

    my $d = matrix(rnorm(32000), 1000, 32);

works as `data`, `nrow`, and `ncol`

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

## mode

Takes either an array or an array reference, and returns an array of the most common scalars (numbers or strings)

    @arr = mode([1,3,3,3]); # returns (3)

    @arr = mode('a','a','c','c','z'); # returns ('a', 'c')

## oneway_test

Like ANOVA/aov but does not assume normality

### hash of array input

    $test_data = oneway_test({
    	yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
    	ctrl  => [1,     1,   1,   0,   0,   0]
    });

which will output a hash reference:

    {
    Group         {
        Df          1,
        "F value"   177.504798464491,
        "Mean Sq"   61.6533333333333,
        Pr(>F)      1.31343255160843e-07,
        "Sum Sq"    61.6533333333333
    },
    group_stats   {
        mean   {
            ctrl    0.5,
            yield   5.03333333333333
        },
        size   {
            ctrl    6,
            yield   6
        }
    },
    Residuals     {
        Df          9.81767348326473,
        "Mean Sq"   0.353783749200256,
        "Sum Sq"    3.47333333333333
    }
}

### array of array input

    oneway_test([
       [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
       [1,     1,   1,   0,   0,   0]
    	]);

which will output a nearly identical hash reference as for hash of arrays:

    {
    Group         {
        Df          1,
        "F value"   177.504798464491,
        "Mean Sq"   61.6533333333333,
        Pr(>F)      1.31343255160843e-07,
        "Sum Sq"    61.6533333333333
    },
    group_stats   {
        mean   {
            "Index 0"   5.03333333333333,
            "Index 1"   0.5
        },
        size   {
            "Index 0"   6,
            "Index 1"   6
        }
    },
    Residuals     {
        Df          9.81767348326473,
        "Mean Sq"   0.353783749200256,
        "Sum Sq"    3.47333333333333
    }
    }


## p_adjust

Returns array of false-discovery-rate-corrected p-values, where methods available are "holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr"

    my @q = p_adjust(\@pvalues, $method);

## power_t_test

    $test_data = power_t_test(
    	n	=> 30,	delta     => 0.5, 
    	sd	=> 1.0, sig_level => 0.05
    );

It also allows configuring the test type (`type => 'one.sample'`, `'two.sample'`, `'paired'`) and alternative hypothesis (`alternative => 'one.sided'`). You can also pass `strict => 1` to strictly evaluate both tails of the distribution.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `n` | Float | `undef` | Number of observations (per group for two-sample, pairs for paired). |
| `delta` | Float | `undef` | True difference in means. |
| `sd` | Float | 1.0 | Standard deviation. |
| `sig_level` | Float | 0.05 | Significance level (Type I error probability). Also accepts `sig.level`. |
| `power` | Float | `undef` | Power of test (1 minus Type II error probability). |
| `type` | String | `"two.sample"` | Type of t-test: `"two.sample"`, `"one.sample"`, or `"paired"`. |
| `alternative` | String | `"two.sided"` | One- or two-sided test: `"two.sided"`, `"one.sided"`, `"greater"`, or `"less"`. |
| `strict` | Boolean | `FALSE` | Use strict interpretation of two-sided power calculations. |
| `tol` | Float | ~`1.22e-4` | Numerical tolerance used for the internal root-finding algorithm. |

## prcomp

Principal Component Analysis

### Options

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `center` | Boolean | `1` (True) | If true, the variables are shifted to be zero-centered before the analysis takes place. |
| `scale` | Boolean | `0` (False) | If true, the variables are scaled to have unit variance before the analysis takes place. *Note: If a column has zero variance, the function will `croak` to prevent division by zero.* |
| `retx` | Boolean | `1` (True) | If true, the rotated data (the original data multiplied by the rotation matrix) is returned under the key `x`. |
| `tol` | Number | `undef` | A value indicating the magnitude below which components should be omitted. Components are omitted if their standard deviation is less than or equal to `tol` times the standard deviation of the first component. |
| `rank` | Integer | `undef` | Optionally specify a strict limit on the number of principal components to return. The function will return `min(rank, rows, columns)` components. |

### Results

### Returned Data Structure

The `prcomp` function returns a HashRef containing the following keys representing the results of the Principal Component Analysis:

| Key | Type | Description |
| :--- | :--- | :--- |
| `sdev` | ArrayRef[Number] | The standard deviations of the principal components. Mathematically, these are the square roots of the eigenvalues of the covariance matrix. |
| `rotation` | ArrayRef[ArrayRef] | A 2D array representing the matrix of variable loadings (the eigenvectors). Each inner array represents a row, and the columns correspond to the principal components. |
| `x` | ArrayRef[ArrayRef] | A 2D array containing the rotated data (often referred to as PCA scores). This is the original data projected onto the principal components. *Note: Only present if the `retx` option is true.* |
| `center` | ArrayRef[Number] or `0` | The centering values used (typically the column means). Returns false (`0`) if centering was disabled. |
| `scale` | ArrayRef[Number] or `0` | The scaling values used (typically the column standard deviations). Returns false (`0`) if scaling was disabled. |
| `varnames` | ArrayRef[String] | The sorted names of the original variables. *Note: Only present if the input data was a Hash of Arrays (HoA) or a Hash of Hashes (HoH).* |

### Using array of arrays

    my $aoa = [ 
        [2, 4], 
        [4, 2], 
        [6, 6] 
    ];
    
    my $pca = prcomp($aoa);

which returns

    {
        center     [
            [0] 4,
            [1] 4
        ],
        rotation   [
            [0] [
                    [0] 0.707106781186547,
                    [1] 0.707106781186548
                ],
            [1] [
                    [0] 0.707106781186548,
                    [1] -0.707106781186547
                ]
        ],
        scale      false,
        sdev       [
            [0] 2.44948974278318,
            [1] 1.4142135623731
        ],
        x          [
            [0] [
                    [0] -1.41421356237309,
                    [1] -1.4142135623731
                ],
            [1] [
                    [0] -1.4142135623731,
                    [1] 1.41421356237309
                ],
            [2] [
                    [0] 2.82842712474619,
                    [1] 2.22044604925031e-16
                ]
        ]
    }

### Hash of Arrays

    my $hoa = { B => [4, 2, 6], A => [2, 4, 6] };
    my $pca = prcomp($hoa);

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

## options

| Option | Description | Example |
| -------- | ------- | ------- |
`comment` | Comment character, by default `#` | `comment = %` or whatever|
|`output.type`| data type for output: array of hash, hash of array, or hash of hash | `'output.type' => 'aoh'`|
|`filter`| Only take in rows with a certain filter | `filter => {	Sex => sub {$_ eq 'f'} }`|
|`row.names` | include row names in retrieved data; off by default | |
|`sep` | field separator character; synonym with `delim`| `sep => "\t"` |
| `delim`| field separator character; synonym with `sep`| `delim => "\t"` |

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

the default delimiter is `,`
Suffixes `.csv` and `.tsv` are automatically detected from file names, but if specified, are overridden by `delim` and/or `sep`. `sep` is given priority.

## rnorm

Make a normal distribution of numbers, with pre-set mean `mean`, standard deviation `sd`, and number `n`.

    my ($rmean, $sd, $n) = (10, 2, 9999);
    my $normals = rnorm( n => $n, mean => $rmean, sd => $sd);

## runif

Make an approximately uniform distribution into an array

### named arguments

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

which passing a reference is shorter and much easier to read.  Stats::LikeR, however, will work for **both**

as of version 0.02, `sum` will cause the script to die if any undefined values are provided

## summary

Analogous to R's `summary`, but does not deal with outputs from other functions.
`summary` only describes data as it is entered.
An option `nrows` or its synonym `nrow` specifies the maximum number of rows that will print.

### array of array input

    my @arr;
    foreach my $i (0..18) {
    	push @arr, runif(22);
    }

and then `summary(\@arr)`, or `summary(@arr)`

    ---------------------------------------------------------------------------
    Index  # values      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
    ---------------------------------------------------------------------------
         0       22   0.04312     0.286    0.4975    0.5121    0.7296    0.9633 
         1       22   0.05932    0.1483     0.495    0.4737    0.7699    0.9371 
         2       22   0.02742    0.1588    0.4045    0.4325    0.6682    0.9878 
         3       22  0.009233    0.2552    0.5398    0.5147    0.7755    0.9808 
         4       22   0.06727    0.2432    0.5019    0.4855    0.7121    0.9043 
         5       22  0.001032    0.1646    0.3021    0.3727    0.5704    0.9556 

### hash of array input

    $test_data = summary(
    	{
    		A => runif(9),
    		B => runif(9)
    	},
    );


## t_test

There are 1-sample and 2-sample t-tests, from one or two arrays:

    my $t_test = t_test( $array1, mu => mean( 0.2334 ));

or 2-sample:

    $t_test = t_test(
    	$array1,	$array2,
	    paired => 1
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
    	'x' => $array1, 'y' => $array2,
	    paired => 1
    );

### Parameters

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `x` | Array Reference | Required | The first vector of data. Must contain at least 2 elements. |
| `y` | Array Reference | `undef` | The second vector of data. Required for two-sample or paired tests. |
| `mu` | Float | 0.0 | The true value of the mean (or difference in means) for the null hypothesis. |
| `paired` | Boolean | `FALSE` | If true, performs a paired t-test. `x` and `y` must be the same length. |
| `var_equal` | Boolean | `FALSE` | If true, assumes equal variances (standard two-sample). If false, performs Welch's t-test with unequal variances. |
| `conf_level` | Float | 0.95 | Confidence level for the returned confidence interval. Must be between 0 and 1. |
| `alternative` | String | `"two.sided"` | Direction of the alternative hypothesis: `"two.sided"`, `"less"`, or `"greater"`. |

### Return Hash

| Key | Description |
| :--- | :--- |
| `statistic` | The computed t-statistic. |
| `df` | Degrees of freedom for the test. |
| `p_value` | The calculated p-value based on the test directionality. |
| `conf_int` | An Array Reference containing two elements: `[lower_bound, upper_bound]`. |
| `estimate` | The estimated mean of `x` (one-sample) OR the mean of the differences (paired). |
| `estimate_x` | The estimated mean of the `x` vector (only returned in two-sample tests). |
| `estimate_y` | The estimated mean of the `y` vector (only returned in two-sample tests). |

## value_counts

Count the values in a given data set, return a hash reference showing how many times each particular value is present.

### Scalar

    $hash = value_counts('c');

returns `{ c => 1 }`

### Array reference

    value_counts(['a','b','b']);

returns `{ a => 1, b => 2}`

### Array

    my $value_counts = value_counts('a','b','b');

like an array reference above, returns `{ a => 1, b => 2}`

### Hash

    my $value_counts = value_counts( { A => 'a', B => 'a', C => 'b' } );

returns `{ a => 2, b => 1}`

### Hash of array

    my $value_counts = value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']});

without a key (like above), the occurences of `j`, `t`, and `v` are counted.

With a key, like `a` for above, only values within that hash key are counted:

    my $vc = value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']}, 'a');

### Hash of hash (table)

    $hash = value_counts( {
        A => {
            a => 'x',
            b => 'z'
        },
        B => {
            a => 'x'
        },
        C => {
	        a => 'y'
        }
    }, 'a');

the column, or second hash key, that you wish to count, is specified at the command line

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

    my @x = (2.9, 3.0, 2.5, 2.6, 3.2);
    my @y = (3.8, 2.7, 4.0, 2.4);

    my $vt = var_test(\@x, \@y);

also, conf_level can be set:

    $vt = var_test(\@x, \@y, conf_level => 0.99);

as well as a ratio (from R: the hypothesized ratio of the population variances of `x` and `y`:

    $test_data = var_test(\@xk, \@yk, ratio => 2);

## wilcox_test

    $test_data = wilcox_test(
    	[1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
    	[0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
    );

It fully supports paired tests (`paired => true`) and can calculate exact p-values (the default for `N < 50` without ties). If ties are encountered, it automatically switches to an approximation with continuity correction.

## write_table

mimics R's `write.table`, with data as first argument to subroutine, and output file as second

    write_table(\@data_aoh, $tmp_file, sep => "\t", 'row.names' => true);

You can also precisely filter and reorder which columns are written by passing an array reference to `col.names`:

    write_table(\@data, $tmp_file, sep => "\t", 'col.names' => ['c', 'a']);

undefined variables are printed as `NA` by default, but can be set as you wish using `undef.val`

    write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan')

as of version 0.07, `write_table` determines comma and tab-separated delimiters from the filename, but will override if `sep` or `delim` are explicitly set.

# changes

## 0.11

better POD formatting for tables

addition of MANIFEST.skip to get better testing results on CPAN

`glm`: bugfix for when there is no intercept in the formula, new test cases in t/glm.t

`write_table` now accepts simple hashes as input, in addition to hash of arrays, hash of hashes, and arrays of hashes

Better documentation for t-test

## 0.10

changes to compilation for CPAN, trying to get this work on Windows

Addition of `prcomp` and `value_counts`

`matrix` will work without key names, just like in R.  Testing for `matrix` has improved.

## 0.09

context changes in XS `dTHX`, `pTHX_`, and `aTHX_` to get better CPAN testing results

`restrict` keywords added to `lm` to increase speed

## 0.08

Speed improvement in `summary` of hashes.

Addition of `add_data`, `dnorm`, `group_by`, `ljoin`, and `mode` functions

Chi-squared function no longer has Perl wrapper, and all code is in XS, which should result in a minor speed increase with 1 less function call.

Compiler changes for GNU source and inclusion of `strings.h`, to ensure more CPAN testing works better.

`read_table` now returns hash-of-hash in {row}{column}

## 0.07

Addition of `summary` function.

Formulas can now be omitted from `aov`, resulting in a stacked calculation as R would think.

Addition of `oneway_test` for multi-group comparisons that does not assume normality like `aov` does.

`read_table` and `write_table` now automatically set separators for `.csv` files as `,` and `.tsv` files as `"\t"`, respectively, so these values no longer need to be specified separately from the file name.

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

