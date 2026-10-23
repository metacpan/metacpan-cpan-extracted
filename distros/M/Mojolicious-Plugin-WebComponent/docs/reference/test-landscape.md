# Test landscape

Run all: `prove -lr t` (same command as `.github/workflows/test.yml`). Last
run for this map: 6 files, 196 tests passed on Perl 5.42 (Mojolicious 9.51 in
podman; the suite also passed on 9.27); the two author tests and the browser
test were skipped.

| Test | Path | Kind | Covers |
|------|------|------|--------|
| Compile | `t/00_compile.t` | Load check | `require_ok` of the plugin module |
| Register | `t/register.t` | Integration (`Test::Mojo`, Mojolicious::Lite app) | A page using `<my-component>` returns 200; `component('my-component', {requestId => 'test-id'})` returns the expected script tag; the script URL with that id returns 200 with the template injected |
| Script route | `t/script-route.t` | Integration (`Test::Mojo`, Mojolicious apps built per case) | Route exists on first request and is not shadowed by an earlier catch-all; path traversal and name allowlist; sub folders; template injected as one JSON string literal (checked with `node --check` when node is installed); template name allowlist and the `false/f/no/0` switch; UTF-8 in scripts and templates; helper URLs (no `cb`, no captures, option scoped to its call); invalid names die; `path`, `javascript_path`, `template_path`, `helper` config; `__DATA__` and non-`ep` handler templates; checksum URL stable across requests and app instances, changes with script, template or used parameter, parameters sorted; `Cache-Control` for a matching checksum (GET, HEAD), a wrong checksum, `requestId` and 404; a template that dies does not break the page; base path and `requestId` escaped in the tag, trailing slash dropped; duplicate registration with a custom helper name; invalid helper names refused; invalid UTF-8 script gives 500; a missing script is logged; injection before the `appendChild` line when there is no `let tmpl;`; the last of repeated `template` parameters wins; `.js` suffix optional; `template => undef` |
| Browser | `t/browser.t`, `t/browser/` | Opt-in (`WEBCOMPONENT_BROWSER_TEST=1`); podman pod with the app under `prefork -w 2` and Playwright 1.49 Chromium | 20 checks: script route answers from every worker before any page render; traversal refused; components define and render; template and script text round-trip (non-ASCII, backtick, backslash); `template => undef`; URL stable across page views; second view is a browser cache hit; `immutable` and `no-cache` headers; two XSS attempts do not run |
| POD syntax | `t/pod.t` | Author test | `all_pod_files_ok`; runs only with `RELEASE_TESTING` set (skips when the module is missing) |
| POD coverage | `t/pod-coverage.t` | Author test | `all_pod_coverage_ok`; same gating |

## Fixtures

| Path | Role |
|------|------|
| `t/files/assets/js/components/`, `t/files/assets/js/alt/` | Component scripts (`my-component`, `echo-box`, `tick-box`, `utf-box`, `sub/sub-box`, `alt-box`); `t/files/secret.js` is the traversal target |
| `t/templates/components/`, `t/templates/alt-tpl/` | Component templates, including `broken` (dies), `custom.html.up` (non-`ep` handler), `notes`, `footer`, `10-grid`, `sub/sub-box` |
| `t/templates/default/index.html.ep`, `t/templates/layouts/default_layout.html.ep` | Page using `<my-component>`; layout calling `component 'system-hosts'` |
| `t/browser/public/`, `t/browser/templates/`, `t/browser/app.pl` | Browser harness app, scripts and templates |

`t/register.t` rewrites the static root from `/public` to `/files`; the
`script-route.t` apps set `static->paths` and `renderer->paths` directly.

## Facts about coverage

- Devel::Cover on the unit suite (2026-10-22, before the last four tests were
  added): statements 98.6%, branches 93.7%, conditions 84.3%, subs 100%. The
  four uncovered behaviours it found are now tested.
- Not exercised by a test: a base path set from a real proxy header (the tests
  set it in a `before_dispatch` hook).
- The layout's `component 'system-hosts'` has no matching script or template
  under `t/`.
