# Template::Sluz — Agent Guide

## Build & test
```sh
perl Makefile.PL
make
make test
```
No CPAN runtime prereqs; only `Test::More` for testing. Perl 5.16+ (CI matrix: 5.16, 5.26, 5.36, latest, plus Windows).
Run one test file: `make test TEST_FILES=t/10-delimiters.t`

## Key facts
- Single-file CPAN-style module: `lib/Template/Sluz.pm` (~2830 lines)
- Smarty-like `{...}` template syntax: `{$var}`, `{if}`, `{foreach}`, `{include}`, modifiers via `|`, comments `{* *}`
- `our $VERSION = 'v0.9.7'` at `lib/Template/Sluz.pm:29` (v-string with `v` prefix — keep the prefix when bumping; `VERSION_FROM` in `Makefile.PL` reads it)

## Test structure
- 14 test files `t/01-main.t` … `t/14-compiled.t`; `t/11-errors.t` exercises every `_error_out` code path, `t/14-compiled.t` checks the compiled foreach renderer against the interpreter
- Shared setup in `t/test_setup.pl`: helpers `setup_sluz()`, `sluz_test()`, `sluz_fetch_test()`
- Every test does `require "$FindBin::Bin/test_setup.pl"` at the top; `setup_sluz()` sets `$sluz->{perl_file_dir}` for template-file resolution
- `sluz_test()` accepts a regex string wrapped in `/pattern/` as expected output; `sluz_fetch_test()` takes `[child, parent]` + regex
- Test helper functions (`truncate`, `join_comma`, `hello_world`, `return_false`, `return_null`) are injected into `main::` via a `BEGIN` block so templates can call them
- Fixtures in `t/tpls/` (`child.stpl`, `parent.stpl`, `extra.stpl`, `nested_inc.stpl`, `var_scope.stpl`); runnable examples in root `tpls/` and `docs/` (the latter use `fetch()` with `__DATA__` inline templates)

## Architecture
- `fetch(file, [parent])` — main entry; aliased as `parse()` and `display()` (the latter prints). Defaults to inline template (`SLUZ_INLINE`) if no args
- `parse_string(string)` — parse a string directly (no file); primary test entrypoint
- Tokenizer: `_get_blocks` (line 516, list-returning, tested directly by `t/07-get_blocks.t`) is wrapped by cached `_get_blocks_ref` — parse path uses the cached version, so edits to `_get_blocks` results need cache-awareness (`_blocks_cache`)
- `set_delimiters($open, $close)` — switch delimiters off the default `{` `}` (one char each, must differ); affects later calls
- `parent_tpl(path)` / passing `child_file, parent_file` to `fetch()` — template inheritance; parent reads the child via `{$__CHILD_TPL}`
- `auto_escape => 1` on `new()` HTML-escapes all `{$var}`; use `|noescape` to emit raw, `|escape` explicitly (wins over auto to avoid double-escaping)
- Modifiers resolve: `main::` → `Template::Sluz` built-ins → `CORE::`; the template var is passed as first arg
- Expression blocks `{func()}` compile in `main::` first (where user functions live), then fall back to `Template::Sluz`
- In `{foreach}`: `$__FOREACH_FIRST`, `$__FOREACH_LAST`, `$__FOREACH_INDEX` are set; handles ARRAY and HASH refs (hash keys iterated in sorted order)
- `{foreach}` bodies are **compiled**: `_foreach_plan()` caches a plan per (loop vars, payload) and `_compile_foreach()` generates a Perl sub for the loop body (text and plain variables inlined; `{if}` blocks inlined when the condition avoids eval). `_foreach_render()` is the interpreter fallback used if the generated source fails to compile — keep the two paths semantically identical
- All errors go through `_error_out()` → central `croak` with numeric codes (`#18933`, `#45821`, `#73467`, etc.); codes must be unique

## Performance / benchmarking
Changes to `lib/Template/Sluz.pm` can regress parse speed — verify with `bench.pl` before and after:
```sh
perl bench.pl                 # all templates, 15000 iters each
perl bench.pl -n 20000        # more iterations for stable numbers
perl bench.pl --filter foreach  # run only matching benchmarks
```
`bench.pl` adds `$FindBin::Bin/lib` to `@INC` so it always measures the working copy and never a stale installed module.

## Code conventions
- `use constant SLUZ_INLINE => 'INLINE_TEMPLATE'` signals inline-template loading
- `use autouse 'Carp' => qw(croak)` — no explicit `use Carp`; `croak` reports errors with numeric codes
- Private methods are underscore-prefixed
- Modifier dispatch uses a localized `no strict 'refs'` block — don't tighten strictness around it
- Template vars are stored in `tpl_vars` and compiled to an internal `$__S` hash under a `sluz_pfx_` prefix — don't rename `var_prefix` or the `sluz_pfx_` keys without updating `_peval` and `_do_foreach`
