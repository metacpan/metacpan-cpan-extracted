# NAME

PDL::IO::DBI - Create PDL from database (optimized for speed and large data)

# SYNOPSIS

    use PDL;
    use PDL::IO::DBI ':all';

    # simple usage - using DSN + SQL query
    my $sql = "select ymd, open, high, low, close from quote where symbol = 'AAPL' AND ymd >= 20140404 order by ymd";
    my $pdl = rdbi2D("dbi:SQLite:dbname=Quotes.db", $sql);

    use DBI;

    # using DBI handle + SQL query with binded values
    my $dbh = DBI->connect("dbi:Pg:dbname=QDB;host=localhost", 'username', 'password');
    my $sql = "select ymd, open, high, low, close from quote where symbol = ? AND ymd >= ? order by ymd";
    # rdbi2D
    my $pdl = rdbi2D($dbh, $sql, ['AAPL', 20140104]);                     # 2D piddle
    # rdbi1D
    my ($y, $o, $h, $l, $c) = rdbi1D($dbh, $sql, ['AAPL', 20140104]);     # 5x 1D piddle (for each column)

    # using DBI handle + SQL query with binded values + extra options
    my $dbh = DBI->connect("dbi:Pg:dbname=QDB;host=localhost", 'username', 'password');
    my $sql = "select ymd, open, high, low, close from quote where symbol = ? AND ymd >= ? order by ymd";
    my $pdl = rdbi2D($dbh, $sql, ['AAPL', 20140104], { type=>float, fetch_chunk=>100000, reshape_inc=>100000 });

# DESCRIPTION

For creating a piddle from database data one can use the following simple approach:

    use PDL;
    use DBI;
    my $dbh = DBI->connect($dsn);
    my $pdl = pdl($dbh->selectall_arrayref($sql_query));

However this approach does not scale well for large data (e.g. SQL queries resulting in millions of rows).

This module is optimized for creating piddles populated with very large database data. It currently **supports only
reading data from database** not updating/inserting to DB.

The goal of this module is to be as fast as possible. It is designed to silently converts anything into a number
(wrong or undefined values are converted into `0`).

# FUNCTIONS

By default, PDL::IO::DBI doesn't import any function. You can import individual functions like this:

    use PDL::IO::DBI 'rdbi2D';

Or import all available functions:

    use PDL::IO::DBI ':all';

## rdbi1D

Queries the database and stores the data into 1D piddles.

    $sql_query = "SELECT high, low, avg FROM data where year > 2010";
    my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query);
    #or
    my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query, \@sql_query_params);
    #or
    my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query, \@sql_query_params, \%options);
    #or
    my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query, \%options);

Example:

    my ($id, $high, $low) = rdbi1D($dbh, 'SELECT id, high, low FROM sales ORDER by id');

    # column types:
    #   id   .. INTEGER
    #   high .. NUMERIC
    #   low  .. NUMERIC

    print $id->info, "\n";
    PDL: Long D [100000]          # == 1D piddle, 100 000 rows from DB

    print $high->info, "\n";
    PDL: Double D [100000]        # == 1D piddle, 100 000 rows from DB

    print $low->info, "\n";
    PDL: Double D [100000]        # == 1D piddle, 100 000 rows from DB

    # column names (lowercase) are stored in loaded piddles in $pdl->hdr->{col_name}
    print $id->hdr->{col_name},   "\n";  # prints: id
    print $high->hdr->{col_name}, "\n";  # prints: high
    print $low->hdr->{col_name},  "\n";  # prints: low

Parameters:

