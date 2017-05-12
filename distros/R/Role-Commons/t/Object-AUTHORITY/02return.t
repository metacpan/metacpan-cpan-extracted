package Local::MyTest;

our $AUTHORITY = 'http://example.net/';

package main;

use Test::More tests => 2;
use Object::AUTHORITY -package => 'Local::MyTest';

is(
	Local::MyTest->AUTHORITY,
	'http://example.net/',
	'test package has correct authority',
	);

SKIP: {
	skip "need Moose 2.02", 1
		unless eval 'use Moose 2.02; 1;';
	skip "Moose seems to have stopped defining an authority", 1
		unless defined $Moose::AUTHORITY;
		
	Object::AUTHORITY->import(-package => 'Moose');
	ok(
		defined Moose->AUTHORITY,
		'Moose has an authority',
		);
}
