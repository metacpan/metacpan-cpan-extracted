## NAME

Mojo::ATProto::OAuth - ATProto OAuth client: PAR, DPoP, token exchange,
refresh, and scope upgrade

## SYNOPSIS

### Inside a Mojolicious app (async, non-blocking)

    use Mojo::ATProto::OAuth;

    my $oauth = Mojo::ATProto::OAuth->new(
        client_id    => 'https://example.com/oauth/client-metadata.json',
        callback_url => 'https://example.com/oauth/callback',
        scopes       => ['atproto', 'transition:generic'],
        store        => 'Memory' # or [ 'Pg' => 'pg-connection-string'] or ['SQLite' => 'sqlite-connection-string' ]
    );

    # kick off login (in a route handler)
    $c->render_later;
    $oauth->start_auth_flow_p(identifier => $handle_or_did)->then(sub ($redirect_url) {
        $c->redirect_to($redirect_url);
    });

    # handle the callback
    $c->render_later;
    $oauth->process_callback_p($c->req->params->to_hash)->then(sub ($session_data) {
        # $session_data->{account_did}, ->{handle}, ->{access_token}, ...
    });

    # later: refresh, or ask for more scopes
    $oauth->refresh_tokens_p($session)->then(sub ($refreshed) { ... });
    $oauth->start_scope_upgrade_p($session, ['repo:generic'])->then(sub ($redirect_url) { ... });

### Standalone - no Mojolicious app, no plugin, just this module

This module can bb used outside of a Mojolicious application, so long as there's _some_ way to send the user's browser to a URL, and _some_ way to receive the callback request's query parameters, which any web framework (Dancer, PSGI, plain CGI, a raw socket listener) or even a manual copy/paste can supply. A minimal, complete, synchronous example, using only this module plus its own shipped in-memory [store](#the-store-interface):

    use Mojo::ATProto::OAuth;

    my $oauth = Mojo::ATProto::OAuth->new_localhost(
        callback_url => 'http://127.0.0.1:8080/callback',
        store        => 'Memory',    # resolves to Mojo::ATProto::OAuth::SessionStore::Memory
    );

    # 1. get the URL to open in a browser
    my $redirect_url = $oauth->start_auth_flow(identifier => 'alice.bsky.social');
    print "Open this URL in a browser: $redirect_url\n";

    # 2. once the browser lands back on your callback URL, collect its
    #    query params however your own app does it, and hand them to
    #    process_callback as a plain hashref
    my $session = $oauth->process_callback(\%callback_query_params);

    print "Logged in as $session->{handle} ($session->{account_did})\n";

## DESCRIPTION

This module provides an implementation of ATproto flavor OAuth - so named because it incorporates just about every RFC known to man, woman, and neither, and no existing OAuth library on CPAN currently provides any of this.

The client core provides: client metadata, PAR, DPoP-sender-constrained requests, the full auth redirect/callback/token exchange flow, token refresh and the ability to upgrade scopes without a full re-authentication.

