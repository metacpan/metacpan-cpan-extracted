use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use ObjectDB::Table;
use Person;

describe 'table find with paging' => sub {

    before each => sub {
        TestEnv->prepare_table('person');
    };

    it 'get_page' => sub {
        Person->new(name => $_)->create for 1 .. 20;

        my $table = _build_table();

        my @persons = $table->find(page => 1);
        is(@persons, 10);
    };

    it 'get_page_with_correct_results' => sub {
        Person->new(name => $_)->create for 1 .. 20;

        my $table = _build_table();

        my @persons = $table->find(page => 2);
        is($persons[0]->get_column('name'),  11);
        is($persons[-1]->get_column('name'), 20);
    };

    it 'default_to_the_first_page_on_invalid_data' => sub {
        Person->new(name => $_)->create for 1 .. 20;

        my $table = _build_table();

        my @persons = $table->find(page => 'abc');
        is($persons[0]->get_column('name'),  1);
        is($persons[-1]->get_column('name'), 10);
    };

};

sub _build_table {
    ObjectDB::Table->new(class => 'Person', dbh => TestDBH->dbh, @_);
}

runtests unless caller;
