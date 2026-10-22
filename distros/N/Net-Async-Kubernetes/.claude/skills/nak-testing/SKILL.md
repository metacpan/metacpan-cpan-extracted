---
name: nak-testing
description: Load before writing or changing tests in Net::Async::Kubernetes — the dual-mode harness, the mock transport registry, the mode map and the pinned Kubernetes::REST/IO::K8s suite.
---

# nak-testing — der Dual-Mode-Testharness

Nachbarskill zu `nak-core`: dort stehen Architektur und Naht, hier der Testharness.
Die Kern-API: `nak-core`. Fehlerwortungen: `nak-hazards`.

## Zwei Modi, eine Suite

`t/lib/MockTransport.pm` (Funktionen, Modul-Zustand) + `t/lib/TestKube.pm`
(`is_live`, `make_kube`, `loop`). `is_live()` = `TEST_KUBERNETES_REST_KUBECONFIG`
gesetzt. `make_kube()` liefert einen gemockten Client (`https://mock.local`,
`MockTransport::install`) oder einen live aus der kubeconfig; beide werden dem
prozessweit gemmemoisierten `loop()` hinzugefügt.

- **`MockTransport::install($kube)`** monkeypatcht **die Klasse** `ref($kube)`
  (`_do_request`, `_do_streaming_request`, `_do_duplex_request`, `_add_to_loop` →
  No-op). Pro Prozess unumkehrbar — nie einen echten Client in eine Datei mischen,
  die `install` ruft. Eine Test-Unterklasse des Clients bekommt ihre eigene
  gepatchte Kopie.
- **Registrierung**: zuerst `reset()`; `mock_response($method,$path,$data,$status,
  \%opts)` — der Schlüssel ist `"METHOD path"` **inklusive Query-String** (sortiert
  ascii-betical nach Schlüssel, wie `prepare_request` ihn baut); `{delay => 1}`
  löst einen Tick später auf, was falsch parallele Orchestrierung in
  `request_log` sichtbar macht. `mock_response_queue($method,$path,
  [$data,$status],...)` beantwortet einen Eintrag je Request (FIFO) und fällt dann
  auf `mock_response`/404 zurück — für 409-Rennen und Retries. Unregistriert → 404
  Status. `mock_watch_events($path,\@events,\%opts)` (`complete` ⇒ auflösen →
  reconnect; `fail` ⇒ Backoff-Retry; `status` ⇒ Antwortcode; ohne opts ⇒ pending
  bis `stop`); `mock_stream_chunks` für `log()`; `mock_duplex_session`. Ein `status`
  ≥ 400 auf einem von beiden ist eine Ablehnung wie am echten Transport: nichts
  erreicht den Chunk-Callback, der Request löst auf (ohne `complete` nötig) mit
  einem Status-Fehler-Body. Streaming-/Duplex-Pfade werden **ohne** Query-String
  gematcht. Inspizieren über `last_request()`/`request_log()`.
- **Discovery im Mock-Modus** (`t/32-mock-unstructured.t`): eine Client-Unterklasse
  überschreibt `rest`, um den `Kubernetes::REST` mit einem `io` zu bauen (verbraucht
  `Kubernetes::REST::Role::IO`; braucht `call` und `call_streaming`), das
  `GET /api` / `GET /apis` mit einer `APIGroupDiscoveryList` beantwortet.
  Ressourcen-Requests laufen weiter über das gemockte `_do_request`; zusichern, dass
  das io nur Discovery sah.
- **Das gemockte `_do_duplex_request` feuert nie Callbacks** — das Verhalten von
  exec/attach/cp wird stattdessen per `local *Net::Async::Kubernetes::exec` /
  `_make_websocket_client`-Monkeypatching getestet (siehe
  `t/13-duplex-transport.t`, `t/16-mock-cp.t`).
- **Dual-Mode-Skelett**: `use lib 't/lib'; use TestKube qw(is_live make_kube loop);`
  `require MockTransport unless is_live()`; Mock-Registrierungen in
  `unless (is_live()) {…}` und Live-only-Aufbau in `if (is_live()) {…}`; immer
  `loop()` benutzen (nie eine frische Loop); neben jeder async-Assertion eine
  `loop()->watch_time`-Watchdog spannen; `ok($ok || is_live(), …)` dort, wo das
  Live-Timing unzuverlässig ist.
