# Net::Async::Authentik Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `Net::Async::Authentik` Phase 1 bauen: den asynchronen Zwilling von `WWW::Authentik` auf `IO::Async` und `Future`, jede öffentliche Methode mit `_f`, gleiche Klassen, gleiche Fehler, gleiches Verhalten gegen dasselbe authentik.

**Architecture:** Moo-Klassen; die Fassade erweitert `IO::Async::Notifier` und hält ein `Net::Async::HTTP` als Kindknoten. Was kein I/O ist, kommt aus der Sync-Dist und wird nicht kopiert: `WWW::Authentik::Role::HTTP` liefert `build_request`, `read_response` und `flatten_field_errors`, `WWW::Authentik::Diff` den Vergleich, `WWW::Authentik::API->resolvable_fields` die Tabelle der Namensauflösung. Gesendet wird hier, über `Net::Async::Authentik::Role::HTTP`, das vor der Sync-Rolle komponiert wird und deren Fehlerklassen-Methoden überschreibt.

**Tech Stack:** Perl 5.20+, Moo, IO::Async, Future, Future::AsyncAwait, Net::Async::HTTP, Types::Standard, WWW::Authentik. Dist::Zilla mit `[@Author::GETTY]`.

**Spec:** die der Sync-Dist, `~/dev/p5-www-authentik/docs/superpowers/specs/2026-10-04-www-authentik-design.md` (freigegeben, mit den Abschnitten 12 und 13). Abschnitt 9 beschreibt diesen Zwilling.

## Was `Net::Async::HTTP` anders macht als LWP

Am laufenden authentik 2026.8.3 geprüft, nicht aus dem Sync-Bau übernommen. Die vier
Gefahren aus Abschnitt 13 der Spec sehen hier anders aus:

| Gefahr der Sync-Dist | `Net::Async::HTTP` 0.50 |
|---|---|
| LWP kündigt `TE` an, authentik lässt jede zweite Anfrage unbeantwortet | **Tritt nicht auf.** Auf dem Draht steht nur `Connection: keep-alive`, `Accept`, `Authorization`, `Host`, `User-Agent`. Sechs Anfragen hintereinander: sechsmal 200. Kein `send_te` nötig und keines vorhanden. |
| `read_response` verlor einen gzip-Rumpf | Es fragt von sich aus keine Komprimierung an, und authentik komprimiert auch auf `Accept-Encoding: gzip` hin nicht (`content-encoding: none`). Die Behebung in der Sync-Rolle trägt hier trotzdem, weil dieselbe Rolle benutzt wird. |
| LWP folgt Redirects, wenn man es lässt | `max_redirects => 0` liefert die 302 als Antwort mit `Location` zurück, also genau das, was `read_response` als Erfolg unter 400 behandelt. Am Authorize-Endpunkt geprüft. |
| LWP meldet „kein Kontakt“ als 500 mit `Client-Warning: Internal response` | Das Future **scheitert**, mit einer Liste von Zeichenketten statt eines Objekts: abgelehnte Verbindung → `('127.0.0.1:9 - connect: Connection refused failed [Connection refused]')`, Zeitüberschreitung → `('Timed out', 'timeout')`. `send_request_f` muss das auf `Net::Async::Authentik::Error::Network` abbilden. |

Dazu zwei Dinge, die es neu mitbringt: es **hält die Verbindung offen** und schickt drei
Anfragen über denselben Socket (LWP öffnete jedes Mal einen neuen), und es lädt
`IO::Async::Internals::Connector` und für HTTPS `IO::Async::SSL` erst beim ersten
Verbindungsaufbau — stirbt dabei ein Modul, bleibt bei `max_connections_per_host => 1`
der Platz für immer belegt und jede weitere Anfrage hängt ohne Fehler (siehe Skill
`perl-io-async-future`). Aufgabe 2 fängt das ab.

## Global Constraints

