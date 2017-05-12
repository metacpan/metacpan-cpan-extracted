package Plack::App::Path::Router::PSGI;
BEGIN {
  $Plack::App::Path::Router::PSGI::AUTHORITY = 'cpan:STEVAN';
}
$Plack::App::Path::Router::PSGI::VERSION = '0.08';
use Moose 0.90;
use MooseX::NonMoose 0.07;
# ABSTRACT: A Plack component for dispatching with Path::Router to Pure PSGI targets

extends 'Plack::App::Path::Router::Custom';



has '+target_to_app' => (
    default => sub {
        sub {
            my ($target) = @_;

            return blessed $target && $target->can('to_app')
                ? $target->to_app
                : $target;
        };
    },
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::Path::Router::PSGI - A Plack component for dispatching with Path::Router to Pure PSGI targets

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  use Plack::App::Path::Router::PSGI;
  use Path::Router;

  my $router = Path::Router->new;
  $router->add_route('/' =>
      target => sub {
          my $env  = shift;
          [
            200,
            [ 'Content-Type' => 'text/html' ],
            [ '<html><body>Home</body></html>' ]
          ]
      }
  );
  $router->add_route('/:action/?:id' =>
      validations => {
          id => 'Int'
      },
      target => sub {
          my $env = shift;
          # matches are passed through the $env
          my ($action, $id) = @{ $env->{'plack.router.match.args'} };
          [
            200,
            [ 'Content-Type' => 'text/html' ],
            [ '<html><body>', $action, $id, '</body></html>' ]
          ]
      }
  );
  $router->add_route('admin/:action/?:id' =>
      validations => {
          id => 'Int'
      },
      # targets are just PSGI apps, so you can
      # wrap with middleware as needed ...
      target => Plack::Middleware::Auth::Basic->wrap(
          sub {
              my $env = shift;
              # matches are passed through the $env
              my ($action, $id) = @{ $env->{'plack.router.match.args'} };
              [
                200,
                [ 'Content-Type' => 'text/html' ],
                [ '<html><body>', $action, $id, '</body></html>' ]
              ]
          },
          authenticator => sub {
              my ($username, $password) = @_;
              return $username eq 'admin' && $password eq 's3cr3t';
          }
      )
  );

  # now create the Plack app
  my $app = Plack::App::Path::Router::PSGI->new( router => $router );

=head1 DESCRIPTION

This is a L<Plack::Component> subclass which creates an endpoint to dispatch
using L<Path::Router>.

This module is similar to L<Plack::App::Path::Router> except that it expects
all the route targets to be pure PSGI apps, nothing more, nothing less. Which
means that they will accept a single C<$env> argument and return a valid
PSGI formatted response.

This will place, into the C<$env> the router instance into 'plack.router',
any valid match in 'plack.router.match' and the collected URL match args in
'plack.router.match.args'.

This thing is dead simple, if my docs don't make sense, then just read the
source (all ~45 lines of it).

=head1 ATTRIBUTES

=head2 router

This is a required attribute and must be an instance of L<Path::Router>.

=head1 AUTHOR

Stevan Little <stevan.little at iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
