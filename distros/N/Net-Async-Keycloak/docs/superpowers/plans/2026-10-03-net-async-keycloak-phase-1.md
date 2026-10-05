# Net::Async::Keycloak Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Den Async-Zwilling von `WWW::Keycloak` Phase 1 bauen: dieselbe Fassade, dieselben Teile, jede Methode als `_f` mit Future, auf IO::Async und Net::Async::HTTP.

**Architecture:** `Net::Async::Keycloak` ist ein Moo-`IO::Async::Notifier` mit einem `Net::Async::HTTP` als Kind. Anfragen baut und Antworten liest `WWW::Keycloak::Role::HTTP` (`build_request`, `read_response`); die Rolle `Net::Async::Keycloak::Role::HTTP` sendet nur und liefert Futures, und weil sie vor der Sync-Rolle eingebunden wird, gewinnen ihre Fehlerklassen. Die `ensure_*_f`-Methoden vergleichen mit `WWW::Keycloak::Diff`. Fehlerklassen erben von den Sync-Klassen.

**Tech Stack:** Perl 5.20+, Moo, IO::Async, Net::Async::HTTP, Future, Future::AsyncAwait, Crypt::JWT, WWW::Keycloak. Dist::Zilla mit `[@Author::GETTY]`.

**Spec:** `p5-www-keycloak/docs/superpowers/specs/2026-10-02-www-keycloak-design.md`, Abschnitte 9 und 12 (Entscheidungen 2026-10-03).

## Ausführung

Ausgeführt am 2026-10-03 (`c83cb2b` bis `c2b6d73`). Ein unabhängiger Review hat danach
Fehler im Zusammenspiel gleichzeitiger Aufrufe gefunden (Abbruch eines Aufrufers traf den
gemeinsamen Login, ungeteiltes Nachladen der Schlüssel, Fehler ohne Loop als String), die in
einem eigenen Commit mit Tests in `t/70-async.t` behoben sind. Maßgeblich ist das Repo.

## Stand des Codes in diesem Plan

Der Code ist am 2026-10-03 als Prototyp gelaufen: `prove -lr t` mit 46 Tests grün, `dzil test` grün, `t/90-live-keycloak.t` grün gegen Keycloak 26.8.0. Die Tests in `t/20` bis `t/60` und `t/90` sind die von `WWW::Keycloak`, maschinell auf `_f->get` umgeschrieben und gegen dasselbe nachgebaute Keycloak gefahren; damit prüfen beide Clients dieselben Erwartungen.

`WWW::Keycloak` muss den Commit `fdaf12d` („Split request building and response reading from sending“) enthalten. Bis `WWW-Keycloak` installiert ist, läuft alles mit `PERL5LIB=~/dev/p5-www-keycloak/lib`.

## Global Constraints

- Jede öffentliche Methode heißt wie in `WWW::Keycloak` plus `_f` und liefert eine Future desselben Ergebnisses. Hier wird keine API erfunden, die der Sync-Client nicht hat.
- Keine Bibliothek ruft `->get` auf einer Future; nichts blockiert die Loop.
- Anfragen bauen und Antworten lesen ausschließlich über `build_request`/`read_response` aus `WWW::Keycloak::Role::HTTP`; der Vergleich in `ensure_*_f` ausschließlich über `WWW::Keycloak::Diff`.
- Klassen binden `Net::Async::Keycloak::Role::HTTP` **vor** `WWW::Keycloak::Role::HTTP` ein (bei Moo gewinnt die erste Rolle still), damit die Fehler dieser Dist geworfen werden.
- `IO::Async::Notifier->new` reicht jeden Konstruktor-Schlüssel an `configure` weiter: eigene Attribute in `FOREIGNBUILDARGS` entfernen; `BUILDARGS` selbst schreiben, weil der Elternteil keine Moo-Klasse ist.
- Ein Paket pro Datei, `# ABSTRACT:` und `our $VERSION = '0.001';` überall; `.t`-Dateien mit Shebang und `done_testing;`; `prove -lr t`.
- **Niemand außer `net-async-keycloak-release-manager` committet.**

## Review Focus

1. **Mehrere Aufrufe brauchen gleichzeitig ein Admin-Token.** Erwartet: ein Login, alle bekommen dasselbe Token. Test `callers waiting for a token share one login` in `t/70-async.t` (Aufgabe 3).
2. **Ein Login schlägt fehl.** Erwartet: Der nächste Aufruf versucht es neu, statt den alten Fehler zu erben. Test `a failed login does not stick` in `t/70-async.t` (Aufgabe 3).
3. **Keycloak ist nicht erreichbar.** Erwartet: eine fehlgeschlagene Future mit `Net::Async::Keycloak::Error::Network`, die die Anfrage nennt. Test `no answer at all` in `t/20-errors.t` (Aufgabe 3).
4. **Code für den Sync-Client fängt Fehler des Async-Clients.** Erwartet: Jeder Fehler ist auch die passende `WWW::Keycloak::Error`-Klasse. Test `classes and stringification` in `t/20-errors.t` (Aufgabe 3).
5. **Ein Keycloak-Neustart mitten in einem Setup.** Erwartet wie im Sync-Client: genau ein neuer Login. Test `a refused token is renewed once` in `t/50-admin.t` (Aufgabe 3).

---

### Task 1: Fehler, HTTP-Rolle, Auth

**Files:**
- Modify: `cpanfile` (ganz ersetzen)
- Create: `lib/Net/Async/Keycloak/Error.pm`, `lib/Net/Async/Keycloak/Error/Validation.pm`, `lib/Net/Async/Keycloak/Error/Network.pm`, `lib/Net/Async/Keycloak/Error/API.pm`
- Create: `lib/Net/Async/Keycloak/Role/HTTP.pm`, `lib/Net/Async/Keycloak/Auth.pm`
- Create: `t/lib/FakeKeycloak.pm` (Kopie aus `p5-www-keycloak`), `t/lib/FakeHTTP.pm`
- Test: `t/30-auth.t`

**Interfaces:**
- Produces: `Net::Async::Keycloak::Error::*` (je auch `WWW::Keycloak::Error::*` und `Net::Async::Keycloak::Error`); Rolle mit `send_request_f( $method, $url, %arg )` → Future von `{ status, data, location }`, `fail_validation($msg)`, `api_error_class`, `network_error_class`, `validation_error_class`; `Net::Async::Keycloak::Auth->new( http =>, token_endpoint =>, ... )` mit `token_f`, `invalidate`, `renewable`. `FakeHTTP->new( fake => $fake_keycloak )->do_request( request => $req )` → erledigte Future.

- [ ] **Step 1: `cpanfile` ersetzen, installieren**

`cpanfile`:

```perl
requires 'perl', '5.020';
requires 'Crypt::JWT';
requires 'Future';
requires 'Future::AsyncAwait';
requires 'IO::Async';
requires 'IO::Async::SSL';
requires 'JSON::MaybeXS';
requires 'Moo';
requires 'Net::Async::HTTP';
requires 'Type::Tiny';
requires 'URI';
requires 'WWW::Keycloak', '0.001';
requires 'namespace::autoclean', '0.16';

on test => sub {
    requires 'CryptX';
    requires 'HTTP::Message';
    requires 'Test::More', '0.96';
};
```

- [ ] **Step 2: Test-Hilfen**

`t/lib/FakeKeycloak.pm` aus `~/dev/p5-www-keycloak/t/lib/` kopieren, unverändert. Dazu:

`t/lib/FakeHTTP.pm`:

```perl
package FakeHTTP;

# What Net::Async::Keycloak needs from Net::Async::HTTP, answered by the
# in-memory Keycloak of t/lib/FakeKeycloak.pm (shared with WWW::Keycloak's
# tests) as already completed futures. No loop is needed.

use strict;
use warnings;
use Future;
use FakeKeycloak;

sub new {
  my ( $class, %arg ) = @_;
  return bless { fake => $arg{fake} || FakeKeycloak->new(%arg) }, $class;
}

sub fake { $_[0]{fake} }

sub do_request {
  my ( $self, %arg ) = @_;
  return Future->done( $self->{fake}->request( $arg{request} ) );
}

1;
```

- [ ] **Step 3: Test schreiben und scheitern sehen**

`t/30-auth.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use FakeHTTP;
use Net::Async::Keycloak::Auth;

my $clock = 1_000_000;
my $fake  = FakeKeycloak->new( expires_in => 60 );
my $http = FakeHTTP->new( fake => $fake );

sub auth {
  return Net::Async::Keycloak::Auth->new( http => $http, token_endpoint => $fake->base.'/realms/master/protocol/openid-connect/token', now => sub { $clock }, @_ );
}

subtest 'password login, kept, renewed' => sub {
  @{ $fake->logins } = ();
  my $auth  = auth( username => 'admin', password => 'admin' );
  my $first = $auth->token_f->get;
  like( $first, qr/\Aat-/, 'a token' );
  is( $fake->logins->[0]{grant_type}, 'password', 'by password grant' );
  is( $fake->logins->[0]{client_id}, 'admin-cli', 'through admin-cli' );
  $clock += 29;
  is( $auth->token_f->get, $first, 'kept while more than the margin is left' );
  is( scalar @{ $fake->logins }, 1, 'without asking again' );
  $clock += 1;
  my $second = $auth->token_f->get;
  isnt( $second, $first, 'renewed 30 seconds before expiry' );
  is( $fake->logins->[1]{grant_type}, 'refresh_token', 'with the refresh token' );
};

subtest 'refresh refused: log in again' => sub {
  @{ $fake->logins } = ();
  my $auth = auth( username => 'admin', password => 'admin' );
  $auth->token_f->get;
  $fake->forget_tokens;
  $clock += 60;
  ok( $auth->token_f->get, 'still a token' );
  is_deeply( [ map { $_->{grant_type} } @{ $fake->logins } ], [qw( password refresh_token password )], 'refresh failed, password login followed' );
};

subtest 'invalidate' => sub {
  @{ $fake->logins } = ();
  my $auth  = auth( username => 'admin', password => 'admin' );
  my $first = $auth->token_f->get;
  $auth->invalidate;
  isnt( $auth->token_f->get, $first, 'a new token after invalidate' );
  is( $fake->logins->[1]{grant_type}, 'password', 'by logging in, not by refresh' );
};

subtest 'service account' => sub {
  @{ $fake->logins } = ();
  my $auth = auth( client_id => 'provisioner', client_secret => 'secret' );
  ok( $auth->token_f->get, 'token' );
  is_deeply( [ @{ $fake->logins->[0] }{qw( grant_type client_id client_secret )} ], [qw( client_credentials provisioner secret )], 'client credentials grant' );
};

subtest 'fixed token' => sub {
  my $auth = Net::Async::Keycloak::Auth->new( http => $http, token => 'fixed' );
  is( $auth->token_f->get, 'fixed', 'used as it is' );
  is( $auth->renewable, 0, 'and not renewable' );
};

subtest 'refusals' => sub {
  my $wrong = auth( username => 'admin', password => 'guess' );
  ok( !eval { $wrong->token_f->get; 1 }, 'wrong password croaks' );
  isa_ok( $@, 'Net::Async::Keycloak::Error::API' );
  like( "$@", qr/\Aadmin login failed: 400 - invalid_grant/, 'and says so (Keycloak answers a wrong password with 400)' );
  unlike( "$@", qr/guess/, 'without the password' );

  ok( !eval { auth( client_id => 'x', client_secret => 'leaked-secret' )->token_f->get; 1 }, 'wrong secret croaks' );
  unlike( "$@", qr/leaked-secret/, 'without the secret' );

  ok( !eval { Net::Async::Keycloak::Auth->new( http => $http, token_endpoint => 'x' ); 1 }, 'no credentials' );
  isa_ok( $@, 'Net::Async::Keycloak::Error::Validation' );
  ok( !eval { Net::Async::Keycloak::Auth->new( http => $http, username => 'a', password => 'b' ); 1 }, 'no token endpoint' );
  ok( !eval { Net::Async::Keycloak::Auth->new( http => $http, token_endpoint => 'x', username => 'a' ); 1 }, 'username without password' );
};

done_testing;
```

Run: `prove -lr t/30-auth.t` — Expected: FAIL mit `Can't locate Net/Async/Keycloak/Auth.pm`.

- [ ] **Step 4: Fehlerklassen, Rolle, Auth schreiben**

`lib/Net/Async/Keycloak/Error.pm`:

```perl
package Net::Async::Keycloak::Error;

# ABSTRACT: Exception base class for Net::Async::Keycloak

use Moo;
extends 'WWW::Keycloak::Error';

our $VERSION = '0.001';

=synopsis

    $kc->admin->get_client_f($id)->else( sub {
      my ( $error ) = @_;
      return Future->done(undef) if $error->isa('Net::Async::Keycloak::Error::API') && $error->is_not_found;
      return Future->fail($error);
    } );

=description

Failed futures of Net::Async::Keycloak fail with one of
L<Net::Async::Keycloak::Error::Validation>,
L<Net::Async::Keycloak::Error::Network> and
L<Net::Async::Keycloak::Error::API>. Each is also the matching
L<WWW::Keycloak::Error> class, and stringifies to its message.

=cut

1;
```

