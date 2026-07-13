# NAME

Mojolicious::Plugin::Fondation - Hierarchical plugin loader with configuration priority and resource sharing

# VERSION

version 0.04

# SYNOPSIS

    # In your Mojolicious application (myapp.pl or startup)
    plugin 'Fondation' => {
        dependencies => [
            { 'Fondation::User' => { title => 'Custom User' } },
            'Fondation::Authorization',
        ],
    };

    # In a plugin (e.g. lib/Mojolicious/Plugin/Fondation/User.pm)
    package Mojolicious::Plugin::Fondation::User;
    use Mojo::Base 'Mojolicious::Plugin', -signatures;

    sub fondation_meta {
        return {
            dependencies => [],
            defaults => {
                title => 'User Management',
                items_per_page => 20,
            },
        };
    }

    sub register ($self, $app, $conf) {
        $app->routes->get('/users' => sub ($c) { $c->render(text => "Users!") });
        return $self;   # Important for finalyze actions
    }

    sub fondation_finalyze ($self, $app, $long_name) {
        # Optional: code to run after all plugins are loaded
        $self->log->debug("User plugin fully loaded");
    }

    1;

# DESCRIPTION

Fondation attempts to provide a foundation for building websites from
pre-built bricks. It is a plugin loader for Mojolicious that enables
hierarchical, recursive plugin loading with automatic configuration
merging, resource sharing (controllers, templates), and post-load actions.

It is designed for modular applications where multiple plugins contribute
routes, templates, and behavior, while avoiding duplicate loads and
respecting configuration priorities.

Key features:

- Recursive plugin loading via `dependencies`
- Configuration cascade: direct > app config > plugin defaults
- Automatic discovery and registration of `share/templates`
- Application-level `share/templates` have priority
- Extensible post-load actions (Templates, Controllers, custom)
- Deferred initialization via `fondation_finalyze`
- Contextual logging via `$self->log` (Mojo::Log context)

# LOADING ORDER

    1. load_plugin_recursive
       └─ Fondation -> dependencies recursively

    2. run_post_load_actions
       └─ For every plugin (load order), execute all actions
          (Templates, Controllers, custom)
       └─ App-level share/templates added with highest priority

    3. run_finalyze
       └─ For every plugin (load order), call fondation_finalyze()

# QUICK START

    # myapp.pl
    use Mojolicious::Lite;

    plugin 'Fondation' => {
        dependencies => [
            'Fondation::User',
            'Fondation::Authorization',
        ],
    };

    # Fondation loads Authorization, which depends on Role + Permission.
    # Result: Role -> Permission -> Authorization -> User
    # All share/templates and controllers are auto-discovered.

## With a config file

    # myapp.conf
    {
        'Fondation' => {
            dependencies => ['Fondation::User', 'Fondation::Authorization'],
        },
        'Fondation::User' => {
            title => 'User Management',
        },
    }

    # myapp.pl
    plugin 'Config';
    plugin 'Fondation';   # reads dependencies from config

# CONFIGURATION PRIORITIES

