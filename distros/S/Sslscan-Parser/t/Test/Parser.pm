#!/usr/bin/perl

package t::Test::Parser;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;

    my $parser = $self->{parser1};
    my $host = $parser->get_host('google.com');
    my @ports = $host->get_all_ports();

    my $port = $host->get_port('443');

    my @ciphers = $port->get_all_ciphers();
  
    my $cipher1 = $ciphers[0];
    my $cipher2 = $ciphers[1];
    my $cipher3 = $ciphers[2];

    is ( $cipher1->status, 'accepted', 'cipher1 type');
    is ( $cipher1->sslversion, 'SSLv2', 'cipher1 path');
    is ( $cipher1->bits, '168', 'cipher1 response_code');
    is ( $cipher1->cipher, 'DES-CBC3-MD5', 'cipher1 response_code');
    
    is ( $cipher2->status, 'accepted', 'cipher2 type');
    is ( $cipher2->sslversion, 'SSLv2', 'cipher2 path');
    is ( $cipher2->bits, '56', 'cipher2 response_code');
    is ( $cipher2->cipher, 'DES-CBC-MD5', 'cipher2 response_code');
    
    is ( $cipher3->status, 'accepted', 'cipher3 type');
    is ( $cipher3->sslversion, 'SSLv2', 'cipher3 path');
    is ( $cipher3->bits, '40', 'cipher3 response_code');
    is ( $cipher3->cipher, 'EXP-RC2-CBC-MD5', 'cipher3 response_code');


}
1;
