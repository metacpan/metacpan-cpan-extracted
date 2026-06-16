# Template::Sluz — Agent Guide

## Build & test
```sh
perl Makefile.PL
make
make test
```

## Key facts
- Single-file CPAN-style Perl module: `lib/Template/Sluz.pm` (1118 lines, zero deps)
- Smarty-like `{...}` template syntax; `{$var}`, `{if}`, `{foreach}`, `{include}`, modifiers via `|`, comments `{* *}`
- Requires Perl 5.16+; no CPAN prereqs at runtime (only `Test::More` for testing)
- Module version in `$VERSION` at `Sluz.pm:27`

## Testing quirks
- Single test file `t/01-main.t` (462 lines, uses `Test::More`)
- Test helper functions injected into `main` namespace via `BEGIN` block (line 16-23)
- Test sets `$sluz->{perl_file_dir}` manually (line 55) — needed for template file resolution
- Template files live in `t/tpls/` (test fixtures: `child.stpl`, `parent.stpl`, `extra.stpl`, `nested_inc.stpl`, `var_scope.stpl`) and `tpls/` (examples)
- Several tests wrapped in `local $TODO = "..."` blocks — features not yet implemented (PHP bracket syntax `{$array[1]}`, negated hash lookup `{if !$cust.age}`, `join_comma` numeric param)
- `sluz_test()` and `sluz_fetch_test()` are custom test helpers; check their definitions before adding new tests

- `{foreach}` now handles both ARRAY and HASH refs; hash iteration uses sorted key order (deterministic)

## Architecture notes
- `fetch(file, [parent])` — main entry point; also aliased as `parse()` and `display()` (prints output)
- `parse_string(string)` — parse a template string directly
- `parent_tpl(path)` — set parent template for inheritance
- Template inheritance: pass `child_file, parent_file` to `fetch()`, or set `parent_tpl()` beforehand
- Modifiers resolve functions in this priority: `main::` → `CORE::` → `Template::Sluz` (built-in module functions like `count`)
- Expression blocks `{func()}` first try `Template::Sluz` then fall back to `main::` package
- `$__FOREACH_FIRST`, `$__FOREACH_LAST`, `$__FOREACH_INDEX` available in foreach loops
- `$__CHILD_TPL` variable available in parent templates for inheritance

## Code conventions
- Uses `use constant SLUZ_INLINE => 'INLINE_TEMPLATE'` for inline template loading
- Private methods prefixed with `_` (underscore)
- `croak` for error reporting with numeric error codes
- No strict refs used in modifier dispatch (`no strict 'refs'` in a small block)
