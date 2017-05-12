
package RayAppStyleParams;

use RayApp::Request ();
use strict;
use utf8;

sub handler {
	my ($dsd, $q) = @_;
	return unless defined $q;
	return (
		style_data => 'Káťa',
		my_relative_url => $q->url( -relative => 1 ),
		my_base_url => $q->url( base => 1 ),
		my_url => $q->url,
		my_url_query => $q->url( query => 1 ),
		my_relative_url_query => $q->url( relative => 1, query => 1 ),
		my_absolute_url => $q->url( absolute => 1 ),
		style_env_data => $ENV{ RAYAPP_ENV_STYLE_DATA },
	);
}

1;

