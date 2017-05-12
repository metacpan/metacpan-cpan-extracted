#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 5;

# use all of the necessary modules
require base;
use File::Spec::Functions;
use Module::Build;

my $module;
{
	local @INC = '../lib';
	$module = 'Module::Build::TestReporter';
	use_ok( $module ) or exit;
}

my %args =
(
	dist_name    => 'MBTR-Test',
	dist_version => '1.97',
);

my $mb  = $module->new( %args );

isa_ok( $mb, 'Module::Build' );
ok( ! $mb->isa( 'Module::Build::TestReporter' ),
	'object should be a plain M::B instance unless prereqs load' );

my $requirements = 
{
	'Test::Harness' => '2.47',
	'SUPER'         => '1.10',
	'Class::Roles'  =>     '',
	'IPC::Open3'    =>     '',
};

is_deeply( $mb->build_requires(), $requirements,
	'... and should add necessary modules to build_requires' );

my %new_reqs =
(
	'strict' => '',
	'SUPER'  => '1.01',
);

$mb = $module->new(%args, build_requires => \%new_reqs );
@{ $requirements }{ keys %new_reqs } = values %new_reqs;
is_deeply( $mb->build_requires(), $requirements,
	'... not disturbing existing requirements' );