- **Modus-Map**: `10-dual-*`/`11-dual-*` = dual (TestKube); `01-crud.t`/`02-watcher.t`
  = live-only (`skip_all` ohne kubeconfig); alles andere mock-only, kein Cluster.
  Achtung: `12-` wird zweimal benutzt (`12-controller.t`,
  `12-mock-port-forward.t`).
- **Ein Aufruf, der noch synchron sterben kann**, läuft im Test durch `eval`
  (`my $r = eval { $kube->x(...)->get }; is($@, '', ...)`) — ein ungefangenes die
  beendet die ganze Datei, nicht nur den Subtest.
- **Lauf**: `prove -l t/` (mock) · `TEST_KUBERNETES_REST_KUBECONFIG=~/.kube/config
  prove -lv t/` (live, nur minikube — verändert den Cluster).

## Gegen die gepinnten Kubernetes::REST / IO::K8s (k66)

`maint/prove-pinned.sh [--lib DIR] [--setup] [--setup-only] [-- PROVE_ARGS]` liest
beide Mindestversionen aus dem `cpanfile`, installiert genau diese plus den Rest
des cpanfile (Testphase inklusive, `--notest`) in ein selbständiges `cpanm -L`-
local::lib — Default `${TMPDIR:-/tmp}/nak-pinned-REST-<pin>-IOK8s-<pin>`, wieder
verwendet, solange das cpanfile unverändert bleibt (`--setup` startet cpanm neu —
und braucht das Netz) — und führt prove aus (Default `-lr t/`; eine Datei:
`-- -l t/42-mock-discover.t`) mit zurückgesetzten `PERL5LIB`, `PERLLIB`, `PERL5OPT`,
`PERL_LOCAL_LIB_ROOT`, `PERL_MB_OPT`, `PERL_MM_OPT`, `PERL_CPANM_OPT`,
`HARNESS_PERL_SWITCHES` und `TEST_KUBERNETES_REST_KUBECONFIG`. Zuerst druckt es die
geladenen Versionen und Pfade und stoppt bei einer anderen Version als dem Pin, einem
außerhalb von DIR geladenen Modul oder einer Kopie einer der Dists in einem anderen
`@INC`-Verzeichnis. **Nie** ein `-I`-Overlay eines älteren `lib/` stattdessen: es
findet immer noch, was jenes Release nicht hat, in `~/perl5` (1.109s
`Kubernetes/REST/APIError.pm` neben 1.108s `REST.pm` — `t/39` erwartet dann ein
APIError-Objekt aus einem `check_response`, das einen String wirft). Ein
Geschwister-Arbeitsbaum wird mit `prove -l -I/home/getty/dev/kubernetes-rest/lib`
geprüft (nur lesend).

## Die Pins

Das cpanfile pinnt: `Kubernetes::REST >= 1.109`, `IO::K8s >= 1.108`,
`IO::Async >= 0.80`, `IO::Async::SSL >= 0.12`, `Net::Async::HTTP >= 0.49`,
`Net::Async::WebSocket::Client >= 0.14`, `Future >= 0.47`, perl 5.020. Beide
K8s-Abhängigkeiten sind Getty-Dists — **nur veröffentlichte CPAN-Versionen pinnen**
(Skill `getty-perl-core`). Die lokal installierten Kubernetes::REST / IO::K8s liegen
oft vor dem Pin; Verhalten, das zählt, gegen die gepinnten Releases prüfen
(`maint/prove-pinned.sh`), nicht mit einem `-I`-Overlay eines älteren `lib/`.

## Ein einsegmentiger Klassenname

Ein einsegmentiger Klassenname (`'+Gizmo'` → `Gizmo`), an RESTs
`inflate_object`/`inflate_list`/`process_watch_chunk` unverändert übergeben, kann als
Kind gelesen werden (REST vor 1.109 tat das: Listeneinträge fielen weg, sie wurden
als das inflatiert, was der Map-Kurzschlüssel `Gizmo` benennt, und `ensure_only`
pruned in dieser Gruppe). Jede inflate-Aufrufstelle, auch die `process_watch_chunk`
des Watchers, übergibt `_exact_class($class)` (`'+Class'` für eine geladene Klasse
mit `IO::K8s::Role::Resource`, die Regel von RESTs privatem Helfer). Eine neue
inflate-Aufrufstelle muss dasselbe tun.
