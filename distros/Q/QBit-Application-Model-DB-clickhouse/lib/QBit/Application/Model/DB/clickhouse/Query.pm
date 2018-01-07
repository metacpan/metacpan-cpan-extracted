package QBit::Application::Model::DB::clickhouse::Query;
$QBit::Application::Model::DB::clickhouse::Query::VERSION = '0.006';
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

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::clickhouse::Query - Class for ClickHouse queries.

=head1 Description

Implements methods for ClickHouse queries.

=cut
