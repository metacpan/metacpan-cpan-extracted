# Catalog scan and source entries

- A catalog item may carry `dir`, its place in the source: a skill via a nested
  `plugin.json` path, or any item from the source's `.claude/{skills,agents,rules}`
  (read last, so a name already found wins; best effort — a symlink there skips that
  directory or item, never the scan; skilletor's own installed copies are not offered).
  `render` (`installPath`) maps its files to `skills/<name>/…`, `agents/<file>` or
  `rules/<file>`, so targets never see the source layout.
- A source entry's `path` replaces that scan: `scan(dir, paths)` offers only the skills
  beneath those paths (`dir` set) — no layout dirs, `plugin.json`, `.claude/` or bundles;
  the root `skilletor.json` is still read. Every `scan` call passes `backend.path`. The
  walk down passes over symlinks and non-skill dot-directories; a name found in two
  directories is that item's `error`, never a failed scan. `path` is no identity: it keys
  no cache and binds no trust, and `check` sees a changed one through `sources-read.json`.
- A source entry without `git`/`url`/`local` only overrides `ref` or `path` of a source
  another file defines: one file's entries may lack a backend, `loadConfig`'s merged
  sources never do; `sourceFields` demands one everywhere but config load (`needsBackend`).
