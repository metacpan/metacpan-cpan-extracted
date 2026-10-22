---
name: nak-core
description: Load before editing Net::Async::Kubernetes — the Kubernetes::REST seam, the public client API, the request pipeline, the transports and the invariants the async client must hold.
---

# Net::Async::Kubernetes — Core Architecture

Async Kubernetes client on IO::Async. `Kubernetes::REST` builds the requests and
inflates the responses; its own `io` backend never carries a request — except for
discovery when `discover` did not read it first. `IO::K8s` provides the typed
objects; `$VERSION` is hand-written in every module, dzil bumps it.

This skill is the orientation: what the parts are, who calls whom, what always
holds. Das Referenzmaterial steht daneben — Klassenauflösung, Fehlerwortungen,
Argumentregeln je Methode, Unstructured, Discovery, TLS: `nak-hazards`; Laufzeit
von `ensure`, Watcher, Controller, Duplex: `nak-runtime`; der Testharness: `nak-testing`.

## File map

| Datei | Zuständigkeit |
|---|---|
| `lib/Net/Async/Kubernetes.pm` | der Client: CRUD, watch, log, duplex, TLS |
| `lib/Net/Async/Kubernetes/Watcher.pm` | auto-reconnectender Watch-Stream |
| `lib/Net/Async/Kubernetes/Controller.pm` | Workqueue, serialisierter Reconcile-Dispatch |
| `lib/Net/Async/Kubernetes/PortForward{Session,Listener}.pm` | Duplex-Session (eigene Datei, `use`d aus `Kubernetes.pm`); lokale TCP-Listener je Pod-Port |
| `t/lib/{MockTransport.pm,TestKube.pm}`, `maint/prove-pinned.sh` | Dual-Mode-Testharness und gepinnte Suite (Skill `nak-testing`) |

## Vocabulary

| Begriff | Bedeutung |
|---|---|
| **Seam** | Grenze zu `Kubernetes::REST`: der Client baut Requests und inflate Antworten, der Transport bleibt asynchron |
| **Unstructured** | `IO::K8s::Unstructured` — Objekt ohne Klassen-`api_version`; der Pfad braucht `kind` + `api_version` vom Aufrufer |
| **inflate** | `Kubernetes::REST::inflate_object` / `inflate_list` — HTTP-Antwort → `IO::K8s`-Objekt |
| **`_exact_class`** | die angereicherte Form (`'+IO::K8s::Pod'`) für RESTs inflate-Helfer — ohne sie liest REST den Kurznamen als Kind |
| **Duplex** | die Websocket-Transports exec / attach / port-forward / cp |

## Öffentliche Fläche des Clients

`Net::Async::Kubernetes` ist ein `IO::Async::Notifier`. Konfiguration: `kubeconfig`,
`context`, `server`, `credentials`, `resource_map`, `resource_map_from_cluster`
(Default 0), `with` (CRD-Provider, an `Kubernetes::REST->new(with =>)` durchgereicht).

Alle Future-Methoden:

| Methode | löst auf |
|---|---|
| `list` | `IO::K8s::List` — **`->items`**, nicht die Liste selbst; `labelSelector`/`fieldSelector` gehen als Query-Parameter raus |
| `get` `create` `update` `patch` `patch_status` `update_status` | inflatiertes Objekt (die beiden status-Methoden auf `.../status`; patch = merge, update = ganzes Objekt) |
| `delete` | `1`; `propagationPolicy` Background\|Foreground\|Orphan als Query-Parameter |
| `ensure` `ensure_all` `ensure_only` | das Objekt / die Objekte in Eingabereihenfolge / die angewendeten Objekte |
| `discover` | nichts — siehe Unstructured in `nak-hazards` |
| `log` | voller Text, oder `undef` mit `on_line` |
| `port_forward` `exec` `attach` | Session-Objekt |
| `port_forward_listen` | `PortForwardListener` |
| `cp_to_pod` `cp_from_pod` | `{local,remote,bytes,stderr,status}` |

