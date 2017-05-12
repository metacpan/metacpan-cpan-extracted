package Collectd::Plugins::OK::ReadUnknownType;

use strict;
use warnings;

use Collectd qw( :all );

my $plugin_name = __PACKAGE__;
$plugin_name =~ s/^Collectd::Plugins:://;

plugin_register(TYPE_READ, $plugin_name, 'my_read');

sub my_read {
	plugin_dispatch_values({
		plugin => $plugin_name,
		type => "this type does not exist",
		values => [ 42 ],
	});
	1;
}

1;

