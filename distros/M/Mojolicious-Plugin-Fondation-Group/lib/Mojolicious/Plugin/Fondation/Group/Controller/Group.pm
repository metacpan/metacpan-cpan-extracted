package Mojolicious::Plugin::Fondation::Group::Controller::Group;
$Mojolicious::Plugin::Fondation::Group::Controller::Group::VERSION = '0.03';
# ABSTRACT: REST controller for Group CRUD via DBIx::Class::Async

use Mojo::Base 'Mojolicious::Plugin::Fondation::Controller::Base', -signatures;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Condition: ?with=perms triggers m2m prefetch
sub _want_perms ($self) {
    return $self->param('with') && $self->param('with') eq 'perms';
}

# ---------------------------------------------------------------------------
# CRUD — groups
# ---------------------------------------------------------------------------

# Render the HTML page (no DB query — datatable loads via AJAX)
sub index ($self) {
    $self->render(template => 'group/list');
}

# List all groups (GET /api/Group)
# m2m perms are auto-included by Base::TO_JSON when $rs->with('perms') is used.
sub list ($self) {
    $self->render_later;

    my $rs = $self->_want_perms
        ? $self->model('group')->with('perms')
        : $self->model('group');

    $rs->TO_JSON->then(sub ($data) {
        $self->render(openapi => $data);
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

# Read a group by ID (GET /api/Group/:id)
# m2m perms auto-included by Base::TO_JSON when with('perms') prefetched.
sub read ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');

    my $rs = $self->_want_perms
        ? $self->model('group')->with('perms')
        : $self->model('group');

    $rs->find($id)->on_done(sub {
        my $group = shift;
        if ($group) {
            $self->render(openapi => $group->TO_JSON);
        }
        else {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
        }
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

# Create a group (POST /api/Group)
sub create ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $data     = $self->req->json;
    my $perm_ids = delete $data->{perms};
    $self->model('group')->create($data)->on_done(sub {
        my $group = shift;
        my $d    = $group->TO_JSON;

        # Sync permission assignments (blocking in this worker)
        $self->_sync_group_perms($d->{id}, $perm_ids)
            if $perm_ids && @$perm_ids;

        $self->res->headers->location($self->url_for('read_group', id => $d->{id}));
        $self->render(status => 201, openapi => $d);

        $self->notify_user({
            type  => 'info',
            title => $self->l('Group created'),
            body  => sprintf($self->l("Group '%s' has been created."), $d->{name} // ''),
        });
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

# Update a group (PUT /api/Group/:id)
sub update ($self) {
    $self->render_later;
    my $id   = $self->param('id');
    my $json = $self->req->json;

    $self = $self->openapi->valid_input or return;
    my $perm_ids = delete $json->{perms};

    $self->model('group')->find($id)->on_done(sub {
        my $group = shift;
        unless ($group) {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
            return;
        }
        $group->update($json)->on_done(sub {
            my $updated = shift;
            my $d       = $updated->TO_JSON;

            # Sync permission assignments (blocking in this worker)
            $self->_sync_group_perms($id, $perm_ids)
                if $perm_ids;

            $self->render(openapi => $d);

            $self->notify_user({
                type  => 'info',
                title => $self->l('Group updated'),
                body  => sprintf($self->l("Group '%s' has been updated."), $d->{name} // ''),
            });
        })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

# Delete a group (DELETE /api/Group/:id)
sub delete ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');
    $self->model('group')->find($id)->on_done(sub {
        my $group = shift;
        unless ($group) {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
            return;
        }
        my $name = $group->name;
        $group->delete->on_done(sub {
            $self->render(status => 204, openapi => {});

            $self->notify_user({
                type  => 'warning',
                title => $self->l('Group deleted'),
                body  => sprintf($self->l("Group '%s' has been deleted."), $name // ''),
            });
        })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

# ---------------------------------------------------------------------------
# Membership — user ↔ group association
# ---------------------------------------------------------------------------

sub members ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $group_id = $self->param('id');
    $self->model('user_group')->search({ group_id => $group_id })->TO_JSON->then(sub ($data) {
        $self->render(openapi => $data);
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

sub add_member ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $group_id = $self->param('id');
    my $data     = $self->req->json;
    $data->{group_id} = $group_id;
    $self->model('user_group')->create($data)->on_done(sub {
        my $membership = shift;
        $self->render(status => 201, openapi => $membership->TO_JSON);
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

sub remove_member ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $group_id = $self->param('id');
    my $user_id  = $self->param('user_id');
    $self->model('user_group')->search({ group_id => $group_id, user_id => $user_id })->all->on_done(sub {
        my $members = shift;
        unless ($members && @$members) {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Member not found', path => '/' }] });
            return;
        }
        $members->[0]->delete->on_done(sub {
            $self->render(status => 204, openapi => {});
        })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

# ---------------------------------------------------------------------------
# Permission assignment sync — internal helper
# ---------------------------------------------------------------------------

sub _sync_group_perms ($self, $group_id, $perm_ids) {
    my $schema = $self->schema;

    # 1. Delete existing permission assignments
    my $existing = $schema->await(
        $self->model('group_perm')->search({ group_id => $group_id })->all
    );
    if ($existing && @$existing) {
        $schema->await(Future->needs_all(map { $_->delete } @$existing));
    }

    # 2. Create new permission assignments
    return unless $perm_ids && @$perm_ids;
    $schema->await(Future->needs_all(
        map { $self->model('group_perm')->create({ group_id => $group_id, perm_id => $_ }) }
            @$perm_ids
    ));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Group::Controller::Group - REST controller for Group CRUD via DBIx::Class::Async

=head1 VERSION

version 0.03

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
