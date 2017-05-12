package Oryx::DBI::Util::SQLite;

use base qw(Oryx::DBI::Util);

our %SQL_TYPES = (
    'Oid'       => 'integer PRIMARY KEY AUTOINCREMENT',
    'Integer'   => 'integer',
    'String'    => 'text',
    'Text'      => 'text',
    'Binary'    => 'blob',
    'Float'     => 'real',
    'Boolean'   => 'integer',
    'DateTime'  => 'text',
);

sub type2sql {
    my ($self, $type, $size) = @_;
    my $sql_type = $SQL_TYPES{$type};
    return $sql_type;
}

# Columns may not be dropped in SQLite. Oh, well.
sub column_drop { }

sub table_exists {
    my ($self, $dbh, $table) = @_;
    my $sth = $dbh->table_info('%', '%', $table);
    $sth->execute();
    my @rv = @{$sth->fetchall_arrayref};
    $sth->finish;
    return grep { lc $_->[2] eq lc $table } @rv;
}

1;

=head1 NAME

Oryx::DBI::Util::SQLite - Oryx DBI utilities for SQLite connections

=head1 DESCRIPTION

This provides an Oryx DBI utility class for use with L<DBD::SQLite>.

=head1 SEE ALSO

L<Oryx::DBI::Util>, L<DBD::Pg>

=head1 AUTHORS

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyrright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
