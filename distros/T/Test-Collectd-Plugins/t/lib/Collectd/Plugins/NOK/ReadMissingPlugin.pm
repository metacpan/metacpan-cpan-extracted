package Collectd::Plugins::OK::ReadMissingPlugin;

use strict;
use warnings;

use Collectd qw( :all );

my $plugin_name = __PACKAGE__;
$plugin_name =~ s/^Collectd::Plugins:://;

plugin_register(TYPE_READ, $plugin_name, 'my_read');

sub my_read {
	plugin_dispatch_values({
		type => "gauge",
		values => [ 42 ],
	});
	1;
}

1;

