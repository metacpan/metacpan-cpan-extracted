use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use ObjectDB::Meta;
use TestDBH;
use TestEnv;

eval { require DBIx::Inspector; 1 } or do {
    require Test::More;
    Test::More->import(skip_all => 'DBIx::Inspector required for this test');
};

describe 'meta auto discovery' => sub {

    before each => sub {
        TestEnv->prepare_table('auto');
    };

    it 'discover schema' => sub {

        {

            package MyTable;
            use base 'ObjectDB';
            __PACKAGE__->meta(table => 'auto', discover_schema => 1);
            sub init_db { TestDBH->dbh }
        }

        is_deeply(
            [ MyTable->meta->columns ],
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
                  /
            ]
        );
        is_deeply([MyTable->meta->primary_key], ['id']);

        is(MyTable->new->get_column('varchar_no_default'), undef);
        is(MyTable->new->get_column('varchar_default_empty'), '');
        is(MyTable->new->get_column('varchar_default'), 'hello');

        is(MyTable->new->get_column('int_no_default'), undef);
        is(MyTable->new->get_column('int_default_empty'), 0);
        is(MyTable->new->get_column('int_default'), 123);

        is(MyTable->new->get_column('bool_no_default'), undef);
        ok(!MyTable->new->get_column('bool_default_false'));
        ok(MyTable->new->get_column('bool_default_true'));
    };

};

runtests unless caller;
