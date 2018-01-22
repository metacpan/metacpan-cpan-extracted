package Pcore::API::ProxyPool::Storage;

use Pcore -class;

has pool_id => ( is => 'ro', isa => Int, required => 1 );

has dbh => ( is => 'lazy', isa => InstanceOf ['Pcore::Handle::sqlite'], init_arg => undef );
has _connect_id => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

sub _build_dbh ($self) {
    my $dbh = P->handle('sqlite:');

    $dbh->add_schema_patch(
        1 => <<'SQL'
            CREATE TABLE IF NOT EXISTS "proxy" (
                "id" INTEGER PRIMARY KEY NOT NULL,
                "hostport" TEXT NOT NULL,
                "source_id" INTEGER NOT NULL,
                "source_enabled" INTEGER NOT NULL,
                "connect_error" INTEGER NOT NULL DEFAULT 0,
                "connect_error_time" INTEGER NOT NULL DEFAULT 0,
                "weight" INTEGER NOT NULL
            );

            CREATE UNIQUE INDEX IF NOT EXISTS "idx_proxy_hostport" ON "proxy" ("hostport" ASC);

            CREATE INDEX IF NOT EXISTS "idx_proxy_source_id" ON "proxy" ("source_id" ASC);

            CREATE INDEX IF NOT EXISTS "idx_proxy_source_enabled" ON "proxy" ("source_enabled" DESC);

            CREATE INDEX IF NOT EXISTS "idx_proxy_connect_error_time" ON "proxy" ("connect_error" DESC, "connect_error_time" ASC);

            CREATE INDEX IF NOT EXISTS "idx_proxy_weight" ON "proxy" ("weight" ASC);

            CREATE TABLE IF NOT EXISTS "connect" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                "name" TEXT NOT NULL
            );

            CREATE UNIQUE INDEX IF NOT EXISTS "idx_connect_name" ON "connect" ("name" ASC);

            CREATE TABLE IF NOT EXISTS "proxy_connect" (
                "proxy_id" INTEGER NOT NULL,
                "connect_id" INTEGER NOT NULL,
                "proxy_type" INTEGER NOT NULL,
                PRIMARY KEY ("proxy_id", "connect_id"),
                FOREIGN KEY("proxy_id") REFERENCES "proxy"("id") ON DELETE CASCADE,
                FOREIGN KEY("connect_id") REFERENCES "connect"("id") ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS "idx_proxy_connect_proxy_type" ON "proxy_connect" ("proxy_type" ASC);

            CREATE TABLE IF NOT EXISTS "proxy_ban" (
                "proxy_id" INTEGER NOT NULL,
                "ban_id" TEXT NOT NULL,
                "release_time" INTEGER NOT NULL,
                PRIMARY KEY ("proxy_id", "ban_id"),
                FOREIGN KEY("proxy_id") REFERENCES "proxy"("id") ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS "idx_proxy_ban_release_time" ON "proxy_ban" ("release_time" ASC);
SQL
    );

    $dbh->upgrade_schema( sub ($status) {
        die $status if !$status;

        return;
    } );

    return $dbh;
}

# PROXY METHODS
sub add_proxy ( $self, $proxy ) {
    state $sth = $self->dbh->prepare(q[INSERT INTO "proxy" ("id", "hostport", "source_id", "source_enabled", "weight") VALUES (?, ?, ?, ?, ?)]);

    $self->dbh->do( $sth, [ $proxy->id, $proxy->hostport, $proxy->source->id, $proxy->source->can_connect, $proxy->weight ] );

    return;
}

sub remove_proxy ( $self, $proxy ) {
    state $sth = $self->dbh->prepare(q[DELETE FROM "proxy" WHERE "id" = ?]);

    $self->dbh->do( $sth, [ $proxy->id ] );

    return;
}

sub ban_proxy ( $self, $proxy, $ban_id, $release_time ) {
    state $sth = $self->dbh->prepare(q[INSERT OR REPLACE INTO "proxy_ban" ("proxy_id", "ban_id", "release_time") VALUES (?, ?, ?)]);

    $self->dbh->do( $sth, [ $proxy->id, $ban_id, $release_time ] );

    return;
}

sub set_connect_error ( $self, $proxy ) {
    state $sth1 = $self->dbh->prepare(q[UPDATE "proxy" SET "connect_error" = 1, "connect_error_time" = ? WHERE "id" = ?]);

    state $sth2 = $self->dbh->prepare(q[DELETE FROM "proxy_connect" WHERE "proxy_id" = ?]);

    $self->dbh->do( $sth1, [ $proxy->{connect_error_time}, $proxy->id ] );

    $self->dbh->do( $sth2, [ $proxy->id ] );

    return;
}

sub update_weight ( $self, $proxy ) {
    state $sth = $self->dbh->prepare(q[UPDATE "proxy" SET "weight" = ? WHERE "id" = ?]);

    $self->dbh->do( $sth, [ $proxy->weight, $proxy->id ] );

    return;
}

sub set_connection_test_results ( $self, $proxy, $connect_id, $proxy_type ) {
    if ( !$self->_connect_id->{$connect_id} ) {
        state $sth1 = $self->dbh->prepare(q[INSERT INTO "connect" ("name") VALUES (?)]);

        $self->dbh->do( $sth1, [$connect_id] );

        $self->{_connect_id}->{$connect_id} = $self->dbh->last_insert_id;
    }

    state $sth2 = $self->dbh->prepare(q[INSERT OR REPLACE INTO "proxy_connect" ("proxy_id", "connect_id", "proxy_type") VALUES (?, ?, ?)]);

    $self->dbh->do( $sth2, [ $proxy->id, $self->{_connect_id}->{$connect_id}, $proxy_type ] );

    return;
}

# SOURCE METHODS
sub update_source_status ( $self, $source, $status ) {
    state $sth = $self->dbh->prepare(q[UPDATE "proxy" SET "source_enabled" = ? WHERE "source_id" = ?]);

    $self->dbh->do( $sth, [ $status, $source->id ] );

    return;
}

# MAINTENANCE METHODS
sub release_connect_error ( $self, $time ) {
    state $sth1 = $self->dbh->prepare(q[SELECT "hostport" FROM "proxy" WHERE "connect_error" = 1 AND "connect_error_time" <= ?]);

    state $sth2 = $self->dbh->prepare(q[UPDATE "proxy" SET "connect_error" = 0, "connect_error_time" = 0 WHERE "connect_error" = 1 AND "connect_error_time" <= ?]);

    if ( my $res = $self->dbh->selectcol( $sth1, [$time] ) ) {
        $self->dbh->do( $sth2, [$time] );

        return $res;
    }

    return;
}

sub release_ban ( $self, $time ) {
    state $sth1 = $self->dbh->prepare(
        <<'SQL'
            SELECT proxy.hostport, proxy_ban.ban_id
            FROM proxy
            INNER JOIN proxy_ban ON proxy.id = proxy_ban.proxy_id
            WHERE proxy_ban.release_time <= ?
SQL
    );

    state $sth2 = $self->dbh->prepare(q[DELETE FROM "proxy_ban" WHERE "release_time" <= ?]);

    if ( my $res = $self->dbh->selectall( $sth1, [$time] ) ) {
        $self->dbh->do( $sth2, [$time] );

        return $res;
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 91, 119              | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::ProxyPool::Storage

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