`lib/Net/Async/Keycloak/Error/Validation.pm`:

```perl
package Net::Async::Keycloak::Error::Validation;

# ABSTRACT: Net::Async::Keycloak's Validation error, a WWW::Keycloak::Error::Validation

use Moo;
extends 'WWW::Keycloak::Error::Validation', 'Net::Async::Keycloak::Error';

our $VERSION = '0.001';

=description

The same error as L<WWW::Keycloak::Error::Validation>, with the same attributes and
methods. It is both a L<WWW::Keycloak::Error::Validation> and a
L<Net::Async::Keycloak::Error>, so code written for the sync client catches it
unchanged.

=cut

1;
```

`lib/Net/Async/Keycloak/Error/Network.pm`:

```perl
package Net::Async::Keycloak::Error::Network;

# ABSTRACT: Net::Async::Keycloak's Network error, a WWW::Keycloak::Error::Network

use Moo;
extends 'WWW::Keycloak::Error::Network', 'Net::Async::Keycloak::Error';

our $VERSION = '0.001';

=description

The same error as L<WWW::Keycloak::Error::Network>, with the same attributes and
methods. It is both a L<WWW::Keycloak::Error::Network> and a
L<Net::Async::Keycloak::Error>, so code written for the sync client catches it
unchanged.

=cut

1;
```

`lib/Net/Async/Keycloak/Error/API.pm`:

```perl
package Net::Async::Keycloak::Error::API;

# ABSTRACT: Net::Async::Keycloak's API error, a WWW::Keycloak::Error::API

use Moo;
extends 'WWW::Keycloak::Error::API', 'Net::Async::Keycloak::Error';

our $VERSION = '0.001';

=description

The same error as L<WWW::Keycloak::Error::API>, with the same attributes and
methods. It is both a L<WWW::Keycloak::Error::API> and a
L<Net::Async::Keycloak::Error>, so code written for the sync client catches it
unchanged.

=cut

1;
```

`lib/Net/Async/Keycloak/Role/HTTP.pm`:

```perl
package Net::Async::Keycloak::Role::HTTP;

# ABSTRACT: Sending requests to Keycloak through Net::Async::HTTP

use Future;
use Net::Async::Keycloak::Error::API;
use Net::Async::Keycloak::Error::Network;
use Net::Async::Keycloak::Error::Validation;
use Scalar::Util qw( blessed );
use Moo::Role;

our $VERSION = '0.001';

=description

The asynchronous counterpart of L<WWW::Keycloak::Role::HTTP>. Requests are
built and responses read by that role's C<build_request> and
C<read_response>, so both clients map Keycloak's answers the same way; this
role only sends through L<Net::Async::HTTP> and returns futures.

Consume it before L<WWW::Keycloak::Role::HTTP>: its error class methods then
win and the errors are this distribution's subclasses.

    with 'Net::Async::Keycloak::Role::HTTP';
    with 'WWW::Keycloak::Role::HTTP';

The consuming class has an C<http> attribute holding a L<Net::Async::HTTP>.

=cut

sub api_error_class        { 'Net::Async::Keycloak::Error::API' }
sub network_error_class    { 'Net::Async::Keycloak::Error::Network' }
sub validation_error_class { 'Net::Async::Keycloak::Error::Validation' }

sub fail_validation {
  my ( $self, $message ) = @_;
  return Future->fail( $self->validation_error_class->new( message => $message ) );
}

=method fail_validation

    return $self->fail_validation('a client_id is needed');

A failed future with a validation error.

=cut

sub send_request_f {
  my ( $self, $method, $url, %arg ) = @_;
  my $request = $self->build_request( $method, $url, %arg );
  return $self->http->do_request( request => $request )->else( sub {
    my ( $message ) = @_;
    return Future->fail($message) if blessed $message;
    return Future->fail( $self->network_error_class->new( message => $method.' '.$url.': '.$message ) );
  } )->then( sub {
    my ( $response ) = @_;
    my $result = eval { $self->read_response( $response, $method, $url, %arg ) };
    return $result ? Future->done($result) : Future->fail($@);
  } );
}

=method send_request_f

    $self->send_request_f( POST => $url, json => \%body, bearer => $token )->then( sub {
      my ( $result ) = @_;   # status, data, location
      ...
    } );

Fails with a network error when no answer came back and an API error for any
status of 400 and above.

=cut

1;
```

`lib/Net/Async/Keycloak/Auth.pm`:

```perl
package Net::Async::Keycloak::Auth;

# ABSTRACT: Get and keep a valid admin token for the Keycloak Admin API, asynchronously

use Moo;
with 'Net::Async::Keycloak::Role::HTTP';
with 'WWW::Keycloak::Role::HTTP';
use Future;
use Future::AsyncAwait;
use Scalar::Util qw( blessed );
use Types::Standard qw( CodeRef Int Object Str );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $auth = Net::Async::Keycloak::Auth->new(
      http           => $http,
      token_endpoint => 'https://id.example.org/realms/master/protocol/openid-connect/token',
      username       => 'admin',
      password       => $password,
    );
    my $bearer = await $auth->token_f;

=description

The asynchronous L<WWW::Keycloak::Auth>: same login options, same renewal
rules, futures instead of values. Callers asking for a token while a login is
under way share that login instead of starting their own.

=cut

has http => (
  is       => 'ro',
  isa      => Object,
  required => 1
);

=attr http

Required. The L<Net::Async::HTTP> to use.

=cut

has token_endpoint => ( is => 'ro', isa => Str );
has username       => ( is => 'ro', isa => Str, predicate => 'has_username' );
has password       => ( is => 'ro', isa => Str );
has client_id      => ( is => 'ro', isa => Str, predicate => 'has_client_id' );
has client_secret  => ( is => 'ro', isa => Str );
has fixed_token    => ( is => 'ro', isa => Str, init_arg => 'token', predicate => 'has_fixed_token' );

=attr token_endpoint

=attr username

=attr password

=attr client_id

=attr client_secret

=attr token

As in L<WWW::Keycloak::Auth>.

=cut

has margin => ( is => 'ro', isa => Int, default => 30 );
has now    => ( is => 'ro', isa => CodeRef, default => sub { sub { time } } );

=attr margin

=attr now

As in L<WWW::Keycloak::Auth>.

=cut

has _access          => ( is => 'rw' );
has _access_expires  => ( is => 'rw' );
has _refresh         => ( is => 'rw' );
has _refresh_expires => ( is => 'rw' );
has _pending         => ( is => 'rw' );

sub BUILD {
  my ( $self ) = @_;
  return if $self->has_fixed_token;
  $self->validation_error_class->throw( message => __PACKAGE__.' needs username and password, client_id and client_secret, or token' )
    unless ( $self->has_username && defined $self->password ) || ( $self->has_client_id && defined $self->client_secret );
  $self->validation_error_class->throw( message => __PACKAGE__.' needs a token_endpoint' )
    unless defined $self->token_endpoint && length $self->token_endpoint;
  return;
}

sub renewable { $_[0]->has_fixed_token ? 0 : 1 }

sub token_f {
  my ( $self ) = @_;
  return Future->done( $self->fixed_token ) if $self->has_fixed_token;
  return Future->done( $self->_access )
    if defined $self->_access && $self->now->() < $self->_access_expires - $self->margin;
  return $self->_pending if $self->_pending;
  my $login = $self->_renew_f->on_ready( sub { $self->_pending(undef) } );
  $self->_pending($login) unless $login->is_ready;
  return $login;
}

=method token_f

    my $bearer = await $auth->token_f;

A future of a token that is valid for at least C<margin> more seconds.

=cut

sub invalidate {
  my ( $self ) = @_;
  $self->_access(undef);
  $self->_refresh(undef);
  return;
}

=method invalidate

=method renewable

As in L<WWW::Keycloak::Auth>.

=cut

async sub _renew_f {
  my ( $self ) = @_;
  if ( defined $self->_refresh && $self->now->() < $self->_refresh_expires - $self->margin ) {
    my $renewed = eval {
      await $self->_grant_f( { grant_type => 'refresh_token', refresh_token => $self->_refresh, $self->_client } );
      1;
    };
    return $self->_access if $renewed;
  }
  await $self->_grant_f( $self->has_username
    ? { grant_type => 'password', username => $self->username, password => $self->password, $self->_client }
    : { grant_type => 'client_credentials', $self->_client } );
  return $self->_access;
}

sub _client {
  my ( $self ) = @_;
  return (
    client_id => $self->has_client_id ? $self->client_id : 'admin-cli',
    defined $self->client_secret ? ( client_secret => $self->client_secret ) : ()
  );
}

async sub _grant_f {
  my ( $self, $form ) = @_;
  my $now  = $self->now->();
  my $data = eval { ( await $self->send_request_f( POST => $self->token_endpoint, form => $form ) )->{data} };
  if ( my $error = $@ ) {
    die $error unless blessed $error && $error->isa('WWW::Keycloak::Error::API');
    $self->api_error_class->throw(
      message     => 'admin login failed: '.$error->http_status.( defined $error->api_message ? ' - '.$error->api_message : '' ),
      http_status => $error->http_status,
      api_message => $error->api_message,
      oauth_error => $error->oauth_error
    );
  }
  $self->_access( $data->{access_token} );
  $self->_access_expires( $now + ( $data->{expires_in} || 60 ) );
  $self->_refresh( $data->{refresh_token} );
  $self->_refresh_expires( $now + ( $data->{refresh_expires_in} || 0 ) );
  return;
}

1;
```

- [ ] **Step 5: Test laufen lassen, Übergabe**

Run: `prove -lr t/30-auth.t` — Expected: PASS (6 Subtests). Module in `t/00-load.t`, `prove -lr t` grün. Betreff: `Add errors, async HTTP role and admin login`.

---

### Task 2: OIDC, Admin, Fassade

**Files:**
- Create: `lib/Net/Async/Keycloak/OIDC.pm`, `lib/Net/Async/Keycloak/Admin.pm`
- Modify: `lib/Net/Async/Keycloak.pm` (der Stub wird ersetzt)
- Test: `t/40-facade.t`, `t/50-admin.t`, `t/51-admin-ensure.t`, `t/60-oidc.t`

**Interfaces:**
- Consumes: Aufgabe 1; `WWW::Keycloak::Diff`.
- Produces: alle Methoden aus `WWW::Keycloak::OIDC` und `WWW::Keycloak::Admin` mit `_f`, dazu `discovery_f` und `endpoint_f` (im Sync-Client Attribut und Methode ohne Future). Fassade `Net::Async::Keycloak->new(...)` mit `http`, `auth`, `oidc`, `admin`, `issuer`, `for_realm`.

- [ ] **Step 1: Tests schreiben und scheitern sehen**

`t/40-facade.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use FakeHTTP;
use Net::Async::Keycloak;

my $fake = FakeKeycloak->new;
my $http = FakeHTTP->new( fake => $fake );

subtest 'construction' => sub {
  my $kc = Net::Async::Keycloak->new( base_url => 'https://id.example.org//', realm => 'main' );
  is( $kc->base_url, 'https://id.example.org', 'trailing slashes go' );
  is( $kc->issuer, 'https://id.example.org/realms/main', 'issuer' );
  isa_ok( $kc, 'IO::Async::Notifier' );
  is( $kc->auth, undef, 'no admin login without credentials' );
  isa_ok( $kc->oidc, 'Net::Async::Keycloak::OIDC' );
  is( $kc->oidc->issuer, $kc->issuer, 'oidc knows the issuer' );
  isa_ok( $kc->admin, 'Net::Async::Keycloak::Admin' );
  ok( !eval { $kc->admin->get_realm_f->get; 1 }, 'the Admin API without credentials' );
  isa_ok( $@, 'Net::Async::Keycloak::Error::Validation' );
  like( "$@", qr/needs credentials/, 'says what is missing' );

  for my $bad ( [ realm => 'x' ], [ base_url => 'x' ], [ base_url => '', realm => 'x' ], [ base_url => 'x', realm => '' ] ) {
    ok( !eval { Net::Async::Keycloak->new(@$bad); 1 }, 'refused: '.join( ' ', map { $_ // 'undef' } @$bad ) );
  }
};

subtest 'admin login options' => sub {
  my $pw = Net::Async::Keycloak->new( base_url => 'http://kc', realm => 'main', username => 'admin', password => 'pw' );
  is( $pw->auth_realm, 'master', 'a password login goes to master' );
  is( $pw->auth->token_endpoint, 'http://kc/realms/master/protocol/openid-connect/token', 'its token endpoint' );
  my $svc = Net::Async::Keycloak->new( base_url => 'http://kc', realm => 'main', client_id => 'svc', client_secret => 's' );
  is( $svc->auth_realm, 'main', 'a service account logs in to its own realm' );
  my $other = Net::Async::Keycloak->new( base_url => 'http://kc', realm => 'main', username => 'a', password => 'b', auth_realm => 'admins' );
  like( $other->auth->token_endpoint, qr{/realms/admins/}, 'auth_realm can be set' );
  my $fixed = Net::Async::Keycloak->new( base_url => 'http://kc', realm => 'main', token => 't' );
  is( $fixed->auth->token_f->get, 't', 'a fixed token' );
};

subtest 'for_realm' => sub {
  my $kc  = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'master', username => 'admin', password => 'admin', http => $http );
  my $dev = $kc->for_realm('dev');
  is( $dev->realm, 'dev', 'other realm' );
  is( $dev->issuer, $fake->base.'/realms/dev', 'its issuer' );
  is( $dev->http, $kc->http, 'same Net::Async::HTTP' );
  is( $dev->auth, $kc->auth, 'same admin login' );
  is( $dev->auth_realm, 'master', 'still logging in to master' );
  $dev->admin->create_realm_f( { displayName => 'Dev' } )->get;
  is( $fake->realm('dev')->{rep}{displayName}, 'Dev', 'and it works on the other realm' );
  @{ $fake->logins } = ();
  $kc->admin->get_realm_f->get;
  $dev->admin->get_realm_f->get;
  is( scalar @{ $fake->logins }, 0, 'without logging in again' );
};

done_testing;
```

