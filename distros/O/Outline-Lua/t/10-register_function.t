#!perl -T

use strict;

use lib 't/lib';
use t::Outline::Lua::register_func;

Test::Class->runtests();

