#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 20;

BEGIN { use_ok( 'Statistics::Lite', ':all' ); }

# undef checking
#
is(min(undef), undef, "call min with only single undefined value" );
is(max(undef), undef, "call max with only single undefined value" );
is(min(), undef, "call min without values" );
is(max(), undef, "call max without values" );
is(min(6,undef,10), 6, "call min with undefined value" );
is(max(-6,-10,undef), -6, "call max with undefined value" );
is(min(undef, 7, -5), -5, "call min with initial undefined value" );
is(max(undef, 7, -5), 7, "call max with initial undefined value" );
is(min(undef,undef,undef), undef, "call min with only undefined values" );
is(max(undef,undef,undef), undef, "call max with only undefined values" );
is(count(undef, 7, -5), 2, "call count with undefined value" );
is(sum(undef, 7, -5), 2, "call sum with undefined value" );
is(mean(undef, 7, -5), 1, "call mean with undefined value" );
is(count(undef,undef,undef), 0, "call count with only undefined values" );
is(mean(undef,undef,undef), undef, "call mean with only undefined values" );
is(range(6,9,undef), 3, "call range with undefined value" );
is(range(undef,6,9), 3, "call range with leading undefined value" );
is(range(undef,undef,undef,7), 0, "call range with single defined value" );
is(range(undef,undef,undef), undef, "call range with only undefined values" );
