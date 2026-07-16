package Mojolicious::Plugin::Fondation::Group::Controller::Group;
$Mojolicious::Plugin::Fondation::Group::Controller::Group::VERSION = '0.01';
# ABSTRACT: REST controller for Group CRUD via DBIx::Class::Async

use Mojo::Base 'Mojolicious::Plugin::Fondation::Controller::Base', -signatures;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Check if Perm plugin is loaded and ?with=perms was requested
sub _want_perms ($self) {
    return 0 unless $self->param('with') && $self->param('with') eq 'perms';
    return 0 unless $self->has_helper('fondation');
    return exists $self->fondation->registry->{'Mojolicious::Plugin::Fondation::Perm'};
}

# Check if Perm plugin is loaded
sub _has_perm_plugin ($self) {
    return 0 unless $self->has_helper('fondation');
    return exists $self->fondation->registry->{'Mojolicious::Plugin::Fondation::Perm'};
}

# ---------------------------------------------------------------------------
# CRUD — groups
# ---------------------------------------------------------------------------

# Render the HTML page (no DB query — datatable loads via AJAX)
sub index ($self) {
    $self->render(template => 'group/list');
}

# List all groups (GET /api/Group)
sub list ($self) {
    $self->render_later;

    my $rs = $self->_want_perms
        ? $self->model('group')->with('perms')
        : $self->model('group');

    my $schema = $self->schema;
    $rs->all->on_done(sub {
        my $groups = shift;
        my @data   = map { _to_data($_, $schema) } @$groups;
        $self->render(openapi => \@data);
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# Read a group by ID (GET /api/Group/:id)
sub read ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');

    my $rs = $self->_want_perms
        ? $self->model('group')->with('perms')
        : $self->model('group');

    my $schema = $self->schema;
    $rs->find($id)->on_done(sub {
        my $group = shift;
        if ($group) {
            $self->render(openapi => _to_data($group, $schema));
        }
        else {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
        }
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# Create a group (POST /api/Group)
sub create ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $data     = $self->req->json;
    my $perm_ids = delete $data->{perms};
    $self->model('group')->create($data)->on_done(sub {
        my $group = shift;
        my $d    = _to_data($group);

        # Sync permission assignments (blocking in this worker)
        $self->_sync_group_perms($d->{id}, $perm_ids)
            if $perm_ids && @$perm_ids && $self->_has_perm_plugin;

        $self->res->headers->location($self->url_for('read_group', id => $d->{id}));
        $self->render(status => 201, openapi => $d);

        $self->notify_user({
            type  => 'info',
            title => $self->l('Group created'),
            body  => sprintf($self->l("Group '%s' has been created."), $d->{name} // ''),
        });
    })->on_fail(sub { $self->_render_error(shift) })->retain;
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
            my $d       = _to_data($updated);

            # Sync permission assignments (blocking in this worker)
            $self->_sync_group_perms($id, $perm_ids)
                if $perm_ids && $self->_has_perm_plugin;

            $self->render(openapi => $d);

            $self->notify_user({
                type  => 'info',
                title => $self->l('Group updated'),
                body  => sprintf($self->l("Group '%s' has been updated."), $d->{name} // ''),
            });
        })->on_fail(sub { $self->_render_error(shift) })->retain;
    })->on_fail(sub { $self->_render_error(shift) })->retain;
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
        })->on_fail(sub { $self->_render_error(shift) })->retain;
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# ---------------------------------------------------------------------------
# Membership — user ↔ group association
# ---------------------------------------------------------------------------

sub members ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $group_id = $self->param('id');
    $self->model('user_group')->search({ group_id => $group_id })->all->on_done(sub {
        my $members = shift;
        my @data    = map { _to_data($_) } @$members;
        $self->render(openapi => \@data);
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

sub add_member ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $group_id = $self->param('id');
    my $data     = $self->req->json;
    $data->{group_id} = $group_id;
    $self->model('user_group')->create($data)->on_done(sub {
        my $membership = shift;
        $self->render(status => 201, openapi => _to_data($membership));
    })->on_fail(sub { $self->_render_error(shift) })->retain;
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
        })->on_fail(sub { $self->_render_error(shift) })->retain;
    })->on_fail(sub { $self->_render_error(shift) })->retain;
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

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _render_error ($self, $err) {
    $self->app->log->error('[Group::Controller] _render_error: ' . $self->dumper($err));
    $self->render(status => 500, openapi =>
        { errors => [{ message => "$err", path => '/' }] });
}

sub _to_data ($row, $schema = undef) {
    my $data = { $row->get_columns };

    # Serialize DateTime objects to ISO 8601 strings
    for my $key (keys %$data) {
        my $val = $data->{$key};
        if (ref $val && eval { $val->isa('DateTime') }) {
            $data->{$key} = $val->iso8601;
        }
    }

    # Include many_to_many perms if available (resolved via prefetched data,
    # Future->done returns instantly — no extra query).
    if ($schema && $row->can('perms')) {
        $data->{perms} = $schema->await($row->perms);
    }

    return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Group::Controller::Group - REST controller for Group CRUD via DBIx::Class::Async

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
