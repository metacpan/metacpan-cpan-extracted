package Test::DBChanges;
use strict;
use warnings;

our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: track changes to database tables


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges - track changes to database tables

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

    my $dbchanges = Test::DBChanges::Pg->new({
        dbh => $dbh,
        source_names => [qw(things ledger)],
    });

    # later:
    my $changeset = $dbchanges->changeset_for_code(sub { do_something($dbh) });

    for my $row ($changeset->changes_for_source('things')->inserted_rows->@*) {
        # $row is a hashref with the inserted data
    }

=head1 DESCRIPTION

Sometimes, when testing code that makes changes to a database, it's
useful to see which rows where inserted / updated / deleted. This
distribution provides mechanisms to do just that.

This distribution provides these classes:

=over

=item L<< C<Test::DBChanges::Pg> >>

to track changes in a PostgreSQL database

=item L<< C<Test::DBChanges::Pg::DBIC> >>

to track changes in a L<< C<DBIx::Class::Schema> >> connected to a
PostgreSQL database

=back

They install a set of triggers in the database, that record all
changes (insert, update, delete) to a set of tables.

They can then parse this record into a
L<changeset|Test::DBChanges::ChangeSet>, which will build hashrefs (or
objects) corresponding to each changed row.

This should really only be used in tests. At the moment the tables,
stored procedures and triggers that these classes need are installed
but never removed.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
