package Notification;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->meta(
    table          => 'notification',
    columns        => [qw/id reply_id/],
    primary_key    => 'id',
    auto_increment => 'id',
    relationships  => {
        reply => {
            type  => 'many to one',
            class => 'Reply',
            map   => {reply_id => 'id'}
        },
    },
);

1;
