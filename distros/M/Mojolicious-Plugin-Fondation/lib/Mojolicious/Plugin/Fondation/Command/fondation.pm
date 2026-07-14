package Mojolicious::Plugin::Fondation::Command::fondation;

# ABSTRACT: Fondation orchestration commands -- init, upgrade, clean, refresh

use Mojo::Base 'Mojolicious::Command', -signatures;

use utf8;
use Mojo::File 'path';
use File::Path qw(remove_tree);

our $VERSION = '0.01';

has description => 'Orchestrate Fondation plugins: init, upgrade, clean, refresh';
has usage       => sub ($self) {
    <<"USAGE";
Usage: APPLICATION fondation COMMAND [OPTIONS]

  myapp.pl db bootstrap-schema    Create the schema class (run once)
  myapp.pl fondation plan init    Preview init steps (dry-run)
  myapp.pl fondation plan upgrade Preview upgrade steps (dry-run)
  myapp.pl fondation plan clean   Preview clean steps (dry-run)
  myapp.pl fondation plan refresh Preview refresh steps (dry-run)
  myapp.pl fondation init         First-time setup for all plugins
  myapp.pl fondation upgrade      Detect drift, upgrade, regenerate
  myapp.pl fondation clean        Clean all generated artifacts
  myapp.pl fondation refresh      Clean all generated artifacts and regenerate

USAGE
};

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

sub run ($self, @args) {
    my $app        = $self->app;
    my $subcommand = shift @args || '';

    die $self->usage unless $subcommand;

    for ($subcommand) {
        /^plan$/    and return $self->_run_plan($app, shift @args || '');
        /^init$/    and return $self->_run_init($app);
        /^upgrade$/ and return $self->_run_upgrade($app);
        /^clean$/   and return $self->_run_clean($app);
        /^refresh$/ and return $self->_run_refresh($app);
        die $self->usage;
    }
}

# ---------------------------------------------------------------------------
# Run a list of steps through $app->commands->run()
# ---------------------------------------------------------------------------

sub _run_steps ($self, $app, $step_name, $long_name, $steps) {
    for my $step (@$steps) {
        my @cmd = ref $step eq 'ARRAY' ? @$step : ($step);
        $app->commands->run(@cmd);
    }
}

# ---------------------------------------------------------------------------
# Collect steps from all plugins in load order
# ---------------------------------------------------------------------------

sub _collect_steps ($self, $app, $key) {
    my @steps;
    for my $long (@{ $app->manager->load_order }) {
        my $entry = $app->manager->registry->{$long};
        my $cfg   = $entry->{config} // {};
        my $plugin_steps = $cfg->{$key};
        next unless $plugin_steps && ref $plugin_steps eq 'ARRAY' && @$plugin_steps;
        push @steps, { long_name => $long, steps => $plugin_steps };
    }
    return @steps;
}

# ---------------------------------------------------------------------------
# Collect clean targets from all plugins in load order
# ---------------------------------------------------------------------------

sub _collect_clean ($self, $app) {
    my @targets;
    for my $long (@{ $app->manager->load_order }) {
        my $entry = $app->manager->registry->{$long};
        my $cfg   = $entry->{config} // {};
        my $plugin_clean = $cfg->{fondation_clean};
        next unless $plugin_clean && ref $plugin_clean eq 'ARRAY' && @$plugin_clean;
        push @targets, { long_name => $long, targets => $plugin_clean };
    }
    return @targets;
}

# ---------------------------------------------------------------------------
# fondation plan (dry-run preview)
# ---------------------------------------------------------------------------

sub _run_plan ($self, $app, $subcommand) {
    die $self->usage unless $subcommand;

    for ($subcommand) {
        /^init$/    and return $self->_show_plan_init($app);
        /^upgrade$/ and return $self->_show_plan_upgrade($app);
        /^clean$/   and return $self->_show_plan_clean($app);
        /^refresh$/ and return $self->_show_plan_refresh($app);
        die $self->usage;
    }
}

sub _short_name ($self, $app, $long) {
    return $app->manager->registry->{$long}{short_name} // $long;
}

sub _show_plan_init ($self, $app) {
    my @plugins = $self->_collect_steps($app, 'fondation_init');
    my $total_steps = 0;

    for my $p (@plugins) {
        my $short = $self->_short_name($app, $p->{long_name});
        say "-- $short";
        for my $step (@{ $p->{steps} }) {
            my @cmd = ref $step eq 'ARRAY' ? @$step : ($step);
            say "   [run] @cmd";
            $total_steps++;
        }
    }

    say "-- Init plan: " . scalar(@plugins) . " plugins, $total_steps steps --";
}

sub _show_plan_upgrade ($self, $app) {
    my @plugins = $self->_collect_steps($app, 'fondation_upgrade');
    my $total_steps = 0;

    for my $p (@plugins) {
        my $short = $self->_short_name($app, $p->{long_name});
        say "-- $short";
        for my $step (@{ $p->{steps} }) {
            my @cmd = ref $step eq 'ARRAY' ? @$step : ($step);
            say "   [run] @cmd";
            $total_steps++;
        }
    }

    say "-- Upgrade plan: " . scalar(@plugins) . " plugins, $total_steps steps --";
}

