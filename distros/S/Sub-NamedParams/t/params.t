#!/usr/bin/perl -w
use strict;
use warnings;
use Test;

BEGIN {
	chdir 't' if -d 't';
	unshift @INC, '../blib/lib';
	plan tests => 16;
}

use Sub::NamedParams qw/wrap/;

sub foo { @_ }
sub bar { @_ }
sub baz { @_ }
sub qux { @_ }
sub qix { @_ }

eval{wrap(sub=>\&foo,names=>[])};
ok($@,qr/'sub' value must not be a reference/);

wrap(
	sub     => 'foo',
	names   => [qw/ first second third/],
	default => {
		first  => 1,
		second => 2,
		third  => 3,
	},
	hashref => 0
);

my ( $one, $two, $three ) = foo(); # look ma, no params!
ok( $one, 1 );
ok( $two, 2 );
ok( $three, 3 );

($one,$two,$three)=foo(first=>'one',second=>'two');

ok( $one, 'one' );
ok( $two, 'two' );
ok( $three, 3 );

wrap (
	sub   => 'bar',
	names => [qw/ first second /]
);

eval{bar(second=>2)};
ok($@,qr/Cannot find value or default for .../);

# hashref is not specified, so it defaults to true
wrap(
	sub => 'baz',
	names => [qw/first second/]
);

($one,$two) = baz( { first => 'un', second => 'deux' } );

ok( $one, 'un' );
ok( $two, 'deux' );

# testing 'rewrap'.  Should fail
eval{(wrap sub=>'baz', names=>[])};
ok( $@,qr/Cannot rewrap .../);

wrap(
	sub     => 'qux',
	names   => [qw/ first second/],
	target  => 'Ovid',
	hashref => 0
);

# new sub should be wrapped
($one,$two) = Ovid( first => 'uno', second => 'dos' );

ok( $one, 'uno' );
ok( $two, 'dos' );

# original sub should remain the same
($one,$two) = qux( 'een', 'twee' );
ok( $one, 'een' );
ok( $two, 'twee' );

eval {wrap(sub=>'qux',names=>[],target=>'qix')};
ok( $@, qr/Cannot target a pre-existing sub.../ );
