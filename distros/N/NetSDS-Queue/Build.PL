#!/usr/bin/env perl

=head1 NAME

Build.PL - Build script generator for NetSDS::Queue

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

=cut

use strict;
use warnings 'all';

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'NetSDS::Queue',
	dist_name          => 'NetSDS-Queue',
	dist_abstract      => 'Perl5 modules for NetSDS messaging queue',
	create_makefile_pl => 'traditional',
	dist_author        => 'Net.Style Development Team <info@netstyle.com.ua>',
	create_readme      => 1,
	license            => 'gpl',
	build_requires     => {
		'Test::More'          => '0',
		'Test::Pod'           => '0',
		'Test::Pod::Coverage' => '0',
		'Module::Build'       => '0',
	},
	requires => {
		'perl'                   => '5.008',
		'version'                => '0.5',
		'Cache::Memcached::Fast' => '0.10',
		'JSON'                   => '2.0',
		'JSON::XS'               => '2.0',
		'NetSDS'                 => '1.000',
		'NetSDS:App'             => '1.000',
		'NetSDS::Util'           => '1.000',
	},
	recommends   => {},
	script_files => {},
);

$build->create_build_script;

__END__

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut
