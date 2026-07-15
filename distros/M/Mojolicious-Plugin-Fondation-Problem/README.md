# NAME

Mojolicious::Plugin::Fondation::Problem - Unified API (RFC 9457) and HTML error responses for Fondation

# VERSION

version 0.01

# SYNOPSIS

    # In myapp.conf
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Problem',
        ],
    };

    # In a controller
    $c->problem(
        status => 422,
        title  => 'Validation failed',
        detail => 'Field "name" is too long (60 > 50)',
        type   => '/problem/validation',
        errors => [
            { detail => 'String too long', pointer => '/name' },
        ],
    );

# DESCRIPTION

`Fondation::Problem` provides a unified error response mechanism
via the `$c->problem()` helper.

For API requests (routes with `openapi.path` in the match stack),
it returns an RFC 9457 `application/problem+json` response.

For browser (HTML) requests, it renders the `problem` template
using the current layout.

In development mode, all fields are returned (`type`, `detail`,
`errors`, `instance`). In production mode, only `status` and
`title` are sent — no internal information is leaked.

# NAME

Mojolicious::Plugin::Fondation::Problem - Unified API (RFC 9457) and HTML error responses for Fondation

# VERSION

version 0.01

# HELPERS

## problem

    $c->problem(
        status   => 422,
        title    => 'Validation failed',
        detail   => 'Field "name" is too long',
        type     => '/problem/validation',
        errors   => [{ detail => '...', pointer => '/name' }],
        instance => '/logs/abc-123',
    );

All arguments are optional. Defaults: `status` = 500, `title` = 'Internal Server Error'.

In production mode, only `status` and `title` are included in the response.
`detail`, `type`, `errors`, and `instance` are suppressed.

# TEMPLATES

## problem.html.ep

Rendered for HTML error responses. Receives stash values:

- `problem_status` — HTTP status code
- `problem_title` — Human-readable error title
- `problem_detail` — Detailed message (only in development mode)

Uses `% layout 'main'` — if `Fondation::Layout::Bootstrap` is loaded,
its Bootstrap layout applies. Without any layout plugin, Mojo renders
the template content directly (no HTML wrapper) — the page remains
functional. A future Fondation core release may provide a minimal
HTML5 layout as a dedicated plugin loaded after Bootstrap.

# RFC 9457 RESPONSE FORMAT

    Content-Type: application/problem+json

    {
      "status": 422,
      "title": "Validation failed",
      "detail": "Field \"name\" is too long (60 > 50)",
      "type": "/problem/validation",
      "errors": [
        { "detail": "String too long", "pointer": "/name" }
      ]
    }

# MODE-AWARE BEHAVIOR

The plugin distinguishes between development and production modes:

    Development  → all fields (type, detail, errors, instance)
    Production   → only status + title

This follows the RFC 9457 principle that `title` is constant per
problem type (always safe to show) while `detail` and `errors`
may reveal internal structure.

# API DETECTION

API requests are detected using three criteria (any one match is sufficient):

- 1. `openapi.path` in the match stack — set by [Mojolicious::Plugin::Fondation::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AOpenAPI)
- 2. URL path starts with `/api/` — custom API routes outside OpenAPI
- 3. `Accept` header contains `application/json` but not `text/html`

Requests matching any of these criteria receive an RFC 9457
`application/problem+json` response. All other requests receive
an HTML error page.

# DEPENDENCIES

[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation)

# SEE ALSO

[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation),
[RFC 9457](https://www.rfc-editor.org/rfc/rfc9457.html),
[Mojolicious::Plugin::Fondation::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AOpenAPI)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
