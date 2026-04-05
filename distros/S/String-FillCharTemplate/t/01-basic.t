#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use String::FillCharTemplate qw(
                                  fill_char_template
                          );

subtest "fill_char_template" => sub {
    is(fill_char_template("###-###-###", "1234567890"), "123-456-789");
    is(fill_char_template(" ##-###-## ", "aabb"), " aa-bb -   ");
};

DONE_TESTING:
done_testing();
