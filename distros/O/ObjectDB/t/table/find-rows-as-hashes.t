use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;
use TestDB;

use Person;

use Scalar::Util qw(blessed);

subtest 'find: returns rows as hashes result' => sub {
    TestEnv->prepare_table('person');

    Person->new(name => 'foo')->create;

    my @result = Person->find(rows_as_hashes => 1);

    ok !blessed $result[0];
    is $result[0]->{name}, 'foo';
};

subtest 'find: returns rows as hashes result with iterator' => sub {
    TestEnv->prepare_table('person');

    Person->new(name => 'foo')->create;

    my $iterator = Person->find(rows_as_hashes => 1);

    my $result = $iterator->next;

    ok !blessed $result;
    is $result->{name}, 'foo';
};

subtest 'find_by_compose: returns rows as hashes result' => sub {
    TestEnv->prepare_table('person');

    Person->new(name => 'foo')->create;

    my @result = Person->table->find_by_compose(
        table          => 'person',
        columns        => [ 'id', 'name' ],
        where          => [ name => 'foo' ],
        rows_as_hashes => 1
    );

    ok !blessed $result[0];
    ok $result[0]->{id};
    is $result[0]->{name}, 'foo';
};

subtest 'find_by_sql: returns rows as hashes result' => sub {
    TestEnv->prepare_table('person');

    Person->new(name => 'foo')->create;

    my @result = Person->table->find_by_sql('SELECT * FROM person', [], rows_as_hashes => 1);

    ok !blessed $result[0];
    is $result[0]->{name}, 'foo';
};

done_testing;
