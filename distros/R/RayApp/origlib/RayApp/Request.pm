
package RayApp::Request;
use strict;

sub new {
	my ($class, $r) = @_;
	if (defined $r) {
		use RayApp::Request::APR;
		return new RayApp::Request::APR($r);
	} else {
		use RayApp::Request::CGI;
		return new RayApp::Request::CGI;
	}
}

1;

