# NAME

Mojolicious::Plugin::Fondation::Setup - Setup wizard generator — scans plugins for user-configurable parameters, generates a setup workflow, and serves the wizard UI

# VERSION

version 0.04

# SYNOPSIS

    # In your Fondation config
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Setup',
        ],
    };

    # Web wizard
    /setup          — Setup wizard UI
    /setup/plugins  — Plugin selection page
    /setup/execute  — POST form data + execute action
    /setup/reset    — Reset wizard

# DESCRIPTION

This plugin provides an interactive web wizard at `/setup` for configuring
Fondation applications. It discovers available plugins via MetaCPAN, lets the
user pick which ones to enable, and walks through their configuration
parameters step by step using [Fondation::Workflow](https://metacpan.org/pod/Fondation%3A%3AWorkflow) with
[Workflow::Persister::File](https://metacpan.org/pod/Workflow%3A%3APersister%3A%3AFile) (no database required).

# NAME

Mojolicious::Plugin::Fondation::Setup - Setup wizard for Fondation applications

# PLUGIN CONTRACT

Other Fondation plugins declare user-configurable parameters via the
`setup` key in their `fondation_meta`:

    sub fondation_meta {
        return {
            setup => {
                label       => 'Database',
                description => 'Main database connection',
                parameters  => [
                    {
                        key      => 'backends.main.dsn',
                        label    => 'DSN',
                        type     => 'string',
                        default  => 'dbi:SQLite:dbname=data/app.db',
                        required => 1,
                    },
                ],
            },
        };
    }

Each parameter supports: key, label, type (string|integer|boolean|select|password),
default, required, min, max, placeholder, options (for select type).

# OUTPUT

## $moniker.conf

Application configuration file written when the user clicks "Save" in the
wizard.  Top-level key is `Fondation`, with `dependencies` listing every
selected plugin.  Plugins that have `setup` parameters are wrapped in a
hashref with their config; plugins without `setup` parameters are listed as
plain strings.

# WIZARD FLOW

    GET  /setup/plugins   — AJAX plugin list from MetaCPAN with selection checkboxes
    POST /setup/start     — build dynamic workflow from selected plugins
    GET  /setup           — interactive wizard (one step per plugin + review + done)
    POST /setup/execute   — store form values, execute workflow action
    GET  /setup/reset     — clear cookie, restart

Plugins already present in `$moniker.conf` are pre-checked on the selection
page.  Their existing config values (e.g. DSN, workers) pre-fill the wizard
fields so the user only changes what they need.

When the workflow reaches the `setup_done` state the controller writes
`$moniker.conf` and displays a confirmation page listing the configured
plugins and the path to the generated file.  If `Mojolicious::Plugin::Config`
is not loaded, a warning is shown with instructions to add `plugin 'Config';`
to the startup script and restart.

# ROUTES

- `GET /setup` — render the wizard for the current state
- `GET /setup/plugins` — plugin selection page (MetaCPAN list with checkboxes)
- `GET /setup/discover` — JSON API returning MetaCPAN plugin list
- `POST /setup/start` — build dynamic workflow from selected plugins
- `POST /setup/execute` — store form values in context, execute action
- `GET /setup/reset` — clear wizard cookie, start fresh

# SEE ALSO

[Mojolicious::Plugin::Fondation::Setup::Controller::Setup](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3ASetup%3A%3AController%3A%3ASetup),
[Mojolicious::Plugin::Fondation::Workflow](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AWorkflow)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
