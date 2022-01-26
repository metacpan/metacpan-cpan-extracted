#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 7;

use Net::DNS::Resolver::Unbound;


my $resolver = Net::DNS::Resolver::Unbound->new();
ok( $resolver, 'create new resolver instance' );


sub test_case {
	my ( $handle, @vector ) = @_;
	Net::DNS::Resolver::libunbound::async_callback( $handle, @vector ) if @vector;
	return $resolver->bgread($handle);
}


is( test_case(), undef, 'handle undefined' );

is( test_case( [1] ), undef, 'awaiting callback' );

is( test_case( [1, 0] ), undef, 'NULL result' );
is( $resolver->errorstring(), undef, '$resolver->errorstring' );

is( test_case( [1, -99] ), undef, 'callback error' );
is( $resolver->errorstring(), 'unknown error', '$resolver->errorstring' );


exit;

