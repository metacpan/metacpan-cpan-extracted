package Author;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->meta(
    table          => 'author',
    columns        => [qw/id name/],
    primary_key    => 'id',
    auto_increment => 'id',
    unique_keys    => 'name',
    relationships  => {
        books => {
            type  => 'one to many',
            class => 'Book',
            map   => {id => 'author_id'}
        }
    },
);

1;
