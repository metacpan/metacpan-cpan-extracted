use strict;
use warnings;
use lib 't/lib';
use TestEnv;

use Test::More;
use Test::Fatal;
use TestEnv;

use_ok 'ObjectDB::Meta::Relationship::ManyToMany';

subtest 'to_source: builds correct mapping' => sub {
    my $rel = _build_relationship(
        name       => 'tags',
        orig_class => 'Book',
        type       => 'many to many',
        map_class  => 'BookTagMap',
        map_from   => 'book',
        map_to     => 'tag'
    );

    is_deeply(
        [ $rel->to_source ],
        [
            {
                table      => 'book_tag_map',
                as         => 'book_tag_map',
                join       => 'left',
                constraint => [ 'book.id' => { -col => 'book_tag_map.book_id' } ]
            },
            {
                table      => 'tag',
                as         => 'tags',
                join       => 'left',
                constraint => [ 'book_tag_map.tag_id' => { -col => 'tags.id' } ],
                columns => [ 'id', 'name' ]
            }
        ]
    );
};

done_testing;

sub _build_relationship {
    ObjectDB::Meta::Relationship::ManyToMany->new(@_);
}
