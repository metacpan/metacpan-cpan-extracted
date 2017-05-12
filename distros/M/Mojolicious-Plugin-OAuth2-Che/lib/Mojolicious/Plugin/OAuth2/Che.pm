package Mojolicious::Plugin::OAuth2::Che;

use Mojo::Base 'Mojolicious::Plugin::OAuth2';
use Carp 'croak';

sub register {
  my ($self, $app, $config) = @_;
  #~ my $providers = $self->providers;

  #~ while ( my ($name, $vals) = each %$config ) {
    #~ @{ $providers->{$name} ||= {} }{ keys %$vals } = values %$vals;
  #~ }

  $self->SUPER::register($app, $config);

  $app->helper('oauth2.process_tx'  => sub {shift; $self->_process_tx(@_) });
}

sub _get_auth_token {
  my ($self, $tx, $nb) = @_;
  my ($data, $err) = $self->_process_tx($tx);

  die $err || 'Unknown error'
    if $err || !$data || !$nb;

  my $token = $data->{access_token}
    or die "No access_token in auth response data broken";
  return $token, $tx;
}

sub _process_response_code {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my ($self, $c, $provider_id, $args) = @_;
  my $provider  = $self->providers->{$provider_id} or croak "[code] Unknown OAuth2 provider $provider_id";
  my $token_url = Mojo::URL->new($provider->{token_url});
  my $params    = {
    client_secret => $provider->{secret},
    client_id     => $provider->{key},
    code          => scalar($c->param('code')),
    grant_type    => 'authorization_code',
    redirect_uri  => $args->{redirect_uri} || $c->url_for->to_abs->to_string,
  };

  $token_url->host($args->{host}) if exists $args->{host};

  if ($cb) {
    return $c->delay(
      sub {
        my ($delay) = @_;
        $self->_ua->post($token_url->to_abs, form => $params => $delay->begin);
      },
      sub {
        my ($delay, $tx) = @_;
        my ($data, $err) = $self->_process_tx($tx);

        $c->$cb($data ? '' : $err || 'Unknown error', $data);
      },
    );
  }
  else {
    my $tx = $self->_ua->post($token_url->to_abs, form => $params);
    my ($data, $err) = $self->_process_tx($tx);

    die $err || 'Unknown error' if $err or !$data;

    return $data;
  }
}

sub _process_tx {
  my ($self, $tx) = @_;
  my ($data, $err);
  if ($err = $tx->error) {
    $err = $err->{message} || $err->{code};
  }
  elsif ($tx->res->headers->content_type =~ m!^(application/json|text/javascript)(;\s*charset=\S+)?$!) {
    $data = $tx->res->json;
  }
  else {
    $data = Mojo::Parameters->new($tx->res->body)->to_hash;
  }
  return $data, $err;
}


=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::OAuth2::Che

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::OAuth2::Che -  forked from marcusramberg/Mojolicious-Plugin-OAuth2 version 1.53. No logic changes. Code text changes only for processing any response tx of API.

=head1 VERSION

Version 1.539

=cut

our $VERSION = '1.539';


=head1 SYNOPSIS

See L<Mojolicious::Plugin::OAuth2>

=head1 ADDITIONAL HELPERS

=head2 oauth2.process_tx

This helper is usefull for processing any API json response:

  my $tx = $c->app->ua->get($profile_url); # blocking example
  my ($data, $err) = $c->oauth2->process_tx($tx);


=head1 SEE ALSO

L<Mojolicious::Plugin::OAuth2>


=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-OAuth2-Che/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

1; # End of Mojolicious::Plugin::OAuth2::Che