Ohne Future: `rest` (der faule `Kubernetes::REST`, `_rest` ist derselbe),
`new_object`, `expand_class`, `watcher(...)`, `controller(...)` — die beiden
letzten `add_child`en den gelieferten Notifier.

Die vier weiteren Klassen — `Watcher` und `Controller` in `nak-runtime`,
`PortForwardSession` (Bless-Hashref um `ws_client`, Duplex-Session mit
`write_channel`/`write_stdin`/`resize`/`close`, Aliase `write`/`stdin`) und
`PortForwardListener` (lokale TCP-Listener je Pod-Port wie `kubectl port-forward`).

## Die Naht zu Kubernetes::REST

Ein fauer `Kubernetes::REST` in `rest`, ein geteilter `Net::Async::HTTP` in `_http`
(`max_connections_per_host => 0`, damit Watch-Streams kein CRUD verhungern — nie
einen zweiten UA). Einheitliche CRUD-Form:

```
my ($class, $error) = $self->_resolve_class($name);        # oder _object_class($label, $obj)
(my $path, $error) = $self->_request_path($class, $name_or_obj, name=>, namespace=>);
return Future->fail($error) unless defined $path;            # croak in croaking methods
  → $rest->prepare_request(METHOD, $path, body=>, parameters=>, headers=>)
  → $self->_checked_request($req, "op class")      # _do_request + _checked_response
  → ->then { $rest->inflate_object/inflate_list($self->_exact_class($class), $res) }
```

Nur die öffentlichen Bausteine von REST benutzen — `expand_class`, `build_path`,
`prepare_request`, `check_response` (croakt ab Status ≥ 400, gerufen nur in
`_checked_response`), `inflate_object`, `inflate_list`, `process_watch_chunk`,
`process_log_chunk`, das dokumentierte `io`-Attribut — nie `_`-prefixte Interna;
wo der Client deren Verhalten braucht, hält er eine Spiegelkopie (`_unstructured_hint`,
`_api_version_and_kind`, `_exact_class`). Bausteine: `nak-hazards`.

`_request_unchecked(METHOD, $path, %opts)` löst mit dem rohen
`Kubernetes::REST::HTTPResponse` auf; `_list_request` / `_delete_request` sind
`list` / `delete` bis dahin und lösen mit `($class, $response)` auf. Auf
`$response->status` verzweigen, nie auf dem Text, den `check_response` croakt.

## Transports

- `_do_request` wickelt die `HTTP::Response` in ein `Kubernetes::REST::HTTPResponse`
  — dieses Umwickeln ist die Naht, die Mocks und der Live-Transport teilen.
- `_do_streaming_request($req, $on_chunk)` (nur GET) installiert den Chunk-Callback
  über `on_header` und löst am Streamende mit `Kubernetes::REST::HTTPResponse` auf
  (leerer Inhalt bei Erfolg, der Fehler-Body bei Status ≥ 400). Ein Fehler-Body geht
  **nie** an `$on_chunk`; der Aufrufer ruft `check_response` selbst.
- Override-Punkte des Testharness: `_do_request`, `_do_streaming_request`,
  `_do_duplex_request`, `_add_to_loop`, `_make_websocket_client`.

## Die Fehlerkonvention — die Regel

Nichts Unbrauchbares erreicht `build_path` — das würde synchron sterben, ohne die
Ressource zu nennen. Eingabefehler, die **vor** jeder Anfrage feststehen, croaken
synchron; alle anderen Future-Methoden liefern `Future->fail($message)`. Fehler des
Ablaufs sind failed Futures, HTTP-Fehler über `_checked_response` →
`Future->fail($err, 'http', $response)`. Wortungen: `nak-hazards`.

## ensure, watch, controller, duplex — die Regeln

Die Zustandsmaschinen dahinter: `nak-runtime`. Was hier gilt:

- **`ensure`** entscheidet nach einem unchecked GET: 404 → POST, 409 → nachladen;
  `core v1` PersistentVolumeClaim bleibt unverändert, `batch/v1` Job wird gelöscht
  und neu angelegt, alles andere PUT auf die resourceVersion des Servers.
