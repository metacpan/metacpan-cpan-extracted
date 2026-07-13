package Mojolicious::Plugin::Fondation::User::Controller::User;
$Mojolicious::Plugin::Fondation::User::Controller::User::VERSION = '0.01';
# ABSTRACT: REST controller for User CRUD via DBIx::Class::Async

use Mojo::Base 'Mojolicious::Plugin::Fondation::Controller::Base', -signatures;

# ────────────────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────────────────

# Check if Group plugin is loaded and ?with=groups was requested
sub _want_groups ($self) {
    return 0 unless $self->param('with') && $self->param('with') eq 'groups';
    return 0 unless $self->has_helper('fondation');
    return exists $self->fondation->registry->{'Mojolicious::Plugin::Fondation::Group'};
}

# Check if Group plugin is loaded
sub _has_group_plugin ($self) {
    return 0 unless $self->has_helper('fondation');
    return exists $self->fondation->registry->{'Mojolicious::Plugin::Fondation::Group'};
}

# ────────────────────────────────────────────────────────────────────────────
# CRUD
# ────────────────────────────────────────────────────────────────────────────

# Render the HTML page (no DB query — datatable loads via AJAX)
sub index ($self) {
    $self->render(template => 'user/list');
}

# List all users (GET /api/User)
sub list ($self) {
    $self->render_later;

    my $rs = $self->_want_groups
        ? $self->model('user')->with('groups')
        : $self->model('user');

    my $schema = $self->schema;
    $rs->all->on_done(sub {
        my $users = shift;
        my @data  = map { _to_data($_, $schema) } @$users;
        $self->render(openapi => \@data);
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# Create a user (POST /api/User)
sub create ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $json      = $self->req->json;
    my $group_ids = delete $json->{groups};
    $self->model('user')->create($json)->on_done(sub {
        my $user = shift;
        my $data = _to_data($user);

        # Sync group assignments (blocking in this worker — fast, no I/O wait)
        $self->_sync_user_groups($data->{id}, $group_ids)
            if $group_ids && @$group_ids && $self->_has_group_plugin;

        $self->res->headers->location($self->url_for('read_user', id => $data->{id}));
        $self->render(status => 201, openapi => $data);

        $self->notify_user({
            type  => 'info',
            title => $self->l('User created'),
            body  => sprintf($self->l("User '%s' has been created."), $data->{username} // ''),
        });
    })->on_fail(sub {
        my $err = shift;
        $self->app->log->error('[User::create] on_fail: ' . $self->dumper($err));
        $self->_render_error($err);
    })->retain;
}

# Read a user by ID (GET /api/User/:id)
sub read ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');

    my $rs = $self->_want_groups
        ? $self->model('user')->with('groups')
        : $self->model('user');

    my $schema = $self->schema;
    $rs->find($id)->on_done(sub {
        my $user = shift;
        if ($user) {
            $self->render(openapi => _to_data($user, $schema));
        }
        else {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
        }
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# Update a user (PUT /api/User/:id)
sub update ($self) {
    $self->render_later;
    my $id   = $self->param('id');
    my $json = $self->req->json;

    # Must be stripped BEFORE valid_input to pass minLength validation
    delete $json->{password} if defined $json->{password} && $json->{password} !~ /\S/;

    $self = $self->openapi->valid_input or return;
    my $group_ids = delete $json->{groups};

    $self->model('user')->find($id)->on_done(sub {
        my $user = shift;
        unless ($user) {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
            return;
        }
        $user->update($json)->on_done(sub {
            my $updated = shift;
            my $data    = _to_data($updated);

            # Sync group assignments (blocking in this worker)
            $self->_sync_user_groups($id, $group_ids)
                if $group_ids && $self->_has_group_plugin;

            $self->render(openapi => $data);

            $self->notify_user({
                type  => 'info',
                title => $self->l('User updated'),
                body  => sprintf($self->l("User '%s' has been updated."), $data->{username} // ''),
            });
        })->on_fail(sub { $self->_render_error(shift) })->retain;
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# Delete a user (DELETE /api/User/:id)
sub delete ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');
    $self->model('user')->find($id)->on_done(sub {
        my $user = shift;
        unless ($user) {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
            return;
        }
        my $username = $user->username;
        $user->delete->on_done(sub {
            $self->notify_user({
                type  => 'warning',
                title => $self->l('User deleted'),
                body  => sprintf($self->l("User '%s' has been deleted."), $username // ''),
            });
            $self->render(status => 204, openapi => {});
        })->on_fail(sub { $self->_render_error(shift) })->retain;
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# ────────────────────────────────────────────────────────────────────────────
# Group assignment sync — internal helper
# ────────────────────────────────────────────────────────────────────────────

sub _sync_user_groups ($self, $user_id, $group_ids) {
    my $schema = $self->schema;

    # 1. Delete existing memberships
    my $existing = $schema->await(
        $self->model('user_group')->search({ user_id => $user_id })->all
    );
    if ($existing && @$existing) {
        $schema->await(Future->needs_all(map { $_->delete } @$existing));
    }

    # 2. Create new memberships
    return unless $group_ids && @$group_ids;
    $schema->await(Future->needs_all(
        map { $self->model('user_group')->create({ user_id => $user_id, group_id => $_ }) }
            @$group_ids
    ));
}

# ────────────────────────────────────────────────────────────────────────────
# Private helpers
# ────────────────────────────────────────────────────────────────────────────

sub _render_error ($self, $err) {
    $self->app->log->error('[User::Controller] _render_error: ' . $self->dumper($err));
    $self->render(status => 500, openapi =>
        { errors => [{ message => "$err", path => '/' }] });
}

sub _to_data ($row, $schema = undef) {
    my $data = { $row->get_columns };
    delete $data->{password};

    # Serialize DateTime objects to ISO 8601 strings
    for my $key (keys %$data) {
        my $val = $data->{$key};
        if (ref $val && eval { $val->isa('DateTime') }) {
            $data->{$key} = $val->iso8601;
        }
    }

    # Include many_to_many groups if available (resolved via prefetched data,
    # Future->done returns instantly — no extra query).
    if ($schema && $row->can('groups')) {
        $data->{groups} = $schema->await($row->groups);
    }

    return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::User::Controller::User - REST controller for User CRUD via DBIx::Class::Async

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
