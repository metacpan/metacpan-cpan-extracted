# SQL::Wizard

**Composable SQL query builder for Perl — expression trees, immutable queries, zero dependencies.**

---

## Features

- **Everything is an expression** — SELECTs, CASE, functions, arithmetic, subqueries all compose freely
- **Immutable queries** — modifier methods return new objects; build a base query once, derive many variants
- **Bind parameters by default** — plain values always produce `?` placeholders; use `raw()` only when you mean it
- **SQL::Abstract-compatible WHERE syntax** — the hashref/arrayref conditions Perl developers already know
- **Zero non-core dependencies** — no SQL::Abstract, no Moose, nothing outside the Perl core

---

## Installation

```bash
cd SQL-Wizard
perl Makefile.PL
make
make test
sudo make install
```

---

## Quick Start

```perl
use SQL::Wizard;

my $q = SQL::Wizard->new;

# SELECT with JOIN, WHERE, ORDER BY, LIMIT
my ($sql, @bind) = $q->select(
    -columns  => ['u.id', 'u.name', $q->func(COUNT => 'o.id')->as('orders')],
    -from     => ['users|u', $q->left_join('orders|o', 'u.id = o.user_id')],
    -where    => { 'u.status' => 'active', 'u.age' => { '>' => 18 } },
    -group_by => 'u.id',
    -order_by => [{ -desc => 'orders' }],
    -limit    => 20,
)->to_sql;

# Pass directly to DBI
my $sth = $dbh->prepare($sql);
$sth->execute(@bind);
```

---

## Expression Primitives

| Method | Output |
|--------|--------|
| `$q->col('u.name')` | column reference (no bind) |
| `$q->val(42)` | bound value → `?` |
| `$q->raw('NOW()')` | literal SQL fragment |
| `$q->func('COUNT', '*')` | `COUNT(*)` |
| `$q->coalesce('a', $q->val(0))` | `COALESCE(a, ?)` |
| `$q->cast('price', 'INTEGER')` | `CAST(price AS INTEGER)` |
| `$q->greatest('a', 'b')` | `GREATEST(a, b)` |
| `$q->between('age', 18, 65)` | `age BETWEEN ? AND ?` |
| `$q->exists($subquery)` | `EXISTS(SELECT ...)` |

Every expression supports `.as('alias')`, `.asc()`, `.desc()`, `.over(...)`, and `.to_sql()`.

---

## Arithmetic

Operator overloading on expression objects:

```perl
my $subtotal = $q->col('price') * $q->col('qty');
my $tax      = $subtotal * $q->val(0.2);
my $total    = $subtotal + $tax;

$q->select(
    -columns => [
        $subtotal->as('subtotal'),
        $tax->as('tax'),
        $total->as('total'),
    ],
    -from => 'line_items',
);
```

Supported: `+`, `-`, `*`, `/`, `%`. Plain Perl numbers are auto-coerced to bind parameters.

---

## WHERE Clause

Hashref conditions (AND by default):

```perl
-where => { status => 'active', age => { '>' => 18 } }
# status = ? AND age > ?

-where => { id => { -in     => [1, 2, 3] } }   # id IN (?, ?, ?)
-where => { id => { -not_in => $subquery  } }   # id NOT IN (SELECT ...)
-where => { deleted_at => undef }               # deleted_at IS NULL
```

Explicit AND / OR nesting:

```perl
-where => [-and => [
    { status => 'active' },
    [-or => [
        { role => 'admin' },
        { role => 'editor' },
    ]],
]]
# (status = ? AND (role = ? OR role = ?))
```

Expression objects in WHERE:

```perl
-where => [
    $q->exists($subquery),
    $q->between('age', 18, 65),
    $q->raw('ST_DWithin(location, ?, ?)', $point, $radius),
]
```

---

## Joins

```perl
$q->join('orders|o',       'u.id = o.user_id')   # INNER JOIN
$q->left_join('orders|o',  'u.id = o.user_id')   # LEFT JOIN
$q->right_join('orders|o', 'u.id = o.user_id')   # RIGHT JOIN
$q->full_join('orders|o',  'u.id = o.user_id')   # FULL OUTER JOIN
$q->cross_join('sizes')                           # CROSS JOIN (no ON)

# table|alias expands to: table alias
# ON clause accepts a string or hashref (same syntax as WHERE)
```

---

## CASE Expressions

```perl
# Searched CASE
$q->case(
    [$q->when({ total => { '>' => 10000 } }, 'Platinum')],
    [$q->when({ total => { '>' => 5000  } }, 'Gold')],
    $q->else('Bronze'),
)->as('tier')

# Simple CASE (CASE ON)
$q->case_on(
    $q->col('u.role'),
    [$q->when($q->val('admin'),  'Full Access')],
    [$q->when($q->val('editor'), 'Edit Access')],
    $q->else('Read Only'),
)->as('access_level')
```

---

## Window Functions

