---
name: nak-runtime
description: Load before changing the runtime behaviour of Net::Async::Kubernetes — ensure/ensure_all/ensure_only, the Watcher reconnect rules, the Controller workqueue and the websocket duplex transports.
---

# nak-runtime — ensure, Watcher, Controller, Duplex

Nachbarskill zu `nak-core`: dort stehen Architektur und Naht, hier die
Zustandsmaschinen. Wortungen der Fehlerbehandlung: `nak-hazards`.

## ensure / ensure_all / ensure_only

- **Hashref → `_manifest_to_object`**: `apiVersion` ist maßgeblich
  (`expand_class($kind, $apiVersion)`, croakt mit beiden Namen, wenn nichts es
  bedient); ohne apiVersion der nackte Kind. Die aufgelöste Klasse geht als
  `'+'.$class` an `struct_to_object` — ein plain `Gizmo` (aus `'+Gizmo'` in der Map)
  würde erneut als Kind gelesen.
- **`ensure`**: unchecked GET → 404: POST; POST 409 → nachladen → derselbe Weg wie
  bei einem existierenden Objekt. Vorhanden: core `v1` PersistentVolumeClaim
  unverändert zurück; `batch/v1` Job, solange aktiv/erfolgreich, sonst löschen mit
  `propagationPolicy` Background (Fehler ignoriert) + `create`; alles andere PUT auf
  der resourceVersion des Servers (zurück in das Objekt des Aufrufers geschrieben),
  ein 409 dort holt einmal nach und ruft `update` (kein weiterer Versuch).
  Sonderfälle matcht `_api_version_and_kind` (exaktes apiVersion + Kind; Klassendaten
  für typisierte Objekte, Instanzdaten für Unstructured) — nie nach dem Klassennamen.
- **`ensure_all`**: streng sequentielle Future-Kette; der erste Fehler stoppt sie.
- **`ensure_only`**: löst erst jeden Hashref auf, dann `ensure_all`, dann pro
  Kind × Namespace (sequentiell) `_list_request` und je unerwartetem Eintrag
  (sequentiell) `_delete_request` mit `propagationPolicy` (Option, Default
  Background; ein unbekannter Wert croakt vorher). Schlüssel = (API-Gruppe, Kind,
  Namespace, Name) aus jedem Objekt — nie aus dem `kinds`-String; keine Version.
  Ein 404 bei list oder delete ist still; jeder andere Fehler (HTTP-Fehler,
  Transportfehler, unauflösbarer `kinds`-Eintrag) wird gecarpt (`ensure_only: cannot
  list <Kind> in namespace '<ns>' | at cluster scope, nothing pruned there: <reason>`
  / `cannot delete <Kind> '<name>' …`) und der Prune läuft weiter. Der Grund
  verliert den Ort des gefangenen Croaks; carps eigener zeigt in die Future (der
  Aufrufer des Callbacks). Ein sterbendes `$SIG{__WARN__}` scheitert das Future. Es
  löst in jedem Fall auf die angewendeten Objekte auf.

## Watcher mechanics

Konfiguration: `kube` (**schwache Referenz**), `resource`, `namespace`, `timeout`
(300), `label_selector`, `field_selector`, `names`, `event_types`,
`reconnect_delay` (1), `max_reconnect_delay` (30), `reconnect_jitter` (0.2),
`max_retries` (undef = endlos), `min_watch_duration` (1; diese fünf werden in
`configure` geprüft, croak), `on_added`/`on_modified`/`on_deleted`/`on_error`/
`on_event`. `start` ist idempotent; `stop`.

- **Parameter je Zyklus**: `watch=true`, `timeoutSeconds`, die verfolgte
  `resourceVersion`, Selektoren. `resourceVersion` wird aus jedem verarbeiteten
  Chunk-Ergebnis aktualisiert. Die Auflösung der Ressource croakt in
  `_start_watch` (beim Add/Start).
- **410 Gone**: leert `resourceVersion`, verwirft die restlichen Events in diesem
  Chunk, geht **nicht** an `on_error`; der Stream endet natürlich und verbindet sich
  ohne Version neu.
