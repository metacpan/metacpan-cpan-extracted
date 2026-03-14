# Net-Async-Zitadel

[![CPAN Version](https://img.shields.io/cpan/v/Net-Async-Zitadel.svg)](https://metacpan.org/pod/Net::Async::Zitadel)
[![License](https://img.shields.io/cpan/l/Net-Async-Zitadel.svg)](https://metacpan.org/pod/Net::Async::Zitadel)

Async [ZITADEL](https://zitadel.com/) client built on [IO::Async](https://metacpan.org/pod/IO::Async)
and [Net::Async::HTTP](https://metacpan.org/pod/Net::Async::HTTP).  All methods return
[Future](https://metacpan.org/pod/Future) objects (`_f` suffix convention).

The API surface mirrors [WWW::Zitadel](https://metacpan.org/pod/WWW::Zitadel) exactly — every
synchronous method has an async `_f` twin.

## Installation

```bash
cpanm Net::Async::Zitadel
```

For local development:

```bash
cpanm --installdeps .
prove -lr t
```

## Quickstart

### Unified entrypoint (`Net::Async::Zitadel`)

```perl
use IO::Async::Loop;
use Net::Async::Zitadel;

my $loop = IO::Async::Loop->new;

my $z = Net::Async::Zitadel->new(
    issuer => 'https://zitadel.example.com',
    token  => $ENV{ZITADEL_PAT},  # only needed for management calls
);
$loop->add($z);

# Async token verification
my $claims = $z->oidc->verify_token_f($jwt, audience => 'my-client-id')->get;

# Async management call
my $projects = $z->management->list_projects_f(limit => 20)->get;
```

### OIDC client

```perl
use IO::Async::Loop;
use Net::Async::Zitadel::OIDC;
use Net::Async::HTTP;

my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new;
$loop->add($http);

my $oidc = Net::Async::Zitadel::OIDC->new(
    issuer => 'https://zitadel.example.com',
    http   => $http,
);

# Discovery metadata (cached 1h by default)
my $doc = $oidc->discovery_f->get;

# Verify JWT (auto-retries with fresh JWKS on key rotation)
my $claims = $oidc->verify_token_f($jwt, audience => 'my-client-id')->get;

# UserInfo
my $profile = $oidc->userinfo_f($access_token)->get;

# Client credentials grant
my $token = $oidc->client_credentials_token_f(
    client_id     => $client_id,
    client_secret => $client_secret,
    scope         => 'openid profile',
)->get;

# Refresh token grant
my $refreshed = $oidc->refresh_token_f(
    $refresh_token,
    client_id     => $client_id,
    client_secret => $client_secret,
)->get;
```

### OIDC caching

JWKS and discovery documents are cached with configurable TTLs:

```perl
my $oidc = Net::Async::Zitadel::OIDC->new(
    issuer        => 'https://zitadel.example.com',
    http          => $http,
    discovery_ttl => 3600,   # seconds; 0 = no cache
    jwks_ttl      => 300,    # seconds; 0 = no cache
);

# Force a JWKS refresh (e.g. after suspected key rotation)
$oidc->jwks_f(force_refresh => 1)->get;
```

Concurrent JWKS refresh requests are automatically coalesced — if a refresh is
already in-flight, subsequent callers receive the same Future rather than
triggering a second HTTP request.

### Management API client

```perl
use IO::Async::Loop;
use Net::Async::Zitadel;

my $loop = IO::Async::Loop->new;
my $z = Net::Async::Zitadel->new(
    issuer => 'https://zitadel.example.com',
    token  => $ENV{ZITADEL_PAT},
);
$loop->add($z);

my $mgmt = $z->management;

# Human users
my $user = $mgmt->create_human_user_f(
    user_name  => 'alice',
    first_name => 'Alice',
    last_name  => 'Smith',
    email      => 'alice@example.com',
)->get;
$mgmt->set_password_f($user->{userId}, password => 'ch@ngeMe!')->get;

# Service users + machine keys
my $svc = $mgmt->create_service_user_f(
    user_name => 'ci-bot',
    name      => 'CI Bot',
)->get;
my $key = $mgmt->add_machine_key_f($svc->{userId})->get;

# Projects and OIDC apps
my $project = $mgmt->create_project_f(name => 'My Project')->get;
my $app = $mgmt->create_oidc_app_f(
    $project->{id},
    name          => 'web-client',
    redirect_uris => ['https://app.example.com/callback'],
)->get;

# Roles and grants
$mgmt->add_project_role_f($project->{id}, role_key => 'admin')->get;
$mgmt->create_user_grant_f(
    user_id    => $user->{userId},
    project_id => $project->{id},
    role_keys  => ['admin'],
)->get;

# Identity Providers
my $idp = $mgmt->create_oidc_idp_f(
    name          => 'Google',
    client_id     => $google_client_id,
    client_secret => $google_client_secret,
    issuer        => 'https://accounts.google.com',
)->get;
$mgmt->activate_idp_f($idp->{idp}{id})->get;
```

### Composing Futures

Because all methods return Futures you can chain and fan-out operations:

```perl
# Parallel: fetch user and project list at the same time
Future->needs_all(
    $mgmt->get_user_f($user_id),
    $mgmt->list_projects_f,
)->then(sub {
    my ($user, $projects) = @_;
    # both resolved
})->get;

# Sequential chain
$mgmt->create_project_f(name => 'Demo')
    ->then(sub {
        my ($project) = @_;
        $mgmt->create_oidc_app_f(
            $project->{id},
            name          => 'demo-app',
            redirect_uris => ['https://demo.example.com/cb'],
        );
    })->get;
```

## Authentication

- OIDC methods use normal OIDC flows; no Management PAT is needed.
- Management API methods require a ZITADEL Personal Access Token (PAT).
- The token is sent as `Authorization: Bearer <token>`.

## Error handling

All errors are returned as failed Futures (or thrown synchronously for
validation errors before any HTTP call).  Failures are
`Net::Async::Zitadel::Error` subclass objects that stringify to their message:

```perl
use Net::Async::Zitadel::Error;

$mgmt->get_user_f($user_id)->catch(sub {
    my ($err) = @_;
    if (ref $err && $err->isa('Net::Async::Zitadel::Error::API')) {
        warn "HTTP: ", $err->http_status, "\n";
        warn "Msg:  ", $err->api_message,  "\n";
    }
    Future->fail($err);  # re-throw
})->get;
```

Three exception types:

| Class | When raised |
|---|---|
| `Net::Async::Zitadel::Error::Validation` | Missing/invalid arguments, empty issuer/base_url |
| `Net::Async::Zitadel::Error::Network` | OIDC endpoint HTTP failures |
| `Net::Async::Zitadel::Error::API` | Management API non-2xx responses |

## Testing

The offline test suite covers all modules without needing a real ZITADEL instance:

```bash
prove -lr t
```

To run live integration tests against a real ZITADEL instance:

```bash
ZITADEL_ISSUER='https://your-zitadel.example.com' \
ZITADEL_TOKEN='your-pat' \
ZITADEL_CLIENT_ID='...' \
ZITADEL_CLIENT_SECRET='...' \
prove -lv t/10-integration.t
```

## Examples

Ready-to-run examples in `examples/`:

```bash
# Verify a JWT
ZITADEL_ISSUER='https://your-zitadel.example.com' \
ZITADEL_TOKEN='eyJ...' \
perl examples/verify_token.pl

# Obtain a client credentials token
ZITADEL_ISSUER='https://your-zitadel.example.com' \
ZITADEL_CLIENT_ID='...' \
ZITADEL_CLIENT_SECRET='...' \
perl examples/client_credentials.pl

# Async user/project management
ZITADEL_ISSUER='https://your-zitadel.example.com' \
ZITADEL_TOKEN='...' \
ZITADEL_USER_ID='...' \
perl examples/manage_users.pl
```

## API Overview

### `Net::Async::Zitadel::OIDC`

- `discovery_f`
- `jwks_f(force_refresh => 1?)`
- `verify_token_f($token, %opts)`
- `userinfo_f($access_token)`
- `introspect_f($token, client_id => ..., client_secret => ...)`
- `token_f(grant_type => ..., %form)`
- `client_credentials_token_f(client_id => ..., client_secret => ...)`
- `refresh_token_f($refresh_token, %form)`
- `exchange_authorization_code_f(code => ..., redirect_uri => ...)`

### `Net::Async::Zitadel::Management`

- Users: `list_users_f`, `get_user_f`, `create_human_user_f`, `update_user_f`,
  `deactivate_user_f`, `reactivate_user_f`, `delete_user_f`
- Passwords: `set_password_f`, `request_password_reset_f`
- Metadata: `set_user_metadata_f`, `get_user_metadata_f`, `list_user_metadata_f`
- Service users: `create_service_user_f`, `list_service_users_f`,
  `get_service_user_f`, `delete_service_user_f`
- Machine keys: `add_machine_key_f`, `list_machine_keys_f`, `remove_machine_key_f`
- Projects: `list_projects_f`, `get_project_f`, `create_project_f`,
  `update_project_f`, `delete_project_f`
- Apps: `list_apps_f`, `get_app_f`, `create_oidc_app_f`, `update_oidc_app_f`,
  `delete_app_f`
- Orgs: `get_org_f`, `create_org_f`, `list_orgs_f`, `update_org_f`, `deactivate_org_f`
- Roles: `add_project_role_f`, `list_project_roles_f`
- Grants: `create_user_grant_f`, `list_user_grants_f`
- IDPs: `create_oidc_idp_f`, `list_idps_f`, `get_idp_f`, `update_idp_f`,
  `delete_idp_f`, `activate_idp_f`, `deactivate_idp_f`

### `Net::Async::Zitadel::Error`

- `Net::Async::Zitadel::Error` (base, stringifies to `message`)
- `Net::Async::Zitadel::Error::Validation`
- `Net::Async::Zitadel::Error::Network`
- `Net::Async::Zitadel::Error::API` (adds `http_status`, `api_message`)

## See also

- [WWW::Zitadel](https://metacpan.org/pod/WWW::Zitadel) — synchronous twin distribution
- [Net::Async::HTTP](https://metacpan.org/pod/Net::Async::HTTP)
- [IO::Async](https://metacpan.org/pod/IO::Async)
- [Future](https://metacpan.org/pod/Future)
