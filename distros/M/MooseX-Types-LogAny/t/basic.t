use strict;
use warnings;
use Test::More;
use Module::Runtime 'use_module';
use Test::Fatal;

{
	package MyTest;
	use Moose;
	use MooseX::Types::LogAny qw( LogAny );

	has log => (
		isa => LogAny,
		is  => 'rw',
	);
}

my $t = new_ok( 'MyTest' );

use_module('Log::Any::Adapter')->set('Null');

my $e0 = exception { $t->log( use_module('Log::Any')->get_logger ) };

ok ! $e0, 'using null logger does not throw an exception' or diag $e0;

use_module('Log::Any::Adapter')->set('Stderr');

my $e1 = exception { $t->log( use_module('Log::Any')->get_logger ) };

ok ! $e1, 'using sterr logger does not throw an exception' or diag $e1;

done_testing;
