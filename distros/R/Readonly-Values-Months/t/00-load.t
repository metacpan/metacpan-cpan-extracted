#!perl -w

use warnings;
use strict;

use Test::Most tests => 3;
use Test::NoWarnings;

BEGIN {
	use_ok('Readonly::Values::Months') || print 'Bail out!';
}

require_ok('Readonly::Values::Months') || print 'Bail out!';

diag("Testing Readonly::Values::Months $Readonly::Values::Months::VERSION, Perl $], $^X");
