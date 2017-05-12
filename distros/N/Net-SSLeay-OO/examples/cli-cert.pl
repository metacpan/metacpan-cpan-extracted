#!/usr/local/bin/perl
# cli-cert.pl
# 8.6.1998, originally written as stdio_bulk.pl Sampo Kellomaki <sampo@iki.fi>
# 8.12.2001, adapted to test client certificates
#
# Contact server using client side certificate. Demonstrates how to
# set up the client and how to make the server request the certificate.
# This also demonstrates how you can communicate via arbitrary stream, not
# just a TCP one.
# $Id: cli-cert.pl,v 1.2 2003/06/13 21:14:41 sampo Exp $

use Socket;
use Net::SSLeay::OO;

$ENV{RND_SEED} = '1234567890123456789012345678901234567890';

($cert_pem, $key_pem, $cert_dir) = @ARGV;      # Read command line
$how_much = 10000;

### Note: the following initialization is common for both client
### and the server. In particular, it is important that VERIFY_PEER
### is sent on the server as well, because otherwise the client
### certificate will never be requested.

use Net::SSLeay::Constants qw(VERIFY_PEER FILETYPE_PEM);

$ctx = Net::SSLeay::Context->new;
$ctx->set_default_passwd_cb(sub{"secr1t"});
$ctx->use_certificate_chain_file($cert_pem);
$ctx->use_PrivateKey_file($key_pem, FILETYPE_PEM);
$ctx->load_verify_locations('', $cert_dir);
$ctx->set_verify(VERIFY_PEER, \&verify);


pipe RS, WC or die "pipe 1 ($!)";
pipe RC, WS or die "pipe 2 ($!)";
select WC; $| = 1;
select WS; $| = 1;
select STDOUT;
$| = 1;

if ($child_pid = fork) {
    print "$$: I'm the server for child $child_pid\n";
    $ssl = Net::SSLeay::SSL->new(ctx => $ctx);

    $ssl->set_rfd(fileno(RS));
    $ssl->set_wfd(fileno(WS));

    print "$$: accept\n";
    $ssl->accept;
    print "$$: Cipher `" . $ssl->get_cipher . "'\n";
    #print "$$: client cert: " . $ssl->dump_peer_certificate;

    $got = $ssl->ssl_read_all($how_much);
    print "$$: got " . length($got) . " bytes\n";
    $ssl->ssl_write_all(\$got);
    $got = '';

    print "$$: close SSL\n";
    undef($ssl);# Tear down connection
    print "$$: close CTX\n";
    undef($ctx);

    print "$$: wait\n";
    wait;  # wait for child to read the stuff

    close WS;
    close RS;
    print "$$: server done ($?).\n"
	. (($? >> 8) ? "ERROR\n" : "OK\n"); 
    exit;
}

print "$$: I'm the child.\n";
sleep 1;  # Give server time to get its act together

$ssl = Net::SSLeay::SSL->new(ctx => $ctx);
$ssl->set_rfd(fileno(RC));
$ssl->set_wfd(fileno(WC));
print "$$: connect\n";
$ssl->connect;

print "$$: Cipher `" . $ssl->get_cipher . "'\n";
#print "$$: server cert: " . $ssl->dump_peer_certificate;

# Exchange data

$data = 'B' x $how_much;
$ssl->ssl_write_all(\$data);
$got = $ssl->ssl_read_all($how_much);

print "$$: close SSL\n";
undef($ssl);               # Tear down connection
print "$$: close CTX\n";
undef($ctx);
print "$$: close pipes\n";
close WC;
close RC;
print "$$: exiting\n";
exit ($data ne $got);

use Net::SSLeay::X509::Context;
use Net::SSLeay::X509;

our $PRINTED;
sub verify {
    my ($ok, $x509_cert) = @_;
    print "$$: **** Verify 2 called ($ok)\n";
    if ($x509_cert) {
	print "$$: Certificate:\n";
	    print "  Subject Name: "
		. $x509_cert->get_subject_name->oneline
		    . "\n";
	    print "  Issuer Name:  "
                . $x509_cert->get_issuer_name->oneline
                  . "\n";
    }
    $callback_called++;
    return 1;
}

__END__
