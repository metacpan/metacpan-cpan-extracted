use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::Perl;

is([1,2,3]->$_perl, '[1,2,3,]');

done_testing;

