#!/usr/bin/perl
use strict;
use warnings;

use Test::More 1;

use Config;
use File::Spec;

my $class = 'Module::Release';

subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

BEGIN {
	use File::Spec::Functions qw(rel2abs catfile);
	my $file = rel2abs( catfile( qw( t lib setup_common.pl) ) );
	require $file;
	}


my %required_env;
my $debug_env_var = 'RELEASE_DEBUG';

if ( $^O eq 'android' ) {
    my $ldlibpth             = $Config{ldlibpthname};
    $required_env{$ldlibpth} = $ENV{$ldlibpth};
    $required_env{PATH}      = $ENV{PATH};
}

subtest no_params_clean => sub {
	local %ENV = %required_env; # don't react to overall setup
	my $method = 'debug';

	my $release = $class->new;
	isa_ok( $release, $class );

	can_ok( $release, $method );
	ok( ! $release->$method(), "debug starts off" );
	};

subtest no_params_debug => sub {
	local %ENV = %required_env; # don't react to overall setup

	$ENV{$debug_env_var} = 1;
	my $method = 'debug';

	my $release = $class->new;
	isa_ok( $release, $class );

	can_ok( $release, $method );
	is( $release->$method(), $ENV{$debug_env_var},
		"$method matches $debug_env_var ($ENV{$debug_env_var})" );
	};

subtest no_params_no_debug => sub {
	local %ENV = %required_env; # don't react to overall setup

	$ENV{$debug_env_var} = 0;
	my $method = 'debug';

	my $release = $class->new;
	isa_ok( $release, $class );

	can_ok( $release, $method );
	is( $release->$method(), $ENV{$debug_env_var},
		"$method matches $debug_env_var ($ENV{$debug_env_var})" );
	};

done_testing();
