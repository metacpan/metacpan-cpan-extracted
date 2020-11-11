#!/usr/bin/env perl

use Test::Most tests => 3;
use Modern::Perl;
use Object::Util magic => 0;

use Orbital::Transfer::EnvironmentVariables;
use Config;

my $sep = $Config{path_sep};

subtest "Paths: prepend" => sub {
	my $env = Orbital::Transfer::EnvironmentVariables->new
		->new;

	ok ! exists $env->environment_hash->{TEST_PATH};

	$env->prepend_path_list( 'TEST_PATH', [ 'a' ]  );
	is $env->environment_hash->{TEST_PATH}, 'a';

	$env->prepend_path_list( 'TEST_PATH', [ 'b' ]  );
	is $env->environment_hash->{TEST_PATH}, "b${sep}a";

	$env->prepend_path_list( 'TEST_PATH', [ 'c', 'd' ]  );
	is $env->environment_hash->{TEST_PATH}, "c${sep}d${sep}b${sep}a";

};

subtest "Paths: append" => sub {
	my $env = Orbital::Transfer::EnvironmentVariables->new
		->new;

	ok ! exists $env->environment_hash->{TEST_PATH};

	$env->append_path_list( 'TEST_PATH', [ 'a' ]  );
	is $env->environment_hash->{TEST_PATH}, 'a';

	$env->append_path_list( 'TEST_PATH', [ 'b' ]  );
	is $env->environment_hash->{TEST_PATH}, "a${sep}b";

	$env->append_path_list( 'TEST_PATH', [ 'c', 'd' ]  );
	is $env->environment_hash->{TEST_PATH}, "a${sep}b${sep}c${sep}d";

};

subtest "Add environments" => sub {
	my $env = Orbital::Transfer::EnvironmentVariables->new
		->new;

	ok ! exists $env->environment_hash->{TEST_ENV_VAR};

	$env->set_string( 'TEST_ENV_VAR', 'test'  );
	is $env->environment_hash->{TEST_ENV_VAR}, 'test';

	my $add_env = Orbital::Transfer::EnvironmentVariables->new
		->new;


	$env->add_environment( $add_env );
	ok ! exists $env->environment_hash->{TEST_ADD_VAR};

	$add_env->set_string( 'TEST_ADD_VAR', 'add' );
	is $env->environment_hash->{TEST_ADD_VAR}, 'add';
};

done_testing;
