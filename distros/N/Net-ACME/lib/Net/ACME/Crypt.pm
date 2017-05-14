package Net::ACME::Crypt;

#----------------------------------------------------------------------
# This module exists because of a desire to do these computations
# in environments where a compiler may not be available.
# (Otherwise, CryptX would be ideal.)
#----------------------------------------------------------------------

use strict;
use warnings;

use Digest::SHA       ();
use JSON              ();
use MIME::Base64      ();

use Net::ACME::Crypt::RSA ();

*_encode_b64u = \&MIME::Base64::encode_base64url;

*get_rsa_public_jwk = \&Net::ACME::Crypt::RSA::get_public_jwk;
*get_rsa_jwk_thumbprint = \&Net::ACME::Crypt::RSA::get_jwk_thumbprint;

#Based on Crypt::JWT::encode_jwt(), but focused on this particular
#protocol’s needs. Note that UTF-8 will probably get mangled in here,
#but that’s not a problem since ACME shouldn’t require sending raw UTF-8.
sub create_rs256_jwt {
    my ( %args ) = @_;

    # key
    die "JWS: missing 'key'" if !$args{key};

    my $payload = $args{payload};
    my $alg     = 'RS256';

    my $header  = $args{extra_headers} ? { %{$args{extra_headers}} } : {};

    # serialize payload
    $payload = _payload_enc($payload);

    # encode payload
    my $b64u_payload = _encode_b64u($payload);

    # prepare header
    $header->{alg} = $alg;

    # encode header
    my $json_header = _encode_json($header);
    my $b64u_header = _encode_b64u($json_header);

    my $signer_cr = Net::ACME::Crypt::RSA->can("sign_$alg");

    my $b64u_signature = _encode_b64u( $signer_cr->("$b64u_header.$b64u_payload", $args{key}) );

    return join('.', $b64u_header, $b64u_payload, $b64u_signature);
}

#----------------------------------------------------------------------

sub _encode_json {
    my ($payload) = @_;

    #Always do a canonical encode so that we can test more easily.
    #Note that JWS itself does NOT require this.
    return JSON->new()->canonical(1)->encode($payload);
}

#Taken from Crypt::JWT
sub _payload_enc {
    my ($payload) = @_;

    if (ref($payload) =~ /^(?:HASH|ARRAY)$/) {
        $payload = _encode_json($payload);
    }
    else {
        utf8::downgrade($payload, 1) or die "JWT: payload cannot contain wide character";
    }

    return $payload;
}

sub _bigint_to_raw {
    my ($bigint) = @_;

    my $hex = $bigint->as_hex();
    $hex =~ s<\A0x><>;

    #Ensure that we have an even number of hex digits.
    if (length($hex) % 2) {
        substr($hex, 0, 0) = '0';
    }

    return pack 'H*', $hex;
}

1;