`t/50-admin.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use FakeHTTP;
use Net::Async::Keycloak;

my $fake = FakeKeycloak->new;
my $http = FakeHTTP->new( fake => $fake );
my $kc   = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', http => $http );
my $admin = $kc->admin;

subtest 'realm' => sub {
  is( $admin->create_realm_f( { displayName => 'Main' } )->get, 'main', 'create_realm returns the realm name' );
  is( $admin->get_realm_f->get->{displayName}, 'Main', 'get_realm' );
  ok( $admin->update_realm_f( { accessTokenLifespan => 600 } )->get, 'update_realm' );
  is( $admin->get_realm_f->get->{accessTokenLifespan}, 600, 'updated' );
  is( $admin->get_realm_f->get->{displayName}, 'Main', 'the rest untouched' );
  is( $admin->server_info_f->get->{systemInfo}{version}, '26.8.0', 'server_info from the server root' );
  my $request = $fake->requests->[-1];
  is( $request->uri->path, '/admin/serverinfo', 'which is not under the realm' );
  is( $request->header('Authorization'), 'Bearer '.$kc->auth->token_f->get, 'with the admin token' );
  is( $admin->partial_import_f( { users => [ { username => 'Imported' } ] }, if_exists => 'SKIP' )->get->{added}, 1, 'partial_import' );
};

subtest 'clients' => sub {
  my $id = $admin->create_client_f( { clientId => 'cli', publicClient => \1 } )->get;
  like( $id, qr/\Aid-\d+\z/, 'create_client returns the id from the Location header' );
  is( $admin->get_client_f($id)->get->{clientId}, 'cli', 'get_client' );
  is( $admin->find_client_f('cli')->get->{id}, $id, 'find_client by clientId' );
  is( $admin->find_client_f('nope')->get, undef, 'find_client without a match' );
  my $client = $admin->get_client_f($id)->get;
  ok( $admin->update_client_f( $id, { %$client, description => 'd' } )->get, 'update_client' );
  is( $admin->get_client_f($id)->get->{description}, 'd', 'updated' );
  is( scalar @{ $admin->list_clients_f->get }, 1, 'list_clients' );
  is( $admin->get_client_secret_f($id)->get->{type}, 'secret', 'get_client_secret' );
  is( $admin->get_service_account_user_f($id)->get->{username}, 'service-account-cli', 'get_service_account_user' );
  ok( !eval { $admin->create_client_f( { clientId => 'cli' } )->get; 1 }, 'a second create croaks' );
  ok( $@->is_conflict, 'with a conflict' );
  ok( $admin->delete_client_f($id)->get, 'delete_client' );
  ok( !eval { $admin->get_client_f($id)->get; 1 } && $@->is_not_found, 'gone' );
};

subtest 'client scopes and protocol mappers' => sub {
  my $client = $admin->create_client_f( { clientId => 'mapped' } )->get;
  my $scope  = $admin->create_client_scope_f( { name => 'amr', protocol => 'openid-connect' } )->get;
  is( $admin->find_client_scope_f('amr')->get->{id}, $scope, 'find_client_scope by name' );
  my $mapper = $admin->create_protocol_mapper_f( client => $client, { name => 'amr', protocolMapper => 'oidc-amr-mapper', config => {} } )->get;
  ok( $mapper, 'create_protocol_mapper on a client' );
  is( $admin->list_protocol_mappers_f( client => $client )->get->[0]{name}, 'amr', 'list_protocol_mappers' );
  ok( $admin->update_protocol_mapper_f( client => $client, $mapper, { name => 'amr', protocolMapper => 'oidc-amr-mapper', config => { a => 'b' } } )->get, 'update_protocol_mapper' );
  is( $admin->list_protocol_mappers_f( client => $client )->get->[0]{config}{a}, 'b', 'updated' );
  ok( $admin->create_protocol_mapper_f( client_scope => $scope, { name => 'amr', protocolMapper => 'oidc-amr-mapper' } )->get, 'on a client scope' );
  like( $fake->requests->[-1]->uri->path, qr{/client-scopes/\Q$scope\E/protocol-mappers/models\z}, 'at the scope' );
  ok( $admin->delete_protocol_mapper_f( client => $client, $mapper )->get, 'delete_protocol_mapper' );
  ok( !eval { $admin->list_protocol_mappers_f( group => 'x' )->get; 1 }, 'an owner that is neither client nor scope' );
  isa_ok( $@, 'Net::Async::Keycloak::Error::Validation' );
  ok( $admin->add_default_client_scope_f( $client, $scope )->get, 'add_default_client_scope' );
  ok( $admin->add_realm_default_client_scope_f($scope)->get, 'add_realm_default_client_scope' );
};

subtest 'users' => sub {
  my $id = $admin->create_user_f( { username => 'Alice', enabled => \1, credentials => [ { type => 'password', value => 'pw', temporary => \0 } ] } )->get;
  is( $admin->find_user_f('alice')->get->{id}, $id, 'find_user' );
  is( $admin->find_user_f('ALICE')->get->{id}, $id, 'in any case' );
  is( $admin->find_user_f('alic')->get, undef, 'exactly' );
  is_deeply( [ map { $_->{type} } @{ $admin->list_credentials_f($id)->get } ], ['password'], 'list_credentials' );
  ok( $admin->set_password_f( $id, 'new', temporary => 1 )->get, 'set_password' );
  my ( $password ) = grep { $_->{type} eq 'password' } @{ $fake->realm('main')->{users}{$id}{credentials} };
  is_deeply( [ @$password{qw( value type )}, ${ $password->{temporary} } ], [ 'new', 'password', 1 ], 'with type and temporary flag' );
  ok( $admin->update_user_f( $id, { firstName => 'A' } )->get, 'update_user' );
  is( $admin->get_user_f($id)->get->{firstName}, 'A', 'updated' );
  is_deeply( $admin->list_sessions_f($id)->get, [], 'list_sessions' );
  ok( $admin->logout_user_f($id)->get, 'logout_user' );
  ok( $admin->delete_credential_f( $id, $admin->list_credentials_f($id)->get->[0]{id} )->get, 'delete_credential' );
  ok( $admin->delete_user_f($id)->get, 'delete_user' );
};

subtest 'authentication' => sub {
  is_deeply( [ map { $_->{alias} } @{ $admin->list_flows_f->get } ], [ 'browser', 'direct grant' ], 'list_flows' );
  my ( $otp ) = grep { ( $_->{providerId} // '' ) eq 'auth-otp-form' } @{ $admin->list_executions_f('browser')->get };
  ok( $otp, 'list_executions' );
  like( $fake->requests->[-1]->uri->as_string, qr{/flows/browser/executions\z}, 'by alias' );
  $admin->list_executions_f('direct grant')->get;
  like( $fake->requests->[-1]->uri->as_string, qr{/flows/direct%20grant/executions\z}, 'an alias with a space is escaped' );
  my $config = $admin->create_execution_config_f( $otp->{id}, { alias => 'x', config => { 'default.reference.value' => 'otp' } } )->get;
  ok( $config, 'create_execution_config' );
  is( $admin->get_execution_config_f($config)->get->{config}{'default.reference.value'}, '**********', 'get_execution_config: masked, as Keycloak does' );
  ok( $admin->update_execution_config_f( $config, { alias => 'x', config => { 'default.reference.value' => 'mfa' } } )->get, 'update_execution_config' );
  is( $fake->realm('main')->{configs}{$config}{config}{'default.reference.value'}, 'mfa', 'updated' );
  is( $fake->realm('main')->{configs}{$config}{id}, $config, 'with its id' );
  ok( $admin->copy_flow_f( 'browser', 'browser-copy' )->get, 'copy_flow' );
  is_deeply( $admin->describe_authenticator_f('auth-otp-form')->get, { properties => [] }, 'describe_authenticator' );
};

subtest 'call reaches what has no method' => sub {
  my $result = $admin->call_f( GET => '/clients?first=0&max=1' )->get;
  is( $result->{status}, 200, 'status' );
  is( ref $result->{data}, 'ARRAY', 'data' );
};

subtest 'a refused token is renewed once' => sub {
  $admin->get_realm_f->get;
  @{ $fake->logins } = ();
  $fake->forget_tokens;
  ok( $admin->get_realm_f->get, 'the call after a Keycloak restart succeeds' );
  is( scalar @{ $fake->logins }, 1, 'after one new login' );

  my $fixed = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', token => 'stale', http => $http );
  ok( !eval { $fixed->admin->get_realm_f->get; 1 }, 'a fixed token that is refused croaks' );
  ok( $@->is_unauthorized, 'with 401' );

  my $always = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', http => $http );
  no warnings 'redefine';
  local *FakeKeycloak::_admin = sub { $_[0]->_reply( 401, { error => 'HTTP 401 Unauthorized' } ) };
  @{ $fake->logins } = ();
  ok( !eval { $always->admin->get_realm_f->get; 1 }, 'a token refused twice croaks' );
  is( scalar @{ $fake->logins }, 2, 'after exactly one retry' );
};

subtest 'a failed login is not retried as a refused token' => sub {
  my $bad = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', client_id => 'svc', client_secret => 'wrong', http => $http );
  @{ $fake->logins } = ();
  ok( !eval { $bad->admin->get_realm_f->get; 1 }, 'a wrong client secret croaks' );
  like( "$@", qr/admin login failed: 401/, 'as a failed login' );
  is( scalar @{ $fake->logins }, 1, 'and the secret went to Keycloak once, not twice' );
};

subtest 'no Location header' => sub {
  no warnings 'redefine';
  local *FakeKeycloak::_admin = sub { $_[0]->_reply(201) };
  ok( !eval { $admin->create_client_f( { clientId => 'x' } )->get; 1 }, 'croaks instead of returning nothing' );
  like( "$@", qr/sent no Location header/, 'and says why' );
};

done_testing;
```

