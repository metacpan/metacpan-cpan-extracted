#!/usr/bin/perl
#

use Module::Build;
use strict;


# Create the Build script
my $build = Module::Build->new
(
	module_name => 'Net::RTP',
	license => 'perl',
	build_requires => {
		'Module::Build' => '0.20'
	},
	script_files => [
		'tools/rtpdump.pl',
		'tools/rtplosslog.pl',
		'tools/rtpsend-pcmu.pl',
		'tools/rtpstats.pl',
		'tools/rtptimer.pl',
	],
	requires => {
		'Test::More' => 0,
		'IO::Socket::INET' => '1.20',
	},
	
	create_makefile_pl => 'passthrough',
	
	
	# Optional modules
	recommends => {
		'IO::Socket::Multicast6' => '0.02',
		'IO::Socket::Multicast' => '1.00',
		'IO::Socket::INET6' => '2.51',
		'Socket6' => '0.19',
		'Test::Pod' => '1.00',
	},
);

$build->create_build_script;
