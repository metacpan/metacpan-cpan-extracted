package Oryx::DBI::Util::Pg;

use base qw(Oryx::DBI::Util);

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

sub lastval {
    my ($self, $dbh, $table) = @_;
    return $dbh->last_insert_id('%', 'public', $table, 'id');
}

1;
__END__

=head1 NAME

Oryx::DBI::Util::Pg - Oryx DBI utilities for PostgreSQL connections

=head1 DESCRIPTION

This provides an Oryx DBI utility class for use with L<DBD::Pg>.

=head1 SEE ALSO

L<Oryx::DBI::Util>, L<DBD::Pg>

=head1 AUTHORS

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