Based on Bluesky Social's from indigo `atproto/auth/oauth` package (`oauth.go`'s `ClientApp`/`ClientConfig`/`SendAuthRequest`/ `SendInitialTokenRequest`/`StartAuthFlow`/`ProcessCallback`), source at [https://github.com/bluesky-social/indigo/tree/main/atproto/auth/oauth](https://github.com/bluesky-social/indigo/tree/main/atproto/auth/oauth).

This module is framework-decoupled on purpose - it does not depend on Mojolicious's request/response cycle, sessions, or any web-framework concept beyond [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent) for HTTP and [Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise) for async. It holds only client configuration (`client_id`, callback URL, scopes, an optional confidential-client key), collaborator instances (an identity resolver, an auth-server resolver, an HTTP client), and a pluggable `store`. Every method takes and returns plain hashrefs.

Every network-calling method has a matching non-blocking `_p` ([Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise)-returning) variant, intended to run inside a Mojolicious request handler (e.g. login), where a blocking call would stall every other concurrent request on the same worker.

## ATTRIBUTES

### client\_id

(Required.) The OAuth client's `client_id` - either a real `https://` URL where ["client\_metadata"](#client_metadata) should be served, or (for a loopback client - see ["new\_localhost"](#new_localhost)) the fixed sentinel string with parameters encoded in its own query string.

### callback\_url

(Required.) The single redirect URI this client uses.

### scopes

Arrayref of default scope strings requested by ["start\_auth\_flow"](#start_auth_flow) when no per-call `scopes` opt is given. Defaults to `['atproto']`.

### private\_key

A [Crypt::PK::ECC](https://metacpan.org/pod/Crypt%3A%3APK%3A%3AECC) private key, for a confidential client. `undef` (the default) for a public client. Must be set together with ["key\_id"](#key_id) - see ["is\_confidential"](#is_confidential).

### key\_id

The key ID matching ["private\_key"](#private_key). See ["is\_confidential"](#is_confidential).

### loopback

Boolean, true for clients constructed via ["new\_localhost"](#new_localhost). Governs whether ["client\_metadata"](#client_metadata) may be called (it dies for a loopback client - there is no document to serve).

### identity

A [Mojo::ATProto::OAuth::Identity](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3AIdentity) instance, used to resolve handles and DIDs. Defaults to a fresh instance.

### resolver

A [Mojo::ATProto::OAuth::Resolver](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3AResolver) instance, used for auth-server discovery and metadata validation. Defaults to a fresh instance.

### store

A session/auth-request persistence backend - required for ["start\_auth\_flow"](#start_auth_flow), ["process\_callback"](#process_callback), ["start\_scope\_upgrade"](#start_scope_upgrade), and ["refresh\_tokens"](#refresh_tokens) (each dies immediately if unset). See ["THE STORE
INTERFACE"](#the-store-interface) below. `undef` by default.

May be set to either a store instance, or a short class-name string that resolves to one of the built-in session storage drivers, or the full class name of a driver you want to use. A driver \*must\* implement the methods listed in [Mojo::ATProto::OAuth::SessionStore](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3ASessionStore). 

### ua

A [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent) instance used for every HTTP request this module makes. Defaults to a fresh instance with a 10-second request timeout.

### log

A [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog) instance for debug logging (see ["DEBUG LOGGING"](#debug-logging)).  Defaults to a fresh instance at the level named by `MOJO_LOG_LEVEL` (`info` if unset).

## CONSTRUCTORS

### new\_localhost

    my $oauth = Mojo::ATProto::OAuth->new_localhost(
        callback_url      => $callback_url,    # required
        scopes            => \@scopes,         # optional, default ['atproto']
        ua                => $ua,              # optional
        user_agent_header => $header,          # optional
        store             => $store,           # optional
    );

Builds a client using ATProto OAuth's "loopback client" allowance for local-dev testing (ported from indigo's `NewLocalhostConfig`): rather than a real `https://` `client_id` URL serving a fetched metadata document, `client_id` is the fixed sentinel `http://localhost` with `redirect_uri`/`scope` encoded directly in its own query string.  Conformant auth servers recognize this literal `client_id` and parse those params instead of fetching anything. Always a public client (loopback clients can't declare a JWKS), so this constructor doesn't accept `private_key`/`key_id`.

The `client_id` host is the literal string `localhost` - a fixed spec sentinel, not a real address to resolve. That is a separate thing from `callback_url`, which must actually point at `127.0.0.1` (not `localhost`) for a plain-`http` redirect URI to be accepted, per the same loopback exception on the _redirect\_uri_ side. Getting the callback URL's host wrong here is not validated by this constructor (it isn't validated by indigo's `NewLocalhostConfig` either) - a real auth server will reject the resulting PAR request with an invalid `redirect_uri` instead; it's the caller's responsibility to actually run on `127.0.0.1`.

### new

    my $oauth = Mojo::ATProto::OAuth->new(
        client_id         => $client_id,       # required, in the form of https://your-site.com/client-metadata.json or something appropriate
        callback_url      => $callback_url,    # required
        scopes            => \@scopes,         # optional, default ['atproto']
        ua                => $ua,              # optional
        user_agent_header => $header,          # optional
        store             => $store,           # optional
    );

## METHODS

### is\_confidential

    my $bool = $oauth->is_confidential;

True if both ["private\_key"](#private_key) and ["key\_id"](#key_id) are set.

### client\_metadata

    my $doc = $oauth->client_metadata;

Returns the client ID metadata document (see [Mojo::ATProto::OAuth::ClientMetadata](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3AClientMetadata)) this client's `client_id` URL must serve byte for byte. Dies if called on a loopback client (see ["loopback"](#loopback)) - a loopback client's `client_id` isn't a fetchable URL at all, so calling this is a caller bug, not a runtime condition to handle gracefully.

### start\_auth\_flow

    my $redirect_url = $oauth->start_auth_flow(%opts);

High-level helper for starting a new login; resolves an identity to auth-server metadata, sends the PAR request, persists the auth request via ["store"](#store), and returns the URL the user's browser should be redirected to for approval. Requires ["store"](#store) to be configured (dies immediately otherwise).

`%opts` - exactly one of:

- `identifier` - an ATProto handle/DID, or an `https://` auth-server URL directly (this second form skips identity resolution entirely until the callback - the returned session's `account_did`/ `handle` stay unresolved until then).
- `did` + `handle` + `host_url` (all three together) - when the caller has already resolved identity itself (e.g. to make a pre-auth decision, such as reading a public repo record to pick a scope set) and there's no reason to pay for a second identity lookup here just to re-derive the same `did`/`handle`. Auth-server discovery (`host_url` -> auth-server URL) still always happens regardless of which mode is used - that's a separate step from identity resolution, not something a caller would plausibly have pre-computed.

Plus, independent of the above:

- `scopes` (optional arrayref) - overrides ["scopes"](#scopes) for just this call; falls back to the client's configured default when omitted.
- `client_state` (optional hashref) - opaque, never inspected by this module; persisted on the auth request and handed back untouched inside ["process\_callback"](#process_callback)'s result. Intended for things like a post-login redirect target that needs to survive the round trip to the auth server and back.
- `extra` (optional hashref) - the same opaque pass-through treatment as `client_state`, but conventionally used by callers for data that belongs in their own session metadata once login completes (e.g. a pre-auth decision worth remembering), rather than callback-routing data. This module draws no distinction between the two beyond "two separate opaque slots" - what each is used for is entirely up to the caller.

### start\_auth\_flow\_p

Non-blocking counterpart of ["start\_auth\_flow"](#start_auth_flow).

### process\_callback

    my $session_data = $oauth->process_callback($params);

High-level helper for completing the auth flow.  `$params` is a plain hashref of the callback request's query parameters (e.g.  `$c->req->params->to_hash` in a Mojolicious route handler).  Verifies the callback params against the persisted auth request, exchanges the authorization code for tokens, verifies the account identity, persists the resulting session via ["store"](#store), and returns the session hashref (shape below). Requires ["store"](#store) to be configured.

A hashref will be returned as follows:

    {
        account_did                     => 'did:plc:...',
        handle                          => 'alice.bsky.social',         # or undef
        session_id                      => $state,                      # the PAR 'state' value
        host_url                        => 'https://pds.example.com',
        auth_server_url                 => 'https://auth.example.com',
        auth_server_token_endpoint      => '...',
        auth_server_revocation_endpoint => '...',                       # or undef
        scopes                          => [ 'atproto', ... ],
        access_token                    => '...',
        refresh_token                   => '...',
        dpop_authserver_nonce           => '...',
        dpop_host_nonce                 => '...',
        dpop_private_key_pem            => '...',                       # PEM, see Mojo::ATProto::OAuth::DPoP
        client_state                    => $opts_client_state,          # from start_auth_flow(_p), or undef
        extra                           => $opts_extra,                 # from start_auth_flow(_p), or undef
    }

If this auth request came from ["start\_scope\_upgrade"](#start_scope_upgrade), `session_id` here is the _existing_ session's id (not a new one) and `scopes` is the union of the existing session's scopes and the newly-granted ones - see ["start\_scope\_upgrade"](#start_scope_upgrade) for why.

On success, the now-consumed auth-request row is deleted from ["store"](#store); a failure to delete it is logged and otherwise ignored (the session itself is already safely persisted at that point - a leftover auth-request row is inert, not a correctness problem), matching indigo's own log-and-continue behavior.

### process\_callback\_p

Non-blocking counterpart of ["process\_callback"](#process_callback). Rejects (rather than dying) on failure, with the same messages.

### start\_scope\_upgrade

    my $redirect_url = $oauth->start_scope_upgrade($session, \@additional_scopes);

Starts a scope-upgrade authorization for an already-known, already- verified session; seamlessly request a broader scope set without a full re-login, merging the result back into the _existing_ session (rather than replacing it) once the callback completes. `$session` is the existing stored session hashref (as returned by ["process\_callback"](#process_callback)); `$additional_scopes` is an arrayref of the newly-needed scopes.

The PAR request actually asks for the union of `$session`'s current scopes and `$additional_scopes`, so a repeated upgrade request for the same additional scope is idempotent rather than narrowing what gets asked for. Returns the redirect URL, same as ["start\_auth\_flow"](#start_auth_flow).  Requires ["store"](#store) to be configured.

### start\_scope\_upgrade\_p

Non-blocking counterpart of ["start\_scope\_upgrade"](#start_scope_upgrade).

### refresh\_tokens

    my $refreshed_session = $oauth->refresh_tokens($session);

Uses the session's stored refresh token to mint a new access token, without involving the user. Reuses the session's own DPoP key - RFC 9449 requires the same key for every proof across one authorization's lifetime, so refreshing never generates a new one.  Persists the updated session via ["store"](#store) and returns it (the same hashref, mutated in place, for convenience). Note this rotates _both_ the access token and the refresh token. Requires ["store"](#store) to be configured.

### refresh\_tokens\_p

Non-blocking counterpart of ["refresh\_tokens"](#refresh_tokens).

## LOWER-LEVEL METHODS

These are used internally by the high-level methods above, and are also exposed for callers that need finer-grained control (e.g. a caller already holding a persisted auth-request row and only needing the token exchange step). Ordinary use of this module should not need to call these directly.

### send\_auth\_request / send\_auth\_request\_p

    my $info = $oauth->send_auth_request($auth_meta, %opts);

Sends the PAR request that kicks off an authorization flow, given already-validated auth-server metadata (as returned by ["resolve\_auth\_server\_metadata" in Mojo::ATProto::OAuth::Resolver](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3AResolver#resolve_auth_server_metadata)).  `%opts`: `scopes` (optional arrayref, defaults to ["scopes"](#scopes)), `login_hint` (optional). Returns an `AuthRequestData`-equivalent hashref (`state`, `auth_server_url`, `scopes`, `pkce_verifier`, `request_uri`, `auth_server_token_endpoint`, `auth_server_revocation_endpoint`, `dpop_authserver_nonce`, `dpop_private_key_pem`) - everything a store needs to persist and later exchange for tokens via ["send\_initial\_token\_request"](#send_initial_token_request). Does not itself persist anything or resolve an identity - see ["start\_auth\_flow"](#start_auth_flow) for the full orchestration.

### send\_initial\_token\_request / send\_initial\_token\_request\_p

    my $token_resp = $oauth->send_initial_token_request($auth_code, $info);

Exchanges an authorization code for tokens. `$info` is the `AuthRequestData`- equivalent hashref from ["send\_auth\_request"](#send_auth_request) or a store lookup - reuses its DPoP keypair (RFC 9449 requires the same key for every proof tied to one authorization attempt) and PKCE verifier. Returns a `TokenResponse`-equivalent hashref (`sub`, `scope`, `access_token`, `refresh_token`) plus the final `dpop_authserver_nonce`, for the caller to persist.

## THE STORE INTERFACE

["store"](#store) is semi-duck-typed, a base class exists in [Mojo::ATProto::OAuth::SessionStore](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3ASessionStore) that will complain loudly if you subclass it without implementing the proper methods. If you write your own session store driver, you must implement the following methods:

- `get_auth_request($state)` / `get_auth_request_p($state)`
- `save_auth_request($info)` / `save_auth_request_p($info)`
- `delete_auth_request($state)` / `delete_auth_request_p($state)`
- `get_session($account_did, $session_id)` / `get_session_p($account_did, $session_id)`
- `save_session($session_data)` / `save_session_p($session_data)`
- `delete_session($account_did, $session_id)` / `delete_session_p($account_did, $session_id)`

A store only needs to implement whichever half a given caller actually uses - the synchronous methods if the caller only ever calls this module's synchronous methods (["start\_auth\_flow"](#start_auth_flow), ["process\_callback"](#process_callback), etc. - see the standalone example in ["SYNOPSIS"](#synopsis), whose `My::MemoryStore` implements only the sync half), or the `_p` methods if the caller only ever uses the async ones. A store used with both needs both halves implemented.

This distribution ships three session store drivers:

- [Mojo::ATProto::OAuth::SessionStore::Memory](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3ASessionStore%3A%3AMemory) - a plain in-process hashref store - sessions and auth requests are lost on process exit; fine for a single-process script or a test suite, not for a real deployment).
- [Mojo::ATProto::OAuth::SessionStore::SQLite](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3ASessionStore%3A%3ASQLite) - an SQLite backed session store, requires [Mojo::SQLite](https://metacpan.org/pod/Mojo%3A%3ASQLite) to be installed. 
- [Mojo::ATProto::OAuth::SessionStore::Pg](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3ASessionStore%3A%3APg) - a Postgres backed session store, requires [Mojo::Pg](https://metacpan.org/pod/Mojo%3A%3APg) to be installed.

The Memory store takes no arguments, whereas the SQLite and Pg stores do (connection strings), these can be passed during construction of the OAuth object:

    my $pg_backed = Mojo::ATProto::OAuth->new(
        client_id         => $client_id,       
        callback_url      => $callback_url,   
        scopes            => [ 'atproto account:email' ],
        store             => [ 'Pg' => 'postgresql://user:pass@host:port/dbname' ]
    );

    my $sqlite_backed = Mojo::ATProto::OAuth->new(
        client_id         => $client_id,       
        callback_url      => $callback_url,   
        scopes            => [ 'atproto account:email' ],
        store             => [ 'SQLite' => 'file:/tmp/test.db?wal_mode=1' ]
    );

## ERROR HANDLING

Synchronous methods `die` with a newline-terminated message on failure (per Perl convention - no "at FILE line N" is appended).  Asynchronous (`_p`) methods reject their returned [Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise) with the same message string instead of dying.

## DEBUG LOGGING

Two independent environment variables control logging: `MOJO_LOG_LEVEL` sets the actual [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog) level (the same variable Mojolicious itself honors for an application's own `->log`); `MOJO_OAUTH_DEBUG` (any true value) additionally enables this module's own debug-level log calls. This means that you need to set `MOJO_LOG_LEVEL` to 'debug' \*and\* set `MOJO_OAUTH_DEBUG` to a true value in order to see debug logs emitted from this module. 

Debug logs never include secret material (tokens, private keys, client assertions, PKCE verifiers) - only identifiers (DID, handle, state, session\_id) and results.

## SEE ALSO

[Mojo::ATProto::OAuth::Identity](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3AIdentity), [Mojo::ATProto::OAuth::Resolver](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3AResolver), [Mojo::ATProto::OAuth::DPoP](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3ADPoP), [Mojo::ATProto::OAuth::ClientMetadata](https://metacpan.org/pod/Mojo%3A%3AATProto%3A%3AOAuth%3A%3AClientMetadata)
