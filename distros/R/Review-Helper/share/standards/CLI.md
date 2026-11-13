# The Review Helper command line, standard version 1

The commands the agent skills (`skills/`) rely on, and how one command name
reaches any implementation. An implementation that provides the required
commands below drives the same skills and reads and writes the same review
files, whatever language it is written in.

The standard has three parts, versioned as a whole: the review file
format ([FORMAT.md](FORMAT.md)), the HTTP API the page uses
([API.md](API.md)), and this command line. `version` reports it.

## The standard's version

The standard is versioned as a whole; this is version 1. Until the first
release it stays 1 and may change freely. After it:

- An optional addition (a route, a response field, a command, an option)
  does not change the version.
- Removing, renaming or changing anything required raises it.
- Raising the review file's `format_version` ([FORMAT.md](FORMAT.md)) raises
  it too.

## The dispatcher

Skills and people run `review-helper`. It is a short POSIX `sh` script
(`bin/review-helper` in the repository, installed with every
implementation) that runs an implementation found on `PATH`:

- An implementation is an executable regular file named
  `review-helper-<impl>` in a `PATH` directory, where `<impl>` is its name:
  one or more letters, digits, `_` and `-`. A file whose name has any other
  character after `review-helper-` (`review-helper-x.bak`), a file that is
  not executable, and a directory are passed over. `PATH` is walked in
  order, and within a directory the files are taken in the order the shell
  sorts them; empty entries in `PATH` and directories that cannot be read
  are skipped. When several directories hold an implementation of the same
  name, the first is that implementation.
- `REVIEW_HELPER_IMPL`, when set, names the one to run. It is an error
  (exit 127) when that one is not on `PATH`, and (exit 2) when the name has
  any other character.
- Otherwise the first implementation found runs. None found is an error
  (exit 127).
- Every argument is passed on unchanged, and the implementation's exit
  status is the dispatcher's.
- `review-helper --which` prints one line for each implementation found, in
  the order found: `* <impl> <path>` for the one it would run and
  `  <impl> <path>` (two spaces first) for each other, where `<path>` is
  the `PATH` entry, `/`, and the file name. Then it runs the chosen
  implementation's `version`.

## Conventions

