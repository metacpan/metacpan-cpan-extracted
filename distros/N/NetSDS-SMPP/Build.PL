#!/usr/bin/env perl

=head1 NAME

Build.PL - Build script generator for NetSDS SMPP applications

=head1 DESCRIPTION

B<NetSDS-SMPP> is an application  providing users with ability to send and receive
SMS messages and create simple SMS services.

=head1 SYNOPSIS

	perl Build.PL
	./Build
	./Build test
	./Build install

=cut

use strict;
use warnings 'all';

# force commit
our $VERSION = "1.204";

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'NetSDS::SMPP',
	dist_name          => 'NetSDS-SMPP',
	dist_version       => $VERSION,
	dist_abstract      => 'NetSDS VAS platform SMPP subsystem',
	create_makefile_pl => 'traditional',
	dist_author        => 'Net.Style Development Team <info@netstyle.com.ua>',
	create_readme      => 0,
	license            => 'gpl',
	build_requires     => {
		'Test::More'          => '0.62',
		'Test::Pod'           => '1.26',
		'Test::Pod::Coverage' => '1.08',
		'Module::Build'       => '0.2805',
	},
	requires => {
		'version'               => '0.50',
		'perl'                  => '5.008',
		'NetSDS'                => '1.000',
		'NetSDS::Util::Convert' => '1.000',
		'NetSDS::Queue'         => '0.030',
		'Net::SMPP'             => '1.10',
	},
	script_files => [
		'scripts/smppqproc',
		'scripts/smppserver',
	],
);

$build->create_build_script;

__END__

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008 Michael Bochkaryov

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
