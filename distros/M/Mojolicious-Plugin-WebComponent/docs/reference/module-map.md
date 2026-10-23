# Module map

| Module | Path | Responsibility | Depends on | Used by |
|--------|------|----------------|------------|---------|
| Plugin class | `lib/Mojolicious/Plugin/WebComponent.pm` | `register` creates the script route and installs the helper; `_serve` answers script requests; `_content` builds the script; `_component` builds the script tag | Mojolicious (`Mojo::Base`, `Mojo::Parameters`, `Mojo::ByteStream`, `Mojo::JSON`, `Mojo::Util`, renderer, static), Carp | Host Mojolicious apps; `t/` |
| Unit and integration tests | `t/register.t`, `t/script-route.t`, `t/00_compile.t`, `t/pod*.t` | See `test-landscape.md` | the plugin | `prove -lr t` |
| Test fixtures | `t/files/`, `t/templates/` | Component scripts, templates, a page and a layout | the plugin | `t/register.t`, `t/script-route.t` |
| Browser harness | `t/browser/`, `t/browser.t` | Plugin under `prefork -w 2` plus Chromium in a podman pod | the plugin, podman, Playwright | `t/browser.t` (opt-in) |
| CI workflow | `.github/workflows/test.yml` | Runs `prove -lr t` on Perl 5.20 to 5.40 | cpanm, `cpanfile` | GitHub push and pull request events |
| Packaging | `minil.toml`, `Build.PL`, `META.json`, `cpanfile` | Minilla release config (`ModuleBuildTiny`), generated build script and metadata, dependency list | Minilla | CPAN release |
| Decision records | `docs/adr/0001-component-url-carries-a-content-checksum.md` | Why the URL carries a content checksum | none | readers |

## Plugin internals (`WebComponent.pm`)

| Symbol | Line | Kind | Role |
|--------|------|------|------|
| `$COMPONENT_NAME`, `$TEMPLATE_NAME` | 12-13 | allowlist regexes | A component is `(<segment>/)*<segment>.js`; a segment may not start with a dot |
| `route` | 15 | attribute (lazy) | `any([HEAD GET] => "<path>/:checksum/*component")`, named `webcomponent`, handled by `_serve`; `<path>` is `config->{path}` or `/component` |
| `app`, `config` | 20-21 | attributes | Set in `register` |
| `register` | 23 | method | Stores app and config; returns early if the helper is already registered; sets stash default `webcomponent.helper`; adds the helper (name `config->{helper}` or `component`); builds the route and moves it to the front of `routes->children` |
| `_serve` | 45 | route callback | Validates the name, builds the content, compares `:checksum` with the content's checksum, sets `Cache-Control` and the content type, renders as text |
| `_checksum` | 66 | method | `sha1_sum` of the UTF-8 encoded content |
| `_content` | 71 | method | Reads the script, injects the template block; undef when the script is absent; dies on invalid UTF-8 |
| `_templateExists` | 106 | method | Looks for an html template by file or `__DATA__` section across all registered handlers |
| `_templateScript` | 116 | method | The `let tmpl` block, or undef when `template` is `false`, `f`, `no` or `0` |
| `_component` | 151 | helper body | Validates the name, escapes the base path, computes the checksum (or takes `requestId`), returns the script tag as `Mojo::ByteStream` |
| `_getAllParams` | 194 | method | Request params plus `mojo.captures` without `cb`, `checksum`, `component`, sorted by name, as `Mojo::Parameters` |

The `component` helper with no arguments returns the plugin object itself
(`WebComponent.pm:36`); with arguments it calls `_component`.
