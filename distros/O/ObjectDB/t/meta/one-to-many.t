use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;

use_ok 'ObjectDB::Meta::Relationship::OneToMany';

subtest 'to_source: builds correct mapping' => sub {
    my $rel = _build_relationship(
        name       => 'books',
        type       => 'one to many',
        orig_class => 'Author',
        class      => 'Book',
        map        => { id => 'book_author_id' },
        constraint => [ foo => 'bar' ]
    );

    is_deeply(
        $rel->to_source,
        {
            table      => 'book',
            as         => 'books',
            join       => 'left',
            constraint => [
                'author.id' => { -col => 'books.book_author_id' },
                foo         => 'bar'
            ],
            columns => [ 'id', 'author_id', 'title' ]
        }
    );
};

done_testing;

sub _build_relationship {
    ObjectDB::Meta::Relationship::OneToMany->new(@_);
}
