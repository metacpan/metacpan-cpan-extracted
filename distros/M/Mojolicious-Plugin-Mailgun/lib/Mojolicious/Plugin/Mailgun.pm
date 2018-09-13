package Mojolicious::Plugin::Mailgun;

use Mojo::Base 'Mojolicious::Plugin';
use Carp 'croak';

our $VERSION = '0.08';

has base_url => sub { Mojo::URL->new('https://api.mailgun.net/v3/'); };
has ua       => sub { Mojo::UserAgent->new(); };
has config   => sub { +{} };

sub register {
  my ($self, $app, $conf) = @_;
  $self->config(keys %$conf ? $conf : $app->config->{mailgun});
  $self->_test_mode($app) if $ENV{MAILGUN_TEST} // $app->mode eq 'development';
  $self->base_url($conf->{base_url}) if $conf->{base_url};
  $app->helper(
    'mailgun.send' => sub {
      my ($c, $site, $mail, $cb) = @_;
      croak "No mailgun config for $site"
        unless my $config = $self->config->{$site};
      my $url=$self->_make_url($config);
      $self->ua->post($url, form => $mail, $cb);
      return $c;
    }
  );
  $app->helper(
    'mailgun.send_p' => sub {
      my ($c, $site, $mail) = @_;
      croak "No mailgun config for $site"
        unless my $config = $self->config->{$site};
      my $url=$self->_make_url($config);
      return $self->ua->post_p($url, form => $mail);
    }
  );
}

sub _make_url {
    my ($self, $config)=@_;
      my $url = $self->base_url->clone;
      $url->path->merge($config->{domain} . '/messages');
      $url->userinfo('api:' . $config->{api_key});
      return $url;
}

sub _test_mode {
  my ($self, $app) = @_;
  $self->base_url($app->ua->server->nb_url->clone->path('/dummy/mail/'));
  $app->routes->post(
    '/dummy/mail/*domain/messages' => sub {
      my $c = shift;
      $c->render(json =>
          {id => 1, params => $c->req->params->to_hash, url => $c->req->url->to_abs});
    }
  );
}


1;

=head1 NAME

Mojolicious::Plugin::Mailgun - Easy Email sending with mailgun

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'mailgun' => { mom => {
    api_key => '123',
    domain => 'mom.no',
  }};

  # Mojolicious
  $self->plugin(mailgun => { mom => {
    site => {
      api_key => '123',
      domain => 'mom.no',
  }});

  # in controller named params
  $self->mailgun->send( mom => {
    recipient => 'pop@pop.com',
    subject   => 'use Perl or die;'
    html      => $html,
    inline    => { file => 'public/file.png' },
    sub { my $self,$res = shift },  # receives a Mojo::Transaction from mailgun.
  );


=head1 DESCRIPTION

Provides a quick and easy way to send email using the Mailgun API with support for
multiple user agents.

=head1 OPTIONS

L<Mojolicious::Plugin::Mailgun> can be provided a hash of mailgun sites with
C<api_key> and C<domain>, or it can read them directly from
$c->config->{mailgun} if not provided at load time.


=head1 HELPERS

L<Mojolicious::Plugin::Mailgun> implements one helper.

=head2 mailgun->send <$site>, <\%post_options>, <$cb>

Send a mail with the mailgun API. This is just a thin wrapper around
Mojo::UserAgent to handle authentication settings. See the mailgun sending
documentation for more information about the supported arguments to the
post_options hash. This API can only be used non-blocking, so the callback is
required.

L<https://documentation.mailgun.com/api-sending.html#sending>

=head1 METHODS

L<Mojolicious::Plugin::Mailgun> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones.

=head2 C<register>

$plugin->register;

Register plugin hooks and helpers in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Marcus Ramberg <mramberg@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2017 by Marcus Ramberg.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
