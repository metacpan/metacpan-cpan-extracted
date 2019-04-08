package SQL::Tiny;

use 5.010001;
use strict;
use warnings;

=head1 NAME

SQL::Tiny - A very simple SQL-building library

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

use parent 'Exporter';

our @EXPORT_OK = qw(
    sql_select
    sql_insert
    sql_update
    sql_delete
);

our %EXPORT_TAGS = (
    all => [@EXPORT_OK],
);


=head1 SYNOPSIS

    my ($sql,$binds) = sql_select( 'users', [ 'name', 'status' ], { status => [ 'Deleted', 'Inactive' ] }, { order_by => 'name' } );

    my ($sql,$binds) = sql_select( 'users', [ 'COUNT(*)' ], { status => [ 'Deleted', 'Inactive' ] }, { group_by => 'status' } );

    my ($sql,$binds) = sql_insert( 'users', { name => 'Dave', status => 'Active' } );

    my ($sql,$binds) = sql_update( 'users', { status => 'Inactive' }, { password => undef } );

    my ($sql,$binds) = sql_delete( 'users', { status => 'Inactive' } );

=head1 DOCUMENTATION

A very simple SQL-building library.  It's not for all your SQL needs,
only the very simple ones.

It doesn't handle JOINs.  It doesn't handle subselects.  It's only for simple SQL.

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
            qty       => \[ 'ROUND(?)', 14.5 ],
        }
    );

than hand-coding:

    my $sql   = 'INSERT INTO users (name,salary,status,dateadded,qty) VALUES (:name,:status,:salary,SYSDATE(),ROUND(:qty))';
    my $binds = {
        ':name'      => 'Dave',
        ':salary'    => 50000,
        ':status'    => 'Active',
        ':dateadded' => \'SYSDATE()',
        ':qty'       => 14.5,
    };

or even the positional:

    my $sql   = 'INSERT INTO users (name,salary,status,dateadded,qty) VALUES (?,?,?,SYSDATE(),ROUND(?))';
    my $binds = [ 'Dave', 50000, 'Active', 14.5 ];

The trade-off for that brevity of code is that SQL::Tiny has to make new
SQL and binds from the input every time. You can't cache the SQL that
comes back from SQL::Tiny because the placeholders could vary depending
on what the input data is. Therefore, you don't want to use SQL::Tiny
where speed is essential.

The other trade-off is that SQL::Tiny handles only very simple code.
It won't handle JOINs of any kind.

SQL::Tiny isn't meant for all of your SQL needs, only the simple ones
that you do over and over.

=head1 EXPORT

All subs can be exported, but none are by default.  C<:all> exports all subs.

=head1 SUBROUTINES/METHODS

=head2 sql_select( $table, \@columns, \%where [, \%other ] )

Creates simple SELECTs and binds.

The C<%other> can contain C<group_by> and C<order_by>.

Calling:

    my ($sql,$binds) = sql_select(
        'users',
        [qw( userid name )],
        { status => 'X' ],
        { order_by => 'name' },
    );

returns:

    $sql   = 'SELECT userid,name FROM users WHERE status=? ORDER BY name';
    $binds = [ 'X' ];

=cut

sub sql_select {
    my $table   = shift;
    my $columns = shift;
    my $where   = shift;
    my $other   = shift // {};

    my @parts = (
        'SELECT ' . join( ',', @{$columns} ),
        "FROM $table",
    );

    my @binds;

    _build_where_section( \@parts, $where, \@binds );
    _build_by_section( \@parts, 'GROUP BY', $other->{group_by} );
    _build_by_section( \@parts, 'ORDER BY', $other->{order_by} );

    my $sql = join( ' ', @parts );

    return ( $sql, \@binds );
}

=head2 sql_insert( $table, \%values )

Creates simple INSERTs and binds.

Calling:

    my ($sql,$binds) = sql_insert(
        'users',
        {
            serialno   => '12345',
            name       => 'Dave',
            rank       => 'Sergeant',
            height     => undef,
            date_added => \'SYSDATE()',
        }
    );

returns:

    $sql   = 'INSERT INTO users (date_added,height,name,rank,serialno) VALUES (SYSDATE(),NULL,?,?,?)';
    $binds = [ 'Dave', 'Sergeant', 12345 ]

=cut

