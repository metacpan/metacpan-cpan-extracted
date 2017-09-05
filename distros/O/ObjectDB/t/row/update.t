use strict;
use warnings;
use Test::More;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use Person;

subtest 'update_by_primary_key' => sub {
    _setup();

    _insert(id => 1, name => 'vti');

    my $person = _build_object(id => 1);
    $person->set_column(name => 'foo');
    $person->update;

    $person = _build_object(id => 1);
    $person->load;

    is($person->column('name'), 'foo');
};

subtest 'update_by_unique_key' => sub {
    _setup();

    _insert(id => 1, name => 'vti', profession => 'hacker');

    my $person = _build_object(name => 'vti');
    $person->set_column(profession => 'slacker');
    $person->update;

    $person = _build_object(id => 1);
    $person->load;

    is($person->column('profession'), 'slacker');
};

subtest 'update_second_time_by_primary_key' => sub {
    _setup();

    _insert(id => 1, name => 'vti');

    my $person = _build_object(name => 'vti');
    $person->load;

    $person->set_column(name => 'foo');
    $person->update;

    $person = _build_object(id => 1);
    $person->load;

    is($person->column('name'), 'foo');
};

subtest 'throw_when_updating_not_by_primary_or_unique_key' => sub {
    _setup();

    my $person = _build_object(profession => 'hacker');
    $person->set_column(profession => 'slacker');

    like(exception { $person->update }, qr/no primary or unique keys specified/);
};

subtest 'throw_when_update_didnt_occur' => sub {
    _setup();

    my $person = _build_object(id => 1);
    $person->set_column(name => 'vti');

    like(exception { $person->update }, qr/No rows were affected/);
};

subtest 'do_nothing_on_second_update' => sub {
    _setup();

    _insert(id => 1, name => 'vti');

    my $person = _build_object(id => 1);
    $person->set_column(name => 'vti');

    $person->update;

    ok($person->update);
};

subtest 'not_modified_after_update' => sub {
    _setup();

    _insert(id => 1, name => 'vti');

    my $person = _build_object(id => 1);
    $person->set_column(name => 'vti');

    $person->update;

    ok(!$person->is_modified);
};

subtest 'is_in_db' => sub {
    _setup();

    _insert(id => 1, name => 'vti');

    my $person = _build_object(id => 1);
    $person->set_column(name => 'vti');

    $person->update;

    ok($person->is_in_db);
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

