package BookDescription;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->meta(
    table          => 'book_description',
    columns        => [qw/id book_id description/],
    primary_key    => 'id',
    auto_increment => 'id',
    relationships  => {
        parent_book => {
            type  => 'one to one',
            class => 'Book',
            map   => {book_id => 'id'}
        }
    }
);

1;
