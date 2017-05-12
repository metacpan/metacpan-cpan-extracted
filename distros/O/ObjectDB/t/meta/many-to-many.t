use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use ObjectDB::Meta::Relationship::ManyToMany;

describe 'many to many' => sub {

    it 'build_to_source' => sub {
        my $rel = _build_relationship(
            name       => 'tags',
            orig_class => 'Book',
            type       => 'many to many',
            map_class  => 'BookTagMap',
            map_from   => 'book',
            map_to     => 'tag'
        );

        is_deeply(
            [$rel->to_source],
            [
                {
                    table => 'book_tag_map',
                    as    => 'book_tag_map',
                    join  => 'left',
                    constraint =>
                      ['book.id' => {-col => 'book_tag_map.book_id'}]
                },
                {
                    table => 'tag',
                    as    => 'tags',
                    join  => 'left',
                    constraint =>
                      ['book_tag_map.tag_id' => {-col => 'tags.id'}],
                    columns => ['id', 'name']
                }
            ]
        );
    };

};

sub _build_relationship {
    ObjectDB::Meta::Relationship::ManyToMany->new(@_);
}

runtests unless caller;
