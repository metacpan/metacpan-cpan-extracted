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

subtest 'related' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    my $book = Book->new(title => 'Crap', author_id => $author->get_column('id'))->create;

    $book = Book->new(title => 'Crap')->load(with => 'parent_author');

    is($book->related('parent_author')->get_column('name'), 'vti');
};

subtest 'related reverse' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    my $book = Book->new(title => 'Crap', author_id => $author->get_column('id'))->create;

    $author = Author->new(name => 'vti')->load(with => 'books');

    ok($author->is_related_loaded('books'));
    is($author->related('books')->[0]->get_column('title'), 'Crap');
};

subtest 'does not load empty related objects' => sub {
    _setup();

    my $book = Book->new(title => 'Crap')->create;

    $book = Book->new(title => 'Crap')->load(with => 'parent_author');

    ok(!defined $book->related('parent_author'));
};

subtest 'does not load empty deeply related objects' => sub {
    _setup();

    my $book_description = BookDescription->new(description => 'Crap')->create;

    $book_description =
      BookDescription->new(id => $book_description->get_column('id'))
      ->load(with => [ 'parent_book', 'parent_book.parent_author' ]);

    ok(!defined $book_description->related('parent_book'));
};

subtest 'is_related_loaded' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    my $book = Book->new(title => 'Crap', author_id => $author->get_column('id'))->create;

    $book = Book->new(title => 'Crap')->load(with => 'parent_author');

    ok($book->is_related_loaded('parent_author'));
};

subtest 'load_related_on_demand' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    my $book = Book->new(title => 'Crap', author_id => $author->get_column('id'))->create;

    $book = Book->new(title => 'Crap')->load;

    is($book->related('parent_author')->get_column('name'), 'vti');
};

subtest 'is_related_loaded_false' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    my $book = Book->new(title => 'Crap', author_id => $author->get_column('id'))->create;

    $book = Book->new(title => 'Crap')->load;

    ok(!$book->is_related_loaded('parent_author'));
};

subtest 'resets related on load' => sub {
    _setup();

    my $author = Author->new(name => 'vti')->create;
    my $book = Book->new(title => 'Crap', author_id => $author->get_column('id'))->create;

    $book = Book->new(title => 'Crap')->load(with => 'parent_author');

    ok($book->is_related_loaded('parent_author'));

    $book = $book->load;

    ok(!$book->is_related_loaded('parent_author'));
};

done_testing;

sub _setup {
    TestEnv->prepare_table('author');
    TestEnv->prepare_table('book');
    TestEnv->prepare_table('book_description');
}
