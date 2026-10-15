package Plack::Middleware::OIDC::Redirect;
use 5.020;
use utf8;
use strict;
use warnings;

use Plack::Response;

=encoding utf8

=head1 NAME

Plack::Middleware::OIDC::Redirect - Internal exception class used to signal a redirect

=head1 DESCRIPTION

L<OIDC::Client::Plugin> is designed for frameworks where the current request
has a mutable response object that a controller can alter at any point
(C<$c->redirect_to(...)> in Mojolicious, for example).

PSGI has no such object: the response is simply the return value of the
application coderef. So when application code calls
C<$env->{oidc}->redirect_to_authorize()> or
C<$env->{oidc}->redirect_to_logout()> from deep within its own logic,
there is no direct way to make the enclosing PSGI application return early
with a redirect response.

To work around this, L<Plack::Middleware::OIDC> gives L<OIDC::Client::Plugin>
a C<redirect> coderef that throws an instance of this class instead of
performing the redirection itself. L<Plack::Middleware::OIDC> then wraps the
call to the downstream application in an C<eval>, catches this exception, and
turns it into a real C<302> PSGI response.

This mirrors the way L<Plack::Middleware::HTTPExceptions> turns exception
objects into HTTP responses, and this class follows the same convention : it
implements an L</as_psgi()> method, so that it is also understood by the
components which look for it.

Frameworks which rethrow the exceptions implementing C<as_psgi()> instead of
turning them into an error page will let this exception reach
L<Plack::Middleware::OIDC>.

=head1 METHODS

=head2 new( url => $url )

  my $redirect = Plack::Middleware::OIDC::Redirect->new(url => $url);

Creates an exception object to be thrown. The C<url> parameter is the URL
the browser must be redirected to.

=cut

sub new {
  my ($class, %args) = @_;

  return bless { url => $args{url} }, $class;
}


=head2 url()

Returns the URL to redirect to.

  my $url = $redirect->url();

=cut

sub url { return $_[0]->{url} }


=head2 as_psgi()

  my $psgi_response = $redirect->as_psgi();

Returns the PSGI response (an arrayref C<[ $status, \@headers, \@body ]>)
corresponding to this redirection : a C<302> status with the C<Location>
header set to the L</url()>.

This method follows the convention used by L<Plack::Middleware::HTTPExceptions>
and by the frameworks which look for it : an exception which implements it is
considered as "knowing what it wants", and can be handed over to the PSGI layer
instead of being handled as an ordinary application error.
L<Plack::Middleware::OIDC> calls it to build the response when it catches the
exception, and L<Plack::Middleware::HTTPExceptions> would do the same if the
exception happened to reach it.

=cut

sub as_psgi {
  my ($self) = @_;

  my $res = Plack::Response->new();
  $res->redirect($self->url);

  return $res->finalize();
}


1;
