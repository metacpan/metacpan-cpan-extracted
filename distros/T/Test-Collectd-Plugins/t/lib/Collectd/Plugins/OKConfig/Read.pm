package Collectd::Plugins::OKConfig::Read;

use strict;
use warnings;

=head1 NAME Collectd::Plugins::OKConfig::Read

=head1 SYNOPSIS

This Read Plugin reads values from its configuration  file and dispatches them back to collectd. If no configuration is provided, it dispatches [ 42 ] as values. As its dumb function suggests, it's been written for testing purposes.

=cut

use Collectd qw( :all );

my $plugin_name = __PACKAGE__;
$plugin_name =~ s/^Collectd::Plugins:://;
my @config_values;

plugin_register(TYPE_CONFIG, $plugin_name, 'my_config');
plugin_register(TYPE_READ, $plugin_name, 'my_read');

sub my_read {
	my @values = scalar @config_values ? @config_values : ( 42, 42, 42);
	plugin_dispatch_values({
		interval => $interval_g,
		host => "localhost.localdomain",
		plugin => $plugin_name,
		type => "load",
		type_instance => "ti",
		plugin_instance => "pi",
		values => \@values,
	});
	1;
}

sub my_config {
	@config_values = ();
	for my $child (@{$_[0] -> {children}}) {
		my $key = $child -> {key};
		push @config_values, @{$child -> {values}};
	}
	1;
}

1;

