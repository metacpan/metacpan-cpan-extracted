#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Sub::Private') || print 'Bail out!';
}

require_ok('Sub::Private') || print 'Bail out!';

diag("Testing Sub::Private $Sub::Private::VERSION, Perl $], $^X");