- Jede öffentliche Methode der Sync-Dist gibt es hier unter demselben Namen plus `_f` und liefert ein Future. Keine eigene API erfinden.
- Was kein I/O ist, kommt aus `WWW-Authentik`: `Role::HTTP` (`build_request`, `read_response`, `flatten_field_errors`, `json_codec`), `Diff`, `API->resolvable_fields`. Nicht kopieren.
- `cpanfile`: `requires 'WWW::Authentik', '0.001';`
- Ein Paket pro Datei, jede Datei unter `lib/` mit `# ABSTRACT:` (nur ASCII) und `our $VERSION = '0.001';`.
- **Nie den Loop blockieren.** Kein `->get` und kein `await` auf etwas Synchrones im Bibliothekscode, kein synchroner HTTP-Client.
- Ein Fehler wird **nicht geworfen, sondern das Future scheitert** — auch bei falschen Argumenten. Der Aufrufer bekommt nie eine Exception aus einem `*_f`.
- `IO::Async::Notifier->new` reicht jeden Schlüssel an `configure`, das Unbekanntes verwirft: eigene Attribute in `FOREIGNBUILDARGS` entfernen.
- Jedes Future, das jemand braucht, wird gehalten, bis es fertig ist; geteilte Abrufe bekommt jeder Aufrufer als `without_cancel`, damit ein Abbruch den Abruf nicht mitnimmt.
- 2 Leerzeichen Einrückung, `my ( $self, ... ) = @_;`, `is => 'ro'`, `namespace::autoclean`, Typen aus `Types::Standard`.
- Tests laufen mit `PERL5LIB=$HOME/dev/p5-www-authentik/lib prove -lr t`; die Live-Suite nur mit `AUTHENTIK_LIVE_TEST=1`, `AUTHENTIK_URL` und `AUTHENTIK_TOKEN`.
- Öffentliches Repo: keine Hostnamen außer `127.0.0.1` und `example.org`, keine Tokens.

## Review Focus

Fünf Dinge, die nur asynchron schiefgehen können und die keine portierte Suite von sich aus prüft.

1. **Zwei Aufrufer, ein Abruf.** Zwanzig gleichzeitige `verify_token_f` dürfen ein Discovery und einen Schlüsselabruf auslösen, nicht zwanzig. Test `concurrent callers share the fetch` in `t/70-async.t` (Aufgabe 5).
2. **Ein Aufrufer bricht ab, die anderen nicht.** `$first->cancel` auf einem geteilten Abruf darf den zweiten Aufrufer nicht um seine Antwort bringen. Test `cancelling one caller` in `t/70-async.t` (Aufgabe 5).
3. **Ein Objekt ohne Loop.** Jede Methode muss ein gescheitertes Future liefern, das sagt, was fehlt — keine Exception und kein Hänger. Test `not in a loop` in `t/70-async.t` (Aufgabe 5).
4. **Ein verlorenes Future.** Ein `ensure_*_f`, dessen Rückgabe niemand hält, darf keine halbe Änderung hinterlassen; die Warnung „lost its returning future“ darf in keinem Testlauf stehen. Test `nothing is written by a future nobody holds` in `t/70-async.t` (Aufgabe 5).
5. **Paginierung über mehrere Seiten.** `_paged_f` muss `pagination.next` folgen, bei 0 aufhören und bei einer Antwort, deren `next` zurückzeigt, abbrechen statt endlos zu laufen. Test `pagination` in `t/50-api.t` (Aufgabe 4) und `_paged_f over three pages` in `t/70-async.t`.

## Dateien

| Datei | Verantwortung | Aufgabe |
|---|---|---|
| `cpanfile` | Abhängigkeiten, darunter `WWW::Authentik` | 1 |
| `lib/Net/Async/Authentik/Error.pm`, `Error/Validation.pm`, `Error/Network.pm`, `Error/API.pm` | Fehler, je zugleich die Klasse der Sync-Dist | 1 |
| `lib/Net/Async/Authentik/Role/HTTP.pm` | `send_request_f`, `fail_validation`, Fehlerklassen | 2 |
| `t/lib/FakeAuthentik.pm`, `t/lib/FakeHTTP.pm` | nachgebautes authentik (Kopie der Sync-Dist) und ein `Net::Async::HTTP`-Ersatz | 2 |
| `lib/Net/Async/Authentik/OIDC.pm` | OIDC, geteilte Abrufe | 3 |
| `lib/Net/Async/Authentik.pm` | Fassade auf `IO::Async::Notifier` | 3 |
| `lib/Net/Async/Authentik/API.pm` | API v3, `_paged_f`, `resolve_f`, `ensure_*_f` | 4 |
| `t/00-load.t`, `t/20-errors.t`, `t/40-facade.t`, `t/50-api.t`, `t/51-api-ensure.t`, `t/52-api-resolve.t`, `t/60-oidc.t` | die portierten Suiten | 2–4 |
| `t/70-async.t` | was nur asynchron schiefgeht | 5 |
| `t/lib/AuthentikExecutor.pm`, `t/90-live-authentik.t`, `t/authentik/` | Live-Suite | 6 |
| `README.md`, `Changes`, `CLAUDE.md`, Core-Skill | Stand nachziehen | 6 |

---

### Task 1: Abhängigkeiten und die Fehlerklassen

**Files:** `cpanfile`, `lib/Net/Async/Authentik/Error.pm`, `Error/Validation.pm`, `Error/Network.pm`, `Error/API.pm`, `t/00-load.t`

