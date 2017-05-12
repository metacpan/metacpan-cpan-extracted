#file:t/response/Test/ConfigApache.pm
#-----------------------------------
package TestSlauth::10::SlauthEnabled;

use strict;
use warnings FATAL => 'all';

use constant BUFSIZ => 512; #small for testing
use Apache2::Const -compile => 'OK';
use Apache2::RequestRec;
use Apache2::RequestIO;
use Slauth::Config::Apache;

#
# This is just a plain-vanilla test out of the docs to check that
# we can get results from the Apache server set up for testing.
#
sub handler {
	my $r = shift;
	$r->content_type('text/plain');

	$r->write("1..1\n");
	if ( Slauth::Config::Apache::isEnabled( $r )) {
		$r->write("ok 1\n");
	} else {
		$r->write("not ok 1\n");
	}

	Apache2::Const::OK;
}
1;
