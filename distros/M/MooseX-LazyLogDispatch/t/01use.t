#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('MooseX::LazyLogDispatch');
    use_ok('MooseX::LazyLogDispatch::Levels');
}
