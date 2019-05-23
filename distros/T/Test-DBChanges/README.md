# NAME

Test::DBChanges - track changes to database tables

# SYNOPSIS

    my $dbchanges = Test::DBChanges::Pg->new({
        dbh => $dbh,
        source_names => [qw(things ledger)],
    });

    # later:
    my $changeset = $dbchanges->changeset_for_code(sub { do_something($dbh) });

    for my $row ($changeset->changes_for_source('things')->inserted_rows->@*) {
        # $row is a hashref with the inserted data
    }

# DESCRIPTION

Sometimes, when testing code that makes changes to a database, it's
useful to see which rows where inserted / updated / deleted. This
distribution provides mechanisms to do just that.

This distribution provides these classes:

- [`Test::DBChanges::Pg`](https://metacpan.org/pod/Test::DBChanges::Pg)

    to track changes in a PostgreSQL database

- [`Test::DBChanges::Pg::DBIC`](https://metacpan.org/pod/Test::DBChanges::Pg::DBIC)

    to track changes in a [`DBIx::Class::Schema`](https://metacpan.org/pod/DBIx::Class::Schema) connected to a
    PostgreSQL database

They install a set of triggers in the database, that record all
changes (insert, update, delete) to a set of tables.

They can then parse this record into a
[changeset](https://metacpan.org/pod/Test::DBChanges::ChangeSet), which will build hashrefs (or
objects) corresponding to each changed row.

This should really only be used in tests. At the moment the tables,
stored procedures and triggers that these classes need are installed
but never removed.

# AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
