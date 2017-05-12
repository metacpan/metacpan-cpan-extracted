use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use Book;
use Tag;
use BookTagMap;

describe 'many to many' => sub {

    before each => sub {
        TestEnv->prepare_table('book');
        TestEnv->prepare_table('tag');
        TestEnv->prepare_table('book_tag_map');
    };

    it 'sets correct values on new' => sub {
        my $book = Book->new(
            title => 'Crap',
            tags  => [{name => 'fiction'}, {name => 'crap'}]
        );

        my @tags = $book->related('tags');

        is(@tags, 2);

        is($tags[0]->get_column('name'), 'fiction');
    };

    it 'sets correct values on create' => sub {
        my $book = Book->new(
            title => 'Crap',
            tags  => [{name => 'fiction'}, {name => 'crap'}]
        )->create;

        my @tags = $book->related('tags');

        is(@tags, 2);

        is($tags[0]->get_column('name'), 'fiction');
    };

    # TODO
    #it 'load with related' => sub {
    #    my $book = Book->new(
    #        title => 'Book',
    #        tags  => [{name => 'fiction'}, {name => 'crap'}]
    #    )->create;

    #    $book = Book->new(id => $book->get_column('id'))->load(with => ['book_tag_map', 'tags']);
    #    ok $book->is_related_loaded('tags');
    #    is($book->related('tags')->[0]->get_column('name'), 'fiction');
    #    is($book->related('tags')->[1]->get_column('name'), 'crap');
    #};
    #
    #it 'find with related' => sub {
    #    Book->new(
    #        title => 'Book',
    #        tags  => [{name => 'fiction'}, {name => 'crap'}]
    #    )->create;

    #    my $book = Book->new->table->find(first => 1, with => ['book_tag_map', 'tags']);
    #    ok $book->is_related_loaded('tags');
    #    is($book->related('tags')->[0]->get_column('name'), 'fiction');
    #    is($book->related('tags')->[1]->get_column('name'), 'crap');
    #};

    it 'find related' => sub {
        Book->new(title => 'Crap', tags => {name => 'fiction'})->create;
        Tag->new(name => 'else')->create;

        my $book = Book->new(title => 'Crap')->load;

        my @tags = $book->find_related('tags');

        is(@tags, 1);

        is($tags[0]->get_column('name'), 'fiction');
    };

    it 'find related with where' => sub {
        Book->new(
            title => 'Crap',
            tags  => [{name => 'fiction1'}, {name => 'fiction2'}]
        )->create;

        my $book = Book->new(title => 'Crap')->load;

        my @tags = $book->find_related('tags', where => [name => 'fiction1']);

        is(@tags, 1);

        is($tags[0]->get_column('name'), 'fiction1');
    };

    it 'find via related' => sub {
        Book->new(
            title => 'Crap',
            tags  => [{name => 'fiction1'}, {name => 'fiction2'}]
        )->create;
        Book->new(
            title => 'Good',
            tags  => [{name => 'documentary'}]
        )->create;

        my @books = Book->find(where => ['tags.name' => 'documentary']);

        is @books, 1;
        is $books[0]->get_column('title'), 'Good';
    };

    it 'create related with map row' => sub {
        my $self = shift;

        my $book = Book->new(title => 'Crap')->create;
        my $tag = $book->create_related('tags', name => 'horror');

        ok(
            BookTagMap->new(
                book_id => $book->get_column('id'),
                tag_id  => $tag->get_column('id')
            )->load
        );
        ok(Tag->new(name => 'horror')->load);
    };

    it 'create related from instance' => sub {
        my $self = shift;

        my $book = Book->new(title => 'Crap')->create;
        my $tag = $book->create_related('tags', Tag->new(name => 'hi there'));

        ok(
            BookTagMap->new(
                book_id => $book->get_column('id'),
                tag_id  => $tag->get_column('id')
            )->load
        );
        ok(Tag->new(name => 'hi there')->load);
    };

    it 'create related from instance from db' => sub {
        my $self = shift;

        my $book = Book->new(title => 'Crap')->create;
        my $tag = Tag->new(name => 'hi there')->create;

        $book->create_related('tags', $tag);

        ok(
            BookTagMap->new(
                book_id => $book->get_column('id'),
                tag_id  => $tag->get_column('id')
            )->load
        );
        ok(Tag->new(name => 'hi there')->load);
    };

    it 'create related when map already exists' => sub {
        my $self = shift;

        my $book = Book->new(title => 'Crap')->create;
        my $tag = Tag->new(name => 'hi there')->create;
        $book->create_related('tags', $tag);
        $book->create_related('tags', $tag);

        ok(
            BookTagMap->new(
                book_id => $book->get_column('id'),
                tag_id  => $tag->get_column('id')
            )->load
        );
        ok(Tag->new(name => 'hi there')->load);
    };

    it 'when tag exists, create only map row' => sub {
        my $self = shift;

        my $book = Book->new(title => 'Crap')->create;
        Tag->new(name => 'horror')->create;
        my $tag = $book->create_related('tags', name => 'horror');

        my $map = BookTagMap->new(
            book_id => $book->get_column('id'),
            tag_id  => $tag->get_column('id')
        )->load;
        ok($map);
    };

    it 'count related' => sub {
        my $self = shift;

        Book->new(title => 'Crap', tags => {name => 'fiction'})->create;

        Tag->new(name => 'else')->create;

        my $book = Book->new(title => 'Crap')->load;

        is($book->count_related('tags'), 1);
    };

    it 'count related with where' => sub {
        my $self = shift;

        Book->new(
            title => 'Crap',
            tags  => [{name => 'fiction1'}, {name => 'fiction2'}]
        )->create;

        my $book = Book->new(title => 'Crap')->load;

        is($book->count_related('tags', where => [name => 'fiction1']), 1);
    };

    it 'delete_map_entry_on_delete_related' => sub {
        my $self = shift;

        Book->new(title => 'Crap', tags => {name => 'fiction'})->create;

        my $book = Book->new(title => 'Crap')->load;

        $book->delete_related('tags');

        ok(!BookTagMap->table->count);
    };

    it 'delete_only_map_entry_on_delete_related' => sub {
        my $self = shift;

        Book->new(title => 'Crap', tags => {name => 'fiction'})->create;

        my $book = Book->new(title => 'Crap')->load;

        $book->delete_related('tags');

        ok(Tag->table->count);
    };

};

runtests unless caller;