- **Reconnect**: ein Zyklus, der mit Status < 400 endet → sofortiger Neustart (und
  Zurücksetzen der Fehlerzahl) — außer er endete direkt nach einem Nicht-410-ERROR-
  Event oder ohne jedes Event innerhalb von `min_watch_duration` (Default 1 s,
  client-gos „very short watch"; gemessen mit `_now` = `$loop->time`, der
  Test-Override-Punkt). Diese, eine Antwort ≥ 400 und eine gescheiterte Anfrage →
  `_watch_failed`: Verzögerung `reconnect_delay * 2**(n-1)`, gedeckelt bei
  `max_reconnect_delay` (Exponent gedeckelt bei 64), dann verkürzt (nie verlängert)
  um `reconnect_jitter * _random_fraction` und auf ms gerundet (`_random_fraction` =
  `rand`, der Test-Override-Punkt; Tests, die Delays prüfen, setzen
  `reconnect_jitter => 0`), gehalten in `_retry_future`; ein Nicht-ERROR-Event auf
  einem Stream setzt die Fehlerzahl zurück (ein ERROR-Event nie; ein 410 zählt für
  die Leerstream-Regel als Event). Jeder Fehlschlag wird gemeldet — was
  `event_types` auch sagt — als `Status`-Hashref (`reason => 'WatchFailed'`,
  `code` = HTTP-Status, der Code des abschließenden ERROR-Events oder 0,
  `message` „watch X failed, retrying in Ns: cause" (`_cause_text`, k74: ein
  APIError als `HTTP <code> <reason>: <message>` aus seinen Accessoren, der Body
  wenn er keinen Status hält; alles andere ohne sein abschließendes
  ` at FILE line N.`), `details => {kind, retryAfterSeconds}`) an `on_error`, sonst
  `warn`. Nach `max_retries` aufeinanderfolgenden Fehlschlägen hört er zuerst auf,
  meldet dann „giving up after N retries". Kein `allowWatchBookmarks`, kein
  Informer-Cache.
- **`start`** ist ein No-op, solange gewatcht oder auf `_retry_future` gewartet wird,
  und setzt die Fehlerzahl zurück. **`stop`** bricht ein pending `_retry_future` ab
  und verschiebt `$f->cancel` auf `$loop->later` — ein Cancel im eigenen `on_read`
  der Verbindung löst Net::Async::HTTPs „Spurious on_read of connection while idle"
  aus. Jeder neue Cancel-Pfad muss dasselbe tun. `on_error` darf `stop` rufen.
- **Zustellreihenfolge**: Typfilter (explizit `event_types`, sonst abgeleitet aus
  den gesetzten Callbacks; `on_event` = Auffangnetz), dann Namensfilter (bei ERROR
  übersprungen), dann `on_event($event)` und eines von
  `on_added`/`on_modified`/`on_deleted($object)`; `on_error` bekommt den **rohen
  Hashref** für ERROR-Events. Callbacks sind nicht eval-geschützt.

## Controller runtime

