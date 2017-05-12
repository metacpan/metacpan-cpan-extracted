use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use Author;
use Book;
use BookDescription;

describe 'one to many' => sub {

    before each => sub {
        TestEnv->prepare_table('author');
        TestEnv->prepare_table('book');
        TestEnv->prepare_table('book_description');
    };

    it 'related in different contexts' => sub {
        my $author = Author->new(
            name  => 'vti',
            books => [{title => 'Book1'}, {title => 'Book2'}]
        );

        my $books = $author->related('books');
        is(@$books, 2);

        my @books = $author->related('books');

        is(@books, 2);

        is($books[0]->get_column('title'), 'Book1');
    };

    it 'sets correct values on new' => sub {
        my $author = Author->new(
            name  => 'vti',
            books => [{title => 'Book1'}, {title => 'Book2'}]
        );

        my @books = $author->related('books');

        is(@books, 2);

        is($books[0]->get_column('title'), 'Book1');
    };

    it 'sets correct values on create' => sub {
        my $author = Author->new(
            name  => 'vti',
            books => [{title => 'Book1'}, {title => 'Book2'}]
        )->create;

        my @books = $author->related('books');

        is(@books, 2);

        is($books[0]->get_column('title'), 'Book1');
    };

    # TODO
    #it 'load with related' => sub {
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
    #it 'find with related' => sub {
    #    Author->new(
    #        name  => 'vti',
    #        books => [{title => 'Book1'}, {title => 'Book2'}]
    #    )->create;

    #    my $author = Author->new->table->find(first => 1, with => 'books');
    #    ok $author->is_related_loaded('books');
    #    is($author->related('books')->[0]->get_column('title'), 'Book1');
    #    is($author->related('books')->[1]->get_column('title'), 'Book2');
    #};

    it 'find with related deeply' => sub {
        my $author = Author->new(
            name  => 'vti',
            books => [
                {title => 'Book1', description => {description => 'Crap1'}},
                {title => 'Book2', description => {description => 'Crap2'}}
            ]
        )->create;

        $author = Author->new->table->find(
            first => 1,
            with  => [qw/books books.description/]
        );

        ok $author->is_related_loaded('books');
        ok $author->related('books')->[0]->is_related_loaded('description');
        is(
            $author->related('books')->[0]->related('description')
              ->get_column('description'),
            'Crap1'
        );
    };

    it 'find_many_to_one_with_query' => sub {
        my $author = Author->new(
            name  => 'vti',
            books => [
                {title => 'Book1', description => {description => 'Crap1'}},
                {title => 'Book2', description => {description => 'Crap2'}}
            ]
        )->create;

        $author = Author->new->table->find(
            first => 1,
            with  => [qw/books books.description/],
            where => ['books.description.description' => 'Crap2']
        );
        ok $author->is_related_loaded('books');
        ok $author->related('books')->[0]->is_related_loaded('description');
        is(
            $author->related('books')->[0]->related('description')
              ->get_column('description'),
            'Crap2'
        );
    };

    # TODO
    #it 'finds related objects ordered' => sub {
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

    it 'create_related' => sub {
        my $author = Author->new(name => 'vti')->create;

        $author->create_related('books', title => 'Crap');

        my $book = Book->new(title => 'Crap')->load;

        is($book->get_column('author_id'), $author->get_column('id'));
    };

    it 'create_related_hashref' => sub {
        my $author = Author->new(name => 'vti')->create;

        $author->create_related('books', {title => 'Crap'});

        my $book = Book->new(title => 'Crap')->load;

        is($book->get_column('author_id'), $author->get_column('id'));
    };

    it 'create_related_multi' => sub {
        my $author = Author->new(name => 'vti')->create;

        $author->create_related('books',
            [{title => 'Crap'}, {title => 'Good'}]);

        is($author->count_related('books'), 2);
    };

    it 'create related from object' => sub {
        my $author = Author->new(name => 'vti')->create;

        $author->create_related('books', [Book->new(title => 'Crap')]);

        is($author->count_related('books'), 1);
    };

    it 'create related from already created object' => sub {
        my $author = Author->new(name => 'vti')->create;

        $author->create_related('books', [Book->new(title => 'Crap')->create]);

        is($author->count_related('books'), 1);
    };

    it 'find_related' => sub {
        my $author = Author->new(name => 'vti')->create;
        $author->create_related('books', title => 'Crap');
        $author->create_related('books', title => 'Good');
        Author->new(name => 'foo')->create;

        my @books = $author->find_related('books');

        is(@books,                                                  2);
        is($books[0]->related('parent_author')->get_column('name'), 'vti');
    };

    it 'related' => sub {
        my $author = Author->new(name => 'vti')->create;
        $author->create_related('books', title => 'Crap');
        $author->create_related('books', title => 'Good');
        Author->new(name => 'foo')->create;

        my @books = $author->related('books');

        is(@books,                                                  2);
        is($books[0]->related('parent_author')->get_column('name'), 'vti');
    };

    it 'count_related' => sub {
        my $author = Author->new(name => 'vti')->create;
        $author->create_related('books', title => 'Crap');

        $author = Author->new(name => 'vti')->load;

        is($author->count_related('books'), 1);
    };

    it 'update_related' => sub {
        my $author = Author->new(name => 'vti')->create;
        $author->create_related('books', title => 'Crap');

        $author = Author->new(name => 'vti')->load;
        $author->update_related('books', set => {title => 'Good'});

        my $book = Book->new(title => 'Good')->load;
        ok($book);
    };

    it 'delete_related' => sub {
        my $author = Author->new(name => 'vti')->create;
        $author->create_related('books', title => 'Crap');

        $author = Author->new(name => 'vti')->load;
        $author->delete_related('books');

        is($author->count_related('books'), 0);
    };

};

runtests unless caller;
