

[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](https://github.com/neo1ite/Modern-OpenAPI-Generator/blob/main/LICENSE)
[![Perl](https://img.shields.io/badge/perl-5.26%2B-blue.svg)](https://www.perl.org/)
[![CI](https://github.com/neo1ite/Modern-OpenAPI-Generator/actions/workflows/ci.yml/badge.svg)](https://github.com/neo1ite/Modern-OpenAPI-Generator/actions/workflows/ci.yml)
[![MetaCPAN package](https://repology.org/badge/version-for-repo/metacpan/perl%3Amodern-openapi-generator.svg)](https://repology.org/project/perl%3Amodern-openapi-generator/versions)
[![CPAN version](https://badge.fury.io/pl/Modern-OpenAPI-Generator.svg)](https://metacpan.org/pod/Modern/OpenAPI/Generator)
[![CPAN testers](https://cpants.cpanauthors.org/dist/Modern-OpenAPI-Generator.svg)](https://cpants.cpanauthors.org/dist/Modern-OpenAPI-Generator)

# NAME

Modern::OpenAPI::Generator - OpenAPI 3.x client/server generator for Mojolicious

# SYNOPSIS

    perl bin/oapi-perl-gen --name MyApp::API --output ./out openapi.yaml

    # or from Perl:
    use Modern::OpenAPI::Generator;
    Modern::OpenAPI::Generator->new(
      spec_path  => 'openapi.yaml',
      output_dir => './generated',
      name       => 'MyApp::API',
    )->run;

# DESCRIPTION

Generates:

- `::Client::Core`, `::Client::Sync`, `::Client::Async` (with `--client`) and `::Client::Result` — `Result` holds `tx` ([Mojo::Transaction](https://metacpan.org/pod/Mojo%3A%3ATransaction)) and `data` (JSON or inflated `::Model::*`). Shared `::Model::*` (and `::StubData` for local stubs) sit under the root package, usable from client or server. They are emitted with `--client` or with `--server --local-test` (even `--no-client`). When `openapi_schema_file` is set, [OpenAPI::Modern](https://metacpan.org/pod/OpenAPI%3A%3AModern) validates outgoing requests and incoming responses before inflation.
- Generated server controllers call `$c->openapi->valid_input` so [Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AOpenAPI) validates each incoming request; responses are checked when you `render(openapi => ...)` per the plugin
- `oapi-perl-gen --local-test` emits `::StubData` and controller stubs that return random data from the response schema, inflated with `::Model::*-`from\_json>, then serialized (`TO_JSON`) instead of HTTP 501
- Mojolicious server with [Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AOpenAPI)
- [Mojolicious::Plugin::SwaggerUI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ASwaggerUI) at `/swagger` on the same server as the API when `--ui` is on
- Optional auth helper modules (HMAC, Bearer) under `::Auth::Plugin::*`
- `README.md` in the output tree (usage, install, server/client/UI commands — OpenAPI Generator style)
- `docs/*.md` per-tag API reference and `components/schemas` model pages, linked from the README
- `t/*.t` smoke tests for the generated modules

See [Modern::OpenAPI::Generator::CLI](https://metacpan.org/pod/Modern%3A%3AOpenAPI%3A%3AGenerator%3A%3ACLI) (`oapi-perl-gen --help`) for `--client` / `--server` / `--ui` selection rules. For Swagger UI, the generated `script/server.pl` prepends the request origin to `servers` in the served YAML only when run with `--local-test` (runtime) or `OAPI_SWAGGER_LOCAL_ORIGIN=1` — this is separate from `oapi-perl-gen --local-test` (codegen stubs).

# METHODS

## new

Builds a generator instance. Required: `spec_path`, `output_dir`, `name`.
Optional boolean / list keys include `client`, `server`, `ui`, `sync`,
`async`, `skeleton`, `force`, `merge`, `signatures`, `local_test`.

## run

Loads the OpenAPI document, emits files under `output_dir`, writes a root
`cpanfile`, and returns `$self`.

# INSTALLATION

After installing the distribution from CPAN (`cpanm Modern::OpenAPI::Generator`)
or from a source tree (`perl Makefile.PL && make && make install`), the
`oapi-perl-gen` script is on your `PATH`.

# DEVELOPMENT

When running tests from a checkout, remove any stale `blib/` directory first
so `lib/` is used (see the project `README.md` / `CONTRIBUTING.md`).

# SEE ALSO

[OpenAPI::Modern](https://metacpan.org/pod/OpenAPI%3A%3AModern), [Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AOpenAPI), [Mojolicious::Plugin::SwaggerUI](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ASwaggerUI),
[YAML::PP](https://metacpan.org/pod/YAML%3A%3APP), [Moo](https://metacpan.org/pod/Moo).

# COPYRIGHT AND LICENSE

Copyright (c) 2026 by the Modern::OpenAPI::Generator authors. This library is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.
