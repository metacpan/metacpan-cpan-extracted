---
name: review-build
description: Build a review-helper review of finished, committed work (a commit, branch, or PR) and fill in its explanations, reading order, note placement, and guide, so a human can review it with review-helper. Use when the user asks for a review file, or when a change made with the review-notes skill is done.
allowed-tools: Bash(review-helper *) Bash(git show *) Bash(git log *) Bash(git diff *) Bash(git grep *) Bash(git rev-parse *) Bash(git merge-base *) Bash(git status *)
---

# Building a review

You build a review file for a range of commits, then write the text a human
reads in place of the code: summaries, a reading order, where your notes
belong, and a short guided tour. The tool does the mechanical work; you write
only explanations.

## Build

```
review-helper prune
review-helper build --base <rev> [--head <rev>] [--title <text>]
```

- `prune` drops refs of closed or orphaned reviews. Always run it first.
- `--base` is the commit the work starts from: the commits reviewed are
  `base..head`. For a branch that is usually
  `git merge-base HEAD <main branch>`. If the range is unclear, ask the user.
- `--head` defaults to `HEAD`. `--title` is a short name for the change.
- `build` prints the review file path. Use it as `FILE` below.

## Fill

Repeat until `fill` reports nothing required remaining:

1. `review-helper sheet FILE` prints JSON with an `items` list.
2. Fill the `fields` of the items you are handling. Keep each item's `id`,
   `type`, and `rev` unchanged, and the top-level keys as printed. Leave an
   item's fields all null to skip it; never write empty strings.
3. Write the sheet to a temporary file outside the working tree and run
   `review-helper fill FILE <that file>`. It validates everything first and
   names any item it rejects; fix that item and fill again.

Work in batches if the sheet is large. `about` gives context only; read the
code at its commit with git ("Splitting a file" below has two tips for
that). Items of type `feedback` and `debate` belong to the
review-feedback and review-requests skills; leave them null.

### Rewriting filled text

A filled item leaves the sheet. Only when the user asks for a rewrite, or
for you to correct text you wrote and got wrong, run
`review-helper sheet --all FILE`: it also lists the filled items with their
current values. Send back only the items you change, `rev` as printed. A
stale `rev` means the item changed since your sheet; take a new one and read
it before writing again. Never use it to replace what a human wrote, or to
change feedback and debate items outside the skills they belong to.

## Writing the text

The human should judge the design from your summaries and open code only when
details matter. Use short paragraphs and `-` bullet lists. Say each thing
once, at the highest level it belongs; lower levels add only what is new.
Each commit's text and its file summaries should fit on one tablet or monitor
screen.

Write the prose fields (`what`, `why`, `how`, a flag's `reason`) the way the
guide's commentary should sound (see "How the commentary should sound"
below): plain words, lead with the purpose, and full sentences rather than
piles of nouns. Bullets are fine; each bullet is still a sentence a person
would say. If a term from the code or the spec matters, say what it means
in each field that uses it, since readers jump around the page.

- **summary** — the whole change. `what` it does, `why` it was needed, `how`
  it works: the approach and the main pieces.
- **commit** — `what`/`why`/`how` for that commit's part of the change.
- **topics** — only in a squashed review, `--squash`; the review-project
  skill says how to fill it.
- **file** — `what` changed in the file. `object_system`: how its objects are
  built (`Object::HashBase`, `Moose`, plain package, ES class, ...).
  `paradigms`: `OOP`, `exporter`, `functional`, `procedural`, ... Leave either
  null where it does not apply, as for Markdown or images.
- **section** — `what` changed in that sub, block statement, CSS rule, POD
  `=head1` or heading. One or two sentences. Facts that differ from the file
  go here, not repeats. Section items appear once the file is split, one
  for each section the commit changed.
- **order** — `paths`: every path of the commit, once each, in reading order.
  A file comes after the files needed to understand it. Put a test first when
  it shows the intent best.
- **split** — the file's sections; see "Splitting a file" below. Every text
  file whose lines the commit changed, and did not delete, has one, and so
  does every text file the commit added, even an empty one; it is required.
  A file only renamed, or with only its mode changed, has none.
- **note** — one of your flag notes (journal entries need no placing: the
  build took them as they are). Read the code at the commits in range
  and set `commit` (the full sha), `path`, and `lines` (`[start, end]`) to the exact
  lines the note concerns. Choose the commit that wrote that code. Use
  `lines: null` for the whole file, and `path: null` for the whole commit.
  Leave `topic` null; only a squashed review split into topics uses it.
