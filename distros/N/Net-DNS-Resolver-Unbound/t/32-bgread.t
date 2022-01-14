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


is( $resolver->bgread(undef), undef, 'resolver->bgread	(undefined $handle)' );

is( $resolver->bgread( {result => undef} ), undef, 'resolver->bgread	(exists $handle{result})' );


NonFatalBegin();

my $handle = $resolver->bgsend('.');

ok( $resolver->bgread($handle), 'resolver->bgread($handle)' );

$resolver->bgcancel($handle);

NonFatalEnd();


exit;

