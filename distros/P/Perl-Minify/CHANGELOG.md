# CHANGELOG

## 0.4.0

- First production release (even minor version).
- Rework POD and README to put `minify.pl` first as the primary interface, with the module API documented after it.
- README: document `minify.pl --sub NAME` and add installation instructions.
- Add Versioning rules to AGENTS.md.
- Add `escape_newlines` option (default on) that writes literal LF, TAB, and CR inside string literals as `\n`, `\t`, `\r`. Single-quoted and `q()` strings containing these characters are re-emitted as double-quoted strings. Strings with code inside interpolations are left alone.

## 0.03

- Add `shorten_vars` option to rename lexical variables to short names.
- Add `wrap` option to word-wrap output to a maximum column width (string/regex aware).
- Add `strip_semicolons` option (default on) to drop safe terminators before `}`.
- Add `keep_name` option (default on) to `minify_sub`; set to 0 for an anonymous `sub { }`.
- Add `minify_sub` to extract and minify a single named subroutine.
- Add `minify_error` accessor and `$Perl::Minify::ERROR` for error reporting.
- Add `optimize` option (EXPERIMENTAL) for constant folding of `Number +/-/* Number` chains.
- Add `minify.pl --sub NAME` to emit a single named subroutine.
- `minify.pl` reports parse errors to STDERR and exits 1.
- Treat `tr///` / `y///` transliteration as unsafe for wrapping.
- Integration: verify minified output compiles with `perl -c`.
