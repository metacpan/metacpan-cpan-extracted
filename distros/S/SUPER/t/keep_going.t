#!perl

BEGIN
{
	chdir 't' if -d 't';
}

use lib '../lib';

use strict;
use warnings;

use Test::More tests => 4;

# so being able to say super() once is neat, but I want to super all
# the way back up to the root of the tree

package Grandfather;

Test::More->import();

sub foo
{
	pass( "Called on the Grandfather" );
	return 42;
}

package Father;

Test::More->import();

use SUPER;
use base qw( Grandfather );
my $called;

sub foo
{
	die "Recursed on Father (should have called Grandfather)"
		if ++$called > 1;

	pass( "Called on the Father" );
	super;
}

package Son;

Test::More->import();

use SUPER;
use base qw( Father );

sub foo
{
	pass( "Called on the Son" );
	super;
}

package main;

is( Son->foo(), 42, "called the Son->Father->Grandfather" );
