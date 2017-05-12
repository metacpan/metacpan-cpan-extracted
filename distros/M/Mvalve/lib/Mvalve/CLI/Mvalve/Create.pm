package Mvalve::CLI::Mvalve::Create;
use Moose;
use DBI;

extends 'MooseX::App::Cmd::Command';
with 'Mvalve::CLI::ConfigFromFile';

has 'connect_info' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 1,
    auto_deref => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub run {
    my $self = shift;

    my $dbh = DBI->connect( $self->connect_info );

    local $dbh->{AutoCommit} = 0;
    local $dbh->{RaiseError} = 1;

    eval {
        $dbh->do(<<"        EOSQL");
            CREATE TABLE q_incoming (
                destination VARCHAR(40) NOT NULL,
                message     BLOB NOT NULL
            ) ENGINE=QUEUE DEFAULT CHARSET=utf8;
        EOSQL

        $dbh->do(<<"        EOSQL");
            CREATE TABLE q_emerg (
                destination VARCHAR(40) NOT NULL,
                message     BLOB NOT NULL
            ) ENGINE=QUEUE DEFAULT CHARSET=utf8;
        EOSQL

        $dbh->do(<<"        EOSQL");
            CREATE TABLE q_timed (
                destination VARCHAR(40) NOT NULL,
                ready       BIGINT NOT NULL,
                message     BLOB NOT NULL
            ) ENGINE=QUEUE DEFAULT CHARSET=utf8;
        EOSQL

        $dbh->do(<<"        EOSQL");
            CREATE TABLE q_statslog (
                action      VARCHAR(40) NOT NULL,
                destination VARCHAR(40) NOT NULL,
                logged_on   TIMESTAMP NOT NULL
            ) ENGINE=QUEUE DEFAULT CHARSET=utf8;
        EOSQL

        $dbh->commit();
    };
    if ($@) {
        print STDERR "Failed to create tables: $@\n";
    }
    $dbh->disconnect;
}


