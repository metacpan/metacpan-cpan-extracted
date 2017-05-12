package Oryx::DBI::Util;
use Carp qw(carp croak);

sub _carp {
    my $class = ref($_[0]) ? ref($_[0]) : $_[0];
    carp("[$class] $_[1]");
}

sub _croak {
    my $class = ref($_[0]) ? ref($_[0]) : $_[0];
    croak("[$class] $_[1]");
}

sub new { return bless { }, $_[0] }

sub type2sql {
    my ($self, $type, $size) = @_;

    # Fetch the SQL type defined in %SQL_TYPES for the current class
    my $class = ref $self;
    my $sql_type = ${"${class}::SQL_TYPES"}{$type};

    # Append a size if given
    $sql_type .= "($size)" if defined $size;

    return $sql_type;
}

sub column_exists {
    my ($self, $dbh, $table, $column) = @_;

    # Get the escape char and escape table and column names
    my $esc = $dbh->get_info( 14 );
    $table  =~ s/([_%])/$esc$1/g;
    $column =~ s/([_%])/$esc$1/g;

    # Is there such a column?
    my $sth = $dbh->column_info('%', '%', $table, $column);
    $sth->execute();
    my @rv = @{ $sth->fetchall_arrayref };
    $sth->finish;
    return @rv;
}

sub column_create {
    my ($self, $dbh, $table, $colname, $coltype) = @_;

    # Create the column
    my $sth = $dbh->prepare(<<"SQL");
ALTER TABLE $table ADD COLUMN $colname $coltype;
SQL
    $sth->execute;
    $sth->finish;
}

# This works in MySQL and PostgreSQL.
sub column_drop {
    my ($self, $dbh, $table, $column) = @_;

    # Drop the column
    my $sth = $dbh->prepare(<<"SQL");
ALTER TABLE $table DROP COLUMN $column;
SQL
    $sth->execute;
    $sth->finish;
}

sub table_exists {
    my ($self, $dbh, $table) = @_;
    my $sth = $dbh->table_info('%', '%', $table);
    my $esc = $dbh->get_info( 14 );
    $table  =~ s/([_%])/$esc$1/g;
    $sth->execute();
    my @rv = @{$sth->fetchall_arrayref};
    $sth->finish;
    return @rv;
}
 
sub table_create {
    my ($self, $dbh, $table, $columns, $types) = @_;

    my $sql = <<"SQL";
CREATE TABLE $table (
SQL

    if (defined $columns and defined $types) {
        for (my $x = 0; $x < @$columns; $x++) {
            $sql .= '  '.$columns->[$x].' '.$types->[$x];
            $sql .= ($x != $#$columns) ? ",\n" : "\n";
        }
    }

    $sql .= <<SQL;
);
SQL

    my $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->finish;
}

sub table_drop {
    my ($self, $dbh, $table) = @_;
    my $sql = "DROP TABLE $table";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

sub lastval {
    my ($self, $dbh, $table) = @_;
    return $dbh->last_insert_id('%', '%', $table, 'id');
}

1;
__END__

=head1 NAME

Oryx::DBI::Util - abstract base class for Oryx DBI utilities

=head1 DESCRIPTION

Oryx::DBI::Util represents an interface to be implemented in order to add support for additional RDBMS'. The following methods must be implemented:

=head1 METHODS

=over

=item B<column_exists( $dbh, $table, $column )>

Returns a true value if the column named C<$column> exists in table named C<$table> in database C<$dbh>.

=item B<column_create( $dbh, $table, $colname, $coltype )>

Adds a column to the table named C<$table> named C<$colname> with type C<$coltype> in database C<$dbh>.

=item B<column_drop( $dbh, $table, $colname )>

Removes the column named $C<$colname> from the table named C<$table>  in database C<$dbh>.

=item B<table_exists( $dbh, $table )>

Returns a true value if the table C<$table> exists in C<$dbh>.

=item B<table_create( $dbh, $table, \@columns, \@types )>

Creates a table named C<$table> with columns C<@columns> having types C<@types> in database C<$dbh>.

=item B<table_drop( $dbh, $table )>

Drops the table named C<$table> in database C<$dbh>.

=item B<type2sql( $type, $size )>

Given an Oryx primitive type C<$type> and an optional size, C<$size>, this method returns the SQL type for the current connection.

=item B<lastval( $dbh, $table )>

Returns what should be the last insert ID used for table C<$table> in database C<$dbh>. However, due to some DBD driver limitations, this method should not be used except to check the last insert ID of an insertion that happened in a statement executed immediately previous to calling this method.

=back

=head2 IMPLEMENTORS

In order to allow Oryx to store data in a database other than those already supported, one need only provide an implementation for a utility class for use with the appropriate driver.

The utility class should inherit from L<Oryx::DBI::Util> and should provide implementations appropriate for all of the methods documented here. Since L<DBI> and standard SQL make the implementation very similar across databases, many of the methods are defined here already. You should examine this class for the default implementations to see if they need to be overridden. You will, at the very least, need to provide either an array named C<%SQL_TYPES> in your class or and implementation of C<type2sql()>:

  # Taken from Oryx::DBI::Util::Pg at the time of writing
  our %SQL_TYPES = (
      'Oid'       => 'serial PRIMARY KEY',
      'Integer'   => 'integer',
      'String'    => 'varchar',
      'Text'      => 'text',
      'Binary'    => 'bytea',
      'Float'     => 'numeric',
      'Boolean'   => 'integer',
      'DateTime'  => 'timestamp',
  );

You may also want to examine the code found in the utilities already provided.  As of this writing, this includes L<Oryx::DBI::Util::Pg> for PostgreSQL accessed via L<DBD::Pg>, L<Oryx::DBI::Util::mysql> for MySQL accessed via L<DBD::mysql>, and L<Oryx::DBI::Util::SQLite> for SQLite accessed via L<DBD::SQLite>.

=head1 SEE ALSO

L<Oryx::DBI>, L<Oryx::DBI::Class>, L<Oryx::DBI::Util::Pg>, L<Oryx::DBI::Util::mysql>, L<Oryx::DBI::Util::SQLite>, L<DBI>

=head1 AUTHORS

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
