package Reply;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->meta(
    table          => 'reply',
    columns        => [qw/id author_id thread_id parent_id content/],
    primary_key    => 'id',
    auto_increment => 'id',
    relationships  => {
        thread => {
            type  => 'many to one',
            class => 'Thread',
            map   => { thread_id => 'id' }
        },
        author => {
            type  => 'many to one',
            class => 'Author',
            map   => { author_id => 'id' }
        },
        parent => {
            type  => 'many to one',
            class => 'Reply',
            map   => { parent_id => 'id' }
        },
    },
);

1;
