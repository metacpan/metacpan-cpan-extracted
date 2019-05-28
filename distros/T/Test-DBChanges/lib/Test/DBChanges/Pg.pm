package Test::DBChanges::Pg;
use Moo;
use namespace::autoclean;

with 'Test::DBChanges::Role::DBI',
    'Test::DBChanges::Role::Pg';

our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: track changes to PostgreSQL tables


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges::Pg - track changes to PostgreSQL tables

=head1 VERSION

version 1.0.1

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

This class installs a set of triggers in the database, that record all
changes (insert, update, delete) to a set of tables. This requires
PostgreSQL version 9.4 at least, because it uses the C<JSONB> type.

It can then parse this record into a
L<changeset|Test::DBChanges::ChangeSet>, which will build hashrefs
corresponding to each changed row.

This should really only be used in tests. At the moment the table,
stored procedure and triggers that this class needs are installed but
never removed.

=head1 ATTRIBUTES

=head2 C<source_names>

Arrayref of names of the tables to record changes for.

=head2 C<dbh>

Connected database handle to track changes in.

=head1 METHODS

=head2 C<changeset_for_code>

  my $changeset = $dbchanges->changeset_for_code(sub { ... });

Runs the given coderefs, and returns a L<<
C<Test::DBChanges::ChangeSet> >> instance containing all
changes to the tables referenced by the L</source_names>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
