#!perl -T

use strict;
use warnings;

BEGIN { chdir 't' if -d 't' }

use Test::More tests => 18;
use Test::Exception;

use vars qw( $void_called $anormalsub %anormalsub @anormalsub );

use_ok( 'Sub::Context' );

Sub::Context->import(
	foo =>
	{
		void   => \&void,
		list   => \&list,
		scalar => \&scalar,
	}
);

can_ok( 'main', 'foo' );

foo();
ok( $void_called, 'should detect and dispatch in void context' );
my @list = foo();
is( @list, 2,               'should respect list context' );
is( "@list", 'list called', '... and should return correct order' );
is( foo(), 'scalar called', 'should detect and dispatch in scalar context' );

package NotMain;

Sub::Context->import(
	bar =>
	{
		'list'   => \&list,
		'scalar' => 'not a sub',
	},
);

package main;

can_ok( 'NotMain', 'bar' );
ok( ! main->can( 'bar' ),
	'import should only pollute calling package namespace' );

throws_ok { NotMain::bar() } qr/No sub for void context/,
	'should throw exception with unexpected context';

throws_ok { my $foo = NotMain::bar() } qr/No sub for scalar/,
	'should not attempt to call a non-sub';
throws_ok { my $foo = NotMain::bar() } qr/not a sub/,
	'... warning with custom message, if necessary';

$anormalsub = 100;
%anormalsub = ( sunny => 'ataraxic' );
@anormalsub = ( 'kudra' );

Sub::Context->import(
	anormalsub =>
	{
		void => sub { die "No void allowed!" },
		list => sub { split( ' ', scalar( anormalsub() ) ) },
	},
);

is( $anormalsub,                    100, 'not overwriting existing scalar' );
is( $anormalsub{sunny},       'ataraxic', '... hash' );
is( $anormalsub[0],              'kudra', '... or array' );
is( anormalsub(), 'this is a normal sub', '... nor original sub' );
my @words = anormalsub();
is( @words, 5, 'should wrap around existing sub for context' );
is( "@words", 'this is a normal sub', 'should call passed subref' );

throws_ok { Sub::Context->import( baz => { viod => sub { }, }, ) }
	qr/type 'viod' not allowed/,
	'import() should warn with bad type request';

sub void
{
	$void_called = 1;
}

sub list
{
	return ( 'list', 'called' );
}

sub scalar
{
	return 'scalar called';
}

sub anormalsub
{
	return 'this is a normal sub';
}
