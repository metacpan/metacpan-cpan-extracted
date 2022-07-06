use strict;
use warnings;
use Test::More;
use Role::Hooks;

BEGIN {
	package Foo;
	sub new { bless [], shift }
};

ok ! Role::Hooks->is_role( 'Foo' );
done_testing;
