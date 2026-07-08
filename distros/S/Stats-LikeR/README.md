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
        'Project Alpha' => [ 'task3' ],         # Appends to existing array
        'Project Beta'  => [ 'task1', 'task2' ] # Creates new array row
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

## agg

Split-apply-combine over a data frame: split the rows into groups, apply one or
more aggregators to chosen columns, and combine the results into a new frame.
This is the *combine* half that `group_by` (which only splits) leaves to you,
and the analog of pandas `df.groupby(...).agg(...)`. With no `by` it collapses
the whole frame to a single row, like pandas `df.agg(...)`.

`agg` accepts all four data-frame shapes and, by default, returns the same shape
it was given:

    AoA  [ [ .. ], [ .. ] ]      array of arrayrefs   (positional columns)
    AoH  [ { .. }, { .. } ]      array of hashrefs    (the read_table default)
    HoA  { c => [ .. ], .. }     hash of arrayrefs    (column-major)
    HoH  { r => { .. }, .. }     hash of hashrefs     (named rows)

For AoA the column identifiers in `by` and in the `agg` spec are integer
positions; for the other three shapes they are column names. The original frame
is never modified.

### Usage

    use Stats::LikeR;

    # grouped, one aggregator per column
    my $out = agg($df, by => 'sex', agg => { wt => 'mean' });

    # grouped, several aggregators, several columns
    my $out = agg($df,
        by  => 'sex',
        agg => { wt => [ 'mean', 'sd' ], age => [ 'mean', 'count' ] },
    );

    # ungrouped: the whole frame becomes one row
    my $out = agg($df, agg => { wt => 'mean', age => 'count' });

    # group on two columns and emit a hash of hashes
    my $out = agg($df,
        by            => [ 'a', 'b' ],
        agg           => { v => 'sum' },
        'output.type' => 'hoh',
    );

### Arguments

`agg` takes the data frame first, then `name => value` pairs.

