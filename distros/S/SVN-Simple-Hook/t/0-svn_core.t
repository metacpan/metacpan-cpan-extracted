#!perl

use Test::More tests => 1;
BEGIN { use_ok('SVN::Core') or BAIL_OUT(q{SVN::Core doesn't work}) }
