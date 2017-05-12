
package RayAppTestInput;

use RayApp::Request ();
use strict;

sub handler {
	my $dsd = shift;
	my $r = shift;
	my $q = new RayApp::Request($r);
	$dsd->validate_parameters($q) or die $dsd->errstr;
	return $q;
}

1;

