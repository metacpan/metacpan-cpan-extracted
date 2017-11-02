package Mojolicious::Plugin::ForkCall;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::IOLoop::ForkCall;
use Carp;
our @CARP_NOT = qw/Mojolicious Mojolicious::Controller/;

sub register {
  my ($self, $app) = @_;

  $app->helper(fork_call => sub {
    my $c = shift;
    unless (@_ > 1 and ref $_[-1] eq 'CODE') {
      croak 'fork_call helper must be passed a callback';
    }

    my $cb = pop;
    my @args = @_;

    $c->delay(
      sub{
        my $end = shift->begin;
        my $once = sub { $end->(@_) if $end; undef $end };
        Mojo::IOLoop::ForkCall->new
          ->catch($once)
          ->run(@args, $once);
      },
      sub {
        my ($delay, $err, @return) = @_;
        die $err if $err;
        $c->$cb(@return);
      }
    );
  });
}

1;

=head1 NAME

Mojolicious::Plugin::ForkCall - run blocking code asynchronously in Mojolicious
applications by forking

=head1 SYNOPSIS

 use Mojolicious::Lite;

 plugin 'Mojolicious::Plugin::ForkCall';

 get '/slow' => sub {
   my $c = shift;
   my @args = ...;
   $c->fork_call(
     sub {
       my @args = @_;
       return do_slow_stuff(@args);
     },
     [@args],
     sub {
       my ($c, @return) = @_;
       $c->render(json => \@return);
     }
   );
 };

 ...

 app->start;

=head1 DESCRIPTION

Registering L<Mojolicious::Plugin::ForkCall> adds a helper method C<fork_call>
to your L<Mojolicious> application, making it easy to start code in a forked
process using L<Mojo::IOLoop::ForkCall>.

Note that it does not increase the timeout of the connection, so if your
forked process is going to take a very long time, you might need to increase
that using L<Mojolicious::Plugin::DefaultHelpers/inactivity_timeout>.

=head1 HELPERS

This module adds the following helper method to your application:

=head2 fork_call

 $c->fork_call(
   sub {
     my @args = @_;
     # This code is run in a forked process
     return @return;
   },
   [$arg1, $arg2, $arg3], # Optional arguments passed to the above code
   sub {
     my ($c, @return) = @_;
     # This code is run in the current process once the child exits
   }
 );

The C<fork_call> helper takes up to 3 arguments: a required code reference to
be run in a forked child process, an optional array reference of arguments to
be passed to the child code, and a required code reference to be run in the
parent as a callback. The callback is passed the controler instance and return
values of the child.

The helper relies on the L<Mojolicious> core helper
L<Mojolicious::Plugin::DefaultHelpers/delay> and as such it will render an
exception (500) page if any uncaught exception occurs in the child process or
in the parent callback. This also means that the parent callback will not be
called if the child process encounters an exception.

This helper is a convenience only and is not indended for complex cases.
If you need to configure the L<Mojo::IOLoop::ForkCall> instance or want to
"fork and forget" a child, you should use the class directly rather than this
helper. If more complicated delays are required, you should use the
L<Mojolicious::Plugin::DefaultHelpers/delay> helper or L<Mojo::IOLoop/delay>
method directly, along with an instance of L<Mojo::IOLoop::ForkCall>.

=cut