Konfiguration: `kube` (**schwache Referenz**) ODER Client-Bau-Keys (baut einen
eigenen Client, hält ihn stark — er besitzt ihn), `on_reconcile` (Pflicht),
`on_watch_error`, `retry_delay` (scalar|arrayref|coderef, Default 1). API:
`watch_resource($resource, %watcher_args, key_for=>sub)`, `start`/`stop`,
`get_object`/`list_objects` (dünne `$kube->`-Wrapper), `patch_status` (eigene Signatur
`status => {...}`, merge als Default; jeden anderen Key weist der Controller selbst
ab (k65) — der Client sieht nur `patch`/`type` — und eine ungerade Liste nach dem
Objekt oder dem positionalen Namen (k68, `Invalid arguments to patch_status()`,
wie die Keyed-Form es immer tat; der Client weist es seit k69 genauso ab; baut
`{status => ...}` und delegiert an `patch_status` des Clients), `update_status`
(delegiert an den Client). Beide melden jeden schlechten Input als failed Future —
`update_status` prüft vorab mit `_object_class`, wo der Client croaken würde.

- `_add_to_loop` croakt ohne `kube`+`on_reconcile`, fügt `kube` bei Bedarf der Loop
  hinzu, croakt bei Loop-Mismatch, dann `start`.
- **Workqueue**: Key = `key_for->($object,$spec)` sonst `"ns/name"`. Das neueste
  Event überschreibt den ctx des wartenden Eintrags (der letzte Zustand gewinnt);
  `active`-Einträge bekommen `dirty=1` und werden nach dem laufenden Reconcile
  wieder eingereiht; `queued` dedupliziert.
- **Lebensdauer eines Eintrags**: ein Eintrag fällt, **sobald sein Key sauber
  reconciled ist** (nichts wartet, nichts dirty, nichts im Retry) — `{entries}` ist
  kein Cache, es ist ausstehende Arbeit. Ein gescheiterter Key behält Eintrag,
  `failures` und den scharfen Retry, damit der Backoff überlebt. `DELETED` braucht
  keinen eigenen Fall; sein Reconcile endet im selben Zweig.
- **Der Drain überspringt** einen wartenden Key, dessen Eintrag weg ist, statt den
  Rest der Queue aufzugeben. Heute unerreichbar; es bewacht die nächste Änderung an
  den Prune-Bedingungen.
- **Reconciles sind global serialisiert** (`active_key`) — einer pro Controller,
  nicht pro Key; lange Reconciles blockieren alles per Head-of-Line.
- **Rückgabewert des Reconciles**: die → failed Future; kein Future → done. Ein
  Fehler erhöht `failures` und plant einen Retry über `retry_delay` (coderef
  `($attempt,$ctx,$error)`, arrayref nach Versuch indiziert, scalar; 0/false ⇒ heißes
  `$loop->later`-Requeue). Kein Versuchsdeckel, kein Jitter.
- **ctx-Hashref**: `{controller, kube, resource, event_type, object, key, attempt}`.
  `controller` und `kube` sind **schwach** — der ctx überlebt das Reconcile im
  Eintrag, und beide würden sonst zyklisch halten (`kube → children → controller →
  kube` und `controller → entries → ctx → controller` schließen auf sich selbst).
  Gilt für das ganze Reconcile, auch für verkettete Futures; ein über den
  Reconcile hinaus gehaltener ctx hält nichts am Leben.
- **Watch-ERROR-Events und die `WatchFailed`-Meldungen des Watchers** erreichen
  `on_watch_error($error, {controller,kube,resource})`, nicht die Workqueue — sie
  tragen ein `Status`-Hashref ohne Key zum Deduplizieren. Ein an `watch_resource`
  übergebener `on_error` hat für diesen Watch Vorrang.
- **`stop` ist Teardown, nicht Pause**: es stoppt jeden Watch **und löst ihn vom
  Client** (`remove_from_parent` — `kube->watcher` hatte ihn `add_child`ed), leert
  die Queue samt `queued`/`dirty`-Flags und verwirft die Retry-Timer. Die
  Fehlerzahlen bleiben. Ein Neustart baut frische Watcher, die wieder LISTen — ein
  aus `watch_resource` gehaltener Watcher-Handle ist nach einem `stop` wertlos.
- **`watch_resource` vor dem Start des Controllers** liefert `undef` (die Spec wird
  gespeichert, der Watcher startet bei `start`).

## Duplex transport (port_forward / exec / attach / cp)

- Normalen Request bauen mit `Connection: Upgrade`, `Upgrade: websocket`,
  `Sec-WebSocket-Protocol` (Default `v4.channel.k8s.io`), dann
  `_do_duplex_request`: https→wss-URL, Header werden zu
  `Protocol::WebSocket::Request` konvertiert (connection/upgrade/host/key/version
  fallen weg, `Authorization` bleibt), `_make_websocket_client` (Mock-Override-
  Punkt), `->connect(..., _ssl_options)`, löst mit einer `PortForwardSession` auf.
- **Kanäle** (erstes Byte jedes Binärframes): 0 stdin, 1 stdout, 2 stderr,
  3 Fehler-/Status-JSON, 4 TTY-Resize. `on_frame->($channel,$payload)`; `on_close`
  feuert höchstens einmal; die User-Callbacks sind eval-geschützt → `on_error`.
- `port_forward` hängt die Ports manuell als `?ports=N&ports=M` an; `exec`/`attach`
  übergeben `command`/Flags via `parameters` (Arrayref-Expansion). Vorgaben: stdin
  false, stdout true, stderr true, tty false.
- **`cp_to_pod`**: slurpt die lokale Datei **voll in den Speicher**, `exec` mit
  `sh -c 'head -c "$1" > "$2"'`, Upload über `_send_stdin_chunks` (sequentielle
  64-KiB-Future-Kette). **`cp_from_pod`**: `cat $remote`, sammelt ch1 im Speicher.
  Fehlererkennung = Regex `/"status"\s*:\s*"Failure"/i` auf dem ch3-Payload.
  Braucht `sh`+`head` bzw. `cat` im Container. **Kein tar** — die `Changes`-Wortung
  0.006/0.007 ist veraltet.
- Alle Duplex-/cp-Pfade verlangen, dass der Client bereits in einer Loop ist;
  `_do_duplex_request` benennt die aufrufende Methode über sein `caller =>`-Argument,
  die cp-Helfer prüfen die Loop selbst.

## PortForwardListener (`port_forward_listen`)

Eigene Klasse in `lib/Net/Async/Kubernetes/PortForwardListener.pm`, kein
`PortForwardSession`: sie stellt **lokale TCP-Listener** bereit — so wie
`kubectl port-forward` eine lokale Portnummer auf einen Pod-Port abbildet.

- `new` croakt, wenn `kube`, `mappings` oder `forward_args` fehlen.
- `start` öffnet je Mapping einen TCP-Listener; ohne `host` lauscht er auf
  `127.0.0.1`.
- `port_for` liefert die zu einem Mapping passende lokale Portnummer.

Der Client baut den Listener in `port_forward_listen`; die Session-Klasse trägt die
Websocket-Seite (`write_channel`, `write_stdin`, `resize`, `close`).