- **agg** (required) — a hashref mapping each column to an aggregator
  *spec*. A spec is one of: a single aggregator name (string), an arrayref of
  names, or a coderef. See [Aggregators](#aggregators) below.
- **by** — a single column or an arrayref of columns to group on. Omit it to
  aggregate the entire frame into one row.
- **skipna** — `1` (default) drops undef cells before a numeric aggregator
  runs. `0` makes any undef in a group poison the numeric result for that group
  (the cell comes back undef), matching pandas `skipna=False`. `count`, `n`,
  `nunique`, `first`, and `last` ignore this flag.
- **sort** — `1` (default) sorts the output groups by key (numerically when
  every key looks like a number, otherwise as strings); `0` keeps first-seen
  order.
- **output.type** — `aoa`, `aoh`, `hoa`, or `hoh`. Defaults to the same family
  as the input frame.

### Aggregators

Named aggregators may be combined in any order per column:

| name      | result                                                      |
|-----------|-------------------------------------------------------------|
| `mean`    | arithmetic mean (needs ≥ 1 defined cell, else undef)        |
| `median`  | median (needs ≥ 1)                                          |
| `sum`     | sum (needs ≥ 1)                                             |
| `sd`      | sample standard deviation (needs ≥ 2, else undef)           |
| `var`     | sample variance (needs ≥ 2, else undef)                     |
| `min`     | minimum (needs ≥ 1)                                          |
| `max`     | maximum (needs ≥ 1)                                          |
| `count`   | number of *defined* cells                                   |
| `n`       | number of cells, undef included                             |
| `nunique` | number of distinct defined cells                            |
| `first`   | first defined cell (undef if none)                          |
| `last`    | last defined cell (undef if none)                           |
| `mode`    | modal defined cell; ties broken deterministically           |

The numeric aggregators call the module's XS functions of the same name, so they
inherit their precision. `agg` filters undef itself before calling them, so they
never croak on missing cells. `mode` is made deterministic: on a tie it returns
the smallest number, or the lowest string when the values are not numeric.

A **coderef** may be supplied instead of a name for full control. It is called
once per group as `$code->(\@cells)`, where `@cells` are every cell for that
column in the group **including undef**, and must return a single scalar:

    # count the missing values in each group
    my $out = agg($df, by => 'sex', agg => {
        age => sub {
            my $cells = shift;
            scalar grep { !defined } @$cells;
        },
    });

### Output shape and column naming

Output columns are laid out deterministically: the `by` columns first, in the
order given, then the aggregated columns sorted (numerically for AoA integer
columns, otherwise as strings), each expanded over its aggregator list in the
order supplied.

A column reduced by a **single** aggregator keeps its own name; reduced by
**two or more** it becomes `<col>_<func>`:

    my $df = [
        { sex => 'M', wt => 70, age => 30    },
        { sex => 'F', wt => 60, age => 25    },
        { sex => 'M', wt => 80, age => 40    },
        { sex => 'F', wt => 55, age => undef },
    ];

    my $out = agg($df,
        by  => 'sex',
        agg => { wt => [ 'mean', 'sd' ], age => [ 'mean', 'count' ] },
    );

**Resulting Structure** (AoH in, AoH out):

    [
        {
            sex       => 'F',
            wt_mean   => 57.5,
            wt_sd     => 3.53553390593274,
            age_mean  => 25,     # the undef age was skipped
            age_count => 1,      # count excludes the undef
        },
        {
            sex       => 'M',
            wt_mean   => 75,
            wt_sd     => 7.07106781186548,
            age_mean  => 35,
            age_count => 2,
        },
    ]

### Ungrouped

Without `by`, the frame collapses to one row:

    my $out = agg($df, agg => { wt => 'mean', age => 'count' });

    # [ { wt => 66.25, age => 3 } ]

### Array of Arrays (AoA)

Columns are integer positions. Grouping on column 0 and reducing column 1:

    my $aoa = [ [ 'M', 70 ], [ 'F', 60 ], [ 'M', 80 ] ];
    my $out = agg($aoa, by => 0, agg => { 1 => [ 'mean', 'max' ] });

    # [ [ 'F', 60, 60 ], [ 'M', 75, 80 ] ]
    #     ^grp  ^mean ^max

The output row is positional: the `by` columns first, then each aggregated
column in the plan order.

### Hash of Hashes (HoH) output

With `output.type => 'hoh'` the row label is the group value; multiple `by`
columns are joined with a dot, an ungrouped result is keyed `all`, and a
collision is made unique with a `.N` suffix.

    my $out = agg($df, by => 'sex', agg => { wt => 'mean' }, 'output.type' => 'hoh');

    # {
    #     F => { sex => 'F', wt => 57.5 },
    #     M => { sex => 'M', wt => 75   },
    # }

### Missing values

By default (`skipna => 1`) undef cells are removed before a numeric aggregator
runs, so a group of `(60, 55)` with a third undef still yields the mean of the
two defined values. `count` reports only defined cells while `n` counts undef
too. With `skipna => 0`, a group containing any undef returns undef for the
numeric aggregators (`mean median sum sd var mode`); the counting and
positional aggregators are unaffected.

A group without enough data yields undef rather than an error: `sd` and `var`
need at least two defined cells, the other numeric aggregators need at least
one.

### Errors

`agg` dies (with a trailing newline, so the message prints cleanly) when:

- the first argument is not an ARRAY or HASH ref;
- no `agg` spec is given, or it is not a non-empty hashref;
- an unknown option is passed;
- an aggregator name is not recognized;
- an aggregator list for a column is empty;
- `output.type` is not one of `aoa`, `aoh`, `hoa`, `hoh`;
- the trailing arguments are not `name => value` pairs.

### See also

`group_by` (the split step), `concat` / `rbind` (row-binding frames),
`dropna`, `assign`, `value_counts`.

## anova

Sequential (Type-I) ANOVA table for a linear model, in the same shape `aov`
returns. `anova` fits `response ~ terms`, then decomposes the model sum of
squares one term at a time, **in formula order**, and F-tests each term
against the residual mean square.

    anova(
    {
        yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
        ctrl  => [1,     1,   1,   0,   0,   0]
    },
    'yield ~ ctrl');

returns

    {
        ctrl        {
            Df          1,
            "F value"   25.6000000000001,
            "Mean Sq"   1.70666666666667,
            "Pr(>F)"    0.00718232855871859,
            "Sum Sq"    1.70666666666667
        },
        Residuals   {
            Df          4,
            "Mean Sq"   0.0666666666666665,
            "Sum Sq"    0.266666666666666
        }
    }

Two-way (and higher) models use the `*` operator, which implicitly evaluates
the main effects alongside the interaction (`a * b` expands to `a + b + a:b`;
`a * b * c` to the full factorial `a + b + c + a:b + a:c + b:c + a:b:c`):

    my $res_2way = anova($data_2way, 'len ~ supp * dose');

Bare string columns are treated as factors and treatment-coded (first level =
reference); numeric columns and `I(x^2)` enter as single regressors. It is
robust against rank deficiency: collinear terms gracefully receive 0 degrees
of freedom and 0 sum of squares, matching R's behavior.

### Input Parameters
| Parameter | Type | Default | Description | Example |
| --- | --- | --- | --- | --- |
| `data_sv` | `HashRef` or `ArrayRef` | *(Required)* | The dataset. A Hash of Arrays (HoA, columns) or Array of Hashes (AoH, rows) — the same forms `aov`/`lm` accept. |
| `formula_sv` | `String` | *(Required)* | Symbolic model `'response ~ rhs'`, with `+`, `:` and `*`. Unlike `aov`, `anova` does **not** auto-stack, so a formula is mandatory. | `'yield ~ N * P'` |

### Output Variables
A single `HashRef`; keys are the parsed term names, so the structure varies
with the formula.
| Parameter | Type | Description | Example |
| --- | --- | --- | --- |
| *(Term Name)* | `HashRef` | ANOVA-table stats for each term (`'ctrl'`, `'N:P'`, …). `'Mean Sq'`, `'F value'` and `'Pr(>F)'` are omitted for 0-df (aliased) terms. | `{'Df'=>1,'Sum Sq'=>14.2,'Mean Sq'=>14.2,'F value'=>25.81,'Pr(>F)'=>0.0004}` |
| `Residuals` | `HashRef` | Residual (error) statistics; never carries an F test. | `{'Df'=>10,'Sum Sq'=>5.5,'Mean Sq'=>0.55}` |

### `anova` vs `aov` — what's the difference?

For a **single model they compute the identical Type-I table** — in R,
`anova(lm(f))` and `summary(aov(f))` return the same sums of squares, and the
same holds here (`anova(\%d,'yield ~ ctrl')` reproduces the `aov` table
above exactly). The difference is one of role, not arithmetic:

- **`aov` is the model-*fitting* idiom for designed experiments.** It leans
  toward factors and balanced designs, and in this module it adds two
  conveniences `anova` deliberately leaves out: it can **auto-stack** a named
  list when you omit the formula (R's `stack()` + `Value ~ Group`), and it
  returns a `group_stats` block of per-group means and counts alongside the
  table. Reach for `aov` when your question is "do these treatment groups
  differ, and what do the groups look like?"

- **`anova` is the model-*table* idiom.** It always wants an explicit formula
  and returns just the decomposition — nothing descriptive. Reach for it when
  you already have a model in mind and only want its term-by-term SS /
  F-tests, or when you want the leaner object to feed onward.

In short: same numbers for one model; `aov` is the richer "fit + describe"
call (and the only one that stacks), `anova` is the minimal "give me the
table" call. Note that both are **Type-I / sequential**, so term order in the
formula matters, and both share this module's `pf`, so p-values agree with
`oneway_test` and the rest of Stats::LikeR.

*(R's `anova` generic can additionally compare several nested models,
`anova(m1, m2)`, giving an F/LRT between them — a capability neither this
`anova` nor `aov` currently provides. Ask if that would be useful.)*

## aoh2hoa

`aoh2hoa($aoh)` — transpose an **array-of-hashes** (row-major) into a **hash-of-arrays** (column-major).

    my $hoa = aoh2hoa([ { a => 1, b => 2 }, { a => 3 } ]);
    # $hoa = { a => [1, 3], b => [2, undef] }

Rows go in, columns come out: each distinct key across the input rows becomes one output column, and the values are gathered down that column in row order.

### Arguments

`$aoh` — an array ref of hash refs, one hash per row. This is the only argument, and it is required. Passing anything that is not an array ref is fatal:

    aoh2hoa({ a => 1 });   # dies: argument must be an arrayref of hashrefs

### Returns

A hash ref of array refs. Each key is a column name (the union of all keys seen across the rows); each value is an array ref holding that column's cells. Every column has exactly `scalar @$aoh` elements, so the result is rectangular even when the input is ragged.

### Behavior

The column set is the **union** of every row's keys — a key that appears in only some rows still produces a full-length column, with `undef` in the rows that lacked it.

Each column is padded to exactly the row count. Cells missing from a given row come through as `undef`, including trailing gaps (a column whose last contributing row is early still runs the full length). These absent cells are cheap holes in the array, not stored SVs.

Values are **copied** (`newSVsv`), so the returned structure is independent of the input — mutating `$aoh` afterward won't disturb the result. The copy is shallow: a value that is itself a reference is copied the same way `$col->[$i] = $row->{$k}` would, i.e. the ref is duplicated but its referent is shared.

Keys are handled SV-first (`hv_iterkeysv` / `hv_fetch_ent`), so UTF-8 and otherwise non-trivial hash keys round-trip correctly.

A row that is **not** a hash ref is skipped rather than fatal: it contributes `undef` to every column at its index. So a stray `undef` or scalar in the input thins the columns at that position instead of dying.

### Notes

The output column order follows hash iteration order and is therefore not guaranteed — sort the keys if you need a stable layout. Round-tripping through `hoa2aoh` (or the reverse) reconstructs the data but not necessarily the original key/row ordering, and rows originally absent a key will gain it as an explicit `undef`.

## `aoh2hoh`

Index an **A**rray-**o**f-**H**ashes into a **H**ash-**o**f-**H**ashes, keyed by the value of one column.

    my $hoh = aoh2hoh($aoh, $key);

Where `aoh2hoa` *transposes* rows into columns, `aoh2hoh` *indexes* rows by a chosen field, turning a sequential list into a lookup table. The chosen field is treated as a **primary key**: it must be unique across the rows, and a repeat is fatal.

### Signature

| Argument | Type        | Meaning                                              |
|----------|-------------|------------------------------------------------------|
| `$aoh`   | arrayref    | The rows: an arrayref of hashrefs.                   |
| `$key`   | scalar      | The column name whose value indexes each row.        |

Returns a hashref. Each top-level key is a row's `$row->{$key}` value; each value is a shallow copy of that row.

    my $rows = [
        { id => 'p1', kd => 12.4, chain => 'A' },
        { id => 'p2', kd =>  3.1, chain => 'B' },
    ];

    my $by_id = aoh2hoh($rows, 'id');
    # {
    #   p1 => { id => 'p1', kd => 12.4, chain => 'A' },
    #   p2 => { id => 'p2', kd =>  3.1, chain => 'B' },
    # }

    $by_id->{p2}{kd};   # 3.1 -- O(1) lookup instead of a linear scan

### Semantics

These choices are the parts most worth keeping in mind, because the AoH->HoH mapping is ambiguous where a transpose is not.

**Duplicate keys are fatal.** If two rows share the same key value, the call dies rather than silently dropping a row:

    aoh2hoh([ { id => 'a', x => 1 }, { id => 'a', x => 9 } ], 'id');
    # dies: aoh2hoh: duplicate key 'a' has >= 2 occurrences

This makes the chosen column an enforced primary key: the result is only returned if every row maps to a distinct bucket. If your data legitimately has repeats and you want to *keep* them, you want a hash-of-arrays-of-rows instead -- a different return shape. If you want last-wins or first-wins collapse, dedup the input before calling.

**The key column is retained** inside each inner hash (the copy is of the whole row). Drop it deliberately if you don't want the redundancy.

**Shallow copy.** Inner hashes are fresh, so adding or removing keys on the output never touches the input. But a *value* that is itself a reference is shared, exactly like `$out{$rk}{$_} = $row->{$_}`:

    my $shared = [ 1, 2, 3 ];
    my $out = aoh2hoh([ { id => 'a', data => $shared } ], 'id');
    push @{ $out->{a}{data} }, 4;   # $shared now has 4 elements too

A row that is not a hashref, or that lacks a defined value at `$key`, is fatal.

**Numeric vs string keys collide.** Hash keys are strings, so `1` and `"1"` map to the same bucket and therefore trip the duplicate-key die. Normalize the key column first if a row could carry both forms.

### Use cases

**Join / enrichment lookups.** Build an index once, then attach fields from one dataset onto another by shared id without an O(n*m) nested loop -- and the duplicate-key die guarantees the join side really is keyed uniquely:

    my $meta = aoh2hoh($pdb_metadata, 'pdb_id');
    for my $hit (@$results) {
        $hit->{resolution} = $meta->{ $hit->{pdb_id} }{resolution};
    }

**Primary-key validation.** Because a repeat is fatal, the call doubles as an assertion that a column is unique -- a cheap way to catch a malformed table (duplicate accession, duplicate peptide id) at load time rather than downstream.

**Random-access reshaping of tabular data.** After parsing a CSV/TSV into an array of row-hashes, re-index by a primary key so downstream code can fetch a row by name rather than scanning. Pairs naturally with the CSV-parsing side of the toolkit.

**Set membership and difference.** `exists $hoh->{$k}` gives a cheap presence test, useful for asking which ids in one table are missing from another.

### Relationship to `aoh2hoa`

| Function   | Output shape           | Indexed by      | Typical question it answers              |
|------------|------------------------|-----------------|------------------------------------------|
| `aoh2hoa`  | hash of arrayrefs      | column name     | "give me every value in column X"        |
| `aoh2hoh`  | hash of hashrefs       | a row's key val | "give me the whole row whose id is Y"    |

Reach for `aoh2hoa` when you want columns (vectors to feed a statistic or a plot); reach for `aoh2hoh` when you want addressable rows keyed by a unique field.

### Implementation note

The operation is a single pass over the rows with one hash insert per row -- the same asymptotics in pure Perl as in XS, and Perl's hash operations are already C underneath. There is no meaningful speed or memory advantage to an XS implementation here, so pure Perl is preferred unless it must live in the same `.xs` for packaging parity. The duplicate check is a single `exists` per row and does not change that. (An XS version would `croak` on the duplicate before allocating the second copy, so there is no extra cleanup to manage.)

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

## assign
Add new columns to a data frame, computed from the columns already there — or handed in ready-made.

### Usage
    assign($df, new_name => VALUE, another => VALUE, ...);

- **`$df`** — your data frame, in any of three shapes:
  - **AoH** — arrayref of row hashrefs: `[ {weight=>70, height=>1.75}, ... ]`
  - **HoA** — hashref of column arrayrefs: `{ weight=>[70,...], height=>[1.75,...] }`
  - **HoH** — hashref of row hashrefs, keyed by row name: `{ Alice=>{weight=>65}, ... }`
- **`new_name => VALUE`** — one or more pairs. `VALUE` is either a **coderef** (computed) or an **arrayref** (a ready-made column).

It changes `$df` in place and also returns it (handy for chaining).

### Coderef values
A coderef is classified by what it returns in list context:

- **One scalar → per-row.** The sub is called once per row and that scalar is the cell.
  - `$_` (and `$_[0]`) is the current row as a hashref, so you read other columns with `$_->{colname}`.
  - `$_[1]` is the row's index (0-based).
  - `$_[2]` is the row key — **HoH only**.
  - A single arrayref return is stored *as the cell*, so `sub { [split /,/, $_->{tags}] }` gives an arrayref-valued column.
- **A list of more than one value → whole column.** The list becomes the entire column, distributed positionally. This is the natural fit for column functions like `rank`:

        assign($df, 'ΔG rank' => sub { rank( vals($df, 'dG_kcal_mol') ) });
        # rank() returns a list, so the whole ranking lands in one column.

### Arrayref values
Pass a column you already have and it is copied in:

    assign($df, 'ΔG rank' => [ rank( vals($df, 'dG_kcal_mol') ) ]);

This is also how you install a computed *list* when you'd otherwise trip the "single arrayref = one cell" rule above.

### Ordering and length
- **AoH** distributes by array order; **HoH** by **sorted key order** — so any list you compute or hand in must be in `sort keys %$df` order.
- Whole-column and arrayref values must have exactly one entry per row; a length mismatch dies.

### Example
    my $df = [
        { weight => 70, height => 1.75 },
        { weight => 90, height => 1.80 },
    ];
    assign($df, bmi => sub { $_->{weight} / $_->{height} ** 2 });
    # $df is now:
    # [ { weight=>70, height=>1.75, bmi=>22.86 },
    #   { weight=>90, height=>1.80, bmi=>27.78 } ]

### Good to know
- **Pairs run in order**, so a later column can use one you just made:

        assign($df,
            bmi   => sub { $_->{weight} / $_->{height} ** 2 },
            class => sub { $_->{bmi} > 25 ? 'high' : 'ok' },   # uses bmi
        );

- **Same recipe, all shapes.** The same per-row `sub { $_->{weight} / ... }` works for AoH, HoA, and HoH; you always read the row through `$_`.
- **It modifies your data frame.** If you need to keep the original, pass a copy: `assign(clone($df), ...)`.
- Reusing a column name **overwrites** that column.

## binom_test

`binom_test` answers one question: you ran a yes/no experiment `n` times and
got `x` successes — is that consistent with some assumed success rate, or is it
too far off to be chance? It is the exact binomial test, the same as R's
`binom.test`.

### A toddler and two cards

Show a toddler two cards each round and ask them to point at the one with the
star. If he/she is only guessing, he/she will be right half the time, so the
"pure guessing" success rate is `p = 0.5`.

You play 10 rounds and the toddler gets 6 right. Real skill, or just luck?

    use Stats::LikeR 'binom_test';

    my $r = binom_test(6, 10, p => 0.5);   # 6 wins, 10 rounds, guessing rate 0.5

    print $r->{p_value};                   # 0.7539

The full result is a hashref:

    {
        statistic   => 6,            # times the toddler was right
        parameter   => 10,           # rounds played
        estimate    => 0.6,          # observed rate, 6/10
        null_value  => 0.5,          # the "pure guessing" rate we test against
        p_value     => 0.7539,
        conf_int    => [0.262, 0.878],
        conf_level  => 0.95,
        alternative => 'two.sided',
        method      => 'Exact binomial test',
    }

### Reading the p-value

The p-value is the chance of seeing a result **at least this surprising** if the
toddler were really just guessing.

Here `p = 0.75`. That is enormous: a pure guesser scores 6/10 (or something
even further from 5) about three times out of four. So 6/10 is completely
ordinary luck — no evidence of skill.

The common cutoff is `0.05`. Below it, you start to believe something real is
going on. Above it, chance explains the result fine. `0.75` is nowhere close,
so we call this **just chance**.

### What "legit" would look like

Suppose the toddler had gone 9 for 10 instead:

    my $r = binom_test(9, 10, p => 0.5);

    print $r->{p_value};                   # 0.0215

Now `p = 0.02`, under `0.05`. A pure guesser almost never does that well, so
this **is** good evidence the toddler can actually tell the cards apart.

### The confidence interval

`conf_int` is the plausible range for the toddler's true success rate. For
6/10 it runs from about `0.26` to `0.88` — wide, and it comfortably includes
`0.5`. That overlap with the guessing rate is another way of seeing that luck
cannot be ruled out. For 9/10 the interval would sit well above `0.5`.

### Options

  - `p` is the assumed success rate (default `0.5`).
  - `alternative` is `'two.sided'` (default), `'less'`, or `'greater'`. Use
    `'greater'` when you only care whether the toddler beats guessing, not
    whether they do worse.
  - `conf_level` sets the interval width (default `0.95`).

You can also pass the counts as `binom_test([6, 4])` — 6 right, 4 wrong — when
you have wins and losses instead of wins and a total.

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

## chunk

Split an array into contiguous, roughly equal groups by *position*. Unlike
[`qcut`](#qcut), `chunk` does not inspect values, sort, or compute cutpoints; it
slices the array in the order given. Use it for batching work, paginating, or
grouping non-numeric data such as strings.

### Signature

    my @groups = chunk($data, size  => $n);   # fixed elements per group
    my @groups = chunk($data, parts => $k);   # fixed number of groups

  - `$data` — an array reference. Its contents are never examined or sorted;
    elements are grouped in input order.

Pass exactly one of `size` or `parts`. Passing both, or neither, is a fatal
error — the two readings of "equal groups" differ (see below), so the caller
chooses which one is meant rather than relying on a default.

  - `size => $n` — each group holds `$n` elements; the final group holds
    whatever remains.
  - `parts => $k` — the array is divided into `$k` groups as equal as possible,
    with any remainder spread across the leading groups.

### Return value

A list of array references, in input order — call it in list context:

    my @groups = chunk($data, parts => 4);

Passing more `parts` than there are elements yields trailing empty groups
(matching `numpy.array_split`), so no elements are ever dropped. An empty input
array returns an empty list.

### Examples

`size` fixes the elements per group; the last group is the remainder. Splitting
the 26 letters into groups of five leaves one over:

    my @groups = chunk(['a' .. 'z'], size => 5);
    # 6 groups, sizes 5,5,5,5,5,1
    # [a b c d e] [f g h i j] [k l m n o] [p q r s t] [u v w x y] [z]

`parts` fixes the number of groups; the remainder is absorbed by the leading
groups instead:

    my @groups = chunk(['a' .. 'z'], parts => 5);
    # 5 groups, sizes 5,5,5,5,6
    # [a b c d e] [f g h i j] [k l m n o] [p q r s t] [u v w x y z]

When the split is even the two forms agree:

    my @a = chunk([1 .. 10], size  => 2);
    my @b = chunk([1 .. 10], parts => 5);
    # identical: 5 groups of 2

Order is preserved — `chunk` never sorts. Sort the array yourself first if you
want ordered groups:

    my @groups = chunk([3, 1, 2], size => 2);
    # ([3, 1], [2])

More parts than elements gives empty trailing groups, losing nothing:

    my @groups = chunk([1, 2, 3], parts => 5);
    # 5 groups; flattening them back gives (1, 2, 3)

## `col2col`

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

### Arguments

    col2col( $data, $command, $cols, %options )
    col2col( $data, $command, \%options )      # options in place of $cols

| Position | Argument    | What it is |
|----------|-------------|------------|
| 1        | `$data`     | Your table, as a reference (see **Data shapes** below). |
| 2        | `$command`  | A code block **or** the name of a two-column function. |
| 3        | `$cols`     | *(optional)* Which columns to use as the "from" side. Omit for all. |
| 4+       | `%options`  | *(optional)* `na`, `skip.errors`, … (see **Options**). |

---

### Data shapes

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

### The command

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

### The result

Always a hash of hashes: **`$result->{from}{to}`**.

    for my $from (sort keys %$result) {
       for my $to (sort keys %{ $result->{$from} }) {
          printf "%s vs %s = %s\n", $from, $to, $result->{$from}{$to};
       }
    }

A column is never compared with itself, so `$result->{a}{a}` does not exist.

---

### Restricting columns (`$cols`)

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

### Options

Options can be given two ways:

    col2col(\%data, 'cor', $cols, 'skip.errors' => 0);   # after $cols
    col2col(\%data, 'cor', { 'skip.errors' => 0 });      # hash ref, no $cols needed

The hash-ref form is convenient when you have **no** column restriction — it saves
you from passing a placeholder. (A hash ref *replaces* `$cols`, so you can't use
it to restrict columns at the same time; use the trailing form for that.)

#### `na` — how undefined values are handled

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

#### `skip.errors` — keep going when a pair fails *(default: true)*

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

### Worked examples

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

### Gotchas

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

## colnames

Return the column names of a data frame, as a list (like R's `colnames`).
Works on all four Stats::LikeR frame shapes and mirrors the column order
`view` shows:

  * `AoA` — 0-based integer indices, `0 .. widest_row-1`
  * `AoH` — the string-sorted union of the keys of every row
  * `HoA` — the string-sorted keys (the keys *are* the columns)
  * `HoH` — the string-sorted union of the inner-row keys

In scalar context it returns the count, so `scalar colnames($df)` equals
`ncol($df)` for a rectangular frame.

    my $aoh = [ { b => 2, a => 1 }, { a => 3, c => 9 } ];
    my @cols = colnames($aoh);        # ('a', 'b', 'c')  -- union, sorted

    my $hoa = { z => [1,2], a => [3,4], m => [5,6] };
    my @cols = colnames($hoa);        # ('a', 'm', 'z')

    my $aoa = [ [1,2,3], [4,5,6] ];
    my @cols = colnames($aoa);        # (0, 1, 2)

    my $n = colnames($hoa);           # 3  (scalar context == ncol)

## concat

Row-bind two or more data frames: stack their rows into one new frame, the
analog of pandas `concat(..., axis=0)` and R's `rbind`. `rbind` is provided as a
true synonym (the same subroutine), so the two names are interchangeable.

`concat` accepts all four data-frame shapes and returns a new frame of that same
shape:

    AoA  [ [ .. ], [ .. ] ]      array of arrayrefs   (positional columns)
    AoH  [ { .. }, { .. } ]      array of hashrefs    (the read_table default)
    HoA  { c => [ .. ], .. }     hash of arrayrefs    (column-major)
    HoH  { r => { .. }, .. }     hash of hashrefs     (named rows)

Every frame must be the same shape; mixing shapes dies with a hint to convert
first (`aoh2hoa`, `hoa2aoh`, `hoh2hoa`, `aoh2hoh`). undef frames and empty
frames are skipped, and the shape is taken from the first non-empty frame. The
original frames are never modified.

### Usage

    use Stats::LikeR;

    my $all = concat($df1, $df2, $df3);   # any number of frames
    my $all = rbind($df1, $df2);          # identical: rbind is a synonym

### Array of Arrays (AoA)

The outer arrays are concatenated in order and the row arrayrefs are reused by
reference (not copied). Ragged rows are kept as-is; reading past a short row
yields undef.

    my $a = [ [ 1, 2 ], [ 3, 4 ] ];
    my $b = [ [ 5, 6 ], [ 7 ]    ];   # ragged last row
    my $c = concat($a, $b);

**Resulting Structure:**

    [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 7 ] ]

### Array of Hashes (AoH)

The rows are concatenated in order and the row hashrefs are reused by reference.
The result is the union of columns; a column absent from a given row simply
reads as undef, matching this module's "missing key means undef" convention
(as used by `dropna`, `view`, and `summary`).

    my $a = [ { id => 1, x => 10 } ];
    my $b = [ { id => 2, x => 20, y => 99 } ];   # extra column y
    my $c = concat($a, $b);

**Resulting Structure:**

    [
        { id => 1, x => 10           },   # no 'y' key -> reads as undef
        { id => 2, x => 20, y => 99  },
    ]

### Hash of Arrays (HoA)

The output columns are the union of all input columns, sorted for a
deterministic layout. Each column is the per-frame arrays joined in frame order.
Because HoA is column-major, a column missing from a frame — or a ragged short
column within a frame — is padded with undef so every output column ends up the
same length (the total number of rows).

    my $a = { g => [ 'a', 'a' ], v => [ 1, 2 ] };
    my $b = { g => [ 'b' ],      w => [ 9 ]    };   # v absent here, w is new
    my $c = concat($a, $b);

**Resulting Structure:**

    {
        g => [ 'a',   'a',   'b' ],
        v => [ 1,     2,     undef ],   # padded for the frame that lacked 'v'
        w => [ undef, undef, 9     ],   # padded for the frame that lacked 'w'
    }

### Hash of Hashes (HoH)

The outer hashes are merged in frame order and the inner row hashrefs are reused
by reference. Because a Perl hash cannot hold duplicate keys, a repeated row
name is made unique R-style — `name`, `name.1`, `name.2`, … — and a single
warning is emitted noting that row names collided.

    my $a = { r => { v => 1 } };
    my $b = { r => { v => 2 } };
    my $c = concat($a, $b);
    # warns: concat: duplicate HoH row name(s) made unique with a .N suffix

**Resulting Structure:**

    {
        r     => { v => 1 },
        'r.1' => { v => 2 },
    }

### Empty and single inputs

undef and empty frames are skipped, so they can be threaded through a pipeline
harmlessly:

    concat(undef, [], [ { n => 1 } ], [ { n => 2 } ]);   # two rows

When every frame is empty the result is an empty frame matching the first
argument's reference type (`[]` for an arrayref, `{}` for a hashref). A single
frame round-trips unchanged.

### rbind

`rbind` is the same subroutine as `concat`, exported under a second name for
readers who know it from R:

    my $c = rbind($df1, $df2);

    # they are literally the same code reference:
    \&Stats::LikeR::rbind == \&Stats::LikeR::concat;   # true

### Errors

`concat` (and therefore `rbind`) dies (with a trailing newline) when:

- no usable frame is given;
- a frame is neither an ARRAY nor a HASH ref;
- the frames are not all the same shape (the message names the two shapes and
  suggests the relevant converter);
- an AoA element is not an arrayref, or an AoH/HoH row is not a hashref.

### See also

`agg` (split-apply-combine), `add_data` (which also appends HoA columns and
merges HoH rows), `ljoin`, `aoh2hoa`, `hoa2aoh`, `hoh2hoa`, `aoh2hoh`.

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

## csort

Sort a data frame by a column or a custom comparator, returning a new
(sorted) copy. The input is never mutated.

    my $sorted = csort($data, $by);
    my $sorted = csort($data, $by, $output_shape);
    my $sorted = csort($hoh,  $by, 'aoh', 'row.name');   # HoH only

`$data` may be any of four shapes:

    AoH   array-of-hashes    [ { col => val, ... }, ... ]   columns are hash keys
    HoA   hash-of-arrays      { col => [ val, ... ], ... }   columns are hash keys
    HoH   hash-of-hashes      { rowname => { col => val }, ... }
    AoA   array-of-arrays    [ [ val, ... ], ... ]           columns are integer indices

The shape is detected automatically. An array-ref whose first row is
itself an array-ref is treated as an AoA; otherwise an array-ref is an
AoH. A hash-ref whose first value is a hash-ref is a HoH (its outer keys
are folded into a row-name column, see below); any other hash-ref is a
HoA.

`$by` selects the sort key:

    'No.'                          # a column: name (AoH/HoA/HoH) or integer index (AoA)
    2                              # AoA: sort by column index 2
    sub { $a->{'No.'} <=> $b->{'No.'} }   # comparator; $a/$b are the rows

For a column sort the values are compared numerically when every present
value looks like a number, and with string `cmp` otherwise. For a
comparator, `$a` and `$b` are the row references (a hash-ref for
AoH/HoA/HoH, an array-ref for AoA), exactly as with Perl's own `sort`.

### Sorting an AoA

Columns in an AoA are addressed by non-negative integer index:

    my $rows = [
        [ 3, 30, 'gamma' ],
        [ 1, 10, 'alpha' ],
        [ 2, 20, 'beta'  ],
    ];

    my $s = csort($rows, 0);       # by column 0 -> id 1, 2, 3
    my $s = csort($rows, 2);       # by column 2 -> alpha, beta, gamma
    my $s = csort($rows, sub { $b->[1] <=> $a->[1] });   # by column 1, descending

The result reuses the original row array-refs (a reorder, not a deep
copy), so it is cheap and the caller's data is left untouched. A
non-integer or negative index croaks; an index no row contains is
reported as a missing column.

### Undefined and missing values

Undefined or missing cells always sort to the end. A "missing" cell is a
row that lacks the key (AoH/HoH) or is shorter than the index (AoA); it
is treated the same as an explicit `undef`. Defined values are ordered
first (ascending, or per the comparison type), undef/missing last, and
undef rows keep their original relative order.

    my $rows = [
        [ 1, 5 ],
        [ 2 ],           # no column 1
        [ 3, undef ],
        [ 4, 1 ],
    ];
    my $s = csort($rows, 1);       # column-0 order: 4, 1, 2, 3

This holds for every shape, for numeric and string columns, and for
**both** a column/index sort and a comparator sort:

    # no need to guard undef yourself -- this does not warn or die,
    # even under  use warnings FATAL => 'all'
    my $s = csort($df, sub { $a->{'tau p'} <=> $b->{'tau p'} }, 'hoa');

For a comparator, csort can't see which field you key on, so it probes
each row once (comparing the row to itself) to find rows whose comparator
would read an `undef`; those rows are moved to the end and the rest are
sorted normally, so your comparator never sees an `undef`. A few
consequences worth knowing:

* If your comparator reads several keys (a tie-break), a row is treated as
  undef-keyed when *any* key the comparator actually evaluates for that
  row is undef. Such rows go to the bottom.
* A comparator that handles undef itself (e.g. `$a->{v} // 0`) never trips
  the probe, so csort leaves its ordering completely alone.
* A comparator that dies for a real reason still propagates that error
  unchanged.
* The probe calls your comparator once per row, so keep comparators free
  of side effects (they should be anyway).

### Choosing the output shape

The optional third argument picks the returned shape, one of `'aoh'`,
`'hoa'`, or `'aoa'` (case-insensitive). It defaults to the input shape
(HoH defaults to AoH). Any shape can be converted to any other:

    csort($aoa, 0)               # AoA -> AoA (default)
    csort($aoa, 0, 'hoa')        # AoA -> HoA
    csort($aoh, 'No.', 'aoa')    # AoH -> AoA

When the target is AoH or HoA, an AoA's columns are keyed by their
stringified index (`'0'`, `'1'`, ...). When the target is AoA, the
positional column order is deterministic:

    from HoA   sorted column-key name
    from AoH   union of the rows' keys, sorted by name
    from AoA   integer index 0 .. widest-row-1 (ragged rows pad with undef)

Because Perl randomizes hash iteration order, the sort of key names is
what makes keyed-to-AoA conversions reproducible from run to run.

### Sorting a HoH

For a HoH, each outer key is the row name. It is folded into a real
column so it survives into the output; the column is named `row.name` by
default, overridable with a fourth argument:

    my $s = csort($hoh, 'score', 'aoh');           # row name in 'row.name'
    my $s = csort($hoh, 'score', 'aoh', 'sample'); # ... named 'sample' instead

## dnorm

gives the density of the normal distribution, with the specified mean and standard deviation.

In other words, the predicted height of the value `x`, given a mean, standard deviation, and whether or not to use a log value.

returns a single scalar/number if a single value is given, otherwise returns an array reference.

Usage:

    dnorm(4) # assumes a mean of 0 and standard deviation of 1

but default mean, standard deviation, and log can be passed as parameters:

    $x = dnorm(0, mean => 0, sd => 2, 'log' => 0);

## drop_cols

Return a new data frame with the named columns removed and the rest kept —
`df.drop(columns=[...])`. Same identifiers and argument forms as
`select_cols`.

    my $hoa = { a => [1,4], b => [2,5], c => [3,6] };
    drop_cols($hoa, 'b');
    # { a => [1,4], c => [3,6] }

    my $aoa = [ [1,2,3], [4,5,6] ];
    drop_cols($aoa, 1);          # result is re-indexed 0,1
    # [ [1,3], [4,6] ]

Unlike `select_cols`, `drop_cols` touches only the keys a row actually has,
so a ragged frame stays ragged:

    drop_cols([ {a=>1,b=>2}, {a=>3,c=>9} ], 'a');
    # [ { b => 2 }, { c => 9 } ]

## dropna

Drop missing data from a data frame, loosely modeled on pandas' `dropna`. Works
on all three shapes: AoH `[ {A=>..}, .. ]`, HoA `{ A=>[..], .. }`, and
HoH `{ r1=>{A=>..}, .. }`.

### Usage

    # NA mode: drop rows that are undef in the named columns
    dropna($df, cols => ['A', 'B']);
    dropna($df, cols => ['A', 'B'], how => 'all');
    # deletion mode: remove specific rows outright
    dropna($df, rows => [2, 5]);          # indices for AoH/HoA, keys for HoH

You pass **exactly one** of `cols` or `rows`.

### `cols` — drop rows with missing values

Inspect only the named columns and drop the rows where they're undef. Columns
you don't name are never inspected, but they stay aligned (their cell at a
dropped row goes too). A missing key counts as undef.

`how` controls the threshold:

- **`'any'`** (default) — drop a row if *any* named column is undef there.
- **`'all'`** — drop a row only if *every* named column is undef there.

    my $df = { A => [1, 2, undef], B => [1, 2, 3], C => [undef, 2, 4] };
    dropna($df, cols => ['A', 'B']);
    # { A => [1, 2], B => [1, 2], C => [undef, 2] }

Index 2 is dropped because `A` is undef there. `C` is not consulted, so its own
undef at index 0 doesn't trigger a drop — but index 2 is still removed from `C`
so every column stays the same length.

### `rows` — delete specific rows

Remove exactly the rows you list — no missing-value logic. Rows are 0-based
indices for AoH and HoA, or the outer keys for HoH. Anything not present is
ignored.

    dropna({ A => [10, 20, 30] }, rows => [1]);   # { A => [10, 30] }

### Good to know

- **Returns a new data frame; the original is never modified.** For HoA the
  column arrays are rebuilt (cell values copied); for AoH and HoH the surviving
  row references are reused, not deep-copied (dropna never mutates a row). Clone
  the result if you need full independence.
- **It dies** on: a non-ref data frame; passing both or neither of `cols`/`rows`;
  a non-arrayref selector; a `cols` name absent from a non-empty HoA or AoH; an
  invalid `how`; an unknown argument; or a hashref that mixes array and hash
  values (ambiguous HoA vs HoH).
- An empty AoH or HoA returns empty rather than erroring.
- HoH results come back in hash order, since HoH rows are unordered.

## filter

Return a new data frame containing only the rows of `$df` that match a predicate. The original `$df` is never modified.

    my $adults = filter($df, col('age') >= 18);

`filter` accepts a predicate in one of two forms:

1. a **`col()` expression** — a small, composable comparison built with overloaded operators, and
2. a **code reference** — for anything the operators can't express (multiple columns, regexes, matching on the row name, arbitrary logic), in the same spirit as the `filter` option of [`read_table`](#).

Both `filter` and `col` are exported by default.

### Arguments

| Position | Name | Description |
| --- | --- | --- |
| 1 | `$df` | The data frame: an **array of hashes** (AoH, the default `read_table` output), a **hash of arrays** (HoA), or a **hash of hashes** (HoH, e.g. `read_table` with `'output.type' => 'hoh'`). |
| 2 | predicate | A `col()` comparison object **or** a `CODE` reference. A coderef receives the row as `$_` / `$_[0]` and the row identifier as `$_[1]` (see below). |
| 3 + | `'output.type' => 'aoh'\|'hoa'` | *Optional.* The shape of the returned frame. Omit it to keep the input's own shape. `'out'` and `'output_type'` are accepted aliases, and a bare `filter($df, $pred, 'aoh')` also works. |

### The `col()` form

`col('name')` is a deferred reference to a column. It carries no data — only the column name — so it can be compared with a literal to build a predicate that `filter` evaluates once per row.

    filter($df, col('age') >= 18);  # keep rows where age >= 18
    filter($df, col('sex') eq 'f'); # keep rows where sex is 'f'
    filter($df, 18 <= col('age'));  # operands may be in either order

| Kind | Operators | Comparison |
| --- | --- | --- |
| Numeric | `>` `<` `>=` `<=` `==` `!=` | numeric (cell and value compared as numbers) |
| String | `gt` `lt` `ge` `le` `eq` `ne` | string (cell and value compared as strings) |

Predicates compose with bitwise `&` (and), `|` (or), and `!` (not):

    filter($df, (col('age') > 18) & (col('sex') eq 'f'));   # and
    filter($df, (col('grp') eq 'a') | (col('grp') eq 'c')); # or
    filter($df, !(col('x') > 100));                         # not

Comparison operators bind more tightly than `&` and `|`, so `(col('a') > 4) & (col('b') < 2)` is parsed correctly, but the parentheses are recommended for readability.

> Note: `col('age') > 32` works because `col('age')` is an object whose `>` is overloaded. A **bare string** cannot do this — `'age' > 32` is computed by Perl to a plain boolean (the string numifies to 0) before `filter` is ever called, so the column name is lost. Always wrap the column in `col(...)`.

> `col()` addresses **columns only** — it has no handle on a HoH's row name (the outer key). It also cannot express a regex match: there is no `=~` operator to overload, so `col('name') =~ /re/` runs the match immediately on the stringified object and never reaches `filter`. For either case, use the code-reference form below.

### The code-reference form

For logic the operators can't express, pass a `sub`. It is called once per row and is given:

- the **row** as a hash reference, available both as `$_` and as the first argument `$_[0]`, and
- the **row identifier** as the second argument, `$_[1]` — the **outer key (the row name)** for a HoH, or the **0-based row index** for an AoH or HoA.

Return a true value to keep the row.

    filter($df, sub { $_->{x} > 4 && $_->{grp} eq 'a' });
    filter($df, sub { $_->{name} =~ /^A/ });
    filter($df, sub { $_->{age} % 2 == 0 });            # things col() has no operator for
    filter($df, sub { $_[0]{score} > $_[0]{threshold} });

For a HoA, each row is assembled into a temporary `{ column => value, ... }` hash before the sub (or the `col()` test) is called, so the same `$_->{column}` syntax works regardless of the input shape.

#### Filtering on the row name (`$_[1]`)

In a HoH the row name is the **outer key**, not a field inside each row hash — so `$_->{row_name}` is `undef`. Match on `$_[1]` instead:

    # HoH keyed by structure id; keep the rows named in @ids
    my $grps = join '|', @ids;
    my $keep = filter($score, sub { $_[1] =~ m/^(?:$grps)$/ });

    # combine the row name with an ordinary column test
    filter($score, sub { $_[1] =~ /^1/ && $_->{anomaly_rank} < 100 });

For an AoH or HoA, `$_[1]` is the 0-based row index:

    filter($aoh, sub { $_[1] % 2 == 0 });   # keep even-indexed rows
    filter($hoa, sub { $_[1] < 10 });        # keep the first ten rows

### Choosing the output shape

By default `filter` returns a frame of the **same shape** as the input (AoH → AoH, HoA → HoA, HoH → HoH). Pass `output.type` to convert while filtering:

    my $aoh = read_table('patients.csv');                          # array of hashes
    my $hoa = filter($aoh, col('Age') >= 18, 'output.type' => 'hoa');
    # $hoa->{Age}, $hoa->{Sex}, ... are all the same length and row-aligned

The two selectable output types are `'aoh'` and `'hoa'`. `'hoh'` is **not** selectable, because producing a hash of hashes would require choosing which column becomes the row key; an HoH input keeps its keys only when the output shape is left at the default (HoH → HoH).

### Examples

    use Stats::LikeR;
    my $df = read_table('patients.csv');                 # array of hashes

    my $adults = filter($df, col('Age') >= 18);          # numeric threshold
    my $target = filter($df, (col('Age') >= 18) & (col('Sex') eq 'f'));   # combine
    my $flagged = filter($df, sub { $_->{ALT} > 40 || $_->{AST} > 40 });  # coderef

    # hash of arrays in -> hash of arrays out (columns filtered in parallel)
    my $hoa = read_table('patients.csv', 'output.type' => 'hoa');
    my $sub = filter($hoa, col('Age') > 32);

    # hash of hashes in -> the same row keys, fewer of them
    my $hoh = read_table('patients.csv', 'output.type' => 'hoh');
    my $keep = filter($hoh, col('Age') > 32);

    # hash of hashes: filter on the row name (the outer key) via $_[1]
    my $grps    = join '|', qw(1cka 1d4t);
    my $by_name = filter($hoh, sub { $_[1] =~ m/^(?:$grps)$/ });

    # convert shape while filtering
    my $as_hoa = filter($df, col('Age') > 32, 'output.type' => 'hoa');

### Behavior and notes

- **The input is never modified.** `filter` builds and returns a new frame; `$df` is left untouched.
- **The predicate receives the row identifier as `$_[1]`.** For a HoH it is the outer key (the row name); for an AoH or HoA it is the 0-based row index. In a HoH the row name lives in the *key*, not inside each row hash, so `$_->{row_name}` is `undef` — filter on `$_[1]` instead. `col()` expressions see only columns, never the row key.
- **A missing or `undef` cell never matches a `col()` comparison.** `col('x') > 0` silently drops any row whose `x` is absent or `undef`; for numeric operators a non-numeric cell is likewise dropped. With a coderef, `undef` is whatever your sub makes of it.
- **Rows are shared, not deep-copied, wherever possible.** When an AoH or HoH row is kept (output left as AoH/HoH, or converted to `aoh`), the returned frame references the *same* inner row hashes as the input. Mutating such a row in the result would also change it in the original. HoA inputs and any `hoa` output build fresh arrays and fresh cell values.
- **Keep-all / keep-none are well defined.** A predicate true for every row returns the whole frame in the chosen shape; true for none returns an empty frame: `[]` for `aoh`, a hash of empty (but present) columns for `hoa`, and `{}` for `hoh`.
- **Supported shapes are AoH, HoA, and HoH.** A non-reference, an AoH element that is not a hash reference, a HoA column that is not an array reference, or a HoH row that is not a hash reference all raise a descriptive error; a bare `col('x')` with no comparison is also an error. An empty hash `{}` is treated as an empty frame.
- **Perl 5.10 compatible.** The `col()`/operator layer is pure Perl (operator overloading building a per-row closure); filtering and any reshaping run in XS.

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

## get_union

    my @all   = get_union(\@a, \@b, \@c); # every distinct value, any list
    my $count = get_union(\@a, \@b, \@c); # how many distinct values

Takes one or more array references and returns every value that appears in at
least one of them. Duplicates collapse and the result keeps first-appearance
order. In scalar context it returns the count. Values are compared by their
string form (like Perl hash keys), so `1`, `"1"` and `1.0` are one element,
while a UTF-8 flagged string stays distinct from the same bytes without the
flag. A non-array-ref argument or an `undef` element is fatal. Mirrors
`List::Compare`'s `get_union`.

    my @a = (1, 2, 3, 3);
    my @b = (3, 4);
    my @u = get_union(\@a, \@b);            # (1, 2, 3, 4)

## get_unique

    my @only_first = get_unique(\@a, \@b, \@c);
    my $count      = get_unique(\@a, \@b, \@c);

Takes one or more array references and returns the values that appear in the
**first** reference and in **no other** reference; with a single reference it
returns that list's distinct values. Duplicates collapse, the result keeps
first-appearance order, and scalar context returns the count. Values are
compared by string form (see `get_union`). A non-array-ref argument or an
`undef` element is fatal. Mirrors `List::Compare`'s `get_unique`, which
likewise defaults to the first list.

    my @a = (1, 2, 3);
    my @b = (3, 4, 5);
    my @c = (5, 6);
    my @u = get_unique(\@a, \@b, \@c);      # (1, 2)  -- 3 is also in @b

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

## hoa2aoh

Turn a hash-of-arrays into an array-of-hashes.

### Usage

    my $aoh = hoa2aoh($hoa);

- **`$hoa`** — a hashref whose values are arrayrefs, one per column:

    { id => [1, 2, 3], name => ['a', 'b', 'c'] }

- **returns** — an arrayref of row hashrefs:

    [
        { id => 1, name => 'a' },
        { id => 2, name => 'b' },
        { id => 3, name => 'c' }
    ]

It builds a brand-new structure and copies every cell, so the result is
completely independent of the input — changing one never affects the other.

### Example

    my $hoa = { mpg => [21, 22.8, 18.1], cyl => [6, 4, 6] };
    my $aoh = hoa2aoh($hoa);
    $aoh->[1]{mpg};        # 22.8
    $hoa->{mpg}[1];        # still 22.8 — unaffected by edits to $aoh

### Good to know

- **Row count** is the length of the longest column. If columns have different
  lengths, the short ones are padded with `undef` in the missing rows.
- **`undef` cells** are kept as `undef`.
- An **empty hash**, or one whose columns are all empty, gives back `[]`.
- It **dies** if the argument isn't a hashref, or if any column value isn't an
  arrayref (the message names the offending column).

### See also

`hoa2aoh` is the reverse of `aoh2hoa`

## hoa2hoh( \%hoa, $key )

Converts a hash-of-arrays (column-major) into a hash-of-hashes keyed by the
`$key` column, i.e. `{ $rowname => { col => value, ... } }`. Analogous to
`hoa2aoh`, but rows are indexed by their `$key` value instead of positionally.

    my %hoa = (
        id => [ qw(a b c) ],
        x  => [ 1, 2, 3 ],
        y  => [ 4, 5, 6 ],
    );
    my $hoh = hoa2hoh( \%hoa, 'id' );
    # { a => { id => 'a', x => 1, y => 4 }, b => {...}, c => {...} }

The `$key` column is retained in each inner row. Columns are copied by value.
Shorter columns are padded with `undef`, matching `hoa2aoh`.

Dies if: the first argument is not a hashref of arrayrefs; `$key` is undef or
names a missing/non-array column; the `$key` column holds an undefined value
for any row; or two rows share the same `$key` value.

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

## intersection

Returns the set intersection (∩) of a list of array references: the values
that appear in **every** array ref given.

	use Stats::LikeR;

	my @i = intersection([1, 2, 3], [2, 3, 4]);          # (2, 3)
	my @t = intersection([1, 2, 3, 4], [2, 3, 4], [3, 4]); # (3, 4)
	my $n = intersection([1, 2, 3], [2, 3, 4]);          # 2

Every argument must be an array reference: each one is treated as a set.
Unlike `mean` and `uniq`, bare scalars are not accepted; passing a non-reference
(or a non-array reference) croaks.

The result is **deduplicated** and ordered by first appearance in the *first*
array ref. Duplicate values within any single ref are counted once, so
`intersection([1, 2, 2, 3], [2, 3, 3, 4])` is `(2, 3)`, not `(2, 2, 3)`.

Values are compared by stringification — the same `eq` semantics used by
`uniq`. `1`, `1.0`, and `"1"` are treated as equal, while `"3"` and `"3.0"`
are distinct. The UTF-8 flag is part of the comparison key, so a UTF-8 string
and a byte-identical non-UTF-8 string are kept separate.

In list context `intersection` returns the shared values; in scalar context it
returns the cardinality (the number of shared values).

With a single array ref, the result is simply that ref's unique values. If any
ref is empty, the intersection is empty.

`intersection` croaks on degenerate or ill-formed input, reporting the
offending position:

	intersection();              # croaks: intersection needs >= 1 array ref
	intersection([1, 2], 3);     # croaks: argument 1 is not an array ref
	intersection([1, undef, 3]); # croaks: undefined value at array ref index 1 (argument 0)

This matches the undef-handling of `mean` and `uniq` and the rest of the
numeric reducers in Stats::LikeR.

## is_equivalent

`is_equivalent(\@a, \@b, ...)` returns **1** if every list holds the same
*set* of distinct values, and **0** otherwise. Order and duplicates don't
count — only which values are present.

Think of each list as a bag, dump each bag into its own set, and ask: are all
the sets identical?

    is_equivalent([1,2,3], [3,2,1])     # 1  same values, different order
    is_equivalent([1,1,2], [2,1])       # 1  duplicates ignored
    is_equivalent([1,2,3], [1,2])       # 0  right is missing 3
    is_equivalent([1,2],   [1,2,3])     # 0  right has an extra 4
    is_equivalent([1,2], [2,1], [1,2])  # 1  works for any number of lists

It generalises `List::Compare`'s `is_LequivalentR()` from two lists to N.

### How it decides

Equivalence is transitive: if every list equals the first list, they all equal
each other. So the check is simple — build the distinct-value set of the
**first** list, then hold each other list up against it. A list matches when:

1. it contains **no value outside** the first set, and
2. it **covers every value** in the first set.

Fail either test for any list and the answer is 0.

### Edge cases

    is_equivalent([], [])        # 1  two empty sets are equal
    is_equivalent([], [1])       # 0  empty vs non-empty
    is_equivalent([1], [1], [1]) # 1

Values are compared **as strings** (like hash keys), so `1` and `"1"` are the
same, but `2` and `"2.0"` are not.

### Rules

- Pass **at least two** array refs. Fewer croaks.
- Every argument must be an **array ref**; anything else croaks.
- **`undef` inside a list croaks** — decide what a missing value means before
  calling, rather than letting it silently match.

### Why it's cheap

One pass over each list. Memory is just the first list's set plus one small
reusable set for de-duping the list currently being checked. A mismatch bails
out immediately, so unequal lists are usually rejected quickly

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

The Kolmogorov–Smirnov test checks whether two samples are drawn from the
same distribution (two-sample), or whether a single sample is drawn from a
given reference distribution (one-sample). It works by comparing the empirical
cumulative distribution functions (ECDFs) and measuring the largest gap
between them.

Two-sample form — pass two array references:

    $ks = ks_test(\@x, \@y);
    $ks = ks_test(\@x, \@y, alternative => 'greater');

One-sample form — pass one array reference and the name of a reference CDF.
Currently only `'pnorm'` is supported, i.e. the standard normal distribution
(mean 0, standard deviation 1):

    $ks = ks_test(\@x, 'pnorm');

Arguments may be given positionally (as above) or by name:

    $ks = ks_test(x => \@x, y => \@y, alternative => 'less', exact => 1);

Non-numeric and undefined elements are silently dropped before the test runs.

`alternative` selects which gap between the ECDFs is measured:

- `'two.sided'` (default) — the largest gap in either direction,
  D = sup |F_x − F_y|.
- `'greater'` — the largest gap where x's ECDF rises above the other,
  D⁺ = sup (F_x − F_y).
- `'less'` — the largest gap in the other direction, D⁻ = sup (F_y − F_x).

These follow R's `ks.test` convention: `'greater'`/`'less'` describe which CDF
lies *above* the other, which (because a higher CDF means smaller values) is
the opposite of which sample tends to be larger.

`exact` controls how the p-value is computed. Omit it to let the test choose:
the exact distribution is used for small samples (two-sample when nx·ny 
10000, one-sample when n < 100) and the asymptotic (Kolmogorov limiting)
approximation otherwise. Pass `exact => 1` to force the exact computation or
`exact => 0` to force the asymptotic one. Exact p-values cannot be computed
when the data contain ties; if ties are present on the exact path, the test
warns and falls back to the asymptotic p-value. (The exact one-sample test is
only available for the two-sided alternative; a one-sided one-sample request
also falls back to asymptotic.)

### Return value

`ks_test` returns a hash reference with four keys:

- **`statistic`** — the KS statistic for the chosen `alternative`: D, D⁺, or
  D⁻. It is the maximum distance between the two ECDFs (or, for the one-sample
  test, between the ECDF and the reference CDF), always in the range [0, 1].
  Larger values mean the distributions are further apart.
- **`p_value`** — the probability, under the null hypothesis that the samples
  share a distribution, of observing a statistic at least this large. It is
  clamped to [0, 1]; a small value (e.g. < 0.05) is evidence against the null.
- **`method`** — a human-readable description of exactly what was run, handy
  for logging or reproducing a result. One of:
  `"Two-sample Kolmogorov-Smirnov exact test"`,
  `"Two-sample Kolmogorov-Smirnov test (asymptotic)"`,
  `"One-sample Kolmogorov-Smirnov exact test"`, or
  `"One-sample Kolmogorov-Smirnov test (asymptotic)"`.
- **`alternative`** — the alternative hypothesis that was applied
  (`'two.sided'`, `'greater'`, or `'less'`), echoed back so the result is
  self-describing.

For example:

    my $ks = ks_test(\@x, \@y);
    if ($ks->{p_value} < 0.05) {
        printf "reject H0: D=%.4f, p=%.4g (%s)\n",
            $ks->{statistic}, $ks->{p_value}, $ks->{method};
    }

## ljoin

Consider a hash: `$h{$row}{$col}`, and another hash `$i{$row}{$col2}`.
`ljoin` will add information for `$col` in `%i` for each `$row` to `%h`, where `$row` exists in both `%h` and `%i`.
Similar to `cbind` in R.

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

## Lonly

    my @left_only = Lonly(\@left, \@right);
    my $count     = Lonly(\@left, \@right);

Takes **exactly two** array references and returns the values in the left list
that are absent from the right list. Duplicates collapse, the result keeps
left-list order, and scalar context returns the count. Values are compared by
string form (see `get_union`). A non-array-ref argument, an `undef` element,
or anything other than two references is fatal. Mirrors `List::Compare`'s
`get_Lonly`.

    my @a = (1, 2, 3, 4);
    my @b = (3, 4, 5);
    my @l = Lonly(\@a, \@b);                # (1, 2)

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
## ncol

`ncol($frame)` returns how many **columns** a data frame has. Like `nrow`, it
works on all the Stats::LikeR frame shapes, so you don't have to remember which
one you're holding:

    ncol([ [1,2,3], [4,5,6] ])         # 3   array of arrays  (AoA)
    ncol([ {a=>1,b=>2}, {a=>3,b=>4} ]) # 2   array of hashes  (AoH)
    ncol({ a=>[1,2], b=>[3,4] })       # 2   hash of arrays   (HoA)
    ncol({ r1=>{...}, r2=>{...} })     # 2   hash of hashes   (HoH)

### NB

A **column** is one field of each record. Where the fields live depends on the
shape:

- **Array of hashes** (AoH) — each row is a hash; the columns are its keys, so
  the count is how many keys a row has.
- **Array of arrays** (AoA) — each row is a list; the columns are its slots, so
  the count is how long a row is.
- **Hash of arrays** (HoA) — the keys *are* the columns, so the count is the
  number of keys.
- **Hash of hashes** (HoH) — each value is a row hash; the columns are that
  hash's keys, so the count is how many keys a row has.

A plain flat list (`[1,2,3]`) is treated as a single column.

### Edge cases

    ncol([])                    # 0
    ncol({})                    # 0
    ncol({ a=>[], b=>[] })      # 2

Empty frames are 0 columns. Note the last one: a HoA still has its columns even
when they hold no rows — the keys are the columns, rows or not.

### What it refuses to do

`ncol` would rather stop than hand back a wrong number:

- **Ragged frame** — if the rows disagree on how many columns they have (AoH,
  AoA, or HoH), there is no single column count, so it dies instead of guessing.
- **Junk input** — `undef`, a plain scalar, a SCALAR/CODE/GLOB ref, or a hash
  whose values aren't all arrays (HoA) or all hashes (HoH) dies with a message
  saying what it got.

Blessed frames are fine — it looks at the underlying array/hash, so your
objects count just like plain refs.

## nrow

`nrow($frame)` returns how many **rows** a data frame has. It works on all the
Stats::LikeR frame shapes, so you don't have to remember which one you're
holding:

    nrow([ [1,2,3], [4,5,6] ])       # 2   array of arrays  (AoA)
    nrow([ {a=>1}, {a=>2} ])         # 2   array of hashes  (AoH)
    nrow({ a=>[1,2,3], b=>[4,5,6] }) # 3   hash of arrays   (HoA)
    nrow({ r1=>{...}, r2=>{...} })   # 2   hash of hashes   (HoH)

### NB

A **row** is one record. Where the records live depends on the shape:

- **Array on the outside** (AoH, AoA, or a plain list) — each top-level
  element is a row, so the count is just the array's length.
- **Hash of hashes** (HoH) — each key is a row, so the count is the number of
  keys.
- **Hash of arrays** (HoA) — the keys are *columns*, not rows; the row count is
  how long those columns are.

### Edge cases

    nrow([])   # 0
    nrow({})   # 0

Empty frames are 0 rows, whatever the shape.

### What it refuses to do

`nrow` would rather stop than hand back a wrong number:

- **Ragged HoA** — if the columns have different lengths there is no single row
  count, so it croaks instead of guessing.
- **Junk input** — `undef`, a plain scalar, or a hash whose values aren't all
  arrays (HoA) or all hashes (HoH) croaks with a message saying what it got.

Blessed frames are fine — it looks at the underlying array/hash, so your
objects count just like plain refs.

## oneway_test

A one-way test for equality of group means that, unlike `aov`/ANOVA, **does not
assume equal variances**. By default it performs **Welch's one-way test** (the
same default as R's `oneway.test`), so the residual degrees of freedom are
usually fractional. Pass `var_equal => 1` for the classic equal-variance form.

    use Stats::LikeR qw(oneway_test);

### Input

`oneway_test` accepts your data in one of three shapes. In every case each
*group* is a vector of at least two numeric observations.

| Shape | What it means | Group labels |
|-------|---------------|--------------|
| **Hash of arrays** `{ a => [...], b => [...] }` | Each key is a group (R's `stack()` view of a named list) | the hash keys |
| **Array of arrays** `[ [...], [...] ]` | Each element is a group | `"Index 0"`, `"Index 1"`, … |
| **Hash + `formula`** `{ resp => [...], grp => [...] }, formula => 'resp ~ grp'` | Long-format columns split by a factor column | the distinct values of the factor |

### Options

| Option | Default | Meaning |
|--------|---------|---------|
| `var_equal` (alias `var.equal`) | `0` (false) | `0` → Welch's test (unequal variances). `1` → pooled-variance test. |
| `formula` | *none* | `'response ~ factor'`. Only valid with a **hash** input; an error with an array of arrays. |

### Data validation

Every observation must be **defined and numeric**; an `undef` or non-numeric
cell makes the call `die` with the offending group and position. This matches
the rest of `Stats::LikeR` (`mean`, `sum`, `cor`, … all die on `undef`) and
prevents missing values from being silently treated as `0`.

Each group needs at least two observations, and you need at least two groups.

### Output

A hash reference with three top-level keys:

| Key | Value |
|-----|-------|
| *factor name* (`Group`, or the formula's factor, e.g. `supp`) | the between-groups row: `Df`, `Sum Sq`, `Mean Sq`, `F value`, `Pr(>F)` |
| `Residuals` | the within-groups row: `Df`, `Sum Sq`, `Mean Sq` (`Df` is fractional under Welch) |
| `group_stats` | `{ mean => { group => mean, … }, size => { group => n, … } }` |

### Examples

#### Hash of arrays (each key is a group)

    my $res = oneway_test({
        yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
        ctrl  => [1,   1,   1,   0,   0,   0  ],
    });

    {
        Group => {
            Df        => 1,
            "Sum Sq"  => 61.6533333333333,
            "Mean Sq" => 61.6533333333333,
            "F value" => 177.504798464491,
            "Pr(>F)"  => 1.31343255160843e-07,
        },
        Residuals => {
            Df        => 9.81767348326473,   # fractional: Welch correction
            "Sum Sq"  => 3.47333333333333,
            "Mean Sq" => 0.353783749200256,
        },
        group_stats => {
            mean => { ctrl => 0.5, yield => 5.03333333333333 },
            size => { ctrl => 6,   yield => 6 },
        },
    }

#### Array of arrays (groups named by index)

    my $res = oneway_test([
        [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
        [1,   1,   1,   0,   0,   0  ],
    ]);

Identical to the hash form, except `group_stats` is keyed by position:

    group_stats => {
        mean => { "Index 0" => 5.03333333333333, "Index 1" => 0.5 },
        size => { "Index 0" => 6,                "Index 1" => 6   },
    }

#### Long format with a formula

When your data is in columns rather than pre-split groups, name the response
and factor columns with a formula. The factor's *values* become the groups and
the factor's *name* becomes the top-level key:

    my $res = oneway_test(
        {
            len  => [4.2, 11.5, 7.3, 16.5, 17.3, 13.6, 23.6, 18.5, 33.9],
            supp => [qw(VC VC VC OJ OJ OJ HI HI HI)],
        },
        formula => 'len ~ supp',
    );
    # $res->{supp}, $res->{Residuals}, $res->{group_stats} ...

### Classic equal-variance form

    my $res = oneway_test(\%groups, var_equal => 1);   # or 'var.equal' => 1

### Notes

- The default (Welch) does **not** require equal group sizes or equal variances;
  the pooled form (`var_equal => 1`) assumes equal variances.
- `formula` is only meaningful for a hash input. Passing it with an array of
  arrays is an error.
- Group order in the output is not guaranteed for hash inputs (it follows hash
  iteration order); read results by name, not position.
- Avoid naming a factor `Residuals` or `group_stats` in a formula, since those
  are reserved top-level keys in the result.

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

## pnorm

The normal cumulative distribution function: the probability that a normal random variable is `<= x`. Ports R's `pnorm`.
That is, take the integral from negative infinity to the point that you want.

    my $p = pnorm(1.96);            # 0.9750021  (standard normal, P(X <= 1.96))

`x` may be a single number or an array reference; an array reference returns an array reference of the same length.

    my $ps = pnorm([-1.96, 0, 1.96]);   # [0.0249979, 0.5, 0.9750021]

### Arguments

| Position | Name | Default | Description |
| --- | --- | --- | --- |
| 1 | `x` | — | A number, or an array reference of numbers. |
| 2 + | `mean` | `0` | Mean of the distribution. |
| | `sd` | `1` | Standard deviation. |
| | `lower` | `1` (true) | `1` = lower tail `P(X <= x)`; `0` = upper tail `P(X > x)`. `'lower.tail'` is an accepted alias. |
| | `log` | `0` (false) | If true, return the log of the probability. `'log.p'` is an accepted alias. |

### Examples

    pnorm(1.96);                    # lower tail:  0.9750021
    pnorm(1.96, lower => 0);        # upper tail:  0.0249979
    pnorm(1.96, log => 1);          # log lower tail: -0.02531565
    pnorm(2, mean => 1, sd => 0.5); # standardizes to z = 2: 0.9772499

Use `log => 1` for tails that would otherwise underflow to `0`:

    pnorm(-40);           # 0  (underflows)
    pnorm(-40, log => 1); # -804.6084

### Notes

- `sd => 0` gives a step at the mean: `x < mean` returns `0`, otherwise `1`.
- `sd < 0` returns `NaN` and warns.
- A `NaN` input (or an `undef` element of an array reference) yields `NaN`.
- `+Inf` returns `1`, `-Inf` returns `0`.

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

## predict

R-style prediction for the fitted objects returned by `lm` and `glm`. It rebuilds
each row's linear predictor from the model's coefficients and (for `glm`) applies
the inverse link.

### Usage

    my $fit  = lm(formula => 'mpg ~ wt + hp', data => $train);
    my $yhat = predict($fit, $newdata);              # predictions on new rows
    my $resp = predict($logit_fit, $newdata);        # glm: response scale (default)
    my $eta  = predict($logit_fit, $newdata, type => 'link');   # linear predictor
    my $fitted = predict($fit);                      # no newdata -> stored fitted.values

- **`$model`** — a fitted `lm`/`glm` hashref. `predict` reads its `coefficients`
  (and, for `glm`, its `family`).
- **`$newdata`** — a HoA, AoH, or HoH of new observations. Omit it (or pass
  `undef`) to get the model's own `fitted.values` back.
- **`type`** — `'response'` (default) returns predictions on the response scale
  (the inverse link applied — logistic for binomial); `'link'` returns the linear
  predictor. For `lm` and gaussian `glm` the link is the identity, so the two are
  the same.

### What it returns

A hashref keyed by row name → prediction, exactly like `lm`/`glm` key
`fitted.values`: a `row.names` column (or HoH key) if present, otherwise 1-based
integer labels.

    my $m = lm(formula => 'y ~ x + I(x^2)', data => $train);
    my $p = predict($m, { x => [1, 2, 3] });
    # { 1 => ..., 2 => ..., 3 => ... }

### How it works

For each new row the prediction is

    eta = Intercept + Σ  coef[term] · term(row)

where each `term` is evaluated with the same engine used to fit the model, so
interactions (`x:z` → product) and transforms (`I(x^2)` → power) behave
identically to fitting. Coefficients that the fit marked aliased (stored as NaN)
contribute nothing, just as they were excluded from the fitted values. For `glm`
with `family => 'binomial'` and `type => 'response'`, `eta` is passed through the
logistic function `1 / (1 + exp(-eta))`; otherwise `eta` is returned as is.

A consequence worth noting: predicting on the *training* data reproduces the
model's `fitted.values` for any model built from continuous terms, interactions,
or `I()` transforms.

### Good to know

- A prediction comes back as **NaN** when a required term can't be evaluated in
  the new data (a missing column, or a value that makes the term undefined).
- **Factors are a limitation.** The fitted object stores only the dummy term
  *names* (e.g. `genderM`), not the underlying factor levels, so `predict`
  cannot re-expand a raw categorical column in new data. Either pass pre-expanded
  0/1 dummy columns whose names match the coefficient names, or extend `lm`/`glm`
  to retain the factor levels.
- **It dies** on: a model that isn't a hashref or has no `coefficients`; an
  invalid `type`; or `newdata` that isn't a HoA/HoH hashref or AoH arrayref.

## qcut

Equal-frequency binning of a numeric column, which is the analog of pandas `qcut`.
Where `cut` would slice a value range into equal-*width* intervals (and dump
most of a skewed distribution into one bin), `qcut` chooses cutpoints so each
bin holds roughly the same *number* of observations. This is the binning you
usually want for ranked-list work: deciles, quartiles, top-5% tranches.

Cutpoints are computed by linear interpolation between order statistics, the
same method as numpy/pandas, so results match `pandas.qcut` exactly. Bins are
right-closed, `(a, b]`, with the lowest bin closed on both ends, `[a, b]`, so
the minimum value is always included.

### Signature

    qcut($data, $q, %options)

  - `$data` — an array reference of numbers. `undef` entries are treated as
    missing (NA): they are skipped when computing cutpoints and, when codes are
    requested, come back as `undef` in their original positions.
  - `$q` — either a positive integer (the number of equal-frequency bins) or an
    array reference of probabilities in `[0, 1]` giving explicit cut
    boundaries, e.g. `[0, 0.5, 0.95, 1]`.

For a usage reminder at the prompt, call `qcut('h')` (or `qcut('H')`); it dies
with a short help message.

### What it returns

By default `qcut` returns the **edge vector as a flat list** — the cheap,
common query — so call it in list context:

    my @edges = qcut($data, 4);          # ($e0, $e1, $e2, $e3, $e4)

The per-element bin assignment (the expensive part) is opt-in. Ask for it with
`codes => 1` and you get an array reference parallel to `$data`:

    my $codes = qcut($data, 4, codes => 1);

Ask for both in a single pass and you get two references, `($codes, $edges)`:

    my ($codes, $edges) = qcut($data, 4, codes => 1, edges => 1);

### Options

  - `edges => 1` — include the edge vector. On by default; turned off
    automatically when you request codes, so set it explicitly to get both.
  - `codes => 1` — include the 0-based integer bin codes.
  - `labels => [...]` — map the bin codes onto your own labels (implies
    `codes => 1`). The list length must equal the number of bins.
  - `labels => 'interval'` — label each element with its interval string,
    e.g. `(3.25, 5.5]` (also implies codes).
  - `duplicates => 'drop'` — if tied data produces non-unique cutpoints, merge
    them into fewer bins instead of dying. The default, `'raise'`, throws an
    error (as pandas does).

### Examples

Quartile edges (the default). The cutpoints match pandas exactly:

    my @edges = qcut([1 .. 10], 4);
    # @edges = (1, 3.25, 5.5, 7.75, 10)

Bin codes. They are 0-based; note the tie distribution matches pandas (inner
bins take 2 here, outer bins 3):

    my $codes = qcut([1 .. 10], 4, codes => 1);
    # $codes = [0, 0, 0, 1, 1, 2, 2, 3, 3, 3]

Edges and codes together, computed in one pass:

    my ($codes, $edges) = qcut([1 .. 10], 4, codes => 1, edges => 1);

Equal frequency on clean data — 100 values into 4 bins of 25:

    my $codes = qcut([1 .. 100], 4, codes => 1);
    # 25 elements in each of bins 0, 1, 2, 3

An explicit probability vector, for an asymmetric top-5% tranche:

    my @edges = qcut([1 .. 100], [0, 0.5, 0.95, 1]);
    my $codes = qcut([1 .. 100], [0, 0.5, 0.95, 1], codes => 1);
    # bin 0: lower half (50), bin 1: next 45%, bin 2: top 5%

Named labels instead of integer codes (implies codes):

    my $labels = qcut([1 .. 10], 4, labels => [qw/Q1 Q2 Q3 Q4/]);
    # ['Q1','Q1','Q1','Q2','Q2','Q3','Q3','Q4','Q4','Q4']

Interval-string labels:

    my $iv = qcut([1 .. 10], 4, labels => 'interval');
    # $iv->[0]  eq '[1, 3.25]'
    # $iv->[-1] eq '(7.75, 10]'

Missing values are ignored for cutpoints, and (when codes are requested) pass
straight through:

    my $codes = qcut([1, 2, undef, 4, 5, 6, 7, 8, 9, 10], 4, codes => 1);
    # $codes->[2] is undef; the rest are binned as usual

Tied data and `duplicates`. Heavy ties can make adjacent cutpoints equal; the
default raises, `'drop'` merges:

    my @tied = ((0) x 8, 1, 2, 3, 4);
    qcut(\@tied, 4);                         # dies: bin edges are not unique
    my @edges = qcut(\@tied, 4, duplicates => 'drop');
    # fewer than 5 edges; the empty quantile bands are collapsed

Get the usage summary and stop:

    qcut('h');   # dies with the help text above

## quantile

Calculates sample quantiles using R's continuous Type 7 interpolation. 

    my $quantile = quantile('x' => [1..99], probs => [0.05, 0.1, 0.25]);

If the `probs` parameter is omitted, it behaves identically to R by defaulting to the 0, 25, 50, 75, and 100 percentiles (`c(0, .25, .5, .75, 1)`). The returned hash keys match R's standardized naming convention (e.g., `"25%"`, `"33.3%"`).

## rank

Rank values like R's `rank()`. Takes flat scalars and/or array refs (like `min`), with optional trailing `ties.method` / `na.last` options. Returns the list of ranks in input order.

    my @r = rank(3, 1, 4, 1, 5);                           # 3, 1.5, 4, 1.5, 5
    my @r = rank([3, 1, 4, 1, 5], 'ties.method' => 'min'); # 3, 1, 4, 1, 5

Ranks are 1-based; `average` may return half-ranks. `undef` and NaN are treated as NA.

### ties.method

How tied values share ranks (default `average`):

| value     | behavior                       | `rank(3, 1, 4, 1, 5)` |
| --------- | ------------------------------ | --------------------- |
| `average` | mean of the tied ranks         | 3, 1.5, 4, 1.5, 5     |
| `min`     | lowest rank in the group       | 3, 1, 4, 1, 5         |
| `max`     | highest rank in the group      | 3, 2, 4, 2, 5         |
| `first`   | ties keep input order          | 3, 1, 4, 2, 5         |
| `last`    | ties keep reverse input order  | 3, 2, 4, 1, 5         |
| `random`  | ties broken randomly (srand-aware) | varies            |

### na.last

How `undef`/NaN elements are placed (default `true`):

| value           | behavior                   | `rank(5, undef, 1, ...)` |
| --------------- | -------------------------- | ------------------------ |
| `true`          | NAs get the highest ranks  | 2, 3, 1                  |
| `false`         | NAs get the lowest ranks   | 3, 1, 2                  |
| `keep`          | NAs stay undef, in place   | 2, undef, 1              |
| `na` (or undef) | NAs dropped (shorter list) | 2, 1                     |

## Ronly

    my @right_only = Ronly(\@left, \@right);
    my $count      = Ronly(\@left, \@right);

Takes **exactly two** array references and returns the values in the right list
that are absent from the left list. Duplicates collapse, the result keeps
right-list order, and scalar context returns the count. Values are compared by
string form (see `get_union`). A non-array-ref argument, an `undef` element,
or anything other than two references is fatal. Mirrors `List::Compare`'s
`get_Ronly`, and is the reverse of `Lonly`: `Ronly(\@a, \@b)` equals
`Lonly(\@b, \@a)`.

    my @a = (1, 2, 3, 4);
    my @b = (3, 4, 5);
    my @r = Ronly(\@a, \@b); # (5)

## rbinom

Create a binomial distribution of numbers

    my $binom = rbinom( n => $n, prob => 0.5, size => 9);

## read_table

minimal example:

    my $test_data = read_table('t/HepatitisCdata.csv');

### options
| Option | Description | Example |
| -------- | ------- | ------- |
|`comment` | Comment character, by default `#`; lines beginning with it are skipped | `comment => '%'` |
|`output.type`| data type for output: array of hash, hash of array, or hash of hash | `'output.type' => 'aoh'`|
|`filter`| Only take in rows matching a filter | `filter => { Sex => sub {$_ eq 'f'} }`|
|`row.names` | include row names in retrieved data; off by default | |
|`sep` | field separator character; synonym with `delim`| `sep => "\t"` |
| `delim`| field separator character; synonym with `sep`| `delim => "\t"` |
output types can be AOH (aoh), HOA (hoa), HOH (hoh)
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
### commented-out headers
A header that is itself commented out is detected and used automatically, so
    # PDB	score
    1a2b	10
    3c4d	20
reads as though the header were `PDB, score` (the comment marker and any
following whitespace are stripped from the first column). A commented line is
only taken as the header when its field count matches the data, so ordinary
leading comments are never mistaken for one. You may name such a column in a
`filter` either as it appears in the file or by its clean name:
    read_table('ranks.tabular.tsv', filter => { '# PDB' => sub { $_ == 2 } });

## rename_cols

Return a new data frame with columns renamed — `df.rename(columns={...})`.
Columns not named are kept unchanged. The mapping may be given as
`old => new` pairs or as a single hashref. `AoA` frames have no column
labels, so `rename_cols` on an `AoA` dies (convert to `AoH`/`HoA` first).

    my $aoh = [ { a => 1, b => 2 }, { a => 3, b => 4 } ];
    rename_cols($aoh, a => 'x');
    # [ { x => 1, b => 2 }, { x => 3, b => 4 } ]

    my $hoa = { a => [1,4], b => [2,5] };
    rename_cols($hoa, { b => 'B' });
    # { a => [1,4], B => [2,5] }

A swap is fine because the target names stay distinct:

    rename_cols($aoh, a => 'b', b => 'a');   # columns exchanged

### views, speed, and memory

All three verbs return a **new frame** and never modify the source, but the
result is a **shallow view** built for speed on large frames:

  * the row shapes (`AoH`, `HoH`, `AoA`) build fresh row containers but
    **share the cell scalars** with the source — no per-cell copy;
  * `HoA` **shares the whole column arrayrefs**.

The operation itself never mutates the source. Because the underlying data is
shared, a later *in-place* change reaches the source: mutating a result cell
(`$r->[0]{a}++`, `chomp $r->[0]{a}`) or a `push`/`splice` on a result `HoA`
column will be visible through the original. Assigning a whole cell
(`$r->[0]{a} = ...`) is always safe. If you need a fully independent frame,
clone the result (e.g. `Storable::dclone`).

The row shapes run in XS, which shares cells and hashes each column key once
instead of once per row. Measured against the equivalent pure-Perl rebuild
(300k-row `AoH`, 8 columns):

    select 3/8 cols :  ~2x faster, and lower peak RAM (no copied cells)
    drop   2/8 cols :  ~3x faster
    rename 2/8 cols :  ~4x faster

`HoA` and `AoA`-by-drop are pure-Perl aliases and already near-free (a slice
of an 8-column, million-row `HoA` is sub-second). The memory saving grows
with rows × selected columns: at scale the row shapes allocate only the new
row containers, never a second copy of every cell.

### strictness

Mistakes are fatal rather than silently corrupting a frame (validated in Perl
before any XS runs):

  * a requested (or renamed) column not present anywhere dies;
  * a duplicate column in a `select_cols`/`drop_cols` list dies (a hash-keyed
    shape would otherwise collapse it);
  * a `rename_cols` whose targets are not distinct — two columns landing on
    one name — dies (checked against the whole column set, so an `a<->b` swap
    is fine but `a->b` onto an existing `b` is caught).

Shape is classified by the same `_df_shape` detector `agg` uses, so these
accept exactly the frames `agg`/`view` accept; as with that family the check
is `ref`-based, so hand it an unblessed frame.


## rnorm

Make a normal distribution of numbers, with pre-set mean `mean`, standard deviation `sd`, and number `n`.

    my ($rmean, $sd, $n) = (10, 2, 9999);
    my $normals = rnorm( n => $n, mean => $rmean, sd => $sd);

## rownames

Return the row names of a data frame, as a list (like R's `rownames`).
Only `HoH` carries genuine row labels; the other shapes are positional and
so yield 0-based indices, again matching `view`:

  * `AoA` / `AoH` — `0 .. $#$df` (one index per top-level element)
  * `HoA` — `0 .. longest_column-1`
  * `HoH` — the string-sorted outer keys (the row labels)

In scalar context it returns the count, so `scalar rownames($df)` equals
`nrow($df)` for a rectangular frame.

    my $hoh = { r2 => { x => 1 }, r1 => { x => 2 }, r3 => { x => 3 } };
    my @rows = rownames($hoh);        # ('r1', 'r2', 'r3')  -- sorted labels

    my $aoh = [ { a => 1 }, { a => 2 } ];
    my @rows = rownames($aoh);        # (0, 1)

    my $hoa = { a => [1,2,3], b => [4,5,6] };
    my @rows = rownames($hoa);        # (0, 1, 2)

    my $n = rownames($hoh);           # 3  (scalar context == nrow)

### notes

Shape is detected with the same `_df_shape` classifier `agg` uses, so both
functions accept exactly the frames `agg`/`view` accept. A ragged frame is
tolerated for enumeration: `colnames` spans the widest row and `rownames`
the longest column. An empty frame returns an empty list. Because the
classifier is `ref`-based (not `reftype`), pass an unblessed frame — blessed
frames are the one case `ncol`/`nrow` accept that this family does not.

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

## select_cols

Return a new data frame containing only the named columns, in the order
requested — the Stats::LikeR form of pandas `df[['a','b']]`. Works on all
four frame shapes. For `AoA` the identifiers are 0-based integer positions;
for `AoH`, `HoA`, and `HoH` they are column names. Columns may be given as a
list or as a single arrayref.

    my $aoh = [ { a => 1, b => 2, c => 3 },
                { a => 4, b => 5, c => 6 } ];
    my $sub = select_cols($aoh, 'a', 'c');
    # [ { a => 1, c => 3 }, { a => 4, c => 6 } ]

    my $hoa = { a => [1,4], b => [2,5], c => [3,6] };
    my $sub = select_cols($hoa, ['c', 'a']);   # order preserved
    # { c => [3,6], a => [1,4] }

    my $aoa = [ [1,2,3], [4,5,6] ];
    my $sub = select_cols($aoa, 0, 2);
    # [ [1,3], [4,6] ]

A column that appears in only some `AoH`/`HoH` rows is filled with `undef` in
the rows that lack it, so the selection comes back rectangular:

    select_cols([ {a=>1,b=>2}, {a=>3,c=>9} ], 'a', 'c');
    # [ { a => 1, c => undef }, { a => 3, c => 9 } ]

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

## uniq

Returns the distinct values of its arguments, in first-seen order.

	use Stats::LikeR;

	my @u = uniq(1, 2, 2, 3, 1);         # (1, 2, 3)
	my @s = uniq(qw/a b a c/);           # ('a', 'b', 'c')
	my @f = uniq(1, [2, 2, 3], [3, 4]);  # (1, 2, 3, 4)
	my $n = uniq(1, 2, 2, 3, 1);         # 3

`uniq` accepts a flat list of scalars, array references, or any mix of the
two. Array references are expanded **one level** — their elements are treated
as additional arguments, but nested array references are not recursed into and
are compared as opaque values.

Values are compared by stringification, the same `eq` semantics used by
`List::Util::uniq`: `1`, `1.0`, and `"1"` all collapse to a single result, and
the first value seen is the one returned (as a fresh copy, never an alias to
the input). Order of first appearance is preserved.

In list context `uniq` returns the distinct values. In scalar context it
returns the *count* of distinct values, matching `List::Util::uniq`.

The UTF-8 flag is part of the comparison key, so a UTF-8 string and a
byte-identical non-UTF-8 string are kept distinct — they are different strings.
Strings that are logically equal and consistently encoded collapse as expected.

Unlike `List::Util::uniq`, which passes a single `undef` through, `uniq`
**croaks** on any undefined value, reporting the offending argument index (and
the array-ref index, when the undef came from inside a reference):

	uniq(1, undef, 3);     # croaks: undefined value at argument index 1
	uniq([1, undef, 3]);   # croaks: undefined value at array ref index 1 (argument 0)

This matches the undef-handling of `mean` and the other functions in Stats::LikeR.

## vals

Extract a single column from a data frame as a flat array reference, similar to pandas' `to_list`

    my $ages = vals($df, 'age');

`vals` accepts all three data-frame shapes and always returns a new arrayref of that column's values:

- **AoH** (array of hashes) -- one value per row, in row order.
- **HoA** (hash of arrays) -- the named column array, copied.
- **HoH** (hash of hashes) -- one value per row, in **ascending key order** (a HoH has no inherent row order, so keys are sorted as strings).

### Arguments

| Position | Name | Description |
| --- | --- | --- |
| 1 | `$df` | An AoH (arrayref), or a HoA/HoH (hashref). The shape is auto-detected by peeking the first hash value: a hashref value means HoH, otherwise HoA. |
| 2 | `$col` | The column name (must be defined). |

### Behavior and notes

- **The result is a copy.** Every value is duplicated, so mutating the returned array never touches `$df`, and `undef` slots are ordinary writable scalars.
- **A missing cell is `undef`.** For AoH and HoH, a row that lacks the column (or isn't a hashref) yields `undef` for that row.
- **An absent column is strict only for HoA.** Because a HoA column *is* the structure, asking for a column the hash doesn't have dies. For AoH/HoH the column is per-row, so an entirely-absent column simply yields all-`undef` (it is not an error). This asymmetry is deliberate; pass the column name carefully for AoH/HoH, since a typo returns `undef`s rather than dying.
- **Empty frames return `[]`** -- an empty AoH or an empty hash both give a clean empty arrayref.
- UTF-8 column names and HoH keys are handled correctly (lookups use the key SV; HoH keys sort by Perl string order).

### Examples

    my $aoh = read_table('patients.csv');                 # array of hashes
    my $age = vals($aoh, 'Age');                           # [ 34, 51, ... ]

    my $hoa = read_table('patients.csv', 'output.type' => 'hoa');
    my $sex = vals($hoa, 'Sex');                           # copy of the Sex column

    my $hoh = read_table('patients.csv', 'output.type' => 'hoh');
    my $age2 = vals($hoh, 'Age');                          # values in sorted row-key order

    # feed straight into the numeric routines
    my $m = mean( vals($aoh, 'Age') );

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

### Array of hashes

    my @records = (
        { name => 'Alice', dept => 'Sales' },
        { name => 'Bob',   dept => 'Eng'   },
        { name => 'Carol', dept => 'Sales' },
    );
    my $vc = value_counts(\@records, 'dept');

with a key, the value at that key is counted in each hash, so the above returns `{ Sales => 2, Eng => 1 }`. A record that lacks the key is skipped. Passing an array of hashes without a key, or with an element that is not a hash reference, is a fatal error.

### Array of arrays
    my @rows = (['a', 1], ['b', 1], ['a', 2]);
    my $vc = value_counts(\@rows, 0);

when the elements are array references, the key is treated as a numeric column index, so the above returns `{ a => 2, b => 1 }`. A non-numeric index against array-reference elements is a fatal error.

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

The two new subsections (Array of hashes, Array of arrays) are the only additions; everything else is unchanged. They're placed after the array-container forms to keep array inputs grouped, mirroring how Hash of array / Hash of hash sit together. If you'd rather I drop this into a `.md` file or fold it into POD (`=head3` headers, `C<>` for the inline code) for the actual module docs, say the word.

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

## view

An R-style `head` for the structures `read_table` returns. Prints the first
few rows of a dataframe as an aligned text table, with numeric columns
right-justified, string columns left-justified, and undefined cells shown as
`NA`.

| Input type | Perl structure     | What `view` shows                          |
|------------|--------------------|--------------------------------------------|
| `aoa`      | array of array refs| values gathered column-wise by row index   |
| `aoh`      | array of hash refs | one line per row, sequential row numbers   |
| `hoa`      | hash of array refs | values gathered column-wise by row index   |
| `hoh`      | hash of hash refs  | top-level keys become the row label column |

### Synopsis

    my $aoh = read_table('all.data.tsv', 'output.type' => 'aoh');

    view($aoh);                       # first 6 rows, like head()
    view($aoh, n => 20);              # first 20 rows
    view($aoh, cols => [qw(id age tt)]);   # force a column order
    view($aoh, 'row.names' => 'id');  # use column 'id' as the row label
    view($aoh, na => '.', max_width => 30);

    my $txt = view($aoh, return_only => 1);  # capture the string, print nothing
    view($aoh, to => \*STDERR);              # print somewhere other than STDOUT

### Output

    # AoH: 7 rows x 3 cols  (showing 6)
    row_name  Testosterone, total (nmol/L)  age  sex
    p1                                18.2   41  M
    p2                                  NA    7  F
    p3                                1.05   33  F
    p4                                22.9   55  M
    p5                                  14   29  M
    p6                                  NA   62  F
    # ... 1 more row

The banner reports the structure type, full dimensions, and how many rows are
displayed. A footer appears only when rows are hidden.

### Arguments

All arguments after the data reference are optional name/value pairs.

| Argument        | Default | Meaning |
|-----------------|---------|-------------------------------------------------------------------------|
| `n`             | `6`     | Number of rows to show. `n` greater than the table shows everything.    |
| `rows`          | `6`     | Number of rows to show. `n` greater than the table shows everything  (synonymous with `n`)|
| `cols` / `columns` | —    | Array ref pinning column order (and which columns appear).              |
| `row.names`     | —       | Column to use as the row label (for `aoh`/`hoa`). See ordering note.    |
| `na`            | `'NA'`  | Token printed for undefined cells |
| `max_width`     | `80`    | Truncate any cell wider than this (column names are never truncated)   |
| `ellipsis`      | `'...'` | Marker appended to truncated cells |
| `gap`           | `2`     | Spaces between columns |
| `to`            | STDOUT  | Filehandle to print to.   |
| `return_only`   | `0`     | If true, return the string and print nothing |

`view` always returns the formatted string, whether or not it also prints.

### A note on column order

`read_table` stores rows as hashes, so the original CSV column order is not
preserved. `view` therefore sorts columns by name for a stable, reproducible
layout. Two conveniences soften this:

* A column literally named `row_name` (the label `read_table` assigns to a
  leading blank header) is detected automatically and moved to the left as the
  row label.
* Pass `cols => [ ... ]` to control both the order and the selection of columns
  shown.

When no label column is present, `view` numbers the rows `1, 2, 3, …`, the way
R prints row names for an unnamed data frame.

### Edge cases

* Empty input (`[]` or `{}`) prints a clean `0 rows x 0 cols` banner.
* Tabs, carriage returns, and newlines inside a cell are escaped (`\t`, `\r`,
  `\n`) so one record always stays on one line.
* A non-reference argument, or a hash whose values are plain scalars, dies with
  a clear message rather than producing garbled output.

### Tests

The behavior above is covered by `view.t` (run with `prove view.t`): the three
structure types, `n` boundaries, alignment, `NA` rendering, truncation,
`row.names`/`cols` handling, control-character escaping, the `return_only` and
`to` output paths, empty structures, and the error cases.

## wilcox_test

    $test_data = wilcox_test(
    	[1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
    	[0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
    );

Computes the Wilcoxon rank-sum / Mann-Whitney test (two samples) or the Wilcoxon signed-rank test (one sample or paired), following R's `wilcox.test` conventions.
This is an alternative to the t-test, that does not assume a normal distribution.
With two array refs and no `paired` flag it runs the two-sample rank-sum test; with a single sample, or with `paired => 1`, it runs the signed-rank test. It calculates exact p-values by default for `N < 50` without ties; when ties (or, for the signed-rank case, zero differences) are present it automatically switches to the normal approximation with continuity correction.

### Calling conventions

The first one or two array-ref arguments are taken positionally as `x` and `y`; everything after that is parsed as `key => value` pairs. The named forms `x =>` and `y =>` are also accepted and override the positional values. The flat argument list following the positional refs must contain an even number of elements, or the call dies with a usage message.

    # positional
    wilcox_test(\@x, \@y, paired => 1);

    # fully named
    wilcox_test(x => \@x, y => \@y, alternative => "greater", exact => 0);

### Input parameters

| Parameter     | Type            | Default      | Description |
|---------------|-----------------|--------------|-------------|
| `x`           | ARRAY ref       | *(required)* | The first sample. Passed positionally or as `x =>`. Non-numeric and undefined elements are silently dropped; an empty or all-missing `x` is fatal. In the two-sample test `mu` is subtracted from each `x` value. |
| `y`           | ARRAY ref       | `undef`      | The second sample. If present and `paired` is false, a two-sample rank-sum test is run. If `paired` is true, `y` is required and must be the same length as `x`. Omit it for the one-sample signed-rank test. |
| `paired`      | boolean         | `0` (false)  | Run a paired signed-rank test on the per-element differences `x[i] - y[i] - mu`. Requires `y` of equal length. |
| `correct`     | boolean         | `1` (true)   | Apply the continuity correction (±0.5) when using the normal approximation. Ignored when an exact p-value is computed. |
| `mu`          | number          | `0.0`        | Null-hypothesis location shift. Subtracted from `x` (two-sample) or from each difference (one-sample / paired). |
| `exact`       | boolean / undef | `undef` (auto) | Tri-state. `undef` (or absent) selects exact automatically: when both group sizes are `< 50` and there are no ties (two-sample), or `n < 50` with no ties (signed-rank). A true value forces the exact test, a false value forces the approximation. Exact is impossible with ties — or, for the signed-rank test, with zero differences — and falls back to the approximation with a warning. |
| `alternative` | string          | `"two.sided"` | One of `"two.sided"`, `"less"`, or `"greater"`. Selects the tail(s) used for the p-value. |

### Output

Returns a hash ref with the following keys:

| Key           | Type   | Description |
|---------------|--------|-------------|
| `statistic`   | number | The test statistic. For the two-sample test this is the Mann-Whitney **W** (the `x` rank sum minus `nx*(nx+1)/2`). For the signed-rank test it is **V**, the sum of the ranks assigned to the positive differences. |
| `p_value`     | number | The p-value for the chosen `alternative`, capped at `1.0`. Two-sided p-values are `2 * min(p_less, p_greater)`. |
| `method`      | string | A human-readable description of the exact test variant that was run (see below). |
| `alternative` | string | Echoes the `alternative` actually used (`"two.sided"`, `"less"`, or `"greater"`). |

The `method` string reports which path executed:

- Two-sample: `"Wilcoxon rank sum exact test"`, `"Wilcoxon rank sum test with continuity correction"`, or `"Wilcoxon rank sum test"`.
- One-sample / paired: `"Wilcoxon exact signed rank test"`, `"Wilcoxon signed rank test with continuity correction"`, or `"Wilcoxon signed rank test"`.

### Notes and edge cases

Missing data is handled by listwise removal of non-numeric / undefined cells before ranking; in the paired case a pair is dropped if either member is missing. An empty `x` (or, in the two-sample case, an empty `y`) after this filtering is fatal.

For the signed-rank test, exact zero differences are discarded before ranking (matching R), and their presence disables the exact computation. Both empty-after-filtering and all-zero-difference inputs are fatal.

Ties are detected during ranking and trigger the tie-corrected variance in the normal approximation; they also rule out the exact p-value. When `exact` is left on auto, the size thresholds (`< 50` per group, or `< 50` differences) are what gate the exact vs. approximate decision.

## write_table

mimics R's `write.table`, with data as first argument to subroutine, and output file as second

    write_table(\@data_aoh, $tmp_file, sep => "\t", 'row.names' => 1);

`write_table` accepts every data-frame shape: a flat hash (one row), a hash of arrays (HoA), a hash of hashes (HoH), an array of hashes (AoH), and an array of arrays (AoA). For an AoA the first inner array is taken as the header row unless `col.names` is given, in which case every inner array is treated as data:

    write_table([[qw(gene score)], ['TP53', 0.9], ['BRCA1', 0.7]], $tmp_file, 'row.names' => 0);
    write_table([['TP53', 0.9], ['BRCA1', 0.7]], $tmp_file, 'col.names' => [qw(gene score)]);

You can also precisely filter and reorder which columns are written by passing an array reference to `col.names`:

    write_table(\@data, $tmp_file, sep => "\t", 'col.names' => ['c', 'a']);

undefined variables are printed as `NA` by default, but can be set as you wish using `undef.val`

    write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan')

as of version 0.07, `write_table` determines comma and tab-separated delimiters from the filename, but will override if `sep` or `delim` are explicitly set.

Args can also be accepted:

    write_table( 'data' => \%flat, 'file' => $f );

### LaTeX output (`tex`)

`write_table` can write the output file as a LaTeX `tabular` instead of a delimited table. This is selected either by naming the file `*.tex` (auto-detected) or by passing `tex => 1`; an explicit `tex => 0` forces a delimited file even when the name ends in `.tex`. The LaTeX table is built from the same rows as the delimited writer, so it works for every shape above (including arrays of arrays):

    write_table(\@data_aoh, 'table.tex');            # .tex name selects LaTeX
    write_table(\@data_aoh, $tmp_file, 'tex' => 1);  # force LaTeX for any name

The file begins with a `%written by <cwd>/<script>` provenance comment (the working directory and script name). The header row is bold and the table is ruled with `\hline`. Cell text is LaTeX-escaped: `#`, `_`, `%`, and `&` are backslash-escaped, `>` becomes `\textgreater{}`, and a cell consisting solely of `\includesvg{...svg}` is passed through untouched. The `tex.*` options tune the output:

    write_table(\@rows, 'table.tex',
        'tex.col.align'    => 'l',                   # 'c' (default), 'l', or 'r'
        'tex.bold.1st.col' => 0,                     # default 1: bold the first column
        'tex.format'       => 1,                     # %.4g-format numeric cells
        'tex.size'         => '\small',              # size directive after \begin{tabular}
        'tex.comment'      => ['run 3', 'q < 0.05'], # % comment line(s): string or array ref
    );

The `xlsx`, worksheet, and JSON side outputs of the original stand-alone routine are not included.

### Options

| option | default | applies to | meaning |
|---|---|---|---|
| `data` (1st positional, or `data =>`) | *required* | both | the table: flat hash, HoA, HoH, AoH, or AoA |
| `file` (2nd positional, or `file =>`) | *required* | both | output path; written as a delimited table, or as LaTeX when `tex` is on |
| `sep` / `delim` | from extension (`,` for `.csv`, tab for `.tsv`), else `,` | delimited | field separator; the two are aliases |
| `row.names` | `1` (on) | both | true prepends a label column (numeric index, or the outer key for a HoH); `0` omits it; for a HoA/AoH a non-numeric *column name* uses that column's values as the labels and drops it from the body |
| `col.names` | all columns, sorted | both | array ref selecting and ordering columns; for an AoA it also supplies the column names |
| `undef.val` | `''` (empty field) | both | text written for an undefined/missing cell, e.g. `'NA'` |
| `tex` | auto: `1` when `file` ends in `.tex`, else `0` | LaTeX | write the output file as a LaTeX `tabular` instead of a delimited table; `tex => 0` forces delimited even for a `.tex` name |
| `tex.col.align` | `'c'` | LaTeX | per-column alignment: `'c'`, `'l'`, or `'r'` |
| `tex.bold.1st.col` | `1` (on) | LaTeX | bold the first column of each data row |
| `tex.format` | `0` (off) | LaTeX | render numeric cells with `%.4g` |
| `tex.size` | *(none)* | LaTeX | size directive emitted after `\begin{tabular}`, e.g. `\small` |
| `tex.comment` | *(none)* | LaTeX | `%` comment line(s) at the top of the LaTeX file: a string, or an array ref of strings |

# Changes

## 0.22 2026-07-07 CDT

returned `Devel::Confess` to required dependencies to fix for CPAN testers.

## 0.21 2026-07-07 CDT

Better warning message for undefined data for `aoh2hoh`, `assign`, `dropna`

addition of `agg`, `concat`, `drop_cols`, `rank`, `rename_cols`, `select_cols` functions

Improving Kwalitee (sic): added `[PodWeaver]` to dist.ini; as well as `Changes` file

### assign

`assign` now accepts two kinds of column value, so a function that already returns a whole column (like `rank`) drops in without wrapping.

- **Per-row coderef** (unchanged): called once per row, `$_` is the row, and the single scalar it returns is the cell. A single arrayref return is still stored *as the cell*, so arrayref-valued columns keep working.
- **Whole-column coderef** (new): if the coderef returns a *list* of more than one value, that whole list becomes the column, laid down positionally. This is what makes `'ΔG rank' => sub { rank( vals($df, 'dG_kcal_mol') ) }` work directly — no `[ ... ]` needed.
- **Arrayref value** (new): a ready-made column, e.g. `col => [ rank(...) ]`, copied into the frame.

The coderef is probed once (row 0 for AoH/HoH, the first synthesized view for HoA) to decide per-row vs whole-column, so per-row code is never run twice on row 0. Every column value is length-checked against the row count and a mismatch dies. **HoH** is now a supported, documented shape alongside AoH and HoA; whole-column and arrayref values align to **sorted key order**.

Tests: `assign.t` (AoH + HoA) and `assign_HoH.t` were expanded to cover every shape × value-kind combination — per-row scalar, whole-column list, arrayref value, single-arrayref-as-cell, `rank()` integration, chaining, `$_[1]` index, `$_[2]` row key (HoH), overwrite, ragged HoA columns, empty frames, length-mismatch and bad-value / odd-arg / non-hash-row death paths, and `no_leaks_ok` guards on the new whole-column and arrayref paths.

### read_table

Fixed handling of commented-out header lines and made filter columns
referenceable by the name as it appears in the file.

- **Commented-out header recovery.** `_parse_csv_file` treats a line whose
  comment marker is followed by whitespace (e.g. `# PDB<TAB>score`) as a
  comment and drops it, so a header written that way never reached the
  callback and the first *data* row was silently mistaken for the header.
  `read_table` now recovers it: the first physical line, if it is
  `marker + whitespace` and splits into two or more fields, is held as a
  candidate header and confirmed only when its field count matches the first
  data row. If the counts disagree the candidate was an ordinary leading
  comment and is discarded, so a prose comment that happens to contain the
  separator (e.g. `# note, see README`) is never mistaken for a header. A
  marker hugging its text (`#id,val`) is delivered by the parser and
  un-commented in the callback as before. The marker and any following
  whitespace are stripped, so `# PDB` is stored as the clean name `PDB`.

- **Filter columns may be named as written in the file.** Filter keys are
  matched against the header by exact name first, then retried with the
  leading comment marker (and surrounding whitespace) stripped, so a
  commented-header column resolves whether it is referenced as `# PDB` or by
  its clean name `PDB`:

        read_table(
            'regression_rank.tabular.tsv',
            filter => { '# PDB' => sub { $_ == 2 } },
        );

- **Clearer "column not found" error.** The failure now names the file and
  lists the actual header instead of printing it to STDOUT (a library
  shouldn't print):

        read_table: Filter column 'nope' not found in the header of FILE;
        header is: 'PDB', 'score'

## 0.20

addition of `ncol`, `nrow`, and `pnorm` functions

`filter` can filter by row names with `$_[1]`

`view` now accepts array of arrays in addition to AoH, HoA, and HoH

### csort

Two behavioural changes, both contained to the `csort` XSUB (the `cs_*` helpers are untouched).

**Row names survive a Hash-of-Hashes sort.** Sorting a HoH previously discarded the outer keys. Now each row is folded into a *fresh* row hash (a private container over aliased, read-only cells) that carries its outer key under a `row.name` column, so the name flows into whichever shape you request:

    my $hoh = { alpha => { id => 1 }, beta => { id => 2 } };

    csort($hoh, 'id');          # AoH: each row gains a row.name field
    csort($hoh, 'id', 'hoa');   # HoA: an aligned row.name column

- The column name defaults to `row.name` and can be overridden with an optional 4th argument (mirroring `hoa2hoh`'s named-key style): `csort($df, 'id', 'aoh', 'sample')`.
- The outer key is authoritative — it wins over any pre-existing same-named field in the row.
- Once present, the column is sortable like any other: `csort($hoh, 'row.name')`.
- Because rows are now *copied* rather than shared, the caller's HoH is never mutated by the injection. (Minor behaviour change: output rows are no longer the same refs as the source rows.)

**Clearer usage message.** The signature is now `csort(...)`, so xsubpp no longer emits the misleading auto-generated `Usage: Stats::LikeR::csort(data, by, output=&PL_sv_undef)`. Argument count is checked by hand, and the croak now shows both real calling forms:

    Usage: csort($df, 'column.name', 'HoA')
       or  csort($df, sub { $b->{'No.'} <=> $a->{'No.'} }, 'hoa')
      (optional 4th arg names the row-name column when sorting a HoH; default 'row.name')

`data`/`by`/`output` are read as `ST(0..2)`; `output` still defaults to matching the input shape.

**Tightened validation messages.** The `$data` croak now reads `hash-ref (HoA or HoH)`, and the `$by` croak includes a concrete example: `a column name (e.g. 'No.') or a comparator code-ref using $a and $b, e.g. sub { $b->{'No.'} <=> $a->{'No.'} }`. Existing HoA croaks (`unequal lengths`, `not found`, `not an array-ref`) are unchanged.

When sorting, undefined values in the sorting column are placed at the bottom

### cor

Fixed an unsigned-integer underflow in `kendall_tau_b` and added a regression test.

#### Bug

In `kendall_tau_b`, concordant/discordant counts `C` and `D` are declared `size_t` (unsigned). The numerator was computed as:

    return (NV)(C - D) / denom;

The subtraction `C - D` happens in unsigned arithmetic *before* the cast to `NV`. When discordant pairs dominate (`D > C`), the result wraps to a huge positive value instead of going negative.

For the arrays:

    dG_kcal_mol:  -7.765, -9.328, -10.326, -9.038, -9.608, -9.779, -9.975, -6.906
    anomaly_rank: 154, 155, 161, 188, 76, 172, 173, 69

there are `C = 9` concordant and `D = 19` discordant pairs (no ties). `9 - 19` wraps to `18446744073709551607`, so the function returned ~`6.6e17` instead of the correct `-10/28 = -0.3571428571`.

#### Fix

Cast each operand to `NV` before subtracting, so the arithmetic is signed:

    return ((NV)C - (NV)D) / denom;

Only that one line changed. The denominator sums (`C + D + tie_x`, `C + D + tie_y`) are non-negative, so they were left as-is.

#### Regression test — `cor.t`

- Kendall on the offending arrays pinned to `-0.3571428571`.
- Explicit `[-1, 1]` range guard (the real backstop — the pre-fix value `~6.6e17` blows past the bound regardless of exact magnitude), plus a negative-sign assertion.
- Pearson (`-0.4889102301`), Spearman (`-0.4761904762`), and default-method coverage of the three `compute_cor` branches.
- Kendall boundary cases: perfectly concordant (`+1`), perfectly discordant (`-1`), self-correlation (`+1`), and a tie case exercising `tie_x` in the denominator.
- `no_leaks_ok` per method (guarded with `unless $INC{'Devel/Cover.pm'}`).
- Croak paths: length mismatch, unknown method, zero-variance input.

### XS refactor

Consolidate helper functions to reduce binary size, find bugs, and back the changes with tests. Every change was validated by translating the XS (`ExtUtils::ParseXS`) and compiling the result
with the module's own `ccflags`.

#### Outcome

- **Net change to the source:** ~154 fewer lines; helper-function count down by 4 (7 removed, 3 added).
- **Genuine bugs fixed:** two instances of the same latent defect (see below). The rest of the work was behavior-preserving consolidation.

#### Function consolidation

| Change | Before | After |
|---|---|---|
| Three-way `NV` comparator | `compare_rank`, `cmp_rank_item`, `cmp_rank_info`, `compare_NVs` | single `cmp_nv3` (reads the leading `NV` member, valid for `RankInfo`/`RankItem`/raw `NV`) |
| Average-rank routine | `compute_ranks` + `compare_index` restoration sort | existing `rank_data` (scatters ranks into `out[idx]`, no second sort) |
| String comparator | `cmp_string_wt`, `lm_str_qsort` (byte-identical) | single `cmp_string_wt` |
| Set difference | `Lonly` + `Ronly` (duplicated bodies) | shared `set_difference()`; `Ronly` passes the arrays swapped |
| Multiplicity filter | `intersection` + `get_unique` (~90% shared) | shared `set_multiplicity()` with an "all vs. one" mode flag |

All merges were confirmed behavior-preserving: the collapsed comparators are
equivalent on ordinary values, `NaN`, and infinities, and `compute_ranks` and
`rank_data` produce identical average ranks.

#### Bugs

Two comparators stabilized their sort by returning `a->idx - b->idx` directly,
where the index field is an unsigned `size_t`. The subtraction wraps and is then
truncated to `int`, which is implementation-defined and gives the wrong sign
once a difference exceeds `INT_MAX`.

- `compare_index` — removed entirely (the routine that used it, `compute_ranks`, was replaced by `rank_data`).
- `cmp_pval` — the tie-break comparator in the p-adjust path. **Missed in the initial review; found later** via a `-Wconversion` compile of the earlier source. Fixed to compare with the `(a > b) - (a < b)` idiom.

**Caveat on severity:** on every mainstream ABI (LP64, LLP64, ILP32), the
low-word truncation happens to reproduce the correct sign for any array smaller
than ~2^31 elements, so this never produces a wrong result at realistic sizes.
It is a portability/UB issue, not a runtime failure, which is why no functional
test detects it (see "Testing", below).

 `LikeR.xs` — consolidated helpers; `compare_index` removed; `cmp_pval` fixed.

### `view`
 non-ASCII characters now print

### `write_table`

new option to output to LaTeX table

## 0.19

numerous `SSize_t var1 = av_len(var) + 1` are changed to `size_t var1 = av_len(var) + 1` as `size_t`; as the result cannot be negative, in order to expand numerical range

Addition of `hoa2hoh`, `binom_test`, `chunk`, `get_union`, `get_unique`, `Lonly`, `Ronly`, `qcut`, and 3 tukey functions

Better warnings when non-array references are given to `intersection`

`view` now breaks columns into chunks for very wide data sets, more closely matching R's behavior

## 0.18

`restrict` keyword added to numerous places within `intersection` to decrease CPU time

fix to dist.ini for dependencies

fixed POD rendering

## 0.17

addition of `assign`, which adds new columns based on calculations from other columns

addition of `hoa2aoh`, transforming hash of arrays to array of hashes

addition of `predict`, using results from `aov`, `glm`, and `lm`

addition of `aoh2hoh` transforming array of hash into hash of hashes, `intersection`, `uniq`, and `vals`

### `aov`

#### Bug fixes
- **`size_t` underflow on empty arrays.** Three loops were bounded by `av_len(...)`
  compared against an unsigned counter; `av_len` returns `-1` for an empty array,
  which turned `k <= len` into a `SIZE_MAX` loop. The `stack()` value loop, the `.`
  column-expansion loop, and the `group_stats` column loop now use a signed
  `SSize_t` bound.
- **HoH row count.** Row count for hash-of-hashes input was taken from the return
  value of `hv_iterinit`; it now uses `HvUSEDKEYS(hv)` with a separate
  `hv_iterinit`, matching `predict`.
- **Buffer overflow in interaction parsing.** `strcpy(right, colon + 1)` into a
  fixed `char right[256]` is now `snprintf(right, sizeof(right), ...)`.

#### Performance / memory
- **Removed the per-row `row_x` scratch allocation.** Design rows are built
  directly into `X_mat[valid_n]`; `valid_n` simply does not advance on a rejected
  row. Interaction columns read their operands from the same in-progress row, so
  the logic is unchanged.
- **`row_names` is no longer dead.** Surviving row names are transferred (pointer
  move, no copy) into `surv_names` to key `fitted.values`; rejected rows are freed
  in place.
- **Dropped a `restrict` UB.** `orig_data_sv` aliases `data_sv`; the `restrict`
  qualifier was removed.

#### New, `predict`-compatible output keys
- **`coefficients`** — OLS estimates recovered by back-substitution on the R factor
  left in `X_mat` against Q'y in `Y` (no re-derivation). Keys are the expanded term
  names (`Intercept`, continuous names, `base.level` dummies, and `a:b` interaction
  products). Aliased columns are reported as `NaN`, which `predict` drops.
- **`fitted.values`** — `Xb` over the non-aliased columns, keyed by surviving row
  name. Computed from a snapshot of the design (`Dsav`) taken before the QR
  overwrites `X_mat`. Costs one transient copy of the design matrix; negligible for
  typical ANOVA where the column count is small.
- **`xlevels`** — sorted level list per factor, index 0 = reference, aligned with
  the contrast coding used to build the dummies.
- **`family`** — `"gaussian"`.

#### Cleanup-path correctness
- `xlevels_hv`, `Dsav`, and `surv_names` are freed on both the "0 degrees of
  freedom" croak and the normal exit. The interaction-main-effects croak in
  PHASE 3 also frees `xlevels_hv`.

#### Known limitations (unchanged)
- The intercept-stripping string surgery (`-1`, `+0`, `+1`, ...) operates on the
  whole RHS and can still mangle `I(x-1)`-style transforms; treat `I()` with
  arithmetic constants carefully.
- Top-level keys `coefficients` / `fitted.values` / `xlevels` / `family` /
  `group_stats` share the return hash with the ANOVA rows; a predictor literally
  named one of those would collide.

### `predict`

#### New: factor-bearing interaction terms
Previously, interaction coefficients such as `GroupB:Sexmale` or `GroupB:x` fell
through to the continuous `evaluate_term` path and died on a nonexistent column.
They are now handled directly:

- **`dummy_hv`** stores each dummy's factor base index (an `IV`) instead of
  `&PL_sv_yes`, so a dummy name maps back to its `(base, level)` in O(1)
  (`level == name + strlen(base)`). `hv_exists` lookups are unaffected.
- During coefficient caching, any `:` term with at least one factor-dummy component
  is routed to a separate list (`icopy` / `ibeta`); pure-continuous interactions
  (e.g. `x:z`) stay on the existing `evaluate_term` path, so prior behavior is
  preserved.
- Each routed term is parsed once into flat component arrays. Factor components
  store a base index and level pointer; continuous components store the term string
  and get the same up-front column-existence validation as main terms.
- Per row, each factor's raw level is read once into `raw_lv[]` and reused by both
  main effects and interactions (no duplicate `get_data_string_alloc`). An
  interaction's value is the product of its components: a factor component
  contributes `1.0` iff the row's level matches the dummy's level (reference levels
  give `0`), continuous components go through `evaluate_term`.

This covers factor×factor, factor×continuous, continuous×continuous, and n-way
combinations.

#### Other
- HoH row count uses `HvUSEDKEYS` (already present).
- The unseen-factor-level croak now frees every level string already read for the
  current row, not just the current one.

### Tests

- **`aov.t`** — one-way ANOVA against hand-computed values (Df / Sum Sq / Mean Sq /
  F / decomposition); identical results across HoA / HoH / AoH / stacked input;
  simple regression; `.` expansion; intercept removal (`-1`); two-way with
  interaction (Type I SS on a balanced design); NaN listwise deletion; all croak
  paths; leak checks.
- **`predict.t`** — `predict(training) == fitted.values` round-trips for one-way,
  regression, factor×factor, factor×continuous, and continuous×continuous models;
  explicit predicted values; agreement across HoA / AoH / HoH / flat newdata;
  no-newdata path; binomial `link` vs `response`; gaussian identity link; all croak
  paths; leak checks.

Leak tests use `no_leaks_ok` guarded by `unless $INC{'Devel/Cover.pm'}` and skipped
when `Test::LeakTrace` is absent.

#### Assumptions worth confirming
- The NaN-deletion test relies on `evaluate_term` returning `NaN` for a non-finite
  response value (an `Inf - Inf` NaN is fed in deterministically).
- The continuous×continuous round-trip relies on `evaluate_term("x:z")` yielding
  `x * z` — the same assumption the pre-existing `predict` continuous-interaction
  path already made. If that path was untested, this round-trip now exercises it.

### `view`

now returns colored output; fixed bug with incorrect widths; undefined values show as `undef` rather than `NA`, as in Data::Printer

### `csort`

now accepts Hash of Hashes; addition of `restrict` which should decrease calculation time

### filter

- **Added hash-of-hashes (HoH) input.** In addition to AoH and HoA, `filter` now accepts an HoH (`{ key => { col => val, ... }, ... }`); each inner hash is one row, and matching keys are preserved by default (HoH -> HoH).
- **Added `output.type`.** `filter($df, $pred, 'output.type' => 'aoh'|'hoa')` selects the returned shape (aliases `out` / `output_type`; a bare positional type also works). When omitted, the input shape is preserved. `hoh` is not a selectable output, since it would require choosing a key column.
- **`col()` reworked, not removed.** Both predicate forms are kept: `col('age') >= 18` still works and is the concise/composable option, while a coderef covers everything else. Internally `col()` is now **pure Perl** — an overloaded class that builds a per-row closure — and `filter` unwraps that closure so `col()` and a coderef share one evaluation path. The previous standalone XS predicate evaluator (`filt_eval`/`filt_ctx`) is gone; delete it if your tree still has it. One consequence: a `col()` comparison now costs the same per row as the equivalent coderef (a Perl call), rather than being evaluated in C.
- **Unchanged guarantees:** the input frame is never modified; `undef` (and, for numeric ops, non-numeric) cells never match a `col()` comparison; AoH/HoH rows are shared rather than copied where possible; keep-all/keep-none shapes are well defined per output type; Perl 5.10 compatibility is retained. A latent `SvTRUE(POPs)` double-evaluation in the per-row call helper (which crashed on perls where `SvTRUE` is a multi-eval macro) was fixed along the way.

### read_table

Added an opt-in `auto.row.names` argument so `read_table` can read the file R
produces by default from `write.table(x, sep="\t")`.

#### The problem

R's `write.table` defaults to `row.names=TRUE, col.names=TRUE`, which writes the
row-names column in every data row but emits **no header label for it**. So a
frame with N columns comes out as N header fields over N+1 data fields — e.g.
`mtcars` gives 11 headers but 12-field rows. By default `read_table` (correctly)
rejects that as ragged:

    Alignment error on mtcars.tsv data row 1 (12 fields vs 11 headers).

#### The change

`auto.row.names` turns on R's own `read.table` rule: **when, and only when, the
header is exactly one field short of the data rows, treat the first field of
each row as an (unlabelled) row-names column.**

    # default: the leading column is named 'row_name'
    my $df = read_table('mtcars.tsv', 'auto.row.names' => 1);

    # or give it a name
    my $df = read_table('mtcars.tsv', 'auto.row.names' => 'model');

The synthesized column behaves like any other first column: it appears in `aoh`
and `hoa` output, and for `hoh` it becomes the default key (so rows are keyed by
the model name). This also lines up with the existing handling of R's
`col.names=NA` output (a blank leading header), which still produces a
`row_name` column with no flag needed.

#### What did not change

The strict alignment check is still the default. Without `auto.row.names` the
lopsided file still croaks, and even with it, a row that is off by anything
other than exactly one field still croaks — so the corruption guard only relaxes
for the one case R itself treats specially.

Tested in `t/read_table.2.t` (16 assertions, Perl 5.10.1 and 5.38): aoh / hoa /
hoh output, custom column name, the already-aligned file (flag is a no-op), the
`col.names=NA` path, and the strict / ragged croak paths.

#### additional bugfix

    # This is a comment
    id,name,val
    1,Alice,10.5
    2,Bob,
    3,Charlie,15.2

would not be read correctly using `read_table`, but now is read correctly

### value_counts

now accepts array of hashes

## 0.16

changes to dist.ini, the minimum Perl version disappeared when I fixed other problems

clarifications between run time and test dependencies

addition of `csort` function to sort AoH and HoA

addition of `aoh2hoa` to translate array of hashes into a hash of arrays

fix of long double functions: https://www.cpantesters.org/cpan/report/5d5d9836-6a5f-11f1-aadb-63fd6d8775ea

### `glm`

output residual keys now use names, not integers

### `lm`

### Bug fixes

**Memory leak on the zero-degrees-of-freedom error path.** When
`valid_n <= p`, the cleanup freed the `valid_row_names` *array* but not the
per-row name strings it held (those had been transferred out of `row_names`,
whose own array was already freed). The strings leaked on every such error.
Added the per-entry `Safefree` loop before freeing the array, matching the
normal path.

**HoH input validated only the first row.** Only the first hash value was
checked to be a `HASHREF`; subsequent values were `SvRV`'d unconditionally, so
a malformed row (`{ a => {...}, b => 5 }`) dereferenced a non-reference. Every
row is now validated, with the partial allocations cleaned up before the
`croak`, mirroring the existing AoH path.

**`isspace` on a possibly-signed `char`.** `isspace(*src)` is undefined for
byte values ≥ 0x80 on platforms where `char` is signed. Cast to
`(unsigned char)` before the call.

### Speed / RAM improvements

**Formula buffer is now heap-allocated to fit.** `char f_cpy[512]` silently
truncated any longer formula. Replaced with a buffer sized to
`strlen(formula) + 1`, so there is no fixed limit and no truncation.

**`.`-expansion buffer is now a growable heap buffer.** `char rhs_expanded[2048]`
silently dropped expanded terms once full. It is now a buffer that doubles on
demand. Appends also went from `strcat` (which rescans from the start every
time — O(n²) over many columns) to an O(1) amortised append that tracks the
write position.

**No more per-row scratch allocation in matrix construction.** The original
`safemalloc`'d a `row_x` buffer, filled it, copied it into `X`, and freed it
*for every row* — `n` allocations plus `n*p` copies. Each candidate row is now
written straight into `X` at its prospective commit slot; a row that fails
listwise deletion is simply overwritten by the next candidate. This removes the
`n` allocate/free cycles and the copy loop entirely.

**Categorical levels sorted with `qsort`.** The level list used an O(n²) bubble
sort; replaced with `qsort` (relevant only for high-cardinality factors).

**Unused tail of `X` reclaimed after listwise deletion.** `X` is allocated for
all `n` rows up front (`valid_n` is unknown until rows are scanned). When rows
are dropped, `X` is now `Renew`ed down to `valid_n * p`, returning the unused
tail to the allocator before the OLS phase.

**Minor robustness.** The argument-parsing index was widened from
`unsigned short` to `I32` to match `items`, and the HoH row count now uses
`HvUSEDKEYS` rather than relying on `hv_iterinit`'s return value.

### Known limitations (left unchanged)

- A multi-way term such as `a*b*c` is split only on the first `*`, so it yields
  `a`, `b*c`, and `a:b*c` rather than a full three-way expansion. Deeper
  interactions silently fail (the unparsable term evaluates to `NaN` and the
  rows are dropped). This matches the documented two-way `*` support.
- HoA input takes the row count from the first column; columns shorter than
  that simply contribute dropped rows rather than raising an error.

### `oneway_test`

#### Bug fixes

**Memory leaks on error paths.** Nearly every `croak` after an allocation
leaked memory. `croak` does a `longjmp`, so anything allocated but not yet
freed is lost. Affected paths:

- AoA and hash first-pass errors leaked `sizes` and any `gnames[]` entries
  allocated so far.
- Formula-mode "not found as an array ref" errors leaked `lhs` and `rhs`.

All post-allocation errors now route through a single `fail:` label that frees
every pointer unconditionally. Pointers are initialised to `NULL` and `gnames`
is zero-allocated with `Newxz`, so the cleanup is always safe to run.

**Undefined and non-numeric cells silently coerced to `0.0`.** The original
second pass used `(svp && *svp) ? SvNV(*svp) : 0.0`, meaning an `undef` or
non-numeric cell was quietly treated as zero, silently corrupting the
F-statistic. Each cell is now validated with `SvOK` and `looks_like_number`;
the call dies naming the group and observation index, consistent with the rest
of `Stats::LikeR` (`mean`, `sum`, `cor`, etc.).

**Unsigned wraparound on empty array input.** `k = (size_t)av_len(in_av) + 1`
cast to `size_t` *before* adding, so an empty array (`av_len` returns `-1`)
produced `SIZE_MAX` rather than `0`. Changed to
`k = (size_t)(av_len(in_av) + 1)` so the `+1` is done in signed arithmetic
before the cast.

**Unreliable group count from `hv_iterinit`.** `hv_iterinit` returns the
number of buckets in use rather than the number of keys for tied hashes.
Replaced with `HvUSEDKEYS`, which always returns the correct key count.

#### Improvements

**`var.equal` accepted as an alias for `var_equal`.** R users write
`var.equal`; the argument parser now accepts both spellings.

**Perl memory API used throughout.** `safemalloc` and manual `memcpy` replaced
with `Newx`, `Newxz`, `savepv`, and `savepvn`. `savepvn` additionally
preserves embedded NUL bytes in group key strings, which the previous
`strlen`-based copies silently truncated.

#### Known limitations (not changed)

- A factor column named `Residuals` or `group_stats` in a formula call will
  collide with reserved top-level keys in the result hash.
- Group names containing an embedded NUL are stored correctly but are still
  truncated at `strlen` when written into the output hash keys.

### `view`

default view shifted to 80 characters to match Linux window length

#### New features

- **`rows` is accepted as a synonym for `n`** (the number of rows shown).
  Passing both `n` and `rows` is an error.
- **Unknown arguments are now rejected.** `view` validates its argument names
  against the documented set (`n`, `rows`, `na`, `max_width`, `ellipsis`,
  `gap`, `cols`, `columns`, `to`, `return_only`, `row.names`, `row_names`) and
  dies listing any it does not recognise, so a misspelt option (e.g. `widht`)
  is caught instead of silently ignored.
- **`n` / `rows` is validated.** It must be a non-negative integer; `undef` or
  a non-numeric value now dies with a clear message instead of producing
  warnings and being treated as `0`.
- **flat/simple hashes are accepted as input**

#### Bug fixes

- **`n => 0` now still prints the column header.** Column names were collected
  only from the rows being shown, so requesting zero rows produced an empty
  header line. At least one row is now scanned (when data exists) so the
  header always lists the columns.
- **An empty hash (`{}`) no longer dies.** It was rejected as
  *"neither ARRAY nor HASH"*; it is now shown as an empty table
  (`0 rows x 0 cols`), matching the handling of an empty array.
- **The `row_names` alias now drives the Hash-of-Hashes label header.** The
  header for the row-label column consulted only `row.names`, so
  `row_names => 'id'` displayed `row_name` instead of `id`. Both spellings are
  now honoured consistently.
- **Malformed nested values degrade gracefully.** A Hash-of-Arrays column or
  Hash-of-Hashes row whose value is not actually an array/hash reference now
  renders as empty cells rather than throwing a dereference error.

#### Performance

- Column gathering no longer sorts once per scanned row. Unique column names
  are collected across the scanned rows and sorted a single time (same output
  order), and the ellipsis length is computed once rather than per cell.

#### Tests

- `t/view.t` is self-contained (the `view` implementation is inlined; it loads
  no other files) and covers the new argument handling, the bug fixes above,
  and the existing AoH / HoA / HoH behaviour, alignment, truncation, and
  output-path handling.

### `wilcox_test`

Corrected four bugs in the `wilcox_test` XSUB plus a portability fix in its exact signed-rank helper. Behaviour on valid input is unchanged: the R-agreement cases (unpaired `W = 58`, `p = 0.13292`; paired one-sided `V = 40`, `p = 0.019531`; separated exact `W = 0`, `p = 0.028571`) all still match R's `wilcox.test`.

#### Bug fixes

- **Invalid `alternative` is now rejected.** Any value other than `less` or `greater` previously fell through to the two-sided branch and returned a two-sided result mislabelled with the bad string, so a typo like `alternative => "twosided"` silently "worked". It now croaks unless `alternative` is one of `two.sided`, `less`, `greater`.
- **Zero/negative variance is guarded.** When every observation is tied the approximation's variance collapses to 0 and the old code divided by `sqrt(0)`: `wilcox_test([5,5,5], [5,5,5])` returned `p = 0` (a "significant" difference between identical samples). It now warns and returns `p = 1`.
- **Two-sided continuity correction at `z = 0`.** R uses `sign(z) * 0.5`, so the correction is `0` when the statistic sits exactly on its mean; the old code used `-0.5`. Example: `wilcox_test([1,4], [2,3], exact => 0)` changed from `p = 0.698535` to `p = 1` (matches R).
- **`exp` no longer shadows libm.** The local `exp` accumulator (mean of the statistic) shadowed the C library `exp()`; renamed to `mean_w` (two-sample) and `mean_v` (signed-rank). No active miscompute, removed as a latent hazard.

#### Cosmetic

- Collapsed a no-op ternary that assigned the same signed-rank exact method string on both branches; the `method` field is now simply `Wilcoxon signed rank exact test`.

#### Portability (exact signed-rank helper)

- **`exact_psignrank` no longer calls `powl()`.** The `2^n` normaliser is now built by exact repeated doubling, which has no long-double libm dependency. This fixes an `Undefined symbol "powl"` load failure reported by a CPAN smoker (FreeBSD, perl 5.20, `nvtype=double`) whose libm lacks the long-double math functions; the symbol resolved on glibc, which is why local builds passed. `long double` accumulation in the DP is retained — only the `powl` call was at fault.
- **`int` → `size_t`** for `n`, `max_v`, and the DP loop counters, which also removes a `size_t`-to-`int` narrowing at the call site. The `floor()` result (`k`) stays signed so its negative-`q` sentinel still fires, and is cast to `size_t` only after the `k < 0` check.

#### Tests

- Added `t/wilcox_test.t` (flat, no subtests): R-agreement cases, option handling (`paired`, `correct`, `exact`, `mu`, named/positional `x`/`y`, NA dropping), regressions for all four bug fixes, argument-error and `alternative`-validation checks, output shape, and `no_leaks_ok` coverage of the two-sample, exact, and paired allocation paths.

## 0.15

`view` function added, similar to R's `head`

`read_table`:
    filter => {
        'Testosterone, total (nmol/L)' => sub { defined $_ },
    }

was broken by the change in undefined variables in 0.14, but is back to being `undef`

`col2col` improvement in sectioning in README

Numerous changes to prevent quadmath/long double CPAN test failures

Minimum Scalar::Util version in dist.ini is now 1.22, see https://www.cpantesters.org/cpan/report/6b682236-6567-11f1-a3bc-a055f9c4ba34

`Digest::SHA` is no longer needed, and removed as a dependency

### `read_table`

#### Bug fixes

- **A comment-prefixed header is now read correctly.** `read_table` strips a
  leading comment marker from the header line (so a file may begin with
  `#id,val`), but that strip was dead code: the XS parser skipped *every* line
  beginning with the comment string before the callback ever saw it, so a
  commented header was silently dropped and the first data row was mistaken for
  the header. The parser now delivers the first content line even when it
  begins with the comment marker, and only skips comment lines after the header
  has been seen.

- **Carriage returns inside quoted fields are preserved.** The parser stripped
  `\r` unconditionally, so a quoted value such as `"x\ry"` lost its carriage
  return and would not survive a `write_table` -> `read_table` round-trip. `\r`
  is now stripped only as part of a trailing CRLF line ending and as a stray CR
  *outside* quotes; inside quotes it is literal data.

- **Duplicate column names no longer corrupt `hoa` output.** With
  `output.type => 'hoa'`, a repeated column name pushed the same cell once per
  occurrence, so the affected columns came out longer than the others and the
  arrays no longer lined up by row. Columns are now keyed by unique header name
  (first-seen order preserved, later values win, one warning emitted).

- **A defined non-CODE callback is now an error.** Passing a defined argument
  that was not a CODE reference silently fell through to slurp mode and ignored
  the argument; it now croaks
  (*"callback must be a CODE reference"*).

- **An undefined/empty `hoh` row-name now dies instead of keying on `""`.**
  With `output.type => 'hoh'`, a row whose row-name column was empty/undef was
  stored under the `''` key and raised *"uninitialized value"* warnings. It now
  dies, naming the column and the offending data row.

- **A numeric filter key past the last column now dies.** A 1-based numeric
  filter key greater than the column count was accepted, then silently extended
  every row through the `$_` write-back. It is now rejected up front with a
  message naming the column count.

- **`sep` and `delim` together now die.** Supplying both silently preferred
  `delim`; passing both is now an explicit error (`delim` remains an alias for
  `sep` when used alone).

- **The library no longer prints to STDOUT.** The unknown-argument path used
  `say` to dump the offending names to STDOUT before dying; the names are now
  carried in the `die` message itself.

#### Better diagnostics

- Alignment errors now report **which data row** is ragged
  (*"Alignment error on FILE data row N (X fields vs Y headers)"*), instead of
  only the field/header counts.

#### Memory-leak fixes (exception paths)

The parser allocated its working buffers (`current_row`, `field`, and — in
slurp mode — `data`) in the XS `INIT:` block, i.e. *before* any validation, and
freed them only by falling off the end of the function. Any non-local exit
therefore leaked:

- the open-failure `croak` leaked the row buffer and field (and the slurp
  accumulator);
- far more commonly, a `die` thrown **inside the row callback** — which
  `read_table` does routinely on alignment errors, bad row names, and filter
  exceptions — unwound straight out of the XS frame and leaked the field, the
  current row, the line buffer, the slurp accumulator, *and the open file
  handle*.

Allocations now happen in `CODE:` after every croak-able check, and every
long-lived resource (the file handle via `SAVEDESTRUCTOR_X`, the buffers via
`SAVEFREESV`) is tied to the save stack, which an exception unwinds. Measured
with `Test::LeakTrace`: a `die` mid-file went from 5 leaked SVs to 0, and an
open failure from 2 to 0. This is the likely source of the constant-size leaks
seen in CPAN-tester reports for the exception-path tests.

#### Performance

- **~2.5x faster parsing** (57 -> 145 MB/s on a 100k-row quoted file). The core
  loop appended one character at a time with `sv_catpvn(field, &ch, 1)`; it now
  scans runs of ordinary bytes with `memchr` / a bounded scan and appends each
  run in a single `sv_catpvn`, copying field contents in bulk rather than byte
  by byte.

#### Internal / non-behavioral

- XS declarations moved from `INIT:` to `PREINIT:`; allocations deferred into
  `CODE:` (see the leak fixes above).
- The filter loop now aliases the row hash with `local *_ = \%line_hash`
  instead of copying it with `local %_ = %line_hash`. This removes a full
  per-row hash copy for every filtered row and fixes a latent staleness bug:
  after a filter mutated `$_` and the change was written back, `%_` still
  reflected the pre-mutation copy, so a subsequent filter in the same row saw
  stale values. With aliasing, `%_` *is* the row, so write-backs are always
  visible.

#### Known limitation (not changed)

- **`undef.val` does not round-trip back to `undef`.** `write_table` renders an
  `undef` cell as an empty field by default, and `read_table` maps an empty
  field back to `undef`, so the *default* round-trip is clean. But if a file is
  written with a token such as `'undef.val' => 'NA'`, `read_table` has no
  inverse option and reads `NA` back as the string `'NA'`. `read_table` also
  cannot distinguish a deliberately quoted empty string (`""`) from a missing
  value -- both become `undef`. Adding an `na.strings`-style option to
  `read_table` (mapping configurable tokens and/or empty fields to `undef`)
  would close this gap.

### `write_table`

#### Behavior change

- **`undef` cells now write as an empty field, not an empty string.** A missing
  or `undef` value renders as nothing between separators (`a,,c`) rather than a
  quoted empty string (`a,'',c` / `a,"",c`). Supplying `'undef.val' => 'NA'`
  (or any other token) still overrides this, exactly as before. This is the
  only change that can alter the bytes of an existing output file; if you relied
  on the previous default, pass `'undef.val' => ''` to keep an explicit empty
  field, or your chosen placeholder.

#### Bug fixes

- **Wide-character / UTF-8 column names and row keys now round-trip.**
  Previously, cells were looked up with the raw bytes of the column name
  (`hv_fetch(..., SvPV_nolen(name), strlen(name), ...)`), which fails to match a
  UTF-8-flagged hash key: the column header printed correctly but every cell
  under it came back empty. All lookups now fetch by SV (`hv_fetch_ent`), header
  lists are gathered and sorted as SVs (`sortsv` + `sv_cmp`, preserving the
  flag) instead of being round-tripped through `char *`, and the `row.names`
  column is matched with `sv_eq` rather than `strcmp`. Embedded NUL bytes in
  keys are handled correctly as a side effect.

- **`col.names => []` no longer loops forever.** An empty `col.names` array made
  `av_len()` return `-1`, which — compared against an unsigned `size_t` loop
  index — wrapped to `SIZE_MAX` and ran effectively without end. This was fixed
  for flat hashes previously; it was still present for hash-of-hashes,
  hash-of-arrays, and array-of-hashes, plus both `row.names` header-filtering
  loops. All such loops now use a signed index.

- **Tables wider than 65,535 columns no longer hang.** One header loop used an
  `unsigned short` index that silently wrapped past 65,535 and never terminated.
  It now uses `size_t` like the rest of the code.

- **Flat-hash cells holding a reference now croak.** Every other input shape
  rejects a nested reference with
  *"Cannot write nested reference types to table"*; a flat hash instead
  stringified it (e.g. `ARRAY(0x55...)`) into the file. It now croaks
  consistently.

- **`'undef.val' => undef` is handled cleanly.** It previously called
  `SvPV_nolen` on `undef`, raising an *"uninitialized value"* warning and
  yielding an empty string by accident. It is now treated explicitly as an empty
  field, with no warning.

#### Memory-leak fixes (exception paths)

- The row-key list gathered for hash-of-hashes input was leaked when the output
  file could not be opened.
- The *"Could not get headers"* croak on hash-of-arrays input leaked both the
  already-open filehandle and the headers array.

#### Internal / non-behavioral

- Numeric row labels are now formatted into a reused stack buffer instead of a
  per-row `savepv()` / `safefree()` allocation (no functional change; removes a
  cast-away-`const` and one allocation per row).
- Several signed/unsigned index types were made consistent (`SSize_t` vs
  `size_t`) to match `av_len()` and silence the conditions behind the loop bugs
  above.

#### Tests

- `t/write_table.t` expanded from 17 to 69 assertions. New coverage targets each
  fix above: the empty-field default and `undef.val => undef` (no warning),
  `col.names => []` termination across all four input shapes, the
  >65,535-column header loop (gated behind `EXTENDED_TESTING=1`), in-sequence
  numeric row labels, nested-reference rejection, CSV quoting corners
  (carriage return, separators inside column names, multi-character separators),
  empty input writing no file, and UTF-8 column names and row keys. Two leak
  assertions cover the exception paths above.

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

## 0.04 2026-5-17 CDT

addition of `sample` function

GNU source, to maximize compatibility and ease installation

removal of JSON dependency to ease installation

## 0.03 2026-5-13 CDT

Compatibility back to Perl 5.10

## 0.02 2026-5-7 CDT

back-compatible to Perl 5.10, instead of original 5.40, ensuring more people can use it

added var_test

mean, min, sum, median, var, and max die with undefined values, and print the offending indices

"group_stats" added to aov, for TukeyHSD in the future

"cor" dies when given data with standard deviation of 0

`write_table` now has `undef.val` option, which shows how undefined values are printed to tables, which is `NA` by default.

# COPYRIGHT AND LICENSE

This software is free.  It is licensed under the same terms as Perl itself
