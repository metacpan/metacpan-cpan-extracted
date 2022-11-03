use v5.10;
use strict;
use warnings;

use Test::More;

BEGIN {
	unless (eval { require Moo } && Moo->VERSION > 2) {
		plan skip_all => 'These tests require Moo';
	}
}

{

	package Role1;

	use Moo::Role;
	use Mooish::AttributeBuilder;

	has field 'test1';
}

{

	package Role2;

	use Moo::Role;
	use Mooish::AttributeBuilder;

	has field 'test2';
}

{
	package TestMoo;

	use Moo;

	with qw(Role1 Role2);
}

# all ok if we got this far
pass;

done_testing;

