#!/usr/bin/perl

# Main tests for the Net::IP::Resolver module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use Net::IP::Resolver ();





#####################################################################
# Just the basics for now

my $Resolver = Net::IP::Resolver->new;
isa_ok( $Resolver, 'Net::IP::Resolver' );
is( $Resolver->add( 'Comcast', '123.123.0.0/16', '1.2.3.0/24' ), 1,
	'Added basic named network' );
my $company = bless {}, 'Foo';
isa_ok( $company, 'Foo' );
is( $Resolver->add( $company, '124.124.124.0/24' ), 1,
	'Added object network' );
is( $Resolver->find_first(), undef, '->find_fist() returns undef' );
is( $Resolver->find_first( '123.123.123.123' ), 'Comcast',
	'->find_first(ip) returned correct named network' );
is( $Resolver->find_first( '1.2.3.4' ), 'Comcast',
	'->find_first(ip) returned correct named network' );
isa_ok( $Resolver->find_first( '124.124.124.124' ), 'Foo' );
is( $Resolver->find_first( '2.3.4.5' ), undef, '->find_first(outside) ip returns undef' );

1;