`t/51-admin-ensure.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use FakeHTTP;
use Net::Async::Keycloak;

my $fake  = FakeKeycloak->new;
my $http = FakeHTTP->new( fake => $fake );
my $admin = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', http => $http )->admin;

sub writes {
  my ( $code ) = @_;
  my $before = @{ $fake->requests };
  my $result = $code->();
  return ( $result, scalar grep { $_->method ne 'GET' && $_->uri->path !~ m{/token\z} } @{ $fake->requests }[ $before .. $#{ $fake->requests } ] );
}

subtest 'ensure_realm' => sub {
  my ( $r, $w ) = writes( sub { $admin->ensure_realm_f( enabled => \1, displayName => 'Main' )->get } );
  is_deeply( $r, { id => 'main', changed => 'created' }, 'created' );
  ( $r, $w ) = writes( sub { $admin->ensure_realm_f( enabled => \1, displayName => 'Main' )->get } );
  is( $r->{changed}, '', 'second run: nothing to do' );
  is( $w, 0, 'and nothing written' );
  ( $r, $w ) = writes( sub { $admin->ensure_realm_f( displayName => 'Main realm' )->get } );
  is( $r->{changed}, 'updated', 'a change' );
  is( $w, 1, 'one write' );
  is( $fake->realm('main')->{rep}{enabled}, JSON::MaybeXS::true, 'other keys untouched' );
};

subtest 'ensure_client' => sub {
  my %want = ( clientId => 'cli', publicClient => \1, attributes => { 'oauth2.device.authorization.grant.enabled' => 'true' } );
  my $r = $admin->ensure_client_f(%want)->get;
  is( $r->{changed}, 'created', 'created' );
  my ( $again, $w ) = writes( sub { $admin->ensure_client_f(%want)->get } );
  is_deeply( $again, { id => $r->{id}, changed => '' }, 'second run: same id, nothing to do' );
  is( $w, 0, 'nothing written' );
  my ( $changed ) = writes( sub { $admin->ensure_client_f( clientId => 'cli', attributes => { 'pkce.code.challenge.method' => 'S256' } )->get } );
  is( $changed->{changed}, 'updated', 'an attribute added' );
  is_deeply(
    $fake->realm('main')->{clients}{ $r->{id} }{attributes},
    { 'oauth2.device.authorization.grant.enabled' => 'true', 'pkce.code.challenge.method' => 'S256' },
    'the other attribute kept'
  );
  ok( ${ $fake->realm('main')->{clients}{ $r->{id} }{publicClient} }, 'and the other keys too: the whole client was sent' );
  ok( !eval { $admin->ensure_client_f( publicClient => \1 )->get; 1 }, 'without clientId' );
  isa_ok( $@, 'Net::Async::Keycloak::Error::Validation' );
};

subtest 'ensure_client_scope and ensure_protocol_mapper' => sub {
  is( $admin->ensure_client_scope_f( name => 'amr' )->get->{changed}, 'created', 'scope created' );
  is( $fake->realm('main')->{scopes}{ $admin->find_client_scope_f('amr')->get->{id} }{protocol}, 'openid-connect', 'protocol defaults to openid-connect' );
  is( $admin->ensure_client_scope_f( name => 'amr' )->get->{changed}, '', 'scope: nothing to do' );
  is( $admin->ensure_client_scope_f( name => 'amr', description => 'd' )->get->{changed}, 'updated', 'scope updated' );

  my %mapper = ( name => 'amr', protocolMapper => 'oidc-amr-mapper', config => { 'id.token.claim' => 'true' } );
  is( $admin->ensure_protocol_mapper_f( client => 'cli', %mapper )->get->{changed}, 'created', 'mapper on a client, named by clientId' );
  is( $admin->ensure_protocol_mapper_f( client => 'cli', %mapper )->get->{changed}, '', 'nothing to do' );
  is( $admin->ensure_protocol_mapper_f( client => 'cli', name => 'amr', config => { 'access.token.claim' => 'true' } )->get->{changed}, 'updated', 'a config key added' );
  my ( $stored ) = values %{ $fake->realm('main')->{mappers}{ 'clients/'.$admin->find_client_f('cli')->get->{id} } };
  is_deeply( $stored->{config}, { 'id.token.claim' => 'true', 'access.token.claim' => 'true' }, 'merged' );
  is( $admin->ensure_protocol_mapper_f( client_scope => 'amr', %mapper )->get->{changed}, 'created', 'mapper on a scope, named by name' );
  ok( !eval { $admin->ensure_protocol_mapper_f( client => 'nope', %mapper )->get; 1 }, 'an unknown owner' );
  like( "$@", qr/no client nope/, 'is named' );
  ok( !eval { $admin->ensure_protocol_mapper_f( client => 'cli', protocolMapper => 'x' )->get; 1 }, 'without name' );
};

subtest 'ensure_user' => sub {
  my %want = ( username => 'Alice', email => 'Alice@Example.org', enabled => \1, credentials => [ { type => 'password', value => 'first', temporary => \0 } ] );
  my $r = $admin->ensure_user_f(%want)->get;
  is( $r->{changed}, 'created', 'created' );
  my ( $again, $w ) = writes( sub { $admin->ensure_user_f( %want, credentials => [ { type => 'password', value => 'second' } ] )->get } );
  is( $again->{changed}, '', 'second run, with other credentials and mixed case: nothing to do' );
  is( $w, 0, 'nothing written' );
  my ( $password ) = grep { $_->{type} eq 'password' } @{ $fake->realm('main')->{users}{ $r->{id} }{credentials} };
  is( $password->{value}, 'first', 'the password was not reset' );
  is( $admin->ensure_user_f( username => 'alice', firstName => 'Alice' )->get->{changed}, 'updated', 'a change' );
  is( $fake->realm('main')->{users}{ $r->{id} }{email}, 'alice@example.org', 'the rest kept' );
};

subtest 'ensure_execution_config' => sub {
  my %want = ( flow => 'browser', authenticator => 'auth-otp-form', config => { 'default.reference.value' => 'otp', 'default.reference.maxAge' => 3600 } );
  my $r = $admin->ensure_execution_config_f(%want)->get;
  is( $r->{changed}, 'created', 'created' );
  my ( $execution ) = grep { ( $_->{providerId} // '' ) eq 'auth-otp-form' } @{ $fake->realm('main')->{flows}{browser} };
  is( $execution->{authenticationConfig}, $r->{id}, 'attached to the step' );
  is( $fake->realm('main')->{configs}{ $r->{id} }{alias}, 'browser auth-otp-form', 'default alias' );
  my $again = $admin->ensure_execution_config_f(%want)->get;
  is_deeply( $again, { id => $r->{id}, changed => 'updated' }, 'Keycloak hides the values, so a second run writes again' );
  $admin->ensure_execution_config_f( %want, config => { 'default.reference.value' => 'otp' } )->get;
  is_deeply( $fake->realm('main')->{configs}{ $r->{id} }{config}, { 'default.reference.value' => 'otp' }, 'replaced as given, never merged with masked values' );
  ok( !grep( { /\*{10}/ } values %{ $fake->realm('main')->{configs}{ $r->{id} }{config} } ), 'no masked value was written back' );
  is( $admin->ensure_execution_config_f( %want, flow => 'direct grant', authenticator => 'direct-grant-validate-otp', alias => 'mine' )->get->{changed}, 'created', 'in a flow with a space' );
  ok( !eval { $admin->ensure_execution_config_f( %want, authenticator => 'nope' )->get; 1 }, 'an unknown step' );
  like( "$@", qr/flow "browser" has no step nope/, 'is named' );
  ok( !eval { $admin->ensure_execution_config_f( flow => 'browser', authenticator => 'auth-otp-form' )->get; 1 }, 'without config' );
};

subtest 'what the review found against the real Keycloak' => sub {
  my $user = $admin->ensure_user_f( username => 'bob', email => 'bob@example.org', firstName => 'Bob', lastName => 'B', enabled => \1 )->get;
  is( $admin->ensure_user_f( username => 'bob', attributes => { dept => 'x' } )->get->{changed}, 'updated', 'an attribute added' );
  my $stored = $fake->realm('main')->{users}{ $user->{id} };
  is_deeply( [ @$stored{qw( email firstName lastName )} ], [ 'bob@example.org', 'Bob', 'B' ], 'the profile fields survive a PUT with attributes' );
  is_deeply( $stored->{attributes}, { dept => ['x'] }, 'stored as a list' );
  is( $admin->ensure_user_f( username => 'bob', attributes => { dept => 'x' } )->get->{changed}, '', 'a single value given as a string converges' );
  is( $admin->ensure_user_f( username => 'bob', attributes => { dept => ['x'] } )->get->{changed}, '', 'and as a list' );

  my %uris = ( clientId => 'web', redirectUris => [ 'https://b/*', 'https://a/*', 'https://c/*' ], webOrigins => [ 'https://b', 'https://a' ] );
  is( $admin->ensure_client_f(%uris)->get->{changed}, 'created', 'a client with unsorted URI lists' );
  is( $admin->ensure_client_f(%uris)->get->{changed}, '', 'converges although Keycloak sorts them' );

  for my $ignored (qw( defaultClientScopes optionalClientScopes protocolMappers )) {
    ok( !eval { $admin->ensure_client_f( clientId => 'web', $ignored => [] )->get; 1 }, $ignored.' is refused' );
    like( "$@", qr/Keycloak ignores it when a client is updated/, 'with the reason' );
  }
};

done_testing;
```

`t/60-oidc.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Crypt::PK::RSA;
use MIME::Base64 qw( encode_base64url );
use FakeKeycloak;
use FakeHTTP;
use Net::Async::Keycloak;

my $fake = FakeKeycloak->new;
my $http = FakeHTTP->new( fake => $fake );
$fake->add_realm('main');
my $oidc   = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', http => $http )->oidc;
my $issuer = $fake->base.'/realms/main';

sub claims { { iss => $issuer, sub => 'u-1', aud => 'my-api', exp => time + 300, iat => time, @_ } }

subtest 'discovery' => sub {
  is( $oidc->token_endpoint_f->get, $issuer.'/protocol/openid-connect/token', 'token_endpoint' );
  is( $oidc->device_endpoint_f->get, $issuer.'/protocol/openid-connect/auth/device', 'device_endpoint' );
  my $count = grep { $_->uri =~ /well-known/ } @{ $fake->requests };
  $oidc->userinfo_endpoint_f->get;
  is( scalar( grep { $_->uri =~ /well-known/ } @{ $fake->requests } ), $count, 'fetched once' );
  ok( !eval { $oidc->endpoint_f('nope_endpoint')->get; 1 }, 'a missing endpoint croaks' );
  like( "$@", qr/has no nope_endpoint/, 'and names it' );
};

subtest 'verify_token' => sub {
  my $claims = $oidc->verify_token_f( $fake->sign( claims() ), audience => 'my-api' )->get;
  is( $claims->{sub}, 'u-1', 'a good token' );
  ok( $oidc->verify_token_f( $fake->sign( claims() ) )->get, 'audience is only checked when asked' );
  my %bad = (
    'wrong issuer'   => $fake->sign( claims( iss => 'https://evil/realms/main' ) ),
    'expired'        => $fake->sign( claims( exp => time - 10 ) ),
    'wrong audience' => $fake->sign( claims( aud => 'other' ) ),
    'foreign key'    => do { my $k = Crypt::PK::RSA->new; $k->generate_key( 256, 65537 ); $fake->sign( claims(), key => $k ) },
    'HMAC'           => $fake->sign( claims(), alg => 'HS256', key => 'secret' ),
    'not a JWT'      => 'abc.def'
  );
  for my $case ( sort keys %bad ) {
    ok( !eval { $oidc->verify_token_f( $bad{$case}, audience => 'my-api' )->get; 1 }, $case.' is rejected' );
    isa_ok( $@, 'Net::Async::Keycloak::Error::Validation' );
  }
  my ( $none ) = map { join '.', $_, encode_base64url('{"iss":"'.$issuer.'","sub":"x","exp":'.( time + 60 ).'}'), '' } encode_base64url('{"alg":"none"}');
  ok( !eval { $oidc->verify_token_f($none)->get; 1 }, 'alg none is rejected' );
  ok( !eval { $oidc->verify_token_f('')->get; 1 }, 'an empty token' );
};

subtest 'key rotation' => sub {
  my $clock   = time;
  my $rotated = Net::Async::Keycloak::OIDC->new( issuer => $issuer, http => $http, now => sub { $clock } );
  my $fetches = sub { scalar grep { $_->uri =~ /certs/ } @{ $fake->requests } };
  $rotated->jwks_f->get;
  my $start = $fetches->();

  for my $junk ( $fake->sign( claims( iss => 'https://evil' ) ), $fake->sign( claims( exp => time - 1 ) ), 'abc.def' ) {
    ok( !eval { $rotated->verify_token_f($junk)->get; 1 }, 'a bad token is rejected' );
  }
  is( $fetches->(), $start, 'without fetching the keys again' );

  $fake->rotate_key;
  ok( !eval { $rotated->verify_token_f( $fake->sign( claims() ) )->get; 1 }, 'a new key right after the last fetch is not looked up yet' );
  is( $fetches->(), $start, 'jwks_min_age holds the fetch back' );
  $clock += 60;
  ok( $rotated->verify_token_f( $fake->sign( claims() ) )->get, 'a minute later the token with the new key verifies' );
  is( $fetches->(), $start + 1, 'after one fetch' );
  ok( !eval { $rotated->verify_token_f( $fake->sign( claims(), kid => 'unknown' ) )->get; 1 }, 'an unknown kid right after' );
  is( $fetches->(), $start + 1, 'does not fetch again' );
};

subtest 'typ' => sub {
  # a client of its own: the shared one still holds the keys from before the rotation
  my $oidc = Net::Async::Keycloak::OIDC->new( issuer => $issuer, http => $http );
  ok( $oidc->verify_token_f( $fake->sign( claims( typ => 'Bearer' ) ), type => 'Bearer' )->get, 'an access token where one is expected' );
  ok( !eval { $oidc->verify_token_f( $fake->sign( claims( typ => 'ID' ) ), type => 'Bearer' )->get; 1 }, 'an ID token where an access token is expected' );
  like( "$@", qr/typ is ID, expected Bearer/, 'says why' );
  ok( !eval { $oidc->verify_token_f( $fake->sign( claims() ), type => 'Bearer' )->get; 1 }, 'no typ at all' );
  ok( $oidc->verify_token_f( $fake->sign( claims( typ => 'ID' ) ) )->get, 'without type nothing is checked' );
};

subtest 'token endpoint' => sub {
  my $tokens = $oidc->password_token_f( client_id => 'admin-cli', username => 'admin', password => 'admin', totp => '123456', scope => 'openid' )->get;
  like( $tokens->{access_token}, qr/\Aat-/, 'password_token' );
  is_deeply( { map { $_ => $fake->logins->[-1]{$_} } qw( grant_type username totp scope client_id ) },
    { grant_type => 'password', username => 'admin', totp => '123456', scope => 'openid', client_id => 'admin-cli' }, 'sends totp and scope' );
  ok( $oidc->client_credentials_token_f( client_id => 'svc', client_secret => 'secret' )->get->{access_token}, 'client_credentials_token' );
  ok( $oidc->refresh_token_f( $tokens->{refresh_token}, client_id => 'admin-cli' )->get->{access_token}, 'refresh_token' );
  ok( !eval { $oidc->password_token_f( username => 'a', password => 'b' )->get; 1 }, 'without client_id' );
  isa_ok( $@, 'Net::Async::Keycloak::Error::Validation' );
};

subtest 'device flow, one step at a time' => sub {
  my $start = $oidc->device_authorization_f( client_id => 'cli', scope => 'openid' )->get;
  is( $start->{user_code}, 'ABCD-EFGH', 'device_authorization' );
  ok( !eval { $oidc->device_token_f( device_code => $start->{device_code}, client_id => 'cli' )->get; 1 }, 'a pending poll croaks' );
  is( $@->oauth_error, 'authorization_pending', 'with oauth_error authorization_pending' );
};

subtest 'userinfo, introspect, logout' => sub {
  is( $oidc->userinfo_f('user-token')->get->{preferred_username}, 'alice', 'userinfo' );
  ok( !eval { $oidc->userinfo_f('bad')->get; 1 } && $@->is_unauthorized, 'userinfo with a bad token' );
  ok( $oidc->introspect_f( 'user-token', client_id => 'api', client_secret => 's' )->get->{active}, 'introspect' );
  ok( $oidc->logout_f( refresh_token => 'r', client_id => 'cli' )->get, 'logout' );
};

done_testing;
```

