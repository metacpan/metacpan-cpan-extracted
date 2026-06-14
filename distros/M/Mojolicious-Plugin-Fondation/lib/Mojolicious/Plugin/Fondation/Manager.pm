package Mojolicious::Plugin::Fondation::Manager;
$Mojolicious::Plugin::Fondation::Manager::VERSION = '0.01';
# ABSTRACT: Plugin registry, post-load actions, and finalyze initialization

use Mojo::Base -base, -signatures;
use Mojolicious::Plugin::Fondation::Utils qw(find_share_dir share_relative);

has 'app';
has 'config';
has 'api';

has registry   => sub { {} };
has load_order => sub { [] };
has fixture_sets => sub { [] };
has log       => undef;

has action_classes => sub ($self) {
    my $short_list = $self->config->{actions} // ['Templates', 'Controllers', 'Static'];
    my %seen = map { $_ => 1 } @$short_list;
    my @all  = @$short_list;

    for my $long (@{$self->load_order}) {
        my $meta = $self->registry->{$long}{fondation_meta} // {};
        for my $short (@{ $meta->{provides_actions} // [] }) {
            next if $seen{$short}++;
            push @all, $short;
        }
    }

    return [ map { $self->_resolve_action_class($_) } @all ];
};

# ---------------------------------------------------------------------------
# load_all -- instantiate plugins from a pre-sorted list (from Resolver)
# ---------------------------------------------------------------------------
sub load_all ($self, $sorted_specs) {
    $self->{log} //= $self->app->log->context('[Fondation]');

    for my $spec (@$sorted_specs) {
        my $long   = $spec->{long};
        my $short  = $spec->{short};
        my $merged = $spec->{config};
        my $meta   = $spec->{meta};

        next if $self->registry->{$long};

        # Fondation itself is registered by the caller
        next if $long eq 'Mojolicious::Plugin::Fondation';

        $self->log->debug("Loading plugin $short");

        my $instance = $self->_prepare_and_register($long, $short, $merged);

        my $share_dir = find_share_dir($long, $merged->{share_dir});

        $self->registry->{$long} = {
            instance       => $instance,
            short_name     => $short,
            share_dir      => $share_dir,
            config         => $merged,
            loaded_at      => time,
            metadata       => { has_templates => 0, has_assets => 0 },
            fondation_meta => $meta,
        };

        push @{$self->load_order}, $long;
    }
}

sub _prepare_and_register ($self, $long, $short, $merged) {
    my $app = $self->app;

    # 1. Loading the Instance (without Register)
    my $instance = $app->plugins->load_plugin($long);

    # 2. Injection of the contextual logger before register
    $instance->{log} = $app->log->context("[$short]");

    # 3. Inject the ->log method if it doesn't exist
    unless ($instance->can('log')) {
        Mojo::Util::monkey_patch(ref($instance), log => sub { shift->{log} });
    }

    # 4. Calling the register (the logger is now available)disponible)
    $instance->register($app, $merged);

    return $instance;
}

sub _resolve_action_class ($self, $short) {
    return $short if $short =~ /^Mojolicious::/;

    for my $long (@{$self->load_order}) {
        my $meta = $self->registry->{$long}{fondation_meta} // {};
        my $provides = $meta->{provides_actions} // [];
        return "${long}::Action::${short}"
            if grep { $_ eq $short } @$provides;
    }
    return "Mojolicious::Plugin::Fondation::Action::${short}";
}

sub _run_post_load_actions_for ($self, $long, $conf = {}) {
    my $plugin = $self->registry->{$long}{instance};
    return unless $plugin && ref $plugin;
    my $share_dir = $self->registry->{$long}{share_dir};

    for my $action_class (@{$self->action_classes}) {
        eval "require $action_class; 1" or do {
            $self->log->warn("Action $action_class not loaded: $@");
            next;
        };

        my ($action_short) = $action_class =~ /::Action::(.+)$/;
        my $action_log = $self->app->log->context("[$action_short Action]");

        my $action = $action_class->new(
            manager => $self,
            log     => $action_log,
        );
        $action->after_load($long, $conf, $share_dir);
    }
}

sub run_post_load_actions ($self) {
    my $count = scalar @{$self->action_classes};
    $self->log->debug("Running post-load actions for all plugins ($count configured)");

    for my $long (@{$self->load_order}) {
        $self->_run_post_load_actions_for($long);
    }

    # Add local 'share/templates'
    my $app_templates = $self->app->home->child('share', 'templates');
    if (-d $app_templates) {
        unshift @{$self->app->renderer->paths}, $app_templates->to_string;
        $self->log->debug("App templates priority: " . share_relative($app_templates));
    }

    # Add local 'public'
    my $app_public = $self->app->home->child('public');
    if (-d $app_public) {
        unshift @{$self->app->static->paths}, $app_public->to_string;
        $self->log->debug("App public priority: " . share_relative($app_public));
    }
}

sub run_finalyze ($self) {
    $self->log->debug("Running fondation_finalyze in loading order");

    for my $long (@{$self->load_order}) {
        my $entry  = $self->registry->{$long};
        my $plugin = $entry->{instance};

        if (! defined $plugin) {
            $self->log->info("Skipped finalyze for $long");
            next;
        }

        if ($plugin->can('fondation_finalyze')) {
            eval {
                $plugin->fondation_finalyze($self->app, $long);
                1;
            } or do {
                die "Error in fondation_finalyze for $long: $@";
            };
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Manager - Plugin registry, post-load actions, and finalyze initialization

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
