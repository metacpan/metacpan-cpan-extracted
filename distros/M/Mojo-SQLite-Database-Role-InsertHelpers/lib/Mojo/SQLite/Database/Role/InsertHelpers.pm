package Mojo::SQLite::Database::Role::InsertHelpers;

# ABSTRACT: adds insert_or_ignore, insert_or_replace and insert_or_update to Mojo::SQLite::Database

use Mojo::Base -role;
use Memoize;
use Carp;

sub insert_or_ignore {
    my ($db, $table, $values) = @_;
    my ($sql, @binds) = $db->sqlite->abstract->insert($table, $values);
    $sql =~ s/^INSERT/INSERT OR IGNORE/;
    return $db->query($sql, @binds);
}

sub insert_or_replace {
    my ($db, $table, $values) = @_;
    my ($sql, @binds) = $db->sqlite->abstract->insert($table, $values);
    $sql =~ s/^INSERT/INSERT OR REPLACE/;
    return $db->query($sql, @binds);
}

sub insert_or_update {
    my ($db, $table, $values) = @_;

    # Ensure we have a hash
    if (ref $values eq 'ARRAY') {
        my $fields = $db->fields($table);
	croak "insert or update failed: table %s has %i columns but %i values were supplied", $table, scalar $fields->@*, scalar $values->@*
	    if (scalar $values->@* != scalar $fields->@*);
        $values = { map { $fields->[$_] => $values->[$_] } 0 .. $#$fields };
    }

    my $pk = $db->primary_key($table);
    # If no PK, fallback to standard insert (or perhaps insert_or_ignore?)
    return $db->insert($table, $values) unless @$pk;

    # Use 'excluded' to keep the query slim
    my $update = { map { $_ => \ "excluded.$_" } keys %$values };

    return $db->insert($table, $values, { on_conflict => [ $pk => $update ] });
}

sub fields {
    my ($db, $table) = @_;
    [ map { $_->[3] } @{$db->dbh->column_info(undef, undef, $table, undef)->fetchall_arrayref} ];
}

sub primary_key {
    my ($db, $table) = @_;
    [ map { $_->[3] } @{$db->dbh->primary_key_info(undef, undef, $table)->fetchall_arrayref} ];
}


memoize('primary_key', normalizer => sub { return join "|", $_[0]->sqlite->dsn, $_[1] });
memoize('fields',      normalizer => sub { return join "|", $_[0]->sqlite->dsn, $_[1] });

1;

=head1 NAME

Mojo::SQLite::Database::Role::InsertHelpers - Add insert_or_ignore and insert_or_replace methods to Mojo::SQLite::Database

=head1 SYNOPSIS

  use Mojo::SQLite;

  my $sqlite = Mojo::SQLite->new('sqlite.db');
  my $db     = $sqlite->db->with_roles("+InsertHelpers");

  # Insert a row, ignoring conflicts
  $db->insert_or_ignore('users', { name => 'Alice', age => 30 });

  # Insert a row, replacing on conflict (dangerous: deletes field content if not explicitly set)
  $db->insert_or_replace('users', { name => 'Alice', age => 31 });

  # Insert a row, updating on conflict
  $db->insert_or_update('users', { name => 'Alice', age => 32 });

=head1 DESCRIPTION

This role adds helper methods to L<Mojo::SQLite::Database> to simplify common
SQLite insert patterns: inserting rows while ignoring conflicts or replacing
existing rows on conflict.

=head1 METHODS

=head2 insert_or_ignore

  $db->insert_or_ignore($table, \%values);

Builds an SQL INSERT statement with C<OR IGNORE> to insert a row into the
specified table. If a conflict occurs (e.g., a unique constraint is violated),
the insert is ignored instead of failing.

=over 4

=item * C<$table> - Name of the database table.

=item * C<\%values> - Hashref of column => value pairs to insert.

=back

=head2 insert_or_replace

  $db->insert_or_replace($table, \%values);

Builds an SQL INSERT statement with C<OR REPLACE> to insert a row into the
specified table. If a conflict occurs, the existing row is replaced with
the new values.

=over 4

=item * C<$table> - Name of the database table.

=item * C<\%values> - Hashref of column => value pairs to insert.

=back

=head2 insert_or_update

  $db->insert_or_update($table, \%values);

An alias for C<insert_or_replace>.

=head1 AUTHOR

Your Name <you@example.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
