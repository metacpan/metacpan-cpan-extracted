#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Syntax::Feature::With') || print 'Bail out!';
}

require_ok('Syntax::Feature::With') || print 'Bail out!';

diag("Testing Syntax::Feature::With $Syntax::Feature::With::VERSION, Perl $], $^X");
