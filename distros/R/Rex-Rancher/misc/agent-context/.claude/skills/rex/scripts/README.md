# Offline utilities

## Static Rexfile review

`python3 scripts/audit_rexfile.py path/to/Rexfile --json`

Reads explicit UTF-8 files (maximum 2 MiB each), emits fixed diagnostic messages and
line numbers, and never executes Perl or includes source snippets in output.
`-` reads stdin. Exit 0 means no finding at the selected threshold; exit 1 means
findings at/above `--fail-on`; exit 2 means an input error. Thresholds are `error`
(default), `warning`, `info`, or `never`. These labels are review priorities, not
proof of exploitability or Perl syntax errors.

Nine rules cover disabled host-key checking, shell-program execution, status shifts,
moving latest state, task/DSL name collisions, questionable selective-import syntax,
filesystem-using creates guards, forced LibSSH Fs dispatch, and literal credentials.
It skips full-line comments and POD only. It can misread strings, heredocs, inline
comments and multiline code, and misses aliases and generated code. It does not
perform taint analysis, resolve imports, or prove that actions occur inside tasks.
There are no auto-fixes or suppression directives.

## Text-only module inventory

`perl scripts/inspect_rex.pl [--lib trusted-library-directory]`

Searches literal directory entries from `@INC` plus explicit `--lib` directories.
Does not invoke coderef search hooks, require Rex, or evaluate module VERSION code.
Reports first candidate files, literal version text where recognized, and SHA256.
A text match is not an effective runtime version; comments or computed assignments
can make it incomplete or misleading. Compare a trusted runtime's loaded paths
separately. Native libssh/libssh2/client versions are not inferred from these files.

## Package validation

`python3 scripts/validate_package.py .`

Verifies required files/frontmatter, UTF-8/JSON readability, local Markdown file-link
targets, safe paths, no symlinks, exact manifest membership, and SHA256 digests.
Remote URL availability, renderer-specific anchor fragments, Perl examples, semantic
API correctness, publisher authenticity, and infrastructure behavior are not checked.
The manifest excludes only itself; do not put generated caches/logs in the installed
folder. The tests disable Python bytecode writes to preserve package integrity.
