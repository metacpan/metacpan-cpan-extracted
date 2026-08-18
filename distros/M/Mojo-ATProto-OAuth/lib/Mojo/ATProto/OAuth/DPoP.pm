package 
    Mojo::ATProto::OAuth::DPoP;
use Mojo::Base -base, -signatures;

use Crypt::PK::ECC;
use Crypt::URandom qw/urandom/;
use Digest::SHA qw/sha256/;
use MIME::Base64 qw/encode_base64url/;
use Mojo::JSON qw/encode_json decode_json true false/;
use Mojo::Log qw//;

# DPoP (RFC 9449) proof JWTs and OAuth client-assertion JWTs for ATProto
# OAuth - a fresh P-256 keypair per session, a signed sender-constrained
# proof on every PAR/token/resource-server call. 

use constant JWT_TTL => 30;    # seconds 

use constant DEBUG => $ENV{MOJO_OAUTH_DEBUG} || 0;
my $LOG = Mojo::Log->new;

# Generates a fresh P-256 keypair for a new OAuth session/DPoP proof
# chain. Returns a Crypt::PK::ECC object (holds both private and public
# key material).
sub generate_keypair($class) {
    my $pk = Crypt::PK::ECC->new;
    $pk->generate_key('secp256r1');
    $LOG->debug('DPoP: generated a fresh P-256 keypair') if DEBUG;
    return $pk;
}

sub export_private_pem($class, $pk) {
    return $pk->export_key_pem('private');
}

sub import_private_pem($class, $pem) {
    return Crypt::PK::ECC->new(\$pem);
}

sub _b64url($data) {
    return encode_base64url($data, '');
}

sub _jwk_public($pk) {
    return decode_json($pk->export_key_jwk('public'));
}

# A cryptographically random base64url token - used for PKCE verifiers,
# the OAuth `state` parameter, and JWT `jti` values.
sub secure_random_base64 ($class, $nbytes = 32) {
    return _b64url(urandom($nbytes));
}

# SHA-256 + base64url, as used for PKCE code challenges (S256) and for
# the DPoP 'ath' (access token hash) claim.
sub s256_challenge($class, $raw) {
    return _b64url(sha256($raw));
}

# Builds and signs an ES256 JWT from an arbitrary header/claims pair -
# the shared envelope logic under both proof() and client_assertion().
sub sign_jwt($class, $pk, $header, $claims) {
    my $encoded_header  = _b64url(encode_json($header));
    my $encoded_payload = _b64url(encode_json($claims));
    my $signing_input   = "$encoded_header.$encoded_payload";
    my $sig             = $pk->sign_message_rfc7518($signing_input, 'SHA256');
    return "$signing_input." . _b64url($sig);
}

# Builds a DPoP proof JWT. Used for PAR, initial token request, and
# refresh requests (all against the Auth Server, no 'ath'/'iss' claim),
# and for resource-server (PDS) requests once a session exists
#
# %args: key (required, a Crypt::PK::ECC private key), method (required),
# url (required), nonce (optional server-issued DPoP-Nonce), access_token
# (optional, resource-server calls only), issuer (optional, resource-
# server calls only - the auth server URL, per indigo's NewHostDPoP).
sub proof($class, %args) {
    my $pk     = $args{key}    // die "proof: 'key' required\n";
    my $method = $args{method} // die "proof: 'method' required\n";
    my $url    = $args{url}    // die "proof: 'url' required\n";

    my $claims = {
        htm => uc($method),
        htu => $url,
        jti => $class->secure_random_base64(16),
        iat => time,
        exp => time + JWT_TTL,
    };
    $claims->{nonce} = $args{nonce}                             if length($args{nonce}        // '');
    $claims->{ath}   = $class->s256_challenge($args{access_token}) if length($args{access_token} // '');
    $claims->{iss}   = $args{issuer}                             if length($args{issuer}       // '');

    my $header = {
        typ => 'dpop+jwt',
        alg => 'ES256',
        jwk => _jwk_public($pk),
    };

    # Metadata only, never the signed JWT itself - it's presented over
    # the wire regardless, but there's no reason to also let it pile up
    # in logs.
    $LOG->debug(sprintf('DPoP: proof for %s %s (nonce=%s, resource-server=%s)',
        uc($method), $url, (length($args{nonce} // '') ? 'yes' : 'no'), (length($args{issuer} // '') ? 'yes' : 'no'))) if DEBUG;

    return $class->sign_jwt($pk, $header, $claims);
}

# Builds a confidential-client assertion JWT (RFC 7523), for the
# `client_assertion` form parameter on PAR/token/refresh/revocation
# requests. Not used for public clients (no key configured).
#
# %args: key (required, a Crypt::PK::ECC private key), key_id (required),
# client_id (required), audience (required - the auth server's issuer
# URL).
sub client_assertion($class, %args) {
    my $pk        = $args{key}       // die "client_assertion: 'key' required\n";
    my $key_id    = $args{key_id}    // die "client_assertion: 'key_id' required\n";
    my $client_id = $args{client_id} // die "client_assertion: 'client_id' required\n";
    my $audience  = $args{audience}  // die "client_assertion: 'audience' required\n";

    my $claims = {
        iss => $client_id,
        sub => $client_id,
        aud => $audience,
        jti => $class->secure_random_base64(16),
        iat => time,
        exp => time + JWT_TTL,
    };
    my $header = {typ => 'JWT', alg => 'ES256', kid => $key_id};

    $LOG->debug("DPoP: client_assertion for client_id=$client_id audience=$audience key_id=$key_id") if DEBUG;

    return $class->sign_jwt($pk, $header, $claims);
}

1;
