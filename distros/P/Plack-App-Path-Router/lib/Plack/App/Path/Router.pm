package Plack::App::Path::Router;
BEGIN {
  $Plack::App::Path::Router::AUTHORITY = 'cpan:STEVAN';
}
$Plack::App::Path::Router::VERSION = '0.08';
use Moose 0.90;
use MooseX::NonMoose 0.07;
# ABSTRACT: A Plack component for dispatching with Path::Router

use Plack::Request 0.08;

extends 'Plack::App::Path::Router::Custom';




has 'request_class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => sub { 'Plack::Request' },
);

has '+new_request' => (
    default => sub {
        my $self = shift;
        sub {
            $self->request_class->new(@_);
        };
    },
);

has '+target_to_app' => (
    default => sub {
        sub {
            my ($target) = @_;

            if (blessed $target && $target->can('execute')) {
                return sub { $target->execute(@_) };
            }
            else {
                return $target;
            }
        };
    },
);

has '+handle_response' => (
    default => sub {
        sub {
            my ($res) = @_;

            if ( blessed $res && $res->can('finalize') ) {
                return $res->finalize;
            }
            elsif ( not ref $res ) {
                return [ 200, [ 'Content-Type' => 'text/html' ], [ $res ] ];
            }
            else {
                return $res;
            }
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

Plack::App::Path::Router - A Plack component for dispatching with Path::Router

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  use Plack::App::Path::Router;
  use Path::Router;

  my $router = Path::Router->new;
  $router->add_route('/' =>
      target => sub {
          my ($request) = @_;
          # use the Plack::Request to
          # create a Plack::Response ...
          my $response = $request->new_response( 200 );
          $response->content_type('text/html');
          $response->body('<html><body>HELLO WORLD</body></html>');
      }
  );
  $router->add_route('/:action/?:id' =>
      validations => {
          id => 'Int'
      },
      target => sub {
          # matches are passed to the target sub ...
          my ($request, $action, $id) = @_;
          # return a PSGI response ...
          [
            200,
            [ 'Content-Type' => 'text/html' ],
            [ '<html><body>', $action, $id, '</body></html>' ]
          ]
      }
  );
  $router->add_route('/:action/edit/:id' =>
      validations => {
          id => 'Int'
      },
      target => sub {
          my ($r, $action, $id) = @_;
          # return a string (we will wrap
          # it in a PSGI response for you)
          "This is my action($action), and I am editing this id($id)";
      }
  );
  $router->add_route('/foo' =>
      # target objects are also supported
      # as long as the object responds to
      # the ->execute method
      target => MyApp::Action->new( type => 'FOO' )
  );

  # now create the Plack app
  my $app = Plack::App::Path::Router->new( router => $router );

=head1 DESCRIPTION

This is a L<Plack::Component> subclass which creates an endpoint to dispatch
using L<Path::Router>.

This module expects an instance of L<Path::Router> whose routes all have a
C<target> that is a CODE ref or an object which responds to the C<execute>
method. The CODE ref or C<execute> method will be called when a match is
found and passed a L<Plack::Request> instance followed by any path captures
that were found. It is expected that the target return one of the following;
an object which responds to the C<finalize> method (like L<Plack::Response>),
a properly formed PSGI response or a plain string (which we will wrap inside
a PSGI response with a status of 200 and a content type of "text/html").

This thing is dead simple, if my docs don't make sense, then just read the
source (all ~75 lines of it).

=head1 ATTRIBUTES

=head2 router

This is a required attribute and must be an instance of L<Path::Router>.

=head2 request_class

This is a class name used to create the request object. It defaults to
L<Plack::Request> but anything that will accept a PSGI-style C<$env> in
the constructor and respond correctly to C<path_info> will work.

=head1 AUTHOR

Stevan Little <stevan.little at iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
