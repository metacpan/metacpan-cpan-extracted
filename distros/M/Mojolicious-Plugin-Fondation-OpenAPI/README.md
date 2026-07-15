# NAME

Mojolicious::Plugin::Fondation::OpenAPI - OpenAPI specification generator and runtime validator for Fondation applications

# VERSION

version 0.02

# SYNOPSIS

    # In myapp.conf
    'Fondation::OpenAPI' => {
        backend => 'main',
        schemas => {
            User => {
                columns => {
                    password => {
                        writeOnly => 1,
                        create    => { required => 1 },
                        update    => { required => 0 },
                    },
                },
            },
        },
    }

    # CLI
    $ myapp.pl openapi generate
    $ myapp.pl openapi generate -y
    $ myapp.pl openapi generate --output custom.json

# DESCRIPTION

This plugin provides the `openapi generate` command to produce an
OpenAPI 3.0.3 specification from DBIx::Class sources. At runtime,
`fondation_finalyze` loads the generated `share/openapi.json` via
[Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AOpenAPI) for request validation and adds
Swagger UI routes in development mode.

# CONFIGURATION

## Plugin config

    'Fondation::OpenAPI' => {
        backend => 'main',          # optional -- falls back to DBIx::Async default
        schemas => { ... },         # optional -- column overrides
    }

## Backend resolution

The backend name is resolved in this order:

- 1. OpenAPI's own `backend` config
- 2. DBIx::Async's `default_backend` config key
- 3. First backend in DBIx::Async's `backends` array

## Schema config override

Any column property can be overridden via `schemas` without modifying
DBIx Result classes. See [Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AOpenAPI%3A%3ACommand%3A%3Aopenapi)
for the full list of supported keys.

## x-auth config override

Permission annotations on CRUD endpoints can be overridden via `x_auth`
in the `schemas` config. The default convention is
`{moniker_lc}_{operation}` (e.g., `user_create`, `group_list`).

    'Fondation::OpenAPI' => {
        schemas => {
            User => {
                x_auth => {
                    create => {
                        permissions => ['admin_create_user'],
                        groups      => ['admins'],
                    },
                    list => {
                        permissions => [],   # public endpoint
                    },
                },
            },
        },
    }

Overrides replace the default entirely. An empty `permissions` array
makes the endpoint public (no `x-auth` in the generated spec).
Additional constraint keys (`groups`, `features`, etc.) are translated
into `requires()` route conditions at startup via the `openapi_routes_added` hook.

## openapi\_exclude in plugin `fondation_meta`

Plugins can declare tables that should be excluded from the generated
OpenAPI spec via `openapi_exclude` in their `fondation_meta`. This
is the canonical way to hide internal tables (pivot tables, audit logs,
etc.) that should never be exposed as public API endpoints.

    # In any Fondation plugin's fondation_meta:
    sub fondation_meta {
        return {
            defaults => {
                openapi_exclude => ['UserGroup'],
            },
        };
    }

Each entry is a DBIx::Class source moniker (class-derived name, e.g. `UserGroup`),
matching the `register_source` moniker used by Action::DBIx.
Excluded sources produce no CRUD
routes, no OpenAPI schemas, and no `public/js/validators.js` entries.

**Design:** The mechanism lives in plugin `fondation_meta` rather than
in the OpenAPI plugin config because the plugin that owns the table
knows best whether it should be exposed. This follows the Fondation
principle of self-contained bricks — the OpenAPI plugin only reads
what other plugins declare.

# DEPENDENCIES

This plugin requires [Fondation::Model::DBIx::Async](https://metacpan.org/pod/Fondation%3A%3AModel%3A%3ADBIx%3A%3AAsync).

Transitively, it depends on [Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AOpenAPI) >= 5.12,
which requires [JSON::Validator](https://metacpan.org/pod/JSON%3A%3AValidator) >= 5.17.

## Perl 5.40 Incompatibility

On Perl >= 5.40, [Net::IDN::Encode](https://metacpan.org/pod/Net%3A%3AIDN%3A%3AEncode) (a dependency of JSON::Validator
5.17+) fails to compile because its XS code calls `uvuni_to_utf8_flags`,
removed from the Perl C API in 5.40. This cascades:

    Net::IDN::Encode → compile FAIL (Perl ≥ 5.40)
      → JSON::Validator 5.17+ → blocked by cpanm
        → Mojolicious::Plugin::OpenAPI 5.12 → blocked

**Workaround on Debian:** the `libnet-idn-encode-perl` package provides
a pre-compiled version that works on Perl 5.40:

    apt install libnet-idn-encode-perl

# COMMANDS

## openapi generate

Generates `share/openapi.json` and `public/js/validators.js` from
DBIx::Class sources discovered via the configured backend.

Options: `-y` (overwrite without prompt), `--output` (custom path).

# RUNTIME

On startup (`fondation_finalyze`), if `share/openapi.json` exists it
is loaded via [Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AOpenAPI) for request validation.
`x-auth` permissions and groups are translated into route-level
`requires('fondation.perm')` and `requires('fondation.group')`
conditions via the `openapi_routes_added` hook, unifying protection
with HTML routes.
Swagger UI routes (`/swagger` and `/openapi.json`) are added in
development mode. If the spec is missing, a warning is logged and
startup continues.

# OUTPUT FILES

- `share/openapi.json`

    OpenAPI 3.0.3 specification with API Base schemas, contextual
    projections (only when different), and CRUD paths. Committed to the
    application repository.

- `public/js/validators.js`

    Client-side form validation via `FondationValidators.validate()`.
    Consumed by [Fondation::Asset](https://metacpan.org/pod/Fondation%3A%3AAsset) bundles. Committed to the application
    repository.

Always run `openapi generate` before `asset generate`.

# SEE ALSO

[Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AOpenAPI%3A%3ACommand%3A%3Aopenapi),
[Fondation::Model::DBIx::Async](https://metacpan.org/pod/Fondation%3A%3AModel%3A%3ADBIx%3A%3AAsync),
[Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AOpenAPI)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
