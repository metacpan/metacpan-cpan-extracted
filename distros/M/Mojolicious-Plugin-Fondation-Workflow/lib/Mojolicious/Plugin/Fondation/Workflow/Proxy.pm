package Mojolicious::Plugin::Fondation::Workflow::Proxy;
$Mojolicious::Plugin::Fondation::Workflow::Proxy::VERSION = '0.01';
use Mojo::Base -base, -signatures;

has [qw(wf factory c type)];

# ── State accessors ──────────────────────────────────────────────────

sub state ($self) {
    return $self->wf->state;
}

sub state_label ($self) {
    my $state_name = $self->state;
    my $meta       = $self->_state_meta($state_name);
    return $self->c->l($meta->{label} // $state_name);
}

sub state_color ($self) {
    my $state_name = $self->state;
    my $meta       = $self->_state_meta($state_name);
    return $meta->{color} // 'secondary';
}

sub state_icon ($self) {
    my $state_name = $self->state;
    my $meta       = $self->_state_meta($state_name);
    return $meta->{icon};
}

# Return the full fondation metadata of the current state
# (label, color, icon, parameters, plugin, description, ...)
sub state_fondation ($self) {
    return $self->_state_meta($self->state);
}

# ── Actions ──────────────────────────────────────────────────────────

sub actions ($self) {
    my @action_names = $self->wf->get_current_actions;
    my @result;

    # Stable sort: back first, then next, then everything else
    my %order = (back => 0, next => 1);
    @action_names = sort {
        ($order{$a} // 2) <=> ($order{$b} // 2) || $a cmp $b
    } @action_names;

    foreach my $name (@action_names) {
        next unless $self->_action_authorized($name);
        my $meta = $self->_action_meta($name) // {};

        push @result, {
            name       => $name,
            label      => $self->c->l($meta->{label} // $name),
            color      => $meta->{color} // 'primary',
            icon       => $meta->{icon},
            confirm    => $meta->{confirm} ? $self->c->l($meta->{confirm}) : undef,
            group      => $meta->{group} // 'main',
            permission => $meta->{permission},
        };
    }

    return \@result;
}

sub can ($self, $action_name) {
    my @available = $self->wf->get_current_actions;
    return 0 unless grep { $_ eq $action_name } @available;
    return $self->_action_authorized($action_name);
}

# ── Execute ──────────────────────────────────────────────────────────

sub execute ($self, $action_name, $params = {}) {
    my $c      = $self->c;
    my $type   = $self->type;
    my $context = $self->wf->context->param;

    # Hook: before_execute
    $c->app->plugins->emit_hook(workflow_before_execute => $c, $type, $action_name, $context);

    my $old_state = $self->wf->state;
    my $new_state;
    eval {
        $new_state = $self->wf->execute_action($action_name, $params);
        # Workflow.pm 2.09 does not auto-add history during execute_action;
        # save_workflow already runs internally, but there's nothing to save
        # unless we explicitly add_history first.
        $self->wf->add_history({
            action      => $action_name,
            description => $params->{comment} // '',
            state       => $new_state,
            user        => ($c->can('current_user') && $c->current_user) ? $c->current_user->id : 'n/a',
            workflow_id => $self->wf->id,
        });
        $self->factory->save_workflow($self->wf);
    };
    if (my $err = $@) {
        $c->app->plugins->emit_hook(workflow_on_error => $c, $type, $action_name, $context, $err);
        die $err;
    }

    # Hook: after_execute
    $c->app->plugins->emit_hook(workflow_after_execute => $c, $type, $action_name, $context, $new_state);

    return $new_state;
}

# ── History ──────────────────────────────────────────────────────────

sub history ($self) {
    my @records = $self->wf->get_history;
    return [
        map { {
            action      => $_->action,
            description => $_->description,
            state       => $_->state,
            user        => $_->user,
            date        => $_->date,
        } } @records
    ];
}

# ── Workflow ID ─────────────────────────────────────────────────────

sub id ($self) {
    return $self->wf->id;
}

# ── Internal: metadata extraction ────────────────────────────────────

sub _workflow_config ($self) {
    my $type = $self->type;
    return $self->factory->{_workflow_config}{$type} // {};
}

sub _state_meta ($self, $state_name) {
    my $config = $self->_workflow_config;
    my $states = $config->{state} // [];
    foreach my $s (@$states) {
        return $s->{fondation} if $s->{name} eq $state_name;
    }
    return {};
}

sub _action_meta ($self, $action_name) {
    # Look in global action config first
    my $config  = $self->_workflow_config;
    my $actions = $config->{action} // [];
    foreach my $a (@$actions) {
        return $a->{fondation} if $a->{name} eq $action_name && $a->{fondation};
    }

    # Also check inline action definitions in states
    my $states = $config->{state} // [];
    foreach my $s (@$states) {
        my $s_actions = $s->{action} // [];
        foreach my $a (@$s_actions) {
            return $a->{fondation} if $a->{name} eq $action_name && $a->{fondation};
        }
    }

    return {};
}

sub _action_authorized ($self, $action_name) {
    my $meta       = $self->_action_meta($action_name);
    my $permission = $meta->{permission};
    return 1 unless defined $permission;

    my $c = $self->c;
    return 1 unless $c->has_helper('check_perm');
    return $c->check_perm($permission);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Workflow::Proxy

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
