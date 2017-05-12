#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;
use Test::Fatal;

use Statistics::R::REXP::Vector;

# not instantiable
like(exception {
         Statistics::R::REXP::Vector->new,
     }, qr /method required/,
     'creating a Vector instance');

ok( Statistics::R::REXP::Vector->is_vector, 'is vector' );
ok( ! Statistics::R::REXP::Vector->is_null, 'is not null' );
