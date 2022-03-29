#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More;

use Net::DNS;
use Net::DNS::Resolver::Unbound;

my $resolver = Net::DNS::Resolver::Unbound->new();


plan skip_all => 'no local nameserver' unless $resolver->nameservers;
plan tests    => 3;

my $qname = 'ns.net-dns.org';

ok( $resolver->send($qname), "$resolver->send($qname)" );

my $ub_ctx = $resolver->{ub_ctx};
my $secure = $ub_ctx->mock_result( $qname, 1, 0 );
$resolver->_reset_errorstring;
$resolver->_decode_result($secure);
is( $resolver->errorstring(), '', 'secure flag set' );


my $bogus = $ub_ctx->mock_result( $qname, 0, 1 );
$resolver->_reset_errorstring;
$resolver->_decode_result($bogus);
ok( $resolver->errorstring(), 'bogus flag set' );


exit;