- Commands run inside a repository, located from the current directory (or
  the review file's directory).
- Output goes to standard output; errors go to standard error with a
  non-zero exit status, and a command that fails prints nothing on
  standard output.
- A review file path printed (by `build` and `import`) is absolute.
- `-` in place of the `SHEET` of `fill` or the `JSON` of `import` reads
  standard input; no other argument accepts it.
- `FILE` is a review file; `R` a revision as the VCS names it; `P` a path.
- Terms (revision, empty revision, path spec, pin, journal, registry) are
  those of [FORMAT.md](FORMAT.md), "Repository conventions".

## Required commands

Every implementation provides these, with these options and this output.

- `note [--flag C] [--kind K] --path P [--unit U] [--snippet S] --sentence T [--detail D]`

    Does: Append a journal note in the current worktree: a journal entry, or
    with `--flag` a flag of color C (`yellow` or `red`). `--kind` is one of
    `deviation`, `assumption`, `self-review`, `test-revealed`, `note`,
    `other` (the default). Needs no review file.

    Prints: The note id.

- `build [--base R] [--head R] [--squash] [--path P]... [--title T] [--source URL] [--file P]`

    Does: Create a review and iteration 1 covering the commits after
    `--base` up to `--head`, taking the journal's entries; pin; register.
    `--base` is required unless `--squash`, where it defaults to the empty
    revision. `--head` defaults to `HEAD`. `--squash` reviews the range as
    one combined change. Each `--path` (a path spec) limits the review to
    matching files. `--source` links the review to a pull or merge request.
    `--file` chooses the review file's path.

    Prints: The review file path.

- `iterate FILE [--base R] [--head R]`

    Does: Add the next iteration, keeping the previous one's squash mode and
    path specs, and taking the journal's entries; pin. `--base` defaults to
    the previous iteration's base, `--head` to `HEAD`.

    Prints: The iteration number.

- `sheet [--all] FILE`

    Does: Emit the fill sheet ([FORMAT.md](FORMAT.md), "The fill sheet")
    for the latest iteration: every item still needing agent input. `--all`
    also lists the items already filled, with their current values and
    revs, so `fill` can replace them.

    Prints: Sheet JSON.

- `fill FILE SHEET`

    Does: Validate and import a sheet. Nothing is written unless the whole
    sheet is valid; a rejected sheet exits non-zero with its problems on
    standard error, each on a line of its own, a problem with an item naming
    its `id` (a heading line may come first).

    Prints: `filled N, remaining M`: the items written and the required
    items still to do.

- `feedback FILE [--open | --publish [ID...]]`

    Does: Export feedback and requests ([FORMAT.md](FORMAT.md), "Feedback
    export"); `--open` only open ones. With `--publish`, list the feedback
    to post instead: open items not yet posted, or the items with those ids
    ([FORMAT.md](FORMAT.md), "Publish list").

    Prints: Feedback JSON, or publish list JSON.

- `export FILE [--out P]`

    Does: Export the review for sharing ([FORMAT.md](FORMAT.md), "Export"),
    to standard output or `P`, creating missing directories.

    Prints: Export JSON, unless `--out`.

- `import JSON [--file P]`

    Does: Create a review file from an export, or merge an export of a
    review already here into the file holding it ([FORMAT.md](FORMAT.md),
    "Export"); register as open; pin present iterations. A file holding
    another review is never overwritten.

    Prints: The review file path; on standard error, a line for each
    iteration whose head is missing, naming it as `iteration N` (in any
    case) and its head revision.

- `close FILE`

    Does: Mark the review closed: set both `review.state` and the registry
    `state`.

    Prints: Nothing.

- `published FILE ID`

    Does: Mark feedback item ID as posted to the pull or merge request.

    Prints: Nothing.

- `list`

    Does: List the registered reviews of this repository.

    Prints: One per line: id, state, path, separated by tabs.

- `prune [--dry-run]`

    Does: Remove the pins of closed reviews and of reviews whose file is
    gone. `--dry-run` only prints them.

    Prints: The pins removed, one per line, as the VCS names them (git: the
    ref).

- `serve FILE`, and `FILE` alone (any first argument that is not a command)

    Does: Serve the review page and the HTTP API ([API.md](API.md)) for
    `FILE` until stopped.

    Prints: The page's URL, as its first line.

- `skills path`

    Does: Find the agent skills this implementation ships, one directory
    per skill.

    Prints: Their directory.

- `version`

    Prints: `standard <N>`, the version of the standard implemented, then
    `implementation <name> <version>`, where `<name>` is the
    implementation's distribution or product name (`Review-Helper` for the
    Perl one), not its `<impl>`, and `<version>` is that distribution's
    version; neither has spaces.

## Optional options with standard names

An implementation need not provide these. One that offers the behavior uses
these names and meanings.

- `serve`:
    - `--port N` listens on port N (default: any free port);
    - `--port-command CMD` runs CMD (split on spaces, no shell) and listens
      on the port number it prints; `REVIEW_HELPER_PORT_COMMAND` sets it
      every time;
    - `--listen ADDR` listens on another address, which needs the token of
      the local access layer ([API.md](API.md), "The local access layer");
      `REVIEW_HELPER_LISTEN` sets it every time;
    - `--allow-host NAME` (repeatable) accepts another host name for this
      machine; `REVIEW_HELPER_ALLOW_HOSTS` (comma-separated) sets them every
      time;
    - `--open` opens a browser on the page;
    - `--reviewer NAME` names who is reviewing.
- `REVIEW_HELPER_REVIEWER` names who is reviewing, when `--reviewer` does
  not. An implementation that uses the local access layer must honor it
  ([API.md](API.md), "The local access layer").

## Extensions

An implementation may add commands and options of its own. The standard
never defines a command or option starting `x-<impl>-`, where `<impl>` is
the implementation's name; one added under any other name may collide with
one a later version of the standard defines. Likewise the standard never
defines an environment variable starting `REVIEW_HELPER_X_<IMPL>_` (`<impl>`
in upper case, `-` as `_`), so an implementation's own variables go there.
