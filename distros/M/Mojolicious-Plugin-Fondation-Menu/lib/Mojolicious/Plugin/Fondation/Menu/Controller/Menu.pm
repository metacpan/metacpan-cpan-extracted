package Mojolicious::Plugin::Fondation::Menu::Controller::Menu;
$Mojolicious::Plugin::Fondation::Menu::Controller::Menu::VERSION = '0.04';
# ABSTRACT: REST controller for Menu CRUD via DBIx::Class::Async

use Mojo::Base 'Mojolicious::Plugin::Fondation::Controller::Base', -signatures;

# ── CRUD ────────────────────────────────────────────────────────────────

sub list ($self) {
    $self->render_later;
    $self->model('menu')->TO_JSON->then(sub ($data) {
        $self->render(openapi => $data);
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

sub create ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $json = $self->req->json;
    $self->model('menu')->create($json)->on_done(sub {
        my $menu = shift;
        my $data = $menu->TO_JSON;
        $self->res->headers->location($self->url_for('read_menu', id => $data->{id}));
        $self->render(status => 201, openapi => $data);
        $self->menu_cache_invalidate if $self->has_helper('menu_cache_invalidate');
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

sub read ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');
    $self->model('menu')->find($id)->on_done(sub {
        my $menu = shift;
        if ($menu) {
            $self->render(openapi => $menu->TO_JSON);
        } else {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
        }
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

sub update ($self) {
    $self->render_later;
    my $id   = $self->param('id');
    my $json = $self->req->json;
    $self    = $self->openapi->valid_input or return;

    $self->model('menu')->find($id)->on_done(sub {
        my $menu = shift;
        unless ($menu) {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
            return;
        }
        $menu->update($json)->on_done(sub {
            my $updated = shift;
            my $data    = $updated->TO_JSON;
            $self->render(openapi => $data);
            $self->menu_cache_invalidate if $self->has_helper('menu_cache_invalidate');
        })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

sub delete ($self) {
    $self = $self->openapi->valid_input or return;
    $self->render_later;
    my $id = $self->param('id');
    $self->model('menu')->find($id)->on_done(sub {
        my $menu = shift;
        unless ($menu) {
            $self->render(status => 404, openapi =>
                { errors => [{ message => 'Not found', path => '/' }] });
            return;
        }
        $menu->delete->on_done(sub {
            $self->render(status => 204, openapi => {});
            $self->menu_cache_invalidate if $self->has_helper('menu_cache_invalidate');
        })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
    })->on_fail(sub ($err) { $self->problem(status => 500, detail => "$err") })->retain;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Menu::Controller::Menu - REST controller for Menu CRUD via DBIx::Class::Async

=head1 VERSION

version 0.04

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
