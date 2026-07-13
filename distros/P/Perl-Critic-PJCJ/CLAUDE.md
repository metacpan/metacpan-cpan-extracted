# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Overview

Perl::Critic::PJCJ is a CPAN distribution providing Perl::Critic policies for
code style consistency. Built with Dist::Zilla.

## Skills

Always use the `development` and `perl` skills when working on this codebase.

## Development Commands

Run these after every change:

- **Format**: `make format` (runs perlimports + perltidy; always run before
  other formatting)
- **Test**: `make test` (dzil clean + dzil test)
- **Lint**: `make lint` (pre-commit run --all-files, includes perlcritic)
- **Coverage**: `make cover-compilation` (statement/branch/condition report)

Quick test during development (no clean/rebuild): `make t`

Single test file: `yath test -j20 --qvf -T t/path/to/test.t`

## Architecture

### Policies

- `lib/Perl/Critic/Policy/ValuesAndExpressions/RequireConsistentQuoting.pm` -
  the main policy. Enforces three rules: (1) reduce punctuation, (2) prefer
  interpolated strings, (3) use bracket delimiters in preference order. Handles
  six PPI token types via a dispatch table in `violates()`, routing to
  `check_single_quoted`, `check_double_quoted`, `check_q_literal`,
  `check_qq_interpolate`, `check_quote_operators`, and `check_use_statement`.
- `lib/Perl/Critic/Policy/CodeLayout/ProhibitLongLines.pm` - configurable
  maximum line length enforcement. Supports per-file overrides via
  `.gitattributes` (attribute `custom-line-length`; value `ignore` or an
  integer).
- `lib/Perl/Critic/Utils/SourceLocation.pm` - helper for ProhibitLongLines to
  create synthetic PPI elements with line/column info for violations.

### Key internal methods in RequireConsistentQuoting

- `would_interpolate($string)` - uses PPI to check if content would interpolate
  in double quotes.
- `has_quote_sensitive_escapes($string)` - regex check for escape sequences
  (`\n`, `\t`, `\x1b`, `\N{...}`, etc.) that differ between `''` and `""`.
- `find_optimal_delimiter($content, $op, $start, $end)` - determines best
  bracket delimiter (`()` > `[]` > `<>` > `{}`), accounting for unbalanced
  content.
- `parse_quote_token($elem)` - extracts operator, delimiters, and content from
  any quote-like token.

### Test framework

Tests use `Test2::V0` and a shared helper `t/lib/ViolationFinder.pm` which
exports:

- `good $policy, $code, $desc` - assert no violations.
- `bad $policy, $code, $expected_msg, $desc` - assert exactly one violation
  whose `description` matches `$expected_msg` via `like`.
- `find_violations` / `count_violations` - lower-level helpers.

Tests are organised by concern under
`t/ValuesAndExpressions/RequireConsistentQuoting/`: `single_quotes.t`,
`double_quotes.t`, `escape_sequences.t`, `quote_operators.t`,
`delimiter_optimisation.t`, `use_statement_quote_types.t`, `newlines.t`,
`messages.t`, etc.

### Violation messages

RequireConsistentQuoting puts the per-violation suggestion (e.g. `use ''`,
`use ""`, `use qq()`, `use qw()`) in the `description` field, which is what `%m`
formats show. The `explanation` is a single static rationale. Tests check
`description`; there is no policy-class special case in the test helper.

Each violation is a `Perl::Critic::PJCJ::Violation` that carries its structured
fix (`->fix`). The Fixer reads that attached fix directly and only falls back to
`fix_data($description)` for test doubles; a violation with no fix mapping
warns. The suggestion wording lives in one place: the exported constant subs
`desc_double`, `desc_single`, `desc_use_qw`, `desc_remove_parens` and
`desc_optimal($display)`, which tests import rather than duplicating literals.

## Style Notes

- Perl 5.26+ with `use feature qw( signatures )` and
  `use experimental qw( signatures )`.
- Formatting is controlled by `.perltidyrc`; imports by `perlimports`. Do not
  manually reformat - run `make format`.
- Perlcritic configuration is in `.perlcriticrc` (severity 2).
- Each `.pm` file ends with a quoted string (song lyric) instead of `1;`. The
  `Modules::RequireEndWithOne` policy is disabled.
