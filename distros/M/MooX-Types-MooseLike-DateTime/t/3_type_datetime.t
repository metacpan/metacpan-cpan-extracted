#!perl -T

use warnings;
use strict;

use Test::More tests => 2;
use Test::Exception;

{
	package Foo;

	use Moo;
	use MooX::Types::MooseLike::DateTime qw/DateTime/;
	use aliased 'DateTime' => 'DT';

	has foo => (
		is => 'rw',
		isa => DateTime,
		default => sub { DT->today }
	);
}

use DateTime;

lives_ok
	{ Foo->new(foo => DateTime->now) }
	'accepted DateTime->now';

throws_ok
	{ Foo->new(foo => 'bar') }
	qr/a DateTime object/,
	'does not accept strings';

