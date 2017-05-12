package OX::Application::Role::Router::Path::Router;
BEGIN {
  $OX::Application::Role::Router::Path::Router::AUTHORITY = 'cpan:STEVAN';
}
$OX::Application::Role::Router::Path::Router::VERSION = '0.14';
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: implementation of OX::Application::Role::Router which uses Path::Router

use Plack::App::Path::Router::Custom 0.05;

with 'OX::Application::Role::Router', 'OX::Application::Role::Request';


sub router_class { 'Path::Router' }

sub app_from_router {
    my $self = shift;
    my ($router) = @_;

    return Plack::App::Path::Router::Custom->new(
        router => $router,
        new_request => sub {
            $self->new_request(@_);
        },
        target_to_app => sub {
            my ($target) = @_;
            my $app = blessed($target) && $target->can('to_app')
                ? $target->to_app
                : $target;
            sub {
                my ($req, @args) = @_;
                @args = map { $req->_decode($_) } @args;
                $app->($req, @args);
            }
        },
        handle_response => sub {
            $self->handle_response(@_);
        },
    )->to_app;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OX::Application::Role::Router::Path::Router - implementation of OX::Application::Role::Router which uses Path::Router

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  package MyApp;
  use Moose;
  extends 'OX::Application';
  with 'OX::Application::Role::Router::Path::Router';

  sub configure_router {
      my ($self, $router) = @_;

      $router->add_route('/',
          target => sub { "Hello world" }
      );
  }

=head1 DESCRIPTION

This role uses L<Path::Router> to provide a router for your application. It
uses L<OX::Application::Role::Router>, and overrides C<router_class> to be
C<Path::Router> and C<app_from_router> to create an app using
L<Plack::App::Path::Router::Custom>. It also uses
L<OX::Application::Role::Request> to allow the application code to use
L<OX::Request> instead of bare environment hashrefs.

See L<OX::Application::Role::RouterConfig> for a more convenient way to
implement C<configure_router>.

=for Pod::Coverage router_class
  app_from_router

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Jesse Luehrs <doy@tozt.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
