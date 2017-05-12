package Thread;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->meta(
    table          => 'thread',
    columns        => [qw/id author_id title/],
    primary_key    => 'id',
    auto_increment => 'id',
    relationships  => {
        author => {
            type  => 'many to one',
            class => 'Author',
            map   => {author_id => 'id'}
        }
    }
);

1;
