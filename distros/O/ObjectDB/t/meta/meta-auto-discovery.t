use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

eval { require DBIx::Inspector; 1 } or do {
    require Test::More;
    Test::More->import(skip_all => 'DBIx::Inspector required for this test');
};

subtest 'discover schema' => sub {
    _setup();

    is_deeply(
        [ AutoDiscovery->meta->columns ],
        [
            qw/
              id
              varchar_no_default
              varchar_default_empty
              varchar_default
              int_no_default
              int_default_empty
              int_default
              bool_no_default
              bool_default_false
              bool_default_true
              not_nullable
              nullable
              /
        ]
    );
    is_deeply([ AutoDiscovery->meta->primary_key ], ['id']);

    is(AutoDiscovery->new->get_column('varchar_no_default'),    undef);
    is(AutoDiscovery->new->get_column('varchar_default_empty'), '');
    is(AutoDiscovery->new->get_column('varchar_default'),       'hello');

    is(AutoDiscovery->new->get_column('int_no_default'),    undef);
    is(AutoDiscovery->new->get_column('int_default_empty'), 0);
    is(AutoDiscovery->new->get_column('int_default'),       123);

    is(AutoDiscovery->new->get_column('bool_no_default'), undef);
    ok(!AutoDiscovery->new->get_column('bool_default_false'));
    ok(AutoDiscovery->new->get_column('bool_default_true'));

    ok !( AutoDiscovery->meta->is_nullable('not_nullable') );
    ok( AutoDiscovery->meta->is_nullable('nullable') );
};

done_testing;

sub _setup {
    TestEnv->prepare_table('auto');

    require AutoDiscovery;
}
