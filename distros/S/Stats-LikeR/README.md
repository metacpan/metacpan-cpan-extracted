# Synopsis

Get basic statistical functions working in Perl as if they were part of List::Util, like `min`, `max`, `sum`, etc.
I've used Artificial Intelligence tools such as Claude, Gemini, and Grok to write this as well as using my own gray matter.
There are other similar tools on CPAN, but I want speed and a form like List::Util, which I've gotten here with the help of AI, which often required many attempts to do correctly.
This is meant to call subroutines directly through eXternal Subroutines (XS) for performance and portability.

There **are** other modules on CPAN that can do **PARTS** of this, but this works the way that I **want** it to.

# Functions/Subroutines

---

## add_data

Add data to an existing hash or array reference. This function acts as the equivalent of adding new rows, as well as an `ljoin` (described below). It dynamically infers your target data structure, handles deeply nested records, and seamlessly coerces mismatched data shapes to preserve the structural integrity of your primary reference.

### Hash of Hashes (HoH)

When the target is a Hash of Hashes, incoming hash keys update existing rows, and new keys create new rows.

    $data = { 'Jack Smith' => { age => 30 } };
    
    $n = { 
        'Jack Smith' => {    # Update existing (Hash)
            dept => 'Engineering'
         },
        'Jane Doe'   => { age => 25, dept => 'Sales' }, # Add new (Hash)
        'Invalid'    => 'Not a reference'               # Edge case safety
    };
    
    add_data($data, $n); 

**Resulting Structure:**

    {
        "Jack Smith":  {
            "age":  30,
            "dept": "Engineering"
        },
        "Jane Doe":    {
            "age":  25,
            "dept": "Sales"
        }
    }

### Hash of Arrays (HoA)

When the target is a Hash of Arrays, incoming arrays are pushed onto the existing arrays, appending the new elements, similarly to R's `rbind`.

    $data = { 'Project Alpha' => [ 'task1', 'task2' ] };
    
    $n = {
        'Project Alpha' => [ 'task3' ],              # Appends to existing array
        'Project Beta'  => [ 'task1', 'task2' ]      # Creates new array row
    };

    add_data($data, $n);

**Resulting Structure:**

    {
        "Project Alpha": [ "task1", "task2", "task3" ],
        "Project Beta":  [ "task1", "task2" ]
    }

### Array of Hashes / Arrays (AoH / AoA)

`add_data` now natively supports Array references at the root level. When targeting an Array, it iterates through the source array and merges data at the corresponding indices.

    $data = [ 
        { id => 1, name => 'Alice' } 
    ];
    
    $n = [ 
        { role => 'Admin' },             # Updates index 0
        { id => 2, name => 'Bob' }       # Creates index 1
    ];

    add_data($data, $n);

**Resulting Structure:**

    [
        { "id": 1, "name": "Alice", "role": "Admin" },
        { "id": 2, "name": "Bob" }
    ]

### Advanced Structural Coercion & Cross-Merging

`add_data` strictly enforces the primary structure of your target reference (determined by inspecting its outer and inner bounds). If you mix Array and Hash types, the function automatically coerces the incoming data to match the target.

**1. Inner Coercion (Mixing Rows):**

* **Target is HoH:** Source Array rows are read in pairs and converted to key-value pairs.
* **Target is HoA:** Source Hash rows are flattened into key-value pairs and pushed onto the array.

**2. Root-Level Coercion (Mixing Outer Containers):**

* **Target is Array, Source is Hash:** The function evaluates the Hash keys as numeric indices. (e.g., source key `"0"` merges into target array index `[0]`). Non-numeric keys are safely ignored.
* **Target is Hash, Source is Array:** The function converts the Array indices into stringified Hash keys. (e.g., source array index `[1]` merges into target hash key `"1"`).

### Source is a mixed Hash. Keys dictate the target array index!
    $n = {
        '0' => { y => 20 },                 # Merges into $data->[0]
        '1' => [ 'z', 30 ],                 # Array pair coerced to Hash, creates $data->[1]
        'ignored' => { k => 'v' }           # Ignored: cannot map to an array index
    };

    add_data($data, $n);

**Resulting Structure strictly remains an Array of Hashes:**

    [
        { "x": 10, "y": 20 },
        { "z": 30 }
    ]


