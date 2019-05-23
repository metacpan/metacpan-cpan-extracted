use Test::Most;
use lib 't/lib';
use Test::DBChanges::Test;
use Test::DBChanges::Pg;
use DBI;

my $pgsql = pgsql();

my $dbh = DBI->connect($pgsql->dsn);
my $dbchanges = Test::DBChanges::Pg->new({
    dbh => $dbh,
    source_names => [qw(t1 t2)],
});

subtest 'changes to tables outside of source_names' => sub {
    my $changes = $dbchanges->changeset_for_code(
        sub {
            $dbh->do('INSERT INTO t3(name) VALUES (?)',{},'something');
        },
    );

    cmp_deeply(
        $changes->changes_for_source('t3'),
        undef,
        'should not be recorded',
    );

    cmp_deeply(
        $changes->changes_for_source('t1'),
        empty_changeset(),
        'other tables should not see anything, either',
    );
};

subtest 'changes to a table in source_names' => sub {
    my $changes = $dbchanges->changeset_for_code(
        sub {
            $dbh->do('INSERT INTO t1(name) VALUES (?)',{},'new');
            $dbh->do('UPDATE t1 SET name=? WHERE name=?',{},
                     'mitsu', 'three');
        },
    );

    cmp_deeply(
        $changes->changes_for_source('t1'),
        methods(
            inserted_rows => [{ id => 4, name => 'new' }],
            updated_rows =>  [{ id => 3, name => 'mitsu' }],
        ),
        'should be recorded',
    );

    cmp_deeply(
        $changes->changes_for_source('t2'),
        empty_changeset(),
        'other tables should not see changes',
    );
};

subtest 'cascades' => sub {
    my $changes = $dbchanges->changeset_for_code(
        sub {
            $dbh->do('UPDATE t1 SET id=? WHERE id=?',{},
                     10,1);
            $dbh->do('DELETE FROM t1 WHERE id=?',{},
                     2);
        },
    );

    cmp_deeply(
        $changes->changes_for_source('t1'),
        methods(
            inserted_rows => [],
            updated_rows =>  [{ id => 10, name => 'one' }],
            deleted_rows =>  [{ id => 2, name => 'two' }],
        ),
        'main changes should be recorded',
    );

    cmp_deeply(
        $changes->changes_for_source('t2'),
        methods(
            inserted_rows => [],
            updated_rows =>  bag(
                { id => 1, name_id => 10, value => 0.34 },
                { id => 2, name_id => 10, value => 0.68 },
            ),
            deleted_rows =>  [{ id => 3, name_id => 2, value => 2.25 }],
        ),
        'cascades should be recorded as well',
    );
};

done_testing;
