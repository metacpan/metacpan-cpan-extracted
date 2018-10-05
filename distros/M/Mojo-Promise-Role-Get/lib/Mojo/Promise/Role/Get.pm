package Mojo::Promise::Role::Get;

use Carp ();
use Role::Tiny;

our $VERSION = 'v0.1.1';

requires qw(ioloop then wait);

sub get {
  my ($self) = @_;
  Carp::croak "'get' cannot be called when the event loop is running" if $self->ioloop->is_running;
  my (@result, $rejected);
  $self->then(sub { @result = @_ }, sub { $rejected = 1; @result = @_ })->wait;
  if ($rejected) {
    my $reason = $result[0] // 'Promise was rejected';
    die $reason if ref $reason or $reason =~ m/\n\z/;
    Carp::croak $reason;
  }
  return wantarray ? @result : $result[0];
}

1;

=head1 NAME

Mojo::Promise::Role::Get - Wait for the results of a Mojo::Promise

=head1 SYNOPSIS

  use Mojo::IOLoop;
  use Mojo::Promise;
  use Mojo::UserAgent;
  my $ua = Mojo::UserAgent->new;

  # long way of writing $ua->get('http://example.com')->result
  my $res = $ua->get_p('http://example.com')->with_roles('+Get')->get->result;

  # wait for multiple requests at once
  my @responses = map { $_->[0]->result } Mojo::Promise->all(
    $ua->get_p('http://example.com'),
    $ua->get_p('https://www.google.com'),
  )->with_roles('Mojo::Promise::Role::Get')->get;

  # request with exception on timeout
  my $timeout = Mojo::Promise->new;
  Mojo::IOLoop->timer(1 => sub { $timeout->reject('Timed out!') });
  my $res = Mojo::Promise->race($ua->get_p('http://example.com'), $timeout)
    ->with_roles('Mojo::Promise::Role::Get')->get->result;

=head1 DESCRIPTION

L<Mojo::Promise::Role::Get> is a L<Mojo::Promise> L<role|Role::Tiny> that adds
a L</"get"> method to facilitate the usage of asynchronous code in a
synchronous manner, similar to L<Future/"get">.

Note: Like in Future, L</"get"> cannot retrieve results when the event loop is
already running, as that can recurse into the event reactor. Unlike in Future,
this is true even if the promise has already been resolved or rejected, because
retrieving L<Mojo::Promise> results always requires running the event loop.

=head1 METHODS

L<Mojo::Promise::Role::Get> composes the following methods.

=head2 get

  my @results = $promise->get;
  my $first_result = $promise->get;

Blocks until the promise resolves or is rejected. If it is fulfilled, the
results are returned. In scalar context the first value is returned. If the
promise is rejected, the (first value of the) rejection reason is thrown as an
exception.

An exception is thrown if the L<Mojo::Promise/"ioloop"> is running, to prevent
recursing into the event reactor.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Future>
