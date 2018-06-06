package Mojolicious::Plugin::Subprocess;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::IOLoop;
use Mojo::Promise;

our $VERSION = '1.001';

sub register {
  my ($self, $app, $options) = @_;
  
  my %subprocess_args = %{$options // {}};
  my $use_sereal = delete $subprocess_args{use_sereal};
  
  $app->helper(subprocess => sub {
    my ($c, $child, $parent) = @_;
    
    my $subprocess = Mojo::IOLoop->subprocess;
    $subprocess->$_($subprocess_args{$_}) for
      grep { exists $subprocess_args{$_} } qw(deserialize ioloop serialize);
    $subprocess->with_roles('Mojo::IOLoop::Subprocess::Role::Sereal')
      ->with_sereal if $use_sereal;

    my $tx = $c->render_later->tx;

    my $p = Mojo::Promise->new;
    $subprocess->run($child, sub {
      my ($subprocess, $err, @results) = @_;
      return $p->reject($err) if $err;
      $p->resolve(@results);
    });

    return $p->then(sub { $c->$parent(@_) })
      ->catch(sub { $c->helpers->reply->exception(pop) and undef $tx });
  });
}

1;

=head1 NAME

Mojolicious::Plugin::Subprocess - Subprocesses in Mojolicious applications

=head1 SYNOPSIS

  use Mojolicious::Lite;
  
  plugin 'Subprocess';
  
  get '/slow' => sub {
    my $c = shift;
    $c->subprocess(sub {
      return do_slow_stuff();
    }, sub {
      my ($c, @results) = @_;
      $c->render(json => \@results);
    });
  };
  
  # or use Sereal as serializer
  plugin 'Subprocess' => {use_sereal => 1};

=head1 DESCRIPTION

L<Mojolicious::Plugin::Subprocess> is a L<Mojolicious> plugin that adds a
L</"subprocess"> helper method to your application, which uses
L<Mojo::IOLoop::Subprocess> to perform computationally expensive operations in
subprocesses without blocking the event loop.

The option C<use_sereal> (requires L<Mojo::IOLoop::Subprocess::Role::Sereal>)
will use L<Sereal> for data serialization, which is faster than L<Storable> and
supports serialization of more reference types such as C<Regexp>. The
L<Sereal::Encoder/"FREEZE/THAW CALLBACK MECHANISM"> is supported to control
serialization of blessed objects.

Any other options passed to the plugin will be used as attributes to build the
L<Mojo::IOLoop::Subprocess> object.

Note that it does not increase the timeout of the connection, so if your forked
process is going to take a very long time, you might need to increase that
using L<Mojolicious::Plugin::DefaultHelpers/"inactivity_timeout">.

=head1 HELPERS

L<Mojolicious::Plugin::Subprocess> implements the following helpers.

=head2 subprocess

 $c->subprocess(sub {
   my $subprocess = shift;
   ...
 }, sub {
   my ($c, @results) = @_;
   ...
 });

Execute the first callback in a child process with
L<Mojo::IOLoop::Subprocess/"run">, and execute the second callback in the
parent process with the results. Automatic rendering is disabled, and an
exception response is rendered if an exception is thrown in either callback.
This also means that the parent callback will not be called if an exception is
thrown in the child callback.

=head1 METHODS

L<Mojolicious::Plugin::Subprocess> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

 $plugin->register(Mojolicious->new);
 $plugin->register(Mojolicious->new, {ioloop => $ioloop});

Register helper in L<Mojolicious> application.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::IOLoop::Subprocess>, L<Mojolicious::Plugin::ForkCall>
