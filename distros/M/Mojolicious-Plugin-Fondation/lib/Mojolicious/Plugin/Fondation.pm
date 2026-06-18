package Mojolicious::Plugin::Fondation;
$Mojolicious::Plugin::Fondation::VERSION = '0.03';
# ABSTRACT: Hierarchical plugin loader with configuration priority and resource sharing

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojolicious::Plugin::Fondation::Resolver;
use Mojolicious::Plugin::Fondation::Manager;
use Mojolicious::Plugin::Fondation::API;
use Mojolicious::Plugin::Fondation::Helpers;
use Mojolicious::Plugin::Fondation::Utils qw(merge short_name find_share_dir);

sub register ($self, $app, $config = {}) {

    my $merged_config = merge(
        $config,
        $app->config->{'Fondation'} // {},
        );

    my $manager = Mojolicious::Plugin::Fondation::Manager->new(
        app    => $app,
        config => $merged_config,
    );

    # API shares the Manager's registry -- no circular ref
    $manager->{api} = Mojolicious::Plugin::Fondation::API->new(
        registry => $manager->registry,
    );

    # ── Register all helpers (fallbacks + real) BEFORE plugin discovery ──
    Mojolicious::Plugin::Fondation::Helpers->register($app, $manager);

    # ── Register command namespace ──
    push @{$app->commands->namespaces},
        'Mojolicious::Plugin::Fondation::Command';

    # ── Resolve the full dependency graph (with cycle detection) ──
    my $resolver = Mojolicious::Plugin::Fondation::Resolver->new(app => $app);
    my $sorted   = $resolver->resolve('Fondation', $merged_config);

    # ── Pre-register Fondation itself so load_all skips it ──
    my $short = short_name('Mojolicious::Plugin::Fondation');
    $manager->registry->{'Mojolicious::Plugin::Fondation'} = {
        instance       => $self,
        short_name     => $short,
        share_dir      => find_share_dir('Mojolicious::Plugin::Fondation'),
        config         => $merged_config,
        loaded_at      => time,
        metadata       => { has_templates => 0, has_assets => 0 },
        fondation_meta => $resolver->_discover_meta('Mojolicious::Plugin::Fondation'),
    };
    push @{$manager->load_order}, 'Mojolicious::Plugin::Fondation';

    $self->{log} = $app->log->context("[$short]");

    # ── Instantiate all plugins in resolved order ──
    $manager->load_all($sorted);

    # ── Post-load actions and finalyze ──
    $manager->run_post_load_actions();

    $manager->run_finalyze();

    $app->plugins->emit_hook(fondation_after_finalyze => $app, $manager);

    $manager->log->info("=== Fondation loaded successfully ===");

    $app->routes->get('/')->to(
        controller => 'Welcome',
        action     => 'index'
        );

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation - Hierarchical plugin loader with configuration priority and resource sharing

=head1 VERSION

version 0.03

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Fondation attempts to provide a foundation for building websites from
pre-built bricks. It is a plugin loader for Mojolicious that enables
hierarchical, recursive plugin loading with automatic configuration
merging, resource sharing (controllers, templates), and post-load actions.

It is designed for modular applications where multiple plugins contribute
routes, templates, and behavior, while avoiding duplicate loads and
respecting configuration priorities.

Key features:

=over 4

=item * Recursive plugin loading via C<dependencies>

=item * Configuration cascade: direct > app config > plugin defaults

=item * Automatic discovery and registration of C<share/templates>

=item * Application-level C<share/templates> have priority

=item * Extensible post-load actions (Templates, Controllers, custom)

=item * Deferred initialization via C<fondation_finalyze>

=item * Contextual logging via C<< $self->log >> (Mojo::Log context)

=back

=head1 LOADING ORDER

    1. load_plugin_recursive
       └─ Fondation -> dependencies recursively

    2. run_post_load_actions
       └─ For every plugin (load order), execute all actions
          (Templates, Controllers, custom)
       └─ App-level share/templates added with highest priority

    3. run_finalyze
       └─ For every plugin (load order), call fondation_finalyze()

=head1 QUICK START

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

=head2 With a config file

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

=head1 CONFIGURATION PRIORITIES

Each plugin receives a merged configuration built from three sources,
combined with L<Hash::Merge>. The cascade priority is:

=head3 1. Direct configuration (passed in C<dependencies> array)

    plugin 'Fondation' => {
        dependencies => [
            { 'Fondation::User' => { title => 'Direct override' } },
        ],
    };

=head3 2. Application configuration file (e.g. myapp.conf)

    {
        'Fondation::User' => {
            title => 'From config file',
        }
    }

=head3 3. Plugin defaults (returned by C<fondation_meta>)

    sub fondation_meta {
        return {
            defaults => { title => 'Default value' },
        };
    }

The merge rules are:

=over 4

=item * Scalars -- overwrite. The highest-priority non-empty value wins.

=item * Hashes -- merged recursively. Keys present at multiple levels are resolved
by priority; keys present at only one level survive untouched.

=item * Arrays -- concatenated. All values from all levels are kept, ordered
by priority: direct elements first, then app config, then defaults.

=back

Example: a plugin declares C<allowed_roles =E<gt> ['user']> in its defaults,
the app config adds C<allowed_roles =E<gt> ['editor']>, and a direct dependency
passes C<allowed_roles =E<gt> ['admin']>. The merged result is
C<['admin', 'editor', 'user']> -- all three roles are available, with the
highest-priority one first.

The C<dependencies> key is not special -- it follows the same array
concatenation rules. This means an app config can add extra dependencies
without repeating those already declared.

=head1 RESOURCE DIRECTORIES (share/)

Fondation automatically handles shared resources from plugins:

=over 4

=item * C<share/templates> -> pushed to C<$app->renderer->paths>

=item * C<share/public> -> pushed to C<$app->static->paths>

=back

The application's own C<share/templates> directory (if it exists) is added
with C<unshift> and therefore has **highest priority** (application templates
override plugin templates).

=head1 ACTIONS (POST-LOAD PROCESSING)

Actions are classes that run after **all** plugins are loaded, iterating
over each plugin in load order. They perform specific initialization tasks
such as registering templates or controllers. Actions are configurable via
the C<actions> key in Fondation's configuration.

=over 4

=item * Default actions: C<Templates>, C<Controllers>, C<Static>

=item * Custom actions: you can write your own action class by subclassing
C<Mojolicious::Plugin::Fondation::Action::Base> or declare them via
C<fondation_meta -> provides_actions>.

=back

=head2 Configuration

Set the C<actions> key in the Fondation configuration. You rarely need
this -- the defaults C<['Templates', 'Controllers']> are used, plus any
plugin-provided actions from C<fondation_meta -> provides_actions>.

    plugin 'Fondation' => {
        actions      => ['Templates'],       # keep Templates, drop Controllers
        dependencies => ['MyPlugin'],        # MyAction auto-added if declared
    };

=head2 Default Actions

=over 4

=item * C<Templates> (L<Mojolicious::Plugin::Fondation::Action::Templates>)

Adds the plugin's C<share/templates> directory to the application's template
search paths.

=item * C<Controllers> (L<Mojolicious::Plugin::Fondation::Action::Controllers>)

Automatically discovers controller modules under the plugin's namespace
(C<Plugin::Name::Controller::*>) and adds that namespace to
C<$app-E<gt>routes-E<gt>namespaces>, making the controllers available to the router.

=item * C<Static> (L<Mojolicious::Plugin::Fondation::Action::Static>)

Adds the plugin's C<share/public> directory to the application's static file
search paths and stores its location in the registry as C<public_dir> for
other consumers.

=back

=head2 Writing a Custom Action

Create a new class that inherits from C<Mojolicious::Plugin::Fondation::Action::Base>
and implements the C<after_load> method:

  package My::Action;
  use Mojo::Base 'Mojolicious::Plugin::Fondation::Action::Base', -signatures;

  sub after_load ($self, $long_name, $conf, $share_dir) {
      my $manager = $self->manager;
      my $app     = $manager->app;
      $self->log->debug("MyAction executed");
  }

  1;

To auto-enable your action from a plugin, declare it in C<fondation_meta>:

    sub fondation_meta {
        return {
            provides_actions => ['MyAction'],
        };
    }

The action class must live at C<${PluginNS}::Action::MyAction>. Fondation
resolves it automatically.

If the action name does not start with C<Mojolicious::>, Fondation will
prepend C<Mojolicious::Plugin::Fondation::Action::> to it as a fallback.

=head1 PLUGIN REGISTRY

After loading, every plugin is recorded in the registry — a hashref keyed by fully-qualified plugin name. Each entry stores:

=over 4

=item * instance — the plugin object returned by register()

=item * short_name — e.g. "Fondation::User"

=item * share_dir — path to the plugin's share/ directory

=item * config — merged configuration (direct > app > defaults)

=item * metadata — has_templates, has_assets flags

=item * fondation_meta — the raw return value of the plugin's fondation_meta()

=back

The Manager owns the registry. L<Mojolicious::Plugin::Fondation::API> exposes it for read-only access (same hashref, no copy). Post-load actions (Templates, Controllers, Static) iterate over it, as do zone helpers (render_zone, render_zone_js) and the finalyze phase.

=head1 CREATING A FONDATION-AWARE PLUGIN

=head3 1. File structure

    lib/Mojolicious/Plugin/Fondation/MyPlugin.pm
    share/templates/myplugin/           (optional)

=head3 2. Minimal code

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

=head3 3. Loading

    In your Fondation config:

        dependencies => [
            'MyPlugin',
            # or { 'MyPlugin' => { enable_feature => 0 } }
        ]

=head2 The C<fondation_meta> contract

All Fondation-aware plugins must define a class method C<fondation_meta>:

    sub fondation_meta {
        return {
            dependencies     => ['XXX', 'YYY'],   # loaded before this plugin
            provides_actions => ['MyAction'],       # optional custom action
            defaults         => {
                title => 'Default Title',
            },
        };
    }

=over 4

=item * C<dependencies> -> array of plugin names to load first

=item * C<provides_actions> -> optional array of custom action short names

=item * C<defaults> -> fallback configuration values (lowest priority)

=back

This method is called before C<register> to collect metadata without
instantiating the plugin. It is the cornerstone of Fondation's composition
model: every plugin declares what it needs and what it provides.

=head2 Why C<return $self> is required

To fully participate in Fondation's features (especially C<fondation_finalyze>),
a plugin B<must return $self> from its C<register> method.

If you don't return $self:

=over 4

=item * Instance is not stored in the registry

=item * C<fondation_finalyze> cannot be called

=item * Plugin is still loaded and actions run, but finalyze features are skipped

=back

=head1 HELPERS

Fondation registers the following helpers:

=over 4

=item * C<manager> -- returns the L<Mojolicious::Plugin::Fondation::Manager> instance

=item * C<has_helper($name)> -- checks whether a helper is registered

=item * C<l($key)> -- fallback identity function (overridden by I18N plugins)

=item * C<check_group> / C<check_perm> -- permissive fallbacks (allow all)

=item * C<notify_user> -- no-op that returns a resolved Promise

=item * C<render_zone($zone)> -- renders HTML zones from all plugins

=item * C<render_zone_js($zone)> -- includes JS zones from all plugins

=back

=head1 ZONES

Zones let plugins inject HTML or JavaScript fragments into named zones
defined by the application layout. Each plugin can provide zone
templates under C<share/templates/zones/>.

=head2 Directory structure

    share/templates/zones/
      html/header/          -> picked up by render_zone('header')
        greeting.html.ep
      js/footer/            -> picked up by render_zone_js('footer')
        init.js.ep

=head2 How it works

C<render_zone($zone)> iterates over every loaded plugin in load order
and renders all C<.html.ep> templates found in
C<share/templates/zones/html/$zone/>. The output is concatenated.

C<render_zone_js($zone)> does the same for C<.js.ep> files, but reads
the raw content instead of rendering through the template engine.

=head2 Usage in templates

    %= render_zone 'header'
    %= render_zone_js 'footer'

=head1 ABOUT THIS PROJECT

Fondation and its plugin ecosystem were developed with significant
assistance from an AI coding agent.

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