sub _show_plan_clean ($self, $app) {
    my @clean = $self->_collect_clean($app);

    unless (@clean) {
        say "-- Nothing to clean --";
        return;
    }

    say "-- Clean phase --";
    my $total_targets = 0;
    for my $p (@clean) {
        my $short = $self->_short_name($app, $p->{long_name});
        for my $target (@{ $p->{targets} }) {
            say "   [$short] remove $target";
            $total_targets++;
        }
    }

    say "-- Clean plan: " . scalar(@clean) . " plugins, $total_targets targets --";
}

sub _show_plan_refresh ($self, $app) {
    $self->_show_plan_clean($app);
    say '' if @{ [ $self->_collect_clean($app) ] };
    $self->_show_plan_init($app);
    say "-- Refresh plan --";
}

sub _run_init ($self, $app) {
    my @plugins = $self->_collect_steps($app, 'fondation_init');

    for my $plugin (@plugins) {
        my $short = $app->manager->registry->{$plugin->{long_name}}{short_name};
        say "-- $short";
        $self->_run_steps($app, 'fondation_init', $plugin->{long_name}, $plugin->{steps});
    }

    say "-- Init complete --";
}

# ---------------------------------------------------------------------------
# fondation upgrade
# ---------------------------------------------------------------------------

sub _run_upgrade ($self, $app) {
    my @plugins = $self->_collect_steps($app, 'fondation_upgrade');

    for my $plugin (@plugins) {
        my $short = $app->manager->registry->{$plugin->{long_name}}{short_name};
        say "-- $short";
        $self->_run_steps($app, 'fondation_upgrade', $plugin->{long_name}, $plugin->{steps});
    }

    say "-- Upgrade complete --";
}

# ---------------------------------------------------------------------------
# fondation clean
# ---------------------------------------------------------------------------

sub _run_clean ($self, $app) {
    my $home  = $app->home;
    my @clean = $self->_collect_clean($app);

    return say "-- Nothing to clean --" unless @clean;

    say "-- Cleaning generated artifacts --";

    for my $plugin (@clean) {
        my $short = $app->manager->registry->{$plugin->{long_name}}{short_name};
        for my $target (@{ $plugin->{targets} }) {
            my $path = path($home, $target);

            if (-d $path) {
                say "   [$short] Removing $target";
                remove_tree($path->to_string, { safe => 0 });
            }
            elsif (-f $path) {
                say "   [$short] Removing $target";
                unlink $path->to_string;
            }
        }
    }

    say "-- Clean complete --";
}

# ---------------------------------------------------------------------------
# fondation refresh
# ---------------------------------------------------------------------------

sub _run_refresh ($self, $app) {
    $self->_run_clean($app);
    $self->_run_init($app);
    say "-- Refresh complete --";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Command::fondation - Fondation orchestration commands -- init, upgrade, clean, refresh

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  $ myapp.pl fondation init
  $ myapp.pl fondation upgrade
  $ myapp.pl fondation clean
  $ myapp.pl fondation refresh

=head1 DESCRIPTION

Provides C<init>, C<upgrade>, C<clean>, C<refresh>, and C<plan> commands that iterate
over all loaded Fondation plugins and execute the steps each plugin declares in its
C<fondation_meta>.

=head2 Plugin contract

Plugins declare their participation via C<fondation_meta -> defaults>:

  sub fondation_meta {
      return {
          defaults => {
              fondation_init    => [ ['db', 'prepare', '-y'], ['db', 'install'] ],
              fondation_upgrade => [ ['db', 'prepare', '-y', '-a'], ['db', 'upgrade'] ],
              fondation_clean   => ['data/app.db'],
          },
      };
  }

All three keys are optional -- a plugin only declares what it needs.
Because they live in C<defaults>, they participate in the config merge
cascade (direct > app config > defaults). Users can override or extend
them just like any other Fondation config value.

=over

=item * C<fondation_init> -- array of command steps, each C<[command, args...]>

=item * C<fondation_upgrade> -- array of command steps for incremental upgrade

=item * C<fondation_clean> -- array of paths (relative to app home) to remove

=back

=head2 Commands

=head3 fondation plan

Dry-run preview that shows what C<init>, C<upgrade>, C<clean>, or C<refresh> would
execute without actually running any steps.

  $ myapp.pl fondation plan init
  $ myapp.pl fondation plan upgrade
  $ myapp.pl fondation plan clean
  $ myapp.pl fondation plan refresh

Output shows each plugin (by short name) and its steps or clean targets,
in load order. A summary line at the end gives plugin and step counts.

=head3 fondation init

Iterates over plugins in load order. For each plugin that declares
C<fondation_init>, runs each step via C<< $app->commands->run(@step) >>.

=head3 fondation upgrade

Same as C<init>, but uses C<fondation_upgrade> from each plugin.

=head3 fondation clean

Iterates over plugins in load order and removes each path declared in the
plugin's C<fondation_clean> list. Paths are relative to the application home.

=head3 fondation refresh

Calls C<fondation clean> followed by C<fondation init>.

=head1 NAME

Mojolicious::Plugin::Fondation::Command::fondation - Orchestrate Fondation plugins

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
