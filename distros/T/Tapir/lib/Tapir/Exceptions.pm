package Tapir::Exceptions;

use strict;
use warnings;

use Exception::Class (
    'Tapir::Exception',

    'Tapir::Unauthorized' => {
        isa => 'Tapir::Exception',
    },

    'Tapir::InvalidArgument' => {
        isa => 'Tapir::Exception',
        fields => [ 'key', 'value' ],
    },

    'Tapir::MissingArgument' => {
        isa => 'Tapir::InvalidArgument',
    },

    'Tapir::InvalidSpec' => {
        ida => 'Tapir::Exception',
        fields => [ 'key' ],
    },

);

1;
