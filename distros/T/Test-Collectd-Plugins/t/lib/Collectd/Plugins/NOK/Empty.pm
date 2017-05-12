package Collectd::Plugins::OK::Empty;

use strict;
use warnings;

use Collectd qw( :all );

my $plugin_name = __PACKAGE__;
$plugin_name =~ s/^Collectd::Plugins:://;

plugin_register(TYPE_READ, $plugin_name, 'empty_read');

sub empty_read {
	plugin_dispatch_values();
	1;
}

1;

