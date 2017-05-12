use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use ObjectDB::Table;
use Person;

describe 'table delete' => sub {

    before each => sub {
        TestEnv->prepare_table('person');
    };

    it 'delete_objects ' => sub {
        Person->new(name => ' vti ')->create;

        my $table = _build_table();
        $table->delete;

        is($table->count, 0);
    };

    it 'delete_objects_with_query' => sub {
        Person->new(name => 'vti')->create;
        Person->new(name => 'foo')->create;

        my $table = _build_table();
        $table->delete(where => [name => 'foo']);

        is($table->count, 1);
    };

    it 'return_number_of_deleted_rows' => sub {
        Person->new(name => 'vti')->create;
        Person->new(name => 'foo')->create;

        my $table = _build_table();
        is $table->delete, 2;
    };

};

sub _build_table {
    ObjectDB::Table->new(class => 'Person', dbh => TestDBH->dbh, @_);
}

runtests unless caller;
