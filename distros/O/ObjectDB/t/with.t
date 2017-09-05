use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;

use ObjectDB::With;

use Book;
use BookDescription;

subtest 'convert with to joins' => sub {
    my $with = ObjectDB::With->new(meta => Book->meta, with => ['parent_author']);

    is_deeply $with->to_joins,
      [
        {
            source   => 'author',
            rel_name => 'parent_author',
            as       => 'parent_author',
            op       => 'left',
            columns  => [qw/id name/],
            on       => [ 'book.author_id' => { -col => 'parent_author.id' } ],
            join     => [],
        }
      ];
};

subtest 'convert with to joins with custom columns' => sub {
    my $with = ObjectDB::With->new(meta => Book->meta, with => [ { name => 'parent_author', columns => [qw/id/] } ]);

    is_deeply $with->to_joins,
      [
        {
            source   => 'author',
            rel_name => 'parent_author',
            as       => 'parent_author',
            op       => 'left',
            columns  => [qw/id/],
            on       => [ 'book.author_id' => { -col => 'parent_author.id' } ],
            join     => [],
        }
      ];
};

subtest 'convert with to joins deeply' => sub {
    my $with = ObjectDB::With->new(
        meta => BookDescription->meta,
        with => [ 'parent_book', 'parent_book.parent_author' ]
    );

    is_deeply $with->to_joins,
      [
        {
            source   => 'book',
            as       => 'parent_book',
            rel_name => 'parent_book',
            op       => 'left',
            columns  => [qw/id author_id title/],
            on       => [ 'book_description.book_id' => { -col => 'parent_book.id' } ],
            join     => [
                {
                    source   => 'author',
                    as       => 'parent_book_parent_author',
                    rel_name => 'parent_author',
                    op       => 'left',
                    columns  => [qw/id name/],
                    on       => [
                        'parent_book.author_id' => { -col => 'parent_book_parent_author.id' }
                    ],
                    join => []
                }
            ]
        },
      ];
};

subtest 'autoload intermediate joins' => sub {
    my $with = ObjectDB::With->new(
        meta => BookDescription->meta,
        with => ['parent_book.parent_author']
    );

    is_deeply $with->to_joins,
      [
        {
            source   => 'book',
            as       => 'parent_book',
            rel_name => 'parent_book',
            op       => 'left',
            columns  => [qw/id author_id title/],
            on       => [ 'book_description.book_id' => { -col => 'parent_book.id' } ],
            join     => [
                {
                    source   => 'author',
                    as       => 'parent_book_parent_author',
                    rel_name => 'parent_author',
                    op       => 'left',
                    columns  => [qw/id name/],
                    on       => [
                        'parent_book.author_id' => { -col => 'parent_book_parent_author.id' }
                    ],
                    join => []
                }
            ]
        },
      ];
};

subtest 'throw when unknown relationship' => sub {
    like exception { ObjectDB::With->new(meta => Book->meta, with => ['unknown']) }, qr/Unknown relationship 'unknown'/;
};

done_testing;
