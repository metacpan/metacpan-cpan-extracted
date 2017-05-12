package Plack::Middleware::Auth::AccessToken;
{
  $Plack::Middleware::Auth::AccessToken::VERSION = '0.11';
}
#ABSTRACT: Secret access token (aka OAuth Bearer) authentification

use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(authenticator token_type reject_http);
use Plack::Util ();
use Plack::Request;

sub prepare_app {
    my $self = shift;

    die 'authenticator must be a code reference'
        unless (ref $self->authenticator || '') eq 'CODE';

    $self->token_type('bearer')
        unless defined $self->token_type;

    die 'reject_http should be a code reference'
        if (ref $self->reject_http and ref $self->reject_http ne 'CODE');
}

sub call {
    my ($self, $env) = @_;

    my $token;

    if (my $auth = $env->{HTTP_AUTHORIZATION}) {
        my $token_type = $self->token_type;
        $token = $1 if $auth =~ /^\s*$token_type\s+(.+)/i;
    } else {
        my $req = Plack::Request->new($env);
        $token = $req->query_parameters->get('access_token');
    }

    if (defined $token) {
        if ($self->reject_http and $env->{'psgi.url_scheme'} eq 'http') {
            $self->reject_http->($token);
        } elsif ($self->authenticator->($token, $env)) {
            return $self->app->($env);
        }
    } else {
        return $self->unauthorized;
    }

    return $self->unauthorized('Bad credentials')
}

sub unauthorized {
    my $self = shift;
    my $body = shift || 'Authorization required';

    return [ 401,
        [ 'Content-Type' => 'text/plain',
          'Content-Length' => length $body ], [ $body ] ];
}

1;

__END__

=pod

=head1 NAME

Plack::Middleware::Auth::AccessToken - Secret access token (aka OAuth Bearer) authentification

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    use Plack::Middleware::Auth::AccessToken;
    use Plack::Builder;

    my $app = sub { ... };

    builder {
        enable "Auth::AccessToken",
            authenticator => \&check_token;
        $app;
    };

    sub check_token {
        my $token = shift;
        return $token eq 'a02655d46dd0f2160529acaccd4dbf979c6e6e50'; 
    }

=head1 DESCRIPTION

Plack::Middleware::Auth::AccessToken is authentification handler for Plack that
uses a secret access token. Access tokens are also known as OAuth Bearer tokens.
Tokens can be provided both in a HTTP request header or as query parameter:

    https://example.org/api
    Authorization: bearer ACCESS_TOKEN

    https://example.org/api?access_token=ACCESS_TOKEN

The former is recommended because query parameters may show up on log files.

This middleware checks the access token via a callback function and returns an
error document with HTTP code 401 on failure.

=head1 CONFIGURATION

=over 4

=item authenticator

A required callback function that takes an access token and returns whether the
token is valid. The PSGI environment is passed as second argument, but making
use of it should be bad practice.

=item token_type

Used to compare the authorization header. For instance the value 'token' will
make the middleware look for a header such as:

    Authorization: token ACCESS_TOKEN

The token type is case-insensitive and set to 'bearer' by default.

=item reject_http

An optional callback function that takes an access token that has been sent
unencryptedly over HTTP. If this parameter has been set, a HTTP request is
rejected without first consulting the authentificator. The callback function
can be used to mark the access token as invalid.

=back

=head1 SEE ALSO

See L<Plack::Middleware::Auth::OAuth2::ProtectedResource> and
L<Plack::Middleware::OAuth> for modules that take more care to implement OAuth.

=encoding utf8

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
