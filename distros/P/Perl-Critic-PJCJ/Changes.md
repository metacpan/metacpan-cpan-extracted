# Revision history for Perl::Critic::PJCJ

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
