package Tag;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->meta(
    table          => 'tag',
    columns        => [qw/id name/],
    primary_key    => 'id',
    auto_increment => 'id',
    unique_keys    => 'name',
    relationships  => {
        book_tag_map => {
            type  => 'one to many',
            class => 'BookTagMap',
            map   => {id => 'tag_id'}
        },
        books => {
            type      => 'many to many',
            map_class => 'BookTagMap',
            map_from  => 'tag',
            map_to    => 'book'
        }
    }
);

1;
