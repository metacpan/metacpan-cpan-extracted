package Collectd::Plugins::OK::ReadMissingType;

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
		plugin => $plugin_name,
		values => [ 42 ],
	});
	1;
}

sub my_config {
	1;
}

1;

