use Test::Most;
use lib 't/lib';
use Test::DBChanges::Test;
use Test::DBChanges::Schema;
use Test::DBChanges::Pg::DBIC;

my $pgsql = pgsql();

my $schema = Test::DBChanges::Schema->connect(
    $pgsql->dsn, undef, undef,
    { AutoCommit => 1 },
);

my $dbchanges = Test::DBChanges::Pg::DBIC->new({
    schema => $schema,
    source_names => [qw(T1 T2)],
});

my $t1_rs = $schema->resultset('T1');
my $t2_rs = $schema->resultset('T2');
my $t3_rs = $schema->resultset('T3');

subtest 'changes to tables outside of source_names' => sub {
    my $changes = $dbchanges->changeset_for_code(
        sub {
            $t3_rs->create({ name => 'something' });
        },
    );

    cmp_deeply(
        $changes->changes_for_source('T3'),
        undef,
        'should not be recorded',
    );

    cmp_deeply(
        $changes->changes_for_source('T1'),
        empty_changeset(),
        'other tables should not see anything, either',
    );
};

subtest 'changes to a table in source_names' => sub {
    my $changes = $dbchanges->changeset_for_code(
        sub {
            $t1_rs->create({ name => 'new' });
            $t1_rs->search({ name => 'three' })->update({ name => 'mitsu' });
        },
    );

    cmp_deeply(
        $changes->changes_for_source('T1'),
        methods(
            inserted_rows => [methods( id => 4, name => 'new' )],
            updated_rows =>  [methods( id => 3, name => 'mitsu' )],
        ),
        'should be recorded',
    );

    cmp_deeply(
        $changes->changes_for_source('T2'),
        empty_changeset(),
        'other tables should not see changes',
    );
};

subtest 'cascades' => sub {
    my $changes = $dbchanges->changeset_for_code(
        sub {
            $t1_rs->find(1)->update({ id => 10 });
            $t1_rs->find(2)->delete;
        },
    );

    cmp_deeply(
        $changes->changes_for_source('T1'),
        methods(
            inserted_rows => [],
            updated_rows =>  [methods( id => 10, name => 'one' )],
            deleted_rows =>  [methods( id => 2, name => 'two' )],
        ),
        'main changes should be recorded',
    );

    cmp_deeply(
        $changes->changes_for_source('T2'),
        methods(
            inserted_rows => [],
            updated_rows =>  bag(
                methods( id => 1, name_id => 10, value => 0.34 ),
                methods( id => 2, name_id => 10, value => 0.68 ),
            ),
            deleted_rows =>  [methods( id => 3, name_id => 2, value => 2.25 )],
        ),
        'cascades should be recorded as well',
    );
};


done_testing;
