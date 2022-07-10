#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More;

use Net::DNS::Resolver::Unbound;

my $resolver = Net::DNS::Resolver::Unbound->new();

plan skip_all => 'no local nameserver' unless $resolver->nameservers;
plan tests    => 4;


my $qname = 'ns.net-dns.org';

ok( $resolver->send($qname), "$resolver->send($qname)" );

my $ub_ctx = $resolver->{ub_ctx};
my $secure = $ub_ctx->mock_result( $qname, 1, 0 );
$resolver->_reset_errorstring;
$resolver->_decode_result( $secure, int rand(0xffff) );
is( $resolver->errorstring(), '', 'secure flag set' );


my $insecure = $ub_ctx->mock_result( $qname, 0, 0 );
$resolver->_reset_errorstring;
$resolver->_decode_result( $insecure, int rand(0xffff) );
is( $resolver->errorstring(), 'INSECURE', 'secure flag not set' );


my $bogus = $ub_ctx->mock_result( $qname, 0, 1 );
$resolver->_reset_errorstring;
$resolver->_decode_result( $bogus, int rand(0xffff) );
ok( $resolver->errorstring(), 'bogus flag set' );


exit;

