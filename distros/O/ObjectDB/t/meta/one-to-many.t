use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use ObjectDB::Meta::Relationship::OneToMany;

describe 'one to many' => sub {

    it 'build_to_source' => sub {
        my $rel = _build_relationship(
            name       => 'books',
            type       => 'one to many',
            orig_class => 'Author',
            class      => 'Book',
            map        => {id => 'book_author_id'},
            constraint => [foo => 'bar']
        );

        is_deeply(
            $rel->to_source,
            {
                table      => 'book',
                as         => 'books',
                join       => 'left',
                constraint => [
                    'author.id' => {-col => 'books.book_author_id'},
                    foo         => 'bar'
                ],
                columns => ['id', 'author_id', 'title']
            }
        );
    };

};

sub _build_relationship {
    ObjectDB::Meta::Relationship::OneToMany->new(@_);
}

runtests unless caller;
