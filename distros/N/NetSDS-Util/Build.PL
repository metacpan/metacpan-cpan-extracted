#!/usr/bin/env perl

=head1 NAME

Build.PL - Build script generator for NetSDS common

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
	module_name        => 'NetSDS::Util',
	dist_abstract      => 'Utility Perl5 modules for NetSDS VAS development framework',
	create_makefile_pl => 'traditional',
	dist_author        => 'Net.Style Development Team <info@netstyle.com.ua>',
	create_readme      => '0',
	license            => 'gpl',
	build_requires     => {
		'Test::More'          => '0',
		'Test::Pod'           => '1.20',
		'Test::Pod::Coverage' => '1.08',
		'Module::Build'       => '0',
	},
	requires => {
		'perl'              => '5.008',
		'version'           => '0',
		'Data::UUID'        => '1.000',
		'Date::Format'      => '0',
		'Date::Parse'       => '0',
		'Encode'            => '2.000',
		'File::Copy'        => '0',
		'File::MMagic'      => '1.000',
		'File::Path'        => '0',
		'File::Spec'        => '0',
		'File::Temp'        => '0',
		'Getopt::Long'      => '0',
		'HTTP::Date'        => '0',
		'IO::File'          => '0',
		'MIME::Base64'      => '0',
		'Pod::Usage'        => '0',
		'POSIX'             => '0',
		'Scalar::Util'      => '0',
		'Spreadsheet::Read' => '0.30',
		'Time::HiRes'       => '0',
		'Time::Local'       => '0',
		'URI'               => '1.00',
		'URI::Escape'       => '1.00',
	},
	recommends   => {},
	script_files => {},
);

$build->create_build_script;

__END__

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut
