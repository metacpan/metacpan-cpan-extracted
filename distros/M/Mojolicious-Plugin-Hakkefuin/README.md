# Mojolicious::Plugin::Hakkefuin
[![](https://github.com/CellBIS/mojo-hakkefuin/workflows/linux/badge.svg)](https://github.com/CellBIS/mojo-hakkefuin/actions) [![](https://github.com/CellBIS/mojo-hakkefuin/workflows/macos/badge.svg)](https://github.com/CellBIS/mojo-hakkefuin/actions) [![](https://github.com/CellBIS/mojo-hakkefuin/workflows/windows/badge.svg)](https://github.com/CellBIS/mojo-hakkefuin/actions)

Mojolicious plugin for minimalistic authentication. It pairs an HMAC cookie with a server-side CSRF token stored in the database, keeps expirations enforceable from the backend, and ships an optional lock/unlock flow for "screen lock" style behavior.

## Features

- Database-backed auth cookie + CSRF pairing with automatic rotation helpers.
- Built-in SQLite (default), MariaDB/MySQL, and PostgreSQL backends with automailes untic table creation; SQL fder `migrations/` are only written when you supply `table_config`.
- Optional lock/unlock flow with a dedicated lock cookie and callbacks.
- Customizable helper/stash prefixes, cookie lifetimes, and cookie attributes.
- Session manager that supports `max-age` while reusing a shared sessions object per app.

## Installation

```bash
curl -L https://cpanmin.us | perl - -M -n https://github.com/CellBIS/mojo-hakkefuin.git
# or from a clone
cpanm .
```

Using [Perlbrew](http://perlbrew.pl) or another local perl is recommended.

## Quick start

Mojolicious Lite:

```perl
use Mojolicious::Lite;

plugin 'Hakkefuin' => {
  'helper.prefix' => 'fuin',
  'stash.prefix'  => 'fuin',
  via             => 'sqlite',                 # or mariadb / pg
  dir             => 'migrations',             # where migration/sqlite db lives
  dsn             => 'postgresql://user:pass@localhost/mhf', # required for pg/mariadb
  'c.time'        => '1w',                     # auth cookie TTL
  's.time'        => '1w',                     # session TTL
  'cl.time'       => '60m',                    # lock cookie TTL
  'lock'          => 1,                        # enable lock/unlock helpers
};

post '/login' => sub {
  my $c   = shift;
  my $id  = $c->param('user');
  my $res = $c->fuin_signin($id);           # stores cookie+csrf in DB
  return $c->render(status => $res->{code}, json => $res);
};

under sub {
  my $c    = shift;
  my $auth = $c->fuin_has_auth;             # checks cookie+csrf and stashes ids
  return $c->render(status => 423, json => $auth) if $auth->{result} == 2;
  return $c->render(status => 401, text => 'Unauthorized') unless $auth->{result} == 1;
  $c->fuin_csrf;                            # ensure token is in session/header
  return 1;
};

get '/me' => sub {
  my $c = shift;
  return $c->render(json => { user => $c->stash('fuin.identify') });
};

# Per-request override of cookie/session TTLs
post '/login-custom' => sub {
  my $c    = shift;
  my $opts = {
    c_time => $c->param('c_time') // '2h',  # auth cookie TTL
    s_time => $c->param('s_time') // '30m', # session TTL
  };
  my $res = $c->fuin_signin($c->param('user'), $opts);
  return $c->render(status => $res->{code}, json => $res);
};

get '/auth-update-custom' => sub {
  my $c        = shift;
  my $backend  = $c->stash('fuin.backend-id');
  my $res      = $c->fuin_auth_update($backend, {c_time => '45m', s_time => '20m'});
  my $httpcode = $res->{code} // 500;
  return $c->render(status => $httpcode, json => $res);
};

app->start;
```

Mojolicious (non-Lite) looks the same inside `startup`, e.g. `$self->plugin('Hakkefuin' => { ... });`.

On startup the plugin will:

- Ensure the auth table exists on startup. A migration SQL file under `dir` is only written when you pass custom `table_config` (otherwise tables are created directly in the database).
- Attach a shared `Mojo::Hakkefuin::Sessions` instance so session cookies get `max-age` derived from `s.time`.
- Register helpers using your chosen `helper.prefix`.

## Configuration

All options are optional; defaults are shown in parentheses.

- `helper.prefix` (`mhf`): prefix for helpers (`<prefix>_signin`, `<prefix>_csrf`, etc.).
- `stash.prefix` (`mhf`): prefix for stash keys set by `*_has_auth` (`mhf.backend-id`, `mhf.identify`, `mhf.lock_state`).
- `via` (`sqlite`): backend driver: `sqlite`, `mariadb`, or `pg`. `dsn` is required for `mariadb`/`pg`.
- `dsn` (none): DB connection string, e.g. `mariadb://user:pass@db:3306/mhf` or `postgresql://user:pass@localhost/mhf`.
- `dir` (`migrations`): directory for migration SQL and SQLite DB file.
- `csrf.name` (`mhf_csrf_token`): session/header key for the CSRF token.
- `c.time` (`1w`): auth cookie lifetime; also used to set DB expiration.
- `s.time` (`1w`): session cookie lifetime; also sets `max-age` when supported by the browser.
- `cl.time` (`60m`): lock cookie lifetime when `lock` is enabled.
- `lock` (`1`): enable lock/unlock helpers and cookies.
- `cookies` (`{name => 'clg', path => '/', httponly => 1, secure => 0}`): override auth cookie attributes; `expires`/`max_age` are computed from `c.time`.
- `cookies_lock` (`{name => 'clglc', path => '/', httponly => 1, secure => 0}`): override lock cookie attributes; `expires`/`max_age` come from `cl.time`.
- `session` (`{cookie_name => '_mhf', cookie_path => '/', secure => 0}`): base options passed to `Mojo::Hakkefuin::Sessions`; `default_expiration` is derived from `s.time`.
- `callback` (`{lock => sub {}, unlock => sub {}}`): optional coderefs called after lock/unlock operations.

## Helper reference

- `<prefix>_signin($identify)`: create auth cookie + CSRF, store in DB with expiration derived from `c.time`.
- `<prefix>_signout($identify)`: clear session and cookies, remove DB entry.
- `<prefix>_has_auth`: check cookie + CSRF against the backend. Returns `{result => 1}` on success, `{result => 2}` when locked, `{result => 3}` when the CSRF token mismatches, or `{result => 0}` when missing/expired. Stashes backend id, identify, and lock state using `stash.prefix`.
- `<prefix>_auth_update($identify)`: rotate cookie and CSRF token for an active session.
- `<prefix>_lock` / `<prefix>_unlock`: issue or clear the lock cookie when `lock` is enabled.
- `<prefix>_csrf`: ensure a CSRF token exists in the session/response headers.
- `<prefix>_csrf_get`, `<prefix>_csrf_val`, `<prefix>_csrf_regen`: read, validate, or regenerate the CSRF token.
- `<prefix>_backend`: access the underlying backend object (e.g. for inspecting connection status).

### Lock/unlock flow

Call `<prefix>_lock` after `*_has_auth` passes to mark the session locked; a lock cookie is issued and the backend row is marked. Use `<prefix>_unlock` to clear the lock. When locked, `*_has_auth` returns `{result => 2, code => 423, lock_cookie => 0|1}` so you can respond with HTTP 423 or show a lock screen.

## Backend notes

- SQLite stores data in `dir/mhf_sqlite.db`; a `dir/mhf_sqlite.sql` file is written only when `table_config` is provided. Indexes are created in the database at startup.
- MariaDB/MySQL and PostgreSQL create the tables (and indexes) directly in the database at startup; migration SQL is not dumped to `dir` unless you provide `table_config`.
- The plugin calls `check_migration` on startup, so the table is created automatically when credentials are valid.
