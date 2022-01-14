#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 4;

use Net::DNS::Resolver::Unbound;

BEGIN {
	local @INC = ( @INC, qw(t) );
	require NonFatal;
}


my $resolver = Net::DNS::Resolver::Unbound->new();
ok( $resolver, 'create new resolver instance' );


is( $resolver->bgbusy(undef), undef, 'resolver->bgbusy( undefined $handle )' );

is( $resolver->bgbusy( {result => undef} ), undef, 'resolver->bgbusy( exists $handle{result} )' );


NonFatalBegin();

my $handle = $resolver->bgsend('.');

ok( $resolver->bgbusy($handle), 'resolver->bgbusy($handle)' );

$resolver->bgcancel($handle);

NonFatalEnd();


exit;

