use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 3;

use BaseClass;
use SubClass;

BaseClass->affe;
is(BaseClass::no_calls_to_affe(), 1);

SubClass->affe;
is(BaseClass::no_calls_to_affe(), 2);
is(SubClass::no_calls_to_affe(), 1);

