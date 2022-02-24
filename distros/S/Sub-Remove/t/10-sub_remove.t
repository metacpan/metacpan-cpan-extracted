#!perl
use 5.006;
use strict;
use warnings;

use Sub::Remove qw(sub_remove);

use Test::More;

# Throws
{
    is
        eval { sub_remove(); 1; },
        undef,
        "sub_remove() barfs if no parameters sent in ok";

    like
        $@,
        qr/sub_remove\(\) requires a subroutine name/,
        "...and error message is sane";

    is
        eval { sub_remove('asdfasdf'); 1; },
        undef,
        "sub_remove() barfs if sub name sent in doesn't exist ok";

    like
        $@,
        qr/Subroutine named 'main::asdfasdf' doesn't exist/,
        "...and error message is sane";
}

# main sub
{
    like
        'main'->can('testing'),
        qr/^CODE/,
        "main::testing() exists ok";

    is testing(), 99, "...and it returns properly";

    sub_remove('testing');

    is
        'main'->can('testing'),
        undef,
        "sub_remove() removed main::testing() ok";

    is
        eval { testing(); 1; },
        undef,
        "...and it definitely can't be called";

    like
        $@,
        qr/Undefined subroutine/,
        "...and error message is sane"
}

sub testing {
    return 99;
}

done_testing();