- **flag** — required for a flag carried onto code that changed
  (`about.pending` true; it comes after an `iterate`). Read where it was
  (`about.previous`) and the code under it now, and set `decision`. When
  `about.left_change` is true the change no longer touches its file (the
  change to it was reverted, say): it usually no longer applies. When
  `about.rewritten` is true its commit was amended or dropped, and the flag
  was moved to the last commit that changes its file (or the last commit):
  judge it there, and if it belongs somewhere else, retire it and record a
  new note.
  - `keep` — it still holds as it is, on the lines the carry gave it
    (`about.lines`). When it no longer fits any lines, retire it and record
    a new note instead.
  - `recolor` — it holds, but as the other color (as the review-notes skill
    picks them): a new `color` and a one-sentence `reason`. A problem since
    solved in a way the reviewer may still question turns yellow. Turning
    red shows it again, as new, to every reviewer.
  - `retire` — it no longer applies. It leaves the new iteration; its
    comments move to its file, marked as having been on it.

  `sheet --all` lists every flag, pending or not, so you can recolor or
  retire one that work later in the range settled, with a reason naming the
  commit. Its `about` gives the commit its lines are in and its `note` id,
  which a guide `flag` step names.
- **guide** — see below.

## Splitting a file

You decide where a file's sections are: you are reading the code anyway, and
the human reviews it section by section. Read the file at the commit with
numbered lines, `git grep -a -h -n '' <sha> -- ':(top,literal)<path>'`,
and its change, `git diff <parent> <sha> -- ':(top,literal)<path>'`.
`:(top,literal)` keeps a path like `app/[id]/page.js` from matching other
files and works from any directory, and `-a`
reads a file `.gitattributes` marks binary.

Fill `sections` with one object per section:

```
{ "name": "sub fetch", "package": "My::Client",
  "lines": [[40, 72]], "first_line": "sub fetch ($self, $url) {",
  "doc_lines": [[210, 218]] }
```

- `lines`: the section's code as `[[start, end], ...]` in the file after the
  commit. `first_line`: the exact text of its first line, so an off-by-one
  is caught; whitespace at the ends does not matter.
- `doc_lines` (optional): its documentation, wherever it is: Perl POD naming
  it (such as `=head2 fetch` after `__END__`), a JSDoc `/** ... */` block.
  In Perl, use it for POD only; the page renders it as POD.
- `package`: the namespace the code is declared in: the name in
  `package Foo::Bar;` or `class Foo::Bar`, or the module or namespace in
  other languages; null when there is none.
- `old_lines` with `old_first_line` (optional), in the file before the
  commit (at `about.old_path` when the file was renamed): for a unit the
  commit removed outright, give only these, no `lines`. A live unit may
  take them too, when lines removed at its edge would otherwise count
  toward the next section.

What is a section:

- Subs, methods and functions, and other named block statements:
  `subtest "basic" => sub {...}`, `has cache => sub {...}`, `BEGIN`,
  `describe('parser', () => {...})`, a multi-line `my %TABLE = (...)` that
  matters on its own. A CSS rule, or a run of related rules. A Markdown
  heading with its text; a POD `=head1` with its text.
- Not containers: the file's main package or class, module wrappers, a
  JavaScript class body; name what is inside them instead. Not control
  flow: `if`, loops, `map`, `grep`, `eval`, `try`; they stay in the section
  around them.
- The one exception: a short secondary package or class inside another
  package's file (about 100 lines or less) is one section, named
  `package Foo::Bar` or `class Foo::Bar`, with `package` set to `Foo::Bar`
  itself; a long one is split into its subs or methods like any code. The
  file's main package is never a section.
- A block of POD shared by several methods, such as a bare list of methods
  or several `=item` lines sharing one description, is its own section,
  named for what it covers: `POD: method list`,
  `POD: check methods that return errors`. Its POD goes in its `lines`
  (with `first_line`), like a `=head1` section, not in `doc_lines`. A
  documentation line still belongs to one section only.
- Comment lines directly above a unit go in its `lines`.
- You may add a section to explain part of a long unit on its own: name it
  after the unit, like `sub fetch: retry loop`, and give the unit the lines
  around it (`lines` can hold several ranges). Do it only where the parts
  need different explanations.

Names identify a section across iterations and anchor the human's feedback,
so keep them steady: `sub fetch`, `method render`, `subtest "basic"`,
`has cache`, `function parse`, `=head1 NAME`, `## Usage`, the selector text
of a CSS rule. Leave out signatures and arguments. These conventions always
win. A name is unique within its package in the file; add ` (2)` to a
repeat.

When an earlier iteration split the file, `about.previous` gives that
split, all of it, as stored: its `commit`, and each section's `name`,
`package`, `lines` and `doc_lines`, numbered as the file was in that commit.
Diff that commit's file against this one if you want to map the lines. It
is context, not a rule. Where it still fits the code, keeping its boundaries
and its names (those that follow the conventions above) keeps the review
steady across iterations; where it no longer fits, or was not a good split,
change it or drop it freely and split the file as you see best.

Cover the whole file, not only the changed lines: every line with text must
be in a section. Name the parts between units too, by what they hold:
`header`, `imports`, `use constant LIMIT`, `globals`, `end`. Blank lines may
be left out; they join the section before them (the section after them, at
the top of the file). Every section is kept, but only those the commit
changed are shown and explained. Or leave a file whole with `"sections": []` when
sections would not help: vendored or generated code, lock files, data, and
small or trivial files; the page then shows the file and its diff with no
sections.

