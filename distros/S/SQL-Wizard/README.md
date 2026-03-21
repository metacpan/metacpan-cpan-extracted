# SQL::Wizard - Composable SQL query builder with expression trees for Perl

## Synopsis

    use SQL::Wizard;

    my $q = SQL::Wizard->new;

    # SELECT with WHERE, JOIN, ORDER BY, LIMIT
    my ($sql, @bind) = $q->select(
        -columns  => ['u.id', 'u.name', $q->func(COUNT => 'o.id')->as('orders')],
        -from     => ['users|u', $q->left_join('orders|o', 'u.id = o.user_id')],
        -where    => { 'u.status' => 'active', 'u.age' => { '>' => 18 } },
        -group_by => 'u.id',
        -order_by => [{ -desc => 'orders' }],
        -limit    => 20,
    )->to_sql;

    # INSERT
    my ($sql, @bind) = $q->insert(
        -into   => 'users',
        -values => { name => 'Alice', email => 'alice@example.com' },
    )->to_sql;

    # UPDATE
    my ($sql, @bind) = $q->update(
        -table => 'users',
        -set   => { status => 'inactive' },
        -where => { last_login => { '<' => '2023-01-01' } },
    )->to_sql;

    # DELETE
    my ($sql, @bind) = $q->delete(
        -from  => 'users',
        -where => { status => 'deleted' },
    )->to_sql;

## Description

SQL::Wizard builds SQL queries as composable expression trees. Every API call
constructs a node in the tree. Nothing is rendered to SQL until `->to_sql`
is called, which returns `($sql, @bind)` — a SQL string with `?` placeholders
and a flat list of bind values in the correct order.

Key properties:

- **Everything is an expression.** A SELECT is an expression. A CASE is an
expression. A function call is an expression. Anything can nest inside anything
else — subqueries in columns, in FROM, in WHERE; arithmetic in SET clauses;
CASE in ORDER BY.
- **Immutable queries.** Modifier methods (`add_where`, `order_by`,
`limit`, etc.) return new objects and never modify the original. Build a base
query once and derive many variants from it.
- **Bind parameters by default.** Plain Perl values always produce `?`
placeholders. Only `$q->raw()` injects literal SQL.
- **SQL::Abstract-compatible WHERE syntax.** Hashref and arrayref
conditions work exactly as Perl developers already expect.
- **Zero non-core dependencies.** No SQL::Abstract, no Moose, nothing
outside the Perl core (plus Test::More for tests).

## Constructor

### new

    my $q = SQL::Wizard->new;
    my $q = SQL::Wizard->new(dialect => 'mysql');

Creates a new SQL::Wizard instance. The optional `dialect` parameter is
reserved for future dialect-specific rendering (quoting styles, LIMIT syntax,
etc.). Currently all output is standard ANSI SQL.

## Expression Primitives

These methods construct leaf nodes in the expression tree. They are the
building blocks for everything else.

### col

    $q->col('u.name')
    $q->col('price')

Returns a column reference expression. Use this whenever you need to refer to
a column unambiguously — particularly in WHERE values, SET clauses, and JOIN
conditions where a bare string might otherwise be treated as a literal.

    # Explicit column reference in WHERE
    -where => { user_id => $q->col('u.id') }   # user_id = u.id (no bind)

    # vs plain string value (produces bind param)
    -where => { user_id => 'u.id' }             # user_id = ?  (binds 'u.id')

### val

    $q->val(42)
    $q->val('some string')
    $q->val(undef)

Returns a bound value expression. Always produces a `?` placeholder. Use this
when you need to force a value to be treated as a bind parameter in a position
where it might otherwise be interpreted differently (e.g. in `-columns`).

    $q->func(COALESCE => 'nickname', $q->val('Anonymous'))
    # => COALESCE(nickname, ?)  bind: ['Anonymous']

### raw

    $q->raw('NOW()')
    $q->raw('? + INTERVAL ? DAY', $start, $days)

