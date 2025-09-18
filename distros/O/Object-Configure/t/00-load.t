#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Object::Configure') || print 'Bail out!';
}

require_ok('Object::Configure') || print 'Bail out!';

diag("Testing Object::Configure $Object::Configure::VERSION, Perl $], $^X");
