package Oryx::DBI::Util::Generic;

use base qw(Oryx::DBI::Util);

our %SQL_TYPES = (
    'Oid'       => 'integer PRIMARY KEY',
    'Integer'   => 'integer',
    'String'    => 'varchar',
    'Text'      => 'clob',
    'Binary'    => 'blob',
    'Float'     => 'float',
    'Boolean'   => 'boolean',
    'DateTime'  => 'timestamp',
);

sub table_create {
    my ($self, $dbh, $table, $columns, $types) = @_;

    $self->SUPER::table_create(@_);

    unless ($self->sequence_exists($dbh, $table)) {
        $self->sequence_create($dbh, $table);
    }
}

sub _create_oryx_sequence {
    my $self = shift;

    unless ($self->table_exists($dbh, 'oryx_sequences')) {
	$self->table_create($dbh, 
            'oryx_sequences', ['name', 'value'], ['VARCHAR(255)', 'BIGINT']);
    }
}

sub _sequence_exists {
    my ($self, $dbh, $table) = @_;
    my $seq_name = $self->_seq_name($table);

    # Create it if it doesn't yet exist
    $self->_create_oryx_sequence;

    if (!$self->table_exists('oryx_sequences')) {
        $self->table_create
}

sub _sequence_create {
    my ($self, $dbh, $table) = @_;

    # Create it if it doesn't yet exist
    $self->_create_oryx_sequence;

    my $sql = "INSERT INTO oryx_sequences VALUES ('".$self->_seq_name($table)."', 0)";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

sub _seq_name {
    my ($self, $table) = @_;
    return $table."_id_seq";
}

1;

__END__

=head1 NAME

Oryx::DBI::Util::Generic - Oryx DBI utilities for generic connections

=head1 DESCRIPTION

This class is provided in the hope that it will allow officially unsupported databases a chance at working. If there isn't a utility class for a particular DBI driver the user connects to, this class is used to attempt to provide support for it.

This is largely untested and possibly works poorly. Compromises have been made for maximum compatibility that probably decrease overall performance.

=head1 SEE ALSO

L<Oryx::DBI::Util>

=head1 AUTHORS

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
