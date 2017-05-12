use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use Author;
use Book;
use BookDescription;

describe 'many to one' => sub {

    before each => sub {
        TestEnv->prepare_table('author');
        TestEnv->prepare_table('book');
        TestEnv->prepare_table('book_description');
    };

    it 'find with related' => sub {
        Author->new(name => 'vti', books => {title => 'Crap'})->create;

        my $book = Book->new(title => 'Crap')->load;

        my $author = $book->find_related('parent_author');

        is($author->get_column('name'), 'vti');
    };

    it 'find related' => sub {
        Author->new(name => 'vti', books => {title => 'Crap'})->create;

        my $book = Book->new->table->find(first => 1, with => 'parent_author');
        ok $book->is_related_loaded('parent_author');
        is($book->related('parent_author')->get_column('name'), 'vti');
    };

    it 'find related deeply' => sub {
        Author->new(
            name  => 'vti',
            books => {title => 'Crap', description => {description => 'Very'}}
        )->create;

        my $description = BookDescription->new->table->find(
            first => 1,
            with  => 'parent_book.parent_author'
        );
        ok $description->is_related_loaded('parent_book');
        is($description->related('parent_book')->get_column('title'), 'Crap');
        ok $description->related('parent_book')
          ->is_related_loaded('parent_author');
        is(
            $description->related('parent_book')->related('parent_author')
              ->get_column('name'),
            'vti'
        );
    };

    it 'find related with query' => sub {
        Author->new(name => 'vti', books => {title => 'Crap'})->create;
        Author->new(name => 'foo')->create;

        my $book = Book->new->table->find(
            first => 1,
            where => ['parent_author.name' => 'vti']
        );
        ok $book->is_related_loaded('parent_author');
        is($book->related('parent_author')->get_column('name'), 'vti');
    };

    it 'find related when no related' => sub {
        Book->new(title => 'Crap')->create;

        my $book = Book->new->table->find(first => 1, with => 'parent_author');
        ok(!$book->is_related_loaded('parent_author'));
        ok(!$book->related('parent_author'));
    };

    it 'not create already created related objects' => sub {
        my $author = Author->new->create;
        my $book = Book->new(title => 'Crap', author_id => $author->get_column('id'));
        $book->related('parent_author');

        ok $book->create;
    };

};

runtests unless caller;
