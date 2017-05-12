use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TLSTest;

#use Data::Dumper;

BEGIN {
    use_ok 'Protocol::TLS::Server';
}

new_ok 'Protocol::TLS::Server',
  [ cert_file => 't/test.crt', key_file => 't/test.key' ];

subtest 'handshake decode' => sub {
    my $tls_srv = Protocol::TLS::Server->new(
        cert_file => 't/test.crt',
        key_file  => 't/test.key',
    )->new_connection;

    my $data = hstr(<<"    EOF");
    # Record Layer
    16    # ContentType     - handshake (22)
    03 01 # ProtocolVersion - TLS 1.0   (3.1)
    00 6e # Length          - length (110)
    ## Handshake Protocol
        01       # HandshakeType  - Client Hello (1)
        00 00 6a # Length         - length (106)
        03 03    # ProtocolVersion - TLS 1.2   (3.3)
        fdf549b4 # GMT Unix Time: Jan  6, 2105 21:47:16.000000000 MSK
        e17cf5ce82e0ce885edb98fbd4dc21db25aafa84ddde7020b85f2575 # Random Bytes
        20       # Sessionid length
        6ba41dd5122959e749a9ee2fa9ee9e179184a1cb80d6c09c1f0d22c281ce51a1 # Sessionid
        00 0c    # Cipher suites length (12)
            c02b # TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
            c02f # TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
            c00a # TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
            002f # TLS_RSA_WITH_AES_128_CBC_SHA
            0005 # TLS_RSA_WITH_RC4_128_SHA
            0004 # TLS_RSA_WITH_RC4_128_MD5
        01       # Compression Methods Length: 1
            00   # null
        00 13    # Extensions Length: 19
            0000 # server_name
                0011 # length: 17
                000f # list length: 15
                00   # host_name
                000c # host_nane length 12
                6d6574616370616e2e6f7267 # metacpan.org
    EOF

    $tls_srv->feed($data);

    my $p = $tls_srv->{ctx}->{pending};
    is $p->{cipher}, 0x2f;

    #is $hc->{extensions}->{0}->{0}, 'metacpan.org', "correct hostname";
    #note explain $tls_srv->{ctx};
};

done_testing;
