# Issue tracker: karr

Issues and PRDs for this repo live in **karr** — a git-native kanban board.
The board state is stored in `refs/karr/*` (not in commits or in the
working tree). Tasks are Markdown + YAML frontmatter with a numeric ID.

CLI: `karr` (App::karr). See `../karr/README.md` for the full docs.

## Board initialization

Once per repo, if no board exists yet:

```bash
git for-each-ref refs/karr/      # empty? -> create the board:
karr init --name "Net-Async-Crawl4AI"
```

## Skill verb → karr command

| What a skill wants            | karr command                                                           |
| ----------------------------- | ---------------------------------------------------------------------- |
| Create issue/PRD              | `karr create --title "…" --body "…" [--priority …] [--tags …]`         |
| Fetch ticket                  | `karr show <id>`                                                       |
| List / search                 | `karr list [--status …] [--tag …] [--search …] [--json]`                |
| Set triage tag                | `karr edit <id> --add_tag <role>`                                      |
| Remove triage tag             | `karr edit <id> --remove_tag <role>`                                   |
| Append comment / history      | `karr edit <id> --append_body "…"`                                     |
| Change status / board column  | `karr move <id> <status>`                                              |
| Claim task (AFK agent)        | `karr pick --claim "$(karr agentname)" --status todo --move in-progress` |
| Hand off to another agent     | `karr handoff <id> --claim NAME --note "…" --timestamp`                |

## Conventions

- **Issue ID** = the numeric karr ID (e.g. `karr show 7`).
- **PRDs** are tasks with the tag `prd` (or linked via `karr set-refs`).
- **Triage roles are tags**, orthogonal to the kanban column (`--status`/`move`).
  A ticket can e.g. sit in the `todo` column and carry the tag
  `ready-for-agent` at the same time. See `triage-labels.md` for the role strings.

## Async-specific notes

The WWW::Crawl4AI repo has its own karr board. The two boards are independent.
For async-specific issues (IO::Async integration, Future contracts, retry
policy) use this board.

## When a skill says "publish to the issue tracker"

Run `karr create …` — the numeric ID it prints is the issue reference.

## When a skill says "fetch the relevant ticket"

`karr show <id>` with the given ID. For search `karr list --search "…" --json`.