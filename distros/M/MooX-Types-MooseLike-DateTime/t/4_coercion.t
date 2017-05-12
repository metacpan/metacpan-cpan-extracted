#!perl -T

use warnings;
use strict;

use Test::More tests => 1;
use Test::Exception;

{
	package Foo;

	use Moo;
	use MooX::Types::MooseLike::DateTime qw/DateTime/;
	use DateTime;
	use DateTime::Format::Strptime;
	use Scalar::Util qw/blessed looks_like_number/;

	has foo => (
		is => 'rw',
		isa => DateTime,
		default => sub { 'DateTime'->today },
		coerce => sub {
			(blessed($_[0]) and blessed($_[0]) eq 'DateTime') ? $_[0] :
			looks_like_number($_[0])                          ? 'DateTime'->from_epoch(epoch => $_[0]) :
			DateTime::Format::Strptime->new(pattern => '%F %T')->parse_datetime($_[0])
		}
	);
}

lives_ok
	{ Foo->new(foo => time) }
	'coerced time';