- dbh\_or\_dsn

    [DBI](https://metacpan.org/pod/DBI) handle of database connection or data source name.

- sql\_query

    SQL query.

- sql\_query\_params

    Optional bind values that can be used for queries with placeholders.

Items supported in **options** hash:

- type

    Defines the type of output piddles: `double`, `float`, `longlong`, `long`, `short`, `byte`.
    Default value is `auto` which means that the type of the output piddles is auto detected.
    **BEWARE:** type \`longlong\` can be used only on perls with 64bitint support.

    You can set one type for all columns/piddles:

        my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query, {type => double});

    or separately for each column/piddle:

        my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query, {type => [long, double, double]});

- fetch\_chunk

    We do not try to load all query results into memory at once, we load them in chunks defined by this parameter.
    Default value is `8000` (rows). If `reuse_sth` is true, `rdbi1D` will
    return one chunk per call, and the number of rows in a chunk will never exceed
    `fetch_chunk`.

- reshape\_inc

    As we do not try to load all query results into memory at once; we also do not know at the beginning how
    many rows there will be. Therefore we do not know how big piddle to allocate, we have to incrementally
    (re)allocate the piddle by increments defined by this parameter. Default value is `80000` (unless
    `reuse_sth` is used).

    If you know how many rows there will be you can improve performance by setting this parameter to expected row count.

    If you are using `reuse_sth`, `reshape_inc` is by default equal to
    `fetch_chunk` to avoid reallocations, but you could set it to a different
    value if you wanted to.

- null2bad

    Values `0` (default) or `1` - convert NULLs to BAD values (there is a performance cost when turned on).

- reuse\_sth

    Whether to reuse the statement handle used to fetch the rows.

    When `reuse_sth` is `false`, all rows matching the select statement are
    fetched at once, and the statement handle is never reused. Every new call to
    rdbi1D will rerun the select statement and fetch the same rows again.

    When `reuse_sth` is not `false`, it must be a reference (either to undef,
    or to a statement handle). In this case, the operation mode changes: rdbi1D
    will try to fetch `fetch_chunk` rows from the database, **and will return
    early**. It will reuse the statement handle passed in via `reuse_sth`. If a
    reference to `undef` is passed, rdbi1D will initialize the statement handle
    itself. The idea is that you call rdbi1D repeatedly to obtain subsets of the
    total number of rows in the database matching the select statement. This can be
    useful if the logic to handle subsets is already present in your code, and you
    don't need all rows in memory at once.

    As an example, suppose you are calculating a minimum value. (You would probably
    do this in the database directly, but it makes for a simple example.) You don't
    need to have all matching rows in memory at once. Fetching chunk by chunk will
    do just fine:

        my $N = 500_000;
        my $minimum;
        my $sth;
        for (;;) {
          my ($values) = rdbi1D($dbh, "SELECT value FROM table", {reuse_sth => \$sth, fetch_chunk => $N});
          last unless $sth;
          if (!defined($minimum) || $values->minimum->sclr < $minimum) { $minimum = $values->minimum->sclr }
        }

    You can avoid the allocation of a single large PDL in this way. This wouldn't
    help you much if the database was small. But if it was so large the resulting
    PDL didn't fit in memory, working in chunks allows you to process all of the
    data. Note that `reshape_inc` will be set to the same value as `fetch_chunk`
    to avoid a reallocation to the chunk size, unless you explicitly set
    `reshape_inc` to another value.

    Note that rdbi1D sets the reused statement handle to `undef` if there are no
    more chunks, i.e., when the database query returns no rows. You can use this to
    your advantage to terminate the loop fetching the chunks, without having to
    count the rows yourself.

- debug

    Values `0` (default) or `1` - turn on/off debug messages

## rdbi2D

Queries the database and stores the data into a 2D piddle.

    my $pdl = rdbi2D($dbh_or_dsn, $sql_query);
    #or
    my $pdl = rdbi2D($dbh_or_dsn, $sql_query, \@sql_query_params);
    #or
    my $pdl = rdbi2D($dbh_or_dsn, $sql_query, \@sql_query_params, \%options);
    #or
    my $pdl = rdbi2D($dbh_or_dsn, $sql_query, \%options);

Example:

    my $pdl = rdbi2D($dbh, 'SELECT id, high, low FROM sales ORDER by id');

    # column types:
    #   id   .. INTEGER
    #   high .. NUMERIC
    #   low  .. NUMERIC

    print $pdl->info, "\n";
    PDL: Double D [100000, 3]     # == 2D piddle, 100 000 rows from DB

Parameters and items supported in `options` hash are the same as by ["rdbi1D"](#rdbi1d).
`reuse_sth` is not supported yet for ["rdbi2D"](#rdbi2d).

# Handling DATE, DATETIME, TIMESTAMP database types

By default DATETIME values are converted to `double` value representing epoch seconds e.g.

    # 1970-01-01T00:00:01.001     >>          1.001
    # 2000-12-31T12:12:12.5       >>  978264732.5
    # BEWARE: timestamp is truncated to milliseconds
    # 2000-12-31T12:12:12.999001  >>  978264732.999
    # 2000-12-31T12:12:12.999999  >>  978264732.999

If you specify an output type `longlong` for DATETIME column then the DATETIME values are converted
to `longlong` representing epoch microseconds e.g.

    # 1970-01-01T00:00:01.001        >>          1001000
    # 2000-12-31T12:12:12.5          >>  978264732500000
    # 2000-12-31T12:12:12.999999     >>  978264732999999
    # BEWARE: timestamp is truncated to microseconds
    # 2000-12-31T12:12:12.999999001  >>  978264732999999
    # 2000-12-31T12:12:12.999999999  >>  978264732999999

If you have [PDL::DateTime](https://metacpan.org/pod/PDL::DateTime) installed then rcsv1D automaticcally converts DATETIME columns
to [PDL::DateTime](https://metacpan.org/pod/PDL::DateTime) piddles:

    # autodetection - same as: type=>'auto'
    my ($datetime_piddle, $pr) = rdbi1D("select mydate, myprice from sales");

    # or you can explicitely use type 'datetime'
    my ($datetime_piddle, $pr) = rdbi1D("select mydate, myprice from sales", {type=>['datetime', double]});

# SEE ALSO

[PDL](https://metacpan.org/pod/PDL), [DBI](https://metacpan.org/pod/DBI)

# LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# COPYRIGHT

2014+ KMX <kmx@cpan.org>
