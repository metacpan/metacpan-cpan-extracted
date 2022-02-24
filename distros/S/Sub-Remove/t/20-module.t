#!perl
use 5.006;
use strict;
use warnings;

use Sub::Remove qw(sub_remove);

use Test::More;

{
    package Testing;

    sub function {
        return 100;
    }
}

{
    # Throws
    {
        is
            eval { sub_remove('asdfasdf', 'Testing'); 1; },
            undef,
            "sub_remove() barfs if sub name sent in doesn't exist ok";
        like
            $@,
            qr/Subroutine named 'Testing::asdfasdf' doesn't exist/,
            "...and error message is sane";
    }

    # Testing::function sub
    {
        like
            'Testing'->can('function'),
            qr/^CODE/,
            "Testing::function() exists ok";

        is Testing::function(), 100, "...and it returns properly";

        sub_remove('function', 'Testing');

        is
            'Testing'->can('function'),
            undef,
            "sub_remove() removed Testing::function() ok";

        is
            eval { Testing::function(); 1; },
            undef,
            "...and it definitely can't be called";

        like
            $@,
            qr/Undefined subroutine/,
            "...and error message is sane";
    }
}

done_testing();