package Collectd::Plugins::OK::ReadHostNotScalar;

use strict;
use warnings;

use Collectd qw( :all );

my $plugin_name = __PACKAGE__;
$plugin_name =~ s/^Collectd::Plugins:://;

plugin_register(TYPE_READ, $plugin_name, 'my_read');

sub my_read {
	plugin_dispatch_values({
		host => { name => "this ain't no scalar" },
		plugin => $plugin_name,
		type => "gauge",
		values => [ 42 ],
	});
	1;
}

1;

