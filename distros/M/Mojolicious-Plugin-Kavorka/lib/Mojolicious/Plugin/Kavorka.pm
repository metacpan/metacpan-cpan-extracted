package Mojolicious::Plugin::Kavorka;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

use Kavorka;

method register ($app, $config) {
  $app->hook(around_action => \&_around_action);
}

fun _around_action ($next, $c, $action, $last) {
  if (my $info = Kavorka->info($action)) {
    my $sig = $info->signature;
    my @args;
    for my $param ($sig->positional_params, $sig->named_params) {
      my $name = $param->name;
      my $sigil = $param->sigil;
      $name =~ s/^\Q$sigil//;
      push @args, $name if $param->named;
      push @args, $c->stash($name);
    }
    $c->$action(@args);
  } else {
    $next->();
  }
}

1;

=head1 NAME

Mojolicious::Plugin::Kavorka - Signature sugar for your Mojolicious controller actions

=head1 SYNOPSIS

  use Mojolicious::Lite;
  use Kavorka;

  plugin 'Kavorka';

  get '/:name' => method ($name) {
    $self->render("Hello $name!");
  }

  app->start;

=head1 DESCRIPTION

L<Kavorka> lets you define methods with introspectable signatures.
Using that extra knowledge can make your controller methods clearer and friendlier.
L<Mojolicious::Plugin::Kavorka> sits in your dispatch layer and if a target controller method (action) was declared with L<Kavorka> it will extract stash variables of the same name and pass them to the method.

This plugin is a very rough release, I'm not sure what functionality should be added nor what semantics it should have.
Consider it very experimental.
That said, this is a rich testbed for future functionality; if you have ideas or suggestions, please let me know!

=head1 SEE ALSO

=over

=item L<Kavorka>

=item L<Moops>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-Kavorka>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

