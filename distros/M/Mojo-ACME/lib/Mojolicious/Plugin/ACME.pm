package Mojolicious::Plugin::ACME;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util qw/hmac_sha1_sum secure_compare/;
use Safe::Isa '$_isa';

use Mojo::ACME::CA;

my %authorities = (
  letsencrypt => {
    agreement => 'https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf',
    name => q[Let's Encrypt],
    intermediate => 'https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem',
    primary_url => Mojo::URL->new('https://acme-v01.api.letsencrypt.org'),
    test_url    => Mojo::URL->new('https://acme-staging.api.letsencrypt.org'),
  },
);

sub register {
  my ($plugin, $app) = @_;
  my $config = $app->config->{acme} ||= {}; #die 'no ACME config found';

  %{ $config->{authorities} } = (%authorities, %{ $config->{authorities} || {} }); # merge default CAs #}# highlight fix
  $config->{ca} ||= 'letsencrypt';
  if (ref $config->{ca}) {
    $config->{ca} = Mojo::ACME::CA->new($config->{ca})
      unless $config->{ca}->$_isa('Mojo::ACME::CA');
  } else {
    die 'Unknown CA'
      unless my $spec = $config->{authorities}{$config->{ca}};
    $config->{ca} = Mojo::ACME::CA->new($spec);
  }

  my $url = Mojo::URL->new($config->{challenge_url} ||= 'http://127.0.0.1:5000');

  push @{ $app->commands->namespaces }, 'Mojolicious::Plugin::ACME::Command';

  my $ua = Mojo::UserAgent->new;
  $app->routes->get('/.well-known/acme-challenge/:token' => sub {
    my $c = shift;
    my $token = $c->stash('token');
    my $secret = $c->app->secrets->[0];
    my $hmac = hmac_sha1_sum $token, $secret;
    $c->delay(
      sub { $ua->get($url->clone->path("/$token"), {'X-HMAC' => $hmac}, shift->begin) },
      sub {
        my ($delay, $tx) = @_;
        return $c->reply->not_found
          unless $tx->success && (my $auth = $tx->res->text) && (my $hmac_res = $tx->res->headers->header('X-HMAC'));
        return $c->reply->not_found
          unless secure_compare $hmac_res, hmac_sha1_sum($auth, $secret);

        $c->render(text => $auth);
      },
    );
  });
}

1;

=head1 NAME

Mojolicious::Plugin::ACME - ACME client integration for your Mojolicious app

=head1 SYNOPSIS

  use Mojolicious::Lite;

  # optionally load config in application config
  # shown directly below but config plugins work too
  my %acme = (...);
  app->config->{acme} = \%acme;

  plugin 'ACME';

=head1 DESCRIPTION

Establishes a route at the top level of your application to handle the challenge request from the application server.
Also loads configuration which is reused at multiple levels of the ACME cycle.

=head1 CONFIGURATION

L<Mojolicious::Plugin::ACME> is configured via a key named C<acme> in your application's L<config|Mojo/config> method.
The value should be a hash reference of configuration.
If one is not passed in, one will be created for later inspection.

The recognized keys within that hash are:

=head2 authorities

A hash reference containing keys which identify certificate authorities used by L</ca> and values which can be used to initialize an instance of L<Mojo::ACME::CA>.
Any hashreference provided will be merged on top of the defaults which currently contains one entry: C<letsencrypt>.

=head2 ca

The certificate authority to use for issuance.
This may be a hash reference suitable for constructing an instance of L<Mojo::ACME::CA>, a pre-initialized instance or subclass thereof, or else a string.
In the case of a string, this key must exist in L</authorities>.
The default is the string C<letsencrypt>.

=head2 challenge_url

A url suitable to be passed to L<Mojo::Server::Daemon/listen>.
This url is used by the client and server for the application server to forward challenge requests.
The default is C<127.0.0.1:5000>.

=head1 NOTES

Please note that the application's first L<secret|Mojolicious/secrets> is used as a mechanism of signing messages between the ACME client and the application server.
This may be configurable eventually but is not yet.

Early versions of this module used the name C<cas> rather than L</authorities>.

