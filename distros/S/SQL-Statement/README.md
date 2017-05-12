# NAME

SQL::Statement - SQL parsing and processing engine

# SYNOPSIS

    # ... depends on what you want to do, see below

# DESCRIPTION

The SQL::Statement module implements a pure Perl SQL parsing and execution
engine. While it by no means implements full ANSI standard, it does support
many features including column and table aliases, built-in and user-defined
functions, implicit and explicit joins, complex nested search conditions,
and other features.

SQL::Statement is a small embeddable Database Management System
(DBMS). This means that it provides all of the services of a simple
DBMS except that instead of a persistent storage mechanism, it has two
things: 1) an in-memory storage mechanism that allows you to prepare,
execute, and fetch from SQL statements using temporary tables and 2) a
set of software sockets where any author can plug in any storage
mechanism.

There are three main uses for SQL::Statement. One or another (hopefully not
all) may be irrelevant for your needs: 1) to access and manipulate data in
CSV, XML, and other formats 2) to build your own DBD for a new data source
3) to parse and examine the structure of SQL statements.

# INSTALLATION

There are no prerequisites for using this as a standalone parser. If
you want to access persistent stored data, you either need to write a
subclass or use one of the DBI DBD drivers.  You can install this
module using CPAN.pm, CPANPLUS.pm, PPM, apt-get, or other packaging
tools or you can download the tar.gz file from CPAN and use the
standard perl mantra:

    perl Makefile.PL
    make
    make test
    make install

It works fine on all platforms it has been tested on. On Windows, you
can use ppm or with the mantra use nmake, dmake, or make depending on
which is available.

# USAGE

## How can I use SQL::Statement to access and modify data?

