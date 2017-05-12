#!perl

use strict;
use warnings;
use Test::More tests => 1;
use Sub::Current;

ok( !defined ROUTINE, "Don't point to main CV" );
