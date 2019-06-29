package TestApp;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self   = shift;
  my $r      = $self->routes;
  my $config = $self->config->{trustedproxy} || {};

  $self->plugin('TrustedProxy' => $config);

  # Returns current value of tx->remote_proxy_address
  $r->get(
    '/proxyip' => sub {
      my $c = shift;
      $c->render(text => $c->tx->remote_proxy_address || '');
    }
  );

  # Returns current value of tx->remote_address
  $r->get(
    '/ip' => sub {
      my $c = shift;
      $c->render(text => $c->tx->remote_address);
    }
  );

  # Returns current connection scheme as 'http' or 'https'
  $r->get(
    '/scheme' => sub {
      my $c = shift;
      $c->render(text => $c->req->is_secure ? 'https' : 'http');
    }
  );

  # Returns current request host
  $r->get(
    '/host' => sub {
      my $c = shift;
      $c->render(text => $c->req->url->base->host);
    }
  );

  # Returns all header names
  $r->get(
    '/headers' => sub {
      my $c = shift;
      $c->render(json => $c->req->headers->names);
    }
  );

  # Returns all values (User agent IP, proxy IP, scheme, headers)
  $r->get(
    '/all' => sub {
      my $c = shift;
      $c->render(json => {
        ua_ip    => $c->tx->remote_address,
        proxy_ip => $c->tx->remote_proxy_address,
        scheme   => $c->req->is_secure ? 'https' : 'http',
        host     => $c->req->url->base->host,
        headers  => $c->req->headers->names,
      });
    }
  );
}

1;