Run: `prove -lr t/40-facade.t t/50-admin.t t/51-admin-ensure.t t/60-oidc.t` — Expected: FAIL; der Stub hat kein `new` mit diesen Attributen.

- [ ] **Step 2: OIDC, Admin und Fassade schreiben**

`lib/Net/Async/Keycloak/OIDC.pm`:

```perl
package Net::Async::Keycloak::OIDC;

# ABSTRACT: OpenID Connect against one Keycloak realm, asynchronously

use Moo;
with 'Net::Async::Keycloak::Role::HTTP';
with 'WWW::Keycloak::Role::HTTP';
use Crypt::JWT qw( decode_jwt );
use Future;
use Future::AsyncAwait;
use Types::Standard qw( ArrayRef CodeRef Int Object Str );
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $oidc   = $kc->oidc;
    my $claims = await $oidc->verify_token_f( $jwt, audience => 'my-api', type => 'Bearer' );
    my $tokens = await $oidc->password_token_f( client_id => 'cli', username => 'alice', password => $pw );

=description

The asynchronous L<WWW::Keycloak::OIDC>: the same methods with C<_f> and
futures. Token verification follows the same rules, including when the keys
are fetched again.

=cut

has issuer => ( is => 'ro', isa => Str, required => 1 );
has http   => ( is => 'ro', isa => Object, required => 1 );

=attr issuer

Required. C<< <base_url>/realms/<realm> >>.

=attr http

Required. The L<Net::Async::HTTP> to use.

=cut

has algorithms => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [qw( RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512 )] }
);
has jwks_min_age => ( is => 'ro', isa => Int, default => 60 );
has now          => ( is => 'ro', isa => CodeRef, default => sub { sub { time } } );

=attr algorithms

=attr jwks_min_age

=attr now

As in L<WWW::Keycloak::OIDC>.

=cut

has _discovery    => ( is => 'rw' );
has _jwks         => ( is => 'rw' );
has _jwks_fetched => ( is => 'rw' );

async sub discovery_f {
  my ( $self ) = @_;
  return $self->_discovery if $self->_discovery;
  my $data = ( await $self->send_request_f( GET => $self->issuer.'/.well-known/openid-configuration' ) )->{data};
  $self->validation_error_class->throw( message => 'discovery for '.$self->issuer.' returned no JSON object' ) unless ref $data eq 'HASH';
  return $self->_discovery($data);
}

=method discovery_f

The discovery document, fetched once.

=cut

async sub endpoint_f {
  my ( $self, $name ) = @_;
  my $url = ( await $self->discovery_f )->{$name};
  $self->validation_error_class->throw( message => 'the discovery document of '.$self->issuer.' has no '.$name ) unless defined $url;
  return $url;
}

=method endpoint_f

    my $url = await $oidc->endpoint_f('device_authorization_endpoint');

=cut

sub token_endpoint_f    { $_[0]->endpoint_f('token_endpoint') }
sub userinfo_endpoint_f { $_[0]->endpoint_f('userinfo_endpoint') }
sub device_endpoint_f   { $_[0]->endpoint_f('device_authorization_endpoint') }

async sub jwks_f {
  my ( $self, %opt ) = @_;
  if ( $opt{force_refresh} || !$self->_jwks ) {
    my $uri = await $self->endpoint_f('jwks_uri');
    $self->_jwks( ( await $self->send_request_f( GET => $uri ) )->{data} );
    $self->_jwks_fetched( $self->now->() );
  }
  return $self->_jwks;
}

=method jwks_f

    my $keys = await $oidc->jwks_f( force_refresh => 1 );

=cut

async sub verify_token_f {
  my ( $self, $token, %opt ) = @_;
  $self->validation_error_class->throw( message => 'verify_token needs a token' ) unless defined $token && length $token;
  my %check = (
    token          => $token,
    verify_iss     => $self->issuer,
    verify_exp     => 1,
    accepted_alg   => $self->algorithms,
    decode_payload => 1,
    defined $opt{audience} ? ( verify_aud => $opt{audience} ) : ()
  );
  my $keys   = await $self->jwks_f;
  my $claims = eval { decode_jwt( %check, kid_keys => $keys ) };
  my $error  = $@;
  if ( !$claims && $error =~ /kid_keys lookup failed/ && $self->now->() - ( $self->_jwks_fetched // 0 ) >= $self->jwks_min_age ) {
    $keys   = await $self->jwks_f( force_refresh => 1 );
    $claims = eval { decode_jwt( %check, kid_keys => $keys ) };
    $error  = $@;
  }
  $self->_reject( $error =~ s/ at \S+ line \d+.*//sr ) unless $claims;
  $self->_reject( 'typ is '.( $claims->{typ} // 'missing' ).', expected '.$opt{type} )
    if defined $opt{type} && ( $claims->{typ} // '' ) ne $opt{type};
  return $claims;
}

sub _reject {
  my ( $self, $why ) = @_;
  $self->validation_error_class->throw( message => 'token rejected: '.$why );
}

=method verify_token_f

    my $claims = await $oidc->verify_token_f( $jwt, audience => 'my-api', type => 'Bearer' );

=cut

async sub userinfo_f {
  my ( $self, $access_token ) = @_;
  return ( await $self->send_request_f( GET => await( $self->userinfo_endpoint_f ), bearer => $access_token ) )->{data};
}

async sub introspect_f {
  my ( $self, $token, %client ) = @_;
  return await $self->_token_call_f( await( $self->endpoint_f('introspection_endpoint') ), { token => $token }, %client );
}

sub password_token_f           { my ( $self, %arg ) = @_; $self->_grant_f( password => [qw( username password totp scope )], %arg ) }
sub client_credentials_token_f { my ( $self, %arg ) = @_; $self->_grant_f( client_credentials => ['scope'], %arg ) }
sub refresh_token_f            { my ( $self, $refresh, %arg ) = @_; $self->_grant_f( refresh_token => [qw( refresh_token scope )], %arg, refresh_token => $refresh ) }
sub exchange_authorization_code_f { my ( $self, %arg ) = @_; $self->_grant_f( authorization_code => [qw( code redirect_uri code_verifier )], %arg ) }
sub device_token_f             { my ( $self, %arg ) = @_; $self->_grant_f( 'urn:ietf:params:oauth:grant-type:device_code' => ['device_code'], %arg ) }

async sub device_authorization_f {
  my ( $self, %arg ) = @_;
  return await $self->_token_call_f( await( $self->device_endpoint_f ), { defined $arg{scope} ? ( scope => $arg{scope} ) : () }, %arg );
}

async sub logout_f {
  my ( $self, %arg ) = @_;
  await $self->_token_call_f( await( $self->endpoint_f('end_session_endpoint') ), { refresh_token => $arg{refresh_token} }, %arg );
  return 1;
}

=method userinfo_f

=method introspect_f

=method password_token_f

=method client_credentials_token_f

=method refresh_token_f

=method exchange_authorization_code_f

=method device_authorization_f

=method device_token_f

=method logout_f

As the methods without C<_f> in L<WWW::Keycloak::OIDC>, returning futures. A
pending device-flow poll fails with an API error whose C<oauth_error> is
C<authorization_pending>.

=cut

async sub _grant_f {
  my ( $self, $type, $fields, %arg ) = @_;
  return await $self->_token_call_f( await( $self->token_endpoint_f ),
    { grant_type => $type, map { $_ => $arg{$_} } grep { defined $arg{$_} } @$fields }, %arg );
}

async sub _token_call_f {
  my ( $self, $url, $form, %arg ) = @_;
  $self->validation_error_class->throw( message => 'a client_id is needed' ) unless defined $arg{client_id};
  my %form = ( %$form, client_id => $arg{client_id}, defined $arg{client_secret} ? ( client_secret => $arg{client_secret} ) : () );
  return ( await $self->send_request_f( POST => $url, form => \%form ) )->{data} // {};
}

1;
```

`lib/Net/Async/Keycloak/Admin.pm`:

