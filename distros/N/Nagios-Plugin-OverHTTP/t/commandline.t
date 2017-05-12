#!perl

use strict;
use warnings 'all';

use Test::More tests => 15;
use Test::Trap;

use Nagios::Plugin::OverHTTP;

SKIP: {
	local @ARGV = '--help';

	my $skip = 0;
	# Create new plugin with no arguments which means it will read from
	# command line
	trap { Nagios::Plugin::OverHTTP->new_with_options; };

	if ($trap->leaveby ne 'exit' || $trap->exit != 0) {
		ok(0, 'Usage exited with code 0');
		$trap->diag_all;
		skip 'Usage failed out', 9;
	} else {
		ok(1, 'Usage exited with code 0');
	}

	my $output = $trap->stdout;

	like($output, qr/^usage:/ms, 'Help should show usage');

	like($output, qr/\s+--default_status\s+/msx, 'default_status should be in usage');
	like($output, qr/\s+--hostname\s+/msx, 'hostname should be in usage');
	like($output, qr/\s+--path\s+/msx, 'path should be in usage');
	like($output, qr/\s+--ssl\s+/msx, 'ssl should be in usage');
	like($output, qr/\s+--timeout\s+/msx, 'timeout should be in usage');
	like($output, qr/\s+--url\s+/msx, 'url should be in usage');

	unlike($output, qr/\s+--message\s+/msx, 'message should not be in usage');
	unlike($output, qr/\s+--useragent\s+/msx, 'useragent should not be in usage');
}

SKIP: {
	my $url = 'http://example.net/nagios/check_service';
	local @ARGV = "--url=$url";

	# Create new plugin with no arguments which means it will read from
	# command line
	my $plugin = Nagios::Plugin::OverHTTP->new_with_options;

	skip 'Failure creating plugin.', 2 if !defined $plugin;

	is($plugin->url, $url, 'Minimal arguments');

	$plugin = Nagios::Plugin::OverHTTP->new_with_options(url => 'http://example.net/nagios/something');

	is($plugin->url, $url, 'Command line arguments override perl arguments');
}

SKIP: {
	my $url = 'http://example.net/nagios/check_service';
	local @ARGV = split /\s+/, '--hostname=example.net --path=/nagios/check_service';

	# Create new plugin with no arguments which means it will read from
	# command line
	my $plugin = Nagios::Plugin::OverHTTP->new_with_options;

	skip 'Failure creating plugin.', 1 if !defined $plugin;

	is($plugin->url, $url, 'Hostname + relative URL');
}

SKIP: {
	my $url = 'http://example.net/nagios/check_service';
	local @ARGV = split /\s+/, "--url=$url --critical time=4 --critical other=3.5"
		." --warning time=10:3 --warning other=4:";

	# Create new plugin with no arguments which means it will read from
	# command line
	my $plugin = Nagios::Plugin::OverHTTP->new_with_options;

	skip 'Failure creating plugin.', 2 if !defined $plugin;

	is_deeply($plugin->critical, {time => 4, other => 3.5}, 'Critical set');
	is_deeply($plugin->warning, {time => '10:3', other => '4:'}, 'Warning set');
}
