package Test::Crypt;

#----------------------------------------------------------------------
# To avoid needing Crypt::JWT for tests.
#----------------------------------------------------------------------

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use Carp;

use Call::Context ();
use JSON ();
use MIME::Base64 ();

use Crypt::Perl::PK ();

#A stripped-down copy of Crypt::JWT::decode_jwt() that only knows
#how to do RSA SHA256, “full” form. (Copied & adapted from Net::ACME.)
sub decode_acme2_jwt {
    my ($token, $key_text) = @_;

    Call::Context::must_be_list();

    my $token_hr = JSON::decode_json($token);

    my $signed = "$token_hr->{'protected'}.$token_hr->{'payload'}";
    my $signature = MIME::Base64::decode_base64url($token_hr->{'signature'});

    verify( $key_text, $signed, $signature );

    my ($header, $payload) = @{$token_hr}{'protected', 'payload'};

    $_ = MIME::Base64::decode_base64url($_) for ($header, $payload);

    $payload = JSON::decode_json($payload) if $payload =~ m<\A[ \[ \{ ]>x;

    return JSON::decode_json($header), $payload;
}

sub decode_acme2_jwt_extract_key {
    my ($token) = @_;

    my $token_hr = JSON::decode_json($token);

    my $header_hr = JSON::decode_json( MIME::Base64::decode_base64url($token_hr->{'protected'}) );

    my $key_obj = Crypt::Perl::PK::parse_jwk( $header_hr->{'jwk'} );

    my $is_ecc = $key_obj->isa('Crypt::Perl::ECDSA::PublicKey');
    my $to_pem_method = $is_ecc ? 'to_pem_with_curve_name' : 'to_pem';

    return ($key_obj, decode_acme2_jwt($token, $key_obj->$to_pem_method()));
}

sub verify {
    my ($key, $message, $signature) = @_;

    confess "No key!" if !$key;

    my $kobj = Crypt::Perl::PK::parse_key($key);

    my $is_ecc = $kobj->isa('Crypt::Perl::ECDSA::PublicKey');
    my $verify_method = $is_ecc ? 'verify_jwa' : 'verify_RS256';

    die "JWT verification failed!" if !$kobj->$verify_method($message, $signature);

    return;
}

sub decode_eab_jws {
    my ($jws_hr, $mac_key_b64u) = @_;

    require Digest::SHA;

    my $header_hr = JSON::decode_json(
        MIME::Base64::decode_base64url( $jws_hr->{'protected'} )
    );

    my $payload = MIME::Base64::decode_base64url( $jws_hr->{'payload'} );
    my $payload_hr = JSON::decode_json($payload);

    my $mac_key = MIME::Base64::decode_base64url($mac_key_b64u);

    my %hmac_funcs = (
        HS256 => \&Digest::SHA::hmac_sha256,
        HS384 => \&Digest::SHA::hmac_sha384,
        HS512 => \&Digest::SHA::hmac_sha512,
    );

    my $hmac_cr = $hmac_funcs{ $header_hr->{'alg'} }
        or die "Unknown EAB alg: $header_hr->{'alg'}";

    my $signing_input = "$jws_hr->{'protected'}.$jws_hr->{'payload'}";
    my $expected_sig = $hmac_cr->($signing_input, $mac_key);
    my $actual_sig = MIME::Base64::decode_base64url( $jws_hr->{'signature'} );

    die "EAB HMAC verification failed!" if $expected_sig ne $actual_sig;

    return ($header_hr, $payload_hr);
}

1;
