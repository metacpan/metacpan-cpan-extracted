#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

my @modules = map { 'Monitoring::Sneck::Checks::' . $_ } (
	'accounts',      'base',          'cciss',        'cert_dir',  'cert_file',      'checksums',
	'config_value',  'conntrack',     'containers',   'debsecan',  'disk',           'dns',
	'dns_sync',      'file_age',      'file_handles', 'file_mode', 'hosts',          'http',
	'http_json',     'https_cert',    'interface',    'jails',     'kernel_modules', 'listening',
	'load',          'log',           'memory',       'mount',     'neighbors',      'ntp',
	'oom',           'packages',      'pid_file',     'ping',      'pkg_audit',      'pressure',
	'procs',         'reboot_needed', 'resolv',       'sensors',   'service',        'smtp',
	'sshd_config',   'swap',          'swraid',       'sysctl',    'systemd_failed', 'tcp',
	'tls_protocols', 'uptime'
);
push( @modules, 'Monitoring::Sneck::Checks::rbl' ) if eval { require Net::IP; 1 };
foreach my $module ( 'Monitoring::Sneck::Checks', @modules ) {
	use_ok($module) || print "Bail out!\n";
}

diag("Testing Monitoring::Sneck::Checks $Monitoring::Sneck::Checks::VERSION, Perl $], $^X");

done_testing();
