#!perl -T

use strict;
use warnings 'all';

use Test::Class::Load 't/tests';

# Run the tests using Test::Class
Test::Class->runtests;
