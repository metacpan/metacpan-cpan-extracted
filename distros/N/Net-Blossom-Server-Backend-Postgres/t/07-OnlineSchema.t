use strictures 2;

use Test::More;

use Net::Blossom::Server::Backend::Postgres::MetadataStore;

my $SHA256 = 'f' x 64;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

my $admin = _test_dbh('blossom-schema-admin');

subtest 'schema deployment requires AutoCommit' => sub {
    _reset_schema($admin);
    my $metadata = _metadata($admin);
    $admin->begin_work;
    like(
        dies { $metadata->deploy_schema },
        qr/schema deployment requires AutoCommit/,
        'online schema deployment rejects an active transaction',
    );
    $admin->rollback;
};

subtest 'invalid concurrent index is rebuilt' => sub {
    _reset_schema($admin);
    my $metadata = _metadata($admin);
    $metadata->deploy_schema;
    $admin->do('DROP INDEX blossom_owners_sha256');
    _insert_blob($admin);
    _insert_owner($admin, 'a' x 64);
    _insert_owner($admin, 'b' x 64);

    like(
        dies {
            $admin->do(q{
                CREATE UNIQUE INDEX CONCURRENTLY blossom_owners_sha256
                    ON blossom_owners (sha256)
            });
        },
        qr/could not create unique index/,
        'duplicate owners leave a failed concurrent index',
    );
    is(_index_state($admin)->{valid}, 0, 'failed concurrent index is invalid');

    ok($metadata->deploy_schema, 'schema deployment repairs invalid index');
    is_deeply(
        _index_state($admin),
        {
            valid  => 1,
            unique => 0,
            columns => ['sha256'],
        },
        'repaired index is valid and has the expected definition',
    );
};

subtest 'valid incompatible index is rejected' => sub {
    _reset_schema($admin);
    my $metadata = _metadata($admin);
    $metadata->deploy_schema;
    $admin->do('DROP INDEX blossom_owners_sha256');
    $admin->do(q{
        CREATE INDEX CONCURRENTLY blossom_owners_sha256
            ON blossom_owners (pubkey)
    });

    like(
        dies { $metadata->deploy_schema },
        qr/incompatible PostgreSQL index blossom_owners_sha256/,
        'valid index with the wrong definition is not replaced',
    );
    is_deeply(
        _index_state($admin)->{columns},
        ['pubkey'],
        'incompatible valid index is preserved',
    );

    $admin->do('DROP INDEX CONCURRENTLY blossom_owners_sha256');
    ok($metadata->deploy_schema, 'deployment lock is released after rejection');
};

subtest 'custom ordering semantics are rejected' => sub {
    _reset_schema($admin);
    my $metadata = _metadata($admin);
    $metadata->deploy_schema;
    $admin->do('DROP INDEX blossom_owners_pubkey_order');
    $admin->do(q{
        CREATE INDEX CONCURRENTLY blossom_owners_pubkey_order
            ON blossom_owners (
                pubkey text_pattern_ops,
                uploaded DESC,
                sha256 text_pattern_ops
            )
    });

    like(
        dies { $metadata->deploy_schema },
        qr/incompatible PostgreSQL index blossom_owners_pubkey_order/,
        'custom operator classes do not satisfy the ordering index',
    );
};

subtest 'concurrent deployment stays online and is serialized' => sub {
    _reset_schema($admin);
    _metadata($admin)->deploy_schema;
    $admin->do('DROP INDEX blossom_owners_sha256');
    _insert_blob($admin);

    my $blocker = _test_dbh('blossom-schema-held-writer');
    $blocker->begin_work;
    _insert_owner($blocker, 'c' x 64);

    my $first_pid = _fork_deploy($admin, $blocker, 'blossom-schema-deploy-first');
    my $online = _wait_until_online_build($admin, 'blossom-schema-deploy-first');

    my $second_pid = _fork_deploy($admin, $blocker, 'blossom-schema-deploy-second');
    my $serialized = _wait_until_nonblocking_schema_wait(
        $admin,
        'blossom-schema-deploy-first',
        'blossom-schema-deploy-second',
    );

    my $writer = _test_dbh('blossom-schema-concurrent-writer');
    $writer->do(q{SET statement_timeout = '2s'});
    my $write_ok = eval {
        _insert_owner($writer, 'd' x 64);
        1;
    };
    my $write_error = $@;
    $writer->disconnect;

    $blocker->commit;
    $blocker->disconnect;

    waitpid($first_pid, 0);
    my $first_status = $?;
    waitpid($second_pid, 0);
    my $second_status = $?;

    ok($online, 'index build takes the online PostgreSQL lock');
    ok($serialized, 'second schema deployment waits outside a transaction');
    ok($write_ok, 'metadata writer commits during index build')
        or diag $write_error;
    is($first_status, 0, 'first schema deployment succeeds');
    is($second_status, 0, 'serialized schema deployment succeeds');
    is(_index_state($admin)->{valid}, 1, 'online deployment leaves a valid index');
};

_reset_schema($admin);
$admin->disconnect;

done_testing;

