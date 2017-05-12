package Mojolicious::Plugin::RequestBase;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.3';

sub register {
  my ($self, $app, $config) = @_;

  $app->hook(
    before_dispatch => sub {
      my $c = shift;
      if (my $base = $c->req->headers->header('X-Request-Base')) {
        my $url = Mojo::URL->new($base);
        if ($url->host) {
          $c->req->url->base($url);
        }
        else {
          $c->req->url->base->path($url->path);
        }
      }
    }
  );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::RequestBase - Support setting base in frontend proxy

=head1 SYNOPSIS

=head2 Frontend proxy

The "X-Request-Base" header must be set in the frontend proxy.

  # nxinx
  proxy_set_header X-Request-Base "https://example.com/myapp";
  # or
  proxy_set_header X-Request-Base "/myapp";

=head2 Application

This plugin will read the "X-Request-Base" header.

  # Mojolicious
  $app->plugin("RequestBase");

  # Mojolicious::Lite
  plugin "RequestBase";

=head2 Controller

URL generating helpers, such as L<url_for|Mojolicious::Controller/url_for>
will create the correct URL using the base URL from C<X-Request-Base>.

Here are example with C<X-Request-Base> set to C<https://example.com/myapp>
and a request sent to Request to C<https://example.com/myapp/foo>:

  # /myapp/foo
  $c->url_for;

  # https://example.com/myapp/foo
  $c->url_for->to_abs;

  # https://example.com/myapp/some/path
  $c->url_for("/some/path")->to_abs;

  # https://example.com/foo (Probably not what you want)
  $c->req->url->to_abs;

=head2 Hooks

=head2 before_dispatch

In a L<before_dispatch|Mojolicious/HOOKS> the router has not yet started,
so you need to pass in the request path to get the expected result:

  hook before_dispatch => sub {
    my $c = shift;

    # https://example.com/myapp/foo
    $c->url_for($c->req->url->path)->to_abs;

    # https://example.com/foo (Probably not what you want)
    $c->url_for->to_abs;
  };

=head1 DESCRIPTION

Simple plugin to support Request Base header. Just load it and set
X-Request-Base in your Frontend Proxy. For instance, if you are using
nginx you could use it like this: 

  proxy_set_header X-Request-Base 'https://example.com/myapp';

Note that you can also pass a relative URL to retain the original hostname provided by the proxy.

=head1 METHODS

L<Mojolicious::Plugin::RequestBase> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Catalyst::TraitFor::Request::ProxyBase>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Marcus Ramberg.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
