use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Module::Runtime 'use_module';

{
	package Credit;
	use Moose;
	use MooseX::Types::CreditCard qw( CardExpiration );

	has expiration => (
		isa    => CardExpiration,
		is     => 'rw',
		coerce => 1,
	);

	__PACKAGE__->meta->make_immutable;
}

my $now = use_module('DateTime')->now;
my $exp = DateTime->last_day_of_month( month => 10, year => 2013);

my $c1 = new_ok( Credit => [{ expiration => $exp }]);
#{ month => 10, year => 2013 }

my $e0 = exception { $c1->expiration( $now ) };

ok $e0, 'invalid expiration exception';
like $e0, qr/DateTime object is not the last day of month/,
	'invalid expiration message';

done_testing;