NB: If `add_data` is called on a completely empty target reference (e.g., `$data = {}` or `$data = []`), it will intelligently infer the required inner structure (Hashes vs Arrays) by inspecting the first valid row of the source data.

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
| `data_sv` | `HashRef` or `ArrayRef` | *(Required)* | The dataset to analyze. Accepts a Hash of Arrays (HoA) or Array of Hashes (AoH). If no formula is provided, it must be an HoA to allow automatic stacking (mimicking R's `stack()` on a named list). |
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

## cfilter

Select **columns** out of a table and return it in the same shape. A column is
the inner (second-level) key of a **hash of hashes** or an **array of hashes**,
or the outer key of a **hash of arrays**:

    use Stats::LikeR;
    my %hoa = ( x => [1,2,3], y => [4,5,6], z => [0,0,0] );
    cfilter(\%hoa, keep   => ['x','y']);  # { x => [1,2,3], y => [4,5,6] }
    cfilter(\%hoa, remove => ['z']);      # { x => [1,2,3], y => [4,5,6] }

`cfilter` takes exactly one of `keep` or `remove`. `keep` returns only the
matching columns; `remove` returns everything except them. The result is the
same shape as the input (HoH → HoH, HoA → HoA, AoH → AoH), with cell values
copied and the original structure left untouched.

### Selecting by name

Pass an array ref of column names. Naming a column that is not present in the
data is an error (it catches typos), and a row that happens not to contain a
kept column simply comes back without it:

    my @aoh = ( { a => 1, b => 2 }, { a => 3 } );
    cfilter(\@aoh, keep => ['b']);   # [ { b => 2 }, {} ]

### Selecting by a predicate

Instead of names, `keep`/`remove` accept a **predicate** — a CODE ref or a
function name — evaluated once per column. It is called as

    $predicate->($column_values, $column_name)

where `$column_values` is an array ref of the column's **defined** cells (undef
and missing cells are dropped, so functions like `sd` get clean input).
With `keep`, columns for which the predicate is true are kept; with `remove`,
those columns are dropped.

    # Keep only the constant columns (standard deviation zero):
    my $const = cfilter(\%hoa, keep => sub { sd($_[0]) == 0 });   # { z => [0,0,0] }
    # Drop the constant columns instead:
    my $varying = cfilter(\%hoa, remove => sub { sd($_[0]) == 0 }); # { x=>..., y=>... }
    # A bare function name resolves in Stats::LikeR:: (use a package for your own):
    cfilter(\%hoa, keep => 'some_predicate');

A bare string is always treated as a **function name**, not a single column
name, so to keep one column by name use an array ref: `keep => ['x']`.

### Errors

`cfilter` dies (via `croak`) when:

- neither `keep` nor `remove` is given, or both are,
- a named column is not present in the data,
- the selector is neither an array ref nor a code ref / function name, or the
  function name cannot be resolved,
- an unknown option is given, or the options are not `name => value` pairs,
- the data is not a hash/array reference of the expected shape (a hash of hash
  refs or array refs, or an array of hash refs).

## chisq_test

The `chisq_test` function performs chi-squared contingency table tests and goodness-of-fit tests. It natively accepts both arrays and hashes (1D and 2D) and mathematically mirrors R's `chisq.test()`, returning a structured hash reference of the results.

For 2x2 matrices, Yates' Continuity Correction is applied automatically.

### Accepted Inputs

| Input Type | Data Structure | Applied Test |
| --- | --- | --- |
| **1D Array** | `[ $v1, $v2, ... ]` | Chi-squared test for given probabilities |
| **2D Array** | `[ [ $v1, $v2 ], [ $v3, $v4 ] ]` | Pearson's Chi-squared test (Yates' correction if 2x2) |
| **1D Hash** | `{ key1 => $v1, key2 => $v2 }` | Chi-squared test for given probabilities |
| **2D Hash** | `{ row1 => { c1 => $v1, c2 => $v2 } }` | Pearson's Chi-squared test (Yates' correction if 2x2) |

### Output Object Structure

The function returns a single Hash Reference containing the following key-value pairs. The internal structure of `expected` and `observed` will always identically match the structure of your input.

