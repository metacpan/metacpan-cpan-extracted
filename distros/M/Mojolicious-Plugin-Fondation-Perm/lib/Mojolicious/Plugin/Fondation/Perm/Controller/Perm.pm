package Mojolicious::Plugin::Fondation::Perm::Controller::Perm;
$Mojolicious::Plugin::Fondation::Perm::Controller::Perm::VERSION = '0.03';
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
    $self->model('perm')->search({})->TO_JSON->then(sub ($data) {
        $self->render(openapi => $data);
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

# Read a permission by ID (GET /api/Perm/:id)
sub read ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');
    $self->model('perm')->find($id)->on_done(sub {
        my $perm = shift;
        if ($perm) {
            $self->render(openapi => $perm->TO_JSON);
        }
        else {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
        }
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

# Create a permission (POST /api/Perm)
sub create ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $data = $self->req->json;
    $self->model('perm')->create($data)->on_done(sub {
        my $perm = shift;
        my $d    = $perm->TO_JSON;
        $self->res->headers->location($self->url_for('read_perm', id => $d->{id}));
        $self->render(status => 201, openapi => $d);

        $self->notify_user({
            type  => 'info',
            title => $self->l('Permission created'),
            body  => sprintf($self->l("Permission '%s' has been created."), $d->{name} // ''),
        });
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
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
            my $d       = $updated->TO_JSON;
            $self->render(openapi => $d);

            $self->notify_user({
                type  => 'info',
                title => $self->l('Permission updated'),
                body  => sprintf($self->l("Permission '%s' has been updated."), $d->{name} // ''),
            });
        })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
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
        })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Perm::Controller::Perm - REST controller for Perm CRUD via DBIx::Class::Async

=head1 VERSION

version 0.03

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
