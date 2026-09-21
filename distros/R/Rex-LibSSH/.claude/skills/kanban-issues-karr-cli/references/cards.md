# Cards: create, show, move, edit, delete, archive

Every command here takes `--json`. `ID,ID,...` is accepted wherever an `ID`
is shown. A karr id is written `k12` in prose, never `#12` — the forge
resolves `#12` against its own issue tracker.

## create

```bash
karr create "Title" [--status STATUS] [--priority PRIORITY] [--tags t1,t2] [--body TEXT]
karr create --title "Title" --assignee NAME --due 2026-03-15 --estimate 2h --class expedite
karr create "Ship it" --depends-on 2,3                  # ids on this board; each must exist
karr create "Wait for the fix" --needs other-repo#7     # waits on a card in another repository (cross-board.md)
karr create "Fix the thing" --escalated-from home#5     # the card raised in that other repository
karr create "Start now" --status in-progress            # claimed as $KARR_CLAIM; a require_claim status refuses without a claim
karr create "Start now" --status in-progress --claim NAME
karr create "For someone else"                         # unclaimed: KARR_CLAIM is used only for a require_claim status
karr create "New card" --json                           # the card as JSON, so the id can be piped on
```

Priorities on a default board: `low`, `medium`, `high`, `critical`. Classes
of service: `expedite`, `fixed-date`, `standard`, `intangible`. `karr config`
shows this board's lists and defaults.

## show

```bash
karr show 12                 # the card in full, body included
karr show                    # the most recently updated card
karr show --last 5           # the five most recent
karr show --me               # the card your identity most recently acted on (re-orient)
karr show --agent NAME       # the card most recently claimed by NAME
karr show 12 --compact       # one line per card, as list --compact
karr view 12                 # alias for show
```

## move

```bash
karr move 12 STATUS                    # to a named column
karr move 12 --next                    # one column forward
karr move 12 --prev                    # one column back
karr move 12 in-progress --claim NAME  # move and claim (defaults to $KARR_CLAIM)
```

A `require_claim` column refuses without a claim. Taking a card whose
dependencies are unfinished warns, never blocks.

## edit

```bash
karr edit 12 --title "New title"
karr edit 12 --priority high --class fixed-date --due 2026-03-15 --estimate 3h
karr edit 12 --clear-due
karr edit 12 --status review
karr edit 12 --assignee NAME                  # the person responsible; not a claim
karr edit 12 --add-tag urgent --remove-tag later
karr edit 12 --body "New description"
karr edit 12 -a "Appended note"               # append to the body
karr edit 12 -a "Appended note" -t            # ... prefixed with the UTC timestamp
karr edit 12 --claim NAME                     # claim (defaults to $KARR_CLAIM)
karr edit 12 --release                        # release the claim
karr edit 12 --block "Waiting on API"         # mark blocked, with the reason
karr edit 12 --unblock
karr edit 12 --add-depends-on 2,3             # board-local dependencies, no duplicates
karr edit 12 --remove-depends-on 4            # absent ids are a no-op
karr edit 12 --add-needs other-repo#7         # cross-board dependency (cross-board.md)
karr edit 12 --remove-needs other-repo#7      # absent references are a no-op
```

Dependency rules: an unknown or non-numeric id in `--depends-on` /
`--add-depends-on` rejects the whole invocation before anything is written
(usage error, exit 2). A self-reference (`karr edit 5 --add-depends-on 5`)
fails only that id, the rest of the batch proceeds, and the command exits 1.

## delete

```bash
karr delete 12                 # asks first — on STDERR, so --json output stays parseable
karr delete 12 --yes
karr delete 12,13,14 --yes
karr delete 12 --claim NAME    # a card claimed by this agent
```

Before an id goes, `delete` names on STDERR every card on this board that
points at it (`depends_on`, `parent`) and every cross-board link the card
itself carries (`needs:`, `escalated-from:`), offering `karr archive` as the
way to keep it readable. It then proceeds: karr warns about dependencies, it
does not block on them. `--json` carries the same sentences as
`dependent_warnings` and `cross_board_warnings`. A card with a live claim is
not deleted: release it or wait for `claim_timeout`.

## archive

```bash
karr archive 12                # soft-delete: status archived, out of list and board
karr archive 12 --claim NAME
```

Idempotent. Archived cards are read with `karr list --archived` only.
