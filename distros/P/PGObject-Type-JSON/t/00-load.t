#!perl -T

use Test2::V0;
plan 1;

ok( eval "require PGObject::Type::JSON", $@) || bail_out('Did not load');

diag( "Testing PGObject::Type::JSON $PGObject::Type::JSON::VERSION, Perl $], $^X" );
