use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use Book;
use Tag;
use BookTagMap;

subtest 'sets correct values on new' => sub {
    _setup();

    my $book = Book->new(
        title => 'Crap',
        tags  => [ { name => 'fiction' }, { name => 'crap' } ]
    );

    my @tags = $book->related('tags');

    is(@tags, 2);

    is($tags[0]->get_column('name'), 'fiction');
};

subtest 'sets correct values on create' => sub {
    _setup();

    my $book = Book->new(
        title => 'Crap',
        tags  => [ { name => 'fiction' }, { name => 'crap' } ]
    )->create;

    my @tags = $book->related('tags');

    is(@tags, 2);

    is($tags[0]->get_column('name'), 'fiction');
};

# TODO
#subtest 'load with related' => sub {
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
#subtest 'find with related' => sub {
#    Book->new(
#        title => 'Book',
#        tags  => [{name => 'fiction'}, {name => 'crap'}]
#    )->create;

#    my $book = Book->new->table->find(first => 1, with => ['book_tag_map', 'tags']);
#    ok $book->is_related_loaded('tags');
#    is($book->related('tags')->[0]->get_column('name'), 'fiction');
#    is($book->related('tags')->[1]->get_column('name'), 'crap');
#};

subtest 'find related' => sub {
    _setup();

    Book->new(title => 'Crap', tags => { name => 'fiction' })->create;
    Tag->new(name => 'else')->create;

    my $book = Book->new(title => 'Crap')->load;

    my @tags = $book->find_related('tags');

    is(@tags, 1);

    is($tags[0]->get_column('name'), 'fiction');
};

subtest 'find related with where' => sub {
    _setup();

    Book->new(
        title => 'Crap',
        tags  => [ { name => 'fiction1' }, { name => 'fiction2' } ]
    )->create;

    my $book = Book->new(title => 'Crap')->load;

    my @tags = $book->find_related('tags', where => [ name => 'fiction1' ]);

    is(@tags, 1);

    is($tags[0]->get_column('name'), 'fiction1');
};

subtest 'find via related' => sub {
    _setup();

    Book->new(
        title => 'Crap',
        tags  => [ { name => 'fiction1' }, { name => 'fiction2' } ]
    )->create;
    Book->new(
        title => 'Good',
        tags  => [ { name => 'documentary' } ]
    )->create;

    my @books = Book->find(where => [ 'tags.name' => 'documentary' ]);

    is @books, 1;
    is $books[0]->get_column('title'), 'Good';
};

subtest 'create related with map row' => sub {
    _setup();

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

subtest 'create related from instance' => sub {
    _setup();

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

subtest 'create related from instance from db' => sub {
    _setup();

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

subtest 'create related when map already exists' => sub {
    _setup();

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

subtest 'when tag exists, create only map row' => sub {
    _setup();

    my $book = Book->new(title => 'Crap')->create;
    Tag->new(name => 'horror')->create;
    my $tag = $book->create_related('tags', name => 'horror');

    my $map = BookTagMap->new(
        book_id => $book->get_column('id'),
        tag_id  => $tag->get_column('id')
    )->load;
    ok($map);
};

subtest 'count related' => sub {
    _setup();

    Book->new(title => 'Crap', tags => { name => 'fiction' })->create;

    Tag->new(name => 'else')->create;

    my $book = Book->new(title => 'Crap')->load;

    is($book->count_related('tags'), 1);
};

subtest 'count related with where' => sub {
    _setup();

    Book->new(
        title => 'Crap',
        tags  => [ { name => 'fiction1' }, { name => 'fiction2' } ]
    )->create;

    my $book = Book->new(title => 'Crap')->load;

    is($book->count_related('tags', where => [ name => 'fiction1' ]), 1);
};

subtest 'delete_map_entry_on_delete_related' => sub {
    _setup();

    Book->new(title => 'Crap', tags => { name => 'fiction' })->create;

    my $book = Book->new(title => 'Crap')->load;

    $book->delete_related('tags');

    ok(!BookTagMap->table->count);
};

subtest 'delete_only_map_entry_on_delete_related' => sub {
    _setup();

    Book->new(title => 'Crap', tags => { name => 'fiction' })->create;

    my $book = Book->new(title => 'Crap')->load;

    $book->delete_related('tags');

    ok(Tag->table->count);
};

done_testing;

sub _setup {
    TestEnv->prepare_table('book');
    TestEnv->prepare_table('tag');
    TestEnv->prepare_table('book_tag_map');
}