**Interfaces:**
- Produces: `Net::Async::Authentik::Error` erweitert `WWW::Authentik::Error`; `::Error::API` erweitert `WWW::Authentik::Error::API` **und** `Net::Async::Authentik::Error`, ebenso `::Validation` und `::Network`. Jede ist damit auch die Klasse der Sync-Dist, und Code, der `WWW::Authentik::Error::API` fängt, fängt sie mit.

- [ ] **Step 1: `cpanfile`**

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
requires 'WWW::Authentik', '0.001';
requires 'namespace::autoclean', '0.16';

on test => sub {
    requires 'CryptX';
    requires 'HTTP::Message';
    requires 'Test::More', '0.96';
};
```

`IO::Async::SSL` ist eine harte Abhängigkeit, obwohl `Net::Async::HTTP` sie nur empfiehlt: ohne sie hängt die erste HTTPS-Anfrage, statt zu scheitern (Skill `perl-io-async-future`).

Run: `cpanm --installdeps .` — Expected: ohne Fehler.

- [ ] **Step 2: Die vier Fehlerklassen schreiben**

Jede ist vier Zeilen Moo plus POD, nach dem Muster von `Net::Async::Keycloak::Error`:

```perl
package Net::Async::Authentik::Error::API;

# ABSTRACT: Net::Async::Authentik's API error, a WWW::Authentik::Error::API

use Moo;
extends 'WWW::Authentik::Error::API', 'Net::Async::Authentik::Error';

our $VERSION = '0.001';
```

`Net::Async::Authentik::Error` selbst erweitert nur `WWW::Authentik::Error`.

- [ ] **Step 3: `t/00-load.t` und ein erster Lauf**

Alle neun Module auflisten (sie entstehen in den folgenden Aufgaben; bis dahin nur die vorhandenen).
Run: `PERL5LIB=$HOME/dev/p5-www-authentik/lib prove -lr t` — Expected: PASS.
Commit: `Add the dependencies and the error classes`.

---

### Task 2: Die HTTP-Rolle und das Testgerüst

**Files:** `lib/Net/Async/Authentik/Role/HTTP.pm`, `t/lib/FakeAuthentik.pm`, `t/lib/FakeHTTP.pm`, `t/20-errors.t`

**Interfaces:**
- Consumes: `WWW::Authentik::Role::HTTP`.
- Produces: Rolle mit `api_error_class`, `network_error_class`, `validation_error_class`, `fail_validation($message)` → gescheitertes Future, `send_request_f( $method, $url, %arg )` → Future von `{ status, data, location, content }`.
- `FakeHTTP->new( fake => $fake )` mit `do_request( request => $request )` → bereits fertiges Future; `->fake` liefert das `FakeAuthentik`.

- [ ] **Step 1: `t/lib/FakeAuthentik.pm` übernehmen**

Kopie von `~/dev/p5-www-authentik/t/lib/FakeAuthentik.pm`, unverändert bis auf einen
Kopfkommentar, der sagt, woher sie stammt und dass beide gleich bleiben müssen. Eine
Testdatei lässt sich nicht als Abhängigkeit beziehen, deshalb die Kopie — wie bei
`Net::Async::Keycloak`. Dazu in `t/00-load.t` eine Prüfung, die die beiden Dateien
vergleicht, wenn die Sync-Dist daneben ausgecheckt ist, und sonst übersprungen wird:

```perl
my $sync = $ENV{WWW_AUTHENTIK_DIR} || "$ENV{HOME}/dev/p5-www-authentik";
SKIP: {
  skip 'the sync distribution is not checked out next door', 1 unless -f "$sync/t/lib/FakeAuthentik.pm";
  my $here  = do { local ( @ARGV, $/ ) = 't/lib/FakeAuthentik.pm'; <> };
  my $there = do { local ( @ARGV, $/ ) = "$sync/t/lib/FakeAuthentik.pm"; <> };
  # the header comment differs on purpose; everything from `use strict` on must not
  is( ( $here =~ s/\A.*?^use strict;/use strict;/smr ), ( $there =~ s/\A.*?^use strict;/use strict;/smr ),
    'the fake authentik has not drifted from the sync distribution' );
}
```

- [ ] **Step 2: `t/lib/FakeHTTP.pm` schreiben**

```perl
package FakeHTTP;

# What Net::Async::Authentik needs from Net::Async::HTTP, answered by the
# in-memory authentik of t/lib/FakeAuthentik.pm as already completed futures.
# No loop is needed.

use strict;
use warnings;
use Future;
use FakeAuthentik;

sub new {
  my ( $class, %arg ) = @_;
  return bless { fake => $arg{fake} || FakeAuthentik->new(%arg) }, $class;
}

sub fake { $_[0]{fake} }