Injects literal SQL. Use sparingly — only for database-specific constructs that
the API does not support natively. Any bind values are passed as additional
arguments after the SQL string.

    -set => { updated_at => $q->now }
    -where => { created_at => { '>' => $q->raw("NOW() - INTERVAL '30 days'") } }

### func

    $q->func('COUNT', '*')
    $q->func('COALESCE', 'nickname', $q->val('Anonymous'))
    $q->func('ROW_NUMBER')
    $q->func('DATE_TRUNC', $q->val('month'), 'created_at')

Returns a SQL function call expression: `NAME(arg1, arg2, ...)`. The function
name is used as-is (not upcased). Arguments may be column name strings, other
expressions, or `val()` nodes. Plain strings in argument position are treated
as column references.

    $q->func('COUNT', '*')->as('total')        # COUNT(*) AS total
    $q->func('SUM', 'amount')                  # SUM(amount)

### coalesce

    $q->coalesce('nickname', $q->val('Anonymous'))
    # COALESCE(nickname, ?)

Shorthand for `$q->func('COALESCE', ...)`.

### greatest

    $q->greatest('a', 'b', 'c')
    # GREATEST(a, b, c)

Shorthand for `$q->func('GREATEST', ...)`.

### least

    $q->least('a', 'b')
    # LEAST(a, b)

Shorthand for `$q->func('LEAST', ...)`.

### Now

    $q->now
    # NOW()

Shorthand for `$q->func('NOW')`. Useful in SET clauses:

    -set => { updated_at => $q->now }

### cast

    $q->cast('price', 'INTEGER')
    $q->cast($q->col('amount'), 'DECIMAL(10,2)')
    # CAST(price AS INTEGER)

Returns a CAST expression. The first argument may be a column name string or
any expression object.

### exists

    $q->exists($subquery)
    # EXISTS(SELECT ...)

Returns an EXISTS expression wrapping a subquery. Typically used inside a WHERE
clause array:

    -where => [$q->exists(
        $q->select(-columns => [1], -from => 'vip', -where => { user_id => $q->col('u.id') })
    )]

### not\_exists

    $q->not_exists($subquery)
    # NOT EXISTS(SELECT ...)

Like `exists` but negated.

### Any

    $q->any($subquery)
    # ANY(SELECT ...)

Returns an ANY subquery expression. Used with comparison operators in WHERE:

    -where => { salary => { '>' => $q->any(
        $q->select(-columns => ['salary'], -from => 'managers')
    ) } }
    # salary > ANY(SELECT salary FROM managers)

### All

    $q->all($subquery)
    # ALL(SELECT ...)

Returns an ALL subquery expression. The comparison must hold for every row:

    -where => { salary => { '>' => $q->all(
        $q->select(-columns => ['salary'], -from => 'interns')
    ) } }
    # salary > ALL(SELECT salary FROM interns)

### between

    $q->between('age', 18, 65)
    $q->between($q->col('price'), $q->val(10), $q->val(100))
    # age BETWEEN ? AND ?

Returns a BETWEEN expression. The column argument may be a string (treated as
a column reference) or an expression. The low and high bounds may be plain
values or expression objects.

### not\_between

    $q->not_between('age', 0, 17)
    # age NOT BETWEEN ? AND ?

Like `between` but negated.

### and

    $q->and(\%cond1, \%cond2, ...)
    # (cond1 AND cond2)

Combines multiple WHERE conditions with AND. Returns an expression that can be
used anywhere a condition is accepted.

### or

    $q->or(\%cond1, \%cond2, ...)
    # (cond1 OR cond2)

Combines multiple WHERE conditions with OR.

### not

    $q->not(\%cond)
    # NOT (cond)

Negates a condition.

## Expression Methods

All expression objects (returned by `col`, `val`, `func`, `select`, etc.)
support these methods.

### as

    $expr->as('alias')
    # expr AS alias

