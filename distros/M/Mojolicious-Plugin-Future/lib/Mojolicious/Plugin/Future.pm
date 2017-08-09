package Mojolicious::Plugin::Future;
use Mojo::Base 'Mojolicious::Plugin';

use Future::Mojo;
use Scalar::Util 'weaken';

our $VERSION = '0.001';

my %futures;

sub register {
  my ($self, $app, $options) = @_;
  
  $app->helper(future => sub { shift; Future::Mojo->new(@_) });
  
  $app->helper(adopt_future => sub {
    my ($c, $f) = @_;
    my $tx = $c->render_later->tx;
    my $fkey = "$f";
    $futures{$fkey} = $f;
    weaken(my $weak_c = $c);
    return $f->on_ready(sub {
      my $f = shift;
      delete $futures{$fkey};
      $weak_c->helpers->reply->exception(scalar $f->failure)
        if defined $weak_c and $f->is_failed;
      undef $tx;
    });
  });
}

1;

=head1 NAME

Mojolicious::Plugin::Future - use Future in Mojolicious applications

=head1 SYNOPSIS

 use Mojolicious::Lite;
 
 plugin 'Future';
 
 use Scalar::Util 'weaken';
 use Mojo::UserAgent;
 my $ua = Mojo::UserAgent->new;
 get '/async_callback' => sub {
   my $c = shift;
   my $f = $c->future;
   weaken(my $weak_f = $f); # only close over weakened Future
   $ua->get('http://example.com', sub {
     my ($ua, $tx) = @_;
     $tx->success ? $weak_f->done($tx->result) : $weak_f->fail($tx->error->{message});
   });
   $c->adopt_future($f->on_done(sub {
     my ($result) = @_;
     $c->render(json => {result => $result->text});
   }));
 };
 
 get '/future_returning' => sub {
   my $c = shift;
   $c->adopt_future(returns_a_future()->then(sub {
     my @result = @_;
     return returns_another_future(@result);
   })->on_done(sub {
     my @result = @_;
     $c->render(json => {result => \@result});
   }));
 };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Future> is a convenient way to use L<Future> in a
L<Mojolicious> application. The final future in a sequence or convergence is
passed to the L</"adopt_future"> helper, which takes care of the details of
asynchronous rendering in a similar fashion to
L<Mojolicious::Plugin::DefaultHelpers/"delay">.

=head1 HELPERS

=head2 adopt_future

  $f = $c->adopt_future($f);

Disables automatic rendering, stores the Future instance, keeps a reference to
L<Mojolicious::Controller/"tx"> in case the underlying connection gets closed
early, and calls L<< Mojolicious::Plugin::DefaultHelpers/"reply->exception" >>
if the Future fails.

=head2 future

  my $f = $c->future;
  my $f = $c->future($loop);

Convenience method to return a new L<Future::Mojo> object.

=head1 METHODS

L<Mojolicious::Plugin::Future> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register helper in L<Mojolicious> application.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Future::Mojo>, L<Future>
