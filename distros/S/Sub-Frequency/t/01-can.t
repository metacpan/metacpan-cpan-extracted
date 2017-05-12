use strict;
use warnings;

use Test::More;
use Sub::Frequency;

can_ok 'Sub::Frequency', qw( always normally usually sometimes maybe
                             rarely seldom never with_probability
                           );

done_testing;
