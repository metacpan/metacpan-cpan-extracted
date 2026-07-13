# Revision history for Perl::Critic::PJCJ

## v0.3.0 - 2026-07-13

- Add perl-quote-fix, a stdin to stdout filter fixing RequireConsistentQuoting
  violations
  - Fixes are decided by the policy itself, preserve the runtime value of every
    string, and repeat until the source is clean
  - `--lines START-END` restricts fixes to a line range for editor integrations
  - `--inplace` fixes many named files in a single process
  - Perl::Critic::PJCJ::Fixer provides the same rewriting as a module
- Batch file processing in `make format` and the tidy hook so each tool starts
  once rather than once per file, cutting runtime substantially

## v0.2.7 - 2026-06-25

- Count ProhibitLongLines line length in characters, not octets
  - Lines with multi-byte UTF-8 characters are no longer wrongly flagged as too
    long
  - Single-byte source (ASCII, Latin-1) is unaffected; other multi-byte
    encodings are not decoded and still count by octets

## v0.2.6 - 2026-04-11

- Suggest single quotes for qq/q strings containing only double quotes
  - `qq("hello")` and `q("hello")` now correctly suggest `'` instead of keeping
    the quote operator
- Clean and optimise code

## v0.2.5 - 2026-03-22

- Fix false violation for escaped backslashes in double-quoted strings
  - Strings like `"\\"` no longer incorrectly suggest `use ''`

## v0.2.4 - 2026-02-23

- Add per-file line length overrides via `.gitattributes` for ProhibitLongLines
  - New `gitattributes_line_length` parameter (default: `custom-line-length`)
  - Set attribute to `ignore` to skip a file, or an integer to override the
    limit
  - Falls back to the configured default when git is unavailable or attribute is
    unspecified

## v0.2.3 - 2026-02-22

- Allow quoted strings for single-argument pragmas in use/no statements
  - Pragmas (all-lowercase module names) with a single argument now accept
    quoted strings with normal quoting rules applied
  - Multi-argument pragmas and non-pragma modules are unchanged

## v0.2.2 - 2026-02-21

- Close release ticket automatically when PR is merged

## v0.2.1 - 2026-02-21

- Fix set -e exit in `detect_version` when verbose is off
- Skip git hooks during `dzil release` via `$ENV{DZIL_RELEASING}`
- Set release commit message to `Release vX.Y.Z`

## v0.2.0 - 2026-02-21

- Add `allow_lines_matching` parameter to ProhibitLongLines for exempting lines
  that match regex patterns (e.g. long package declarations, URLs)
- Add missing List::Util runtime prerequisite
- Remove dead code in RequireConsistentQuoting
- Unify release workflow with confirmation checkpoints (`make release`)
- Move setup recipe into `utils/run`; skip in CI environments
- Fix experimental signatures warning in `dev/append_postamble`
- Add Perl 5.42 to CI matrix

## v0.1.4 - 2025-08-31

- No changes from v0.1.3-TRIAL

## v0.1.3-TRIAL - 2025-08-31

- Enhance use/no statement handling in RequireConsistentQuoting policy:
  - Add interpolation detection
    - Statements requiring variable interpolation follow normal rules
  - Add support for `no` statements
  - Add fat comma (=>) detection
    - Statements with hash-style arguments have no parentheses
  - Add complex expression detection
    - Statements with variables, conditionals, etc. have no parentheses
    - Add version number exemption
- Improve single quote and q() handling

## v0.1.2 - 2025-07-26

- Initial release
- Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting policy
- Perl::Critic::Policy::CodeLayout::ProhibitLongLines policy
