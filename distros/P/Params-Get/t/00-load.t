#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Params::Get') || print 'Bail out!';
}

require_ok('Params::Get') || print 'Bail out!';

diag("Testing Params::Get $Params::Get::VERSION, Perl $], $^X");
