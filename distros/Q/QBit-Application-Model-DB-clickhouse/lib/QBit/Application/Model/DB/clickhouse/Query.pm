package QBit::Application::Model::DB::clickhouse::Query;
$QBit::Application::Model::DB::clickhouse::Query::VERSION = '0.004';
use qbit;

use base qw(QBit::Application::Model::DB::Query);

BEGIN {
    no strict 'refs';

    foreach my $method (qw(join for_update left_join right_join)) {
        *{__PACKAGE__ . "::$method"} = sub {throw gettext('Method "%s" not supported', $method)}
    }
}

sub _found_rows {
    my ($self) = @_;

    return $self->db->dbh->{'__FOUND_ROWS__'};
}

sub _get_table_alias {
    my ($self, $table) = @_;

    return $self->{'without_table_alias'} ? '' : $self->quote_identifier($self->_table_alias($table)) . '.';
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::clickhouse::Query - Class for ClickHouse queries.

=head1 Description

Implements methods for ClickHouse queries.

=cut
