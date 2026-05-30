# Domain Docs

Wie die Engineering-Skills die Domänen-Doku dieses Repos lesen sollen, wenn sie den
Code erkunden.

## Vor dem Erkunden lesen

- **`CONTEXT.md`** im Repo-Root — das Glossar / die Domänensprache.
- **`docs/adr/`** — die ADRs, die den Bereich berühren, an dem gerade gearbeitet wird.

Dies ist ein **Single-context**-Repo: ein `CONTEXT.md` plus `docs/adr/` im Root.

Wenn eine dieser Dateien nicht existiert, **stillschweigend fortfahren**. Ihr Fehlen
nicht melden und nicht vorab vorschlagen, sie anzulegen. Die Producer-Skills legen
sie erst dann an, wenn Begriffe oder Entscheidungen tatsächlich fixiert werden.

## Dateistruktur

```
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-….md
│   └── 0002-….md
└── lib/
```

## Das Glossar-Vokabular verwenden

Wenn die Ausgabe ein Domänenkonzept benennt (Issue-Titel, Refactor-Vorschlag,
Hypothese, Testname), den in `CONTEXT.md` definierten Begriff verwenden. Nicht zu
Synonymen abdriften, die das Glossar bewusst vermeidet.

## Async-spezifische Domäne

`Net::Async::Crawl4AI` erbt die Domänensprache von `WWW::Crawl4AI` — die Begriffe
Strategy Chain, Attempt, Result, Classification, DeepCrawl gelten hier genauso.
Die async-Sphäre fügt hinzu: Future contract, retry policy, concurrency knob,
delay_sub (test hook), poll_interval (job polling).

## ADR-Konflikte melden

Widerspricht die Ausgabe einem bestehenden ADR, das explizit ansprechen statt
stillschweigend zu übergehen.