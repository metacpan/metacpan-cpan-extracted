#!perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name => 'Module::Build::TestReporter',
	license     => 'perl',
	requires    =>
	{
		'Module::Build' =>     '',
		'Test::Harness' => '2.47',
		'SUPER'         => '1.10',
		'Class::Roles'  =>     '',
		'IPC::Open3'    =>     '',
	},
	build_requires =>
	{
		'IO::String'      =>     '',
		'Test::Exception' =>     '',
		'Test::Simple'    => '0.48',
	},
	dist_version_from  => 'lib/Module/Build/TestReporter.pm',
	report_file        => 'test_output.txt',
	create_makefile_pl => 'traditional',
	sign               => 1,
);

$build->create_build_script();