Each plugin receives a merged configuration built from three sources,
combined with [Hash::Merge](https://metacpan.org/pod/Hash%3A%3AMerge). The cascade priority is:

### 1. Direct configuration (passed in `dependencies` array)

    plugin 'Fondation' => {
        dependencies => [
            { 'Fondation::User' => { title => 'Direct override' } },
        ],
    };

### 2. Application configuration file (e.g. myapp.conf)

    {
        'Fondation::User' => {
            title => 'From config file',
        }
    }

### 3. Plugin defaults (returned by `fondation_meta`)

    sub fondation_meta {
        return {
            defaults => { title => 'Default value' },
        };
    }

The merge rules are:

- Scalars -- overwrite. The highest-priority non-empty value wins.
- Hashes -- merged recursively. Keys present at multiple levels are resolved
by priority; keys present at only one level survive untouched.
- Arrays -- concatenated. All values from all levels are kept, ordered
by priority: direct elements first, then app config, then defaults.

Example: a plugin declares `allowed_roles => ['user']` in its defaults,
the app config adds `allowed_roles => ['editor']`, and a direct dependency
passes `allowed_roles => ['admin']`. The merged result is
`['admin', 'editor', 'user']` -- all three roles are available, with the
highest-priority one first.

The `dependencies` key is not special -- it follows the same array
concatenation rules. This means an app config can add extra dependencies
without repeating those already declared.

# RESOURCE DIRECTORIES (share/)

Fondation automatically handles shared resources from plugins:

- `share/templates` -> pushed to `$app-`renderer->paths>
- `share/public` -> pushed to `$app-`static->paths>

The application's own `share/templates` directory (if it exists) is added
with `unshift` and therefore has \*\*highest priority\*\* (application templates
override plugin templates).

# ACTIONS (POST-LOAD PROCESSING)

Actions are classes that run after \*\*all\*\* plugins are loaded, iterating
over each plugin in load order. They perform specific initialization tasks
such as registering templates or controllers. Actions are configurable via
the `actions` key in Fondation's configuration.

- Default actions: `Templates`, `Controllers`, `Static`
- Custom actions: you can write your own action class by subclassing
`Mojolicious::Plugin::Fondation::Action::Base` or declare them via
`fondation_meta -` provides\_actions>.

## Configuration

Set the `actions` key in the Fondation configuration. You rarely need
this -- the defaults `['Templates', 'Controllers']` are used, plus any
plugin-provided actions from `fondation_meta -` provides\_actions>.

    plugin 'Fondation' => {
        actions      => ['Templates'],       # keep Templates, drop Controllers
        dependencies => ['MyPlugin'],        # MyAction auto-added if declared
    };

## Default Actions

- `Templates` ([Mojolicious::Plugin::Fondation::Action::Templates](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAction%3A%3ATemplates))

    Adds the plugin's `share/templates` directory to the application's template
    search paths.

- `Controllers` ([Mojolicious::Plugin::Fondation::Action::Controllers](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAction%3A%3AControllers))

    Automatically discovers controller modules under the plugin's namespace
    (`Plugin::Name::Controller::*`) and adds that namespace to
    `$app->routes->namespaces`, making the controllers available to the router.

- `Static` ([Mojolicious::Plugin::Fondation::Action::Static](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAction%3A%3AStatic))

    Adds the plugin's `share/public` directory to the application's static file
    search paths and stores its location in the registry as `public_dir` for
    other consumers.

## Writing a Custom Action

Create a new class that inherits from `Mojolicious::Plugin::Fondation::Action::Base`
and implements the `after_load` method:

    package My::Action;
    use Mojo::Base 'Mojolicious::Plugin::Fondation::Action::Base', -signatures;

    sub after_load ($self, $long_name, $conf, $share_dir) {
        my $manager = $self->manager;
        my $app     = $manager->app;
        $self->log->debug("MyAction executed");
    }

    1;

To auto-enable your action from a plugin, declare it in `fondation_meta`:

    sub fondation_meta {
        return {
            provides_actions => ['MyAction'],
        };
    }

The action class must live at `${PluginNS}::Action::MyAction`. Fondation
resolves it automatically.

If the action name does not start with `Mojolicious::`, Fondation will
prepend `Mojolicious::Plugin::Fondation::Action::` to it as a fallback.

# PLUGIN REGISTRY

After loading, every plugin is recorded in the registry — a hashref keyed by fully-qualified plugin name. Each entry stores:

- instance — the plugin object returned by register()
- short\_name — e.g. "Fondation::User"
- share\_dir — path to the plugin's share/ directory
- config — merged configuration (direct > app > defaults)
- metadata — has\_templates, has\_assets flags
- fondation\_meta — the raw return value of the plugin's fondation\_meta()

The Manager owns the registry. [Mojolicious::Plugin::Fondation::API](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAPI) exposes it for read-only access (same hashref, no copy). Post-load actions (Templates, Controllers, Static) iterate over it, as do zone helpers (render\_zone, render\_zone\_js) and the finalyze phase.

# CREATING A FONDATION-AWARE PLUGIN

### 1. File structure

    lib/Mojolicious/Plugin/Fondation/MyPlugin.pm
    share/templates/myplugin/           (optional)

### 2. Minimal code

    package Mojolicious::Plugin::Fondation::MyPlugin;
    use Mojo::Base 'Mojolicious::Plugin', -signatures;

    sub fondation_meta {
        return {
            dependencies => [],
            defaults     => { enable_feature => 1 },
        };
    }

    sub register ($self, $app, $conf) {
        $app->routes->get('/myplugin' => sub ($c) {
            $c->render(text => "Hello from MyPlugin!");
        });
        return $self;  # Required for finalyze
    }

    sub fondation_finalyze ($self, $app, $long_name) {
        $self->log->debug("MyPlugin fully initialized");
    }

    1;

### 3. Loading

    In your Fondation config:

        dependencies => [
            'MyPlugin',
            # or { 'MyPlugin' => { enable_feature => 0 } }
        ]

## The `fondation_meta` contract

All Fondation-aware plugins must define a class method `fondation_meta`:

    sub fondation_meta {
        return {
            dependencies     => ['XXX', 'YYY'],   # loaded before this plugin
            provides_actions => ['MyAction'],       # optional custom action
            before           => ['ZZZ'],            # soft: load this plugin before ZZZ
            after            => ['WWW'],            # soft: load this plugin after WWW
            defaults         => {
                title => 'Default Title',
            },
        };
    }

- `dependencies` -> array of plugin names to load first
- `provides_actions` -> optional array of custom action short names
- `before` -> soft ordering: this plugin loads **before** the listed plugins.
Silently ignored when the target is not in the graph.
- `after` -> soft ordering: this plugin loads **after** the listed plugins.
Silently ignored when the target is not in the graph.
- `defaults` -> fallback configuration values (lowest priority)

This method is called before `register` to collect metadata without
instantiating the plugin. It is the cornerstone of Fondation's composition
model: every plugin declares what it needs and what it provides.

## Why `return $self` is required

To fully participate in Fondation's features (especially `fondation_finalyze`),
a plugin **must return $self** from its `register` method.

If you don't return $self:

- Instance is not stored in the registry
- `fondation_finalyze` cannot be called
- Plugin is still loaded and actions run, but finalyze features are skipped

# HELPERS

Fondation registers the following helpers:

- `manager` -- returns the [Mojolicious::Plugin::Fondation::Manager](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AManager) instance
- `has_helper($name)` -- checks whether a helper is registered
- `l($key)` -- fallback identity function (overridden by I18N plugins)
- `check_group` / `check_perm` -- permissive fallbacks (allow all)
- `notify_user` -- no-op that returns a resolved Promise
- `render_zone($zone)` -- renders HTML zones from all plugins
- `render_zone_js($zone)` -- includes JS zones from all plugins

# ZONES

Zones let plugins inject HTML or JavaScript fragments into named zones
defined by the application layout. Each plugin can provide zone
templates under `share/templates/zones/`.

## Directory structure

    share/templates/zones/
      html/header/          -> picked up by render_zone('header')
        greeting.html.ep
      js/footer/            -> picked up by render_zone_js('footer')
        init.js.ep

## How it works

`render_zone($zone)` iterates over every loaded plugin in load order
and renders all `.html.ep` templates found in
`share/templates/zones/html/$zone/`. The output is concatenated.

`render_zone_js($zone)` does the same for `.js.ep` files, but reads
the raw content instead of rendering through the template engine.

## Usage in templates

    %= render_zone 'header'
    %= render_zone_js 'footer'

# ABOUT THIS PROJECT

Fondation and its plugin ecosystem were developed with significant
assistance from an AI coding agent.

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
