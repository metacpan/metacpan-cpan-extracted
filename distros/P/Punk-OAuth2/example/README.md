# Punk::OAuth2 example: a working authorization server

`oauth-server.psgi` is a complete, runnable OAuth2 / OIDC authorization
server built on Punk. It mounts:

- the authorization server at `/oauth`
  (`/authorize`, `/token`, `/revoke`, `/introspect`, `/jwks.json`),
- the RFC 8414 metadata at `/.well-known/oauth-authorization-server`,
- a tiny cookie-session login and auto-approving consent,
- a Bearer-protected resource at `/api/me` (scope `read`), guarded by a
  checker that validates the server's own tokens.

A demo client is registered on boot: `demo-client` / `demo-secret`,
redirect `http://localhost:5000/callback`, scopes `read write`.

This is a demonstration: the login accepts any username and consent is
auto-approved. Do not deploy it as-is.

## Run it

    hyperman example/oauth-server.psgi        # http://localhost:5000

Then open <http://localhost:5000/> for the overview page, or drive it
with curl below.

## Client-credentials grant (simplest)

    TOKEN=$(curl -s -u demo-client:demo-secret \
      -d grant_type=client_credentials -d scope=read \
      http://localhost:5000/oauth/token \
      | perl -MFile::Raw::JSON=file_json_decode -0777 \
             -ne 'print file_json_decode($_)->{access_token}')

    curl -s -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/me
    # {"subject":"demo-client","client_id":"demo-client","scope":"read",...}

## Introspection and revocation

    curl -s -u demo-client:demo-secret -d token=$TOKEN \
      http://localhost:5000/oauth/introspect
    # {"active":true,"client_id":"demo-client",...}

    curl -s -u demo-client:demo-secret -d token=$REFRESH \
      http://localhost:5000/oauth/revoke        # always 200

## Authorization-code + PKCE (the browser flow)

1. Build a PKCE verifier and challenge:

        VERIFIER=$(perl -MCrypt::JWS=b64url,random_bytes -e 'print b64url(random_bytes(32))')
        CHALLENGE=$(perl -MCrypt::JWS=b64url,sha256 -e 'print b64url(sha256(shift))' "$VERIFIER")

2. Open the authorize URL in a browser (you will be asked to log in -
   any username works):

        http://localhost:5000/oauth/authorize?response_type=code
          &client_id=demo-client
          &redirect_uri=http://localhost:5000/callback
          &scope=read&state=demo
          &code_challenge=$CHALLENGE&code_challenge_method=S256

   After login you are redirected to
   `http://localhost:5000/callback?code=...&state=demo&iss=...`.
   Copy the `code`.

3. Exchange the code for tokens:

        curl -s -u demo-client:demo-secret \
          -d grant_type=authorization_code -d code=$CODE \
          --data-urlencode redirect_uri=http://localhost:5000/callback \
          -d code_verifier=$VERIFIER \
          http://localhost:5000/oauth/token

   The `access_token` is an ES256 JWT (RFC 9068 `at+jwt`); `/api/me`
   accepts it, and the `subject` is the username you logged in as.

## Metadata and keys

    curl -s http://localhost:5000/.well-known/oauth-authorization-server
    curl -s http://localhost:5000/oauth/jwks.json

## Registering more clients

The store is a SQLite file (`/tmp/oauth-demo.db` by default, set
`OAUTH_DEMO_DB`). Register a client from Perl:

    use Punk::OAuth2::Server::Store;
    my $store = Punk::OAuth2::Server::Store->new(
        dsn => 'dbi:SQLite:dbname=/tmp/oauth-demo.db');
    $store->client_put({
        client_id     => 'my-app',
        secret        => 'my-secret',        # stored as a SHA-256 digest
        redirect_uris => ['https://my-app/callback'],
        scopes        => 'read write',
    });

## Environment

- `OAUTH_DEMO_ISSUER` - the issuer URL (default `http://localhost:5000`)
- `OAUTH_DEMO_DB` - the SQLite path (default `/tmp/oauth-demo.db`)
- `OAUTH_DEMO_SESSION_KEY` - the session signing key
