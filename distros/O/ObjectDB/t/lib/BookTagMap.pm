package BookTagMap;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->meta(
    table         => 'book_tag_map',
    columns       => [qw/book_id tag_id/],
    primary_key   => [qw/book_id tag_id/],
    relationships => {
        book => {
            type  => 'many to one',
            class => 'Book',
            map   => {book_id => 'id'}
        },
        tag => {
            type  => 'many to one',
            class => 'Tag',
            map   => {tag_id => 'id'}
        }
    }
);

1;
