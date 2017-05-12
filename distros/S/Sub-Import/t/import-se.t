#!perl
use strict;
use warnings;

use lib 't/lib';
use Test::More 'no_plan';

use Sub::Import SE => (foo => { -as => 'bar'});

is(bar(), 'FOO', "we imported something");

