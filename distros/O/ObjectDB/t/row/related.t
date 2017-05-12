use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use Author;
use Book;
use BookDescription;

describe 'related' => sub {

    before each => sub {
        TestEnv->prepare_table('author');
        TestEnv->prepare_table('book');
        TestEnv->prepare_table('book_description');
    };

    it 'related' => sub {
        my $author = Author->new(name => 'vti')->create;
        my $book =
          Book->new(title => 'Crap', author_id => $author->get_column('id'))
          ->create;

        $book = Book->new(title => 'Crap')->load(with => 'parent_author');

        is($book->related('parent_author')->get_column('name'), 'vti');
    };

    it 'related reverse' => sub {
        my $author = Author->new(name => 'vti')->create;
        my $book =
          Book->new(title => 'Crap', author_id => $author->get_column('id'))
          ->create;

        $author = Author->new(name => 'vti')->load(with => 'books');

        ok($author->is_related_loaded('books'));
        is($author->related('books')->[0]->get_column('title'), 'Crap');
    };

    it 'does not load empty related objects' => sub {
        my $book = Book->new(title => 'Crap')->create;

        $book = Book->new(title => 'Crap')->load(with => 'parent_author');

        ok(!defined $book->related('parent_author'));
    };

    it 'does not load empty deeply related objects' => sub {
        my $book_description = BookDescription->new(description => 'Crap')->create;

        $book_description =
          BookDescription->new(id => $book_description->get_column('id'))
          ->load(with => ['parent_book', 'parent_book.parent_author']);

        ok(!defined $book_description->related('parent_book'));
    };

    it 'is_related_loaded' => sub {
        my $author = Author->new(name => 'vti')->create;
        my $book =
          Book->new(title => 'Crap', author_id => $author->get_column('id'))
          ->create;

        $book = Book->new(title => 'Crap')->load(with => 'parent_author');

        ok($book->is_related_loaded('parent_author'));
    };

    it 'load_related_on_demand' => sub {
        my $author = Author->new(name => 'vti')->create;
        my $book =
          Book->new(title => 'Crap', author_id => $author->get_column('id'))
          ->create;

        $book = Book->new(title => 'Crap')->load;

        is($book->related('parent_author')->get_column('name'), 'vti');
    };

    it 'is_related_loaded_false' => sub {
        my $author = Author->new(name => 'vti')->create;
        my $book =
          Book->new(title => 'Crap', author_id => $author->get_column('id'))
          ->create;

        $book = Book->new(title => 'Crap')->load;

        ok(!$book->is_related_loaded('parent_author'));
    };

    it 'resets related on load' => sub {
        my $author = Author->new(name => 'vti')->create;
        my $book =
          Book->new(title => 'Crap', author_id => $author->get_column('id'))
          ->create;

        $book = Book->new(title => 'Crap')->load(with => 'parent_author');

        ok($book->is_related_loaded('parent_author'));

        $book = $book->load;

        ok(!$book->is_related_loaded('parent_author'));
    };

};

runtests unless caller;