Returns an aliased expression. Works on any expression type.

    $q->func('COUNT', '*')->as('total')        # COUNT(*) AS total
    $q->col('u.name')->as('user_name')         # u.name AS user_name
    $q->select(...)->as('subq')                # (SELECT ...) AS subq

### asc

    $expr->asc
    # expr ASC

Returns an ORDER BY expression with ASC direction.

### desc

    $expr->desc
    # expr DESC

Returns an ORDER BY expression with DESC direction.

### asc\_nulls\_first

    $expr->asc_nulls_first
    # expr ASC NULLS FIRST

### desc\_nulls\_last

    $expr->desc_nulls_last
    # expr DESC NULLS LAST

### over

    $func->over('window_name')
    $func->over(-partition_by => 'dept', -order_by => 'salary')

Converts a function call into a window function expression. See
["WINDOW FUNCTIONS"](#window-functions) for full documentation.

### to\_sql

    my ($sql, @bind) = $expr->to_sql;

Renders the expression (or full query) to a SQL string and a flat list of bind
values. This is the only method that produces output — all other methods build
the tree.

The returned `$sql` contains `?` placeholders. Pass `@bind` directly to
DBI's execute:

    my ($sql, @bind) = $q->select(...)->to_sql;
    $dbh->prepare($sql)->execute(@bind);

## Arithmetic Operators

Expression objects support Perl arithmetic operators via overloading:

    $q->col('price') + $q->col('tax')          # price + tax
    $q->col('price') * $q->val(0.9)            # price * ?  (bind: 0.9)
    $q->col('score') - 10                      # score - ?  (bind: 10)
    $q->col('total') / $q->col('count')        # total / count
    $q->col('id') % 2                          # id % ?     (bind: 2)

Plain Perl numbers are automatically coerced to bound value nodes. Operators
can be chained:

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

**Note:** Do not try to stringify an expression with `"$expr"` — it will die.
Always use `->to_sql`.

## select

    my ($sql, @bind) = $q->select(
        -distinct => 1,                   # optional
        -columns  => \@exprs,
        -from     => $table_or_arrayref,
        -where    => $condition,
        -group_by => $col_or_arrayref,
        -having   => $condition,
        -order_by => $col_or_arrayref,
        -window   => \%window_definitions,
        -limit    => $n,
        -offset   => $n,
    )->to_sql;

All keys are optional except `-from`. Omitting `-columns` defaults to
`SELECT *`.

### -distinct

Set to `1` to produce `SELECT DISTINCT`:

    $q->select(-distinct => 1, -columns => ['department'], -from => 'employees')
    # SELECT DISTINCT department FROM employees

Can also be applied as an immutable modifier (see ["QUERY MODIFICATION"](#query-modification)):

    $base->distinct->to_sql

### -columns

An arrayref of column expressions. Each element may be:

- A plain string — used as-is (e.g. `'u.name'`, `'*'`)
- An expression object — rendered via its renderer
- An aliased expression — `$expr->as('label')`

    -columns => [
        'u.id',
        'u.name',
        $q->func('COUNT', 'o.id')->as('order_count'),
        ($q->col('price') * $q->col('qty'))->as('subtotal'),
        $q->case(...)->as('status_label'),
    ]

### -from

A table name string, a `table|alias` shorthand, an expression, or an arrayref
mixing tables and join expressions.

The `table|alias` shorthand expands to `table alias` in SQL:

    -from => 'users|u'                   # FROM users u
    -from => ['users|u', $q->join(...)]  # FROM users u JOIN ...

Subqueries in FROM must be aliased with `->as()`:

    -from => [$q->select(...)->as('sub')]

### -where

See ["WHERE CLAUSE SYNTAX"](#where-clause-syntax).

### -group\_by

A column name string or arrayref of column names/expressions:

    -group_by => 'department'
    -group_by => ['department', 'year']
    -group_by => [$q->func('DATE_TRUNC', $q->val('month'), 'created_at')]

### -having

Same syntax as `-where`. Applied after grouping.

    -having => { $q->raw('COUNT(*)') => { '>' => 5 } }
    -having => $q->raw('COUNT(*) > ?', 5)

**Note:** Because Perl hash keys are always stringified, you cannot use an Expr
object as a hash key in `-having`. Use `$q-`raw()> for function-based HAVING
conditions, or use the arrayref condition syntax.

### -order\_by

A single column name, an expression, or an arrayref of either:

    -order_by => 'name'                                 # name (ASC)
    -order_by => '-created_at'                          # shorthand: col DESC
    -order_by => { -desc => 'created_at' }              # hashref form
    -order_by => { -asc  => 'name' }                    # hashref form (ASC)
    -order_by => $q->col('created_at')->desc            # expression method
    -order_by => $q->col('name')->asc                   # expression method (ASC)

These can be mixed in an arrayref:

    -order_by => ['-created_at', 'name']                # created_at DESC, name
    -order_by => [{ -desc => 'created_at' }, 'name']    # same result
    -order_by => [$q->col('created_at')->desc, 'name']  # same result

### -window

A hashref mapping window names to window specifications, for use with named
windows. See ["WINDOW FUNCTIONS"](#window-functions).

### -limit And -offset

    -limit  => 20
    -offset => 40

Appended as `LIMIT 20 OFFSET 40`.

## Where Clause Syntax

The WHERE clause accepts several forms that can be freely mixed and nested.

### Hashref Conditions

    { column => $value }          # column = ?
    { column => undef }           # column IS NULL
    { column => \@list }          # column IN (?, ?, ?)
    { column => $expr }           # column = expr  (no bind if Expr object)
    { column => { op => $val } }  # column op ?

Supported operators: `>`, `>=`, `<`, `<=`, `!=`,
`=`, `LIKE`, `-in`, `-not_in`, and any other SQL operator string.

Multiple keys in a hashref are combined with AND:

    { status => 'active', age => { '>' => 18 } }
    # status = ? AND age > ?

### -in And -not\_in

    { id => { -in     => [1, 2, 3] } }           # id IN (?, ?, ?)
    { id => { -not_in => [1, 2, 3] } }           # id NOT IN (?, ?, ?)
    { id => { -in     => $subquery  } }           # id IN (SELECT ...)
    { id => { -not_in => $subquery  } }           # id NOT IN (SELECT ...)

### Arrayref With -and / -or

    [-and => [ \%cond1, \%cond2 ]]        # cond1 AND cond2
    [-or  => [ \%cond1, \%cond2 ]]        # cond1 OR cond2

Nesting:

    [-and => [
        { status => 'active' },
        [-or => [
            { role => 'admin' },
            { role => 'editor' },
        ]],
    ]]
    # (status = ? AND (role = ? OR role = ?))

### Expression Objects In Where

Any expression object can appear in a WHERE array:

    -where => [
        $q->exists($subquery),
        $q->between('age', 18, 65),
        $q->raw('ST_DWithin(location, ?, ?)', $point, $radius),
    ]

### Plain String

    -where => '1 = 1'

Used as a literal SQL fragment. No bind parameters.

## Joins

    $q->join($table, $on)
    $q->left_join($table, $on)
    $q->right_join($table, $on)
    $q->full_join($table, $on)
    $q->cross_join($table)

All join methods return a join expression for use in a `-from` arrayref. The
`$table` argument accepts the same forms as `-from`: a string, a
`table|alias` shorthand, or an aliased subquery. The `$on` argument accepts
a plain SQL string or a hashref condition.

    # String ON
    $q->join('orders|o', 'u.id = o.user_id')
    # => JOIN orders o ON u.id = o.user_id

    # Hashref ON (same syntax as WHERE)
    $q->left_join('orders|o', {
        'u.id'     => $q->col('o.user_id'),
        'o.status' => 'completed',
    })
    # => LEFT JOIN orders o ON o.status = ? AND u.id = o.user_id

    # Join on subquery
    $q->join(
        $q->select(
            -columns  => ['user_id', $q->func('MAX', 'login_date')->as('last_login')],
            -from     => 'logins',
            -group_by => 'user_id',
        )->as('ll'),
        'u.id = ll.user_id',
    )
    # => JOIN (SELECT user_id, MAX(login_date) AS last_login FROM logins GROUP BY user_id) AS ll
    #    ON u.id = ll.user_id

`full_join` renders as `FULL OUTER JOIN`. `cross_join` takes no ON clause.

## Case Expressions

### Searched Case

    $q->case(
        [$q->when(\%condition, $then), ...],
        $q->else($default),      # optional
    )

Each `when` takes a WHERE-syntax condition and a result value. The result
value may be a plain scalar (auto-wrapped as a bind parameter) or any
expression object.

    $q->case(
        [$q->when({ total => { '>'  => 10000 } }, 'Platinum')],
        [$q->when({ total => { '>'  => 5000  } }, 'Gold')],
        [$q->when({ total => { '>'  => 1000  } }, 'Silver')],
        $q->else('Bronze'),
    )->as('tier')
    # CASE WHEN total > ? THEN ? WHEN total > ? THEN ? WHEN total > ? THEN ? ELSE ? END AS tier

### Simple Case (case On)

    $q->case_on(
        $q->col('u.role'),
        [$q->when($q->val('admin'),  'Full Access')],
        [$q->when($q->val('editor'), 'Edit Access')],
        $q->else('Read Only'),
    )->as('access_level')
    # CASE u.role WHEN ? THEN ? WHEN ? THEN ? ELSE ? END AS access_level

### When And Else

`when($condition, $then)` and `else($value)` are helper constructors used
only inside `case()` and `case_on()`. They are not standalone expressions.

## Window Functions

Window functions are created by calling `->over(...)` on a `func()`
expression.

### Inline Window Specification

    $q->func('ROW_NUMBER')->over(
        -partition_by => 'department',
        -order_by     => [{ -desc => 'salary' }],
    )->as('rank')
    # ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rank

    $q->func('SUM', 'amount')->over(
        -partition_by => 'account_id',
        -order_by     => 'transaction_date',
        -frame        => 'ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW',
    )->as('running_total')

Options for the inline spec:

- `-partition_by` — a column name or arrayref of column names
- `-order_by` — same syntax as SELECT `-order_by`
- `-frame` — a raw SQL frame clause string

### Named Windows

Reference a named window (defined in `-window`) by passing its name as a
string to `over`:

    $q->func('RANK')->over('dept_window')->as('dept_rank')

    $q->select(
        -columns => [
            $q->func('RANK')->over('w')->as('r1'),
            $q->func('DENSE_RANK')->over('w')->as('r2'),
        ],
        -from    => 'employees',
        -window  => {
            w => {
                '-partition_by' => 'department',
                '-order_by'     => [{ -desc => 'salary' }],
            },
        },
    )
    # ... WINDOW w AS (PARTITION BY department ORDER BY salary DESC)

## Union / Intersect / Except

Compound queries are built by chaining methods on a SELECT expression:

    my $a = $q->select(-columns => [qw/id name/], -from => 'active_users');
    my $b = $q->select(-columns => [qw/id name/], -from => 'legacy_users');
    my $c = $q->select(-columns => [qw/id name/], -from => 'pending_users');

    my ($sql, @bind) = $a->union($b)->union_all($c)->order_by('name')->limit(100)->to_sql;
    # (SELECT id, name FROM active_users)
    # UNION
    # (SELECT id, name FROM legacy_users)
    # UNION ALL
    # (SELECT id, name FROM pending_users)
    # ORDER BY name LIMIT 100

Available methods: `union`, `union_all`, `intersect`, `except`. All take
another SELECT (or compound) expression as their argument.

`order_by`, `limit`, and `offset` on a compound apply to the entire result
set, not to any individual query.

Compound expressions are immutable — each chained call returns a new object.

## CTEs (with Clauses)

### with

    $q->with(
        cte_name => $select_expr,
        ...
    )->select(-from => 'cte_name', ...)

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
    # WITH recent_orders AS (...), big_spenders AS (...)
    # SELECT u.name, bs.spent FROM users u JOIN big_spenders bs ON u.id = bs.user_id
    # ORDER BY bs.spent DESC

CTEs are named pairwise: `(name1 =` $query1, name2 => $query2, ...)>.

### with\_recursive

    $q->with_recursive(
        cte_name => {
            -initial => $base_case_select,
            -recurse => $recursive_select,
        },
    )->select(...)

The hash value for a recursive CTE must have `-initial` and `-recurse` keys.
They are joined with `UNION ALL`:

    my ($sql, @bind) = $q->with_recursive(
        org_tree => {
            -initial => $q->select(
                -columns => [qw/id name parent_id/],
                -from    => 'employees',
                -where   => { parent_id => undef },
            ),
            -recurse => $q->select(
                -columns => ['e.id', 'e.name', 'e.parent_id'],
                -from    => ['employees|e', $q->join('org_tree|t', 'e.parent_id = t.id')],
            ),
        },
    )->select(
        -columns  => ['*'],
        -from     => 'org_tree',
        -order_by => 'name',
    )->to_sql;
    # WITH RECURSIVE org_tree AS (
    #   SELECT id, name, parent_id FROM employees WHERE parent_id IS NULL
    #   UNION ALL
    #   SELECT e.id, e.name, e.parent_id FROM employees e JOIN org_tree t ON e.parent_id = t.id
    # )
    # SELECT * FROM org_tree ORDER BY name

## insert

    $q->insert(
        -into         => $table,
        -values       => \%row_or_arrayref,
        -columns      => \@col_names,      # for multi-row insert
        -select       => $select_expr,     # INSERT ... SELECT
        -on_conflict  => \%spec,           # PostgreSQL ON CONFLICT
        -on_duplicate => \%set,            # MySQL ON DUPLICATE KEY UPDATE
        -returning    => \@cols,           # PostgreSQL RETURNING
    )->to_sql

### Single Row

    $q->insert(
        -into   => 'users',
        -values => { name => 'Alice', email => 'alice@example.com', status => 'active' },
    )->to_sql
    # INSERT INTO users (email, name, status) VALUES (?, ?, ?)

Columns are sorted alphabetically. Values are auto-wrapped as bind parameters.
Use `$q-`raw()> to inject a literal:

    -values => { name => 'Alice', created_at => $q->now }

### Multi-row

    $q->insert(
        -into    => 'users',
        -columns => [qw/name email/],
        -values  => [
            ['Alice', 'alice@example.com'],
            ['Bob',   'bob@example.com'],
        ],
    )->to_sql
    # INSERT INTO users (name, email) VALUES (?, ?), (?, ?)

### Insert ... Select

    $q->insert(
        -into    => 'archive_users',
        -columns => [qw/id name email/],
        -select  => $q->select(
            -columns => [qw/id name email/],
            -from    => 'users',
            -where   => { status => 'deleted' },
        ),
    )->to_sql
    # INSERT INTO archive_users (id, name, email) SELECT id, name, email FROM users WHERE status = ?

### Upsert — PostgreSQL On Conflict

    $q->insert(
        -into    => 'counters',
        -values  => { key => 'hits', value => 1 },
        -on_conflict => {
            -target => 'key',
            -update => { value => $q->raw('counters.value + EXCLUDED.value') },
        },
    )->to_sql
    # INSERT INTO counters (key, value) VALUES (?, ?)
    # ON CONFLICT (key) DO UPDATE SET value = counters.value + EXCLUDED.value

### Upsert — MySQL On Duplicate Key

    $q->insert(
        -into    => 'counters',
        -values  => { key => 'hits', value => 1 },
        -on_duplicate => {
            value => $q->raw('value + VALUES(value)'),
        },
    )->to_sql
    # INSERT INTO counters (key, value) VALUES (?, ?)
    # ON DUPLICATE KEY UPDATE value = value + VALUES(value)

### returning

    $q->insert(
        -into      => 'users',
        -values    => { name => 'Alice' },
        -returning => ['id', 'created_at'],
    )->to_sql
    # INSERT INTO users (name) VALUES (?) RETURNING id, created_at

## update

    $q->update(
        -table     => $table,
        -set       => \%assignments,
        -where     => $condition,
        -from      => $table_or_arrayref,  # PostgreSQL FROM
        -returning => \@cols,
    )->to_sql

### Simple Update

    $q->update(
        -table => 'users',
        -set   => { status => 'inactive', updated_at => $q->now },
        -where => { last_login => { '<' => '2023-01-01' } },
    )->to_sql
    # UPDATE users SET status = ?, updated_at = NOW() WHERE last_login < ?

### Update With Join (MySQL Style)

    $q->update(
        -table => ['users|u', $q->join('orders|o', 'u.id = o.user_id')],
        -set   => { 'u.last_order' => $q->col('o.created_at') },
        -where => { 'o.status' => 'completed' },
    )->to_sql
    # UPDATE users u JOIN orders o ON u.id = o.user_id
    # SET u.last_order = o.created_at
    # WHERE o.status = ?

### Update With From (PostgreSQL Style)

    $q->update(
        -table => 'users',
        -set   => { score => $q->col('s.new_score') },
        -from  => [
            $q->select(
                -columns  => ['user_id', $q->func('AVG', 'points')->as('new_score')],
                -from     => 'scores',
                -group_by => 'user_id',
            )->as('s'),
        ],
        -where => { 'users.id' => $q->col('s.user_id') },
    )->to_sql

## delete

    $q->delete(
        -from      => $table,
        -where     => $condition,
        -using     => $table,       # PostgreSQL USING
        -returning => \@cols,
    )->to_sql

### Simple Delete

    $q->delete(
        -from  => 'users',
        -where => { status => 'deleted', last_login => { '<' => '2020-01-01' } },
    )->to_sql
    # DELETE FROM users WHERE last_login < ? AND status = ?

### Delete With Subquery

    $q->delete(
        -from  => 'users',
        -where => {
            id => { -not_in => $q->select(-columns => ['user_id'], -from => 'active_sessions') },
        },
    )->to_sql
    # DELETE FROM users WHERE id NOT IN (SELECT user_id FROM active_sessions)

### Delete With Using (PostgreSQL)

    $q->delete(
        -from  => 'orders',
        -using => 'users',
        -where => {
            'orders.user_id' => $q->col('users.id'),
            'users.status'   => 'banned',
        },
    )->to_sql
    # DELETE FROM orders USING users WHERE orders.user_id = users.id AND users.status = ?

## Query Modification

SELECT expressions are immutable. These methods return a modified copy without
changing the original:

    my $base    = $q->select(-from => 'users', -where => { status => 'active' });
    my $admins  = $base->add_where({ role => 'admin' });
    my $sorted  = $admins->order_by('name');
    my $page2   = $sorted->limit(20)->offset(20);
    my $counted = $base->columns([$q->func('COUNT', '*')->as('total')]);

    $base->to_sql;     # SELECT * FROM users WHERE status = ?
    $admins->to_sql;   # SELECT * FROM users WHERE status = ? AND role = ?
    $page2->to_sql;    # ... ORDER BY name LIMIT 20 OFFSET 20
    $counted->to_sql;  # SELECT COUNT(*) AS total FROM users WHERE status = ?

### Distinct

    $select->distinct

Returns a new SELECT with the DISTINCT keyword added.

### Where

    $select->where(\%condition)
    $select->where(undef)

Returns a new SELECT with the WHERE clause replaced. Pass `undef` to remove
the WHERE clause entirely.

    my $filtered = $base->where({ role => 'admin' });
    my $all      = $base->where(undef);

### add\_where

    $select->add_where(\%extra_condition)

Returns a new SELECT with the extra condition ANDed onto the existing WHERE.

### columns

    $select->columns(\@new_columns)

Returns a new SELECT with a replaced column list.

### order\_by

    $select->order_by('name')
    $select->order_by('-name')                    # name DESC
    $select->order_by($q->col('name')->desc, 'id')

Returns a new SELECT with the given ORDER BY clause (replaces any existing one).
The `'-col'` shorthand for DESC works here as well.

### limit

    $select->limit(20)

Returns a new SELECT with the given LIMIT.

### offset

    $select->offset(40)

Returns a new SELECT with the given OFFSET.

Compound queries (UNION etc.) also support `order_by`, `limit`, and `offset`
as modifiers that apply to the full compound result.

## Usage With DBI

    use DBI;
    use SQL::Wizard;

    my $dbh = DBI->connect('dbi:Pg:dbname=mydb', 'user', 'pass');
    my $q   = SQL::Wizard->new;

    my ($sql, @bind) = $q->select(
        -columns => ['id', 'name', 'email'],
        -from    => 'users',
        -where   => { status => 'active' },
        -limit   => 100,
    )->to_sql;

    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    my $rows = $sth->fetchall_arrayref({});

## SQL Injection Protection

SQL::Wizard uses multiple layers of defense against SQL injection:

### Bind Parameters By Default

All data values are rendered as `?` placeholders with bind parameters.
This includes `-where` values, `-values` in INSERT, `-set` values in
UPDATE, and `-limit`/`-offset`. User data never becomes literal SQL.

### Automatic Identifier Quoting

Identifiers (column names, table names, aliases, etc.) are automatically
quoted when they are SQL reserved words, contain uppercase characters, or
contain special characters. ANSI double quotes are used by default;
MySQL backticks are used with `dialect => 'mysql'`. Embedded quote
characters are escaped by doubling, making injection through identifiers
structurally impossible.

### Input Validation

On top of quoting, identifiers are validated against strict patterns as
defense in depth:

- WHERE operators are checked against a whitelist
- Function names must match `\w+`
- Aliases must match `\w+`
- Table names must match `(\w+\.)*\w+(\|\w+)?`
- Column and ORDER BY names must match `(\w+\.)*\w+`
- CAST types must match `\w[\w\s(),]*`
- Window names must match `\w+`
- LIMIT and OFFSET must be integers

### Injection Guard On Raw SQL Strings

Freeform SQL strings — string ON conditions in joins, plain string WHERE
clauses, and window frame specifications — are checked against an injection
guard that rejects `;` (statement terminators) and `GO` (SQL Server batch
separators).

### The raw() Escape Hatch

`$q->raw(...)` is the only way to inject literal SQL into the query
tree. **Never pass untrusted user input to `raw()`.** It is intended for
database-specific constructs that the API does not support natively:

    # Safe: hardcoded SQL with bind params
    $q->raw('NOW() - INTERVAL ? DAY', $days)

    # DANGEROUS: user input in raw SQL
    $q->raw($user_input)   # DO NOT DO THIS

## Inspiration

The closest equivalents in other languages are Ruby's Sequel and Python's
SQLAlchemy Core. SQL::Wizard brings that level of SQL composability to Perl.

## See Also

- [SQL::Abstract](https://metacpan.org/pod/SQL%3A%3AAbstract) — hash/arrayref to WHERE clause and basic CRUD
- [SQL::Abstract::More](https://metacpan.org/pod/SQL%3A%3AAbstract%3A%3AMore) — extends SQL::Abstract with joins, limit, column syntax
- [SQL::Abstract::Classic](https://metacpan.org/pod/SQL%3A%3AAbstract%3A%3AClassic) — the pre-v2 SQL::Abstract API
- [SQL::Maker](https://metacpan.org/pod/SQL%3A%3AMaker) — alternative hash to SQL generator
- [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) — full ORM built on SQL::Abstract

## Author

Thomas Busch <tbusch@cpan.org>

## License

MIT License

Copyright (c) 2026 Thomas Busch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
