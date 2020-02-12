use strict;
use warnings;
use Test::More;

{ package Local::Dummy1; use Test::Requires 'Sub::HandlesVia'; }
{ package Local::Dummy2; use Test::Requires 'Moo'; }
{ package Local::Dummy3; use Test::Requires 'Moose'; }
{ package Local::Dummy4; use Test::Requires 'Mouse'; }

use MooX::Press::Keywords;

use constant COMMON_DEFINITION => (
	has => [
		'foo' => {
			is           => bare,
			type         => Int,
			handles_via  => 'Counter',
			handles      => { 'inc_foo' => [ 'inc', 1 ] },
		},
	],
);

use MooX::Press (
	prefix => 'Foo',
	class => [
		'Moo'   => { toolkit => 'Moo',   COMMON_DEFINITION() },
		'Moose' => { toolkit => 'Moose', COMMON_DEFINITION() },
		'Mouse' => { toolkit => 'Mouse', COMMON_DEFINITION() },
	],
);

for my $toolkit (qw/ Moo Moose Mouse /) {
	
	my $class = "Foo::$toolkit";
	note "Class '$class'";
	
	my $obj = $class->new( foo => 42 );
	is( $obj->{foo}, 42, 'attribute can be set by constructor' );
	
	ok( !$obj->can('foo'),     'no method called foo' );
	ok(  $obj->can('inc_foo'), 'method called inc_foo' );
	
	$obj->inc_foo;
	
	is ($obj->{foo}, 43, 'attribute can be modified by handler' );
}

done_testing;
