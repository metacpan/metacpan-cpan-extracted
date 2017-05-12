package Collectd::Plugins::OK::ReadTwice;

use strict;
use warnings;

use Collectd qw( :all );

my $plugin_name = __PACKAGE__;
$plugin_name =~ s/^Collectd::Plugins:://;

plugin_register(TYPE_CONFIG, $plugin_name, 'my_config');
plugin_register(TYPE_READ, $plugin_name, 'my_read');
plugin_register(TYPE_INIT, $plugin_name, 'my_init');

sub my_init {
	1;
}

sub my_read {
	plugin_dispatch_values({
		interval => $interval_g,
		host => "localhost.localdomain",
		plugin => $plugin_name,
		type => "gauge",
		type_instance => "ti",
		plugin_instance => "pi",
		values => [ 42 ],
	});
	sleep 2;
	plugin_dispatch_values({
		interval => $interval_g,
		host => "localhost.localdomain",
		plugin => $plugin_name,
		type => "gauge",
		type_instance => "ti2",
		plugin_instance => "pi2",
		values => [ 0 ],
	});
	1;
}

sub my_config {
	1;
}

1;

