package Mojo::Promise::Role::Futurify;

use Future::Mojo;
use Scalar::Util;
use Role::Tiny;

our $VERSION = 'v1.0.0';

requires qw(ioloop then);

sub futurify {
  my $self = shift;
  my $f = Future::Mojo->new($self->ioloop);
  Scalar::Util::weaken(my $weak_f = $f);
  $self->then(sub { $weak_f->done(@_) if $weak_f; 1 },
    sub { $weak_f->fail(@_) if $weak_f; 1 });
  return $f;
}

1;

=head1 NAME

Mojo::Promise::Role::Futurify - Chain a Future from a Mojo::Promise

=head1 SYNOPSIS

  use Mojo::Promise;
  
  my $promise = Mojo::Promise->with_roles('+Futurify')->new;
  my $future = $promise->futurify->on_ready(sub {
    my $f = shift;
    say $f->is_done ? 'Done' : 'Failed';
  });
  $promise->ioloop->timer(5 => sub { $promise->resolve });
  $future->await;
  
  use Mojo::UserAgent;
  my $ua = Mojo::UserAgent->new;
  
  # complicated way of doing $ua->get('https://example.com')
  my $tx = $ua->get_p('https://example.com')->with_roles('+Futurify')->futurify->get;
  
  # using Future composition methods
  my @futures;
  foreach my $url (@urls) {
    push @futures, $ua->get_p($url)->with_roles('+Futurify')->futurify;
  }
  
  use Future;
  Future->wait_all(@futures)->then(sub {
    foreach my $f (@_) {
      if ($f->is_done) {
        my $tx = $f->get;
      } elsif ($f->is_failed) {
        my $err = $f->failure;
      }
    }
  })->await;
  
  # using Future::Utils in a Mojolicious application
  use Mojolicious::Lite;
  use Future::Utils 'fmap_concat';
  my $ua = Mojo::UserAgent->new;
  
  get '/foo' => sub {
    my $c = shift;
    my $count = $c->param('count') // 50;
    
    my $f = fmap_concat {
      $ua->get_p('https://example.com')->with_roles('+Futurify')->futurify;
    } foreach => [1..$count], concurrent => 10;
    
    my $tx = $c->render_later->tx;
    $f->on_done(sub {
      my @txs = @_;
      $c->render(json => [titles => map { $_->res->dom->at('title')->text } @txs]);
    })->on_fail(sub {
      $c->reply->exception(@_);
    })->on_ready(sub { undef $tx })->retain;
  };
  
  app->start;

=head1 DESCRIPTION

L<Mojo::Promise::Role::Futurify> provides an interface to chain L<Future>
objects from L<Mojo::Promise> objects.

=head1 METHODS

L<Mojo::Promise::Role::Futurify> composes the following methods.

=head2 futurify

  my $future = $promise->futurify;

Returns a L<Future::Mojo> object that will become ready with success or failure
when the L<Mojo::Promise> resolves or rejects.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::Promise>, L<Future>, L<Future::Mojo>
