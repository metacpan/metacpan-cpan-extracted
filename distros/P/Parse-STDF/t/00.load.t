#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use blib;

use Test::More tests => 2;
note( "Testing Parse::STDF $Parse::STDF::VERSION" );

BEGIN {
use_ok( 'Parse::STDF' );
}

ok(defined($Parse::STDF::VERSION), "\$Parse::STDF::VERSION number is set");
