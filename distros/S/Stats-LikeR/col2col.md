## col2col

    my $result = col2col( $data, $command );

Compares **every column against every other column** in a dataset and returns a
hash of hashes:

    $result->{ $col_a }{ $col_b }   # outcome of comparing column A with column B

The diagonal is skipped (a column is never compared with itself), so each inner
hash holds an entry for every *other* column.

`$data` may be given in any of three shapes — *array of hashes*, *hash of
arrays*, or *hash of hashes* — and `col2col` detects which one it received.

`$command` is either:

- a **string** naming a `Stats::LikeR` function (`"cor"`, `"cov"`, `"cor_test"`,
  `"t_test"`, `"ks_test"`, `"wilcox_test"`, `"var_test"`, `"kruskal_test"`, …).
  A name containing `::` is used verbatim; otherwise `Stats::LikeR::` is
  prepended. Each pair is passed as `$fn->( \@col_a, \@col_b )` and whatever the
  function returns is stored verbatim.
- a **code ref** for a custom analysis, also called as `$sub->( \@col_a, \@col_b )`.

**Undefined values are always removed**, but how depends on the command:

| Command | Removal | Effect |
| --- | --- | --- |
| `cor`, `cov`, `cor_test` | **pairwise** (complete cases) | rows where *either* column is undef/non-numeric are dropped, so the two vectors stay the same length — as correlation and covariance require |
| everything else, and all code refs | **per column** | each column is cleaned independently, giving two independent samples — the natural input for two-sample tests |

---

### array of hash input

Row-major: an array ref whose elements are hash refs (`$data->[$row]{$col}`).
Column names are the union of the keys seen across all rows.

    my $rows = [
        { height => 170, weight => 65, age => 31 },
        { height => 182, weight => 84, age => 45 },
        { height => 168, weight => 60, age => 29 },
        { height => 191, weight => 92, age => 52 },
        { height => 175, weight => 71, age => 38 },
    ];

    my $cor = col2col( $rows, 'cor' );

    print $cor->{height}{weight}, "\n";   # Pearson r between height and weight
    print $cor->{weight}{age},    "\n";

---

### hash of array input

Column-major: a hash ref whose values are array refs (`$data->{$col}[$row]`).
The keys are the column names. This is the most direct shape — each value is
already a column.

    my $data = {
        height => [ 170, 182, 168, 191, 175 ],
        weight => [  65,  84,  60,  92,  71 ],
        age    => [  31,  45,  29,  52,  38 ],
    };
    my $cov = col2col( $data, 'cov' );
    print $cov->{height}{weight}, "\n";   # sample covariance

Undefined entries are skipped. For `cor`/`cov`/`cor_test` they are dropped
pairwise, so the pair below is compared on its three complete rows only:

    my $data = {
        a => [ 1,      2,     3,  4,  5 ],
        b => [ 2,  undef,     6,  8, 10 ],   # row 1 dropped for any pair touching b
    };

    my $cor = col2col( $data, 'cor' );
    print $cor->{a}{b}, "\n";              # correlation over rows 0,2,3,4

---

### hash of hash input

Row-major and keyed: a hash ref whose values are hash refs
(`$data->{$row}{$col}`). The outer keys label the rows (e.g. sample IDs); the
inner keys are the column names (the union across all rows).

    my $samples = {
        s1 => { height => 170, weight => 65, age => 31 },
        s2 => { height => 182, weight => 84, age => 45 },
        s3 => { height => 168, weight => 60, age => 29 },
        s4 => { height => 191, weight => 92, age => 52 },
        s5 => { height => 175, weight => 71, age => 38 },
    };

    my $cor = col2col( $samples, 'cor' );
    print $cor->{age}{weight}, "\n";

Because pairing is done within each row, the (unordered) row-key order does not
affect the result — all three shapes above give the same numbers.

---

### Examples with different `Stats::LikeR` functions

The same dataset can be run through any comparison function just by changing the
command. Using the hash-of-arrays `$data` from above:

```perl
# Correlation coefficients (Pearson) — returns a number per pair
my $r = col2col( $data, 'cor' );
print $r->{height}{weight}, "\n";

# Covariance — returns a number per pair
my $c = col2col( $data, 'cov' );

# Correlation test — returns whatever Stats::LikeR::cor_test returns
# (e.g. estimate, statistic, p_value) for each pair
my $ct = col2col( $data, 'cor_test' );
print $ct->{height}{weight}{p_value}, "\n";

# Welch two-sample t-test between every pair of columns
my $t = col2col( $data, 't_test' );
print $t->{height}{age}{p_value}, "\n";

# Two-sample Kolmogorov–Smirnov test
my $ks = col2col( $data, 'ks_test' );
print $ks->{height}{age}{statistic}, "\n";

# Other two-sample comparisons dispatch the same way
my $w  = col2col( $data, 'wilcox_test' );    # Wilcoxon rank-sum
my $f  = col2col( $data, 'var_test'    );    # F test for equal variances
my $kw = col2col( $data, 'kruskal_test');    # Kruskal–Wallis
```

#### Custom subroutine

Pass a code ref to run any analysis you like. It receives the two columns as
array refs (cleaned per column) and its return value is stored verbatim.

```perl
# Mean difference between every pair of columns
my $diff = col2col( $data, sub {
    my ( $x, $y ) = @_;
    my $mx = 0; $mx += $_ for @$x; $mx /= @$x;
    my $my = 0; $my += $_ for @$y; $my /= @$y;
    return $mx - $my;
} );

print $diff->{height}{weight}, "\n";

# Wrap a built-in to pass extra options (e.g. a non-default correlation method)
my $spearman = col2col( $data, sub {
    return Stats::LikeR::cor( $_[0], $_[1], method => 'spearman' );
} );
```
