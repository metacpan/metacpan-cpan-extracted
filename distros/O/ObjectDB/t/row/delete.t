use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use Person;

subtest 'delete_by_primary_key' => sub {
    _setup();

    my $original_person = Person->new(name => 'vti')->create;

    my $person = _build_object(id => $original_person->get_column('id'));

    $person->delete;

    $person = _build_object(id => $original_person->get_column('id'));
    ok(!$person->load);
};

subtest 'delete_by_unique_key' => sub {
    _setup();

    my $original_person = Person->new(name => 'vti')->create;

    my $person = _build_object(name => 'vti');
    $person->delete;

    $person = _build_object(id => $original_person->get_column('id'));
    ok(!$person->load);
};

subtest 'throw_when_deleting_not_by_primary_or_unique_key' => sub {
    _setup();

    my $original_person = Person->new(name => 'vti')->create;

    my $person = _build_object(profession => 'hacker');

    like(exception { $person->delete }, qr/no primary or unique keys specified/);
};

subtest 'throw_when_delete_didnt_occur' => sub {
    _setup();

    my $original_person = Person->new(name => 'vti')->create;

    my $person = _build_object(id => 999);

    like(exception { $person->delete }, qr/No rows were affected/);
};

subtest 'empty_object_after_deletion' => sub {
    _setup();

    my $original_person = Person->new(name => 'vti')->create;

    my $person = _build_object(id => 1);

    $person->delete;

    ok(not defined $person->get_column('id'));
};

subtest 'not_modified_after_delete' => sub {
    _setup();

    my $original_person = Person->new(name => 'vti')->create;

    my $person = _build_object(id => 1);

    $person->delete;

    ok(!$person->is_modified);
};

subtest 'not_in_db' => sub {
    _setup();

    my $original_person = Person->new(name => 'vti')->create;

    my $person = _build_object(id => 1);

    $person->delete;

    ok(!$person->is_in_db);
};

done_testing;

sub _setup {
    TestEnv->prepare_table('person');
}

sub _build_object {
    Person->new(@_);
}
