package Mojolicious::Plugin::FastHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util 'monkey_patch';

use constant DEBUG => $ENV{MOJO_FASTHELPERS_DEBUG} || 0;

our $VERSION = '0.02';

sub register {
  my ($self, $app, $config) = @_;

  $self->_add_helper_classes;
  $self->_monkey_patch_add_helper($app);
}

sub _monkey_patch_add_helper {
  my ($self, $app) = @_;
  my $renderer = $app->renderer;

  # Add any helper that has been added already
  _add_helper_method($_) for sort map { (split /\./, $_)[0] } keys %{$renderer->helpers};

  state $patched = {};
  return if $patched->{ref($renderer)}++;

  # Add new helper methods when calling $app->helper(...)
  my $orig = $renderer->can('add_helper');
  monkey_patch $renderer => add_helper => sub {
    my ($renderer, $name) = (shift, shift);
    _add_helper_method($name);
    $orig->($renderer, $name, @_);
  };
}

sub _add_helper_classes {
  my $self = shift;

  for my $class (qw(Mojolicious Mojolicious::Controller)) {
    my $helper_class = "${class}::_FastHelpers";
    next if UNIVERSAL::isa($class, $helper_class);
    eval "package $helper_class;1" or die $@;

    monkey_patch $class => can => sub {
      my ($self, $name, @rest) = @_;
      return undef unless my $can = $self->SUPER::can($name, @rest);
      return undef if $can eq ($helper_class->can($name) // '');    # Hiding helper methods from can()
      return $can;
    };

    no strict 'refs';
    unshift @{"${class}::ISA"}, $helper_class;
  }
}

sub _add_helper_method {
  my $name = shift;
  return if Mojolicious::_FastHelpers->can($name);                  # No need to add it again

  monkey_patch 'Mojolicious::_FastHelpers' => $name => sub {
    my $app = shift;
    Carp::croak qq/Can't locate object method "$name" via package "@{[ref $app]}"/
      unless my $helper = $app->renderer->get_helper($name);
    return $app->build_controller->$helper(@_);
  };

  monkey_patch 'Mojolicious::Controller::_FastHelpers' => $name => sub {
    my $c = shift;
    my $p = $c->{_FastHelpers} ||= $c->app->renderer->get_helper('')->($c);
    Carp::croak qq/Can't locate object method "$name" via package "@{[ref $c]}"/ unless $p->can($name);
    return $p->$name(@_);
  };
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::FastHelpers - Faster helpers for your Mojolicious application

=head1 SYNOPSIS

=head2 Lite app

  use Mojolicious::Lite;
  plugin "FastHelpers";
  app->start;

=head1 DESCRIPTION

L<Mojolicious::Plugin::FastHelpers> is a L<Mojolicious> plugin which can speed
up your helpers, by avoiding C<AUTOLOAD>.

It does this by injecting some new classes into the inheritance tree of
L<Mojolicious> and L<Mojolicious::Controller>.

=head2 Warning

This module must be considered EXPERIMENTAL. There might even be some security
isseus, so use it with care.

It is not currently used in production anywhere I know of, and I'm not sure if
I can endorce such usage.

This is strictly a (unproven) proof of concept.

=head2 Benchmarks

There is a benchmark test bundled with this distribution, if you want to run it
yourself, but here is a quick overview:

  $ TEST_BENCHMARK=200000 prove -vl t/benchmark.t
  ok 1 - App::Normal 2.08688 wallclock secs ( 2.08 usr +  0.00 sys =  2.08 CPU) @ 96153.85/s (n=200000)
  ok 2 - Ctrl::Normal 0.654221 wallclock secs ( 0.65 usr +  0.00 sys =  0.65 CPU) @ 307692.31/s (n=200000)
  ok 3 - App::FastHelpers 1.62765 wallclock secs ( 1.62 usr + -0.01 sys =  1.61 CPU) @ 124223.60/s (n=200000)
  ok 4 - Ctrl::FastHelpers 0.131942 wallclock secs ( 0.13 usr +  0.00 sys =  0.13 CPU) @ 1538461.54/s (n=200000)
  ok 5 - App::FastHelpers (1.61s) is not slower than App::Normal (2.08s)
  ok 6 - Ctrl::FastHelpers (0.13s) is not slower than Ctrl::Normal (0.65s)

                         Rate App::Normal App::FastHelpers Ctrl::Normal Ctrl::FastHelpers
  App::Normal         96154/s          --             -23%         -69%              -94%
  App::FastHelpers   124224/s         29%               --         -60%              -92%
  Ctrl::Normal       307692/s        220%             148%           --              -80%
  Ctrl::FastHelpers 1538462/s       1500%            1138%         400%                --

=head1 METHODS

=head2 register

Will create new classes for your application and
L<Mojolicious/controller_class>, and monkey patch in all the helpers.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>

=cut
