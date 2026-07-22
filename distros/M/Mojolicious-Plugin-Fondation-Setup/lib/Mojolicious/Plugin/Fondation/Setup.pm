package Mojolicious::Plugin::Fondation::Setup;
$Mojolicious::Plugin::Fondation::Setup::VERSION = '0.11';
# ABSTRACT: Setup wizard with session-based state (clean rebuild)

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [
            'Fondation::Layout::Bootstrap',
            'Fondation::SessionStore',
        ],
    };
}

sub register ($self, $app, $conf) {

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

Mojolicious::Plugin::Fondation::Setup - Setup wizard with session-based state (clean rebuild)

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  # myapp.pl
  use Mojolicious::Lite;
  plugin 'Fondation' => {
      dependencies => ['Fondation::Setup'],
  };
  app->start;

  # Then visit http://localhost:3000/setup

=head1 DESCRIPTION

This plugin provides a step-by-step web wizard at C</setup> for
configuring a Fondation application. It discovers available plugins
from MetaCPAN, lets the user pick which ones to enable, and walks
through their configuration parameters.

=head2 How it works

=over

=item 1. B<Plugin selection> (C</setup/plugins>)

The wizard fetches the list of Fondation plugins from MetaCPAN. Each
plugin shows its version, status (installed/not installed), and
dependencies. Plugins already in the application's C<.conf> file are
pre-selected. Checking a plugin automatically checks its dependencies.

=item 2. B<Install missing plugins>

If any selected plugin is not installed via C<cpanm>, the wizard
shows the exact command to run. Configuration is skipped until all
plugins are installed. After running C<cpanm>, click "I have installed
the plugins, retry" to continue.

=item 3. B<Configuration> (one page per plugin)

For each installed plugin that declares user-configurable parameters
(via C<fondation_meta → setup>), the wizard shows a form. Values from
an existing C<.conf> file pre-fill the fields.

=item 4. B<Review and save>

A summary table shows all configured values. Click "Save Configuration"
to write the C<$moniker.conf> file.

=item 5. B<Apply>

Run C<myapp.pl fondation refresh> then restart the server.

=back

=head2 State management

All wizard state (selected plugins, current step, form values) is
stored in Mojolicious sessions — no database or file persister needed.
Clicking "Reset" or visiting C</setup/reset> clears the session.

=head1 QUICK START

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

=head1 ROUTES

  GET  /setup           Wizard main page
  GET  /setup/plugins   Plugin selection with checkboxes
  GET  /setup/discover  JSON API: plugin list from MetaCPAN
  POST /setup/start     Build session state from selected plugins
  POST /setup/execute   Process next/back/save actions
  GET  /setup/reset     Clear session, restart

=head1 CONFIGURATION

No configuration parameters. The plugin reads C<dev_plugins_dir> for locally-developed plugins.

=head1 PLUGIN CONTRACT

Other Fondation plugins declare their configurable parameters via the
C<setup> key in C<fondation_meta>:

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

=head1 DEPENDENCIES

=over

=item C<Fondation::Layout::Bootstrap> — provides the page layout

=back

=head1 OUTPUT

The wizard generates C<$moniker.conf> (e.g. C<myapp.conf>) in the
application home directory. Example:

  {
      Fondation => {
          dependencies => ['Fondation::Model::DBIx::Async', 'Fondation::User'],
      },
      'Fondation::Model::DBIx::Async' => {
          backends => [main => { dsn => 'dbi:SQLite:dbname=data/app.db' }],
      },
  }

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation>,

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
