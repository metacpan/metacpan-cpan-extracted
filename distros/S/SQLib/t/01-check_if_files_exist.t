#!perl -T
use 5.006;
use strict;
use Test::More 'no_plan';
use Test::More;

use SQLib;

use_ok( 'SQLib' ) or die;
ok( -e 't/example-good.sql' ) or warn "Cannot find example-good.sql for tests";
ok( -e 't/example-bad.sql' ) or warn "Cannot find example-bad.sql for tests";
