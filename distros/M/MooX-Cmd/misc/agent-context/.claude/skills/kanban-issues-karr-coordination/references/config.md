# Board config and the karr-foundation opt-out

## config

```bash
karr config                          # this board's effective config
karr config get KEY
karr config set KEY VALUE
karr config show --defaults          # karr's built-in defaults; reads no board
karr config show --compact           # key=value per line
karr config --json
```

Writable keys: `board.name`, `board.description`, `defaults.status`,
`defaults.priority`, `defaults.class`, `claim_timeout`, `lock_timeout`,
`foundation.enabled`, `foundation.reason`.

`show` and `get` read this board and exit 1 when there is none — never the
built-in defaults. `--defaults` reads no board and needs no repository, so
`diff <(karr config show) <(karr config show --defaults)` is exactly what this
board overrides.

## The stored shape

`refs/karr/config` holds sparse overrides of this YAML; the next card id is
kept apart in `refs/karr/meta/next-id`.

```yaml
version: 1
board:
  name: My Project
statuses:
  - backlog
  - todo
  - name: in-progress
    require_claim: true
  - name: review
    require_claim: true
  - done
  - archived
priorities: [low, medium, high, critical]
classes: [expedite, fixed-date, standard, intangible]
claim_timeout: 1h
lock_timeout: 5m
defaults:
  status: backlog
  priority: medium
  class: standard
foundation:
  enabled: false
  reason: abandoned driver, backlog parked
```

## disable / enable — no automated agent runs here

```bash
karr disable                                  # karr-foundation skips this board
karr disable --reason "abandoned driver, backlog parked"
karr enable
karr disable --json                           # {"foundation":{"enabled":0,"reason":"…"}}
karr config get foundation.enabled            # 0 or 1
karr config set foundation.enabled false      # true/false, yes/no, on/off, 1/0
karr config set foundation.reason "why"
```

Board state (`foundation.enabled` in `refs/karr/config`), so it syncs with the
board and every foundation instance on every machine honours it: no drain, no
auto-block, no agent run — neither `karr-foundation --command`, the config's
`default_command`, the `.karr` file nor `--force` overrides it. The board stays
fully usable by hand. `karr disable` without `--reason` clears a stored reason.
Use it for a backlog that is parked rather than abandoned.