`fill` rejects a split whose ranges fall outside the file or overlap,
whose first lines do not match, that repeats a name, or that leaves a line
with text in no section; fix it and fill again. The section items come in
the next sheet. A re-split file is explained afresh: its sections take no
explanation from an earlier split, even where they read the same.

## The guide

A short tour of the change, played step by step in the page and often read
aloud by speech synthesis. Fill `steps` with
`{ "target", "highlight", "commentary" }`.

- Target types: `summary`, `commit`, `file`, `section`, `flag`, `diff`, and
  `view` (a file at a line range). `<sha>` is always the full sha, as
  `about` gives it; a short one is refused. Shapes:
  `{ "type": "commit", "commit": "<sha>" }`,
  `{ "type": "file", "commit": "<sha>", "path": "<path>" }`,
  `{ "type": "section", "commit": "<sha>", "path": "<path>", "section": { "name": "<name>", "package": "<package or null>" } }`,
  `{ "type": "flag", "flag": "<note id>" }` (a flag item's `about.note`, or
  the id after `note:` of a note item you place in the same fill),
  `{ "type": "diff", "commit": "<sha>" }` (add `path`, then `section`, to
  narrow it), `{ "type": "view", "commit": "<sha>", "path": "<path>", "lines": [s, e] }`.
  In a squashed review split into topics, a `commit` or `diff` step with no
  `path` also names its `"topic"`.
- `highlight`: the exact lines the step talks about, in the target's commit:
  `[ { "path": "<path>", "side": "new", "lines": [s, e] } ]`. Use `old` for
  removed lines. Highlight whenever the commentary points at code.
- A step about one sub, method, function, or heading targets that `section`
  when the commit changed that section and the `highlight` is on lines the
  section owns, in its code or its documentation. The page opens the section
  with its diff, which shows the whole unit and its documentation. Otherwise
  use `view` with the section's lines, as for a whole
  file, a span across sections, or a file the commit did not change.
- `commentary`: up to three short sentences, at most 400 characters.
- Start at the summary. Go into diffs and source only at points of interest:
  the core idea, a tricky spot, a red flag. Skip commit overviews the guide
  already covers. Use the fewest steps that tell the story.
- The guide need not follow the history. For a long or merge-heavy range,
  tour the code as it finally lands instead: `view` steps at the head commit
  (any commit of the range works, wherever the file exists), with `flag`
  steps interleaved for the points of interest. A flag lives on a file its
  commit changed, so a view of a file that commit did not change shows no
  flags; tour flags with `flag` steps. Step into individual commits or
  merges only where how the code got there matters.
- Write to be heard. Say "the highlighted loop", "the Builder module", "the
  fill method". Never write code tokens: no backticks, `->`, `::`, `()`, or a
  `$`, `@`, or `%` before a word. `fill` rejects them.

### How the commentary should sound

Talk as if you were sitting next to the reviewer, pointing at the screen.

- Use "this", "here", "notice", and "so". Make one point per step.
- Say why before what: the purpose, or what is surprising. Leave out details
  the screen already shows.
- Use plain words. If a term from the code or the spec matters, such as
  "change id" or "squashed review", say what it means the first time.
- Never put a list after a colon, never write "X: A, B, C, and D", and keep
  to one comma list per sentence.
- Read each line as if you were saying it out loud, and rewrite any you would
  stumble over.

Bad, then good:

- Bad: "The highlighted method made this review: one entry carrying the head
  commit's text, the base as its parent, no patch id, and the files of the
  range diff. Above it, the normal path lists every commit, works out merge
  ownership, and drops commits that touch none of the given paths."
  Good: "This method is what builds a squashed review. Instead of walking
  each commit, it pretends the whole branch is one big commit, from the base
  to the head. The method just above it is the normal path, one commit at a
  time."
- Bad: "Red flag: the retry loop has no upper bound, no backoff, and no
  logging, so a failing server causes unbounded requests, CPU load, and
  silent failure."
  Good: "Here is the worry. If the server keeps failing, this loop retries
  forever, as fast as it can. Nothing slows it down or stops it, so it needs
  a limit."
- Bad: "This change adds export and import: a JSON writer, a schema check,
  iteration replacement, and ref pinning, with tests, docs, and a Changes
  entry."
  Good: "This change lets you hand a review to someone else. You export it to
  a file, and they import it into their own copy of the repository. Notice
  that an import never touches their own feedback."

## Serve the review

If you already started a server for this review in this session and it is
still running, give its URL again. Otherwise start one yourself: run
`review-helper serve FILE` as a background process, so it keeps running,
and give the user the URL it prints on its first line. If the user wants to
review with others on their network, start it (stopping your earlier one)
with `review-helper serve FILE --listen 0.0.0.0` and give them the URL with
the token, the first one it prints; anyone holding it can read the review
and leave feedback. Stop the server when the review is closed, or when the
user asks.

## Finish

Tell the user the review is ready, and give them its URL (see "Serve the
review").

Offer to export the review so others can import it:

```
review-helper export FILE --out .review-helper/<name>.json
```

The export leaves out feedback and requests. Whether to commit it on the
branch or attach it to the PR is the user's call; never commit it unasked.
