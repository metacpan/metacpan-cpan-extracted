#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;

BEGIN {
	use_ok( 'Test::CPAN::Meta::JSON' );
	use_ok( 'Test::CPAN::Meta::JSON::Version' );
}
