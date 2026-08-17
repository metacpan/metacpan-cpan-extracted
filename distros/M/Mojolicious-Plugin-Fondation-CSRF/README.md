# NAME

Mojolicious::Plugin::Fondation::CSRF - CSRF protection plugin for Fondation — route condition, OpenAPI integration, JS injection

# VERSION

version 0.01

# SYNOPSIS

    # In myapp.conf
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::SessionStore',     # sessions required for CSRF tokens
            'Fondation::CSRF',
        ],
    };

    # Per-route opt-in (when auto_protect is disabled):
    $r->post('/secure-action')->requires('fondation.csrf')->to('mycontroller#action');

    # With exemptions:
    'Fondation::CSRF' => {
        auto_protect => 1,
        exemptions   => [qr{^/webhook/}, qr{^/api/public/}],
    },

# DESCRIPTION

`Mojolicious::Plugin::Fondation::CSRF` provides Cross-Site Request Forgery
protection for Fondation applications. It uses Mojolicious' built-in CSRF
token mechanism (stored in session, validated via ["csrf\_protect" in Validation](https://metacpan.org/pod/Validation#csrf_protect)).

Three protection layers, all using the same underlying Mojo validation:

- 1. Route condition `fondation.csrf` — explicit opt-in on any route
- 2. OpenAPI auto-protection — POST/PUT/PATCH/DELETE routes generated
by [Fondation::OpenAPI](https://metacpan.org/pod/Fondation%3A%3AOpenAPI) automatically get `requires('fondation.csrf')`
- 3. `around_dispatch` blanket protection — all mutating requests
(POST/PUT/PATCH/DELETE) are checked unless the path matches an exemption

Token transmission works two ways, both handled automatically by Mojo:

- Form field `csrf_token` — standard HTML forms via ["csrf\_field" in TagHelpers](https://metacpan.org/pod/TagHelpers#csrf_field)
- Header `X-CSRF-Token` — AJAX requests (the plugin provides a JS zone
that reads the CSRF meta tag and patches `fetch` and `XMLHttpRequest`)

# CONFIGURATION

- auto\_protect

    Enable/disable the `around_dispatch` blanket protection.
    Default: `1` (enabled). Set to `0` to use only explicit route conditions.

- exemptions

    Arrayref of regex patterns. Paths matching any pattern are skipped by
    `around_dispatch`. Useful for webhooks, public API endpoints, etc.
    Default: `[]` (no exemptions).

# DEPENDENCIES

[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation).

Sessions must be enabled ([Fondation::SessionStore](https://metacpan.org/pod/Fondation%3A%3ASessionStore) or Mojolicious' default
signed cookies). The CSRF token lives in `$c->session->{csrf_token}`.

# STATIC JS FILE

The plugin ships `share/public/js/csrf.js` — a standalone script that
reads the CSRF token from `<meta name="csrf-token">` and auto-injects
it as `X-CSRF-Token` header on all `fetch` and `XMLHttpRequest`
POST/PUT/PATCH/DELETE calls.

Add it to your assetpack.def:

    < js/csrf.js

Or include it directly in your layout:

    <script src="/js/csrf.js"></script>

The meta tag must be present in the page. [Fondation::Layout-Bootstrap](https://metacpan.org/pod/Fondation%3A%3ALayout-Bootstrap)
provides it by default:

    <meta name="csrf-token" content="<%= csrf_token %>">

# END-TO-END FLOW

When the CSRF plugin is loaded alongside the standard Fondation stack
(Layout-Bootstrap, Asset, OpenAPI, Auth), protection works automatically:

- 1. Layout-Bootstrap injects `<meta name="csrf-token">` in `<head>`.
- 2. `csrf.js` (loaded via AssetPack bundle or `<script src>`) patches
`fetch` and `XMLHttpRequest` to inject `X-CSRF-Token` on all mutating AJAX calls.
- 3. HTML forms (login, etc.) include `<%= csrf_field %>` to embed
the token as a hidden field.
- 4. OpenAPI routes (POST/PUT/PATCH/DELETE) automatically get
`requires('fondation.csrf')` via the `openapi_routes_added` hook.
- 5. HTML POST routes are protected by `around_dispatch` when
`auto_protect` is enabled (default), or by explicit `requires('fondation.csrf')`.
- 6. Mojo's `csrf_protect` validates the token from form field or
`X-CSRF-Token` header against the session token.

# HOW TOKEN VALIDATION WORKS

The route condition and `around_dispatch` both delegate to Mojo's
`csrf_protect` validation:

- 1. Mojo generates a unique token on first session access
- 2. Token is stored in `$c->session->{csrf_token}`
- 3. Client sends the token back (form field or `X-CSRF-Token` header)
- 4. `csrf_protect` compares the submitted token with the session token
- 5. Mismatch → validation error `csrf_token` → 403

# SEE ALSO

[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation),
[Mojolicious::Plugin::Fondation::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AOpenAPI),
[Mojolicious::Guides::Routing](https://metacpan.org/pod/Mojolicious%3A%3AGuides%3A%3ARouting),
[Mojolicious::Validator::Validation](https://metacpan.org/pod/Mojolicious%3A%3AValidator%3A%3AValidation)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
