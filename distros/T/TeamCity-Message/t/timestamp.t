#!perl

use strict;
use warnings;

use Test::Fatal;
use Test::More 0.96;

use TeamCity::Message qw( tc_timestamp );

like tc_timestamp(), qr/^
    [0-9]{4}-[0-9]{2}-[0-9]{2}
    T
    [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}
$/x, 'timetamp matches regex';

done_testing
