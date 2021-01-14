package Mojo::UserAgent::SecureServer;
use Mojo::Base 'Mojo::UserAgent::Server';

use Net::SSLeay ();
use Scalar::Util qw(weaken);

our $VERSION = '0.02';

has listen => sub { Mojo::URL->new('https://127.0.0.1') };

sub from_ua {
  my $self   = ref $_[0] ? shift : shift->new;
  my $ua     = shift;
  my $server = $ua->server;

  $self->$_($server->$_) for qw(app ioloop);
  $self->listen->query->param($_ => $ua->$_) for grep { $ua->$_ } qw(ca cert key);
  $self->listen->query->param(verify => Net::SSLeay::VERIFY_PEER()) unless $ua->insecure;

  return $self;
}

sub nb_url { shift->_url(1, @_) }
sub url    { shift->_url(0, @_) }

sub _url {
  my ($self, $nb) = @_;

  my $port_key = $nb ? 'nb_port' : 'port';
  unless ($self->{$port_key}) {
    my $server_key   = $nb ? 'nb_server' : 'server';
    my $url          = $self->listen->clone;
    my @daemon_attrs = (silent => 1);
    push @daemon_attrs, ioloop => $self->ioloop unless $nb;

    my $server = $self->{$server_key} = Mojo::Server::Daemon->new(@daemon_attrs);
    weaken $server->app($self->app)->{app};
    $url->port($self->{port} || undef);
    $self->{$port_key} = $server->listen([$url->to_string])->start->ports->[0];
  }

  return Mojo::URL->new("https://127.0.0.1:$self->{$port_key}/");
}

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::SecureServer - Secure application server for Mojo::UserAgent

=head1 SYNOPSIS

  # Construct from Mojo::UserAgent
  my $ua = Mojo::UserAgent->new;
  $ua->ca('ca.pem')->cert('cert.pem')->key('key.pem');
  $ua->server(Mojo::UserAgent::SecureServer->from_ua($ua));

  # Construct manually
  my $ua     = Mojo::UserAgent->new;
  my $server = Mojo::UserAgent::SecureServer->new;
  $server->listen(Mojo::URL->new('https://127.0.0.1?cert=/x/server.crt&key=/y/server.key&ca=/z/ca.crt'));
  $ua->server($server);

  # Test::Mojo
  my $app = Mojolicious->new;
  $app->routes->get('/' => sub {
    my $c      = shift;
    my $handle = Mojo::IOLoop->stream($c->tx->connection)->handle;
    $c->render(json => {cn => $handle->peer_certificate('cn')});
  });

  my $t = Test::Mojo->new($app);
  $t->ua->insecure(0);
  $t->ua->ca('t/pki/certs/ca-chain.cert.pem')
    ->cert('t/pki/mojo.example.com.cert.pem')
    ->key('t/pki/mojo.example.com.key.pem');
  $t->ua->server(Mojo::UserAgent::SecureServer->from_ua($t->ua));

  $t->get_ok('/')->status_is(200)->json_is('/cn', 'mojo.example.com');

=head1 DESCRIPTION

L<Mojo::UserAgent::SecureServer> allows you to test your L<Mojolicious> web
application with custom SSL/TLS key/cert/ca.

=head1 ATTRIBUTES

L<Mojo::UserAgent::SecureServer> inherits all attributes from
L<Mojo::UserAgent::Server> and implements the following new ones.

=head2 listen

  $url = $server->listen;
  $server = $server->listen(Mojo::URL->new('https://127.0.0.1'));

The base listen URL for L<Mojo::Server::Daemon> created by L</nb_url> and
L</url>. The "port" will be discarded, while other
L<Mojo::Server::Daemon/listen> parameters are kept.

=head1 METHODS

L<Mojo::UserAgent::SecureServer> inherits all methods from
L<Mojo::UserAgent::Server> and implements the following new ones.

=head2 from_ua

  $server = Mojo::UserAgent::SecureServer->from_ua($ua);
  $server = $server->from_ua($ua);

Used to construct a new object and/or copy attributes from a L<Mojo::UserAgent>
object. Here is the long version:

  $server->app($ua->server->app);
  $server->ioloop($ua->server->ioloop);
  $server->listen->query->param(ca     => $ua->ca);
  $server->listen->query->param(cert   => $ua->cert);
  $server->listen->query->param(key    => $ua->key);
  $server->listen->query->param(verify => Net::SSLeay::VERIFY_PEER()) unless $ua->insecure

=head2 nb_url

  $url = $server->nb_url;

Get absolute L<Mojo::URL> object for server processing non-blocking requests
with L<Mojo::UserAgent::Server/app>.

=head2 url

  $url = $server->url;

Get absolute L<Mojo::URL> object for server processing non-blocking requests
with L<Mojo::UserAgent::Server/app>.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::UserAgent>, L<Mojo::UserAgent::Server> and L<Test::Mojo>.

=cut
