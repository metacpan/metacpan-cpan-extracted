# The Review File Format, version 1

The Review File Format, version 1: the data a review tool and its agent
skills exchange. Any tool, in any language, may read and write the same
files and drive the same skills by implementing the command line in
[CLI.md](CLI.md).

The aim is a standard, sharable base for AI/LLM-assisted code review: one
review file that many tools, skills, and review processes can build on and
extend.

This document is authoritative for everything it covers. How a backend
implements it is covered by that backend's own documentation; the backends
in this repository each have a directory of their own beside `standards/`.

Covered: repository conventions, the diff convention, the review database,
the journal, the fill sheet, the feedback export and publish list, and the
export used to share a review. The command line the skills rely on is
[CLI.md](CLI.md) and the HTTP API the page uses is [API.md](API.md). The
three make up the standard, versioned as a whole (this is standard version
1; [CLI.md](CLI.md), "The standard's version", says when it changes);
`format_version` versions the files and exports alone, and raising it raises
the standard's version too. Not covered: how an agent chooses a file's
sections (only what a section means, and what `fill` accepts).

Conventions throughout:

- Timestamps are integer Unix epoch seconds.
- Lines are 1-based. A range is `[start, end]`, inclusive. A range list is a
JSON array of ranges, sorted, non-overlapping.
- "JSON" columns hold UTF-8 JSON text.
- Paths are repository-relative with `/` separators.

## Repository conventions