- **`ensure_only`** prunt je Kind × Namespace; der Schlüssel ist (API-Gruppe,
  Kind, Namespace, Name) aus dem Objekt — nie aus dem `kinds`-String.
- **Watcher**: **410 Gone** leert die `resourceVersion` und geht **nicht** an
  `on_error`; ein Zyklus unter Status 400 startet sofort neu (außer nach einem
  Nicht-410-ERROR-Event oder ohne jedes Event), sonst Backoff und Meldung als
  `Status`-Hashref an `on_error` oder per `warn`.
- **Controller**: ein Eintrag fällt, sobald sein Key sauber reconciled ist —
  `{entries}` ist kein Cache, sondern ausstehende Arbeit; **Reconciles sind global
  serialisiert** (`active_key`), einer pro Controller, nicht pro Key.
- **Duplex**: `Connection: Upgrade`, `Sec-WebSocket-Protocol` (Default
  `v4.channel.k8s.io`); die Kanäle sind 0 stdin, 1 stdout, 2 stderr, 3
  Fehler-/Status-JSON, 4 TTY-Resize.

## TLS / auth

Explizites `server`/`credentials` gewinnen; sonst `Kubernetes::REST::Kubeconfig`
(explizites `kubeconfig` oder `context` → croakt beim Bauen mit dem Grund, sonst
stilles eval und der Fehler taucht später als croakender Accessor auf); sonst das
In-Cluster-SA-Token. `_ssl_options` wird **einmal** berechnet und gecacht; inline
`ssl_*_pem` wird in `File::Temp`-Dateien materialisiert, `*_pem` schlägt gleichnamig
`*_file`. https/wss brauchen `IO::Async::SSL`. Details: `nak-hazards`.

## Invarianten und Fallen

- `list()` liefert `IO::K8s::List` — immer `->items`.
- Nie ein Future in einem Callback `->get` (Watcher/Reconcile/`on_frame`) — Deadlock.
- Retention: Watcher und Controller schwächen `kube` ab (der Controller besitzt einen
  selbst gebauten Client stark). Ein GC'ter Client ⇒ seine Watches sterben still.
- `watcher()`/`controller()` haben schon `add_child` aufgerufen — nie den Kind-
  Notifier noch einmal `$loop->add`en. Ein Watcher, der vor dem Loop-Beitritt des
  Clients entsteht, startet, wenn der Client hinzugefügt wird.
- Kein URI-Escaping in Pfad oder Parametern — Sonderzeichen in Namen, Selektoren
  und Exec-Kommandos gehen roh hinaus.
- `sub delete`/`exec`/`log` verdecken Builtins im Client-Paket (und `close` in
  `PortForwardSession`) — als Methoden in Ordnung, aber Bareword-Aufrufe in diesen
  Paketen treffen CORE.
- Ein einsegmentiger Klassenname (`'+Gizmo'` → `Gizmo`), an RESTs inflate-Helfer
  übergeben, könnte als Kind gelesen werden (REST vor 1.109 tat das: Listeneinträge
  fielen weg, `ensure_only` pruned in dieser Gruppe). Jede inflate-Aufrufstelle —
  auch die des Watchers — übergibt `_exact_class($class)`.
- POD-Stil: inline `=method`/`=attr` beim Sub (`Kubernetes.pm`, `Watcher.pm`),
  `Controller.pm` in `__END__` — pro Datei angleichen.

## Grenzen

- Der Client ist **kein** Kubernetes-Client an sich: Request-Bau, Pfadbildung, JSON
  und Fehlertexte gehören `Kubernetes::REST`, die Inflation gehört `IO::K8s`; die
  Watcher, Controller und Duplex-Transports leben hier, nicht die K8s-API-Semantik.
- Async/Future-Leben: `perl-io-async-future`. K8s-API-Umfang: `perl-kubernetes-rest`
  + `perl-io-k8s-kubernetes-classes`. Release: `getty-perl-release-author-getty`,
  `perl-release-dist-ini`.
