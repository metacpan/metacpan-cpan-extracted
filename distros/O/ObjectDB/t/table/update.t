use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use ObjectDB::Table;
use Person;

describe 'table update' => sub {

    before each => sub {
        TestEnv->prepare_table('person');
    };

    it 'update_objects' => sub {
        Person->new(name => 'vti')->create;

        my $table = _build_table();
        $table->update(set => {name => 'foo'});

        my $person = Person->new(id => 1)->load;

        is($person->get_column('name'), 'foo');
    };

    it 'update_objects_with_query' => sub {
        Person->new(name => 'vti')->create;
        Person->new(name => 'foo')->create;

        my $table = _build_table();
        $table->update(set => {name => 'bar'}, where => [name => 'foo']);

        my $person = Person->new(id => 1)->load;
        is($person->get_column('name'), 'vti');

        $person = Person->new(id => 2)->load;
        is($person->get_column('name'), 'bar');
    };

    it 'return_number_of_updated_rows' => sub {
        Person->new(name => 'vti')->create;
        Person->new(name => 'foo')->create;

        my $table = _build_table();
        is $table->update(set => {name => 'bar'}, where => [name => 'foo']), 1;
    };

};

sub _build_table {
    ObjectDB::Table->new(class => 'Person', dbh => TestDBH->dbh, @_);
}

runtests unless caller;
