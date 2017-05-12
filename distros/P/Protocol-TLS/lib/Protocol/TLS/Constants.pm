package Protocol::TLS::Constants;
use strict;
use warnings;
use constant {

    TLS_v10 => 0x0301,
    TLS_v11 => 0x0302,
    TLS_v12 => 0x0303,
    TLS_v13 => 0x0304,

    # connectionEnd
    CLIENT => 0,
    SERVER => 1,

    # Content Type
    CTYPE_CHANGE_CIPHER_SPEC => 20,
    CTYPE_ALERT              => 21,
    CTYPE_HANDSHAKE          => 22,
    CTYPE_APPLICATION_DATA   => 23,

    # Handshake Type
    HSTYPE_HELLO_REQUEST       => 0,
    HSTYPE_CLIENT_HELLO        => 1,
    HSTYPE_SERVER_HELLO        => 2,
    HSTYPE_CERTIFICATE         => 11,
    HSTYPE_SERVER_KEY_EXCHANGE => 12,
    HSTYPE_CERTIFICATE_REQUEST => 13,
    HSTYPE_SERVER_HELLO_DONE   => 14,
    HSTYPE_CERTIFICATE_VERIFY  => 15,
    HSTYPE_CLIENT_KEY_EXCHANGE => 16,
    HSTYPE_FINISHED            => 20,

    # Ciphers
    TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 => 0xc02b,
    TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256   => 0xc02f,
    TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA    => 0xc00a,
    TLS_RSA_WITH_AES_128_CBC_SHA            => 0x002f,
    TLS_RSA_WITH_3DES_EDE_CBC_SHA           => 0x000a,
    TLS_RSA_WITH_RC4_128_SHA                => 0x0005,
    TLS_RSA_WITH_RC4_128_MD5                => 0x0004,
    TLS_RSA_WITH_NULL_SHA256                => 0x003b,
    TLS_RSA_WITH_NULL_SHA                   => 0x0002,
    TLS_NULL_WITH_NULL_NULL                 => 0x0000,

    # State
    STATE_IDLE        => 0,
    STATE_HS_START    => 1,
    STATE_SESS_NEW    => 2,
    STATE_SESS_RESUME => 3,
    STATE_HS_RESUME   => 4,
    STATE_HS_HALF     => 5,
    STATE_HS_FULL     => 6,
    STATE_OPEN        => 7,

    # Alert
    WARNING => 1,
    FATAL   => 2,

    # Alert description
    CLOSE_NOTIFY                => 0,
    UNEXPECTED_MESSAGE          => 10,
    BAD_RECORD_MAC              => 20,
    DECRYPTION_FAILED_RESERVED  => 21,
    RECORD_OVERFLOW             => 22,
    DECOMPRESSION_FAILURE       => 30,
    HANDSHAKE_FAILURE           => 40,
    NO_CERTIFICATE_RESERVED     => 41,
    BAD_CERTIFICATE             => 42,
    UNSUPPORTED_CERTIFICATE     => 43,
    CERTIFICATE_REVOKED         => 44,
    CERTIFICATE_EXPIRED         => 45,
    CERTIFICATE_UNKNOWN         => 46,
    ILLEGAL_PARAMETER           => 47,
    UNKNOWN_CA                  => 48,
    ACCESS_DENIED               => 49,
    DECODE_ERROR                => 50,
    DECRYPT_ERROR               => 51,
    EXPORT_RESTRICTION_RESERVED => 60,
    PROTOCOL_VERSION            => 70,
    INSUFFICIENT_SECURITY       => 71,
    INTERNAL_ERROR              => 80,
    USER_CANCELED               => 90,
    NO_RENEGOTIATION            => 100,
    UNSUPPORTED_EXTENSION       => 110,

    # Hash Algorithm
    HASH_NONE   => 0,
    HASH_MD5    => 1,
    HASH_SHA1   => 2,
    HASH_SHA224 => 3,
    HASH_SHA256 => 4,
    HASH_SHA384 => 5,
    HASH_SHA512 => 6,

    # Signature Algorithm
    SIGN_ANONYMOUS => 0,
    SIGN_RSA       => 1,
    SIGN_DSA       => 2,
    SIGN_ECDSA     => 64,

    # Client Certificate Type
    RSA_SIGN                  => 1,
    DSS_SIGN                  => 2,
    RSA_FIXED_DH              => 3,
    DSS_FIXED_DH              => 4,
    RSA_EPHEMERAL_DH_RESERVED => 5,
    DSS_EPHEMERAL_DH_RESERVED => 6,
    FORTEZZA_DMS_RESERVED     => 20,
};

