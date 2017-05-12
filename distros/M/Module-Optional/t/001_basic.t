# -*- perl -*-

# t/001_basic.t - Basic defaulting for non-OO module

use Test::More tests => 3;
use strict;

BEGIN { use_ok( 'Module::Optional', 'FooGlurch' ); }

#02
can_ok('FooGlurch', 'blink');

#03
is(FooGlurch::blink(),'moo', "Correct sub being called");

package FooGlurch::Dummy;

sub blink {
	return "moo";
}

