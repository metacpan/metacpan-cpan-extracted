#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More;

ok 1, 'Should be reached';

plan skip_all => 'Testing skip all';

ok 0, 'Should not reach here';
