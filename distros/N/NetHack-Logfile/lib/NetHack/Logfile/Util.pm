package NetHack::Logfile::Util;
our $VERSION = '1.00';

use MooseX::Attributes::Curried (
    field => sub {
        return { } if /^\+/;

        return {
            is       => 'ro',
            isa      => 'Str',
            required => 1,
        }
    },
);

1;

