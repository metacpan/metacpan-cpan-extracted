use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use Author;
use Book;

use ObjectDB::Meta::Relationship::ManyToOne;

describe 'many to one' => sub {

    it 'build_to_source' => sub {
        my $rel = _build_relationship(
            name       => 'author',
            type       => 'many to one',
            class      => 'Author',
            orig_class => 'Book',
            map        => {book_author_id => 'id'},
            constraint => [foo => 'bar']
        );

        is_deeply(
            $rel->to_source,
            {
                table      => 'author',
                as         => 'author',
                join       => 'left',
                constraint => [
                    'book.book_author_id' => {-col => 'author.id'},
                    foo                   => 'bar'
                ],
                columns => ['id', 'name']
            }
        );
    };

    it 'accept_columns_but_leave_primary_key' => sub {
        my $rel = _build_relationship(
            name       => 'author',
            type       => 'many to one',
            class      => 'Author',
            orig_class => 'Book',
            map        => {book_author_id => 'id'}
        );

        is_deeply(
            $rel->to_source(columns => []),
            {
                table      => 'author',
                as         => 'author',
                join       => 'left',
                constraint => ['book.book_author_id' => {-col => 'author.id'}],
                columns    => ['id']
            }
        );
    };

    it 'accept_join_type' => sub {
        my $rel = _build_relationship(
            name       => 'parent_author',
            type       => 'many to one',
            orig_class => 'Book',
            class      => 'Author',
            map        => {author_id => 'id'},
            join       => 'inner'
        );

        is_deeply(
            $rel->to_source,
            {
                table => 'author',
                as    => 'parent_author',
                join  => 'inner',
                constraint =>
                  ['book.author_id' => {-col => 'parent_author.id'}],
                columns => ['id', 'name']
            }
        );
    };

};

sub _build_relationship {
    ObjectDB::Meta::Relationship::ManyToOne->new(@_);
}

runtests unless caller;
