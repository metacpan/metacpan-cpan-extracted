use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use Person;

describe 'delete' => sub {

    my $original_person;
    before each => sub {
        TestEnv->prepare_table('person');

        $original_person = Person->new(name => 'vti')->create;
    };

    it 'delete_by_primary_key' => sub {
        my $person = _build_object(id => $original_person->get_column('id'));

        $person->delete;

        $person = _build_object(id => $original_person->get_column('id'));
        ok(!$person->load);
    };

    it 'delete_by_unique_key' => sub {
        my $person = _build_object(name => 'vti');
        $person->delete;

        $person = _build_object(id => $original_person->get_column('id'));
        ok(!$person->load);
    };

    it 'throw_when_deleting_not_by_primary_or_unique_key' => sub {
        my $person = _build_object(profession => 'hacker');

        like(exception { $person->delete },
            qr/no primary or unique keys specified/);
    };

    it 'throw_when_delete_didnt_occur' => sub {
        my $person = _build_object(id => 999);

        like(exception { $person->delete }, qr/No rows were affected/);
    };

    it 'empty_object_after_deletion' => sub {
        my $person = _build_object(id => 1);

        $person->delete;

        ok(not defined $person->get_column('id'));
    };

    it 'not_modified_after_delete' => sub {
        my $person = _build_object(id => 1);

        $person->delete;

        ok(!$person->is_modified);
    };

    it 'not_in_db' => sub {
        my $person = _build_object(id => 1);

        $person->delete;

        ok(!$person->is_in_db);
    };

};

sub _build_object {
    Person->new(@_);
}

runtests unless caller;
