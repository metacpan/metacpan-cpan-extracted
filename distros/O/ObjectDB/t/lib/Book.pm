package Book;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->meta(
    table          => 'book',
    columns        => [qw/id author_id title/],
    primary_key    => 'id',
    auto_increment => 'id',
    unique_keys    => 'title',
    relationships  => {
        parent_author => {
            type  => 'many to one',
            class => 'Author',
            map   => {author_id => 'id'}
        },
        book_tag_map => {
            type  => 'one to many',
            class => 'BookTagMap',
            map   => {id => 'book_id'}
        },
        tags => {
            type      => 'many to many',
            map_class => 'BookTagMap',
            map_from  => 'book',
            map_to    => 'tag'
        },
        description => {
            type  => 'one to one',
            class => 'BookDescription',
            map   => {id => 'book_id'}
        }
    }
);

1;