```perl
package Net::Async::Keycloak::Admin;

# ABSTRACT: Keycloak Admin REST API for one realm, asynchronously, with idempotent ensure methods

use Moo;
with 'Net::Async::Keycloak::Role::HTTP';
with 'WWW::Keycloak::Role::HTTP';
use Future;
use Future::AsyncAwait;
use Scalar::Util qw( blessed );
use Types::Standard qw( InstanceOf Object Str );
use Net::Async::Keycloak::Error;
use URI::Escape qw( uri_escape_utf8 );
use WWW::Keycloak::Diff;
use namespace::autoclean;

our $VERSION = '0.001';

=synopsis

    my $admin = $kc->admin;

    my $client = await $admin->find_client_f('my-cli');
    my $r      = await $admin->ensure_client_f( clientId => 'my-cli', publicClient => \1 );

=description

The asynchronous L<WWW::Keycloak::Admin>: every method with C<_f>, returning a
future of what the sync method returns. The rules of the C<ensure_*_f> methods
are the same, and so is the comparison: both use L<WWW::Keycloak::Diff>.

=cut

has base_url => ( is => 'ro', isa => Str, required => 1 );
has realm    => ( is => 'ro', isa => Str, required => 1 );
has http     => ( is => 'ro', isa => Object, required => 1 );
has auth     => ( is => 'ro', isa => InstanceOf['Net::Async::Keycloak::Auth'], predicate => 'has_auth' );

=attr base_url

=attr realm

=attr http

=attr auth

As in L<WWW::Keycloak::Admin>, with a L<Net::Async::HTTP> as C<http> and a
L<Net::Async::Keycloak::Auth> as C<auth>.

=cut

sub diff_class { 'WWW::Keycloak::Diff' }

####  transport

sub realm_url { $_[0]->base_url.'/admin/realms/'.uri_escape_utf8( $_[0]->realm ) }

async sub call_f {
  my ( $self, $method, $path, $body ) = @_;
  my $url = $path =~ m{\A/admin/} ? $self->base_url.$path : $self->realm_url.$path;
  $self->validation_error_class->throw( message => 'the Admin API needs credentials: give username and password, client_id and client_secret, or token' )
    unless $self->has_auth;
  my %arg    = defined $body ? ( json => $body ) : ();
  my $bearer = await $self->auth->token_f;   # outside the eval: a failed login is not a refused token
  my $result = eval { await $self->send_request_f( $method, $url, %arg, bearer => $bearer ) };
  if ( my $error = $@ ) {
    die $error unless blessed $error && $error->isa('WWW::Keycloak::Error::API') && $error->is_unauthorized && $self->auth->renewable;
    $self->auth->invalidate;
    $result = await $self->send_request_f( $method, $url, %arg, bearer => await( $self->auth->token_f ) );
  }
  return $result;
}

=method call_f

    my $result = await $admin->call_f( GET => '/clients?clientId=x' );

As C<call> in L<WWW::Keycloak::Admin>.

=cut

async sub _data_f { return ( await $_[0]->call_f( @_[ 1 .. $#_ ] ) )->{data} }
async sub _done_f { await $_[0]->call_f( @_[ 1 .. $#_ ] ); return 1 }

async sub _create_f {
  my ( $self, $path, $body ) = @_;
  my $location = ( await $self->call_f( POST => $path, $body ) )->{location} // '';
  my ( $id ) = $location =~ m{/([^/]+)\z};
  Net::Async::Keycloak::Error->throw( message => 'POST '.$path.' created something but sent no Location header' ) unless defined $id;
  return $id;
}

sub _esc { uri_escape_utf8( $_[1] ) }

sub _query {
  my ( $self, %query ) = @_;
  return '' unless %query;
  return '?'.join '&', map { $self->_esc($_).'='.$self->_esc( $query{$_} ) } sort keys %query;
}

####  server and realm

sub server_info_f  { $_[0]->_data_f( GET => '/admin/serverinfo' ) }
sub get_realm_f    { $_[0]->_data_f( GET => '' ) }
sub update_realm_f { $_[0]->_done_f( PUT => '', $_[1] ) }
sub delete_realm_f { $_[0]->_done_f( DELETE => '' ) }

async sub create_realm_f {
  my ( $self, $rep ) = @_;
  await $self->call_f( POST => '/admin/realms', { realm => $self->realm, %{ $rep || {} } } );
  return $self->realm;
}

sub export_realm_f {
  my ( $self, %opt ) = @_;
  return $self->_data_f( POST => '/partial-export'.$self->_query(
    exportClients        => $opt{clients} ? 'true' : 'false',
    exportGroupsAndRoles => $opt{groups_and_roles} ? 'true' : 'false'
  ) );
}

sub partial_import_f {
  my ( $self, $rep, %opt ) = @_;
  return $self->_data_f( POST => '/partialImport', { ifResourceExists => $opt{if_exists} // 'FAIL', %$rep } );
}

####  clients

sub list_clients_f  { my ( $self, %q ) = @_; $self->_data_f( GET => '/clients'.$self->_query(%q) ) }
sub get_client_f    { $_[0]->_data_f( GET => '/clients/'.$_[0]->_esc( $_[1] ) ) }
sub create_client_f { $_[0]->_create_f( '/clients', $_[1] ) }
sub update_client_f { $_[0]->_done_f( PUT => '/clients/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_client_f { $_[0]->_done_f( DELETE => '/clients/'.$_[0]->_esc( $_[1] ) ) }

async sub find_client_f {
  my ( $self, $client_id ) = @_;
  my ( $client ) = grep { $_->{clientId} eq $client_id } @{ await $self->list_clients_f( clientId => $client_id ) };
  return $client;
}

sub get_client_secret_f        { $_[0]->_data_f( GET => '/clients/'.$_[0]->_esc( $_[1] ).'/client-secret' ) }
sub regenerate_client_secret_f { $_[0]->_data_f( POST => '/clients/'.$_[0]->_esc( $_[1] ).'/client-secret' ) }
sub get_service_account_user_f { $_[0]->_data_f( GET => '/clients/'.$_[0]->_esc( $_[1] ).'/service-account-user' ) }

####  client scopes

sub list_client_scopes_f  { $_[0]->_data_f( GET => '/client-scopes' ) }
sub get_client_scope_f    { $_[0]->_data_f( GET => '/client-scopes/'.$_[0]->_esc( $_[1] ) ) }
sub create_client_scope_f { $_[0]->_create_f( '/client-scopes', $_[1] ) }
sub update_client_scope_f { $_[0]->_done_f( PUT => '/client-scopes/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_client_scope_f { $_[0]->_done_f( DELETE => '/client-scopes/'.$_[0]->_esc( $_[1] ) ) }

async sub find_client_scope_f {
  my ( $self, $name ) = @_;
  my ( $scope ) = grep { $_->{name} eq $name } @{ await $self->list_client_scopes_f };
  return $scope;
}

sub add_default_client_scope_f {
  my ( $self, $client, $scope ) = @_;
  return $self->_done_f( PUT => '/clients/'.$self->_esc($client).'/default-client-scopes/'.$self->_esc($scope) );
}

sub add_realm_default_client_scope_f { $_[0]->_done_f( PUT => '/default-default-client-scopes/'.$_[0]->_esc( $_[1] ) ) }

####  protocol mappers

sub _mapper_path {
  my ( $self, $kind, $owner ) = @_;
  $self->validation_error_class->throw( message => 'protocol mappers belong to a client or a client_scope, not to '.( $kind // 'nothing' ) )
    unless defined $kind && ( $kind eq 'client' || $kind eq 'client_scope' );
  return ( $kind eq 'client' ? '/clients/' : '/client-scopes/' ).$self->_esc($owner).'/protocol-mappers/models';
}

async sub list_protocol_mappers_f  { my ( $self, $kind, $owner ) = @_; return await $self->_data_f( GET => $self->_mapper_path( $kind, $owner ) ) }
async sub create_protocol_mapper_f { my ( $self, $kind, $owner, $rep ) = @_; return await $self->_create_f( $self->_mapper_path( $kind, $owner ), $rep ) }

async sub update_protocol_mapper_f {
  my ( $self, $kind, $owner, $id, $rep ) = @_;
  return await $self->_done_f( PUT => $self->_mapper_path( $kind, $owner ).'/'.$self->_esc($id), $rep );
}

async sub delete_protocol_mapper_f {
  my ( $self, $kind, $owner, $id ) = @_;
  return await $self->_done_f( DELETE => $self->_mapper_path( $kind, $owner ).'/'.$self->_esc($id) );
}

####  users

sub list_users_f  { my ( $self, %q ) = @_; $self->_data_f( GET => '/users'.$self->_query(%q) ) }
sub get_user_f    { $_[0]->_data_f( GET => '/users/'.$_[0]->_esc( $_[1] ) ) }
sub create_user_f { $_[0]->_create_f( '/users', $_[1] ) }
sub update_user_f { $_[0]->_done_f( PUT => '/users/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_user_f { $_[0]->_done_f( DELETE => '/users/'.$_[0]->_esc( $_[1] ) ) }

async sub find_user_f {
  my ( $self, $username ) = @_;
  my ( $user ) = grep { lc $_->{username} eq lc $username } @{ await $self->list_users_f( username => $username, exact => 'true' ) };
  return $user;
}

sub set_password_f {
  my ( $self, $id, $password, %opt ) = @_;
  return $self->_done_f( PUT => '/users/'.$self->_esc($id).'/reset-password',
    { type => 'password', value => $password, temporary => $opt{temporary} ? \1 : \0 } );
}

sub list_credentials_f  { $_[0]->_data_f( GET => '/users/'.$_[0]->_esc( $_[1] ).'/credentials' ) }
sub delete_credential_f { $_[0]->_done_f( DELETE => '/users/'.$_[0]->_esc( $_[1] ).'/credentials/'.$_[0]->_esc( $_[2] ) ) }
sub list_sessions_f     { $_[0]->_data_f( GET => '/users/'.$_[0]->_esc( $_[1] ).'/sessions' ) }
sub logout_user_f       { $_[0]->_done_f( POST => '/users/'.$_[0]->_esc( $_[1] ).'/logout' ) }

####  authentication

sub list_flows_f              { $_[0]->_data_f( GET => '/authentication/flows' ) }
sub list_executions_f         { $_[0]->_data_f( GET => '/authentication/flows/'.$_[0]->_esc( $_[1] ).'/executions' ) }
sub copy_flow_f               { $_[0]->_create_f( '/authentication/flows/'.$_[0]->_esc( $_[1] ).'/copy', { newName => $_[2] } ) }
sub get_execution_config_f    { $_[0]->_data_f( GET => '/authentication/config/'.$_[0]->_esc( $_[1] ) ) }
sub create_execution_config_f { $_[0]->_create_f( '/authentication/executions/'.$_[0]->_esc( $_[1] ).'/config', $_[2] ) }
sub update_execution_config_f { $_[0]->_done_f( PUT => '/authentication/config/'.$_[0]->_esc( $_[1] ), { %{ $_[2] }, id => $_[1] } ) }
sub describe_authenticator_f  { $_[0]->_data_f( GET => '/authentication/config-description/'.$_[0]->_esc( $_[1] ) ) }

=method server_info_f

=method get_realm_f

=method create_realm_f

=method update_realm_f

=method delete_realm_f

=method export_realm_f

=method partial_import_f

=method list_clients_f

=method find_client_f

=method get_client_f

=method create_client_f

=method update_client_f

=method delete_client_f

=method get_client_secret_f

=method regenerate_client_secret_f

=method get_service_account_user_f

=method list_client_scopes_f

=method find_client_scope_f

=method get_client_scope_f

=method create_client_scope_f

=method update_client_scope_f

=method delete_client_scope_f

=method add_default_client_scope_f

=method add_realm_default_client_scope_f

=method list_protocol_mappers_f

=method create_protocol_mapper_f

=method update_protocol_mapper_f

=method delete_protocol_mapper_f

=method list_users_f

=method find_user_f

=method get_user_f

=method create_user_f

=method update_user_f

=method delete_user_f

=method set_password_f

=method list_credentials_f

=method delete_credential_f

=method list_sessions_f

=method logout_user_f

=method list_flows_f

=method list_executions_f

=method copy_flow_f

=method get_execution_config_f

=method create_execution_config_f

=method update_execution_config_f

=method describe_authenticator_f

The methods of L<WWW::Keycloak::Admin> with the same name without C<_f>,
taking the same arguments and returning a future of the same result. A failure
is a failed future with a L<Net::Async::Keycloak::Error::API>.

=cut

####  ensure

async sub _ensure_f {
  my ( $self, %arg ) = @_;
  my $current = await $arg{find}->();
  return { id => await( $arg{create}->() ), changed => 'created' } unless $current;
  my $changes = $self->diff_class->changes( $current, $arg{wanted} );
  return { id => $arg{id}->($current), changed => '' } unless %$changes;
  await $arg{update}->( $current, $changes );
  return { id => $arg{id}->($current), changed => 'updated' };
}

sub ensure_realm_f {
  my ( $self, %rep ) = @_;
  return $self->_ensure_f(
    wanted => \%rep,
    find   => sub {
      $self->get_realm_f->else( sub {
        my ( $error ) = @_;
        return Future->done(undef) if blessed $error && $error->isa('WWW::Keycloak::Error::API') && $error->is_not_found;
        return Future->fail($error);
      } );
    },
    create => sub { $self->create_realm_f( \%rep ) },
    update => sub { $self->update_realm_f( $_[1] ) },
    id     => sub { $_[0]->{realm} }
  );
}

sub ensure_client_f {
  my ( $self, %rep ) = @_;
  return $self->fail_validation('ensure_client needs a clientId') unless defined $rep{clientId};
  for my $ignored (qw( defaultClientScopes optionalClientScopes protocolMappers )) {
    return $self->fail_validation( 'ensure_client cannot set '.$ignored
      .': Keycloak ignores it when a client is updated; use add_default_client_scope or ensure_protocol_mapper' )
      if exists $rep{$ignored};
  }
  return $self->_ensure_f(
    wanted => \%rep,
    find   => sub { $self->find_client_f( $rep{clientId} ) },
    create => sub { $self->create_client_f( \%rep ) },
    update => sub { $self->update_client_f( $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}

sub ensure_client_scope_f {
  my ( $self, %rep ) = @_;
  return $self->fail_validation('ensure_client_scope needs a name') unless defined $rep{name};
  return $self->_ensure_f(
    wanted => \%rep,
    find   => sub { $self->find_client_scope_f( $rep{name} ) },
    create => sub { $self->create_client_scope_f( { protocol => 'openid-connect', %rep } ) },
    update => sub { $self->update_client_scope_f( $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}

async sub ensure_protocol_mapper_f {
  my ( $self, $kind, $owner_key, %rep ) = @_;
  $self->validation_error_class->throw( message => 'ensure_protocol_mapper needs a name' ) unless defined $rep{name};
  my $owner = $kind && $kind eq 'client' ? await( $self->find_client_f($owner_key) )
    : $kind && $kind eq 'client_scope' ? await( $self->find_client_scope_f($owner_key) )
    : $self->_mapper_path($kind);
  $self->validation_error_class->throw( message => 'ensure_protocol_mapper: no '.$kind.' '.$owner_key ) unless $owner;
  return await $self->_ensure_f(
    wanted => \%rep,
    find   => sub {
      $self->list_protocol_mappers_f( $kind, $owner->{id} )->then( sub {
        Future->done( ( grep { $_->{name} eq $rep{name} } @{ $_[0] } )[0] );
      } );
    },
    create => sub { $self->create_protocol_mapper_f( $kind, $owner->{id}, { protocol => 'openid-connect', %rep } ) },
    update => sub { $self->update_protocol_mapper_f( $kind, $owner->{id}, $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}

sub ensure_user_f {
  my ( $self, %rep ) = @_;
  return $self->fail_validation('ensure_user needs a username') unless defined $rep{username};
  # Keycloak keeps user names and e-mail addresses in lower case
  my %compare = %rep;
  delete $compare{credentials};
  $compare{$_} = lc $compare{$_} for grep { defined $compare{$_} } qw( username email );
  # Keycloak keeps every user attribute as a list of strings
  $compare{attributes} = { map { $_ => ref $rep{attributes}{$_} eq 'ARRAY' ? $rep{attributes}{$_} : [ $rep{attributes}{$_} ] } keys %{ $rep{attributes} } }
    if ref $rep{attributes} eq 'HASH';
  return $self->_ensure_f(
    wanted => \%compare,
    find   => sub { $self->find_user_f( $rep{username} ) },
    create => sub { $self->create_user_f( \%rep ) },
    # the whole user: Keycloak's user profile drops fields a PUT with attributes does not name
    update => sub { $self->update_user_f( $_[0]{id}, $self->diff_class->merge( $_[0], $_[1] ) ) },
    id     => sub { $_[0]->{id} }
  );
}

async sub ensure_execution_config_f {
  my ( $self, %arg ) = @_;
  for (qw( flow authenticator config )) {
    $self->validation_error_class->throw( message => 'ensure_execution_config needs '.$_ ) unless defined $arg{$_};
  }
  my ( $execution ) = grep { ( $_->{providerId} // '' ) eq $arg{authenticator} } @{ await $self->list_executions_f( $arg{flow} ) };
  $self->validation_error_class->throw( message => 'flow "'.$arg{flow}.'" has no step '.$arg{authenticator} ) unless $execution;
  my $alias = $arg{alias} // $arg{flow}.' '.$arg{authenticator};
  return await $self->_ensure_f(
    wanted => { config => $arg{config} },
    find   => sub { $execution->{authenticationConfig} ? $self->get_execution_config_f( $execution->{authenticationConfig} ) : Future->done(undef) },
    create => sub { $self->create_execution_config_f( $execution->{id}, { alias => $alias, config => $arg{config} } ) },
    update => sub { $self->update_execution_config_f( $_[0]{id}, { alias => $_[0]{alias}, config => $arg{config} } ) },
    id     => sub { $_[0]->{id} }
  );
}

=method ensure_realm_f

=method ensure_client_f

=method ensure_client_scope_f

=method ensure_protocol_mapper_f

=method ensure_user_f

=method ensure_execution_config_f

    my $r = await $admin->ensure_client_f( clientId => 'my-cli', publicClient => \1 );

As the C<ensure_*> methods of L<WWW::Keycloak::Admin>, with the same rules and
the same comparison, returning a future of C<< { id => ..., changed => ... } >>.

=cut

1;
```

