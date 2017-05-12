#!perl -T

use strict;
use warnings 'all';

use Test::More tests => 15;

use_ok('Nagios::Plugin::OverHTTP');

{
	# Clear the environment
	local @ARGV = '';

	my $plugin = Nagios::Plugin::OverHTTP->new(
		url => 'http://example.net/check_ok',
	);

	ok(defined $plugin, 'new succeeded');
	is($plugin->url, 'http://example.net/check_ok', 'url set with new');

	my $plugin_opts = Nagios::Plugin::OverHTTP->new_with_options(
		url => 'http://example.net/check_ok',
	);

	ok(defined $plugin_opts, 'new_with_options succeeded');
	is($plugin_opts->url, 'http://example.net/check_ok', 'url set with new_with_options');
}

{
	my $plugin = Nagios::Plugin::OverHTTP->new({
		url => 'http://example.net/check_ok',
	});

	ok(defined $plugin, 'new using hashref succeeded');
	is($plugin->url, 'http://example.net/check_ok', 'url set with new');
}

{
	my $plugin_opts = eval { Nagios::Plugin::OverHTTP->new_with_options({
		url => 'http://example.net/check_ok',
	}) };

	ok(defined $plugin_opts, 'new_with_options using hashref succeeded');
	is($plugin_opts->url, 'http://example.net/check_ok', 'url set with new_with_options');
}

########################
# new_with_options TESTS

SKIP: {
	local @ARGV = split /\s+/, '--hostname example.net --path /nagios/check_service --timeout=20 --ssl';

	my $plugin = Nagios::Plugin::OverHTTP->new_with_options;

	ok(defined $plugin, 'plugin initiated');
	is($plugin->hostname, 'example.net', 'With space');
	is($plugin->timeout, 20, 'With equals');
	is($plugin->ssl, 1, 'Set bool');
}

SKIP: {
	local @ARGV = split /\s+/, '--hostname=example.net --path /nagios/check_service --timeout=20 --no-ssl';

	my $plugin = Nagios::Plugin::OverHTTP->new_with_options;

	ok(defined $plugin, 'plugin initiated');
	isnt($plugin->ssl, 1, 'Unset bool');
}
