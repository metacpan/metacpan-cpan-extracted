package Test::DBChanges::Pg::DBIC;
use Moo;
use namespace::autoclean;

with 'Test::DBChanges::Role::DBIC',
    'Test::DBChanges::Role::Pg';

our $VERSION = '1.0.0'; # VERSION
# ABSTRACT: track changes to DBIC+PostgreSQL resultsets


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges::Pg::DBIC - track changes to DBIC+PostgreSQL resultsets

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

  my $dbchanges = Test::DBChanges::Pg::DBIC->new({
    schema => $schema,
    source_names => [qw(Things Ledger)],
  });

  # later:
  my $changeset = $dbchanges->changeset_for_code(sub { do_something($dbh) });

  for my $row ($changeset->changes_for_source('Things')->inserted_rows->@*) {
     # $row is a MySchema::Result::Things object with the inserted data
  }

=head1 DESCRIPTION

This class installs a set of triggers in the database, that record all
changes (insert, update, delete) to a set of tables.

It can then parse this record into a
L<changeset|Test::DBChanges::ChangeSet>, which will build DBIC objects
corresponding to each changed row.

I<NOTE>: the row objects will not be C<in_storage> (some of them may
refer to deleted rows, for example!)

This should really only be used in tests. At the moment the table,
stored procedure and triggers that this class needs are installed but
never removed.

=head1 ATTRIBUTES

=head2 C<source_names>

Arrayref of I<resultset> names corresponding to the tables to record
changes for.

=head2 C<schema>

The connected schema to track changes in.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
