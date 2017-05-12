#!/usr/bin/perl -w
# sslecho.pl - Echo server using SSL
#
# Copyright (c) 1996,1998 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
# Date:   27.6.1996, 8.6.1998
# 7.12.2001, added more support for client side certificate testing --Sampo
# $Id: sslecho.pl,v 1.2 2001/12/08 17:43:14 sampo Exp $
#
# Usage: ./sslecho.pl *port* *cert.pem* *key.pem*
#
# This server always binds to localhost as this is all that is needed
# for tests.
#
#  Updated for Net::SSLeay::OO 2009-10-10, Sam Vilain.
#
#  To use from the source distribution, after running Makefile.PL
#
#    perl -Mlib=lib examples/sslecho.pl 12345 t/certs/server-{cert,key}.pem
#    (password 'secr1t')
#
#  Connect to it with:
#    openssl s_client -connect localhost:12345 -CApath t/certs \
#         -cert t/certs/client-cert.pem \
#         -key t/certs/client-key.pem
#
#  It should work with or without the client certificate (ie, the
#  -cert and -key arguments are optional)

die "Usage: ./sslecho.pl *port* *cert.pem* *key.pem*\n" unless $#ARGV == 2;
($port, $cert_pem, $key_pem) = @ARGV;
$our_ip = "\x7F\0\0\x01";

$trace = 2;
use Socket;
use Net::SSLeay::OO;
use Net::SSLeay::OO::Constants qw(VERIFY_PEER OP_ALL);

#$Net::SSLeay::trace = 3; # Super verbose debugging

#
# Create the socket and open a connection
#

$our_serv_params = pack ('S n a4 x8', &AF_INET, $port, $our_ip);
socket (S, &AF_INET, &SOCK_STREAM, 0)  or die "socket: $!";
bind (S, $our_serv_params)             or die "bind:   $! (port=$port)";
listen (S, 5)                          or die "listen: $!";

#
# Prepare SSLeay
#

print "sslecho: Creating SSL context...\n" if $trace>1;
$ctx = Net::SSLeay::OO::Context->new;
print "sslecho: Setting cert and RSA key...\n" if $trace>1;
$ctx->set_cipher_list('ALL');
$ctx->set_cert_and_key($cert_pem, $key_pem);
$ctx->set_verify(VERIFY_PEER);
#$ctx->set_options(OP_ALL);

while (1) {
    
    print "sslecho $$: Accepting connections...\n" if $trace>1;
    ($addr = accept (NS, S)) or die "accept: $!";
    $old_out = select (NS); $| = 1; select ($old_out);  # Piping hot!
    
    if ($trace) {
	($af,$client_port,$client_ip) = unpack('S n a4 x8',$addr);
	@inetaddr = unpack('C4',$client_ip);
	print "$af connection from " . join ('.', @inetaddr)
	    . ":$client_port\n" if $trace;;
    }
    
    #
    # Do SSL negotiation stuff
    #

    print "sslecho: Creating SSL session (cxt=`$ctx')...\n" if $trace>1;
    my $ssl = $ctx->accept(\*NS) or die "failed to accept";
    
    print "sslecho: Cipher `" . $ssl->get_cipher . "'\n" if $trace;
    
    #
    # Connected. Exchange some data.
    #
    
    while ( length($got = $ssl->read(100)) ) {
	    print "sslecho $$: got " . length($got) . " bytes\n" if $trace==2;
	    print "sslecho: Got `$got' (" . length ($got) . " chars)\n" if $trace>2;
	    $got = uc $got;
	    if ($got =~ /^CLIENT-CERT-TEST\s*\Z/) {
		    $got .= $ssl->dump_peer_certificate . "END CERT\n";
	    }
	    $ssl->write($got);
    }
    
    print "sslecho: Tearing down the connection.\n\n" if $trace>1;
    
    $ssl->shutdown;
    close NS;
}
$ctx->free;
close S;

__END__
