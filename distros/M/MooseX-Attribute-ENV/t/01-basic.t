
use warnings;
use strict;
use Test::More tests => 9;

ENV_ATTRIBUTES: {

	local %ENV;

	$ENV{test1} = '111';
	$ENV{test2} = '222';	
	$ENV{'444_test4'} = '444';
	$ENV{"MooseX_Attribute_ENV_Test_Class_test5"} = 'packagetest';	
	
	{
		package MooseX::Attribute::ENV::Test::Class;
		
		use Moose;
		use MooseX::Attribute::ENV;
		
		has 'test1' => (
			traits=>[qw/ENV/],	
			is=>'ro',
		);

		has 'test1a' => (
			traits=>[qw/ENV/],
			env_key=>'test2',
			is=>'ro',
		);

		has 'test3' => (
			traits=>[qw/ENV/],	
			is=>'ro',
			default=>'333',
		);
		
		has 'test3a' => (
			traits=>[qw/ENV/],
			env_key=>'test4',
			is=>'ro',
			default=>'444',
		);
		
		has 'test4' => (
			traits=>[qw/ENV/],
			env_prefix=>'444',
			is=>'ro',
		);

		has 'test5' => (
			traits=>[qw/ENV/],
			env_package_prefix=>1,
			is=>'ro',
		);
		
		has 'test6' => (
			traits=>[qw/ENV/],
			env_package_prefix=>1,
			is=>'ro',
			default=>sub{
			return blessed shift;
			}
		);
	}

	ok( my $env = 'MooseX::Attribute::ENV::Test::Class'->new(), "Got a good object");
	isa_ok( $env, 'MooseX::Attribute::ENV::Test::Class' );

	is $env->test1, 111, "correct value";
	is $env->test1a, 222, "correct value";
	is $env->test3, 333, "correct value";
	is $env->test3a, 444, "correct value";
	is $env->test4, '444', "correct value";	
	is $env->test5, 'packagetest', "correct value";	
	is $env->test6, 'MooseX::Attribute::ENV::Test::Class', "correct value";	
}



