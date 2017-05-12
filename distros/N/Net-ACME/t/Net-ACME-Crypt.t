package t::Net::ACME::Crypt;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use parent qw(
  Test::Class
);

use Test::More;
use Test::NoWarnings;

use MIME::Base64 ();
use JSON ();

use Crypt::Perl::ECDSA::Generate ();
use Crypt::Perl::RSA::Generate ();

use Net::ACME::Crypt ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_get_jwk_thumbprint : Tests(1) {
    my $ecdsa = Crypt::Perl::ECDSA::Generate::by_name('prime256v1');

    my $jwk_hr = $ecdsa->get_struct_for_public_jwk();

    is(
        Net::ACME::Crypt::get_jwk_thumbprint($jwk_hr),
        $ecdsa->get_jwk_thumbprint(Net::ACME::Crypt::JWK_THUMBPRINT_DIGEST()),
        'get_jwk_thumbprint()',
    );

    return;
}

sub test_create_jwt : Tests(6) {
    my $json = JSON->new()->canonical(1);

    my $payload = 'This is tough.';

    my %headers = ( extra => 42 );

    #----------------------------------------------------------------------
    my $rsa = Crypt::Perl::RSA::Generate::create(1024);

    my $rjwt = Net::ACME::Crypt::create_jwt(
        key => $rsa,
        payload => $payload,
        extra_headers => \%headers,
    );

    my ($hdr_b64u, $bdy_b64u, $sig_b64u) = split m<\.>, $rjwt;

    my $sig = MIME::Base64::decode_base64url($sig_b64u);

    ok(
        $rsa->verify_RS256( "$hdr_b64u.$bdy_b64u", $sig ),
        'RSA signature',
    );

    is(
        MIME::Base64::decode_base64url($bdy_b64u),
        $payload,
        'body (RSA)',
    );

    is(
        MIME::Base64::decode_base64url($hdr_b64u),
        $json->encode( { alg => 'RS256', %headers } ),
        'JSON header (RSA)',
    );

    #----------------------------------------------------------------------
    my $ecdsa = Crypt::Perl::ECDSA::Generate::by_name('prime256v1');

    my $ejwt = Net::ACME::Crypt::create_jwt(
        key => $ecdsa,
        payload => $payload,
        extra_headers => \%headers,
    );

    ($hdr_b64u, $bdy_b64u, $sig_b64u) = split m<\.>, $ejwt;

    $sig = MIME::Base64::decode_base64url($sig_b64u);

    ok(
        $ecdsa->verify_jwa( "$hdr_b64u.$bdy_b64u", $sig ),
        'ECDSA signature',
    );

    is(
        MIME::Base64::decode_base64url($bdy_b64u),
        $payload,
        'body (ECDSA)',
    );

    is(
        MIME::Base64::decode_base64url($hdr_b64u),
        $json->encode( { alg => 'ES256', %headers } ),
        'JSON header (ECDSA)',
    );

    return;
}

1;
