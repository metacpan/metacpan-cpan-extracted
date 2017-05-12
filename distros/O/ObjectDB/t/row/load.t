use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use Person;

describe 'load' => sub {

    before each => sub {
        TestEnv->prepare_table('person');
    };

    it 'load_by_primary_key' => sub {
        _insert(id => 1, name => 'foo');
        _insert(id => 2, name => 'vti');

        my $person = _build_object(id => 2);
        $person->load;

        is($person->column('name'), 'vti');
    };

    it 'overwrite_columns' => sub {
        my $person = Person->new(name => 'vti')->create;
        $person->set_column(name => 'bar');
        $person->load;

        is($person->get_column('name'), 'vti');
    };

    it 'leave_virtual_columns' => sub {
        my $person = Person->new(name => 'vti')->create;
        $person->set_column(virtual => 'bar');
        $person->load;

        is($person->get_column('virtual'), 'bar');
    };

    it 'load_by_unique_key' => sub {
        _insert(id => 1, name => 'vti');

        my $person = _build_object(name => 'vti');
        $person->load;

        is($person->column('id'), 1);
    };

    it 'load_second_time_by_primary_key' => sub {
        _insert(id => 1, name => 'vti');

        my $person = _build_object(name => 'vti');
        $person->load;

        TestDBH->dbh->do("UPDATE person SET name = 'foo' WHERE id = 1");

        $person->load;

        is($person->column('name'), 'foo');
    };

    it 'load with columns' => sub {
        _insert(id => 1, name => 'vti');

        my $person = _build_object(name => 'vti');
        $person->load(columns => ['id']);

        ok($person->get_column('id'));
        ok(!$person->get_column('name'));
    };

    it 'throw_when_loading_not_by_primary_or_unique_key' => sub {
        my $person = _build_object(profession => 'hacker');

        like(exception { $person->load },
            qr/no primary or unique keys specified/);
    };

    it 'return_undef_when_not_found' => sub {
        my $person = _build_object(name => 'vti');

        ok(not defined $person->load);
    };

    it 'is_in_db' => sub {
        _insert(id => 1, name => 'vti');

        my $person = _build_object(name => 'vti');
        $person->load;

        ok($person->is_in_db);
    };

    it 'not_modified' => sub {
        _insert(id => 1, name => 'vti');

        my $person = _build_object(name => 'vti');
        $person->load;

        ok(!$person->is_modified);
    };

};

sub _build_object {
    Person->new(@_);
}

sub _insert {
    my (%params) = @_;

    my $names  = join ',', map { "$_" } keys %params;
    my $values = join ',', map { "'$_'" } values %params;

    TestDBH->dbh->do("INSERT INTO person ($names) VALUES ($values)");
}

runtests unless caller;