sub sql_insert {
    my $table  = shift;
    my $values = shift;

    my @parts = (
        "INSERT INTO $table"
    );

    my @values;
    my @binds;

    my @columns = sort keys %{$values};
    for my $key ( @columns ) {
        my $value = $values->{$key};

        if ( !defined($value) ) {
            push @values, 'NULL';
        }
        elsif ( ref($value) eq 'SCALAR' ) {
            push @values, ${$value};
        }
        elsif ( ref($value) eq 'REF' ) {
            my $deepval = ${$value};

            my ($literal,$bind) = @{$deepval};
            push @values, $literal;
            push @binds, $bind;
        }
        else {
            push @values, '?';
            push @binds, $value;
        }
    }

    push @parts, '(' . join( ',', @columns ) . ')';
    push @parts, 'VALUES (' . join( ',', @values ) . ')';
    my $sql = join( ' ', @parts );

    return ( $sql, \@binds );
}


=head2 sql_update( $table, \%values, \%where )

Creates simple UPDATE calls and binds.

Calling:

    my ($sql,$binds) = sql_update(
        'users',
        {
            status     => 'X',
            lockdate   => undef,
        },
        {
            orderdate => \'SYSDATE()',
        },
    );

returns:

    $sql   = 'UPDATE users SET lockdate=NULL, status=? WHERE orderdate=SYSDATE()'
    $binds = [ 'X' ]

=cut

sub sql_update {
    my $table  = shift;
    my $values = shift;
    my $where  = shift;

    my @parts = (
        "UPDATE $table"
    );

    my @columns;
    my @binds;

    for my $key ( sort keys %{$values} ) {
        my $value = $values->{$key};

        if ( !defined($value) ) {
            push @columns, "$key=NULL";
        }
        elsif ( ref($value) eq 'SCALAR' ) {
            push @columns, "$key=${$value}";
        }
        elsif ( ref($value) eq 'REF' ) {
            my $deepval = ${$value};

            my ($literal,$bind) = @{$deepval};
            push @columns, "$key=$literal";
            push @binds, $bind;
        }
        else {
            push @columns, "$key=?";
            push @binds, $value;
        }
    }
    push @parts, 'SET ' . join( ', ', @columns );

    _build_where_section( \@parts, $where, \@binds );

    my $sql = join( ' ', @parts );

    return ( $sql, \@binds );
}


=head2 sql_delete( $table, \%where )

Creates simple DELETE calls and binds.

Calling:

    my ($sql,$binds) = sql_delete(
        'users',
        {
            serialno   => 12345,
            height     => undef,
            date_added => \'SYSDATE()',
            status     => [qw( X Y Z )],
        },
    );

returns:

    $sql   = 'DELETE FROM users WHERE date_added = SYSDATE() AND height IS NULL AND serialno = ? AND status IN (?,?,?)'
    $binds = [ 12345, 'X', 'Y', 'Z' ]

=cut

sub sql_delete {
    my $table = shift;
    my $where = shift;

    my @parts = (
        "DELETE FROM $table"
    );

    my @binds;

    _build_where_section( \@parts, $where, \@binds );

    my $sql = join( ' ', @parts );

    return ( $sql, \@binds );
}


sub _build_where_section {
    my $parts = shift;
    my $where = shift;
    my $binds = shift;

    my @conditions;
    for my $key ( sort keys %{$where} ) {
        my $value = $where->{$key};
        if ( !defined($value) ) {
            push @conditions, "$key IS NULL";
        }
        elsif ( ref($value) eq 'ARRAY' ) {
            push @conditions, "$key IN (" . join( ',', ('?') x @{$value} ) . ')';
            push @{$binds}, @{$value};
        }
        elsif ( ref($value) eq 'SCALAR' ) {
            push @conditions, "$key=${$value}";
        }
        elsif ( ref($value) eq 'REF' ) {
            my $deepval = ${$value};

            my ($literal,$bind) = @{$deepval};
            push @conditions, "$key=$literal";
            push @{$binds}, $bind;
        }
        else {
            push @conditions, "$key=?";
            push @{$binds}, $value;
        }
    }

    if ( @conditions ) {
        push @{$parts}, 'WHERE ' . join( ' AND ', @conditions );
    }

    return;
}


sub _build_by_section {
    my $parts   = shift;
    my $section = shift;
    my $columns = shift;

    if ( $columns ) {
        if ( ref($columns) eq 'ARRAY' ) {
            push @{$parts}, $section . ' ' . join( ',', @{$columns} );
        }
        else {
            push @{$parts}, "$section $columns";
        }
    }

    return;
}


=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/petdance/sql-tiny/issues>, or email me directly.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SQL::Tiny

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/SQL-Tiny>

=item * GitHub issue tracker

L<https://github.com/petdance/sql-tiny/issues>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the following folks for their contributions:
Mohammad S Anwar,
Tim Heaney.

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Andy Lester.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of SQL::Tiny
