package Collectd::Plugins::OK::ReadTypeInstanceSlash;

use strict;
use warnings;

use Collectd qw( :all );

my $plugin_name = __PACKAGE__;
$plugin_name =~ s/^Collectd::Plugins:://;

plugin_register(TYPE_READ, $plugin_name, 'my_read');

sub my_read {
	plugin_dispatch_values({
		host => "this may not contain / slashes",
		plugin => $plugin_name,
		type => "gauge",
		values => [ 42 ],
		type_instance => "this/ain't no valid type instance",
	});
	1;
}

1;