| Key | Data Type | Description |
| --- | --- | --- |
| **data.name** | String | Identifies the input type (e.g., `"Perl ArrayRef"` or `"Perl HashRef"`). |
| **expected** | Array/Hash Ref | The expected frequencies, matching the geometry of the input. |
| **method** | String | The specific statistical test applied. |
| **observed** | Array/Hash Ref | The original data passed to the function. |
| **p.value** | Float | The calculated p-value of the test. |
| **parameter** | Hash Ref | Contains the degrees of freedom (`df`). |
| **statistic** | Hash Ref | Contains the test statistic (`X-squared`). |

### Two-Dimensional Array

Passing an Array of Arrays (AoA) triggers a standard Pearson's Chi-squared test. If the input is exactly a 2x2 matrix, Yates' continuity correction is applied automatically.

    my $test_data = [
        [762, 327, 468], 
        [484, 239, 477]
    ];
    my $res = chisq_test($test_data);

**Output:**

    {
        'data.name' => 'Perl ArrayRef',
        'expected'  => [
            [ 703.671381936888, 319.645266594124, 533.683351468988 ],
            [ 542.328618063112, 246.354733405876, 411.316648531012 ]
        ],
        'method'    => "Pearson's Chi-squared test",
        'observed'  => [
            [ 762, 327, 468 ],
            [ 484, 239, 477 ]
        ],
        'p.value'   => 2.95358918321176e-07,
        'parameter' => { 'df' => 2 },
        'statistic' => { 'X-squared' => 30.0701490957547 }
    }


### 1-Dimensional Array (Goodness of Fit)

Passing a flat Array Reference triggers a Goodness of Fit test, assuming equal expected probabilities across all items.

    my $data = [10, 20, 30];
    my $res = chisq_test($data);

**Output:**

    {
        'data.name' => 'Perl ArrayRef',
        'expected'  => [ 20, 20, 20 ],
        'method'    => 'Chi-squared test for given probabilities',
        'observed'  => [ 10, 20, 30 ],
        'p.value'   => 0.00673794699908547,
        'parameter' => { 'df' => 2 },
        'statistic' => { 'X-squared' => 10 }
    }

### 2-Dimensional Hash (Pearson's Chi-squared)

Passing a Hash of Hashes (HoH) applies the exact same logic as a 2D Array, but preserves your nested string keys in the output. This is particularly useful when mapping data extracted directly from JSON, databases, or categorical mappings.

    my $data = {
        GroupA => { Success => 10, Failure => 15 },
        GroupB => { Success => 20, Failure => 5  }
    };
    
    my $res = chisq_test($data);

**Output:**

    {
        'data.name' => 'Perl HashRef',
        'expected'  => {
        'GroupA' => { 'Failure' => 10, 'Success' => 15 },
        'GroupB' => { 'Failure' => 10, 'Success' => 15 }
    },
    'method'    => "Pearson's Chi-squared test with Yates' continuity correction",
        'observed'  => {
        'GroupA' => { 'Failure' => 15, 'Success' => 10 },
        'GroupB' => { 'Failure' => 5,  'Success' => 20 }
        },
        'p.value'   => 0.00937475878430379,
        'parameter' => { 'df' => 1 },
        'statistic' => { 'X-squared' => 6.75 }
    }


### One-Dimensional Hash (Goodness of Fit)

Flat Hash References evaluate Goodness of Fit while preserving your categorical keys in the `expected` and `observed` output blocks.


	my $data = { 
		Apples  => 10, 
		Oranges => 20, 
		Bananas => 30 
	};
	
	my $res = chisq_test($data);

# `col2col`

Apply a **two-column function** to every pair of columns in a table and collect
the answers in a hash of hashes.

It's the workhorse behind things like correlation matrices: give it your data and
the name of a function that takes two columns (`cor`, `t_test`, …) and you get
back every column compared against every other column.

    use Stats::LikeR;
    
    my %data = (
        height => [ 170, 165, 180, 175 ],
        weight => [  70,  60,  85,  77 ],
        age    => [  30,  41,  25,  38 ],
    );

    my $result = col2col(\%data, 'cor');
    
    # $result->{height}{weight}  == correlation of height vs weight
    # $result->{height}{age}     == correlation of height vs age
    # ...and so on for every pair

---

## Arguments

    col2col( $data, $command, $cols, %options )
    col2col( $data, $command, \%options )      # options in place of $cols