sub _test_dbh {
    my ($application_name) = @_;
    my $dsn = $ENV{NET_BLOSSOM_POSTGRES_DSN}
        or plan skip_all => 'NET_BLOSSOM_POSTGRES_DSN is not set';

    eval 'use DBI (); use DBD::Pg (); 1'
        or die $@;

    my $dbh = DBI->connect(
        $dsn,
        $ENV{NET_BLOSSOM_POSTGRES_USER},
        $ENV{NET_BLOSSOM_POSTGRES_PASSWORD},
        {
            AutoCommit     => 1,
            RaiseError     => 1,
            PrintError     => 0,
            pg_enable_utf8 => 0,
        },
    );
    $dbh->do('SET application_name = ' . $dbh->quote($application_name));
    $dbh->do(q{SET statement_timeout = '15s'});
    return $dbh;
}

sub _metadata {
    my ($dbh) = @_;
    return Net::Blossom::Server::Backend::Postgres::MetadataStore->new(dbh => $dbh);
}

sub _insert_blob {
    my ($dbh) = @_;
    $dbh->do(
        q{
            INSERT INTO blossom_blobs
                (sha256, storage_key, size, type, uploaded)
            VALUES (?, ?, ?, ?, ?)
        },
        undef,
        $SHA256,
        $SHA256,
        1,
        'application/octet-stream',
        1,
    );
    return;
}

sub _insert_owner {
    my ($dbh, $pubkey) = @_;
    $dbh->do(
        q{
            INSERT INTO blossom_owners (pubkey, sha256, type, uploaded)
            VALUES (?, ?, ?, ?)
        },
        undef,
        $pubkey,
        $SHA256,
        'application/octet-stream',
        1,
    );
    return;
}

sub _index_state {
    my ($dbh) = @_;
    my $row = $dbh->selectrow_hashref(q{
        SELECT CASE WHEN i.indisvalid THEN 1 ELSE 0 END AS valid,
               CASE WHEN i.indisunique THEN 1 ELSE 0 END AS unique_index,
               i.indexrelid
          FROM pg_index i
          JOIN pg_class c ON c.oid = i.indexrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = current_schema()
           AND c.relname = 'blossom_owners_sha256'
    });
    return unless defined $row;

    my @columns = map {
        $dbh->selectrow_array(
            q{SELECT pg_get_indexdef(CAST(? AS oid), ?, true)},
            undef,
            $row->{indexrelid},
            $_,
        );
    } 1 .. $dbh->selectrow_array(
        q{SELECT indnatts FROM pg_index WHERE indexrelid = CAST(? AS oid)},
        undef,
        $row->{indexrelid},
    );

    return {
        valid   => 0 + $row->{valid},
        unique  => 0 + $row->{unique_index},
        columns => \@columns,
    };
}

sub _fork_deploy {
    my ($admin_dbh, $blocker_dbh, $application_name) = @_;
    my $pid = fork();
    die "fork failed: $!\n" unless defined $pid;

    if (!$pid) {
        $admin_dbh->{InactiveDestroy} = 1;
        $blocker_dbh->{InactiveDestroy} = 1;
        my $ok = eval {
            my $dbh = _test_dbh($application_name);
            _metadata($dbh)->deploy_schema;
            $dbh->disconnect;
            1;
        };
        warn $@ unless $ok;
        exit($ok ? 0 : 1);
    }

    return $pid;
}

sub _wait_until_online_build {
    my ($dbh, $application_name) = @_;
    return _wait_until($dbh, sub {
        return $dbh->selectrow_array(q{
            SELECT 1
              FROM pg_stat_activity a
              JOIN pg_locks l ON l.pid = a.pid
              JOIN pg_class c ON c.oid = l.relation
             WHERE a.application_name = ?
               AND c.relname = 'blossom_owners'
               AND l.mode = 'ShareUpdateExclusiveLock'
               AND l.granted
        }, undef, $application_name);
    });
}

sub _wait_until_nonblocking_schema_wait {
    my ($dbh, $owner_name, $waiting_name) = @_;
    return _wait_until($dbh, sub {
        return $dbh->selectrow_array(q{
            SELECT 1
              FROM pg_stat_activity waiting
             WHERE waiting.application_name = ?
               AND waiting.state = 'idle'
               AND waiting.xact_start IS NULL
               AND NOT EXISTS (
                    SELECT 1
                      FROM pg_locks waiting_lock
                     WHERE waiting_lock.pid = waiting.pid
                       AND waiting_lock.locktype = 'advisory'
                       AND waiting_lock.granted
               )
               AND EXISTS (
                    SELECT 1
                      FROM pg_stat_activity owner
                      JOIN pg_locks owner_lock ON owner_lock.pid = owner.pid
                     WHERE owner.application_name = ?
                       AND owner_lock.locktype = 'advisory'
                       AND owner_lock.granted
               )
        }, undef, $waiting_name, $owner_name);
    });
}

sub _wait_until {
    my ($dbh, $check) = @_;
    for (1 .. 200) {
        return 1 if $check->();
        select undef, undef, undef, 0.025;
    }
    return 0;
}

sub _reset_schema {
    my ($dbh) = @_;
    $dbh->do('DROP TABLE IF EXISTS blossom_owners');
    $dbh->do('DROP TABLE IF EXISTS blossom_blobs');
    return;
}
