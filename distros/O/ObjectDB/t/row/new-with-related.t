use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use Author;
use Book;

subtest 'accepts related values as hash ref' => sub {
    my $author = Author->new(books => { title => 'foo' });

    my @books = $author->related('books');
    is(@books,                         1);
    is($books[0]->get_column('title'), 'foo');
};

subtest 'accepts related values as objects' => sub {
    my $author = Author->new(books => Book->new);

    my @books = $author->related('books');
    is(@books, 1);
};

subtest 'accepts related values as array of objects' => sub {
    my $author =
      Author->new(books => [ Book->new(title => 'foo'), { title => 'bar' } ]);

    my @books = $author->related('books');
    is(@books,                         2);
    is($books[0]->get_column('title'), 'foo');
    is($books[1]->get_column('title'), 'bar');
};

subtest 'not set related when value is undef' => sub {
    my $author = Author->new(books => undef);

    my @books = $author->related('books');
    is(@books, 0);
};

subtest 'not set related when array of empty values' => sub {
    my $author = Author->new(books => [ {}, undef ]);

    my @books = $author->related('books');
    is(@books, 0);
};

done_testing;
