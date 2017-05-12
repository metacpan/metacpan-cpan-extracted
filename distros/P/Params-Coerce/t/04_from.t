#!/usr/bin/perl -w

# Using Params::Coerce the correct way, and "does stuff happen" tests

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Params::Coerce;





#####################################################################
# Check the behaviour of ->from with subclasses

my $Foo = Foo->new;
isa_ok( $Foo, 'Foo' );
my $Bar = Bar->from($Foo);
isa_ok( $Bar, 'Bar' );
isa_ok( $Bar->was, 'Foo' );
my $Baz = Bar::Baz->from($Foo);
isa_ok( $Baz, 'Bar' );
isa_ok( $Baz, 'Bar::Baz' );
isa_ok( $Baz->was, 'Foo' );


	



#####################################################################
# Create all the testing packages we needed for this

package Foo;

sub new {
	bless {}, shift;
}

sub __as_Bar {
	bless { was => shift }, 'Bar';
}

sub __as_Bar_Baz {
	bless { was => shift }, 'Bar::Baz';
}

package Bar;

use Params::Coerce 'from';

sub was { $_[0]->{was} }

package Bar::Baz;

use vars qw{@ISA};
BEGIN {
	@ISA = 'Bar';
}

1;
