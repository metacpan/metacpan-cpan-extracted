package Spread::Messaging::Exception;

use strict;
use warnings;

use Exception::Class (
    'Spread::Messaging::Exception' => {
        fields => [qw( errno errstr )]
    }
);

1;
