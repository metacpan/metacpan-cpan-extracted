# Issue tracker: karr

Issues und PRDs für dieses Repo leben in **karr** — einem git-nativen Kanban-Board.
Der Board-Zustand wird in `refs/karr/*` gespeichert (nicht in Commits oder im
Arbeitsverzeichnis). Tasks sind Markdown + YAML-Frontmatter mit numerischer ID.

CLI: `karr` (App::karr). Siehe `../p5-app-karr/README.md` für die volle Doku.

## Board-Initialisierung

Einmalig pro Repo, falls noch kein Board existiert:

```bash
git for-each-ref refs/karr/      # leer? -> Board anlegen:
karr init --name "Net-Async-Crawl4AI"
```

## Skill-Verb → karr-Befehl

| Was ein Skill will            | karr-Befehl                                                            |
| ----------------------------- | ---------------------------------------------------------------------- |
| Issue/PRD anlegen             | `karr create --title "…" --body "…" [--priority …] [--tags …]`         |
| Ticket holen                  | `karr show <id>`                                                       |
| Auflisten / suchen            | `karr list [--status …] [--tag …] [--search …] [--json]`                |
| Triage-Tag setzen             | `karr edit <id> --add_tag <role>`                                      |
| Triage-Tag entfernen          | `karr edit <id> --remove_tag <role>`                                   |
| Kommentar / Verlauf anhängen  | `karr edit <id> --append_body "…"`                                     |
| Status / Board-Spalte ändern  | `karr move <id> <status>`                                              |
| Task claimen (AFK-Agent)      | `karr pick --claim "$(karr agentname)" --status todo --move in-progress` |
| Übergabe an anderen Agenten   | `karr handoff <id> --claim NAME --note "…" --timestamp`                |

## Konventionen

- **Issue-ID** = die numerische karr-ID (z. B. `karr show 7`).
- **PRDs** sind Tasks mit dem Tag `prd` (oder über `karr set-refs` verknüpft).
- **Triage-Rollen sind Tags**, orthogonal zur Kanban-Spalte (`--status`/`move`).
  Ein Ticket kann z. B. in der Spalte `todo` stehen und gleichzeitig den Tag
  `ready-for-agent` tragen. Siehe `triage-labels.md` für die Rollen-Strings.

## Async-spezifische Notes

Das WWW::Crawl4AI Repo hat ein eigenes karr-Board. Beide Boards sind unabhängig.
Für async-spezifische Issues (IO::Async integration, Future contracts, retry
policy) dieses Board nutzen.

## Wenn ein Skill sagt „publish to the issue tracker"

`karr create …` ausführen — die ausgegebene numerische ID ist die Issue-Referenz.

## Wenn ein Skill sagt „fetch the relevant ticket"

`karr show <id>` mit der übergebenen ID. Für Suche `karr list --search "…" --json`.