#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Params::Validate::Strict') || print 'Bail out!';
}

require_ok('Params::Validate::Strict') || print 'Bail out!';

diag("Testing Params::Validate::Strict $Params::Validate::Strict::VERSION, Perl $], $^X");
