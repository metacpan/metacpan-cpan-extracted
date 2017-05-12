#!/usr/bin/env perl

=head1 NAME

Build.PL - Build script generator for NetSDS core libraries

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
	module_name        => 'NetSDS',
	dist_name          => 'NetSDS',
	dist_abstract      => 'Core Perl5 modules for NetSDS VAS development framework',
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
		'version'                => '0.700',
		'CGI'                    => '3.29',
		'CGI::Cookie'            => '0',
		'CGI::Fast'              => '0',
		'DBI'                    => '1.600',
		'DBD::Pg'                => '0',
		'FCGI'                   => '0.67',
		'JSON'                   => '2.0',
		'JSON::XS'               => '2.0',
		'Class::Accessor'        => '0',
		'Class::Accessor::Class' => '0',
		'Config::General'        => '0',
		'Data::Structure::Util'  => '0',
		'Getopt::Long'           => '0',
		'HTML::Template::Pro'    => '0.81',
		'Locale::gettext'        => '1.00',
		'POSIX'                  => '0',
		'Proc::Daemon'           => '0.03',
		'Proc::PID::File'        => '0',
		'Storable'               => '2.15',
		'Unix::Syslog'           => '1.0',
	},
	recommends   => {},
	script_files => {},
);

$build->create_build_script;

__END__

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut
