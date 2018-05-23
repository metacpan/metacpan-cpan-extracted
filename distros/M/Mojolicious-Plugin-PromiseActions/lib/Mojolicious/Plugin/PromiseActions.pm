package Mojolicious::Plugin::PromiseActions;

use Mojo::Base 'Mojolicious::Plugin';

use Scalar::Util 'blessed';

our $VERSION = '0.05';

sub register {
  my ($elf, $app, $config) = @_;
  $app->hook(
    around_action => sub {
      my ($next, $c) = @_;
      my $res = $next->();
      if (blessed($res) && $res->can('then')) {
        my $tx = $c->render_later;
        $res->then(undef, sub { $c->reply->exception(pop) and undef $tx });
      }
      return $res;
    }
  );
}

1;

=head1 NAME

Mojolicious::Plugin::PromiseActions - Automatic async and error handling for Promises

=head1 SYNOPSIS

  plugin 'PromiseActions';

  get '/' => sub {
    my $c=shift;
    app->ua->get_p('ifconfig.me/all.json')->then(sub {
      $c->render(text=>shift->res->json('/ip_addr'));
    });
  };

=head1  METHODS

=head2 register

Sets up a around_dispatch hook to disable automatic rendering and
add a default catch callback to render an exception page when
actions return a L<Mojo::Promise>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Marcus Ramberg.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://github.com/kraih/mojo>, L<Mojolicious::Guides>,
L<Mojo::Promise>, L<Mojolicious::Plugin>

=cut
