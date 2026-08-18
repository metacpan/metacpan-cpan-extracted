package 
    Mojo::ATProto::OAuth::ClientMetadata;

use Mojo::Base -base, -signatures;
use Mojo::ATProto::OAuth::DPoP qw//;
use Mojo::JSON qw/decode_json true/;
use Mojo::Log  qw//;

use constant DEBUG => $ENV{MOJO_OAUTH_DEBUG} || 0;
my $LOG = Mojo::Log->new;

# Builds the "client ID metadata document" - the JSON document ATProto
# OAuth's client-ID-metadata-document flow requires be served, byte for
# byte, at the client_id URL itself (no separate client registration
# step). 
#
# %config keys: client_id, callback_url, scopes (arrayref, must include
# 'atproto'), private_key + key_id (optional Crypt::PK::ECC keypair -
# presence makes this a confidential client; omit both for a public
# client).
sub build ($class, %config) {
    my $client_id    = $config{client_id}    // die "build: 'client_id' required\n";
    my $callback_url = $config{callback_url} // die "build: 'callback_url' required\n";
    my $scopes       = $config{scopes}       // die "build: 'scopes' required\n";

    my $doc = {
        client_id                   => $client_id,
        application_type            => 'web',
        grant_types                 => ['authorization_code', 'refresh_token'],
        scope                       => join(' ', @$scopes),
        response_types              => ['code'],
        redirect_uris               => [$callback_url],
        dpop_bound_access_tokens    => true,
        token_endpoint_auth_method  => 'none',
    };

    if (defined($config{private_key}) && defined($config{key_id})) {
        $doc->{token_endpoint_auth_method}    = 'private_key_jwt';
        $doc->{token_endpoint_auth_signing_alg} = 'ES256';
        $doc->{jwks}                           = $class->public_jwks(%config);
    }

    $LOG->debug("ClientMetadata: built document for client_id=$client_id (confidential="
        . (defined($config{private_key}) ? 'yes' : 'no') . ')') if DEBUG;

    return $doc;
}

# Returns a JWKS document ({keys => [...]}) exposing the client's public
# assertion key - only meaningful for confidential clients. Callable on
# its own (not just via build()), so a public client's missing key
# still gets a safe {keys => []} rather than dying - but build() itself
# only sets this on the *document* for a confidential client; a public
# client's document omits the `jwks` key entirely, it doesn't get an
# empty one.
sub public_jwks ($class, %config) {
    return {keys => []} unless defined($config{private_key}) && defined($config{key_id});

    my $pub = $config{private_key}->export_key_jwk('public');
    my $jwk = decode_json($pub);
    $jwk->{kid} = $config{key_id};

    return {keys => [$jwk]};
}

1;
