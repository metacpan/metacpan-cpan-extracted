package SQL::AlterTable::SQLite;

our $DATE = '2016-07-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       gen_sql_alter_table
               );

our %SPEC;

$SPEC{gen_sql_alter_table} = {
    v => 1.1,
    summary => 'Generate SQL statements to alter a SQLite table',
    description => <<'_',

Performing ALTER TABLE on a SQLite table can be a bit cumbersome. SQLite only
supports a limited ALTER TABLE functionality, i.e. rename a table or add new
columns. For the other functionality, e.g. rename a column or delete/modify
columns, a common technique is to construct a new table with the desired
structure, fill it with rows from the old table, then delete the old table and
rename the new table to the old.

This routine can help. You specify the operations you want, the table
information, and the routine will generate a series of SQL statements.

_
    args => {
        dbh => {
            schema => ['obj*'],
            summary => 'DBI database handle',
            req => 1,
        },
        table => {
            schema => ['str*'],
            summary => 'Table name',
            req => 1,
        },
        rename_table => {
            schema => ['str*'],
            summary => 'New table name',
            tags => ['category:operation'],
        },
        add_columns => {
            schema => ['array*', of=>'str*'], # XXX pairs
            summary => 'Add columns',
            description => <<'_',

Value should be an arrayref of pairs of name-definition.

_
            tags => ['category:operation'],
        },
        delete_columns => {
            schema => ['array*', of=>'str*'],
            summary => 'Delete columns',
            description => <<'_',

Value should be an arrayref of column names to delete.

_
            tags => ['category:operation'],
        },
        modify_columns => {
            schema => ['array*', of=>'str*'], # XXX pairs
            summary => 'Modify columns',
            description => <<'_',

Value should be an arrayref of pairs of name-new definition.

_
            tags => ['category:operation'],
        },
        rename_columns => {
            schema => ['array*', of=>'str*'], # XXX pairs
            summary => 'Rename columns',
            description => <<'_',

Value should be an arrayref of pairs of old column name-new column name.

_
            tags => ['category:operation'],
        },
        # XXX add_indices
        # XXX delete_indices
    },
    result_naked => 1,
    result => {
        schema => ['array*', of=>'str*'],
    },
};
sub gen_sql_alter_table {
    my %args = @_;

    my $dbh    = $args{dbh};
    my $table  = $args{table};

    my @sql;

    # get the current columns of the table (XXX perhaps there should be an
    # option of specifying this, instead of getting from $dbh)
    my $sth = $dbh->column_info(undef, "main", $table, "%");

    my %col_orders;
    my %col_info;
    my $i = 0;
    while (my $row = $sth->fetchrow_hashref) {
        my $col_name = $row->{COLUMN_NAME};
        $col_orders{$col_name} = $i++;
        $col_info{$col_name} = $row;
    }
    die "Can't alter table '$table': table doesn't exist" unless $i;

    my %orig_col_orders = %col_orders;

    my $create_tmp;

    # drop columns
    if ($args{delete_columns}) {
        my @delete_cols = @{ $args{delete_columns} };
        for my $c (@delete_cols) {
            $create_tmp++;
            if (defined $col_orders{$c}) {
                delete $col_orders{$c};
            } else {
                die "Can't delete column '$c': column doesn't exist";
            }
        }
    }

    # modify columns
    my %col_definitions; # for new and modified columns
    if ($args{modify_columns}) {
        my @modify_cols = @{ $args{modify_columns} };
        while (my ($c, $def) = splice @modify_cols, 0, 2) {
            $create_tmp++;
            if (defined $col_orders{$c}) {
                $col_definitions{$c} = $def;
            } else {
                die "Can't modify column '$c': column doesn't exist";
            }
        }
    }

    # rename columns
    my %col_rename_map;
    my %col_rename_rmap;
    if ($args{rename_columns}) {
        my @rename_cols = @{ $args{rename_columns} };
        while (my ($c, $cnew) = splice @rename_cols, 0, 2) {
            $create_tmp++;
            unless (defined $orig_col_orders{$c}) {
                die "Can't rename column '$c' -> '$cnew': ".
                    "column '$c' doesn't exist";
            }
            if (defined $orig_col_orders{$cnew}) {
                die "Can't rename column '$c' -> '$cnew': ".
                    "column '$cnew' already exists";
            }
            $col_orders{$cnew} = delete $col_orders{$c};
            $col_rename_map{$c} = $cnew;
            $col_rename_rmap{$cnew} = $c;
        }
    }

    my $new_table = $args{rename_table} // $table;

    if ($create_tmp) {
        # XXX check that temporary name doesn't exist
        my $tmp_table = "_${table}_tmp";
        my @cols_new = sort { $col_orders{$a} <=> $col_orders{$b} }
            keys %col_orders;
        my @cols_old;
        for my $c (@cols_new) {
            my $c2;
            if (defined $col_rename_rmap{$c}) {
                $c2 = $col_rename_rmap{$c};
            } else {
                $c2 = $c;
            }
            say "D:c2=<$c2>";
            unless ($col_definitions{$c2}) {
                my $colinfo = $col_info{$c2};
                $col_definitions{$c2} = join(
                    "",
                    $colinfo->{TYPE_NAME},
                    $colinfo->{IS_NULLABLE} eq 'YES' ? '' : ' NOT NULL',
                );
            }
            push @cols_old, $c2;
        }
        push @sql, join(
            "",
            "CREATE TABLE \"$tmp_table\" (",
            join(", ", map { "\"$_\" ".$col_definitions{ $col_rename_rmap{$_} // $_ } }
                     @cols_new),
            ")",
        );
        push @sql, join(
            "",
            "INSERT INTO \"$tmp_table\" (",
            join(",", map {"\"$_\""} @cols_new),") ",
            "SELECT ", join(",", map {"\"$_\""} @cols_old)," ",
            "FROM \"$table\"",
        );
        push @sql, "DROP TABLE \"$table\"";
        push @sql, "ALTER TABLE \"$tmp_table\" RENAME TO \"$new_table\"";
    } else {
        push @sql, "ALTER TABLE \"$table\" RENAME TO \"$new_table\""
            if $table ne $new_table;
    }

    # add columns
    if ($args{add_columns}) {
        my @add_cols = @{ $args{add_columns} };
        while (my ($c, $def) = splice @add_cols, 0, 2) {
            if (defined $col_orders{$c}) {
                die "Can't add column '$c': column already exist";
            }
            if ($create_tmp) {
                push @sql, "ALTER TABLE \"$new_table\" ADD COLUMN \"$c\" $def";
            } else {
                $col_orders{$c} = keys(%col_orders);
                $col_definitions{$c} = $def;
            }
        }
    }

    \@sql;
}

1;
# ABSTRACT: Generate SQL statements to alter a SQLite table

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::AlterTable::SQLite - Generate SQL statements to alter a SQLite table

=head1 VERSION

This document describes version 0.003 of SQL::AlterTable::SQLite (from Perl distribution SQL-AlterTable-SQLite), released on 2016-07-10.

=head1 SYNOPSIS

 use SQL::AlterTable::SQLite qw(gen_sql_alter_table);

 my $sql_stmts = gen_sql_alter_table(
     dbh            => $dbh,
     table          => 't',
     delete_columns => ['b'],
     modify_columns => ['a', 'INT NOT NULL'],
     rename_columns => ['a', 'a2'],
     add_columns    => ['c', 'TEXT'],
     rename_table   => 't2',
 );

The result:

 [
     'CREATE TABLE "_t_tmp" ("a2" INT NOT NULL)',
     'INSERT INTO "_t_tmp" ("a2") SELECT "a" FROM "t"',
     'DROP TABLE "t"',
     'ALTER TABLE "_t_tmp" RENAME TO "t2"',
     'ALTER TABLE "t2" ADD COLUMN "c" TEXT',
 ]

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 gen_sql_alter_table(%args) -> array[str]

Generate SQL statements to alter a SQLite table.

Performing ALTER TABLE on a SQLite table can be a bit cumbersome. SQLite only
supports a limited ALTER TABLE functionality, i.e. rename a table or add new
columns. For the other functionality, e.g. rename a column or delete/modify
columns, a common technique is to construct a new table with the desired
structure, fill it with rows from the old table, then delete the old table and
rename the new table to the old.

This routine can help. You specify the operations you want, the table
information, and the routine will generate a series of SQL statements.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_columns> => I<array[str]>

Add columns.

Value should be an arrayref of pairs of name-definition.

=item * B<dbh>* => I<obj>

DBI database handle.

=item * B<delete_columns> => I<array[str]>

Delete columns.

Value should be an arrayref of column names to delete.

=item * B<modify_columns> => I<array[str]>

Modify columns.

Value should be an arrayref of pairs of name-new definition.

=item * B<rename_columns> => I<array[str]>

Rename columns.

Value should be an arrayref of pairs of old column name-new column name.

=item * B<rename_table> => I<str>

New table name.

=item * B<table>* => I<str>

Table name.

=back

Return value:  (array[str])

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQL-AlterTable-SQLite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQL-AlterTable-SQLite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-AlterTable-SQLite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=over

=item * L<SQL::Schema::Versioned>

You can feed the result of C<gen_sql_alter_table()> to
C<SQL::Schema::Versioned>'s C<create_or_update_db_schema>.

=back

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
