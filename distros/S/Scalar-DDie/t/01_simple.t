use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::DDie;

is(ddie(5), 5);

eval { ddie(undef) };

like $@, qr/The value is not defined/;

done_testing;

