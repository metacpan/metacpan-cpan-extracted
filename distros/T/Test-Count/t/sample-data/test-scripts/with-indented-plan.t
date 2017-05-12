#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

if (exists($ENV{TEST_ME}))
{
    plan tests => 1;
}
else
{
    plan skip_all => 'Skipping';
}

# TEST
ok (1, 'One test');

# TEST
ok (1, 'Second test');
