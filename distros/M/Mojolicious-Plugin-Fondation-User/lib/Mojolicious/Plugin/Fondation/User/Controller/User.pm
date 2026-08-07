package Mojolicious::Plugin::Fondation::User::Controller::User;
$Mojolicious::Plugin::Fondation::User::Controller::User::VERSION = '0.03';
# ABSTRACT: REST controller for User CRUD via DBIx::Class::Async

use Mojo::Base 'Mojolicious::Plugin::Fondation::Controller::Base', -signatures;

# ────────────────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────────────────

# Condition: ?with=groups triggers m2m prefetch
sub _want_groups ($self) {
    return $self->param('with') && $self->param('with') eq 'groups';
}

# ────────────────────────────────────────────────────────────────────────────
# CRUD
# ────────────────────────────────────────────────────────────────────────────

# Render the HTML page (no DB query — datatable loads via AJAX)
sub index ($self) {
    $self->render(template => 'user/list');
}

# List all users (GET /api/User)
# m2m groups are auto-included by Base::TO_JSON when $rs->with('groups') is used.
sub list ($self) {
    $self->render_later;

    my $rs = $self->_want_groups
        ? $self->model('user')->with('groups')
        : $self->model('user');

    $rs->TO_JSON->then(sub ($data) {
        $self->render(openapi => $data);
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

# Create a user (POST /api/User)
sub create ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $json      = $self->req->json;
    my $group_ids = delete $json->{groups};
    $self->model('user')->create($json)->on_done(sub {
        my $user = shift;

        my $data = $user->TO_JSON;

        # Sync group assignments (blocking in this worker — fast, no I/O wait)
        $self->_sync_user_groups($data->{id}, $group_ids)
            if $group_ids && @$group_ids;

        $self->res->headers->location($self->url_for('read_user', id => $data->{id}));
        $self->render(status => 201, openapi => $data);

        $self->notify_user({
            type  => 'info',
            title => $self->l('User created'),
            body  => sprintf($self->l("User '%s' has been created."), $data->{username} // ''),
        });
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

# Read a user by ID (GET /api/User/:id)
# m2m groups auto-included by Base::TO_JSON when with('groups') prefetched.
sub read ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');

    my $rs = $self->_want_groups
        ? $self->model('user')->with('groups')
        : $self->model('user');

    $rs->find($id)->on_done(sub {
        my $user = shift;
        if ($user) {
            $self->render(openapi => $user->TO_JSON);
        }
        else {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
        }
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
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

            my $data = $updated->TO_JSON;

            # Sync group assignments (blocking in this worker)
            $self->_sync_user_groups($id, $group_ids)
                if $group_ids;

            $self->render(openapi => $data);

            $self->notify_user({
                type  => 'info',
                title => $self->l('User updated'),
                body  => sprintf($self->l("User '%s' has been updated."), $data->{username} // ''),
            });
        })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
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
        })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::User::Controller::User - REST controller for User CRUD via DBIx::Class::Async

=head1 VERSION

version 0.03

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
