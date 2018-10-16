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
    my $with = ObjectDB::With->new(
        meta => Book->meta,
        with => [ { name => 'parent_author', columns => [qw/id/] } ]
    );

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
    like exception {
        ObjectDB::With->new(meta => Book->meta, with => ['unknown'])
    }, qr/Unknown relationship 'unknown'/;
};

subtest 'convert with to joins with custom columns correct order' => sub {
    for (1 .. 100) {
        my $with = ObjectDB::With->new(
            meta => Book->meta,
            with => [
                { name => 'parent_author', columns => [qw/name/] },
                {
                    name    => 'description.parent_book',
                    columns => [qw/id title/]
                },
                'parent_author.books',
                { name => 'description', columns => [qw/id description/] }
            ]
        );

        is_deeply $with->to_joins,
          [
            {
                'columns' => [ 'id', 'description' ],
                'op'      => 'left',
                'join'    => [
                    {
                        'on' => [
                            'description.book_id',
                            {
                                '-col' => 'description_parent_book.id'
                            }
                        ],
                        'rel_name' => 'parent_book',
                        'source'   => 'book',
                        'op'       => 'left',
                        'join'     => [],
                        'as'       => 'description_parent_book',
                        'columns'  => [ 'id', 'title' ]
                    }
                ],
                'as'       => 'description',
                'source'   => 'book_description',
                'rel_name' => 'description',
                'on'       => [
                    'book.id',
                    {
                        '-col' => 'description.book_id'
                    }
                ]
            },
            {
                'source' => 'author',
                'on'     => [
                    'book.author_id',
                    {
                        '-col' => 'parent_author.id'
                    }
                ],
                'rel_name' => 'parent_author',
                'columns'  => ['name'],
                'op'       => 'left',
                'as'       => 'parent_author',
                'join'     => [
                    {
                        'columns'  => [ 'id', 'author_id', 'title' ],
                        'op'       => 'left',
                        'join'     => [],
                        'as'       => 'parent_author_books',
                        'rel_name' => 'books',
                        'on'       => [
                            'author.id',
                            {
                                '-col' => 'books.author_id'
                            }
                        ],
                        'source' => 'book'
                    }
                ]
            }
          ];
    }
};

done_testing;