Terms: a **revision** is one recorded state of the repository, named by its
full id (git: a commit sha); the **empty revision** stands for "nothing yet"
(git: the empty tree's id); a **path spec** limits files as the VCS does
(git: a pathspec); a **pin** keeps a revision from being removed (git: a
ref); the **change id** of a commit is a stable id of its change, equal when
the same change is rebased (git: `git patch-id --stable`).

All locations are resolved through the VCS from the review file's directory
or the current directory; nothing stores a repository path. For git:

- Review files (default)

    `$(git rev-parse --git-path review-helper)/<name>.sqlite` (per worktree).
    Any path inside a worktree is valid.

- Journal

    `$(git rev-parse --git-path review-helper)/journal.jsonl` (per worktree).

- Registry

    `$(git rev-parse --git-common-dir)/review-helper/registry.json` (shared).

- Pins

    `refs/review-helper/<review-id>/<iteration-number>` (shared refs).

- Shared export ([Export](#export))

    `.review-helper/<name>.json`, committed on the branch under review.

### Registry

    { "reviews": { "<review-id>": { "path": "/abs/path/to/file.sqlite", "state": "open" } } }

`state` is `open` or `closed` and mirrors the review file's
`review.state`; closing a review sets both. State is each reviewer's own: an
import always arrives open ([Export](#export)).

### Pins and pruning

Each iteration pins its head commit under its `pin` name. Pruning removes
every pin of review `<id>` (for git, every ref under
`refs/review-helper/<id>/`) when the registry marks `<id>` closed or its
file no longer exists, then drops that registry entry. Pruning
never deletes review files.

### Locking

The registry and the journal ([The journal](#the-journal)) are shared by concurrent
processes. Open the file itself and hold an exclusive `flock` (`LOCK_EX`)
for every change: read, then rewrite in place (seek to the start, truncate,
write) or append. Never replace the file, for example by writing a temporary
file and renaming it: a process locked on the old file would then write into a
file nobody reads. Readers hold a shared `flock` (`LOCK_SH`).

## Diff convention

Line anchors depend on diff output, so every diff a tool stores counts from,
or whose line numbers it shows for anchoring, is a unified diff produced, for
git, as:

    GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
    git diff --no-ext-diff --no-color --no-textconv --indent-heuristic \
        --diff-algorithm=histogram --find-renames -U3 \
        --src-prefix=a/ --dst-prefix=b/ <parent> <commit> -- <paths>

with `GIT_LITERAL_PATHSPECS`, `GIT_GLOB_PATHSPECS`,
`GIT_NOGLOB_PATHSPECS` and `GIT_ICASE_PATHSPECS` unset. `<paths>` are
the iteration's path specs as stored (magic such as `:(exclude)` applies);
a diff of one file names it as `:(literal)<path>`, so a path holding
glob characters (`app/[id]/page.js`) matches only itself.

A root commit diffs against the empty revision. Changing any of this is a new
format version.

A tool may also show other views, such as more context around a unit or a
merge's conflict resolutions (git: its remerge diff), but nothing anchors to
them.

**Line counts** per hunk: each run of `-` lines followed by `+` lines counts
`min(removed, added)` as changed, the rest as removed or added.

## The review database

One SQLite 3 file. Readers ignore tables they do not know. The standard
never defines a table or column starting `x_`. An implementation's own
tables and columns start `x_<impl>_`, where `<impl>` is its name as in
`review-helper-<impl>` ([CLI.md](CLI.md), "The dispatcher"), as its own
fields, routes, commands and variables do ([API.md](API.md) and
[CLI.md](CLI.md), "Extensions"); one named otherwise may collide with a
later version of the standard or another implementation.

Readers check `format` and `format_version` in `meta` and nothing else of
the schema. Files are never upgraded: every change to the schema is a
new format version once the format is released. Until then version 1 still
changes, and a file an earlier build wrote may fail with SQLite errors; it
is rebuilt.

The schema is exactly [`review.sql`](review.sql), beside this file (in
`standards/` of the repository and of a distribution's share directory): a
new file is made by running it as is. Its types, constraints, defaults and
indexes are authoritative; the tables are:

- **`meta`**: `key` and `value`. Required keys: `format` = `review-file`,
`format_version` = `1`, `generator` = `<tool name> <version>`.
- **`review`**: exactly one row. `id` (UUID v7), `title`, `source` (the
pull/merge request URL, when reviewing one), `created`, `state` (`open` or
`closed`).
- **`iteration`**: one row per iteration. `number` (1, 2, ...), `base` and
`head` (revisions; `base` is the empty revision for a whole codebase),
`squashed` (1: one combined entry for `base..head`), `paths` (a JSON array
of path specs limiting the review; NULL: all), `pin` (the name of the pin
keeping `head`), `created`, `note` (what this iteration changed), and
`what`, `why` and `how` (the agent's summary of the whole change).
- **`commit_entry`**: an iteration's commits, or its topics. `id`,
`iteration`, `position` (1 = first), `merge_id` (the merge entry that
brought it in; NULL on the mainline), `revision`, `parent` (first parent's
revision; NULL for a root commit), `subject`, `message`, `author`,
`authored`, `change_id`, `topic` (squashed iterations: the topic's name;
NULL: no topic), `what`, `why`, `how`, and `order_set` (1 once reading order
is filled). Unique by `iteration` and `position`, and by `iteration`,
`revision` and `topic` (NULL counting as one value).
- **`file_change`**: the files an entry changes, unique by `commit_id` and
`path`. `id`, `commit_id`, `path` (after the commit; before it, for a
delete), `old_path` (renames only), `status` (`A`, `D`, `M` or `R`), `kind`,
`size_unit` (`lines` or `bytes`), `size_before` (NULL when added),
`size_after` (NULL when deleted), `added`, `removed`, `changed`,
`read_position` (reading order; NULL until filled), `split_source` (`none`
or `agent`), `what`, `object_system` and `paradigms`.
- **`section`**: a file change's sections. `id`, `file_id`, `position` (file
order), `name`, `package` (the enclosing package, class or module, when
known), `ranges` (JSON range list, new side; `[]` when deleted),
`doc_ranges` (JSON range list, new side), `old_ranges` (JSON range list, old
side), `deleted`, `added`, `removed`, `changed` and `what`.
- **`flag`**: `id`, `note_id` (the journal note id, shared by
carried-forward copies), `commit_id`, `path` (NULL: whole commit),
`line_start` and `line_end` (NULL: whole file), `color` (`yellow` or
`red`), `color_reason` (why the color last changed; NULL: as recorded),
`kind`, `sentence`, `detail`, `created` and `pending` (1: carried onto
changed code, awaiting the agent).
- **`journal_entry`**: an iteration's journal. `id` (the journal note id),
`iteration`, `kind` (as a flag's), `path`, `unit`, `sentence`, `detail` and
`created`.
- **`guide_step`**: an iteration's guide, keyed by `iteration` and
`position`. `target` and `highlight` (JSON; see [Guide JSON](#guide-json))
and `commentary`.
- **`feedback`**: `id`, `iteration`, `target` (`review`, `commit`, `file`,
`section`, `line` or `flag`), the anchor columns `revision`, `path`,
`section_name`, `section_package`, `topic`, `flag` (a flag's note id),
`flag_sentence`, `line` and `side` (`old` or `new`), then `body`,
`created`, `updated`, `status` (`open`, `addressed` or `declined`),
`response`, `resolved_in` (an iteration number), `published` (when posted
to the pull/merge request; NULL if not) and `reviewer` (who wrote it:
`Name <email>` or a login name; NULL if unknown).
- **`request`**: `id`, `iteration`, `kind` (`debate` or `split`), `target`
(`review`, `commit`, `file` or `section`), the anchor columns `revision`,
`path`, `section_name`, `section_package` and `topic`, then `note` (the
human's note), `status` (`open` or `done`), `created`, `case_for` and
`case_against` (debate results) and `reviewer` (who asked, as in
`feedback`).
- **`flag_seen`**: a reviewer has seen a flag. `flag` (the flag's `id`),
`reviewer` (as in `feedback`) and `at` (when marked).

### Meaning

- **Commits** in an iteration are `base..head`, oldest first, less any that
**Paths** below leaves out. The **mainline** is the first-parent chain from
`head` back to `base`; its entries have a NULL `merge_id`. A merge commit's
own entry groups the commits it brought in — those reachable from its second
and later parents but not from its first — through their `merge_id`. Merges
inside a branch nest the same way. A merge entry has no file changes; its
commits carry them.
- **Squashed iterations** review `base..head` as one combined change: entries
with `revision` = head, `parent` = base (NULL when the base is the empty revision,
i.e. the whole codebase), the head's `subject`, `message`, `author` and
`authored`, no `change_id`, and between them the file changes between base and
head, each in one entry. Used to review or learn a codebase as it lands
rather than its history.
- **Topics.** The agent filling a squashed iteration groups its files into
named topics (see [The fill sheet](#the-fill-sheet), `topics`), each reviewable on its own
(for example the skills, the Perl backend, the frontend). Each topic is an
entry of its own: `topic` holds its name, unique in the iteration, and its
`position` orders the topics. Files in no topic yet share one entry with a
NULL `topic`; before the first `topics` fill that is the iteration's only
entry, holding every file. Entries of other iterations have a NULL `topic`.
An iteration has at most one entry per `revision` and `topic` (NULL counting
as one value), so `revision` alone names an entry everywhere but in a squashed
iteration split into topics: there a path names the entry holding it, and an
anchor with no path names the topic too (**Feedback and request targets**,
[Guide JSON](#guide-json), the `note` item).
- **Paths.** When `paths` is set, only files matching those path specs are
included, so a large codebase can be split into several reviews. Without
squashing, commits that change no matching file are left out, and so are
merges left with no commits.
- **File kind.** `kind` names the language or content of the file: `perl`,
`javascript`, `typescript`, `css`, `html`, `xml`, `markdown`, `shell`, `sql`,
`json`, `yaml`, `ini`, `toml`, `python`, `ruby`, `go`, `rust`, `c`, `cpp`,
`java`, `makefile`, `dockerfile`, `diff`, `text`, `image` or `binary`. The
list in the schema is open: other tools may write other kinds, and a reader
treats a kind it does not know as plain text. `size_unit` is `bytes` for
`image` and `binary` files, which have no lines and always count zero
`added`/`removed`/`changed`; it is `lines` for every other kind. SVG files
are `text`, not `image`: they have a diff and take line feedback.
- **`object_system`** describes how the file's objects are built (for example
`Object::HashBase`, `Moose`, an ES class), and **`paradigms`** the
programming styles it uses (for example `OOP`, `exporter`, `functional`).
Both are free text, NULL where they do not apply.
- **`split_source`** says whether a file's sections exist yet: `none` (no
split yet: no sections) or `agent` (the agent filling the review split it
through a sheet; see [Sections](#sections)). A file's split
carries forward with it when the change is the same (see **Carry-forward**).
A file whose change is a rename or mode change alone stays `none` for good:
it gets no `split` item (see [The fill sheet](#the-fill-sheet)).
- **Sections.** A file change's sections are the agent's whole split of the
file, touched or not. A section is _touched_ when it is `deleted` or any of
its `added`, `removed` and `changed` counts is not 0 (it owns a `+` or
`-` line, see **Section counts**); displays show and explain only touched
sections, and untouched ones are kept so a later split can start from the
whole of this one. The agent filling the review defines them (see [Sections](#sections)); the tool finds
none itself, so a file has none until it is split. Every section is a
_unit_ the agent named: a sub, method, function, or other named braced construct, a
CSS rule, a heading, or a part of one the agent wants explained on its own.
Its `ranges` are its code lines, its `doc_ranges` the documentation and
comments the agent attached to it, and its `old_ranges` the lines it held
in the file before the commit, when the agent gave them. A unit with
`deleted` set existed only before the commit: it has only `old_ranges`. A
split covers every line of the file after the commit (a run of blank lines
in no unit joins the section before it, or after it at the top of the file,
as code or documentation like its neighbouring line), or none: a file the
agent leaves whole has no sections at all. A unit is identified by `name`
plus `package`, unique within its file.
- **Section counts.** A section's `added`/`removed`/`changed` count the diff
lines it owns, using the per-hunk rule of [Diff convention](#diff-convention) within each
section. A `+` or context line belongs to the section holding its new-side
line. A `-` line belongs to the section whose `old_ranges` hold it;
otherwise to the section holding the nearest following new-side line of its
hunk, or the nearest preceding one when none follows. `old_ranges` come
only from the agent (`old_lines` in [Sections](#sections)): a deleted unit's lines,
or lines at the edge of a live unit that the next line would otherwise take.
- **Anchors.** Feedback anchors to a commit's revision id + path + line in that
commit's file, never to a section id (in a squashed iteration split into topics, to
the topic holding the path). `side` says whether `line` counts in the file
before (`old`) or after (`new`) the commit. Flags anchor through
`commit_id` + path + lines; `line_start` and `line_end` count in the file
after the commit, or before it when the file change's status is `D`.
- **Feedback and request targets.** Each `target` requires these anchor columns;
the commit must be in the row's `iteration`, and the path and section must
exist in that commit:

    - `review`

        nothing

    - `commit`

        `revision`; `topic` when the commit is a squashed iteration's split into
        topics, or NULL for its files not yet in a topic (NULL otherwise)

    - `file`

        `revision`, `path`

    - `section`

        `revision`, `path`, `section_name` (`section_package` when the section
        has one)

    - `line`

        `revision`, `path`, `line`, `side`

    - `flag`

        feedback only: `flag`, the `note_id` of a flag of the row's iteration,
        with that flag's `sentence` as `flag_sentence`, its commit as
        `revision` and its `path` (NULL for a whole-commit flag, which also
        takes `topic` as a `commit` target does)

    `flag` and `flag_sentence` are set on no other target, except as context:
    when the agent retires a flag (the `flag` item of [The fill sheet](#the-fill-sheet)), its
    feedback becomes `file` feedback, or `commit` feedback when it has no
    `path`, that keeps both, naming the flag it was given on (whose rows may
    then be gone). `topic` is set on no other target, except
    as context: when a `topics` fill removes a topic's entry, `commit` feedback
    and requests on it become `review` ones that keep `revision` and `topic`, naming where they were
    given; a `topic` of `''` there names the entry of files not in a topic yet,
    and none the entry of the whole change. `section_name`/`section_package` may
    also be set on a `file` or `line` target as context. On `file` feedback and
    requests they name the section it was given on, which a later split took away
    or left untouched (see [The fill sheet](#the-fill-sheet), `split`). `split` requests always
    target a `file`; `debate` may target anything but `line`.

- **Flags.** A flag is the agent making the reviewer aware of something: a
change of direction, a bug found and fixed, a wrong assumption. Only agents
create flags, by placing journal notes ([The journal](#the-journal)). `color`
says what it asks of the reviewer:

    - `yellow`: a reviewer may object

        A decision, a deviation, or a problem solved in a way the reviewer
        may not accept.

    - `red`: probably a problem

        Something still unsolved. Nothing solved is red.

    Only the agent changes `color` (the `flag` item); `color_reason`
    says why it last changed, NULL while it is as recorded. No history is kept.
    `kind` labels where the flag came from: `deviation` (from a plan or spec),
    `assumption` (one that proved wrong), `self-review` (a correction found
    re-reading the work), `test-revealed` (a misunderstanding a test exposed),
    `note` (a point worth the reviewer's attention) or `other` (anything
    else). `sentence` is one line; `detail` optional. `pending` is 1 while
    the agent has not decided on a flag the carry-forward made pending
    (its code changed, its file left the change, or its commit was rewritten
    or dropped; see **Carry-forward**), 0 otherwise.

- **Journal entries.** What the agent recorded for the reviewer's
information that probably needs no attention: anything worth knowing that is
not a flag. A build or iteration takes every journal note without a `flag`
as an entry of the new iteration ([The journal](#the-journal)). An entry has
no lines, comments, seen marks or carry-forward: it belongs to the iteration
it was taken into.

- **Reviewers.** `reviewer` on `feedback` and `request` names who wrote the
row, as `Name <email>` or another name the reviewer chose; NULL when the tool
did not know. A `flag_seen` row records that a reviewer has seen a flag; it is
the reviewer's own state, like feedback. Seen marks belong to one flag row, so
to one iteration; a flag carried into a new iteration brings them unless it is
carried pending (see **Carry-forward**).
- **Sizes.** A file grew or shrank by comparing `size_before` and
`size_after`.
- **Carry-forward.** A new iteration may copy `what`/`why`/`how`, reading
order, and flags from a commit with the same `change_id` in the previous
iteration (commits sharing a `change_id` pair in order, the first with the
first; a commit with no `change_id`, whose diff is empty, pairs with the
same `revision`), and a file's split (`split_source` and its sections with
their `what`) when the file reads the same in both commits, before and after
them. Any other file starts unsplit, and its sections are explained afresh
once it is split again: explanations never carry by content. A copied
flag keeps every column but its `id` and `commit_id` (its color and
`pending` too), and its lines move by the diff between the file in
the old commit and in the new one (both before the commit for a deleted
file). When the file is not at its `path` in the new commit and the VCS
finds it renamed between the two commits (git: `git diff -M`), the copy
takes the new path and is compared there; in a squashed iteration, a copied flag with a
`path` goes to the entry holding that path. Its `flag_seen` rows (every reviewer's, keeping `at`) are copied too
when the code it covers is unchanged: no flagged line changed and no line was
added between them, or, flagging a whole file, the file reads the same in
both commits, or it has no `path`. Otherwise the code under it changed: the
copy is `pending` with no seen marks, on the lines from the first to the
last flagged line the diff kept, or on the whole file when it kept none, the
file exists in only one of the commits, or it is a binary file that changed.
A copy whose file left the change in this iteration is `pending` with no
seen marks too, whatever its lines: no entry of its commit (its revision's
entries, in a squashed iteration) changes its `path`, while in the previous
iteration an entry with that flag's commit's revision changed the path the flag
had there. A flag kept on a file already outside the change carries as any
other.
In an iteration that is not squashed, the flags of a previous commit that no
new commit pairs with (its change was rewritten, so its `change_id` changed,
or the commit was dropped) are copied too, `pending` with no seen marks: to
the last commit (by `position`) that changes the flag's `path`, its lines
moved by the diff between the file in the old commit and in that one as
above (the whole file when the diff keeps none of them); with no commit
changing its `path`, or no `path`, to the iteration's last commit, a flag
with a `path` there flagging the whole file.
Feedback on a flag needs no copying: it belongs to the flag's `note_id`.

    When the previous and the new iteration are both `squashed` with the same
    `base` and `paths`, their entries (which have no `change_id`) are matched by
    `topic` instead (NULL matching NULL). When the previous iteration has topics,
    the new one is split by them first: each file goes to the topic that held its
    path there, in the topics' `position` order, and files in none (new paths, or
    paths in no topic there) to one entry with a NULL `topic`, last; a topic left
    with no file is not made. Flags and their seen marks carry by the rules above;
    those of an entry no new entry matches (a topic left with no file) carry to
    the first entry, as a `topics` fill moves a flag whose entry goes. Reading
    order (`order_set` and `read_position`) is copied only when both entries
    list the same paths, and the entry's `what`/`why`/`how` only when, besides,
    every file reads the same after both (the base being the same, its change is
    then the same). A file's `what`, `object_system` and `paradigms` are copied
    only when the file reads the same in both entries. With another base or other
    paths, or when either iteration is not squashed, nothing is matched. Feedback
    and requests are never copied; a `commit` one with a `topic` belongs to the
    topic of that name in any iteration that has one, and one with no `topic` to
    the entry of its commit with none; `file`, `section` and `line` ones belong
    to the entry of their commit that holds their `path`, and a `section` one
    only while that file shows a section of its name and package (one the commit
    changed); a `flag` one belongs to the flag with its `note_id` in any
    iteration that has one. One that no entry or flag of the iteration shown
    holds (its commit, its topic, its path, its section or its flag is not
    there) is listed with the `review` feedback, so none is hidden.

- **Orphaned requests.** When a new iteration is added, an open `split`
request whose commit is not in it is closed: its `status`
becomes `done` and ` (closed: its commit was rewritten)` is appended to its
`note` (the note becomes just that text when it was NULL).

### Sections

A file's sections are data the agent filling the review supplies through a
`split` item of the fill sheet (see [The fill sheet](#the-fill-sheet)); no tool rule finds
them. The agent reads the file and names its units: subs, methods,
functions and other named braced constructs (a `subtest`, a `has` with a
sub, a `BEGIN` block), CSS rules, Markdown or POD headings, with the
comments and documentation that belong to each. The file's main package or
class block, module wrappers and control flow are not units; a short
secondary package or class inside another package's file may be one unit,
named `package Foo::Bar` or `class Foo::Bar` with `package` `Foo::Bar`
(a long one is named by its subs or methods). It may also
make a unit of part of a body, or split a long unit into parts, when they
need their own explanations. A split covers the whole file: the agent names
the lines between units too (a header, imports, a constant between subs, a
closing `1;`), so no line with text is left in no section. A file it leaves
whole (vendored, generated, trivial) gets an empty split, `[]`, and has no
sections.

Each section of a split is an object:

    { "name": "sub foo", "package": "Foo",
      "lines": [[12, 30]], "first_line": "sub foo ($self) {",
      "doc_lines": [[80, 84]],
      "old_lines": [[12, 28]], "old_first_line": "sub foo {" }

`lines` and `doc_lines` count in the file after the commit, `old_lines`
in the file before it (at its `old_path` when renamed); each is a range
list: an array of `[start, end]` pairs of positive whole numbers (a string
of decimal digits with no leading zero counts as one). A section with `lines` is
live; one with only `old_lines` is deleted: it existed only before the
commit. `package` may be null.

`fill` rejects a split, naming the section, when:

- a field is unknown, `name` is not a non-empty string or number,
`package` is given but is not one, or a range list is not an array of
arrays. Whitespace at either end of `name` and `package` is trimmed
first, and the trimmed value is stored;
- neither `lines` nor `old_lines` holds a range, `doc_lines` holds a range
but `lines` holds none, `first_line` is given but `lines` holds no range,
or `old_first_line` is given but `old_lines` holds no range;
- a range is not two positive whole numbers, is outside its side of the file
(`lines` and `doc_lines`: the file after the commit; `old_lines`: before
it), or starts after it ends;
- a new-side line (`lines` or `doc_lines`) or an old-side line is in two
sections, or twice in one;
- `lines` holds a range and `first_line` is missing or is not the text of
the first line of `lines` (the lowest), or `old_lines` holds a range and
`old_first_line` is missing or is not the text of the first line of
`old_lines`; whitespace at either end does not count;
- two sections have the same `name` and `package` (NULL counts as one
package).

and rejects the split as a whole when it holds a section and leaves a line
of the file after the commit that holds a character other than whitespace
in no section's `lines` or `doc_lines`.

A valid split replaces the file's sections: each section a unit (deleted
when it has no `lines`), the blank lines in none joined as in **Sections**
above, every one kept, touched or not, with counts from the diff
(**Section counts** above), and each with no `what`: a re-split file is
explained afresh. The file's `split_source` becomes `agent`.

A file whose change is the same in the next iteration keeps its sections
outright, with their `what` (**Carry-forward** above).

### Guide JSON

`target`:

    { "type": "summary" }
    { "type": "commit",  "commit": "<revision>", "topic": "Perl backend" }
    { "type": "file",    "commit": "<revision>", "path": "lib/Foo.pm" }
    { "type": "section", "commit": "<revision>", "path": "lib/Foo.pm", "section": { "name": "sub bar", "package": "Foo" } }
    { "type": "flag",    "flag": "<note id>" }
    { "type": "diff",    "commit": "<revision>", "path": "lib/Foo.pm", "section": { ... } }
    { "type": "view",    "commit": "<revision>", "path": "lib/Foo.pm", "lines": [10, 30] }

A `flag` target names the flag by its note id: a `flag` item's
`about.note`, or, for a `note` item placed in the same fill, its id without
the `note:` prefix.

For `diff`, `path` and `section` are optional: omit both for the commit's
diff, `section` for the file's. `topic` is allowed on `commit` and `diff`
targets only, and needed there, with no `path`, when the commit is a
squashed iteration's split into topics (it may be given, and must exist,
otherwise); a `path` names the topic holding it. A `view` of a path in no
topic shows it in the first. On a merge, a commit-level `diff` step shows
the merge's conflict resolution, or its commit list when it has none. A
`commit` is the full revision id, matched exactly (no prefix, no other case), here
and in a `note` item. A
`section` named by a `section` or `diff` step must be a touched one (see
**Sections**): displays show no other.

A `view` step may name any commit of the iteration, typically its head,
wherever the file exists at that commit; the commit need not have changed it.
A guide may tour the code as it finally lands rather than the history.

`highlight`:
`[ { "path": "lib/Foo.pm", "side": "new", "lines": [12, 14] } ]`, in the
target's commit; on a `view` step, `side` is `new`. A view's or a
highlight's `lines` is `[start, end]`, whole numbers from 1 with start
not after end, and is not checked against the file's length: a display
marks only the lines that exist.

`commentary` is at most 400 characters and written to be read aloud: no
backticks, `->`, `::`, `()`, or a sigil (`$`, `@`, `%`) followed by
a word character.

## The journal

JSON Lines. One note per line, appended under the lock described in
[Repository conventions](#repository-conventions). A writer that finds the file not ending in a
newline (a write cut short) writes one first, so its note starts a line of
its own:

    {"id":"<uuid v7>","created":1762732800,"flag":"yellow","kind":"deviation",
     "path":"lib/Foo.pm","unit":"bar","snippet":"return unless $x;",
     "sentence":"...","detail":"..."}

`id` is a non-empty string and `created` whole epoch seconds. `flag` is the
color of the flag to make, `yellow` or `red`, and `kind` one of `deviation`,
`assumption`, `self-review`, `test-revealed`, `note` and `other`, both as a
flag's (see **Flags** in [Meaning](#meaning)); a writer stores `other` when
the author gives no kind. `kind`, `path` and `sentence` are required; `flag`,
`unit`, `snippet` and `detail` may be null; every other field given is a
non-empty string (a reader also accepts a JSON number there). A note with a `flag` is removed from the journal, by a locked
in-place rewrite, when it is placed into a review as a flag. A note without
one is a journal entry: the next `build` or `iterate` stores it as an entry
of the new iteration (`journal_entry`, without `snippet`) and then removes it
the same way. A reader skips, with a warning, a line that is not a JSON
object with an `id`, and a rewrite keeps it as it is. A build or iteration
skips, with a warning, a journal entry that breaks a rule above, and leaves
it in the journal.

## The fill sheet

The only way agents write review text. `sheet` emits it; the agent fills
`fields`; `fill` validates and imports it.

    {
      "format": "review-sheet",
      "format_version": 1,
      "review": "<review id>",
      "iteration": 2,
      "items": [
        { "id": "commit:14", "type": "commit", "rev": "<hex>",
          "about": { "revision": "...", "subject": "..." },
          "fields": { "what": null, "why": null, "how": null } }
      ]
    }

- `about` is read-only context. It never contains code; agents read code
through the VCS.
- `rev` is a hash of the data the item describes. `fill` rejects an item whose
`rev` no longer matches.
- `fields` hold the item's current stored values, null where unset (feedback
`status` and every `flag` field always start null). A field returned with a value is written, even
when the value is the one the sheet gave.
- An item whose fields are all null is skipped. Empty strings are rejected.
- An item counts as done once its required fields are set; other fields may stay
null, meaning "not applicable". Required, per type:
    - `summary`: `what`, `why`, `how`; `note` is optional.
    - `commit`: `what`, `why`, `how`.
    - `topics`: `topics`; done while every file is in a topic.
    - `order`: `paths`.
    - `file` and `section`: `what`.
    - `split`: `sections`.
    - `note`: `commit`; `path` and `lines` may be null.
    - `flag`: `decision`, needed only while the flag is `pending`; any other
    flag is done.
    - `feedback`: `status`, which also needs a `response`, given in the sheet or
    already stored. The item is listed until its status is set.
    - `debate`: `case_for` and `case_against`.
    - `guide`: `steps`, none of them naming a section that is missing or
    untouched (as after a later re-split) or a flag the iteration no longer has
    (one the agent retired); such a guide is asked for again.
- Feedback and debate items list everything still open, whatever iteration it
was made in. A `split` request appears only while its commit and path are in
the latest iteration.
- `optional: true` marks an item that may be left empty without counting as
remaining work. `split`, `section` and `order` items are optional in squashed
iterations, where a whole codebase may hold thousands of units and paths. Only
notes with a `flag` get `note` items, and they are always optional. A `flag`
item appears for each `pending` flag of the iteration, and is required: the
code under it changed, and only the agent can tell whether the flag still
holds. With `--all` every flag of the iteration has one, so the agent can
recolor or retire it (after a reviewer's comment, say).
- Done items are left out of the sheet. `sheet --all` lists them too, with
their current field values and `rev`, so `fill` can replace text already
written. A replacement is checked as fully as a first fill, and an item
another fill changed since the sheet was taken is rejected as stale. Done
`summary`, `commit`, `topics`, `order`, `file`, `section`, `split`,
`flag`, `debate` and `guide` items come back; `note` items do not, since a
placed note leaves the journal and is then a flag; a journal note the
iteration already holds as a flag gets no item. A done `split` keeps null
fields; its `about` lists the current units. Feedback is listed only while
open, as its status may be the reviewer's.

- `summary`

    Id: `summary:<iteration>`

    Fields: `what`, `why`, `how`; from iteration 2 also `note` (what this
    iteration changed). `about` gives `title`, `base` and `head` (the
    iteration's revisions), `squashed` (true or false) and `paths` (its path
    specs, or null for all)

- `commit`

    Id: `commit:<commit id>`

    Fields: `what`, `why`, `how`; `about` gives `revision`, `subject`,
    `position`, `merge` (the merge that brought it in, or null) and `topic`
    (null but for a topic of a squashed iteration)

- `topics`

    Id: `topics:<iteration>`, in a squashed iteration only

    Fields: `topics`: `[{ "name", "paths" }]`, the topics in reading order,
    each with its paths; null until a topic is stored. `about` gives `paths`
    (every path of the iteration, sorted) and `unassigned` (the paths in no
    topic, sorted). `fill` rejects it unless `topics` is a non-empty array of
    objects with only `name` (a string or number, not empty, no control
    character, unique; whitespace at either end is trimmed first) and `paths` (a non-empty array of paths
    of the iteration), and every path of the iteration is in exactly one topic.
    One topic for all the files is fine for a small review. A `topics` item
    sent back with the topics stored (the same names in the same order, each
    with the same paths in any order) changes nothing and is skipped, like an
    item with no field set.

    Writing it makes the iteration's entries the topics, in order. A topic keeps
    the entry with its name, or else an entry (named or not) with exactly its
    paths, keeping that entry's `id`, text, reading order and flags, and is
    otherwise a new entry with the squashed entry's commit facts and no text. A
    kept entry whose paths change loses `what`, `why`, `how` and `order_set`.
    Each file change moves to its topic's entry, and each flag with a path to the
    entry holding the path; a flag with no path stays on its entry, or moves to
    the first topic when its entry goes. Every entry no topic kept is removed; its
    `commit` feedback and requests of this iteration become `review` ones
    keeping `revision` and `topic` as context (`''` for the entry with no
    topic when the iteration had topics: the files not in a topic yet), and those
    of a renamed entry take the new `topic`; those of earlier iterations keep the
    name they were given under (shown with the `review` feedback once no topic
    has it). A sheet that fills `topics` may hold no `commit`, `order`, `note`
    or `guide` item, which name entries the fill moves: each is rejected, to be
    filled from the next sheet. A stored guide step whose commit, `topic` or path
    no longer names an entry, or a path in it, makes the `guide` item not done,
    so the sheet asks for the guide again.

- `order`

    Id: `order:<commit id>`, one for each commit entry with files

    Fields: `paths`: every path of the commit, once each, in reading order;
    `about` gives `commit` (its revision) and `paths` (the commit's paths)

- `file`

    Id: `file:<file id>`

    Fields: `what`, `object_system`, `paradigms`. Done once `what` is
    stored; until then `fill` skips an item without `what`: nothing is
    written, it is not counted as filled, and it stays to do.

- `section`

    Id: `section:<section id>`

    Fields: `what`

- `split`

    Id: `split:<file id>`

    Fields: `sections`: the file's sections, as in [Sections](#sections); `[]` leaves
    the file whole. `about` gives `commit`, `path`, `old_path` (the path
    before the commit when renamed, where `old_lines` count; else null),
    `status`, `kind`, `size_before`,
    `size_after`, `request` (an open split request's `id` and `note`, or
    null), `sections` (the units stored now, in the `sections` field's shape, without
    first lines) and `previous`: while the file has no split, the newest split
    an earlier iteration stored for this path (or for its `old_path`), else
    null. Among the stored file changes of that path whose `split_source` is
    not `none`, it takes the newest iteration, in it the commit with the same
    `change_id` as this one (null matching null) when there is one, else the
    last by `position`. It is `{ "commit", "iteration", "path", "sections" }`:
    that commit's revision, its iteration, the path there, and each of its live
    (not `deleted`) sections in `position` order as `{ "name", "package",
    "lines", "doc_lines" }`: its stored `ranges` and `doc_ranges`, line
    numbers of the file in that commit, not moved to this one. Like
    `sections`, it holds the whole split.

- `note`

    Id: `note:<note id>`

    Fields: `commit` (full revision id), `topic` (null; in a squashed iteration split into
    topics, the topic a note with no `path` goes to, and needed then; a path
    picks the topic holding it), `path` (null for the whole commit), `lines`
    (`[s, e]`, null for the whole file)

- `flag`

    Id: `flag:<flag id>`

    Fields: `decision` (`keep`, `recolor` or `retire`), `color` (`yellow` or
    `red`) and `reason` (why the color changed). `about` gives its `note` (the
    note id, which a guide `flag` target names), `commit` (its revision),
    `topic`, `path`, `lines`, `color`, `color_reason`, `kind`, `sentence`,
    `detail`, `pending` (true or false), `left_change` (true when its commit
    no longer changes its `path`: the file left the change, as when a squashed
    change to it was reverted; such a flag comes back pending in the iteration
    the file leaves, and is usually retired), `rewritten` (true while
    `pending` in an iteration that is not squashed when the commit it is on
    does not pair with the commit it was on in the previous iteration: their
    `change_id`s differ, or, the old one having none, their revisions do; its
    commit was rewritten or dropped, see **Carry-forward**) and `previous`:
    while `pending`, where the flag was in the previous iteration, as `{
    "commit", "path", "lines" }` (null when that iteration has no flag with
    its note id), else null.

    `fill` rejects a `flag` item unless `decision` is given, and a `recolor`
    unless it has `color`, the other color, and `reason` (a non-empty
    string). A `keep` or `retire` ignores `color` and `reason`, given or not.

    A guide step in the same sheet may not name a flag the sheet retires.

    A filled `flag` item sets `pending` to 0; the flag stays on the lines the
    carry gave it. `keep` changes nothing else. `recolor` stores `color` and
    `reason` (as `color_reason`); a yellow flag turned red also becomes unseen
    by everyone (its `flag_seen` rows deleted). `retire` deletes the flag from
    the iteration with its `flag_seen` rows; earlier iterations keep their
    copies. Its `flag` feedback, from any iteration, becomes `file` feedback
    (`commit` feedback when the flag has no `path`) keeping `flag` (see
    **Feedback and request targets**). A stored guide step naming a retired
    flag makes the `guide` item not done, so the sheet asks for the guide
    again.

- `feedback`

    Id: `feedback:<id>`

    Fields: `status` (`addressed`/`declined`), `response`

- `debate`

    Id: `request:<id>`

    Fields: `case_for`, `case_against`

- `guide`

    Id: `guide:<iteration>`

    Fields: `steps`: `[{ "target", "highlight", "commentary" }]`

Every text file its commit adds, or does not delete and changes a line of
(it has a `+` or `-` line), has a `split` item, even an empty one (its
deleted units still need naming); deleted, image and binary files have none,
and so does a file whose change is a rename or mode change alone: it is one
unit with no sections. It is
required while the file has no split (`split_source` `none`; optional in a
squashed iteration) and while a `split` request on it is open, and done
otherwise. Its `about` `sections` lists the file's stored units, the
whole split. Section items for a file appear once it is split, in the next
sheet, one for each touched section (see **Sections**); a `section` item of
a file re-split in the same sheet is rejected. A filled split replaces the
file's sections (see [Sections](#sections)). Section feedback and section requests
on the file stay on the new touched section with its `name` and
`package`; with none (gone or untouched) they become `file` feedback or
requests that keep `section_name` and `section_package`, naming the
section they were given on. Nothing else about them changes. An open split
request on the file is marked done.

`fill` validates everything before writing anything, and rejects with a
message naming the item: unknown ids, wrong types, stale `rev`, ranges
outside the file, a split [Sections](#sections) rejects, an `order` that is not exactly
the commit's paths, `topics` that do not hold every path once, guide
targets or highlights that do not exist in the iteration, commentary over
400 characters or containing code tokens. A valid
sheet is written in one transaction.

## Feedback export

    {
      "format": "review-feedback",
      "format_version": 1,
      "review": "<review id>",
      "source": "<pull/merge request URL or null>",
      "iteration": 2,
      "base": "<revision>",
      "head": "<revision>",
      "feedback": [ { "id": 7, "iteration": 1, "target": "line", "commit": "<revision>", "topic": null,
                      "path": "lib/Foo.pm", "section": { "name": "sub bar", "package": "Foo" }, "flag": null,
                      "line": 42, "side": "new", "body": "...", "status": "open",
                      "response": null, "resolved_in": null, "published": null,
                      "reviewer": "Ann <ann@example.com>" } ],
      "requests": [ { "id": 3, "iteration": 1, "kind": "debate", "target": "file", "commit": "<revision>", "topic": null,
                      "path": "lib/Foo.pm", "section": null, "note": "...", "status": "open",
                      "case_for": null, "case_against": null, "reviewer": null } ]
    }

Each entry carries the anchor columns of its row as `commit`, `topic`,
`path` and `section` (`{ name, package }` or null). A feedback
entry's `flag` is null, or, for a `flag` target or feedback that a retired
flag left on its file or commit,

    { "note": "<note id>", "sentence": "...", "path": "lib/Foo.pm", "lines": [12, 14] }

its `flag`, `flag_sentence` and `path` (null for a whole-commit flag),
and `lines`: the `[start, end]` of the flag with that note id in the
entry's `iteration`, after the commit as a flag's lines count; null for a
whole-file or whole-commit flag, or one that iteration no longer has. A tool
posting the comment elsewhere can anchor it there.

## Publish list

What to post to the pull or merge request under review, each comment's
text final:

    {
      "format": "review-publish",
      "format_version": 1,
      "review": "<review id>",
      "source": "<pull/merge request URL or null>",
      "head": "<revision>",
      "items": [ { "id": 7, "text": "Why?", "anchor": { "path": "lib/Foo.pm", "line": 42, "side": "new" },
                   "fallback": "`lib/Foo.pm:42` (commit abc1234)\n\nWhy?" },
                 { "id": 8, "text": "`lib/Foo.pm`\n\nSplit this file?", "anchor": null, "fallback": null } ]
    }

`head` is the latest iteration's. `items` are the feedback items with
`status` `open` and `published` null, oldest first, or the items asked for
by id, in that order, each once.

An item is a general comment unless a line comment fits. Its `text` is then
its location prefix, a blank line, and its `body` exactly as stored, or the
`body` alone when it has no prefix; `anchor` and `fallback` are null. A
line comment's `text` is the `body` alone, `anchor` is where it goes, and
`fallback` is the general comment to post if the forge refuses the line
comment.

Prefixes, with `abc1234` the first seven characters of the item's
`revision`:

| Item | Prefix |
|---|---|
| `line`, `side` `new` | `` `path:line` (commit abc1234) `` |
| `line`, `side` `old` | `` `path:line` (old side, commit abc1234) `` |
| `section` | `` `path`, section `name` `` |
| `file`, no `section_name` | `` `path` `` |
| `file` with a `section_name` | `` `path`, was on section `name` `` |
| `commit`, no `topic` | `commit abc1234` |
| `commit` with a `topic` | `` topic `name` (commit abc1234) `` |
| `review`, no `topic` | none |
| `review` with a non-empty `topic` | `` was on topic `name` `` |
| `review` with a `topic` of `''` | `was on the files not in a topic yet` |
| `flag` whose flag has lines | `` `path:start-end` (commit abc1234), on a flag `` |
| `flag` with a `path`, its flag without lines | `` `path`, on a flag `` |
| `flag` with a `topic`, no `path` | `` topic `name` (commit abc1234), on a flag `` |
| `flag`, no `path` or `topic` | `commit abc1234, on a flag` |

A flag's lines are those of the flag with the item's note id in the item's
iteration, as in the feedback export; `start` alone when they are equal. A
`file` or `commit` item with a `flag` (a retired flag left it there) takes
`, was on a flag` after its prefix. A flag's sentence is never posted.

A `line` item's anchor is its `path`, `line` and `side`; a `flag` item's is
its flag's first line on the `new` side. It fits only when that line counts
in the same file as that side of the request's diff, as the review knows the
request (its latest iteration):

- that iteration has an entry for the item's revision;
- no other entry of it changes the path (as `path` or `old_path`, and
likewise the path the entry renamed the file from) after that entry, for
the `new` side, or before it, for the `old` side; with any
merged-in entry (`merge_id` set) in the iteration, no other entry changes
the path at all;
- except that the `old` side of an item from a squashed iteration fits when
that iteration's `base` is the latest one's.

## Export

A review is shared as JSON text: committed on the branch under review at
`.review-helper/<name>.json`, or attached to the pull/merge request. Each
reviewer imports it into a review file of their own.

    {
      "format": "review-export",
      "format_version": 1,
      "generator": "<tool name> <version>",
      "tables": {
        "iteration": { "columns": ["number", "base", ...], "rows": [[1, "<revision>", ...]] }
      }
    }

- **Tables.** Every table the schema defines except `feedback`, `request` and
`flag_seen` (each reviewer keeps their own); other tables a file holds are
not exported. `columns` lists every column in table order; `rows` holds every row as an
array in that order, sorted by primary key, or by rowid when the table has
none. Values are strings, numbers, or null.
- **Extensions** (`x_` tables and columns) are not carried in format version 1;
how extension data travels is part of the extension design still to come.
- **Layout.** Keys sorted, one row per line, so exports diff well.

Importing:

- Rejects an export whose `format` or `format_version` it does not support,
that has `feedback`, `request` or `flag_seen`, or that does not hold
exactly one `review` row.
- For a review not yet here, creates a new file with the current schema and
fills it with the exported rows
in one transaction; the new file's own `meta` rows are kept.
- **Another version's export.** On every import, new file or merge, an export
that lacks a table this format version exports, or a column of one (other
than an `x_` one), was built by a different version: it is refused, saying
to export it again with this version or import it with the version that
built it, since the missing column would otherwise load as null. A column
the file's table lacks fails the import. Tables it does not know, and `x_`
tables and columns, are ignored.
- **State is per reviewer.** The imported review is `open`, in `review.state`
and the registry, whatever state the export records.
- **Re-import merges.** When the review id is already registered with a file
that exists, or the target file holds the same review, the export is merged
into that file in one transaction: its `review` row replaces the file's, each
exported iteration replaces the file's iteration of that number with every row
under it (commits, files, sections, flags, journal entries, guide steps), and
iterations the file lacks are added. The file's `meta` rows, iterations the
export lacks, and all `feedback` and `request` rows stay. Flag ids are per
file, so a `flag_seen` row on a replaced flag moves to the flag with the same
`note_id` in that iteration when it covers the same commit, path and lines,
and is dropped otherwise, or when the export has the flag red where the file
had it yellow: a flag turned red is unseen by everyone.
- Each iteration's `pin` must be the name the VCS gives that iteration's
pin (git: `refs/review-helper/<review-id>/<number>`). Every iteration of the file
whose head commit is present is pinned, so re-importing after a fetch pins
what the fetch brought; the others are reported so their commits can be
fetched.
- Registers the review. Refuses when the target file exists and holds a
different review, and when the review is registered with a file that exists
and another target file is asked for.