sub do_request {
  my ( $self, %arg ) = @_;
  return Future->done( $self->{fake}->request( $arg{request} ) );
}

1;
```

- [ ] **Step 3: `lib/Net/Async/Authentik/Role/HTTP.pm` schreiben**

```perl
package Net::Async::Authentik::Role::HTTP;

# ABSTRACT: Sending requests to authentik through Net::Async::HTTP

use Future;
use Net::Async::Authentik::Error::API;
use Net::Async::Authentik::Error::Network;
use Net::Async::Authentik::Error::Validation;
use Scalar::Util qw( blessed );
use Moo::Role;

our $VERSION = '0.001';

sub api_error_class        { 'Net::Async::Authentik::Error::API' }
sub network_error_class    { 'Net::Async::Authentik::Error::Network' }
sub validation_error_class { 'Net::Async::Authentik::Error::Validation' }

sub fail_validation {
  my ( $self, $message ) = @_;
  return Future->fail( $self->validation_error_class->new( message => $message ) );
}

sub send_request_f {
  my ( $self, $method, $url, %arg ) = @_;
  my $request = $self->build_request( $method, $url, %arg );
  # Net::Async::HTTP dies instead of failing when it is in no loop
  my $sent = eval { $self->http->do_request( request => $request ) };
  return Future->fail( $self->network_error_class->new( message => $method.' '.$url.': could not send ('
    .( $@ =~ s/ at \S+ line \d+.*//sr ).'); was the Net::Async::Authentik added to a loop?' ) ) unless $sent;
  return $sent->else( sub {
    my ( $message ) = @_;
    return Future->fail($message) if blessed $message;
    # a refused connection or a timeout arrives as plain strings
    return Future->fail( $self->network_error_class->new( message => $method.' '.$url.': '.$message ) );
  } )->then( sub {
    my ( $response ) = @_;
    my $result = eval { $self->read_response( $response, $method, $url, %arg ) };
    return $result ? Future->done($result) : Future->fail($@);
  } );
}

1;
```

Die Rolle wird **vor** `WWW::Authentik::Role::HTTP` komponiert, damit ihre
Fehlerklassen-Methoden gewinnen:

```perl
with 'Net::Async::Authentik::Role::HTTP';
with 'WWW::Authentik::Role::HTTP';
```

POD: `=description` sagt, dass Anfragen und Antworten von der Sync-Rolle gebaut und
gelesen werden, damit beide Clients authentiks Antworten gleich abbilden, und dass diese
Rolle nur sendet.

- [ ] **Step 4: `t/20-errors.t` portieren**

Die Suite der Sync-Dist, jeder Aufruf als `->get`, und statt `error_of { ... }` ein
Helfer, der das Scheitern des Futures nimmt:

```perl
sub failure_of { my ( $future ) = @_; $future->is_failed ? ( $future->failure )[0] : undef }
```

Dazu drei Prüfungen, die es nur hier gibt: jede Fehlerklasse ist auch die der Sync-Dist
(`isa_ok( $error, 'WWW::Authentik::Error::API' )`), ein falsches Argument **scheitert das
Future, statt zu werfen**, und eine abgelehnte Verbindung wird zu
`Net::Async::Authentik::Error::Network`.

Run: `PERL5LIB=… prove -lr t` — Expected: PASS.
Commit: `Add the HTTP role and the test harness`.

---

### Task 3: OIDC und die Fassade

**Files:** `lib/Net/Async/Authentik/OIDC.pm`, `lib/Net/Async/Authentik.pm`, `t/40-facade.t`, `t/60-oidc.t`

**Interfaces:**
- Produces: `Net::Async::Authentik->new( base_url =>, application =>, client_id =>, token =>, http => )` mit `->oidc`, `->api`, `->issuer`, `->application_url`, `->api_url`, `->for_application($slug)`, `->http`.
- `Net::Async::Authentik::OIDC->new( application_url =>, http =>, client_id =>, algorithms =>, jwks_min_age =>, now => )` mit `discovery_f`, `jwks_f`, `endpoint_f`, `issuer_f`, den acht `*_endpoint_f`, `issuer_names_the_application_f`, `verify_token_f`, `userinfo_f`, `introspect_f`, `revoke_f`, `client_credentials_token_f`, `refresh_token_f`, `exchange_authorization_code_f`, `device_authorization_f`, `device_token_f`, `authorization_url_f`.

- [ ] **Step 1: Die Tests schreiben**

`t/40-facade.t` wie in der Sync-Dist, dazu: `http` ist ein Kindknoten der Fassade
(`grep { $_ == $ak->http } $ak->children`), ein übergebenes `http` wird **nicht** als Kind
hinzugefügt, `for_application` teilt es, und die Fassade nimmt auch eine Hash-Referenz.
Die Sync-Prüfungen auf `max_redirect` und `send_te` entfallen; stattdessen:
`max_redirects` ist 0 und `fail_on_error` ist falsch, damit eine 404 als Antwort
zurückkommt und `read_response` sie in einen Fehler verwandelt.

`t/60-oidc.t` wie in der Sync-Dist, jeder Aufruf `->get`, einschließlich des Subtests
`two applications of one instance` mit `issuer_mode: global`.

- [ ] **Step 2: `lib/Net/Async/Authentik/OIDC.pm` schreiben**

Attribute wie die Sync-Klasse, aber `http` statt `ua`, und die Zustände als `rw`:
`_discovery`, `_jwks`, `_jwks_fetched`, `_in_flight` (`default => sub { {} }`).

Der geteilte Abruf, wörtlich wie beim Keycloak-Zwilling:

```perl
# One fetch for everybody who asks while it is under way, each with a view of
# its own so that cancelling one does not cancel the fetch.
sub _shared {
  my ( $self, $key, $start ) = @_;
  my $in_flight = $self->_in_flight;
  unless ( $in_flight->{$key} ) {
    my $future = $start->()->on_ready( sub { delete $in_flight->{$key} } );
    return $future if $future->is_ready;
    $in_flight->{$key} = $future;
  }
  return $in_flight->{$key}->without_cancel;
}
```

`discovery_f` und `jwks_f` gehen darüber; `jwks_f` setzt `_jwks_fetched` **beim Start**,
damit schon laufende Prüfungen es sehen.

`verify_token_f` ist die Sync-Methode mit `await` davor, mit allen drei Punkten aus
Spec 13.2: `client_id` als voreingestellte `audience`, die Weigerung, ohne
unterscheidenden Aussteller zu prüfen (`any_audience => 1` hebt sie auf), und die
`scope`-Heuristik für `type`. Der Unterschied zur Sync-Fassung: der Aussteller kommt aus
einem Future, also

```perl
async sub issuer_names_the_application_f {
  my ( $self ) = @_;
  return ( await $self->issuer_f ) eq $self->application_url.'/' ? 1 : 0;
}
```

und `verify_token_f` wartet auf `issuer_f` und `issuer_names_the_application_f`, bevor es
entscheidet. Ein Nachladen der Schlüssel darf auch dann geschehen, wenn gerade ein Abruf
läuft (`$self->_in_flight->{jwks} || $self->now->() - ... >= $self->jwks_min_age`), sonst
scheitern zwanzig gleichzeitige Prüfungen mit einem rotierten Schlüssel.

`authorization_url_f` ist das einzige, was kein I/O bräuchte — es braucht aber den
Endpunkt aus dem Discovery, also ist es ebenfalls ein Future.

- [ ] **Step 3: `lib/Net/Async/Authentik.pm` schreiben**

```perl
use Moo;
extends 'IO::Async::Notifier';

sub FOREIGNBUILDARGS {
  my ( $class, @args ) = @_;
  my %arg = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
  delete @arg{qw( base_url application client_id token http )};
  return %arg;
}

sub BUILDARGS {
  my ( $class, @args ) = @_;
  my %args = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
  $args{base_url} =~ s{/+\z}{} if defined $args{base_url};
  return \%args;
}
```

`http` ist `is => 'lazy'` und wird als Kind hinzugefügt:

```perl
sub _build_http {
  my ( $self ) = @_;
  # no redirects: authentik answers 302 wherever it wants a browser, and
  # those answers are read, not followed. fail_on_error off, so that a 4xx
  # comes back as a response and read_response can turn it into an error.
  my $http = Net::Async::HTTP->new(
    user_agent     => 'Net-Async-Authentik/'.$VERSION,
    max_redirects  => 0,
    fail_on_error  => 0,
    timeout        => 30
  );
  $self->add_child($http);
  return $http;
}
```

`oidc` und `api` wie in der Sync-Fassade, aber sie scheitern nicht beim Bauen: ein
fehlender Slug oder ein fehlendes Token wird erst beim Aufruf zu einem **gescheiterten
Future**, weil ein Attributzugriff nicht werfen soll. Also bauen `_build_oidc` und
`_build_api` das Unterobjekt immer, und die Methoden dort prüfen.

Die POD der Fassade nennt, wie die der Sync-Dist, den Unterschied in der Rückgabe
(`{ object, changed }`) und dazu: zuerst `$loop->add($ak)`, sonst scheitert jede Anfrage
mit einem Netzwerkfehler, der genau das sagt.

- [ ] **Step 4: Tests laufen lassen, committen**

Run: `PERL5LIB=… prove -lr t` — Expected: PASS.
Commit: `Add the OIDC client and the facade`.

---

### Task 4: `Net::Async::Authentik::API`

**Files:** `lib/Net/Async/Authentik/API.pm`, `t/50-api.t`, `t/51-api-ensure.t`, `t/52-api-resolve.t`

**Interfaces:**
- Consumes: `WWW::Authentik::Diff`, `WWW::Authentik::API->resolvable_fields`.
- Produces: jede Methode von `WWW::Authentik::API` mit `_f`, dazu `call_f`, `_paged_f`, `resolve_f`, `_ensure_f`.

- [ ] **Step 1: Die drei Suiten portieren**

Wörtlich die der Sync-Dist, mit `_f` und `->get`. In `t/50-api.t` kommt die Paginierung
dazu, die hier eine Schleife mit `await` ist statt einer `while`-Schleife.

- [ ] **Step 2: Transport, Paginierung, Auflösung**

```perl
async sub call_f {
  my ( $self, $method, $path, $body ) = @_;
  $path = '/'.$path unless $path =~ m{\A/};
  my %arg = defined $body ? ( json => $body ) : ();
  return await $self->send_request_f( $method, $self->api_url.$path, %arg, bearer => $self->token );
}

async sub _paged_f {
  my ( $self, $path, %query ) = @_;
  my $page_size = delete $query{page_size} // $self->page_size;
  my ( @all, %seen );
  my $page = 1;
  while ( defined $page && $page > 0 && !$seen{$page}++ ) {
    my $data = await $self->_data_f( GET => $path.$self->_query( %query, page => $page, page_size => $page_size ) );
    last unless ref $data eq 'HASH';
    push @all, @{ $data->{results} || [] };
    $page = ref $data->{pagination} eq 'HASH' ? $data->{pagination}{next} : 0;
  }
  return \@all;
}
```

`_query` und `_esc` sind reine Funktionen und werden aus `WWW::Authentik::API` geerbt —
nein: die Sync-Klasse ist keine Rolle. Sie werden hier als dieselben drei Zeilen
geschrieben, und `resolvable_fields` wird **delegiert**, damit die Tabelle nur einmal
existiert:

```perl
sub resolvable_fields { WWW::Authentik::API->resolvable_fields }

async sub resolve_f {
  my ( $self, $rep ) = @_;
  my %out    = %$rep;
  my $fields = $self->resolvable_fields;
  ...   # dieselbe Reihenfolge und dieselben Prüfungen wie in der Sync-Dist,
        # aber `my $found = await $self->${\ ( $spec->{find}.'_f' ) }($value);`
  return \%out;
}
```

Der Name der Nachschlagemethode ist der der Sync-Dist plus `_f`. Dass die Tabelle geteilt
ist, hält die Regel aus Spec 12 (keine Rate-Erkennung) in beiden Dists gleich.

- [ ] **Step 3: Die Grundoperationen und `ensure_*_f`**

Jede Methode eine Zeile nach dem Muster der Sync-Dist. `_ensure_f`:

```perl
async sub _ensure_f {
  my ( $self, %arg ) = @_;
  my $current = await $arg{find}->();
  unless ($current) {
    my $object = await $arg{create}->();
    await $arg{after_create}->($object) if $arg{after_create};
    return { object => $object, changed => 'created' };
  }
  my $changes = $self->diff_class->changes( $current, $arg{wanted} );
  return { object => $current, changed => '' } unless %$changes;
  return { object => await $arg{update}->( $current, $changes ), changed => 'updated' };
}
```

`diff_class` ist `WWW::Authentik::Diff`, also derselbe Vergleich, einschließlich der
Regel aus Spec 13.2 über zugeschnittene Textfelder.

Jede Prüfung, die in der Sync-Dist wirft, gibt hier ein gescheitertes Future zurück:
`return $self->fail_validation('ensure_user needs a username') unless defined $rep{username};`

- [ ] **Step 4: Tests laufen lassen, committen**

Commit: `Add the API v3 client with the ensure methods`.

---

### Task 5: `t/70-async.t`

**Files:** `t/70-async.t`

Ein `DeferredHTTP`, dessen Antworten erst kommen, wenn der Test es sagt, wie beim
Keycloak-Zwilling. Subtests:

- `concurrent callers share the fetch` — zwanzig `verify_token_f` mit unbekannter `kid`: ein Discovery, zwei Schlüsselabrufe (der erste und einer wegen der unbekannten Schlüssel), zwanzig gescheiterte Futures mit Validation-Fehler.
- `cancelling one caller leaves the fetch alone` — zwei Aufrufer teilen einen Abruf, der erste bricht ab, der zweite bekommt seine Antwort.
- `requests run side by side` — drei `*_f` gleichzeitig, drei Anfragen unterwegs, alle drei fertig.
- `_paged_f over three pages` — 25 Objekte bei `page_size => 10`: drei Anfragen, 25 Treffer; eine Antwort, deren `next` zurückzeigt, bricht ab.
- `not in a loop` — jede Methode liefert ein gescheitertes Future mit `Net::Async::Authentik::Error::Network`, dessen Meldung „added to a loop“ enthält.
- `wrong arguments fail the future` — `ensure_user_f()`, `find_user_f(undef)`, `resolve_f({ scopes => undef })`: gescheitert, nicht geworfen, und jedes Mal ein Validation-Fehler.
- `nothing is written by a future nobody holds` — ein `ensure_group_f`, dessen Rückgabe fallen gelassen wird, gefolgt von einem gehaltenen Lauf: der Zähler `$fake->writes` darf höchstens einmal steigen, und `$SIG{__WARN__}` darf kein „lost its returning future“ sehen.

Commit: `Add the asynchronous behaviour tests`.

---

### Task 6: Live-Suite und Stand nachziehen

**Files:** `t/lib/AuthentikExecutor.pm`, `t/90-live-authentik.t`, `t/authentik/docker-compose.yml`, `t/authentik/env.example`, `t/authentik/ci-live-job.yml`, `README.md`, `Changes`, `CLAUDE.md`, `.claude/skills/net-async-authentik-core/SKILL.md`, `t/00-load.t`

- [ ] **Step 1: Die Live-Suite portieren**

Die der Sync-Dist mit `_f` und `->get`, eigenes Präfix `naauth-live-…`, derselbe
`END`-Block, einschließlich des Service-Accounts des Client-Credentials-Grants. Der
Executor-Helfer kommt als Kopie mit (er spricht HTTP für sich selbst und bleibt
synchron; das ist Testcode, kein Bibliothekscode).

Dazu zwei Prüfungen, die es nur hier gibt: die Fassade wird dem Loop hinzugefügt, und ein
`Future->needs_all` über drei `ensure_*_f` läuft gegen das echte authentik parallel und
alle drei melden beim zweiten Lauf nichts.

- [ ] **Step 2: Das Compose-File und den CI-Job übernehmen**

`t/authentik/docker-compose.yml` und `env.example` wie in der Sync-Dist. Der Live-Job
kommt als `t/authentik/ci-live-job.yml` ins Repo, nicht nach `.github/workflows/`: der
Deploy-Key darf keine Workflow-Dateien pushen.

- [ ] **Step 3: `README.md`, `Changes`, `CLAUDE.md`, Core-Skill, `t/00-load.t`**

Kein „Skeleton state“ mehr; das README zeigt `$loop->add($ak)` und je ein Beispiel für
`oidc` und `api`.

- [ ] **Step 4: Alles laufen lassen**

Run: `PERL5LIB=$HOME/dev/p5-www-authentik/lib prove -lr t && PERL5LIB=… dzil test --all`
und die Live-Suite gegen die Wegwerf-Instanz. Expected: alle PASS.
Commit: `Add the live suite and bring the docs to the built state`.

---

## Selbstprüfung gegen die Spec

- **Abschnitt 9 (Zwilling)** → `build_request`/`read_response` und `Diff` aus der Sync-Dist (Aufgaben 2 und 4), `_paged_f` und `resolve_f` als eigene Methoden mit derselben Tabelle (Aufgabe 4).
- **Abschnitte 5 und 6** → jede Methode mit `_f` (Aufgaben 3 und 4).
- **Abschnitt 7** → die Fehlerhierarchie, jede Klasse zugleich die der Sync-Dist (Aufgabe 1).
- **Abschnitt 13.1** → die vier Gefahren oben neu geprüft; `TE` entfällt, der Rest trägt.
- **Abschnitt 13.2** → `verify_token_f` mit `client_id`, Audience-Pflicht und `any_audience`; `resolve_f` mit denselben Weigerungen; `find_*_f(undef)` scheitert; der Vergleich ist derselbe.

## Nach dem Bau geklärt (2026-10-04)

Ein unabhängiger Review ohne Bau-Kontext, mit Proben gegen das laufende authentik 2026.8.3,
hat sechs Punkte gefunden. Fünf sind behoben und durch Tests festgehalten; der sechste ist
ein Fehler in Future::AsyncAwait, den diese Dist nicht beheben kann.

### Der Absturz bei Programmende — Future::AsyncAwait 0.71, nicht diese Dist

Der Review meldete einen reproduzierbaren Absturz des Interpreters (`double free or
corruption`, `free(): invalid pointer`, Segmentation Fault) beim Abbrechen laufender
Futures. Die Nachprüfung hat ihn bestätigt und dann anders eingeordnet, als er gemeldet war:

- **Mit dem Abbrechen hat er nichts zu tun.** Derselbe Aufruf ohne `cancel` stürzt ebenso ab.
- **Der Auslöser ist eine Referenz im Rahmen einer bei Programmende noch angehaltenen
  `async sub`.** Mit einer Zeichenkette statt der Referenz ist derselbe Ablauf sauber.
- **Er liegt in der globalen Aufräumphase**, nach der Arbeit des Programms: die Ausgabe
  erscheint noch, der Exit-Status ist 134 oder 139.
- **Weder `Net::Async::HTTP` noch `IO::Async` noch Moo sind beteiligt.** Acht Zeilen reines
  Future::AsyncAwait reichen; sie stehen als `docs/future-asyncawait-0.71-crash.pl` im Repo,
  mitsamt dem, was daran etwas ändert und was nicht.
- **Der Aufrufer kann sich nicht dagegen schützen**, indem er das Future hält oder
  `->retain` ruft — nur dadurch, dass er es fertig werden lässt.

0.71 ist die neueste Fassung auf CPAN, eine Pinnung hilft also nicht. Was die Dist tut:
`pairs_or_fail` in `Net::Async::Authentik::Role::HTTP` prüft bei jeder `async sub`, die eine
Hash-Liste einsammelt, vorher die Form der Argumentliste und scheitert das Future bei einer
ungeraden — das war der leichteste Weg, versehentlich eine Referenz in so einen Rahmen zu
bekommen. Und die POD der Fassade und das README sagen jetzt ausdrücklich, dass jedes Future
vor Programmende fertig werden muss, mit dem Verweis auf den Reproducer. Für PEVANS
aufzubereiten und zu melden: Gettys Entscheidung, nicht meine.

### Behoben

- **`send_request_f` konnte werfen.** `build_request` stand außerhalb des `eval`, und ein
  Rumpf, den der JSON-Kodierer nicht kann, ließ `call_f` eine Exception werfen statt das
  Future scheitern — gegen die zugesagte Regel, dass hier nichts wirft. Jetzt ein
  Validation-Fehler im Future.
- **`ensure_binding_f` meldete jeden Fehler als „no flow“.** Ein `eval` um die Suche fing
  auch eine abgelehnte Verbindung, eine 401 und eine 500 und machte daraus die Behauptung,
  der Flow gebe es nicht. Jetzt wird nur ein ausbleibender Treffer zum Validation-Fehler,
  alles andere bleibt, was es ist.
- **`uuid_pattern` und `integer_pattern` fehlten.** Die Sync-Dist hat sie seit `45325ea` als
  öffentliche Klassenmethoden, der Zwilling benutzte sie, legte sie aber nicht offen. Jetzt
  delegiert er sie, und ein Test vergleicht beide Klassen Methode für Methode in beide
  Richtungen.
- **`_detail_f` konnte mit der leeren Zeichenkette sterben.** Es unterschied Erfolg und
  Fehler an der Wahrheit des Ergebnisses; eine Antwort ohne Rumpf führte zu `die ''`. Jetzt
  entscheidet, ob `eval` gescheitert ist.
- **`_fetch_jwks_f` prüfte nicht, was zurückkam.** Ein Rumpf, der kein JSON-Objekt ist, ließ
  den Zwischenspeicher leer, und jede Prüfung holte die Schlüssel erneut. Jetzt dieselbe
  Prüfung wie beim Discovery-Dokument drei Zeilen darüber.

### Geprüft und in Ordnung befunden

Der geteilte Abruf, wenn der erste **scheitert** (zweimal hintereinander, kein Festfahren);
alle Aufrufer brechen ab (der nächste bekommt eine frische Sicht); die Abbildung aller sechs
Fehlerformen von `Net::Async::HTTP` (DNS, abgelehnt, Zeitüberschreitung, kaputte Statuszeile,
Verbindungsabbruch im Rumpf, Abbruch vor dem Kopf) auf `Error::Network`, jeweils als Objekt;
„nichts wirft“ über rund 70 Methoden mal sechs Argumentformen; die Lebensdauer (nach
`$loop->remove` wird das Objekt freigegeben, kein festgehaltenes `$self`); `for_application`;
und `ensure_*` gegen das echte authentik durch **beide** Clients nacheinander, die sich einig
sind, was eine Änderung ist.

### Vom Review nicht erreicht

Ein echter OIDC-Durchlauf gegen die Instanz, die Live-Suite und `dzil build`. Alles drei ist
hier gelaufen: `prove -lr t`, `dzil test --all` und `t/90-live-authentik.t` zweimal
hintereinander.
