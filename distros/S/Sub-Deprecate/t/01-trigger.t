#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

use Sub::Deprecate qw(sub_trigger_once_with);

sub foo {7};

{
	eval {
		sub_trigger_once_with( __PACKAGE__, 'foo', sub { die "4242\n" } );
		foo()
	};
	like( $@, qr/4242/, 'triggers as expected');
}

{
	eval {
		sub_trigger_once_with( __PACKAGE__, 'does_not_exist', sub { die "4242\n" } );
	};
	like( $@, qr/must exist/, 'sub must exist');
}

1;
