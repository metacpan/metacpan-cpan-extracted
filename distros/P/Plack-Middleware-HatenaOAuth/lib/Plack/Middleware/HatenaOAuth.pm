package Plack::Middleware::HatenaOAuth;
use strict;
use warnings;

our $VERSION   = '0.02';

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(consumer_key consumer_secret consumer login_path);
use Plack::Request;
use Plack::Session;

use OAuth::Lite::Consumer;
use JSON::XS;

use constant +{
    SITE               => q{https://www.hatena.com},
    REQUEST_TOKEN_PATH => q{/oauth/initiate},
    ACCESS_TOKEN_PATH  => q{/oauth/token},
    AUTHORIZE_PATH     => q{https://www.hatena.ne.jp/oauth/authorize},
    USER_INFO_URL      => q{https://n.hatena.ne.jp/applications/my.json},
};

sub prepare_app {
    my ($self) = @_;
    die join(
        "\n",
        'No consumer_key or consumer_secret specified.',
        'Get one by following the instructions on http://developer.hatena.ne.jp/en/documents/auth/apis/oauth/consumer',
    ) unless $self->consumer_key and $self->consumer_secret;

    $self->consumer(OAuth::Lite::Consumer->new(
        consumer_key       => $self->consumer_key,
        consumer_secret    => $self->consumer_secret,
        site               => SITE,
        request_token_path => REQUEST_TOKEN_PATH,
        access_token_path  => ACCESS_TOKEN_PATH,
        authorize_path     => AUTHORIZE_PATH,
        ($self->{ua} ? (ua => $self->{ua}) : ()),
    ));
}

sub _get_request_token {
    my ($self, $callback_url) = @_;
    return $self->consumer->get_request_token(
        callback_url => $callback_url,
        scope        => 'read_public',
    );
}

sub _get_access_token {
    my ($self, $verifier, $request_token) = @_;
    return $self->consumer->get_access_token(
        token    => $request_token,
        verifier => $verifier,
    );
}

sub _get_user_info {
    my ($self, $access_token) = @_;
    my $res = $self->consumer->request(
        method => 'POST',
        url    => USER_INFO_URL,
        token  => $access_token,
    );
    $res->is_success or return;
    return eval { decode_json($res->decoded_content || $res->content) };
}

sub _error {
    my ($self, $code, $message) = @_;
    return [
        $code,
        [ 'Content-Type' => 'text/plain' ],
        [ $message ],
    ];
}

sub _login_handler {
    my ($self, $env) = @_;
    my $session = Plack::Session->new($env);
    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);
    my $consumer = $self->consumer;
    my $verifier = $req->parameters->{oauth_verifier};

    if (!$verifier) {
        my $request_token = $self->_get_request_token(
            [ split /\?/, $req->uri, 2]->[0],
        ) or return $self->_error(500, sprintf(
            "Could not get an OAuth request token from %s\nMessage: %s",
            SITE,
            $consumer->errstr,
        ));

        $session->set(hatenaoauth_request_token => $request_token);
        $session->set(hatenaoauth_location => $req->parameters->{location});
        $res->redirect($consumer->url_to_authorize(token => $request_token));
    } else {
        my $access_token = $self->_get_access_token(
            $verifier,
            $session->get('hatenaoauth_request_token'),
        ) or return $self->_error(500, sprintf(
            "Could not get an OAuth access token from %s\nMessage: %s",
            SITE,
            $consumer->errstr,
        ));
        $session->remove('hatenaoauth_request_token');

        my $user_info = $self->_get_user_info($access_token);
        $session->set('hatenaoauth_user_info', $user_info) if $user_info;
        $res->redirect($session->get('hatenaoauth_location') || '/');
        $session->remove('hatenaoauth_location');
    }

    return $res->finalize;
}

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);
    return $self->_login_handler($env) if $req->path eq $self->login_path;
    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::HatenaOAuth - provide a login endpoint for Hatena OAuth

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Session;

  my $app = sub {
      my $env = shift;
      my $session = Plack::Session->new($env);
      my $user_info = $session->get('hatenaoauth_user_info') || {};
      my $user_name = $user_info->{url_name};
      return [
          200,
          [ 'Content-Type' => 'text/html' ],
          [
              "<html><head><title>Hello</title><body>",
              $user_name
                  ? "Hello, id:$user_name !"
                  : "<a href='/login?location=/'>Login</a>"
          ],
      ];
  };

  builder {
      enable 'Session';
      enable 'Plack::Middleware::HatenaOAuth',
           consumer_key       => 'vUarxVrr0NHiTg==',
           consumer_secret    => 'RqbbFaPN2ubYqL/+0F5gKUe7dHc=',
           login_path         => '/login',
         # ua                 => LWP::UserAgent->new(...), # optional
           ;
      $app;
  };

=head1 DESCRIPTION

This middleware adds an endpoint to start Hatena OAuth authentication
flow to your Plack app.

=head1 CONFIGURATIONS

=over 4

=item consumer_key

=item consumer_secret

    consumer_key    => 'vUarxVrr0NHiTg=='
    consumer_secret => 'RqbbFaPN2ubYqL/+0F5gKUe7dHc='

A consumer key and consumer secret registered on L<the setting page
for developers|http://www.hatena.ne.jp/oauth/develop>.  Follow the
instructions in L<the documentation on the devloper
center|http://developer.hatena.ne.jp/en/documents/auth/apis/oauth/consumer>
for registration.

=item login_path

    login_path => '/login'

An endpoint for OAuth login, which is added to your Plack app.

=item ua

    ua => LWP::UserAgent->new(...)

A user agent to make a remote access to the OAuth server.

=back

=head1 LICENSE

Copyright (C) Hatena Co., Ltd..

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mechairoi E<lt>ttsujikawa@gmail.comE<gt>

INA Lintaro E<lt>tarao.gnn@gmail.comE<gt>

=cut
