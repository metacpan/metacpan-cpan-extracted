package OX::Application::Role::RouterConfig;
BEGIN {
  $OX::Application::Role::RouterConfig::AUTHORITY = 'cpan:STEVAN';
}
$OX::Application::Role::RouterConfig::VERSION = '0.14';
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: adds some common shortcuts to route declarations from OX::Application::Role::RouteBuilder

with 'OX::Application::Role::RouteBuilder';


around parse_route => sub {
    my $orig = shift;
    my $self = shift;
    my ($path, $route) = @_;

    if (ref($route) eq 'HASH'
     && exists($route->{controller})
     && exists($route->{action})) {
        my $controller = delete $route->{controller};
        my $action     = delete $route->{action};

        $route = {
            class      => 'OX::RouteBuilder::ControllerAction',
            route_spec => {
                controller => $controller,
                action     => $action,
            },
            params     => $route,
        };
    }
    elsif (ref($route) eq 'CODE') {
        $route = {
            class      => 'OX::RouteBuilder::Code',
            route_spec => $route,
            params     => {},
        };
    }

    return $self->$orig($path, $route);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OX::Application::Role::RouterConfig - adds some common shortcuts to route declarations from OX::Application::Role::RouteBuilder

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  package MyApp;
  use Moose;
  use Bread::Board;

  extends 'OX::Application';
  with 'OX::Application::Role::RouterConfig',
       'OX::Application::Role::Router::Path::Router';

  sub BUILD {
      my $self = shift;

      container $self => as {
          service root => (
              class => 'Foo::Root',
          );

          service 'RouterConfig' => (
              block => sub {
                  +{
                      '/' => {
                          controller => 'root',
                          action     => 'index',
                      },
                      '/foo' => sub { 'FOO' },
                  }
              },
          );
      };
  }

=head1 DESCRIPTION

This role overrides C<parse_route> in L<OX::Application::Role::RouteBuilder> to
provide some nicer syntax. If a value in your router config contains the
C<controller> and C<action> keys, it will extract those out and automatically
construct an L<OX::RouteBuilder::ControllerAction> for you. If the value is a
single coderef, it will automatically construct an L<OX::RouteBuilder::Code>
for you.

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
