package Mojolicious::Plugin::Fondation::Setup;

# ABSTRACT: Setup wizard generator — scans plugins for user-configurable parameters, generates a setup workflow, and serves the wizard UI

use Mojo::Base 'Mojolicious::Plugin', -signatures;

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => [
            'Fondation::Workflow',
            'Fondation::Layout::Bootstrap',
        ],
        after => ['Fondation::Workflow'],
    };
}

sub register ($self, $app, $conf) {

    # ── Setup wizard routes ──────────────────────────────────────────

    my $r = $app->routes;

    $r->get('/setup')->to('Setup#wizard')->name('setup_wizard');
    $r->get('/setup/plugins')->to('Setup#plugins')->name('setup_plugins');
    $r->get('/setup/discover')->to('Setup#discover')->name('setup_discover');
    $r->post('/setup/start')->to('Setup#start')->name('setup_start');
    $r->post('/setup/execute')->to('Setup#execute')->name('setup_execute');
    $r->get('/setup/reset')->to('Setup#reset')->name('setup_reset');

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Setup - Setup wizard generator — scans plugins for user-configurable parameters, generates a setup workflow, and serves the wizard UI

=head1 VERSION

version 0.02

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This plugin provides an interactive web wizard at C</setup> for configuring
Fondation applications. It discovers available plugins via MetaCPAN, lets the
user pick which ones to enable, and walks through their configuration
parameters step by step using L<Fondation::Workflow> with
L<Workflow::Persister::File> (no database required).

=head1 NAME

Mojolicious::Plugin::Fondation::Setup - Setup wizard for Fondation applications

=head1 PLUGIN CONTRACT

Other Fondation plugins declare user-configurable parameters via the
C<setup> key in their C<fondation_meta>:

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

=head1 OUTPUT

=head2 $moniker.conf

Application configuration file written when the user clicks "Save" in the
wizard.  Top-level key is C<Fondation>, with C<dependencies> listing every
selected plugin.  Plugins that have C<setup> parameters are wrapped in a
hashref with their config; plugins without C<setup> parameters are listed as
plain strings.

=head1 WIZARD FLOW

  GET  /setup/plugins   — AJAX plugin list from MetaCPAN with selection checkboxes
  POST /setup/start     — build dynamic workflow from selected plugins
  GET  /setup           — interactive wizard (one step per plugin + review + done)
  POST /setup/execute   — store form values, execute workflow action
  GET  /setup/reset     — clear cookie, restart

Plugins already present in C<$moniker.conf> are pre-checked on the selection
page.  Their existing config values (e.g. DSN, workers) pre-fill the wizard
fields so the user only changes what they need.

When the workflow reaches the C<setup_done> state the controller writes
C<$moniker.conf> and displays a confirmation page listing the configured
plugins and the path to the generated file.  If C<Mojolicious::Plugin::Config>
is not loaded, a warning is shown with instructions to add C<plugin 'Config';>
to the startup script and restart.

=head1 ROUTES

=over

=item C<GET /setup> — render the wizard for the current state

=item C<GET /setup/plugins> — plugin selection page (MetaCPAN list with checkboxes)

=item C<GET /setup/discover> — JSON API returning MetaCPAN plugin list

=item C<POST /setup/start> — build dynamic workflow from selected plugins

=item C<POST /setup/execute> — store form values in context, execute action

=item C<GET /setup/reset> — clear wizard cookie, start fresh

=back

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation::Setup::Controller::Setup>,
L<Mojolicious::Plugin::Fondation::Workflow>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
