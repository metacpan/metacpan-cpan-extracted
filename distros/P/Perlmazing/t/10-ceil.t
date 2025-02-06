use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;
use Perlmazing qw(ceil);

is ceil(5.4), 6, 'Ceil value is correct';
is ceil(4), 4, 'Ceil value is correct';
is ceil(1.0000001), 2, 'Ceil value is correct';
is ceil('string'), 'string', 'Ceil value is correct';