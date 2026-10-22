---
name: nak-hazards
description: Load when the Kubernetes::REST seam of Net::Async::Kubernetes bites — class resolution, error wordings, unknown arguments, Unstructured objects, discovery and TLS.
---

# nak-hazards — Klassenauflösung, Fehler, Unstructured, TLS

Nachbarskill zu `nak-core`: dort steht die Architektur, hier die genaue
Fehlerbehandlung. **Die Wortungen sind Vertrag** — die Tests prüfen sie wörtlich,
und die API des Clients ändert sich ohne Vorwarnung.

## Class resolution — die drei Helfer

Alle drei geben entweder die Klasse oder `(undef, $message)` zurück; der Aufrufer
meldet es nach seinem eigenen Vertrag. Nichts Unbrauchbares erreicht `build_path`.

- **`_resolve_class($name)`** — `$rest->expand_class` schließt für einen
  qualifizierten Namen (`undef`) und öffnet für einen nackten Kind (ein erfundenes
  `IO::K8s::<Kind>`); beides und ein erfundener, nicht ladbarer Name sind
  „unknown resource '…'". Eine Referenz in Klassenname-Position (ein
  Manifest-Hashref an `patch`) erreicht `expand_class` nie: `_resource_name_error`
  weist sie ab mit „resource name must be a string, got a HASH reference" (ein
  gesegnetes Objekt: „got an object of class …"). Alles andere geht an
  `_usable_class`. `get` und `delete` (Klassenform) rufen denselben Helfer auch auf
  ihrem Objektnamen-Positional auf — `get('Pod', $ref)` und
  `delete('Pod', {name=>'web'})` stringifizierten die Referenz sonst in den Pfad und
  scheiterten erst als 404 des Servers (k70, `t/37`). Die `_named_args`-Methoden
  (`log`, die Duplex-Methoden, `patch` in Klassenform) weisen eine Referenz dort
  schon als „Invalid arguments to METHOD()" ab (ihr `!ref`-Positional-Test).
- **`_usable_class($name, $class)`** — die Klasse muss laden (sonst deren
  Ladefehler) und `api_version` als Klassenmethode beantworten (sonst „not a
  Kubernetes resource class" — ein nacktes `List`, `Resource`, `Types`,
  `Unstructured`). `IO::K8s::Unstructured` besteht, sofern es nicht über seinen
  eigenen nackten Namen erreicht wird. Das öffentliche `expand_class` lädt also, was
  es zurückgibt.
- **`_object_class($label, $object)`** — dieselbe Prüfung auf `ref($object)` für die
  Objektformen (`create`, `update`, `update_status`, `patch`, `patch_status`,
  `delete`, `ensure`); ungesegnet → „requires an IO::K8s object".

## Die Fehlerkonvention im Detail

- **`_unknown_argument_error($label, \%args, @allowed)`** (k63): der erste unbekannte
  Key in Sortierreihenfolge als „Unknown argument 'KEY' to METHOD() (allowed: a, b)"
  — die Wortung von Kubernetes::REST. Geprüft direkt nach dem Argument-Parsing, vor
  der Klassenauflösung, in `list` (`_list_request`), `get`, `log`,
  `patch`/`patch_status` (`_patch_args`; Objektform nur `patch`, `type`) und
  `ensure_only` (croakt). k65 fügte `port_forward`, `exec`, `attach`, `cp_to_pod`,
  `cp_from_pod` hinzu (vorher wanderten Reste nach `build_path`, das ein
  Neben-`subresource` in den Pfad las); seit k67 parsen diese fünf und `log` über
  `_named_args($label, \@args, @allowed)`: eine Liste je Methode ist zugleich der
  Positional-Namen-Test (ein erstes Argument, das ein erlaubter Key ist, oder eine
  Referenz, startet die Keyed-Form) und die Unbekannt-Key-Prüfung; Rückgabe
  `(undef, %args)` oder die Meldung „Invalid arguments to METHOD()" für eine
  ungerade Liste; Test `t/45`. Ebenso der `patch_status` des Controllers (über
  `$self->kube->`; Objektform nur `status`, `type`) — alles failed Futures, direkt
  nach dem Argument-Parsing (cp_*: nach ihrer Loop-Prüfung).
- **`delete`** nutzt es ebenfalls (k64), nach Klassen- und Namensprüfung (seit k60);
  `_propagation_policy_error` formuliert eine schlechte Policy wie REST:
  „Unknown propagationPolicy 'x' for delete() (use: Background, Foreground, Orphan)".
- **`watcher`** braucht nichts: `IO::Async::Notifier::configure` croakt auf einen
  unbekannten Key.
- **Eine ungerade Optionsliste** (k69, Test `t/46`) ist „Invalid arguments to
  METHOD()" — geprüft **vor** der Unbekannt-Key-Prüfung, nie eine Perl-Warnung plus
  ein Request mit dem Wert des Fremd-Keys: failed Future in `get` (eigener Parse: ein
  einzelnes Argument bleibt der Name, auch wenn es `namespace` heißt, das
  `_named_args` ablehnen würde), `list`/`_list_request`, `_patch_args` (Objektform
  direkt geprüft, Klassenform über `_named_args`), `delete` und den
  `_named_args`-Methoden; croak in `ensure_only`, `watcher`, `controller` und dem
  `watch_resource` des Controllers. Eine neue Methode mit Optionen tut dasselbe.
