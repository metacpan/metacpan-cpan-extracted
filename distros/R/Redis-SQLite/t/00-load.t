#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 3;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

ok( $Redis::SQLite::VERSION, "Version defined" );
ok( $Redis::SQLite::VERSION =~ /^([0-9\.]+)/,
    "Version is numeric" );
