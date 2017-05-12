use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use Author;
use Book;
use Person;

describe 'to hash' => sub {

    before each => sub {
        TestEnv->prepare_table('author');
        TestEnv->prepare_table('book');
    };

    it 'to_hash' => sub {
        my $author = Author->new(name => 'vti')->create;

        is_deeply($author->to_hash, {id => 1, name => 'vti'});
    };

    it 'with_virtual_columns' => sub {
        my $author = Author->new(name => 'vti')->create;
        $author->set_column(virtual => 'bar');

        is_deeply($author->to_hash, {id => 1, name => 'vti', virtual => 'bar'});
    };

    it 'with_default_values' => sub {
        my $person = Person->new();

        is_deeply($person->to_hash, {profession => 'slacker'});
    };

    it 'with_related' => sub {
        my $author = Author->new(name => 'vti')->create;
        $author->create_related('books', title => 'Crap');

        my $book = Book->new(title => 'Crap')->load(with => 'parent_author');

        is_deeply(
            $book->to_hash,
            {
                id            => 1,
                author_id     => 1,
                title         => 'Crap',
                parent_author => {id => 1, name => 'vti'}
            }
        );
    };

    it 'with related empty' => sub {
        Book->new(title => 'Crap')->create;

        my $book = Book->new(title => 'Crap')->load(with => 'parent_author');
        $book->related('parent_author');

        is_deeply(
            $book->to_hash,
            {
                id        => 1,
                author_id => 0,
                title     => 'Crap',
            }
        );
    };

    it 'with_related multi' => sub {
        my $author = Author->new(name => 'vti')->create;
        $author->create_related('books', title => 'Crap');

        $author->load(with => 'books');

        is_deeply(
            $author->to_hash,
            {
                id    => 1,
                name  => 'vti',
                books => [{id => 1, author_id => 1, title => 'Crap'}]
            }
        );
    };

};

runtests unless caller;
