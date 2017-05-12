
use strict;
use warnings;
use RayApp;

sub handler {
	return {
		id => 13,
		data => $ENV{RAYAPP_ENV_DATA},
		version => $RayApp::VERSION,
	};
}

1;

