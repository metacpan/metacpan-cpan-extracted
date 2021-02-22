#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 1.0;
use Capture::Tiny qw( capture );

require 't/lib/setup_common.pl';

my $class = 'Module::Release';
subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

my $release = Module::Release->new;
$release->{'preset_field'} = 'preset';
is( $release->get_env_var('PRESET_FIELD'),
	'preset', 'Preset field value returned' );

$ENV{'MOO'} = 'baa';
is( $release->get_env_var('MOO'),
	'baa', 'Preset environment variable value returned' );

no warnings 'redefine';

subtest empty => sub {
	local *Module::Release::_slurp = sub { "baa\n" };
	local $ENV{'MOO'} = '';
	my ( $stdout, $stderr, @result ) = capture { $release->get_env_var('MOO') };
	is(
		$stdout,
		'MOO is not set.  Enter it now: ',
		'Empty environment variable prompts for value'
		);
	is( $result[0], 'baa', 'Variable read from input' );
	};

subtest undefined => sub {
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
	};

SKIP: {
	skip "Windows GitHub runner doesn't have a console", 2
		if $ENV{CI} and ($ENV{GITHUB_WORKFLOW}//'') eq 'windows';
	subtest cpan_pass => sub {
		local *Module::Release::_slurp = sub { "s3cr3t\n" };
		local $ENV{'CPAN_PASS'} = undef;

		my( $stdout, $stderr, @result ) = capture { $release->get_env_var('CPAN_PASS') };

		is(
			$stdout,
			'CPAN_PASS is not set.  Enter it now: ',
			'Undef CPAN_PASS variable prompts for value'
		);
		is( $result[0], 's3cr3t', 'Variable password from input' );
		};
	}

done_testing();
