
package RayApp::UserAgent;

use strict;
use warnings;

use RayApp ();
use LWP::UserAgent ();
use base qw( LWP::UserAgent );
use vars qw( $VERSION );

*VERSION = \$RayApp::VERSION;

sub new {
	my $class = shift;
	my %options = @_;

	return bless {
		agent => __PACKAGE__ . " $VERSION",
		use_eval => 1,
		%options,
	}, $class;
}
sub redirect_ok {
	my ($prospective_request, $response) = @_;
	if ($response->header('X-RayApp-Status')) {
		# this header will be set by RayApp backend, and
		# prospective redirect has to be sent to client
		return;
	}
	return 1;
}

1;

