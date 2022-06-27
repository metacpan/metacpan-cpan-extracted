#!/usr/bin/perl

##
## Tests of main functionality of Object::Destroyer -
## i.e. destruction of objects - are here.
##

use strict;
use warnings;

use Test::More;
use Object::Destroyer;

##
## Make sure a Foo object behaves as expected
##
is( $Foo::destroy_counter, 0, 'Start value' );

SCOPE: {
	##
	## This object will not be destroyed automatically
	##
	my $foo = Foo->new;
	is( $Foo::destroy_counter, 0, 'No auto destroy of Foo objects' );
}

SCOPE: {
	##
	## This $foo is destroyed manually
	##
	my $foo = Foo->new;
	$foo->DESTROY;
	is( $Foo::destroy_counter, 1, 'Manually called DESTROY' );
}
is( $Foo::destroy_counter, 2, 'Auto called DESTROY after leaving the scope' );


##
## Foo objects are OK, let's start testing our Object::Destroyer
##

##
## Test of default 'DESTROY' method
## It's called twice - 1st by Object::Destroyer, 2nd by Perl gc!
##
SCOPE: {
	my $foo = Foo->new;
	my $sentry = Object::Destroyer->new($foo);
	@Foo::called_method = ();
}
is( $Foo::destroy_counter, 4, 'DESTROY called by Object::Destroyer' );
is_deeply( \@Foo::called_method, ['DESTROY', 'DESTROY'] );

##
## Test that the specified method is called indeed
##
SCOPE: {
	my $foo = Foo->new;
	my $sentry = Object::Destroyer->new($foo, 'release');
	@Foo::called_method = ();
}
is( $Foo::destroy_counter, 5, 'release called by Object::Destroyer' );
is_deeply( \@Foo::called_method, ['release', 'DESTROY'] );

SCOPE: {
	my $foo = Foo->new;
	my $sentry = Object::Destroyer->new($foo, 'delete');
	@Foo::called_method = ();
}
is( $Foo::destroy_counter, 6, 'delete called by Object::Destroyer' );
is_deeply( \@Foo::called_method, ['delete', 'DESTROY'] );


##
## Test manual clean-up of the enclosed object
## by $sentry->DESTROY or undef($sentry)
##
SCOPE: {
	my $foo = Foo->new;
	my $sentry = Object::Destroyer->new($foo);
	is( $Foo::destroy_counter, 6, 'nothing changed' );
	$sentry->DESTROY;
	is( $Foo::destroy_counter, 7, 'Foo->DESTROY by Object::Destroyer' );
}
is( $Foo::destroy_counter, 8, 'Foo->DESTROY by Perl gc' );

SCOPE: {
	my $foo = Foo->new;
	my $sentry = Object::Destroyer->new($foo, 'release');
	is( $Foo::destroy_counter, 8, 'nothing changed' );
	$sentry->DESTROY;
	is( $Foo::destroy_counter, 8, 'Foo->release (not DESTROY) has not been called' );
}
is( $Foo::destroy_counter, 9, 'Foo->DESTROY by Perl gc' );

SCOPE: {
	my $foo = Foo->new;
	my $sentry = Object::Destroyer->new($foo);
	is( $Foo::destroy_counter, 9, 'nothing changed' );
	undef $sentry;
	is( $Foo::destroy_counter, 10, 'Foo->DESTROY by Object::Destroyer' );
}
is( $Foo::destroy_counter, 11, 'Foo->DESTROY by Perl gc' );

SCOPE: {
	my $foo = Foo->new;
	my $sentry = Object::Destroyer->new($foo, 'release');
	is( $Foo::destroy_counter, 11, 'nothing changed' );
	undef $sentry;
	is( $Foo::destroy_counter, 11, 'Foo->release' );
}
is( $Foo::destroy_counter, 12, 'Foo->DESTROY by Perl gc' );


##
## Test anonymous subrotine calls
##
SCOPE: {
	my $test = 0;
	SCOPE: {
		my $sentry = Object::Destroyer->new( sub{$test=1} );
		is($test, 0);
	}
	is($test, 1);
	for ( 1 .. 10 ) {
		my $sentry = Object::Destroyer->new( sub{$test++} );
	}
	is($test, 11);
}

##
## Anonymous subrotine destroys an object not capable of auto-destroy
##
is( $Bar::count, 0 );
for (0..9) {
	my $bar = Bar->new;
}
is( $Bar::count, 10 );
for (0..9) {
	my $bar = Bar->new;
	my $sentry = Object::Destroyer->new( sub{undef $bar->{self}} );
}
is( $Bar::count, 10 );

##
## Test objects that use Object::Destroy in their constructors
##
is( $Buzz::count, 0 );
{
	my $bar = Buzz->new;
	is( $Buzz::count, 1 );
}
is( $Buzz::count, 0 );

done_testing;



#####################################################################
# Test Classes

package Foo;

use vars qw{$destroy_counter @called_method};
BEGIN { $destroy_counter = 0 }

sub new {
	my $class = shift;
	my $self = {};
	$self->{self} = $self; ## circular reference
	return bless $self, ref $class || $class;
}

sub delete{
	my $self = shift;
	undef $self->{self};
	push @called_method, 'delete';
}

sub release {
	my $self = shift;
	undef $self->{self};
	push @called_method, 'release';
}

sub DESTROY {
	my $self = shift;
	$destroy_counter++;
	undef $self->{self};
	push @called_method, 'DESTROY';
}

##
## Object of class Bar has no clean-up method at all
##
package Bar;
use vars '$count';
BEGIN { $count = 0; }

sub new{
	my $class = shift;

	$count++;

	my $self = {};
	$self->{self} = $self;
	return bless $self, ref $class || $class;
}

sub DESTROY{
	$count--;
}

##
## Constructor of Buzz returns itself in a wrapper
##
package Buzz;
use vars '$count';
BEGIN { $count = 0 };
sub new{
	my $class = shift;

	$count++;

	my $self = bless {}, ref $class || $class;
	$self->{self} = $self;
	return Object::Destroyer->new($self, 'release');
}

sub release{
	my $self = shift;
	undef $self->{self};
}

sub DESTROY{
	my $self = shift;
	$count--;
}

1;
