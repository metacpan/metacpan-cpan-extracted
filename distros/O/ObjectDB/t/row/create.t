use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use Person;

subtest 'create with default values' => sub {
    _setup();

    my $person = _build_object();
    $person->create;

    my $result = TestDBH->dbh->selectall_arrayref('SELECT * FROM person');

    is(@$result, 1);
};

subtest 'create_one_instance' => sub {
    _setup();

    my $person = _build_object(name => 'vti');
    $person->create;

    my $result = TestDBH->dbh->selectall_arrayref('SELECT * FROM person');

    is(@$result, 1);
};

subtest 'save_columns' => sub {
    _setup();

    my $person = _build_object(name => 'vti');
    $person->create;

    my $result = TestDBH->dbh->selectall_arrayref('SELECT id, name FROM person');

    is_deeply($result->[0], [ 1, 'vti' ]);
};

subtest 'throws on double created' => sub {
    _setup();

    my $person = _build_object(name => 'vti');
    $person->create;

    like exception { $person->create }, qr/Calling 'create' on already created object/;
};

subtest 'autoincrement_field_is_set' => sub {
    _setup();

    my $person = _build_object(name => 'vti');
    $person->create;

    is($person->column('id'), 1);
};

subtest 'is_in_db' => sub {
    _setup();

    my $person = _build_object(name => 'vti');
    $person->create;

    ok($person->is_in_db);
};

subtest 'not_modified' => sub {
    _setup();

    my $person = _build_object(name => 'vti');
    $person->create;

    ok(!$person->is_modified);
};

done_testing;

sub _setup {
    TestEnv->prepare_table('person');
}

sub _build_object {
    return Person->new(@_);
}

