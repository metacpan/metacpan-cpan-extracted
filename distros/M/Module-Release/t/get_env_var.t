#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 1.0 tests => 10;
use Capture::Tiny qw( capture );

use Module::Release;

BEGIN {
	use File::Spec::Functions qw(rel2abs catfile);
	my $file = rel2abs( catfile( qw( t lib setup_common.pl) ) );
	require $file;
	}

my $release = Module::Release->new;
$release->{'preset_field'} = 'preset';
is( $release->get_env_var('PRESET_FIELD'),
	'preset', 'Preset field value returned' );

$ENV{'MOO'} = 'baa';
is( $release->get_env_var('MOO'),
	'baa', 'Preset environment variable value returned' );

no warnings 'redefine';

{
local *Module::Release::_slurp = sub { "baa\n" };
local $ENV{'MOO'} = '';
my ( $stdout, $stderr, @result ) = capture { $release->get_env_var('MOO') };
is(
	$stdout,
	'MOO is not set.  Enter it now: ',
	'Empty environment variable prompts for value'
	);
is( $result[0], 'baa', 'Variable read from input' );
}

{
local *Module::Release::_slurp = sub { "\n" };
local $ENV{'MOO'} = undef;
$release->turn_debug_on;
my( $stdout, $stderr, @result ) = capture { $release->get_env_var('MOO') };
is(
	$stdout,
	'MOO is not set.  Enter it now: ',
	'Undef environment variable prompts for value'
	);
is(
	$stderr,
	"MOO not supplied.  Aborting...\n",
	"Error message about missing variable shown in debug mode"
	);
}

{
local *Module::Release::_slurp = sub { "s3cr3t\n" };
local $ENV{'CPAN_PASS'} = undef;
my( $stdout, $stderr, @result ) = capture { $release->get_env_var('CPAN_PASS') };
is(
	$stdout,
	'CPAN_PASS is not set.  Enter it now: ',
	'Undef CPAN_PASS variable prompts for value'
);
is( $result[0], 's3cr3t', 'Variable password from input' );
}
