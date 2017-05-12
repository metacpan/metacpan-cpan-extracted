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
        TestEnv->prepare_table('person');
    };

    it 'discover schema' => sub {

        {

            package MyTable;
            use base 'ObjectDB';
            __PACKAGE__->meta(table => 'person', discover_schema => 1);
            sub init_db { TestDBH->dbh }
        }

        is_deeply([MyTable->meta->columns], [qw/id name profession age/]);
        is_deeply([MyTable->meta->primary_key], ['id']);

        is(MyTable->new->get_column('name'), '');
    };

};

runtests unless caller;
