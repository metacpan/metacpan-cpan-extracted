package Mojolicious::Plugin::Model;
use Mojo::Base 'Mojolicious::Plugin';

use List::Util 'any';
use Mojo::Loader ();
use Mojo::Util 'camelize';

our $VERSION = '0.11';

sub register {
  my ($plugin, $app, $conf) = @_;

  $app->helper(
    model => sub {
      my ($self, $name) = @_;
      $name //= $conf->{default};

      my $model;
      return $model if $model = $plugin->{models}{$name};

      my $class = _load_class_for_name($plugin, $app, $conf, $name)
        or return undef;

      my $params = $conf->{params}{$name};
      $model = $class->new(ref $params eq 'HASH' ? %$params : (), app => $app);
      $plugin->{models}{$name} = $model;
      return $model;
    }
  );

  $app->helper(
    entity => sub {
      my ($self, $name) = @_;
      $name //= $conf->{default};

      my $class = _load_class_for_name($plugin, $app, $conf, $name)
        or return undef;

      my $params = $conf->{params}{$name};
      return $class->new(ref $params eq 'HASH' ? %$params : (), app => $app);
    }
  );

}

sub _load_class {
  my $class = shift;

  my $error = Mojo::Loader->can('new') ? Mojo::Loader->new->load($class) : Mojo::Loader::load_class($class);

  return 1 unless $error;
  die $error if ref $error;
  return;
}

sub _load_class_for_name {
  my ($plugin, $app, $conf, $name) = @_;
  return $plugin->{classes_loaded}{$name} if $plugin->{classes_loaded}{$name};

  my $ns   = $conf->{namespaces}   // [camelize($app->moniker) . '::Model'];
  my $base = $conf->{base_classes} // [qw(MojoX::Model)];

  $name = camelize($name) if $name =~ /^[a-z]/;

  for my $class ( map "${_}::$name", @$ns ) {
    next unless _load_class($class);

    unless ( any { $class->isa($_) } @$base ) {
      $app->log->debug(qq[Class "$class" is not a model]);
      next;
    }
    $plugin->{classes_loaded}{$name} = $class;
    return $class;
  }
  $app->log->debug(qq[Model "$name" does not exist]);
  return undef;
};

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Model - Model for Mojolicious applications

=head1 SYNOPSIS

Model Users

  package MyApp::Model::Users;
  use Mojo::Base 'MojoX::Model';

  sub check {
    my ($self, $name, $pass) = @_;

    # Constant
    return int rand 2;

    # Or Mojo::Pg
    return $self->app->pg->db->query('...')->array->[0];

    # Or HTTP check
    return $self->app->ua->post($url => json => {user => $name, pass => $pass})
      ->rex->tx->json('/result');
  }

  1;

Model Users-Client

  package MyApp::Model::Users::Client;
  use Mojo::Base 'MyApp::Model::User';

  sub do {
    my ($self) = @_;
  }

  1;

Mojolicious::Lite application

  #!/usr/bin/env perl
  use Mojolicious::Lite;

  use lib 'lib';

  plugin 'Model';

  # /?user=sebastian&pass=secr3t
  any '/' => sub {
    my $c = shift;

    my $user = $c->param('user') || '';
    my $pass = $c->param('pass') || '';

    # client model
    my $client = $c->model('users-client');
    $client->do();

    return $c->render(text => "Welcome $user.") if $c->model('users')->check($user, $pass);
    $c->render(text => 'Wrong username or password.');
  };

  app->start;

All available options

  #!/usr/bin/env perl
  use Mojolicious::Lite;

  plugin Model => {
    namespaces   => ['MyApp::Model', 'MyApp::CLI::Model'],
    base_classes => ['MyApp::Model'],
    default      => 'MyApp::Model::Pg',
    params => {Pg => {uri => 'postgresql://user@/mydb'}}
  };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Model> is a Model (M in MVC architecture) for Mojolicious applications. Each
model has an C<app> attribute.

=head1 OPTIONS

L<Mojolicious::Plugin::Model> supports the following options.

=head2 namespaces

  # Mojolicious::Lite
  plugin Model => {namespaces => ['MyApp::Model']};

Namespace to load models from, defaults to C<$moniker::Model>.

=head2 base_classes

  # Mojolicious::Lite
  plugin Model => {base_classes => ['MyApp::Model']};

Base classes used to identify models, defaults to L<MojoX::Model>.

=head2 default

  # Mojolicious::Lite
  plugin Model => {default => 'MyModel'};

  any '/' => sub {
    my $c = shift();
    $c->model->do(); # used model MyModel
    # ...
  }

The name of the default model to use if the name of the current model not
specified.

=head2 params

  # Mojolicious::Lite
  plugin Model => {params => {DBI => {dsn => 'dbi:mysql:mydb'}}};

Parameters to be passed to the class constructor of the model.

=head1 HELPERS

L<Mojolicious::Plugin::Model> implements the following helpers.

=head2 model

  my $model = $c->model($name);

Load, create and cache a model object with given name. Default class for
model C<camelize($moniker)::Model>. Return C<undef> if model not found.

=head2 entity

  my $disposable_model = $c->entity($name);

Create a new model object with given name. Default class for
model C<camelize($moniker)::Model>. Return C<undef> if model not found.
Use C<entity> instead of C<model> when you need stateful objects.

=head1 METHODS

L<Mojolicious::Plugin::Model> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Andrey Khozov, C<avkhozov@googlemail.com>.

=head1 CONTRIBUTORS

Alexey Stavrov, C<logioniz@ya.ru>.

Denis Ibaev, C<dionys@gmail.com>.

Eugen Konkov, C<kes-kes@yandex.ru>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017, Andrey Khozov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
