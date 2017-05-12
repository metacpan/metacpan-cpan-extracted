
package RayApp::CGIWrapper;
use strict;
use RayApp::CGI;

BEGIN {
	if (defined $ENV{'PERL5OPT'}) {
		my $package = __PACKAGE__;
		if ($ENV{'PERL5OPT'} eq "-M$package") {
			delete $ENV{'PERL5OPT'};
		}
	}
	RayApp::CGI::handler();	
}

1;

