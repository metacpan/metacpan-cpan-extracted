package Mojo::Promisify;
use Mojo::Base -strict;

use Exporter 'import';
use Mojo::Promise;
use Mojo::Util 'monkey_patch';

our @EXPORT_OK = qw(promisify promisify_call promisify_patch);
our $VERSION = '0.01';

sub promisify {
  my ($obj, $method) = @_;

  return sub {
    my @args = @_;
    my $p    = Mojo::Promise->new;

    eval {
      $obj->$method(
        @args,
        sub {
          my ($obj, $err) = (shift, shift);
          return $err ? $p->reject($err) : $p->resolve(@_);
        }
      );
      1;
    } or do {
      $p->reject($@);
    };

    return $p;
  };
}

sub promisify_call {
  my ($obj, $method, @args) = @_;
  return promisify($obj => $method)->(@args);
}

sub promisify_patch {
  my ($class, @methods) = @_;

  for my $method (@methods) {
    monkey_patch $class => "${method}_p" => sub {
      my ($obj, @args) = @_;
      my $p = Mojo::Promise->new;

      eval {
        $obj->$method(
          @args,
          sub {
            my ($obj, $err) = (shift, shift);
            return $err ? $p->reject($err) : $p->resolve(@_);
          }
        );
        1;
      } or do {
        $p->reject($@);
      };

      return $p;
    };
  }
}

1;

=encoding utf8

=head1 NAME

Mojo::Promisify - Convert callback code to promise based code

=head1 SYNOPSIS

  use Mojo::Promisify qw(promisify_call promisify_patch);
  use Some::NonBlockingClass;

  # Create an object from a callback based class
  my $nb_obj = Some::NonBlockingClass->new;

  # Call a callback based method, but return a Mojo::Promise
  promisify_call($nb_obj => get_stuff_by_id => 42)->then(sub {
    my @res = shift;
    warn @res;
  })->catch(sub {
    my $err = shift;
    die $err;
  });

  # Add a method that wraps around the callback based method and return a
  # Mojo::Promise.
  promisify_patch "Some::NonBlockingClass" => "get_stuff_by_id";

  # The added method has the "_p" suffix
  $nb_obj->get_stuff_by_id_p(42)->then(sub {
    my @res = shift;
    warn @res;
  });

=head1 DESCRIPTION

L<Mojo::Promisify> is a utility module that can upgrade your legacy callback
based API to a L<Mojo::Promise> based API.

It might not be the most efficient way to run your code, but it will allow
you to easily add methods that will return promises.

This method only works with methods that passes on C<$err> as the first argument
to the callback, like this:

  sub get_stuff_by_id {
    my ($self, $id, $cb) = @_;

    my $err = "Some error";
    my $res = undef;
    Mojo::IOLoop->next_tick(sub { $self->$cb($err, $res) });

    return $self;
  }

It can however pass on as many arguments as it wants after the C<$err> and all
will be passed on to the fulfillment callback in the promise. C<$err> on the
other hand will cause the promise to be rejected.

Note that this module is currently EXPERIMENTAL, but it will most probably not
change much.

=head1 FUNCTIONS

=head2 promisify

  $code = promisify($obj => $method);
  $promise = $code->(@args);

Will return a curried function that wraps around a given C<$method> in a
C<$class> and returns a promise. C<@args> are the same arguments you would
normally give to the C<$method>, but without the callback at the end.

It can be useful to use this function instead of L</promisify_call>, in case
you want to call the same C<$method> on the I<same> object over and over again.

=head2 promisify_call

  $promise = promisify_call($obj => $method, @args);

This function basically does:

  my $promise = promisify($obj => $method)->(@args);

=head2 promisify_patch

  promisify_patch $class, @methods;

Used to monkey patch a class with new promise based methods. The methods that
are patched in, will have the "_p" suffix added.

Note that this function I<will> replace existing methods!

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::Promise>

=cut
