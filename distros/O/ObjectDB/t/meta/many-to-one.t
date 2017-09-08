use strict;
use warnings;
use lib 't/lib';
use TestEnv;

use Test::More;
use Test::Fatal;

use Author;
use Book;

use_ok 'ObjectDB::Meta::Relationship::ManyToOne';

subtest 'to_source: builds correct mapping' => sub {
    my $rel = _build_relationship(
        name       => 'author',
        type       => 'many to one',
        class      => 'Author',
        orig_class => 'Book',
        map        => { book_author_id => 'id' },
        constraint => [ foo => 'bar' ]
    );

    is_deeply(
        $rel->to_source,
        {
            table      => 'author',
            as         => 'author',
            join       => 'left',
            constraint => [
                'book.book_author_id' => { -col => 'author.id' },
                foo                   => 'bar'
            ],
            columns => [ 'id', 'name' ]
        }
    );
};

subtest 'to_source: builds mapping saving primary key' => sub {
    my $rel = _build_relationship(
        name       => 'author',
        type       => 'many to one',
        class      => 'Author',
        orig_class => 'Book',
        map        => { book_author_id => 'id' }
    );

    is_deeply(
        $rel->to_source(columns => []),
        {
            table      => 'author',
            as         => 'author',
            join       => 'left',
            constraint => [ 'book.book_author_id' => { -col => 'author.id' } ],
            columns    => ['id']
        }
    );
};

subtest 'to_source: builds mapping with join type' => sub {
    my $rel = _build_relationship(
        name       => 'parent_author',
        type       => 'many to one',
        orig_class => 'Book',
        class      => 'Author',
        map        => { author_id => 'id' },
        join       => 'inner'
    );

    is_deeply(
        $rel->to_source,
        {
            table      => 'author',
            as         => 'parent_author',
            join       => 'inner',
            constraint => [ 'book.author_id' => { -col => 'parent_author.id' } ],
            columns => [ 'id', 'name' ]
        }
    );
};

done_testing;

sub _build_relationship {
    ObjectDB::Meta::Relationship::ManyToOne->new(@_);
}
