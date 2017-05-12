package Net::ACME::Crypt;

#----------------------------------------------------------------------
# This module exists because of a desire to do these computations
# in environments where a compiler may not be available.
# (Otherwise, CryptX would be ideal.)
#----------------------------------------------------------------------

use strict;
use warnings;

use JSON              ();
use MIME::Base64      ();

use Crypt::Perl::PK ();

use Net::ACME::X ();

#As per the ACME spec
use constant JWK_THUMBPRINT_DIGEST => 'sha256';

use constant JWT_RSA_SIG => 'RS256';

*parse_key = \&Crypt::Perl::PK::parse_key;

sub get_jwk_thumbprint {
    my ($jwk_hr) = @_;

    #We could generate the thumbprint directly from the JWK,
    #but there’d be more code to maintain. For now the speed hit
    #seems acceptable … ?

    my $key_obj = Crypt::Perl::PK::parse_jwk($jwk_hr);

    return $key_obj->get_jwk_thumbprint(JWK_THUMBPRINT_DIGEST());
}

*_encode_b64u = \&MIME::Base64::encode_base64url;

#expects:
#   key - object
#   payload
#   extra_headers (optional, hashref)
sub create_jwt {
    my (%args) = @_;

    if ($args{'key'}->isa('Crypt::Perl::RSA::PrivateKey')) {
        return _create_rs256_jwt(%args);
    }
    elsif ($args{'key'}->isa('Crypt::Perl::ECDSA::PrivateKey')) {
        return _create_ecc_jwt(%args);
    }

    die "Unrecognized “key”: “$args{'key'}”";
}

#----------------------------------------------------------------------

#Based on Crypt::JWT::encode_jwt(), but focused on this particular
#protocol’s needs. Note that UTF-8 might get mangled in here,
#but that’s not a problem since ACME shouldn’t require sending raw UTF-8.
#(Maybe with registration??)
sub _create_rs256_jwt {
    my ( %args ) = @_;

    my $alg = JWT_RSA_SIG();

    my $key = $args{'key'};

    my $signer_cr = sub {
        return $key->can("sign_$alg")->($key, @_);
    };

    return _create_jwt(
        %args,
        alg => $alg,
        signer_cr => $signer_cr,
    );
}

sub _create_ecc_jwt {
    my (%args) = @_;

    my $key = $args{'key'};

    my $signer_cr = sub {
        return $key->sign_jwa(@_);
    };

    return _create_jwt(
        %args,
        alg => $key->get_jwa_alg(),
        signer_cr => $signer_cr,
    );
}

sub _create_jwt {
    my ( %args ) = @_;

    # key
    die "JWS: missing 'key'" if !$args{key};

    my $payload = $args{payload};
    my $alg     = $args{'alg'};

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

    my $signer_cr = $args{'signer_cr'};

    my $b64u_signature = _encode_b64u( $signer_cr->("$b64u_header.$b64u_payload", $args{key}) );

    return join('.', $b64u_header, $b64u_payload, $b64u_signature);
}

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

1;