SQL::Statement provides the SQL engine for a number of existing DBI drivers
including [DBD::CSV](https://metacpan.org/pod/DBD::CSV), [DBD::DBM](https://metacpan.org/pod/DBD::DBM), [DBD::AnyData](https://metacpan.org/pod/DBD::AnyData), [DBD::Excel](https://metacpan.org/pod/DBD::Excel),
[DBD::Amazon](https://metacpan.org/pod/DBD::Amazon), and others.

These modules provide access to Comma Separated Values, Fixed Length, XML,
HTML and many other kinds of text files, to Excel Spreadsheets, to BerkeleyDB
and other DBM formats, and to non-traditional data sources like on-the-fly
Amazon searches.

If you are interested in accessing and manipulating persistent data, you may
not really want to use SQL::Statement directly, but use [DBI](https://metacpan.org/pod/DBI) along with
one of the DBDs mentioned above instead. You will be using SQL::Statement, but
under the hood of the DBD. See [http://dbi.perl.org](http://dbi.perl.org) for help with DBI and
see [SQL::Statement::Syntax](https://metacpan.org/pod/SQL::Statement::Syntax) for a description of the SQL syntax that
SQL::Statement provides for these modules and see the documentation for
whichever DBD you are using for additional details.

## How can I use it to parse and examine the structure of SQL statements?

SQL::Statement can be used stand-alone (without a subclass and without
DBI) to parse and examine the structure of SQL statements.  See
[SQL::Statement::Structure](https://metacpan.org/pod/SQL::Statement::Structure) for details.

## How can I use it to embed a SQL engine in a DBD or other module?

SQL::Statement is designed to be easily embedded in other modules and is
especially suited for developing new DBI drivers (DBDs).
See [SQL::Statement::Embed](https://metacpan.org/pod/SQL::Statement::Embed).

## What SQL Syntax is supported?

SQL::Statement supports a small but powerful subset of SQL commands.
See [SQL::Statement::Syntax](https://metacpan.org/pod/SQL::Statement::Syntax).

## How can I extend the supported SQL syntax?

You can modify and extend the SQL syntax either by issuing SQL commands or
by subclassing SQL::Statement.  See [SQL::Statement::Syntax](https://metacpan.org/pod/SQL::Statement::Syntax).

# How can I participate in ongoing development?

SQL::Statement is a large module with many potential future directions.
You are invited to help plan, code, test, document, or kibbitz about these
directions. If you want to join the development team, or just hear more
about the development, write Jeff (&lt;jzuckerATcpan.org>) or Jens
(&lt;rehsackATcpan.org>) a note.

# METHODS

The following methods can or must be overridden by derived classes.

## capability

    $has_capability = $h->capability('capability_name');

Returns a true value if the specified capability is available.

Currently no capabilities are defined and this is a placeholder for
future use. It is envisioned it will be used like `SQL::Eval::Table::capability`.

## open\_table

The `open_table` method must be overridden by derived classes to provide
the capability of opening data tables. This is a necessity.

Arguments given to open\_table call:

- `$data`

    The database memo parameter. See ["execute"](#execute).

- `$table`

    The name of the table to open as parsed from SQL statement.

- `$createMode`

    A flag indicating the mode (`CREATE TABLE ...`) the table should
    be opened with. Set to a true value in create mode.

- `$lockMode`

    A flag indicating whether the table should be opened for writing (any
    other than `SELECT ...`).  Set to a true value if the table is to
    be opened for write access.

The following methods are required to use SQL::Statement in a DBD (for
example).

## new

Instantiates a new SQL::Statement object.

Arguments:

- `$sql`

    The SQL statement for later actions.

- `$parser`

    An instance of a [SQL::Parser](https://metacpan.org/pod/SQL::Parser) object or flags for it's instantiation.
    If omitted, default flags are used.

When the basic initialization is completed,
`$self->prepare($sql, $parser)` is invoked.

## prepare

Prepares SQL::Statement to execute a SQL statement.

Arguments:

- `$sql`

    The SQL statement to parse and prepare.

- `$parser`

    Instance of a [SQL::Parser](https://metacpan.org/pod/SQL::Parser) object to parse the provided SQL statement.

## execute

Executes a prepared statement.

Arguments:

- `$data`

    Memo field passed through to calls of the instantiated `$table`
    objects or `open_table` calls. In `CREATE` with subquery,
    `$data->{Database}` must be a DBI database handle object.

- `$params`

    Bound params via DBI ...

## errstr

Gives the error string of the last error, if any.

## fetch\_row

Fetches the next row from the result data set (implies removing the fetched
row from the result data set).

## fetch\_rows

Fetches all (remaining) rows from the result data set.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SQL::Statement

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQL-Statement](http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQL-Statement)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/SQL-Statement](http://annocpan.org/dist/SQL-Statement)

- CPAN Ratings

    [http://cpanratings.perl.org/s/SQL-Statement](http://cpanratings.perl.org/s/SQL-Statement)

- CPAN Search

    [http://search.cpan.org/dist/SQL-Statement/](http://search.cpan.org/dist/SQL-Statement/)

## Where can I go for help?

For questions about installation or usage, please ask on the
dbi-users@perl.org mailing list (see http://dbi.perl.org) or post a
question on PerlMonks ([http://www.perlmonks.org/](http://www.perlmonks.org/), where Jeff is
known as jZed).  Jens does not visit PerlMonks on a regular basis.

If you have a bug report, a patch or a suggestion, please open a new
report ticket at CPAN (but please check previous reports first in case
your issue has already been addressed). You can mail any of the module
maintainers, but you are more assured of an answer by posting to
the dbi-users list or reporting the issue in RT.

Report tickets should contain a detailed description of the bug or
enhancement request and at least an easily verifiable way of
reproducing the issue or fix. Patches are always welcome, too.

## Where can I go for help with a concrete version?

Bugs and feature requests are accepted against the latest version
only. To get patches for earlier versions, you need to get an
agreement with a developer of your choice - who may or not report the
issue and a suggested fix upstream (depends on the license you have
chosen).

## Business support and maintenance

For business support you can contact Jens via his CPAN email
address rehsackATcpan.org. Please keep in mind that business
support is neither available for free nor are you eligible to
receive any support based on the license distributed with this
package.

# ACKNOWLEDGEMENTS

Jochen Wiedmann created the original module as an XS (C) extension in 1998.
Jeff Zucker took over the maintenance in 2001 and rewrote all of the C
portions in Perl and began extending the SQL support.  More recently Ilya
Sterin provided help with SQL::Parser, Tim Bunce provided both general and
specific support, Dan Wright and Dean Arnold have contributed extensively
to the code, and dozens of people from around the world have submitted
patches, bug reports, and suggestions.

In 2008 Jens Rehsack took over the maintenance of the extended module
from Jeff.  Together with H.Merijn Brand (who has taken DBD::CSV),
Detlef Wartke and Volker Schubbert (especially between 1.16 developer
versions until 1.22) and all submitters of bug reports via RT a lot of
issues have been fixed.

Thanks to all!

If you're interested in helping develop SQL::Statement or want to use it
with your own modules, feel free to contact Jeff or Jens.

# BUGS AND LIMITATIONS

- Currently we treat NULL and '' as the same in AnyData/CSV mode -
eventually fix.
- No nested C-style comments allowed as SQL99 says.
- There are some issues regarding combining outer joins with where
clauses.
- Aggregate functions cannot be used in where clause.
- Some SQL commands/features are not supported (most of them cannot by
design), as `LOCK TABLE`, using indices, sub-selects etc.

    Currently the statement for missing features is: I plan to create a
    SQL::Statement v2.00 based on a pure Backus-Naur-Form parser and a
    fully object oriented command pattern based engine implementation.
    When the time is available, I will do it. Until then bugs will be
    fixed or other Perl modules under my maintainership will receive my
    time. Features which can be added without deep design changes might be
    applied earlier - especially when their addition allows studying
    effective ways to implement the feature in upcoming 2.00.

- Some people report that SQL::Statement is slower since the XS parts
were implemented in pure Perl. This might be true, but on the other
hand a large number of features have been added including support for
ANSI SQL 99.

    For SQL::Statement 1.xx it's not planned to add new XS parts.

- Wildcards are expanded to lower cased identifiers. This might confuse
some people, but it was easier to implement.

    The warning in [DBI](https://metacpan.org/pod/DBI) to never trust the case of returned column names
    should be read more often. If you need to rely on identifiers, always
    use `sth->{NAME_lc}` or `sth->{NAME_uc}` - never rely on
    `sth->{NAME}`:

        $dbh->{FetchHashKeyName} = 'NAME_lc';
        $sth = $dbh->prepare("SELECT FOO, BAR, ID, NAME, BAZ FROM TABLE");
        $sth->execute;
        $hash_ref = $sth->fetchall_hashref('id');
        print "Name for id 42 is $hash_ref->{42}->{name}\n";

    See ["FetchHashKeyName" in DBI](https://metacpan.org/pod/DBI#FetchHashKeyName) for more information.

- Unable to use the same table twice with different aliases. **Workaround**:
Temporary tables: `CREATE TEMP TABLE t_foo AS SELECT * FROM foo`.
Than both tables can be used independently.

Patches to fix bugs/limitations (or a grant to do it) would be
very welcome. Please note, that any patches **must** successfully pass
all the `SQL::Statement`, [DBD::File](https://metacpan.org/pod/DBD::File) and [DBD::CSV](https://metacpan.org/pod/DBD::CSV) tests and must
be a general improvement.

# AUTHOR AND COPYRIGHT

Jochen Wiedmann created the original module as an XS (C) extension in 1998.
Jeff Zucker took over the maintenance in 2001 and rewrote all of the C
portions in perl and began extending the SQL support. Since 2008, Jens
Rehsack is the maintainer.

Copyright (c) 2001,2005 by Jeff Zucker: jzuckerATcpan.org
Copyright (c) 2007-2016 by Jens Rehsack: rehsackATcpan.org

Portions Copyright (C) 1998 by Jochen Wiedmann: jwiedATcpan.org

All rights reserved.

You may distribute this module under the terms of either the GNU
General Public License or the Artistic License, as specified in
the Perl README file.
