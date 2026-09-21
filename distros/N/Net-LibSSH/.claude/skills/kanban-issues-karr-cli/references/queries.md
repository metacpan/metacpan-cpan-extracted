# Queries: list, board, dashboard, log, metrics, context

All six take `--json` and `--compact`.

## list

```bash
karr list                                  # open cards
karr list --compact                        # one line per card
karr list --status todo,in-progress
karr list --priority high,critical
karr list --tag backend
karr list --class expedite
karr list --assignee NAME
karr list --blocked                        # only blocked cards
karr list --not-blocked
karr list --archived                       # the archive, and nothing else
karr list -s "search term"                 # title, body, tags
karr list --sort priority --reverse        # id, title, status, priority, created, updated, due
karr list --sort priority -n 5 --json      # the five most urgent open cards
karr list --group-by status                # assignee, tag, class, priority, status
karr list --claimed-by NAME                # exact match on the claim field (defaults to $KARR_CLAIM)
karr list --unclaimed                      # what no live claim holds
```

Finished work is out by default: the final column (`done`) and `archived`
appear only when named (`--status done`, `--archived`). `priority` sorts most
urgent first. `-n`/`--limit` cuts after filtering **and** sorting, so
`--sort priority -n 5` is the five most urgent cards, not five arbitrary ones
put in order — the "what next" call without pulling the whole board.

`--unclaimed` is "free right now": no claim, or one older than
`claim_timeout` — the same test `pick` uses, without taking the card. It is
not the opposite of `--claimed-by NAME`, which matches an expired claim too;
passing both is a usage error. A blocked card nobody holds is still listed, so
`--blocked --unclaimed` is a real triage query.

## board

```bash
karr board                    # every column but the last
karr board --done             # the final column too
karr board --tags             # tags on an extra line per card
karr board --group-by tag     # assignee, tag, class, priority, status
karr board --compact          # status(count): ids, one per column
```

One `## Status` section per column in board order, empty ones included, and a
footer totalling cards, claims and blocks. The final column is hidden unless
`--done` is given and the footer says how many it withheld (`(2 done hidden)`).
Archived cards are in none of it.

## dashboard

```bash
karr dashboard                        # scan the current directory
karr dashboard ~/projects --depth 2   # default depth 4
karr dashboard --hide-no-board        # drop the board-less list
karr dashboard --show-no-board        # list board-less repos by name
```

Walks a directory tree for Git repositories with a karr board and prints one
block per board, several side by side per terminal row, each open card
coloured by status. Configuration-free and read-only: never fetches, pushes or
writes. Board-less repositories that do not fit one line collapse to a count.

## log

```bash
karr log                       # last 20 entries
karr log --agent NAME
karr log --task 5
karr log --action KIND         # one action kind
karr log --since 2026-01-01
karr log --last 50 --json
karr log --compact             # one line per entry
```

## metrics

```bash
karr metrics                   # throughput, lead/cycle time, efficiency, aging
karr metrics --since 2026-01-01
karr metrics --compact         # one line plus one per aging item
```

Every figure comes from the `created`/`started`/`completed` stamps on the
cards, not from the log. Cards whose stamps cannot carry a measurement (an
unreadable date, `started` before `created`, `completed` before `started`) are
left out of the averages that need them and counted in `unusable_timestamps`
(cards, not stamps). Lead time is the exception: a `completed` before its own
`created` is averaged in, negative and all, and counted in
`negative_lead_samples` — such cards come from boards written before karr
0.403, which stamped bare dates that read as midnight.

## context

```bash
karr context                                # markdown summary
karr context --write-to AGENTS.md           # create/update the file between sentinels
karr context --sections blocked,overdue     # in-progress,blocked,overdue,recently-completed,activity
karr context --days 14                      # lookback for recently-completed (default 7)
karr context --activity-limit 10            # other agents' log entries (default 5)
karr context --compact                      # board_name and the four counts, key=value
```

Sections: In Progress, Blocked, Overdue, Recently Completed, Recent Activity.
`--write-to` updates in place between `<!-- BEGIN kanban-md context -->` and
`<!-- END kanban-md context -->`.
