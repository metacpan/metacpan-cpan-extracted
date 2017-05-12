#!perl -w

use strict;
use Test::More tests => 3;

BEGIN{
	package X;
	use Sub::Attribute;

	sub C :ATTR_SUB{
		my($class, $sym, $code, $name, $data) = @_;

		no warnings 'redefine';
		*{$sym} = sub{ $data };
	}

	$INC{'X.pm'}++;
}

use parent -norequire => qw(X);

sub foo :C( 42 );
is foo(), 42;

sub bar :C(  bar  );
is bar(), 'bar';

sub baz :C(	 	baz	 	);
is baz(), 'baz';

eval '' if my $must_be_false;
