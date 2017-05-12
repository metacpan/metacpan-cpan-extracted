#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;
use Test::Fatal;

use Statistics::R::REXP;

# not instantiable
like(exception {
    Statistics::R::REXP->new,
     }, qr /an abstract class/,
     'creating a REXP instance');
