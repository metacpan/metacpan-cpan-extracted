package _inject_plugin;
use strict;
use warnings;
no warnings 'redefine';

my $org = \&Mojolicious::new;
*Mojolicious::new = sub {
  my $self = $org->(@_);
  $self->plugin(plack_middleware => []);
  $self;
};

=memo

* Copy the lates mojo tests into ./compat/

* Replace

  s{use Mojolicious;}{use Mojolicious; use _inject_plugin}g;
  s{use Mojolicious::Lite;}{use Mojolicious::Lite; plugin plack_middleware => []}g;
  s{use Mojo::Base 'Mojolicious';}{use Mojo::Base 'Mojolicious' use _inject_plugin}g;

* prove with plugin injector

  prove -rl -Ixt/lib xt

=app