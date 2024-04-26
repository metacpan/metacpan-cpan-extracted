package Mojolicious::Plugin::Authentication::OIDC::Controller::OpenIDConnect 0.01;
use v5.26;

# ABSTRACT: OpenID controller endpoints implementation

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Authentication::OIDC::Controller::OpenIDConnect - controller
endpoints for OpenID Connect authentication

=head1 DESCRIPTION

This is a simple mojolicious controller that implements the endpoints necessary
for OpenID Connect authentication. These endpoints must be registered as routes
to function, which can be done implicity by 
L<Mojolicious::Plugin::Authentication::OIDC/make_routes>

=head1 METHODS

L<Mojolicious::Plugin::Authentication::OIDC::Controller::OpenIDConnect> inherits
all methods from L<Mojolicious::Controller> and implements the following new ones

=head2 redirect

Returns an HTTP 302, redirecting the client to the auhorization server's 
C<authorization_endpoint> with the proper parameters populated for an openid
code response, and then to redirect to L</login>

=head2 login

Contacts the authorization server to receive an access token for the OpenID
authenticated user. Calls the 
L<Mojolicious::Plugin::Authentication::OIDC/on_success> or
L<Mojolicious::Plugin::Authentication::OIDC/on_error> handles, as apprporiate.

=cut

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Parameters;
use Mojo::UserAgent;
use Syntax::Keyword::Try;

use experimental qw(signatures);

my sub make_app_url($self, $path = '/') {
  my $url = $self->tx->req->url->to_abs->clone;
  $url->fragment(undef);
  $url->query(Mojo::Parameters->new);
  $url->path($path);
}

sub redirect($self) {
  my $idp_url = Mojo::URL->new($self->_oidc_params->{auth_endpoint});
  $idp_url->query(
    {
      client_id     => $self->_oidc_params->{client_id},
      scope         => $self->_oidc_params->{scope},
      response_type => $self->_oidc_params->{response_type},
      redirect_uri  => make_app_url($self, $self->_oidc_params->{login_path}),
    }
  );
  $self->redirect_to($idp_url);
}

sub login($self) {
  my $code = $self->param('code');
  my $ua   = Mojo::UserAgent->new();
  my $url  = Mojo::URL->new($self->_oidc_params->{token_endpoint})
    ->userinfo(join(':', $self->_oidc_params->{client_id}, $self->_oidc_params->{client_secret}));

  my $resp = $ua->post(
    $url => form => {
      grant_type   => $self->_oidc_params->{grant_type},
      code         => $code,
      redirect_uri => make_app_url($self, $self->_oidc_params->{login_path}),
    }
  );

  if ($resp->res->json->{error}) {
    return $self->_oidc_params->{on_error}->($self, $resp->res->json);
  } else {
    try {
      my $token = $resp->res->json->{access_token};
      # Decode the token; if it fails, because the key is wrong, or the token
      # is invalid or has been re-encrypted, then we throw it away and call
      # error handler
      $self->_oidc_token($token);
      return $self->_oidc_params->{on_success}->($self, $token);
    } catch ($e) {
      $self->log->error($e);
      $self->_oidc_params->{on_error}->($self, $resp->res->json);
    }
  }
}

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
