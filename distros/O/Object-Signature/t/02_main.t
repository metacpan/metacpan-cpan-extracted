#!/usr/bin/perl

# Load testing for Object::Signature

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 17;

# Test a trivial example
my $Foo1 = Foo->new;
isa_ok( $Foo1, 'Foo' );
isa_ok( $Foo1, 'Object::Signature' );
ok( $Foo1->signature, '->signature returns true' );
is( length($Foo1->signature), 32, '->signature returns 32 chars' );
is( $Foo1->signature, $Foo1->signature, 'Multiple ->signature calls return the same' );

my $Foo2 = Foo->new;
isa_ok( $Foo2, 'Foo' );
is( length($Foo2->signature), 32, '->signature returns 32 chars' );
is( $Foo1->signature, $Foo2->signature, 'Multiple identical objects return the same ->signature' );

my $Bar1 = Bar->new;
isa_ok( $Bar1, 'Bar' );
isa_ok( $Bar1, 'Object::Signature' );
ok( $Bar1->signature, '->signature returns true' );
is( length($Bar1->signature), 32, '->signature returns 32 chars' );
isnt(
	$Foo1->signature,
	$Bar1->signature,
	'Identical objects of different classes return different signatures',
);

my $Bar2 = Bar->new;
isa_ok( $Bar2, 'Bar' );
ok( $Bar2->signature, '->signature returns true' );
is( length($Bar2->signature), 32, '->signature returns 32 chars' );
isnt(
	$Bar1->signature,
	$Bar2->signature,
	'Different objects of the same class return different signatures',
);





BEGIN {
	package Foo;

	use Object::Signature ();

	@Foo::ISA = 'Object::Signature';

	sub new {
		bless { a => 1 }, 'Foo'
	};

	1;

	package Bar;

	use Object::Signature ();

	@Bar::ISA = 'Object::Signature';

	my $bar = 0;

	sub new {
		bless { a => ++$bar }, 'Bar'
	}

	1;
}