`lib/Net/Async/Keycloak.pm`:

```perl
package Net::Async::Keycloak;

# ABSTRACT: Async Perl client for Keycloak identity management (IO::Async + Future)

use Moo;
extends 'IO::Async::Notifier';
use Net::Async::HTTP;
use Net::Async::Keycloak::Admin;
use Net::Async::Keycloak::Auth;
use Net::Async::Keycloak::Error;
use Net::Async::Keycloak::Error::API;
use Net::Async::Keycloak::Error::Network;
use Net::Async::Keycloak::Error::Validation;
use Net::Async::Keycloak::OIDC;
use Types::Standard qw( InstanceOf Object Str );
use URI::Escape qw( uri_escape_utf8 );

our $VERSION = '0.001';

=synopsis

    use IO::Async::Loop;
    use Future::AsyncAwait;
    use Net::Async::Keycloak;

    my $loop = IO::Async::Loop->new;
    my $kc   = Net::Async::Keycloak->new(
      base_url => 'https://id.example.org',
      realm    => 'main',
      username => 'admin',
      password => $ENV{KEYCLOAK_ADMIN_PASSWORD},
    );
    $loop->add($kc);

    my $claims = await $kc->oidc->verify_token_f( $jwt, audience => 'my-api', type => 'Bearer' );
    my $r      = await $kc->admin->ensure_client_f( clientId => 'my-cli', publicClient => \1 );

=description

The asynchronous twin of L<WWW::Keycloak>, on L<IO::Async> and L<Future>: the
same facade, the same parts, every method with C<_f> returning a future.
Requests are built and responses read by the same code as in the sync client,
and the C<ensure_*_f> methods compare with the same L<WWW::Keycloak::Diff>, so
both clients do the same thing to a realm.

Add the object to a loop before the first request: the L<Net::Async::HTTP> it
sends through is its child notifier.

=cut

# IO::Async::Notifier->new hands every constructor key to configure(), which
# croaks on keys it does not know. Keep ours away from it.
sub FOREIGNBUILDARGS {
  my ( $class, %arg ) = @_;
  delete @arg{qw( base_url realm username password client_id client_secret token auth_realm http auth )};
  return %arg;
}

has base_url => ( is => 'ro', isa => Str, required => 1 );
has realm    => ( is => 'ro', isa => Str, required => 1 );

=attr base_url

=attr realm

Required, as in L<WWW::Keycloak>. A trailing slash on C<base_url> is removed.

=cut

has username      => ( is => 'ro', isa => Str, predicate => 'has_username' );
has password      => ( is => 'ro', isa => Str );
has client_id     => ( is => 'ro', isa => Str, predicate => 'has_client_id' );
has client_secret => ( is => 'ro', isa => Str );
has token         => ( is => 'ro', isa => Str, predicate => 'has_token' );

=attr username

=attr password

=attr client_id

=attr client_secret

=attr token

The admin login, as in L<WWW::Keycloak>.

=cut

has auth_realm => ( is => 'lazy', isa => Str );

sub _build_auth_realm { $_[0]->has_username ? 'master' : $_[0]->realm }

=attr auth_realm

As in L<WWW::Keycloak>.

=cut

has http => ( is => 'lazy', isa => Object, predicate => 'has_http' );

sub _build_http {
  my ( $self ) = @_;
  # no redirects: nothing here needs one, and none may carry the admin token elsewhere
  my $http = Net::Async::HTTP->new( user_agent => 'Net-Async-Keycloak/'.$VERSION, max_redirects => 0, timeout => 30, fail_on_error => 0 );
  $self->add_child($http);
  return $http;
}

=attr http

The L<Net::Async::HTTP> every part shares, built as a child of this notifier.
Pass one in to share it; it is then not added as a child.

=cut

has auth => ( is => 'lazy', isa => InstanceOf['Net::Async::Keycloak::Auth'] | Types::Standard::Undef );

sub _build_auth {
  my ( $self ) = @_;
  return Net::Async::Keycloak::Auth->new( http => $self->http, token => $self->token ) if $self->has_token;
  return unless $self->has_username || $self->has_client_id;
  return Net::Async::Keycloak::Auth->new(
    http           => $self->http,
    token_endpoint => $self->base_url.'/realms/'.uri_escape_utf8( $self->auth_realm ).'/protocol/openid-connect/token',
    map { $_ => $self->$_ } grep { defined $self->$_ } qw( username password client_id client_secret )
  );
}

=attr auth

The L<Net::Async::Keycloak::Auth>, or undef without admin login.

=cut

has oidc => ( is => 'lazy', init_arg => undef );

sub _build_oidc { Net::Async::Keycloak::OIDC->new( issuer => $_[0]->issuer, http => $_[0]->http ) }

=attr oidc

The L<Net::Async::Keycloak::OIDC> of this realm.

=cut

has admin => ( is => 'lazy', init_arg => undef );

sub _build_admin {
  my ( $self ) = @_;
  return Net::Async::Keycloak::Admin->new(
    base_url => $self->base_url,
    realm    => $self->realm,
    http     => $self->http,
    $self->auth ? ( auth => $self->auth ) : ()
  );
}

=attr admin

The L<Net::Async::Keycloak::Admin> of this realm.

=cut

# The parent is not a Moo class, so there is no BUILDARGS to wrap.
sub BUILDARGS {
  my ( $class, @args ) = @_;
  my %args = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
  $args{base_url} =~ s{/+\z}{} if defined $args{base_url};
  return \%args;
}

sub BUILD {
  my ( $self ) = @_;
  for (qw( base_url realm )) {
    Net::Async::Keycloak::Error::Validation->throw( message => __PACKAGE__.' needs a '.$_ ) unless length $self->$_;
  }
  return;
}

sub issuer { $_[0]->base_url.'/realms/'.uri_escape_utf8( $_[0]->realm ) }

=method issuer

=cut

sub for_realm {
  my ( $self, $realm ) = @_;
  return ref($self)->new(
    base_url   => $self->base_url,
    realm      => $realm,
    http       => $self->http,
    auth_realm => $self->auth_realm,
    $self->auth ? ( auth => $self->auth ) : ()
  );
}

=method for_realm

    my $dev = $kc->for_realm('dev');

The same client for another realm, sharing the L<Net::Async::HTTP> and the
admin login. The new object is not a notifier of its own in any loop; it sends
through the shared C<http>.

=cut

1;
```

- [ ] **Step 3: Tests laufen lassen, Übergabe**

Run: `prove -lr t` — Expected: PASS (3, 9, 6 und 7 Subtests in den neuen Dateien). Betreff: `Add OIDC, Admin API and the facade`.

---

### Task 3: Fehler- und Async-Tests, Live-Suite, README

**Files:**
- Test: `t/20-errors.t`, `t/70-async.t`, `t/90-live-keycloak.t`
- Create: `t/keycloak/k8s.yaml` (Kopie aus `p5-www-keycloak`)
- Modify: `README.md`

- [ ] **Step 1: Tests schreiben**

`t/20-errors.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use IO::Async::Loop;
use Scalar::Util qw( blessed );
use FakeKeycloak;
use FakeHTTP;
use Net::Async::Keycloak;

my $fake = FakeKeycloak->new;
my $http = FakeHTTP->new( fake => $fake );
my $kc   = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'master', username => 'admin', password => 'admin', http => $http );

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

subtest 'classes and stringification' => sub {
  my $e = Net::Async::Keycloak::Error::API->new( message => 'boom', http_status => 409 );
  isa_ok( $e, 'Net::Async::Keycloak::Error' );
  is( "$e", 'boom', 'stringifies to the message' );
  ok( $e->is_conflict && !$e->is_not_found && !$e->is_unauthorized, 'predicates' );
  isa_ok( Net::Async::Keycloak::Error::Validation->new( message => 'x' ), 'Net::Async::Keycloak::Error' );
  isa_ok( Net::Async::Keycloak::Error::Network->new( message => 'x' ), 'Net::Async::Keycloak::Error' );
  my $thrown = error_of { Net::Async::Keycloak::Error::Validation->throw( message => 'thrown' ) };
  isa_ok( $thrown, 'Net::Async::Keycloak::Error::Validation', 'throw' );
};

subtest 'the three shapes Keycloak answers errors in' => sub {
  my $conflict = error_of { $kc->admin->create_realm_f->get };
  isa_ok( $conflict, 'Net::Async::Keycloak::Error::API' );
  is( $conflict->http_status, 409, 'status as a number' );
  is( $conflict->api_message, 'Realm master already exists', 'errorMessage' );
  ok( $conflict->is_conflict, 'is_conflict' );
  like( "$conflict", qr{POST http://kc.test/admin/realms failed: 409 .* - Realm master already exists}, 'message names the request' );

  my $missing = error_of { $kc->admin->get_client_f('nope')->get };
  ok( $missing->is_not_found, 'is_not_found' );
  is( $missing->api_message, 'Could not find client', 'error' );
  is( $missing->oauth_error, undef, 'an admin error is no OAuth error' );

  my $oauth = error_of { $kc->oidc->password_token_f( client_id => 'cli', username => 'x', password => 'y' )->get };
  is( $oauth->oauth_error, 'invalid_grant', 'oauth_error from the token endpoint' );
  is( $oauth->api_message, 'invalid_grant: Invalid user credentials', 'with the description' );
};

subtest 'no answer at all' => sub {
  my $loop = IO::Async::Loop->new;
  my $down = Net::Async::Keycloak->new( base_url => 'http://127.0.0.1:9', realm => 'x' );
  $loop->add($down);
  my $future = $down->oidc->discovery_f;
  $loop->await($future);
  my $error = $future->failure;
  isa_ok( $error, 'Net::Async::Keycloak::Error::Network' );
  like( "$error", qr{GET http://127.0.0.1:9/realms/x/.well-known/openid-configuration: }, 'names the request' );
};

done_testing;
```

