package Net::HTTP2::IOSocketSSL;

use strict;
use warnings;

use IO::Socket::SSL ();

use constant _TLS_PROTO_ARGNAME => IO::Socket::SSL->can_alpn() ? 'SSL_alpn_protocols' : 'SSL_npn_protocols';

sub tls_proto_args {
    return ( _TLS_PROTO_ARGNAME, [Protocol::HTTP2::ident_tls] );
}

sub verify_args_from_boolean {
    my ($verify_yn) = @_;

    return ( SSL_verify_mode => $verify_yn ? IO::Socket::SSL::SSL_VERIFY_PEER : IO::Socket::SSL::SSL_VERIFY_NONE );
}

1;
