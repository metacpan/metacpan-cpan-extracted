use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use Person;

subtest 'load_by_primary_key' => sub {
    _setup();

    _insert(id => 1, name => 'foo');
    _insert(id => 2, name => 'vti');

    my $person = _build_object(id => 2);
    $person->load;

    is($person->column('name'), 'vti');
};

subtest 'overwrite_columns' => sub {
    _setup();

    my $person = Person->new(name => 'vti')->create;
    $person->set_column(name => 'bar');
    $person->load;

    is($person->get_column('name'), 'vti');
};

subtest 'leave_virtual_columns' => sub {
    _setup();

    my $person = Person->new(name => 'vti')->create;
    $person->set_column(virtual => 'bar');
    $person->load;

    is($person->get_column('virtual'), 'bar');
};

subtest 'load_by_unique_key' => sub {
    _setup();

    _insert(id => 1, name => 'vti');

    my $person = _build_object(name => 'vti');
    $person->load;

    is($person->column('id'), 1);
};

subtest 'load_second_time_by_primary_key' => sub {
    _setup();

    _insert(id => 1, name => 'vti');

    my $person = _build_object(name => 'vti');
    $person->load;

    TestDBH->dbh->do("UPDATE person SET name = 'foo' WHERE id = 1");

    $person->load;

    is($person->column('name'), 'foo');
};

subtest 'load with columns' => sub {
    _setup();

    _insert(id => 1, name => 'vti');

    my $person = _build_object(name => 'vti');
    $person->load(columns => ['id']);

    ok($person->get_column('id'));
    ok(!$person->get_column('name'));
};

subtest 'throw_when_loading_not_by_primary_or_unique_key' => sub {
    _setup();

    my $person = _build_object(profession => 'hacker');

    like(exception { $person->load }, qr/no primary or unique keys specified/);
};

subtest 'return_undef_when_not_found' => sub {
    _setup();

    my $person = _build_object(name => 'vti');

    ok(not defined $person->load);
};

subtest 'is_in_db' => sub {
    _setup();

    _insert(id => 1, name => 'vti');

    my $person = _build_object(name => 'vti');
    $person->load;

    ok($person->is_in_db);
};

subtest 'not_modified' => sub {
    _setup();

    _insert(id => 1, name => 'vti');

    my $person = _build_object(name => 'vti');
    $person->load;

    ok(!$person->is_modified);
};

done_testing;

sub _setup {
    TestEnv->prepare_table('person');
}

sub _build_object {
    Person->new(@_);
}

sub _insert {
    my (%params) = @_;

    my $names  = join ',', map { "$_" } keys %params;
    my $values = join ',', map { "'$_'" } values %params;

    TestDBH->dbh->do("INSERT INTO person ($names) VALUES ($values)");
}
