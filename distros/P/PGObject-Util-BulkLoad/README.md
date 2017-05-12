# NAME
[![Build Status](https://travis-ci.org/binary-com/perl-PGObject-Util-BulkLoad.svg?branch=master)](https://travis-ci.org/binary-com/perl-PGObject-Util-BulkLoad)
[![codecov](https://codecov.io/gh/binary-com/perl-PGObject-Util-BulkLoad/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-PGObject-Util-BulkLoad)

PGObject::Util::BulkLoad - Bulk load records into PostgreSQL

# VERSION

Version 0.04

# SYNOPSIS

To insert all rows into a table using COPY:

    PGObject::Util::BulkLoad->copy(
        {table => 'mytable', insert_cols => ['col1', 'col2'], dbh => $dbh}, 
        @objects
    );

To copy to a temp table and then upsert:

    PGObject::Util::BulkLoad->upsert(
        {table       => 'mytable', 
         insert_cols => ['col1', 'col2'], 
         update_cols => ['col1'],
         key_cols    => ['col2'],
         dbh         => $dbh}, 
        @objects
    );

Or if you prefer to run the statements yourself:

    PGObject::Util::BulkLoad->statement(
       table => 'mytable', type  => 'temp', tempname => 'foo_123'
    );
    PGObject::Util::BulkLoad->statement(
       table => 'mytable', type  => 'copy', insert_cols => ['col1', 'col2']
    );
    PGObject::Util::BulkLoad->statement(
        type        => 'upsert',
        tempname    => 'foo_123',
        table       => 'mytable',
        insert_cols => ['col1', 'col2'],
        update_cols => ['col1'],
        key_cols    => ['col2']
    );

If you are running repetitive calls, you may be able to trade time for memory 
using Memoize by unning the following:

    PGObject::Util::BulkLoad->memoize_statements;

To unmemoize:

    PGObject::Util::BulkLoad->unmemoize;

To flush cache

    PGObject::Util::BulkLoad->flush_memoization;

# DESCRIPTION

# SUBROUTINES/METHODS

## memoize\_statements

This function exists to memoize statement calls, i.e. generate the exact same 
statements on the same argument calls.  This isn't too likely to be useful in
most cases but it may be if you have repeated bulk loader calls in a persistent
script (for example real-time importing of csv data from a frequent source).

## unmemoize 

Unmemoizes the statement calls.

## flush\_memoization

Flushes the cache for statement memoization.  Does \*not\* flush the cache for
escaping memoization since that is a bigger win and a pure function accepting
simple strings.

## statement

This takes the following arguments and returns a suitable SQL statement

- type 

    Type of statement.  Options are:

    - temp

        Create a temporary table

    - copy

        sql COPY statement

    - upsert

        Update/Insert CTE pulling temp table

    - stats

        Get stats on pending upsert, grouped by an arbitrary column.

- table

    Name of table

- tempname

    Name of temp table

- insert\_cols

    Column names for insert

- update\_cols

    Column names for update

- key\_cols

    Names of columns in primary key.

- group\_stats\_by

    Names of columns to group stats by

## upsert

Creates a temporary table named "pg\_object.bulkload" and copies the data there

If the first argument is an object, then if there is a function by the name 
of the object, it will provide the value.

- table

    Table to upsert into

- insert\_cols

    Columns to insert (by name)

- update\_cols

    Columns to update (by name)

- key\_cols

    Key columns (by name)

- group\_stats\_by

    This is an array of column names for optional stats retrieval and grouping.
    If it is set then we will grab the stats and return them.  Note this has a 
    performance penalty because it means an extra scan of the temp table and an
    extra join against the parent table.  See get\_stats for the return value
    information if this is set.

## copy

Copies data into the specified table.  The following arguments are used:

- table

    Table to upsert into

- insert\_cols

    Columns to insert (by name)

## get\_stats

Takes the same arguments as upsert plus group\_stats\_by

Returns an array of hashrefs representing the number of inserts and updates
that an upsert will perform.  It must be performed before the upsert statement
actually runs.  Typically this is run via the upsert command (which 
automatically runs this if group\_stats\_by is set in the argumements hash).

There is a performance penalty here since an unindexed left join is required 
between the temp and the normal table.

This function requires tempname, table, and group\_stats\_by to be set in the
argument hashref.  The return value is a list of hashrefs with the following 
keys:

- stats

    Hashref with keys inserts and updates including numbers of rows.

- keys

    Hashref for key columns and their values, by name

# AUTHOR

Chris Travers, `<chris.travers at gmail.com>`

# CO-MAINTAINERS

- Binary.com, `<perl at binary.com>`

# BUGS

Please report any bugs or feature requests to `bug-pgobject-util-bulkupload at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-BulkLoad](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-BulkLoad).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::BulkLoad

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-BulkLoad](http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-BulkLoad)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/PGObject-Util-BulkLoad](http://annocpan.org/dist/PGObject-Util-BulkLoad)

- CPAN Ratings

    [http://cpanratings.perl.org/d/PGObject-Util-BulkLoad](http://cpanratings.perl.org/d/PGObject-Util-BulkLoad)

- Search CPAN

    [http://search.cpan.org/dist/PGObject-Util-BulkLoad/](http://search.cpan.org/dist/PGObject-Util-BulkLoad/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2014 Chris Travers.

This program is distributed under the (Revised) BSD License:
[http://www.opensource.org/licenses/BSD-3-Clause](http://www.opensource.org/licenses/BSD-3-Clause)

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

\* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

\* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

\* Neither the name of Chris Travers's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
