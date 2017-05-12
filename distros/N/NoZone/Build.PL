#!/usr/bin/perl
#
# Copyright (C) 2013  Daniel P. Berrange <dan@berrange.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use Module::Build;

my $build = Module::Build->new(
    module_name => 'NoZone',
    license => 'gpl',
    configure_requires => {
	'Module::Build' => 0.40
    },
    build_requires => {
	'File::Temp' => 0,
	'Test::More' => 0,
	'Test::Pod' => 0,
	'Test::Pod::Coverage' => 0,
    },
    requires    => {
	'perl' => '5.6.0',
	'Config::Record' => "1.1.2",
	'File::Spec::Functions' => 0,
    },
    dist_abstract => "A Bind DNS zone file generator",
    dist_author => "Daniel P. Berrange <dan@berrange.com>",
    dist_version_from => "lib/NoZone.pm",
    script_files => [
	"bin/nozone",
    ],
    etc_files => {
	"etc/nozone.cfg" => "etc/nozone.cfg",
    },
    install_path => { etc => "/etc" },
    );
$build->add_build_element('etc');
$build->create_build_script;
