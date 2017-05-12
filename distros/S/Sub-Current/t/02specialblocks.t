#!perl

use strict;
use warnings;
use Test::More tests => 4;

use Sub::Current;

BEGIN { ok( !defined ROUTINE, "Don't point to BEGIN" ); }
CHECK { ok( !defined ROUTINE, "Don't point to CHECK" ); }
INIT  { ok( !defined ROUTINE, "Don't point to INIT" ); }
END   { ok( !defined ROUTINE, "Don't point to END" ); }