| Position | Argument    | What it is |
|----------|-------------|------------|
| 1        | `$data`     | Your table, as a reference (see **Data shapes** below). |
| 2        | `$command`  | A code block **or** the name of a two-column function. |
| 3        | `$cols`     | *(optional)* Which columns to use as the "from" side. Omit for all. |
| 4+       | `%options`  | *(optional)* `na`, `skip.errors`, … (see **Options**). |

---

## Data shapes

`col2col` understands three layouts. In every case a **column** is the thing that
gets compared, and the result is keyed by column name.

**Hash of arrays (HoA)** — keys are column names:

    my %hoa = ( a => [1, 2, 3], b => [4, 5, 6] );

**Hash of hashes (HoH)** — First keys are row names, second keys are columns:

    my %hoh = (
        row1 => { a => 1, b => 4 },
        row2 => { a => 2, b => 5 },
    );

**Array of hashes (AoH)** — each element is a row, inner keys are columns:

    my @aoh = ( { a => 1, b => 4 }, { a => 2, b => 5 } );

All three produce the same result for the same underlying numbers. Missing or
`undef` cells are handled by the `na` option (below).

---

## The command

The second argument is the function applied to each pair of columns. It is called
as:

    $command->( $column_a, $column_b )    # two ARRAY refs

so inside a block the two columns arrive in `@_`:

    my $result = col2col(\%data, sub {
        my ($x, $y) = @_;       # $x and $y are array refs
        cor($x, $y);
    });

You can also pass a **function name as a string**. A bare name is looked up in
`Stats::LikeR::`, so these two are equivalent:

    col2col(\%data, 'cor');
    col2col(\%data, sub { cor($_[0], $_[1]) });

---

## The result

Always a hash of hashes: **`$result->{from}{to}`**.

    for my $from (sort keys %$result) {
       for my $to (sort keys %{ $result->{$from} }) {
          printf "%s vs %s = %s\n", $from, $to, $result->{$from}{$to};
       }
    }

A column is never compared with itself, so `$result->{a}{a}` does not exist.

---

## Restricting columns (`$cols`)

By default every column is used as the "from" side. The third argument narrows
that down — handy when you only care about one variable.

    # all columns vs all columns
    my $all = col2col(\%data, 'cor');
    # just ONE column vs every other column
    my $one = col2col(\%data, 'cor', 'height');
    my $cors = $one->{height};          # { weight => ..., age => ... }
    # a FEW specific columns vs every other column
    my $few = col2col(\%data, 'cor', ['height', 'weight']);

The "to" side is always every other column; `$cols` only limits the outer keys.

---

## Options

Options can be given two ways:

    col2col(\%data, 'cor', $cols, 'skip.errors' => 0);   # after $cols
    col2col(\%data, 'cor', { 'skip.errors' => 0 });      # hash ref, no $cols needed

The hash-ref form is convenient when you have **no** column restriction — it saves
you from passing a placeholder. (A hash ref *replaces* `$cols`, so you can't use
it to restrict columns at the same time; use the trailing form for that.)

### `na` — how undefined values are handled

Real data has gaps. `na` decides what the function sees.

| Value                   | Behaviour | Use for |
|-------------------------|-----------|---------|
| `'pairwise'` *(default)*| A row is used for a pair only if **both** columns are defined there. The two columns arrive aligned and equal-length. | Paired stats like `cor`. |
| `'omit'`                | Each column drops **its own** undefined values independently. The two columns may end up **different lengths**. | Unpaired tests like `t_test`, `kruskal_test`, where a gap in one sample shouldn't discard a value in the other. |
| `'keep'`                | Every row is passed through, `undef` and all. | When your function does its own missing-data handling. |

    # correlation: keep only complete pairs (the default)
    col2col(\%data, 'cor');
    # two-sample test: each column keeps its own values
    col2col(\%data, 't_test', undef, na => 'omit');
    col2col(\%data, 't_test', { na => 'omit' });        # same, no placeholder

`rm.undef` / `rm.na` remain as boolean aliases for backward compatibility:
`true` means `'pairwise'`, `false` means `'keep'`. Don't combine them with `na`.

### `skip.errors` — keep going when a pair fails *(default: true)*

Some functions croak on degenerate input — for example `cor` dies if a column has
zero variance. By default `col2col` **traps** that croak per pair: instead of
aborting the whole run, it stores the **first line** of the error message in that
cell, so the result tells you *which* pair failed and *why*. Every other cell is
computed normally.

    my $r = col2col(\%data, 'cor');
    # a good pair:   $r->{a}{b} == 0.83
    # a bad pair:    $r->{a}{const} eq 'cor: standard deviation of y is 0'

