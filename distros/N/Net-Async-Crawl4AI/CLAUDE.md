# CLAUDE.md

Repo-spezifische Hinweise für `Net::Async::Crawl4AI`. Die allgemeinen Perl-Regeln
(Module-Loading, Moo/Moose, `@Author::GETTY` Dist::Zilla, cpanfile-Versionierung,
Style) stehen in der Workspace-`../CLAUDE.md` und im `perl-core`-Skill — die gelten
hier weiterhin.

## Agent skills

### Issue tracker

Issues und PRDs werden mit **karr** (git-natives Kanban, Board in `refs/karr/*`)
verwaltet. See `docs/agents/issue-tracker.md`.

### Triage labels

Die fünf kanonischen Triage-Rollen sind als karr-Tags mit ihren Standardnamen
abgebildet. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: ein `CONTEXT.md` + `docs/adr/` im Repo-Root. See `docs/agents/domain.md`.