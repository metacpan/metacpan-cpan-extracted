use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use ObjectDB::Table;
use Person;
use Author;
use Book;

subtest 'find_objects' => sub {
    _setup();

    Person->new(name => 'vti')->create;

    my $table = _build_table();

    my @persons = $table->find;

    is(@persons, 1);
};

subtest 'have is_in_db flag' => sub {
    _setup();

    Person->new(name => 'vti')->create;

    my $table = _build_table();

    my @persons = $table->find;

    ok($persons[0]->is_in_db);
};

subtest 'find_objects_with_query' => sub {
    _setup();

    Person->new(name => 'vti')->create;
    Person->new(name => 'foo')->create;

    my $table = _build_table();

    my @persons = $table->find(where => [ name => 'vti' ]);

    is($persons[0]->get_column('name'), 'vti');
};

subtest 'find objects with specified columns' => sub {
    _setup();

    Person->new(name => 'vti')->create;

    my $table = _build_table();

    my $person = $table->find(first => 1, where => [ name => 'vti' ], columns => ['id']);

    ok($person->get_column('id'));
    ok(!$person->get_column('name'));
};

subtest 'find objects with specified +columns' => sub {
    _setup();

    Person->new(name => 'vti')->create;

    my $table = _build_table();

    my $person =
      $table->find(first => 1, where => [ name => 'vti' ], '+columns' => [ { -col => \'1', -as => 'one' } ]);

    ok($person->get_column('id'));
    is($person->get_column('name'), 'vti');
    is($person->get_column('one'),  '1');
};

subtest 'find objects with specified -columns' => sub {
    _setup();

    Person->new(name => 'vti')->create;

    my $table = _build_table();

    my $person = $table->find(first => 1, where => [ name => 'vti' ], '-columns' => ['name']);

    ok($person->get_column('id'));
    ok(!$person->get_column('name'));
};

subtest 'find objects with specified columns with aliases' => sub {
    _setup();

    Person->new(name => 'vti')->create;

    my $table = _build_table();

    my $person = $table->find(
        first   => 1,
        where   => [ name => 'vti' ],
        columns => [ { -col => 'id', -as => 'alias' } ]
    );

    ok($person->get_column('alias'));
};

subtest 'find_single_object' => sub {
    _setup();

    Person->new(name => 'vti')->create;
    Person->new(name => 'foo')->create;

    my $table = _build_table();

    my $person = $table->find(where => [ name => 'vti' ], single => 1);

    is($person->get_column('name'), 'vti');
};

subtest 'finds objects with callback iterator' => sub {
    _setup();

    Person->new(name => 'vti')->create;
    Person->new(name => 'foo')->create;

    my $table = _build_table();

    my @persons;
    $table->find(
        where => [ name => 'vti' ],
        each  => sub {
            my ($person) = @_;

            push @persons, $person;
        }
    );

    is($persons[0]->get_column('name'), 'vti');
};

subtest 'finds objects with object iterator' => sub {
    _setup();

    Person->new(name => 'vti')->create;
    Person->new(name => 'foo')->create;

    my $table = _build_table();

    my $iterator = $table->find;

    is($iterator->next->get_column('name'), 'vti');
    is($iterator->next->get_column('name'), 'foo');

    ok !defined $iterator->next;
};

subtest 'finds objects with group by and having' => sub {
    _setup();

    Book->new(title => 'Foo', description => { description => 'foo' })->create;
    Book->new(title => 'Bar', description => { description => 'bar' })->create;

    my $table = _build_table(class => 'Book');

    my @books = $table->find(
        group_by => [ 'id', 'title', 'description.id' ],
        having => [ 'description.description' => 'foo' ]
    );
    is($books[0]->get_column('title'), 'Foo');
};

subtest 'finds objects with custom join' => sub {
    _setup();

    my $author = Author->new(name => 'me')->create;

    Book->new(author_id => $author->get_column('id'), title => 'vti')->create;

    my $table = _build_table(class => 'Book');

    my @books = $table->find(
        join => [
            {
                columns => [qw/id name/],
                source  => 'author',
                on      => [ 'author.id' => { -col => 'book.id' } ]
            }
        ]
    );

    is($books[0]->get_column('title'),          'vti');
    is($books[0]->get_column('author')->{name}, 'me');
};

done_testing;

sub _setup {
    TestEnv->prepare_table('person');
    TestEnv->prepare_table('book');
    TestEnv->prepare_table('book_description');
    TestEnv->prepare_table('author');
}

sub _build_table {
    ObjectDB::Table->new(class => 'Person', dbh => TestDBH->dbh, @_);
}