`t/70-async.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Future;
use FakeKeycloak;
use Net::Async::Keycloak;

# A Net::Async::HTTP stand-in whose answers arrive only when the test says so,
# to see what happens while requests are under way.
{
  package DeferredHTTP;
  sub new { bless { fake => $_[1], queue => [] }, $_[0] }
  sub pending { scalar @{ $_[0]{queue} } }
  sub do_request {
    my ( $self, %arg ) = @_;
    my $future = Future->new;
    push @{ $self->{queue} }, [ $future, $arg{request} ];
    return $future;
  }
  sub answer_all {
    my ( $self ) = @_;
    while ( my $next = shift @{ $self->{queue} } ) { $next->[0]->done( $self->{fake}->request( $next->[1] ) ) }
    return;
  }
}

my $fake = FakeKeycloak->new;

subtest 'callers waiting for a token share one login' => sub {
  my $http = DeferredHTTP->new($fake);
  my $auth = Net::Async::Keycloak::Auth->new( http => $http, token_endpoint => $fake->base.'/realms/master/protocol/openid-connect/token', username => 'admin', password => 'admin' );
  @{ $fake->logins } = ();
  my @waiting = map { $auth->token_f } 1 .. 3;
  is( $http->pending, 1, 'three callers, one request' );
  ok( !$waiting[0]->is_ready, 'nobody has a token yet' );
  $http->answer_all;
  ok( !grep( { !$_->is_done } @waiting ), 'all three are served' );
  my %seen = map { $_->get => 1 } @waiting;
  is( scalar keys %seen, 1, 'with the same token' );
  is( scalar @{ $fake->logins }, 1, 'from one login' );
  is( $auth->token_f->get, $waiting[0]->get, 'and the next caller gets it at once' );
  is( $http->pending, 0, 'without a request' );
};

subtest 'a failed login does not stick' => sub {
  my $http = DeferredHTTP->new($fake);
  my $auth = Net::Async::Keycloak::Auth->new( http => $http, token_endpoint => $fake->base.'/realms/master/protocol/openid-connect/token', username => 'admin', password => 'nope' );
  my $first = $auth->token_f;
  $http->answer_all;
  ok( $first->is_failed, 'the login fails' );
  my $second = $auth->token_f;
  is( $http->pending, 1, 'the next caller tries again instead of getting the old failure' );
  $http->answer_all;
};

subtest 'requests run side by side' => sub {
  my $http  = DeferredHTTP->new($fake);
  my $kc    = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'master', token => 'x', http => $http );
  $fake->{tokens}{x} = 1;
  my @calls = ( $kc->admin->get_realm_f, $kc->admin->list_clients_f, $kc->admin->list_users_f );
  is( $http->pending, 3, 'three requests are out at once' );
  $http->answer_all;
  ok( !grep( { !$_->is_done } @calls ), 'and all three complete' );
};

done_testing;
```

`t/90-live-keycloak.t`:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Live test against a real Keycloak, the same as WWW::Keycloak's, through
# Net::Async::Keycloak. Off unless KEYCLOAK_LIVE_TEST=1 and
# KEYCLOAK_URL point at one; KEYCLOAK_ADMIN and KEYCLOAK_ADMIN_PASSWORD are
# the bootstrap admin (default admin/admin). The test creates a realm with a
# random name, works only inside it, and deletes it at the end.

BEGIN {
  plan skip_all => 'set KEYCLOAK_LIVE_TEST=1 and KEYCLOAK_URL to run the Keycloak live test'
    unless $ENV{KEYCLOAK_LIVE_TEST} && $ENV{KEYCLOAK_URL};
}

use Crypt::JWT qw( decode_jwt );
use IO::Async::Loop;
use Digest::SHA qw( hmac_sha1 );
use Net::Async::Keycloak;

my $realm = 'wwwkc-live-'.join '', map { ( 'a' .. 'z' )[ rand 26 ] } 1 .. 8;
my $kc    = Net::Async::Keycloak->new(
  base_url => $ENV{KEYCLOAK_URL},
  realm    => $realm,
  username => $ENV{KEYCLOAK_ADMIN} // 'admin',
  password => $ENV{KEYCLOAK_ADMIN_PASSWORD} // 'admin'
);
my $loop = IO::Async::Loop->new;
$loop->add($kc);
my $admin = $kc->admin;
my $secret = '12345678901234567890';

# RFC 6238 with HMAC-SHA1, six digits
sub totp {
  my $step = int( time / 30 );
  my $mac  = hmac_sha1( pack( 'NN', int( $step / 4294967296 ), $step % 4294967296 ), $secret );
  my $off  = ord( substr $mac, -1 ) & 0x0f;
  return sprintf '%06d', ( unpack( 'N', substr $mac, $off, 4 ) & 0x7fffffff ) % 1_000_000;
}

sub twice {
  my ( $name, $code ) = @_;
  my $first  = $code->();
  my $second = $code->();
  is( $first->{changed}, 'created', $name.': created' );
  is( $second->{changed}, '', $name.': second run changes nothing' );
  is( $second->{id}, $first->{id}, $name.': same id' );
  return $first;
}

END { eval { $admin->delete_realm_f->get } if $admin }

subtest 'server' => sub {
  my $info = $admin->server_info_f->get;
  diag 'Keycloak '.$info->{systemInfo}{version};
  ok( grep( { $_->{id} eq 'oidc-amr-mapper' } @{ $info->{protocolMapperTypes}{'openid-connect'} } ), 'offers the AMR mapper' );
};

subtest 'a realm from nothing, twice' => sub {
  twice( realm => sub { $admin->ensure_realm_f( enabled => \1, displayName => 'WWW::Keycloak live test' )->get } );
  is( $admin->ensure_realm_f( accessTokenLifespan => 600 )->get->{changed}, 'updated', 'a realm setting changed' );
  is( $admin->get_realm_f->get->{displayName}, 'WWW::Keycloak live test', 'the others kept' );

  twice( client => sub {
    $admin->ensure_client_f(
      clientId                  => 'live-cli',
      publicClient              => \1,
      standardFlowEnabled       => \0,
      directAccessGrantsEnabled => \1,
      attributes                => { 'oauth2.device.authorization.grant.enabled' => 'true' }
    )->get;
  } );
  is( $admin->ensure_client_f( clientId => 'live-cli', description => 'changed' )->get->{changed}, 'updated', 'client changed' );
  is( $admin->find_client_f('live-cli')->get->{attributes}{'oauth2.device.authorization.grant.enabled'}, 'true', 'the attribute kept' );

  twice( mapper => sub {
    $admin->ensure_protocol_mapper_f( client => 'live-cli', name => 'amr', protocolMapper => 'oidc-amr-mapper',
      config => { 'id.token.claim' => 'true', 'access.token.claim' => 'true' } )->get;
  } );
  twice( scope => sub { $admin->ensure_client_scope_f( name => 'live-scope', description => 'x' )->get } );
  twice( user => sub {
    $admin->ensure_user_f(
      username      => 'Live-User',
      email         => 'Live@Example.org',
      firstName     => 'Live',
      lastName      => 'User',
      enabled       => \1,
      emailVerified => \1,
      credentials   => [
        { type => 'password', value => 'live-password', temporary => \0 },
        { type => 'otp', secretData => '{"value":"'.$secret.'"}',
          credentialData => '{"subType":"totp","digits":6,"counter":0,"period":30,"algorithm":"HmacSHA1"}' }
      ]
    )->get;
  } );
  is_deeply( [ sort map { $_->{type} } @{ $admin->list_credentials_f( $admin->find_user_f('live-user')->get->{id} )->get } ], [qw( otp password )], 'password and OTP set at creation' );

  $admin->ensure_user_f( username => 'live-user', attributes => { dept => 'x' } )->get;
  my $user = $admin->find_user_f('live-user')->get;
  is_deeply( [ @$user{qw( email firstName lastName )} ], [ 'live@example.org', 'Live', 'User' ], 'a write with attributes keeps the profile fields' );

  twice( 'unsorted redirect URIs' => sub {
    $admin->ensure_client_f( clientId => 'live-web', redirectUris => [ 'https://b.example/*', 'https://a.example/*', 'https://c.example/*' ] )->get;
  } );

  for my $step ( [ 'direct grant', 'direct-grant-validate-password', 'pwd' ], [ 'direct grant', 'direct-grant-validate-otp', 'otp' ] ) {
    my %arg = ( flow => $step->[0], authenticator => $step->[1], config => { 'default.reference.value' => $step->[2], 'default.reference.maxAge' => 3600 } );
    is( $admin->ensure_execution_config_f(%arg)->get->{changed}, 'created', $step->[1].': created' );
    is( $admin->ensure_execution_config_f(%arg)->get->{changed}, 'updated', $step->[1].': written again, Keycloak hides the values' );
  }
};

subtest 'OIDC against the new realm' => sub {
  my $oidc   = $kc->oidc;
  my $tokens = $oidc->password_token_f( client_id => 'live-cli', username => 'live-user', password => 'live-password', totp => totp(), scope => 'openid' )->get;
  ok( $tokens->{access_token}, 'a login with password and TOTP' );
  my $claims = $oidc->verify_token_f( $tokens->{id_token}, audience => 'live-cli' )->get;
  is( $claims->{preferred_username}, 'live-user', 'verify_token' );
  is_deeply( $claims->{amr}, [qw( pwd otp )], 'amr reports both steps' );
  is( $oidc->userinfo_f( $tokens->{access_token} )->get->{preferred_username}, 'live-user', 'userinfo' );
  ok( $oidc->refresh_token_f( $tokens->{refresh_token}, client_id => 'live-cli' )->get->{access_token}, 'refresh_token' );

  my $wrong = eval { $oidc->password_token_f( client_id => 'live-cli', username => 'live-user', password => 'live-password' )->get; 1 } ? undef : $@;
  is( $wrong && $wrong->oauth_error, 'invalid_grant', 'without the TOTP code: invalid_grant' );

  my $start = $oidc->device_authorization_f( client_id => 'live-cli', scope => 'openid' )->get;
  like( $start->{verification_uri_complete}, qr/\Q$start->{user_code}\E/, 'device_authorization' );
  my $pending = eval { $oidc->device_token_f( device_code => $start->{device_code}, client_id => 'live-cli' )->get; 1 } ? undef : $@;
  is( $pending && $pending->oauth_error, 'authorization_pending', 'device_token before approval' );

  ok( $oidc->logout_f( refresh_token => $tokens->{refresh_token}, client_id => 'live-cli' )->get, 'logout' );
  my $after = eval { $oidc->refresh_token_f( $tokens->{refresh_token}, client_id => 'live-cli' )->get; 1 } ? undef : $@;
  is( $after && $after->oauth_error, 'invalid_grant', 'the refresh token is dead after logout' );
};

subtest 'clean up' => sub {
  ok( $admin->delete_realm_f->get, 'realm deleted' );
  my $gone = eval { $admin->get_realm_f->get; 1 } ? undef : $@;
  ok( $gone && $gone->is_not_found, 'and gone' );
  undef $admin;
};

done_testing;
```

- [ ] **Step 2: README ersetzen**

`README.md`:

````markdown
# Net-Async-Keycloak

Async Perl client for [Keycloak](https://www.keycloak.org/) on IO::Async and
Future: the twin of [WWW::Keycloak](../p5-www-keycloak), with the same facade,
the same parts and every method as `_f` returning a future.

```perl
use IO::Async::Loop;
use Future::AsyncAwait;
use Net::Async::Keycloak;

my $loop = IO::Async::Loop->new;
my $kc   = Net::Async::Keycloak->new(
  base_url => 'https://id.example.org',
  realm    => 'main',
  username => 'admin',
  password => $ENV{KEYCLOAK_ADMIN_PASSWORD},
);
$loop->add($kc);

my $claims = await $kc->oidc->verify_token_f( $jwt, audience => 'my-api', type => 'Bearer' );
my $r      = await $kc->admin->ensure_client_f( clientId => 'cli', publicClient => \1 );
```

Requests are built and responses read by the same code as in WWW::Keycloak,
and the `ensure_*_f` methods compare with the same `WWW::Keycloak::Diff`, so
both clients do the same thing to a realm. Errors are
`Net::Async::Keycloak::Error::*`, each also the matching
`WWW::Keycloak::Error::*`.

Callers that need an admin token while a login is under way share that login.

Developed and live-tested against Keycloak 26.8.0.

## Live tests

```bash
KEYCLOAK_LIVE_TEST=1 KEYCLOAK_URL=http://localhost:8080 prove -lv t/90-live-keycloak.t
```

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
````

- [ ] **Step 3: Alles laufen lassen**

Run: `prove -lr t && dzil test` — Expected: PASS. Mit laufendem Keycloak: `KEYCLOAK_LIVE_TEST=1 KEYCLOAK_URL=... prove -lv t/90-live-keycloak.t` — Expected: PASS (4 Subtests). Betreff: `Add error, async and live tests, README`.
