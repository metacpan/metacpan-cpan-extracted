# Overview

`Mojolicious::Plugin::WebComponent` is a CPAN distribution (version 0.07,
`lib/Mojolicious/Plugin/WebComponent.pm:8`) that adds server-side templating to
custom web component scripts in a Mojolicious app.

## What it does

1. A template calls the `component` helper, which emits a
   `<script src='/component/<checksum>/<name>.js?<params>'></script>` tag.
   `<checksum>` is the SHA-1 of the script the URL serves (script with its
   template injected), or the `requestId` option when given.
2. The browser requests that URL. The plugin's route serves the component's
   JavaScript file from the app's static assets, with
   `Cache-Control: public, max-age=31536000, immutable` when the checksum in the
   URL matches the content, and `no-cache` otherwise.
3. While serving, the plugin renders the matching Mojolicious template
   (`templates/components/<name>.html.ep`) and splices it into the script as a
   `let tmpl = document.createElement('template'); tmpl.innerHTML = "<json string>"`
   block, at the script's `let tmpl;` line or just before its
   `shadowRoot.appendChild(tmpl.content.cloneNode(true))` line.

Request parameters and route captures of the original page request travel on
the script URL, sorted by name, and reach the template as the `$params` hash.

## Parts

| Part | Path |
|------|------|
| Plugin (route, helper, injection, checksum) | `lib/Mojolicious/Plugin/WebComponent.pm` |
| Tests and fixtures | `t/` |
| Browser harness (podman, Chromium) | `t/browser/`, `t/browser.t` |
| Packaging (Minilla, Module::Build::Tiny) | `minil.toml`, `Build.PL`, `META.json`, `cpanfile` |
| CI | `.github/workflows/test.yml` |
| Release notes | `Changes` |
| Decision records | `docs/adr/` |

The distribution is one Perl module. Its documentation is the POD after
`__END__` in the same file; `README.md` is the generated copy.

## Deployment

A library installed from CPAN (`requires 'Mojolicious', '9.27'` and
`requires 'perl', '5.020'` in `cpanfile`). It has no service of its own.
Reverse-proxy installs are supported by prefixing the generated script path
with the request's base path (`WebComponent.pm:158-162`, Changes 0.07).
