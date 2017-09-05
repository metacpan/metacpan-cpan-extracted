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

subtest 'find_by_compose: returns rows by raw query' => sub {
    TestEnv->prepare_table('person');

    Person->new(name => 'foo')->create;

    my @result = TestDB->table->find_by_compose(
        table   => 'person',
        columns => [ 'id', 'name' ],
        where   => [ name => 'foo' ]
    );

    is @result, 1;
    is $result[0]->get_column('name'), 'foo';
};

subtest 'find_by_compose: returns rows iterator by raw query' => sub {
    TestEnv->prepare_table('person');

    Person->new(name => 'foo')->create;

    my $iterator = TestDB->table->find_by_compose(
        table   => 'person',
        columns => [ 'id', 'name' ],
        where   => [ name => 'foo' ]
    );

    my $result = $iterator->next;

    is $result->get_column('name'), 'foo';
};

done_testing;
