use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use Author;
use Book;
use BookDescription;

subtest 'related in different contexts' => sub {
    _setup();

    my $author = Author->new(
        name  => 'vti',
        books => [ { title => 'Book1' }, { title => 'Book2' } ]
    );

    my $books = $author->related('books');
    is(@$books, 2);

    my @books = $author->related('books');

    is(@books, 2);

    is($books[0]->get_column('title'), 'Book1');
};

subtest 'sets correct values on new' => sub {
    _setup();

    my $author = Author->new(
        name  => 'vti',
        books => [ { title => 'Book1' }, { title => 'Book2' } ]
    );

    my @books = $author->related('books');

    is(@books, 2);

    is($books[0]->get_column('title'), 'Book1');
};

subtest 'sets correct values on create' => sub {
    _setup();

    my $author = Author->new(
        name  => 'vti',
        books => [ { title => 'Book1' }, { title => 'Book2' } ]
    )->create;

    my @books = $author->related('books');

    is(@books, 2);

    is($books[0]->get_column('title'), 'Book1');
};

# TODO
#subtest 'load with related' => sub {
#    my $author = Author->new(
#        name  => 'vti',
#        books => [{title => 'Book1'}, {title => 'Book2'}]
#    )->create;

#    $author =
#      Author->new(id => $author->get_column('id'))->load(with => 'books');

#    my @books = $author->related('books');

#    is(@books, 2);

#    is($books[0]->get_column('title'), 'Book1');
#};
#
#subtest 'find with related' => sub {
#    Author->new(
#        name  => 'vti',
#        books => [{title => 'Book1'}, {title => 'Book2'}]
#    )->create;

#    my $author = Author->new->table->find(first => 1, with => 'books');
#    ok $author->is_related_loaded('books');
#    is($author->related('books')->[0]->get_column('title'), 'Book1');
#    is($author->related('books')->[1]->get_column('title'), 'Book2');
#};

subtest 'find with related deeply' => sub {
    _setup();

    my $author = Author->new(
        name  => 'vti',
        books => [
            { title => 'Book1', description => { description => 'Crap1' } },
            { title => 'Book2', description => { description => 'Crap2' } }
        ]
    )->create;

    $author = Author->new->table->find(
        first => 1,
        with  => [qw/books books.description/]
    );

    ok $author->is_related_loaded('books');
    ok $author->related('books')->[0]->is_related_loaded('description');
    is($author->related('books')->[0]->related('description')->get_column('description'), 'Crap1');
};

subtest 'find_many_to_one_with_query' => sub {
    _setup();

    my $author = Author->new(
        name  => 'vti',
        books => [
            { title => 'Book1', description => { description => 'Crap1' } },
            { title => 'Book2', description => { description => 'Crap2' } }
        ]
    )->create;

    $author = Author->new->table->find(
        first => 1,
        with  => [qw/books books.description/],
        where => [ 'books.description.description' => 'Crap2' ]
    );
    ok $author->is_related_loaded('books');
    ok $author->related('books')->[0]->is_related_loaded('description');
    is($author->related('books')->[0]->related('description')->get_column('description'), 'Crap2');
};

# TODO
#subtest 'finds related objects ordered' => sub {
#    Author->new(
#        name  => 'vti',
#        books => [{title => 'Book1'}, {title => 'Book2'}]
#    )->create;
#    Author->new(
#        name  => 'bill',
#        books => [{title => 'Book2'}, {title => 'Book1'}]
#    )->create;

#    my @authors = Author->new->table->find(
#        with     => [qw/books/],
#        order_by => 'books.title'
#    );
#    is(@authors, 2);
#    ok $authors[0]->is_related_loaded('books');
#    is($authors[0]->related('books')->[0]->get_column('title'), 'Book1');
#    is($authors[0]->related('books')->[1]->get_column('title'), 'Book2');
#    ok $authors[1]->is_related_loaded('books');
#    is($authors[1]->related('books')->[0]->get_column('title'), 'Book1');
#    is($authors[1]->related('books')->[1]->get_column('title'), 'Book2');
#};

subtest 'create_related' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;

    $author->create_related('books', title => 'Crap');

    my $book = Book->new(title => 'Crap')->load;

    is($book->get_column('author_id'), $author->get_column('id'));
};

subtest 'create_related_hashref' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;

    $author->create_related('books', { title => 'Crap' });

    my $book = Book->new(title => 'Crap')->load;

    is($book->get_column('author_id'), $author->get_column('id'));
};

subtest 'create_related_multi' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;

    $author->create_related('books', [ { title => 'Crap' }, { title => 'Good' } ]);

    is($author->count_related('books'), 2);
};

subtest 'create related from object' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;

    $author->create_related('books', [ Book->new(title => 'Crap') ]);

    is($author->count_related('books'), 1);
};

subtest 'create related from already created object' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;

    $author->create_related('books', [ Book->new(title => 'Crap')->create ]);

    is($author->count_related('books'), 1);
};

subtest 'find_related' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    $author->create_related('books', title => 'Crap');
    $author->create_related('books', title => 'Good');
    Author->new(name => 'foo')->create;

    my @books = $author->find_related('books');

    is(@books,                                                  2);
    is($books[0]->related('parent_author')->get_column('name'), 'vti');
};

subtest 'related' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    $author->create_related('books', title => 'Crap');
    $author->create_related('books', title => 'Good');
    Author->new(name => 'foo')->create;

    my @books = $author->related('books');

    is(@books,                                                  2);
    is($books[0]->related('parent_author')->get_column('name'), 'vti');
};

subtest 'count_related' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    $author->create_related('books', title => 'Crap');

    $author = Author->new(name => 'vti')->load;

    is($author->count_related('books'), 1);
};

subtest 'update_related' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    $author->create_related('books', title => 'Crap');

    $author = Author->new(name => 'vti')->load;
    $author->update_related('books', set => { title => 'Good' });

    my $book = Book->new(title => 'Good')->load;
    ok($book);
};

subtest 'delete_related' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    $author->create_related('books', title => 'Crap');

    $author = Author->new(name => 'vti')->load;
    $author->delete_related('books');

    is($author->count_related('books'), 0);
};

done_testing;

sub _setup {
    TestEnv->prepare_table('author');
    TestEnv->prepare_table('book');
    TestEnv->prepare_table('book_description');
}
