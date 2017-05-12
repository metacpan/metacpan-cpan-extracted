#!perl

use strict;
use warnings;
use 5.012;
use Carp;
use autodie;
use utf8;

use lib 't/lib';
use TheClass;

use Test::More;
can_ok( 'TheClass', 'foo' );    # succeeds
can_ok( 'TheClass', 'bar' );    # fails

done_testing;
