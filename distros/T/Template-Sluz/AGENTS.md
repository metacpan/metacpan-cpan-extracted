# Template::Sluz — Agent Guide

## Build & test
```sh
perl Makefile.PL
make
make test
```
No CPAN prereqs at runtime; only `Test::More` for testing. Perl 5.16+.

## Key facts
- Single-file CPAN-style Perl module: `lib/Template/Sluz.pm` (~1510 lines)
- Smarty-like `{...}` template syntax; `{$var}`, `{if}`, `{foreach}`, `{include}`, modifiers via `|`, comments `{* *}`
- Version: `v0.9.3` (at `Sluz.pm:27`)

## Test structure
- 9 test files: `t/01-main.t` through `t/09-autoescape.t`
- Shared setup in `t/test_setup.pl` — `setup_sluz()`, `sluz_test()`, `sluz_fetch_test()` helpers
- All tests `require "$FindBin::Bin/test_setup.pl"` at top
- `setup_sluz()` sets `$sluz->{perl_file_dir}` (line 68) — required for template file resolution
- Test helper functions injected into `main::` via `BEGIN` block (test_setup.pl:14-21)
- Template fixtures in `t/tpls/` (`child.stpl`, `parent.stpl`, `extra.stpl`, `nested_inc.stpl`, `var_scope.stpl`); examples in `tpls/`

## Architecture notes
- `fetch(file, [parent])` — main entry; also aliased as `parse()` and `display()` (prints output)
- `parse_string(string)` — parse a template string directly
- `parent_tpl(path)` — set parent template for inheritance
- Template inheritance: pass `child_file, parent_file` to `fetch()`, or set `parent_tpl()` beforehand
- Modifiers resolve functions in this priority: `main::` → `CORE::` → `Template::Sluz` (built-in module functions like `count`)
- Expression blocks `{func()}` first try `Template::Sluz` then fall back to `main::` package
- `$__FOREACH_FIRST`, `$__FOREACH_LAST`, `$__FOREACH_INDEX` available in foreach loops
- `$__CHILD_TPL` variable available in parent templates for inheritance
- `{foreach}` handles both ARRAY and HASH refs; hash iteration uses sorted key order

## Code conventions
- Uses `use constant SLUZ_INLINE => 'INLINE_TEMPLATE'` for inline template loading
- Uses `use autouse 'Carp' => qw(croak)` — no explicit `use Carp`
- Private methods prefixed with `_` (underscore)
- `croak` for error reporting with numeric error codes
- `no strict 'refs'` used in a small block for modifier dispatch (Sluz.pm:695)
