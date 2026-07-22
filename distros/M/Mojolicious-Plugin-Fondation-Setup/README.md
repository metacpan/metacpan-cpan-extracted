# NAME

Mojolicious::Plugin::Fondation::Setup - Setup wizard with session-based state (clean rebuild)

# VERSION

version 0.11

# SYNOPSIS

    # myapp.pl
    use Mojolicious::Lite;
    plugin 'Fondation' => {
        dependencies => ['Fondation::Setup'],
    };
    app->start;

    # Then visit http://localhost:3000/setup

# DESCRIPTION

This plugin provides a step-by-step web wizard at `/setup` for
configuring a Fondation application. It discovers available plugins
from MetaCPAN, lets the user pick which ones to enable, and walks
through their configuration parameters.

## How it works

- 1. **Plugin selection** (`/setup/plugins`)

    The wizard fetches the list of Fondation plugins from MetaCPAN. Each
    plugin shows its version, status (installed/not installed), and
    dependencies. Plugins already in the application's `.conf` file are
    pre-selected. Checking a plugin automatically checks its dependencies.

- 2. **Install missing plugins**

    If any selected plugin is not installed via `cpanm`, the wizard
    shows the exact command to run. Configuration is skipped until all
    plugins are installed. After running `cpanm`, click "I have installed
    the plugins, retry" to continue.

- 3. **Configuration** (one page per plugin)

    For each installed plugin that declares user-configurable parameters
    (via `fondation_meta → setup`), the wizard shows a form. Values from
    an existing `.conf` file pre-fill the fields.

- 4. **Review and save**

    A summary table shows all configured values. Click "Save Configuration"
    to write the `$moniker.conf` file.

- 5. **Apply**

    Run `myapp.pl fondation refresh` then restart the server.

## State management

All wizard state (selected plugins, current step, form values) is
stored in Mojolicious sessions — no database or file persister needed.
Clicking "Reset" or visiting `/setup/reset` clears the session.

# QUICK START

    # 1. Create a new application directory
    mkdir Myapp && cd Myapp

    # 2. Create myapp.pl
    echo 'use Mojolicious::Lite;
    use lib 'lib';
    plugin "Config";
    plugin "Fondation";
    app->start;' > myapp.pl

    # 2. Create myapp.conf
    {
      Fondation => {
        dependencies => [
          'Fondation::Setup',
        ]
      },
    }


    # 3. Initialize (creates assets, etc.)
    perl myapp.pl fondation init

    # 4. Start the development server
    perl myapp.pl daemon

    # 5. Open http://localhost:3000/setup in your browser

# ROUTES

    GET  /setup           Wizard main page
    GET  /setup/plugins   Plugin selection with checkboxes
    GET  /setup/discover  JSON API: plugin list from MetaCPAN
    POST /setup/start     Build session state from selected plugins
    POST /setup/execute   Process next/back/save actions
    GET  /setup/reset     Clear session, restart

# CONFIGURATION

No configuration parameters. The plugin reads `dev_plugins_dir` for locally-developed plugins.

# PLUGIN CONTRACT

Other Fondation plugins declare their configurable parameters via the
`setup` key in `fondation_meta`:

    sub fondation_meta {
        return {
            setup => {
                label       => 'Database',
                description => 'Main database connection',
                parameters  => [
                    {
                        key      => 'dsn',
                        label    => 'DSN',
                        type     => 'string',
                        default  => 'dbi:SQLite:dbname=data/app.db',
                        required => 1,
                    },
                ],
            },
        };
    }

# DEPENDENCIES

- `Fondation::Layout::Bootstrap` — provides the page layout

# OUTPUT

The wizard generates `$moniker.conf` (e.g. `myapp.conf`) in the
application home directory. Example:

    {
        Fondation => {
            dependencies => ['Fondation::Model::DBIx::Async', 'Fondation::User'],
        },
        'Fondation::Model::DBIx::Async' => {
            backends => [main => { dsn => 'dbi:SQLite:dbname=data/app.db' }],
        },
    }

# SEE ALSO

[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation),

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
