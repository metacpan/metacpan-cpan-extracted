package Mojolicious::Plugin::Fondation::Perm::Controller::Perm;
$Mojolicious::Plugin::Fondation::Perm::Controller::Perm::VERSION = '0.01';
# ABSTRACT: REST controller for Perm CRUD via DBIx::Class::Async

use Mojo::Base 'Mojolicious::Plugin::Fondation::Controller::Base', -signatures;

# ---------------------------------------------------------------------------
# CRUD — permissions
# ---------------------------------------------------------------------------

# Render the HTML page (no DB query — datatable loads via AJAX)
sub index ($self) {
    $self->render(template => 'perm/list');
}

# List all permissions (GET /api/Perm)
sub list ($self) {
    $self->render_later;
    $self->model('perm')->search({})->all->on_done(sub {
        my $perms = shift;
        my @data  = map { _to_data($_) } @$perms;
        $self->render(openapi => \@data);
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# Read a permission by ID (GET /api/Perm/:id)
sub read ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');
    $self->model('perm')->find($id)->on_done(sub {
        my $perm = shift;
        if ($perm) {
            $self->render(openapi => _to_data($perm));
        }
        else {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
        }
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# Create a permission (POST /api/Perm)
sub create ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $data = $self->req->json;
    $self->model('perm')->create($data)->on_done(sub {
        my $perm = shift;
        my $d    = _to_data($perm);
        $self->res->headers->location($self->url_for('read_perm', id => $d->{id}));
        $self->render(status => 201, openapi => $d);

        $self->notify_user({
            type  => 'info',
            title => $self->l('Permission created'),
            body  => sprintf($self->l("Permission '%s' has been created."), $d->{name} // ''),
        });
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# Update a permission (PUT /api/Perm/:id)
sub update ($self) {
    $self->render_later;
    my $id   = $self->param('id');
    my $json = $self->req->json;

    $self = $self->openapi->valid_input or return;

    $self->model('perm')->find($id)->on_done(sub {
        my $perm = shift;
        unless ($perm) {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
            return;
        }
        $perm->update($json)->on_done(sub {
            my $updated = shift;
            my $d       = _to_data($updated);
            $self->render(openapi => $d);

            $self->notify_user({
                type  => 'info',
                title => $self->l('Permission updated'),
                body  => sprintf($self->l("Permission '%s' has been updated."), $d->{name} // ''),
            });
        })->on_fail(sub { $self->_render_error(shift) })->retain;
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# Delete a permission (DELETE /api/Perm/:id)
sub delete ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');
    $self->model('perm')->find($id)->on_done(sub {
        my $perm = shift;
        unless ($perm) {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
            return;
        }
        my $name = $perm->name;
        $perm->delete->on_done(sub {
            $self->render(status => 204, openapi => {});

            $self->notify_user({
                type  => 'warning',
                title => $self->l('Permission deleted'),
                body  => sprintf($self->l("Permission '%s' has been deleted."), $name // ''),
            });
        })->on_fail(sub { $self->_render_error(shift) })->retain;
    })->on_fail(sub { $self->_render_error(shift) })->retain;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _render_error ($self, $err) {
    $self->app->log->error('[Perm::Controller] _render_error: ' . $self->dumper($err));
    $self->render(status => 500, openapi =>
        { errors => [{ message => "$err", path => '/' }] });
}

sub _to_data ($row) {
    my $data = { $row->get_columns };

    # Serialize DateTime objects to ISO 8601 strings
    for my $key (keys %$data) {
        my $val = $data->{$key};
        if (ref $val && eval { $val->isa('DateTime') }) {
            $data->{$key} = $val->iso8601;
        }
    }

    return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Perm::Controller::Perm - REST controller for Perm CRUD via DBIx::Class::Async

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
