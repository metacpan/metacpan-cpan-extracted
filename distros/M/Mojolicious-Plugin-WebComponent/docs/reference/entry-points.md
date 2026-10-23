# Entry points

| Entry point | Kind | Path | Notes |
|-------------|------|------|-------|
| `plugin WebComponent => {...}` / `$app->plugin(WebComponent, {...})` | Public API (`register`) | `lib/Mojolicious/Plugin/WebComponent.pm:23` | Config keys read: `path`, `javascript_path`, `template_path`, `helper` |
| `component` helper | Template helper | `WebComponent.pm:36` | `component $name, \%opts`; option `template` (name, or `undef` to skip templating); option `requestId` (replaces the checksum in the URL, percent-encoded as UTF-8; may not contain `/`; the script is then served `no-cache`) |
| `component` with no args | Helper | `WebComponent.pm:36` | Returns the plugin instance |
| `GET`/`HEAD <path>/:checksum/*component` | HTTP route `webcomponent` | `WebComponent.pm:15-19`, handler `_serve` at `:45` | Default `<path>` is `/component`; created in `register` and placed first among the app's routes |

## Config keys

| Key | Default | Read at |
|-----|---------|---------|
| `path` | `/component` | `WebComponent.pm:17` |
| `javascript_path` | `components` (under `<static asset_dir>/js/`) | `WebComponent.pm:74` |
| `template_path` | `components` (under the app templates) | `WebComponent.pm:118` |
| `helper` | `component`; must match `\A\w+\z` or `register` croaks | `WebComponent.pm:27-28` |

## Responses of the script route

| Case | Status | `Cache-Control` | Where |
|------|--------|-----------------|-------|
| Name not matching `$COMPONENT_NAME`, or script file absent | 404 | not set | `WebComponent.pm:51`, `:54` |
| `:checksum` equals the checksum of the content | 200 | `public, max-age=31536000, immutable` | `:58-59` |
| Any other `:checksum` (stale page, `requestId`) | 200 | `no-cache` | `:58-59` |
| Script is not valid UTF-8, or the template dies | 500 | not set | `:81` |

Content type is `application/javascript; charset=UTF-8` (`:62`).

## Parameters on the script URL

`_templateScript` reads `template` from the merged params (`:117`, `:121-126`).
A value that is exactly `false`, `f`, `no` or `0` (any case) skips templating;
any other value names the template; a name outside `$TEMPLATE_NAME` gives the
"template not found" div. `_component` writes `template=false` into the params
when the helper option is `undef` (`:167-170`).
