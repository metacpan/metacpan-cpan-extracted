#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;

BEGIN {
	use_ok( 'Test::CPAN::Meta' );
	use_ok( 'Test::CPAN::Meta::Version' );
}
