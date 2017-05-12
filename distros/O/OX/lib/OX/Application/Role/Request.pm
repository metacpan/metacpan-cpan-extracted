package OX::Application::Role::Request;
BEGIN {
  $OX::Application::Role::Request::AUTHORITY = 'cpan:STEVAN';
}
$OX::Application::Role::Request::VERSION = '0.14';
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: application role to allow the use of request and response objects

use Class::Load 'load_class';


sub BUILD { }
before BUILD => sub {
    my $self = shift;

    load_class($self->request_class);
};


sub request_class { 'OX::Request' }


sub new_request {
    my $self = shift;
    my ($env) = @_;

    return $self->request_class->new(env => $env);
}


sub handle_response {
    my $self = shift;
    my ($res, $req) = @_;

    if (!ref($res)) {
        $res = $req->new_response([
            200, [ 'Content-Type' => 'text/html' ], [ $res ]
        ]);
    }
    elsif (!blessed($res) || !$res->can('finalize')) {
        $res = $req->new_response($res);
    }

    return $res->finalize;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OX::Application::Role::Request - application role to allow the use of request and response objects

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  package MyApp;
  use Moose;
  extends 'OX::Application';
  with 'OX::Application::Role::Request';

  sub build_app {
      my $self = shift;
      return sub {
          my $env = shift;
          my $r = $self->new_request($env);
          return $self->handle_response(
              MyApp::Controller->new->do_action($r), $r
          );
      };
  }

=head1 DESCRIPTION

This role provides some helper methods for handling request and response
objects in your application.

=head1 METHODS

=head2 request_class

This method can be overridden to provide your own custom request class.
Defaults to OX::Request.

This request class is expected to provide a C<new_response> method, so
overriding the response class to use can be done by overriding this method in
your request class.

=head2 new_request($env)

Creates a new instance of the request class for the given PSGI environment.

=head2 handle_response($response, $request)

Takes a response provided by the application and turns it into a proper PSGI
response arrayref. The default implementation of this method handles bare
strings (turns them into a response with a code of 200 and a C<Content-Type>
header of C<text/html>) and anything which can be provided to the
C<new_response> method of the request object. C<$request> must be passed in
addition to the actual response that was received in order to be able to call
C<new_response>.

=for Pod::Coverage BUILD

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
