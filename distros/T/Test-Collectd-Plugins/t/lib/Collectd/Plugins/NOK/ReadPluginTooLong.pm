package Collectd::Plugins::OK::ReadPluginTooLong;

use strict;
use warnings;

use Collectd qw( :all );

my $plugin_name = __PACKAGE__;
$plugin_name = "a"x64;

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