require Exporter;
our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
    versions => [qw(TLS_v10 TLS_v11 TLS_v12 TLS_v13)],
    c_types  => [
        qw( CTYPE_CHANGE_CIPHER_SPEC CTYPE_ALERT CTYPE_HANDSHAKE
          CTYPE_APPLICATION_DATA )
    ],
    hs_types => [
        qw( HSTYPE_HELLO_REQUEST HSTYPE_CLIENT_HELLO HSTYPE_SERVER_HELLO
          HSTYPE_CERTIFICATE HSTYPE_SERVER_KEY_EXCHANGE
          HSTYPE_CERTIFICATE_REQUEST HSTYPE_SERVER_HELLO_DONE
          HSTYPE_CERTIFICATE_VERIFY HSTYPE_CLIENT_KEY_EXCHANGE HSTYPE_FINISHED )
    ],
    end_types => [qw( CLIENT SERVER )],
    ciphers   => [
        qw( TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
          TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
          TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA TLS_RSA_WITH_AES_128_CBC_SHA
          TLS_RSA_WITH_3DES_EDE_CBC_SHA TLS_RSA_WITH_RC4_128_SHA
          TLS_RSA_WITH_RC4_128_MD5 TLS_RSA_WITH_NULL_SHA256 TLS_RSA_WITH_NULL_SHA
          TLS_NULL_WITH_NULL_NULL )
    ],
    state_types => [
        qw( STATE_IDLE STATE_HS_START STATE_SESS_NEW STATE_SESS_RESUME
          STATE_HS_RESUME STATE_HS_HALF STATE_HS_FULL STATE_OPEN )
    ],
    alert_types => [qw( WARNING FATAL )],
    alert_desc  => [
        qw( CLOSE_NOTIFY UNEXPECTED_MESSAGE BAD_RECORD_MAC
          DECRYPTION_FAILED_RESERVED RECORD_OVERFLOW DECOMPRESSION_FAILURE
          HANDSHAKE_FAILURE NO_CERTIFICATE_RESERVED BAD_CERTIFICATE
          UNSUPPORTED_CERTIFICATE CERTIFICATE_REVOKED CERTIFICATE_EXPIRED
          CERTIFICATE_UNKNOWN ILLEGAL_PARAMETER UNKNOWN_CA ACCESS_DENIED
          DECODE_ERROR DECRYPT_ERROR EXPORT_RESTRICTION_RESERVED PROTOCOL_VERSION
          INSUFFICIENT_SECURITY INTERNAL_ERROR USER_CANCELED NO_RENEGOTIATION
          UNSUPPORTED_EXTENSION)
    ],
    hash_alg => [
        qw( HASH_NONE HASH_MD5 HASH_SHA1 HASH_SHA224 HASH_SHA256 HASH_SHA384
          HASH_SHA512 )
    ],
    sign_alg       => [qw( SIGN_ANONYMOUS SIGN_RSA SIGN_DSA SIGN_ECDSA )],
    client_c_types => [
        qw( RSA_SIGN DSS_SIGN RSA_FIXED_DH DSS_FIXED_DH RSA_EPHEMERAL_DH_RESERVED
          DSS_EPHEMERAL_DH_RESERVED FORTEZZA_DMS_RESERVED )
    ],
);

my ( %reverse, %ciphers );
{
    no strict 'refs';
    for my $k ( keys %EXPORT_TAGS ) {
        for my $v ( @{ $EXPORT_TAGS{$k} } ) {
            $reverse{$k}{ &{$v} } = $v;
        }
    }

    for my $c ( keys %{ $reverse{ciphers} } ) {
        $ciphers{$c} =
          [ $reverse{ciphers}{$c} =~ /^TLS_(.+)_WITH_(.+)_([^_]+)$/ ];
    }
}

sub const_name {
    my ( $tag, $value ) = @_;
    exists $reverse{$tag} ? ( $reverse{$tag}{$value} || '' ) : '';
}

sub is_tls_version {
    $_[0] < TLS_v10 || $_[0] > TLS_v12 ? undef : $_[0];
}

sub cipher_type {
    exists $ciphers{ $_[0] } ? @{ $ciphers{ $_[0] } } : ();
}

our @EXPORT_OK = (
    qw(const_name is_tls_version cipher_type ),
    map { @$_ } values %EXPORT_TAGS
);

1