```perl
# Inline specification
$q->func('ROW_NUMBER')->over(
    -partition_by => 'department',
    -order_by     => [{ -desc => 'salary' }],
)->as('rank')
# ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rank

# Running total with frame
$q->func('SUM', 'amount')->over(
    -partition_by => 'account_id',
    -order_by     => 'transaction_date',
    -frame        => 'ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW',
)->as('running_total')

# Named windows (defined in -window)
$q->select(
    -columns => [
        $q->func('RANK')->over('w')->as('r'),
        $q->func('DENSE_RANK')->over('w')->as('dr'),
    ],
    -from   => 'employees',
    -window => { w => { '-partition_by' => 'dept', '-order_by' => 'salary' } },
)
```

---

## UNION / INTERSECT / EXCEPT

```perl
my $a = $q->select(-columns => [qw/id name/], -from => 'active_users');
my $b = $q->select(-columns => [qw/id name/], -from => 'legacy_users');
my $c = $q->select(-columns => [qw/id name/], -from => 'pending_users');

my ($sql, @bind) = $a->union($b)->union_all($c)->order_by('name')->limit(100)->to_sql;
```

Methods: `union`, `union_all`, `intersect`, `except`.

---

## CTEs (WITH clauses)

```perl
my ($sql, @bind) = $q->with(
    recent_orders => $q->select(
        -columns => ['*'],
        -from    => 'orders',
        -where   => { created_at => { '>' => $q->raw("NOW() - INTERVAL '30 days'") } },
    ),
    big_spenders => $q->select(
        -columns  => ['user_id', $q->func(SUM => 'total')->as('spent')],
        -from     => 'recent_orders',
        -group_by => 'user_id',
        -having   => $q->raw('SUM(total) > ?', 1000),
    ),
)->select(
    -columns  => ['u.name', 'bs.spent'],
    -from     => ['users|u', $q->join('big_spenders|bs', 'u.id = bs.user_id')],
    -order_by => [{ -desc => 'bs.spent' }],
)->to_sql;
```

Recursive CTEs:

```perl
$q->with_recursive(
    org_tree => {
        -initial => $q->select(-columns => [qw/id name parent_id/], -from => 'employees',
                               -where => { parent_id => undef }),
        -recurse => $q->select(-columns => ['e.id', 'e.name', 'e.parent_id'],
                               -from => ['employees|e', $q->join('org_tree|t', 'e.parent_id = t.id')]),
    },
)->select(-columns => ['*'], -from => 'org_tree', -order_by => 'name')->to_sql;
```

---

## INSERT

```perl
# Single row
$q->insert(-into => 'users', -values => { name => 'Alice', email => 'alice@example.com' })->to_sql;

# Multi-row
$q->insert(
    -into    => 'users',
    -columns => [qw/name email/],
    -values  => [['Alice', 'alice@example.com'], ['Bob', 'bob@example.com']],
)->to_sql;

# INSERT ... SELECT
$q->insert(-into => 'archive', -columns => [qw/id name/],
           -select => $q->select(-columns => [qw/id name/], -from => 'users', -where => { status => 'deleted' }))->to_sql;

# PostgreSQL upsert
$q->insert(
    -into    => 'counters',
    -values  => { key => 'hits', value => 1 },
    -on_conflict => { -target => 'key', -update => { value => $q->raw('counters.value + EXCLUDED.value') } },
)->to_sql;

# MySQL ON DUPLICATE KEY
$q->insert(
    -into         => 'counters',
    -values       => { key => 'hits', value => 1 },
    -on_duplicate => { value => $q->raw('value + VALUES(value)') },
)->to_sql;
```

---

## UPDATE

```perl
# Simple
$q->update(
    -table => 'users',
    -set   => { status => 'inactive', updated_at => $q->raw('NOW()') },
    -where => { last_login => { '<' => '2023-01-01' } },
)->to_sql;

# With JOIN (MySQL style)
$q->update(
    -table => ['users|u', $q->join('orders|o', 'u.id = o.user_id')],
    -set   => { 'u.last_order' => $q->col('o.created_at') },
    -where => { 'o.status' => 'completed' },
)->to_sql;
```

---

## DELETE

```perl
# Simple
$q->delete(-from => 'users', -where => { status => 'deleted' })->to_sql;

# With subquery
$q->delete(
    -from  => 'users',
    -where => { id => { -not_in => $q->select(-columns => ['user_id'], -from => 'active_sessions') } },
)->to_sql;

# PostgreSQL USING
$q->delete(
    -from  => 'orders',
    -using => 'users',
    -where => { 'orders.user_id' => $q->col('users.id'), 'users.status' => 'banned' },
)->to_sql;
```

---

## Immutable Query Modification

```perl
my $base   = $q->select(-from => 'users', -where => { status => 'active' });
my $admins = $base->add_where({ role => 'admin' });
my $page   = $admins->order_by('name')->limit(20)->offset(0);
my $count  = $base->columns([$q->func('COUNT', '*')->as('n')]);

# $base is unchanged throughout
```

Methods: `add_where`, `columns`, `order_by`, `limit`, `offset`.

---

## License

See the [LICENSE](LICENSE) file for details.