- **Eingabefehler, die vor jeder Anfrage feststehen, croaken synchron** in
  `expand_class`, wenn ein Watcher startet, und in `update`, `update_status`,
  `ensure` (inkl. der Hashref-Auflösung von `ensure_only` und fehlendem `label`);
  jede andere Future-Methode gibt `Future->fail($message)` zurück. `ensure_all`
  croakt nie — ein `ensure`-Croak scheitert seine Kette.
- **Die unchecked Zweige** (`_request_unchecked`, `_list_request`, `_delete_request`)
  melden zuerst ihre Argumentfehler — erst danach kommt der rohe Response.
- **Fehler des Ablaufs selbst** sind immer failed Futures: HTTP ≥ 400 →
  `_checked_response($response, $context)` → `Future->fail($err, 'http', $response)`,
  wobei `$err` genau das ist, was `check_response` wirft (ein
  `Kubernetes::REST::APIError`-Objekt — hier nie nachgebaut); Transportfehler wie
  der Transport sie meldet. Jede Statusprüfung läuft über `_checked_response`
  (`_checked_request` = `_do_request` + sie), auch die unchecked Zweige von
  `ensure`/`ensure_only`; nur der Watcher ruft `check_response` selbst, für den
  Ursachentext seines `WatchFailed`-Berichts.

## Unstructured und Discovery

- **`resource_map_from_cluster => 1`**: Kubernetes::REST holt die Discovery
  (`GET /api`, `GET /apis`) **über sein eigenes synchrones `io`** (LWP als Default),
  einmal, beim ersten Gebrauch — das blockiert die Loop und umgeht `_do_request` —
  außer `discover` lief vorher. Seine Map löst die ausgelieferten Kinds auf; ein per
  Discovery gelistetes Kind löst zu nichts aus, was ausgeliefert wird.
- **`discover`** (k59, nie implizit gerufen): aus ohne `resource_map_from_cluster`
  (fertig, nichts gesendet). Sonst RESTs `prepare_discovery_requests`: beide Requests
  durch `_checked_request` (`needs_all`; ≥ 400 → `fail($err, 'http', $response)`),
  dann `absorb_discovery` in `then` (ein Croak — kaputtes JSON — scheitert das
  Future); `absorb_discovery` false = Legacy-Discovery, trotzdem erledigt, REST liest
  sie später synchron beim ersten Gebrauch. Test: `t/42` (REST-io aufzeichnend).
- **Unstructured** hat kein Klassen-`api_version`; `build_path` braucht `kind` (und
  `api_version`) vom Aufrufer und nimmt Plural und Scope aus dem Discovery-Katalog.
  `build_path` wird nur an einer Stelle gerufen, `_request_path($class, $ident, %args)`
  (CRUD, Status, Log, Duplex, beide Pfade in `ensure`, der Watcher), das
  `_unstructured_hint($class, $ident)` ergänzt: leer für typisierte Klassen;
  `kind`/`apiVersion` eines Unstructured-Objekts; ein Name wie bei `expand_class`
  gesplittet (ein qualifiziertes `group/version/Kind` behält Gruppe und Version;
  `+…`- und `…::…`-Namen tragen kein Kind).
- **Ein `apiVersion` im Hint pinnt Gruppe/Version.** Kubernetes::REST verweigert eine
  gepinnte, die der Cluster nicht bedient (sein k43); der Client prüft selbst mit:
  `_request_path` lehnt einen Pfad außerhalb `/apis/<group>/<version>/`
  (`/api/<version>/` für core) mit RESTs Meldung ab, und `_usable_class` prüft einen
  qualifizierten Namen, der über `_request_path` zu Unstructured aufgelöst wurde
  (kein Request, gecachter Katalog) → „unknown resource".
- **Ohne Discovery** (`resource_map_from_cluster` 0, der Default), für einen
  expliziten `IO::K8s::Unstructured`-Klassennamen oder ein Unstructured-Objekt ohne
  `kind` croakt `build_path`. `_request_path` fängt das und gibt `(undef, $message)`
  zurück (Ort entfernt), was der Aufrufer wie einen Auflösungsfehler meldet: failed
  Future oder croak in `update`/`update_status`/`ensure`/ beim Start des Watchers.
- **Unstructured-Status** liegt im Unknown-Fields-Beutel: über `TO_JSON` lesen, nie
  über `->status`.

## TLS / auth im Detail

- **Konfigurationsauflösung**: explizites `server`/`credentials` gewinnen; sonst
  `Kubernetes::REST::Kubeconfig` (explizites `kubeconfig` oder `context` → croakt
  beim Konstruieren mit dem Grund, z. B. „Context not found: x"; Automatik ohne
  beides → stilles eval, Fehler tauchen später als croakende Accessoren auf); sonst
  das In-Cluster-SA-Token (`Kubeconfig->api` fällt darauf zurück, wenn keine
  kubeconfig-Datei existiert, auch mit einem Context). `with` (CRD-Provider) ist
  `Kubernetes::REST->new(with =>)` seit 1.108 öffentlich.
- **`_ssl_options`** wird **einmal** berechnet und gecacht und flach in jeden Request
  und jeden Connect gesplatzt: `SSL_verify_mode` aus `ssl_verify_server`,
  `SSL_{ca,cert,key}_file` als Durchreichung; inline `ssl_*_pem` aus der kubeconfig
  wird in `File::Temp`-Dateien materialisiert (die Handles bleiben in
  `{_ssl_tempfiles}` für die Lebenszeit des Clients, damit die Pfade gültig bleiben);
  `*_pem` schlägt gleichnamig `*_file`. Kein SNI/`SSL_hostname` gesetzt.
- **https/wss** brauchen `IO::Async::SSL`, das Net::Async::HTTP / WebSocket nur
  empfehlen; das cpanfile verlangt es.
