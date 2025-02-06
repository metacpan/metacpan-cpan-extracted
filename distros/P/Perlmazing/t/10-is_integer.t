use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 6;
use Perlmazing qw(is_integer);

is is_integer 5, 1, 'is_integer returns the correct value';
isnt is_integer 3.4, 1, 'is_integer returns the correct value';
is is_integer 1024, 1, 'is_integer returns the correct value';
is is_integer 1024.0000001, undef, 'is_integer returns the correct value';
is is_integer undef, undef, 'is_integer returns the correct value';
is is_integer 'string', undef, 'is_integer returns the correct value';