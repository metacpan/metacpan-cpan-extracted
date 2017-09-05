use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use ObjectDB::Table;
use Person;

subtest 'get_page' => sub {
    _setup();

    Person->new(name => $_)->create for 1 .. 20;

    my $table = _build_table();

    my @persons = $table->find(page => 1);
    is(@persons, 10);
};

subtest 'get_page_with_correct_results' => sub {
    _setup();

    Person->new(name => $_)->create for 1 .. 20;

    my $table = _build_table();

    my @persons = $table->find(page => 2);
    is($persons[0]->get_column('name'),  11);
    is($persons[-1]->get_column('name'), 20);
};

subtest 'default_to_the_first_page_on_invalid_data' => sub {
    _setup();

    Person->new(name => $_)->create for 1 .. 20;

    my $table = _build_table();

    my @persons = $table->find(page => 'abc');
    is($persons[0]->get_column('name'),  1);
    is($persons[-1]->get_column('name'), 10);
};

done_testing;

sub _setup {
    TestEnv->prepare_table('person');
}

sub _build_table {
    ObjectDB::Table->new(class => 'Person', dbh => TestDBH->dbh, @_);
}
