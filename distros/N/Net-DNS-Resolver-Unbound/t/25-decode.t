#!/usr/bin/perl
#

use strict;
use warnings;
use IO::File;
use Test::More;

use Net::DNS::Resolver::Unbound;

my $resolver = Net::DNS::Resolver::Unbound->new();

plan skip_all => 'no local nameserver' unless $resolver->nameservers;
plan tests    => 4;


my $qname = 'www.net-dns.org';

my $ub_ctx = $resolver->{ub_ctx};
my $secure = $ub_ctx->mock_resolve( $qname, 1, 0 );
$resolver->_reset_errorstring;
$resolver->_decode_result($secure);
is( $resolver->errorstring(), '', 'secure flag set' );


my $insecure = $ub_ctx->mock_resolve( $qname, 0, 0 );
$resolver->_reset_errorstring;
$resolver->_decode_result($insecure);
is( $resolver->errorstring(), 'INSECURE', 'secure flag not set' );


my $bogus = $ub_ctx->mock_resolve( $qname, 0, 1 );
$resolver->_reset_errorstring;
$resolver->_decode_result($bogus);
ok( $resolver->errorstring(), 'bogus flag set' );


is( $resolver->_decode_result(undef), undef, 'undefined result' );


my $file   = "25-decode.tmp";					# discard debug output
my $handle = IO::File->new( $file, '>' ) || die "Could not open $file for writing";
$resolver->debug(1);
select( ( select($handle), $resolver->_decode_result($secure) )[0] );
close($handle);
unlink($file);


exit;

