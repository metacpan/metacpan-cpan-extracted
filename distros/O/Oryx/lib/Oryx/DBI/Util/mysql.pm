package Oryx::DBI::Util::mysql;

use base qw(Oryx::DBI::Util);

our %SQL_TYPES = (
    'Oid'       => 'bigint PRIMARY KEY auto_increment',
    'Integer'   => 'bigint',
    'String'    => 'varchar',
    'Text'      => 'text',
    'Binary'    => 'blob',
    'Float'     => 'float',
    'Boolean'   => 'tinyint',
    'DateTime'  => 'datetime',
);

sub type2sql {
    my ($self, $type, $size) = @_;
    my $sql_type = $SQL_TYPES{$type};
    if ($type eq 'String') {
	$size ||= '255';
	$sql_type .= "($size)";
    } elsif ($type eq 'Integer' and defined $size) {
	$sql_type .= "($size)";
    }
    return $sql_type;
}

sub table_exists {
    my ($self, $dbh, $table) = @_;
    my $sth = $dbh->table_info('%', '%', $table);
    $sth->execute();
    my @rv = @{$sth->fetchall_arrayref};
    $sth->finish;
    return grep { $_->[2] eq $table } @rv;
}

# DBD::mysql is gimpy here...
sub lastval {
    my ($self, $dbh, $table) = @_;
    return $dbh->{mysql_insertid};
}

1;

__END__

=head1 NAME

Oryx::DBI::Util::mysql - Oryx DBI utilities for MySQL connections

=head1 DESCRIPTION

This provides an Oryx DBI utility class for use with L<DBD::mysql>.

=head1 BUGS

The C<lastval()> method is implemented using the "mysql_insertid" field of the database handler. This will only be able to return the insert ID of the last inserted row. This is, to my knowledge at the time of this writing, the only way to do this as the standard C<last_insert_id()> method of L<DBI> has not yet been implemented.

=head1 SEE ALSO

L<Oryx::DBI::Util>, L<DBD::mysql>

=head1 AUTHORS

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