To restore the old "die on the first error" behaviour, turn it off:

    col2col(\%data, 'cor', undef, 'skip.errors' => 0);
    col2col(\%data, 'cor', { 'skip.errors' => 0 });

Only errors from **your function** are trapped. Mistakes in the call itself
(unknown column, bad data, unknown function name, unknown option) always die.

---

## Worked examples

**Full correlation matrix:**

    my $m = col2col(\%data, 'cor');

**One variable against all others, sorted strongest first, skipping failures:**

    my $col  = 'Testosterone, total (nmol/L)';
    my $cors = col2col($hoa, 'cor', $col)->{$col};
    for my $other (sort { ($cors->{$b} // -2) <=> ($cors->{$a} // -2) } keys %$cors) {
        next unless $cors->{$other} =~ /^-?\d/;        # skip cells holding an error message
        printf "%-30s % .3f\n", $other, $cors->{$other};
    }

**Two-sample test across columns of unequal completeness:**

    my $t = col2col($hoa, 't_test', undef, na => 'omit');

**Find which pairs could not be computed:**

    my $m = col2col($hoa, 'cor');
    for my $from (sort keys %$m) {
        for my $to (sort keys %{ $m->{$from} }) {
            my $v = $m->{$from}{$to};
            warn "$from vs $to: $v\n" if defined $v && $v !~ /^-?\d/;   # non-numeric = error
        }
    }

---

## Gotchas

- **Your function receives two array refs**, `($col_a, $col_b)` — not a column and
  a name. Unpack with `my ($x, $y) = @_;`.
- **`'pairwise'` can still hit a constant *subset*.** A column with overall
  variance can be flat on just the rows it shares with one partner, so `cor` may
  still croak for that pair. With the default `skip.errors`, that shows up as a
  message in the single offending cell rather than killing the run.
- **`col2col` does not modify your data.** It reads the table and returns a new
  hash of hashes.
- **In the error message, "x" is the first column and "y" is the second** — i.e.
  `y` is the inner ("to") key. So `$result->{A}{B}` reading `…deviation of y is 0`
  means column `B` is the degenerate one for that pair.

## cor

    cor($array1, $array2, $method = 'pearson'),

that is, `pearson` is the default and will be used if `$method` is not specified.

Just like R, `pearson`, `spearman`, and `kendall` are available

If you provide an array of arrays (a matrix), `cor` will compute the correlation matrix automatically. 

## cor_test

    my $result = cor_test(
    		'x'         => $x,
    		'y'         => $y,
    		alternative => 'two.sided',
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

## filter

Return a new data frame containing only the rows of `$df` that match a predicate. The original `$df` is never modified.

    my $df2 = filter($df, col('column.name') > 4);

`filter` accepts a predicate in one of two forms:

1. a **`col()` expression** — a small, composable comparison built with overloaded operators, and
2. a **code reference** — for anything the operators can't express (multiple columns, regexes, arbitrary logic), in the same spirit as the `filter` option of [`read_table`](#).

Both `filter` and `col` are exported by default.

### Arguments

| Position | Name | Description |
| --- | --- | --- |
| 1 | `$df` | The data frame to filter. Either an **array of hashes** (AoH — e.g. the default output of `read_table`) or a **hash of arrays** (HoA). |
| 2 | predicate | Either a `col()` comparison object or a `CODE` reference. |

The return value is a **new** data frame of the **same shape** as the input (AoH in → AoH out, HoA in → HoA out). For an HoA, every column is filtered in parallel by row index, so all returned columns stay the same length and aligned.

### The `col()` form

`col('name')` is a deferred reference to a column. It carries no data — only the column name — so it can be compared with a literal (or another value) to build a predicate that `filter` evaluates once per row.

    filter($df, col('age') >= 18);   # keep rows where age >= 18
    filter($df, col('sex') eq 'f');  # keep rows where sex is 'f'
    filter($df, 18 <= col('age'));   # operands may be in either order

### Comparison operators

| Kind | Operators | Comparison |
| --- | --- | --- |
| Numeric | `>` `<` `>=` `<=` `==` `!=` | numeric (the cell and the value are compared as numbers) |
| String | `gt` `lt` `ge` `le` `eq` `ne` | string (the cell and the value are compared as strings) |

`col('x')` may appear on either side of the operator; `4 < col('x')` is automatically rewritten to the equivalent `col('x') > 4`.

### Combining predicates: `&`, `|`, `!`

Predicates compose with bitwise `&` (and), `|` (or), and `!` (not):

    filter($df, (col('age') > 18) & (col('sex') eq 'f'));   # and
    filter($df, (col('grp') eq 'a') | (col('grp') eq 'c')); # or
    filter($df, !(col('x') > 100));                         # not

Comparison operators bind more tightly than `&` and `|`, so `(col('a') > 4) & (col('b') < 2)` is parsed correctly, but the parentheses are recommended for readability.

### The code-reference form

For logic the operators can't express, pass a `sub`. It is called once per row; the **row is a hash reference**, available both as `$_` and as the first argument `$_[0]`. Return a true value to keep the row.

    filter($df, sub { $_->{x} > 4 && $_->{grp} eq 'a' });
    filter($df, sub { $_->{name} =~ /^A/ });
    filter($df, sub { $_[0]{score} > $_[0]{threshold} });

For an HoA, each row is assembled into a temporary hash reference (`{ column => value, ... }`) before the sub is called, so the same `$_->{column}` syntax works regardless of the input shape.

### Examples

    use Stats::LikeR;
    my $df = read_table('patients.csv');                 # array of hashes
    # numeric threshold
    my $adults = filter($df, col('Age') >= 18);
    # combine conditions
    my $target = filter($df, (col('Age') >= 18) & (col('Sex') eq 'f'));
    # arbitrary logic with a coderef
    my $flagged = filter($df, sub { $_->{ALT} > 40 || $_->{AST} > 40 });
    # hash-of-arrays input -> hash-of-arrays output, columns filtered in parallel
    my $hoa = read_table('patients.csv', 'output.type' => 'hoa');
    my $sub = filter($hoa, col('Age') > 32);
    # $sub->{Age}, $sub->{Sex}, ... are all the same length and row-aligned

### Behavior and notes

- **The input is never modified.** `filter` builds and returns a new frame; `$df` is left untouched.
- **A missing or `undef` cell never matches** a `col()` comparison. For example `col('x') > 0` silently drops any row that has no `x` value or whose `x` is `undef`.
- **AoH rows are shared, not deep-copied**, into the returned frame: the returned array references the *same* row hashes as the input (fast, low-memory). Mutating a row in the result would therefore also change it in the original. HoA values are copied into fresh arrays.
- **Keep-all / keep-none** are well defined: a predicate true for every row returns a copy-shaped frame with all rows; a predicate true for none returns an empty frame (`[]` for AoH, a hash of empty arrays for HoA).
- **Supported shapes are AoH and HoA.** Passing a non-reference, an array element that is not a hash reference, or an HoA column that is not an array reference raises a descriptive error.
- **Perl 5.10 compatible.** The `col()`/operator layer is pure Perl (operator overloading); the per-row evaluation is done in XS.

### See also

`read_table` (whose `filter` option applies the same coderef convention while reading a file), `col2col`.

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
        [0] 2.75343836564204,
        [1] 300.682787419401
    ],
    conf_level    0.95,
    estimate      {
        "odds ratio"   21.3053312750168
    },
    method        "Fisher's Exact Test for Count Data",
    p_value       0.000536724119143435
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
| `summary` | `HashRef` | A nested hash mapping each term to its detailed summary statistics, including `Estimate`, `Std. Error`, `t value` / `z value`, and `Pr(> t )` / `Pr(> z )`. Aliased parameters return `"NaN"`. | `{'wt' => {'Estimate' => -0.5, 'Std. Error' => 0.1, ...}}` |
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

all become hash of arrays:

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
        { 'Race/Hispanic origin w/ NH Asian' => sub { $_ eq $n } },# filter
        { 'Testosterone, total (nmol/L)' => sub { $_ ne 'NA' } } # filter
    );

where each filter filters on the columns, e.g. second hash keys.

## hoh2hoa

Convert a **hash of hashes** (row-major: outer key = row, inner key = column)
into a **hash of arrays** (column-major: key = column, value = that column's
cells down the rows).

    use Stats::LikeR;

    my %hoh = (
        'r1' => { 'a' => 1, 'b' => 2 },
        'r2' => { 'a' => 3, 'b' => 4 },
    );
    
    my $hoa = hoh2hoa(\%hoh);

which returns
    {
      a => [1, 3],
      b => [2, 4],
    }

### Behavior

- **Columns** are the union of every inner key, so a key that appears in only
  some rows still becomes a column.
- **Rows** are emitted in sorted outer-key (row-name) order, and that one order
  is used for every column, so the arrays stay aligned and the result is
  reproducible regardless of hash ordering.
- **Gaps** — a missing inner key, or a cell whose value is `undef` — are filled
  with the fill value (see `undef.val` below). Every column therefore has
  exactly one entry per row.
- Values are **copied** into the result; the original structure is left
  untouched.
- An **empty** hash of hashes returns an empty hash of arrays (it is not an
  error).

### Options

Options are passed as trailing `name => value` pairs.

| Option | Default | Meaning |
| --- | --- | --- |
| `undef.val` | `undef` | Value used to fill a missing key or an `undef` cell. Any defined scalar works, including `0` and `''`. Passing `undef` keeps the default. |
| `row.names` | *(none)* | If set to a string, an extra column of that name is added holding the sorted row labels, aligned with the data. Dies if the name collides with an existing column. |

    # Ragged input with an explicit fill string:
    my %ragged = (
        'r1' => { 'a' => 1, 'b' => 2 },
        'r2' => { 'a' => 3, 'c' => 9 },
    );
    my $hoa = hoh2hoa(\%ragged, 'undef.val' => 'NA');
    # {
    #   a => [1,    3   ],
    #   b => [2,    'NA'],
    #   c => ['NA', 9   ],
    # }
    
    # Keep the row labels as a column:
    my $with_ids = hoh2hoa(\%ragged, 'row.names' => 'id');
    # {
    #   id => ['r1', 'r2'],
    #   a  => [1,    3   ],
    #   b  => [2,    undef],
    #   c  => [undef, 9  ],
    # }

### Errors

`hoh2hoa` dies (via `croak`) when:

- the argument is not a hash reference,
- any value in the hash is not itself a hash reference,
- an unknown option is given, or the options are not `name => value` pairs,
- `row.names` is not a plain string, or it names an already-present column.

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
    $kt = kruskal_test(\%x);

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
    my $kt = kruskal_test(\@x, \@g);

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
| `strict` | Boolean | 0 (False) | Use strict interpretation of two-sided power calculations. |
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

#### Returned Data Structure

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
        scale      0,
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

### options

| Option | Description | Example |
| -------- | ------- | ------- |
|`comment` | Comment character, by default `#` | `comment => %` or whatever; does not apply with header|
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

    my @scaled_results = scale(1..5, { center => false, scale => 1 });

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

### Standard integer sequence

    say 'seq(1, 5):';
    my @seq = seq(1, 5);
    say join(', ', @seq), "\n";

    say 'seq(1, 2, 0.25):';
    @seq = seq(1, 2, 0.25);

### Fractional steps

    say 'seq(1, 2, 0.25):';
    @seq = seq(1, 2, 0.25);
    say join(", ", @seq), "\n";
    for (my $idx = 2; $idx >= 1; $idx -= 0.25) { # count down to pop
    	is_approx(pop @seq, $idx, "seq item $idx with fractional step");
    }

### Negative steps

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

    my $t_test = t_test( $array1, mu => 0.2334 );

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

## transpose

Transposes a two-dimensional data structure, swapping rows and columns. Accepts either an array of arrays or a hash of hashes.
Returns a new reference of the same type; the input is never modified.

### Array of array input

Takes a reference to an array of array references and returns a new AoA where `output[j][i] = input[i][j]`.

    my $matrix = [[1, 2, 3], [4, 5, 6]];
    my $t = transpose($matrix);
    # [[1, 4],
    #  [2, 5],
    #  [3, 6]]

All rows must be the same length; a ragged input is a fatal error.
`undef` is valid as an element value and is preserved exactly. An empty outer array or an array of empty rows both return `[]`.

Dies if:
- any inner element is not an array reference
- rows differ in length (ragged array)

### Hash of hash input

Takes a reference to a hash of hash references and returns a new HoH where `output{col}{row} = input{row}{col}`.

    my $table = { alice => { score => 97, grade => 'A' }, bob   => { score => 84, grade => 'B' } };
    my $t = transpose($table);
    # { score => { alice => 97,  bob => 84  },
    #   grade => { alice => 'A', bob => 'B' } }

Inner keys do not need to be uniform across rows. If a given column key appears in only some rows, the output hash for that column will simply contain only those rows — no padding or `undef`-filling is performed.

    my $sparse = {
    a => { x => 1, y => 2 },
    b => { x => 3, z => 4 } };
    
    my $t = transpose($sparse);
    # { x => { a => 1, b => 3 },
    #   y => { a => 2 },
    #   z => { b => 4 } }

An empty outer hash or an outer hash whose inner hashes are all empty both return `{}`.

Dies if any inner element is not a hash reference

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

It fully supports paired tests (`paired => 1`) and can calculate exact p-values (the default for `N < 50` without ties). If ties are encountered, it automatically switches to an approximation with continuity correction.

## write_table

mimics R's `write.table`, with data as first argument to subroutine, and output file as second

    write_table(\@data_aoh, $tmp_file, sep => "\t", 'row.names' => 1);

You can also precisely filter and reorder which columns are written by passing an array reference to `col.names`:

    write_table(\@data, $tmp_file, sep => "\t", 'col.names' => ['c', 'a']);

undefined variables are printed as `NA` by default, but can be set as you wish using `undef.val`

    write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan')

as of version 0.07, `write_table` determines comma and tab-separated delimiters from the filename, but will override if `sep` or `delim` are explicitly set.

Args can also be accepted:

    write_table( 'data' => \%flat, 'file' => $f );

# changes

## 0.14

`filter` function added for rows

`read_table` reads undefined values to `undef` instead of `NA`, which makes calculations easier

`write_table` writes undef by default as an empty string `''`

`hoh2hoa` transforms a hash of hashes into an hash of arrays

`quantile` uses `NV` instead of `double` to allow for high-precision 128-bit floats to be used on quadmath machines when available: https://www.cpantesters.org/cpan/report/296f4868-631f-11f1-abba-ff15558d240b

Numerous switches from `double` to `NV` for local precision, like above

numerous changes to `col2col` for ease of use and working with datasets with numerous undefined values

dist.ini now links to math library when compiling: https://www.cpantesters.org/cpan/report/785e26d8-6397-11f1-89c0-dc066e8775ea

`fisher_test` now should be complete, errors with confidence intervals fixed

## 0.13

`read_table`: speed improvements; commented headers are now allowed

`write_table`: fix for 

    Attempt to free temp prematurely: SV 0x56417a2ae610 at t/write_table.t line 182.
    	main::wrote_ok(",age\x{a}Alice,30\x{a}Bob,25\x{a}", "row.names => 'name' uses that column as labels", HASH(0x56417a272250), "row.names", "name") called at t/write_table.t line 203
    Attempt to free unreferenced scalar: SV 0x56417a2ae610 at t/write_table.t line 183.
    	main::wrote_ok(",age\x{a}Alice,30\x{a}Bob,25\x{a}", "row.names => 'name' uses that column as labels", HASH(0x56417a272250), "row.names", "name") called at t/write_table.t line 203

`write_table` gives better warnings for incorrect types of data given

Numerous changes to dist.ini to improve CPAN testing, especially for Win32

## 0.12

`add_data` can also take hash of arrays, and various mixes of data types

`ljoin`: Addition of `restrict` keywords in many places; should improve CPU performance

Better POD formatting, correction of output hash for README's `add_data`

`chisq_test` can now accept hash of hashes as input

new `transpose` function for switching 2D hash keys and 2D array indices, and `col2col` for comparing columns against columns

removed unused function from C helpers

`value_counts`: addition of restrict keywords in preinit, should improve CPU performance

MANIFEST.skip changed to MANIFEST.SKIP to improve CPAN testing

using `is_deeply` for tests of `transpose`, which may or may not work with CPAN testers (experimental)

Added function name to warnings, so I actually know which function is producing the error

`write_table` can also take `file` and `data` as args, in addition to positions

fixed `write_table` as it could hang if given empty `col.names` or `row.names`

Added `__EXTENSIONS__` to source XS file for better CPAN testing

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

`write_table` now has `undef.val` option, which shows how undefined values are printed to tables, which is `NA` by default.

