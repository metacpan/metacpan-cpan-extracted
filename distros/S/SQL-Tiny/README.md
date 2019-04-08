# SQL::Tiny, a Perl module for generating simple SQL statements

A very simple SQL-building library.  It's not for all your SQL needs,
only the very simple ones.

It doesn't handle JOINs.  It doesn't handle subselects.  It's only for simple SQL.

    my ($sql,$binds) = sql_select( 'users', [ 'name', 'status' ], { status => [ 'Deleted', 'Inactive' ] }, { order_by => 'name' } );

    my ($sql,$binds) = sql_insert( 'users', { name => 'Dave', status => 'Active' } );

    my ($sql,$binds) = sql_update( 'users', { status => 'Inactive' }, { password => undef } );

    my ($sql,$binds) = sql_delete( 'users', { status => 'Inactive' } );

In my test suites, I have a lot of ad hoc SQL queries, and it drives me
nuts to have so much SQL code lying around.  SQL::Tiny is for generating
SQL code for simple cases.

I'd far rather have:

    my ($sql,$binds) = sql_insert(
        'users',
        {
            name      => 'Dave',
            salary    => 50000,
            status    => 'Active',
            dateadded => \'SYSDATE()',
        }
    );

than hand-coding:

    my $sql   = 'INSERT INTO users (name,salary,status,dateadded) VALUES (:name,:status,:salary,SYSDATE())';
    my $binds = {
        ':name'      => 'Dave',
        ':salary'    => 50000,
        ':status'    => 'Active',
        ':dateadded' => \'SYSDATE()',
    };

or even the positional:

    my $sql   = 'INSERT INTO users (name,salary,status,dateadded) VALUES (?,?,?,SYSDATE())';
    my $binds = [ 'Dave', 50000, 'Active' ];

# Build status of dev branch

* Travis (Linux) [![Build Status](https://travis-ci.org/petdance/sql-tiny.png?branch=dev)](https://travis-ci.org/petdance/sql-tiny)
* [CPAN Testers](https://cpantesters.org/distro/S/sql-tiny.html)

# Installation

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

# Support and Documentation

After installing, you can find documentation for this module with the
perldoc command.

    perldoc SQL::Tiny

You can also look for information at:

    MetaCPAN
        https://metacpan.org/release/SQL-Tiny

    Project home page
        https://github.com/petdance/sql-tiny

    Project issue tracker
        https://github.com/petdance/sql-tiny/issues

# License and Copyright

Copyright (C) 2019 Andy Lester

This program is free software; you can redistribute it and/or modify it
under the terms of the the
[Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).
