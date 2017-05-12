use strict;
use warnings;
use utf8;
use Test::More;
use PLON;

is(PLON->new->canonical->encode({ a => 1, b => 2, c => 3 }), '{"a"=>1,"b"=>2,"c"=>3,}');

done_testing;

