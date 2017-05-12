#!perl

BEGIN
{
	chdir 't' if -d 't';
}

use lib '../lib';

use strict;
use warnings;

use Test::More tests => 7;

# Being able to say SUPER() once is neat, but I want to super all
# the way back up to the root of the tree, passing different arguments

package Grandfather;

Test::More->import();

sub foo
{
	my ($self, $from) = @_;
	pass( 'Called on the Grandfather' );
	is( $from, 'Father', '... from the father' );
	return __PACKAGE__;
}

package Father;

Test::More->import();

use SUPER;
use base qw( Grandfather );
my $called;

sub foo
{
	my ($self, $from) = @_;
	die "Recursed on Father (should have called Grandfather)"
		if ++$called > 1;

	pass( 'Called on the Father' );
	is( $from, 'Son', '... from the son' );
	my $super_class = $self->SUPER( __PACKAGE__ );
	is( $super_class, 'Grandfather', '... (whose parent is the grandfather)' );
	return __PACKAGE__;
}

package Son;

Test::More->import();

use SUPER;
use base qw( Father );

sub foo
{
	my $self = shift;
	pass( 'Called on the Son' );
	my $super_class = $self->SUPER( __PACKAGE__ );
	is( $super_class, 'Father', '... (whose parent is the father)' );
}

package main;

Son->foo();
