use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use ObjectDB::Table;
use Person;
use Author;
use Book;

describe 'table find' => sub {

    before each => sub {
        TestEnv->prepare_table('person');
        TestEnv->prepare_table('book');
        TestEnv->prepare_table('book_description');
        TestEnv->prepare_table('author');
    };

    it 'find_objects' => sub {
        Person->new(name => 'vti')->create;

        my $table = _build_table();

        my @persons = $table->find;

        is(@persons, 1);
    };

    it 'have is_in_db flag' => sub {
        Person->new(name => 'vti')->create;

        my $table = _build_table();

        my @persons = $table->find;

        ok($persons[0]->is_in_db);
    };

    it 'find_objects_with_query' => sub {
        Person->new(name => 'vti')->create;
        Person->new(name => 'foo')->create;

        my $table = _build_table();

        my @persons = $table->find(where => [name => 'vti']);

        is($persons[0]->get_column('name'), 'vti');
    };

    it 'find objects with specified columns' => sub {
        Person->new(name => 'vti')->create;

        my $table = _build_table();

        my $person = $table->find(first => 1, where => [name => 'vti'], columns => ['id']);

        ok($person->get_column('id'));
        ok(!$person->get_column('name'));
    };

    it 'find objects with specified +columns' => sub {
        Person->new(name => 'vti')->create;

        my $table = _build_table();

        my $person = $table->find(first => 1, where => [name => 'vti'], '+columns' => [{-col => \'1', -as => 'one'}]);

        ok($person->get_column('id'));
        is($person->get_column('name'), 'vti');
        is($person->get_column('one'), '1');
    };

    it 'find objects with specified -columns' => sub {
        Person->new(name => 'vti')->create;

        my $table = _build_table();

        my $person = $table->find(first => 1, where => [name => 'vti'], '-columns' => ['name']);

        ok($person->get_column('id'));
        ok(!$person->get_column('name'));
    };

    it 'find objects with specified columns with aliases' => sub {
        Person->new(name => 'vti')->create;

        my $table = _build_table();

        my $person = $table->find(
            first   => 1,
            where   => [name => 'vti'],
            columns => [{-col => 'id', -as => 'alias'}]
        );

        ok($person->get_column('alias'));
    };

    it 'find_single_object' => sub {
        Person->new(name => 'vti')->create;
        Person->new(name => 'foo')->create;

        my $table = _build_table();

        my $person = $table->find(where => [name => 'vti'], single => 1);

        is($person->get_column('name'), 'vti');
    };

    it 'finds objects with iterator' => sub {
        Person->new(name => 'vti')->create;
        Person->new(name => 'foo')->create;

        my $table = _build_table();

        my @persons;
        $table->find(
            where => [name => 'vti'],
            each  => sub {
                my ($person) = @_;

                push @persons, $person;
            }
        );

        is($persons[0]->get_column('name'), 'vti');
    };

    it 'finds objects with group by and having' => sub {
        Book->new(title => 'Foo', description => {description => 'foo'})->create;
        Book->new(title => 'Bar', description => {description => 'bar'})->create;

        my $table = _build_table(class => 'Book');

        my @books = $table->find(group_by => 'title', having => ['description.description' => 'foo']);
        is($books[0]->get_column('title'), 'Foo');
    };

    it 'finds objects with custom join' => sub {
        my $author = Author->new(name => 'me')->create;

        Book->new(author_id => $author->get_column('id'), title => 'vti')->create;

        my $table = _build_table(class => 'Book');

        my @books = $table->find(
            join => [
                {
                    columns => [qw/id name/],
                    source => 'author',
                    on     => ['author.id' => {-col => 'book.id'}]
                }
            ]
        );

        is($books[0]->get_column('title'), 'vti');
        is($books[0]->get_column('author')->{name}, 'me');
    };

};

sub _build_table {
    ObjectDB::Table->new(class => 'Person', dbh => TestDBH->dbh, @_);
}

runtests unless caller;
