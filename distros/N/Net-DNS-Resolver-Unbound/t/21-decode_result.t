#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 7;

use Net::DNS::Resolver::Unbound;


my $resolver = Net::DNS::Resolver::Unbound->new();
ok( $resolver, 'create new resolver instance' );


$resolver->_reset_errorstring;

is( $resolver->_decode_result(), undef, '$resolver->_decode_result()' );
is( $resolver->errorstring,	 '',	'empty $resolver->errorstring' );

is( $resolver->_decode_result(0), undef, '$resolver->_decode_result(0)' );
is( $resolver->errorstring,	  '',	 'empty $resolver->errorstring' );

is( $resolver->_decode_result(1), undef,	   '$resolver->_decode_result(1)' );
is( $resolver->errorstring,	  'unknown error', 'defined $resolver->errorstring' );


exit;

