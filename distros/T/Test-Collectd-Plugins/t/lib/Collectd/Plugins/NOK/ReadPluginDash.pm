package Collectd::Plugins::OK::ReadPluginDash;

use strict;
use warnings;

use Collectd qw( :all );

my $plugin_name = "Read-Plugin";

plugin_register(TYPE_READ, $plugin_name, 'my_read');

sub my_read {
	plugin_dispatch_values({
		plugin => $plugin_name,
		type => "gauge",
		values => [ 42 ],
	});
	1;
}

1;

