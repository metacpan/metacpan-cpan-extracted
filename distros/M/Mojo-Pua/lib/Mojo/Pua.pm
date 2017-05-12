package Mojo::Pua;
use Mojo::Base 'Mojo::UserAgent';
use Evo 'Evo::Export; -Promise::Mojo *; Carp croak';

our $VERSION = '0.010';    # VERSION

# LIB version

use constant PUA => __PACKAGE__->new();
export 'PUA';

# OO version
sub start ($self, $tx, $cb_empty = undef) {

  croak "Got callback but this class returns a Promise" if $cb_empty;
  my $d = deferred();

  my $pcb = sub ($ua, $tx) {
    return $d->resolve($tx) if $tx->res->code;
    $d->reject($tx->error->{message});
  };

  $self->SUPER::start($tx, $pcb);

  $d->promise;
}

sub want_code($want_code) : prototype($) : Export {
  my (undef, $file, $line) = caller();
  return sub($tx) {
    my $res = $tx->res;
    return $res if $res->code == $want_code;
    die
      "Wanted [$want_code], got [${\$res->code}] ${\$res->message} at $file line $line\n";
  };
}

1;

# ABSTRACT: HTTP Client + Evo::Promise

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::Pua - HTTP Client + Evo::Promise

=head1 VERSION

version 0.010

=head1 SYNOPSIS

C<Mojo::Pua> inherits all methods from L<Mojo::UserAgent> but returns L<Evo::Promise::Mojo> object for each request

  use Evo 'Mojo::Pua';
  my $ua = Mojo::Pua->new();

  $ua->get("http://alexbyk.com/")

    ->then(sub($tx) {
      my $res = $tx->success;
      $res ? say $res->dom->at('title') : say "ERROR: ", $tx->error->{message};
    })

    ->catch(sub($err) { say "CATCHED: $err" })

    ->finally(sub { Mojo::IOLoop->stop; });

  Mojo::IOLoop->start;

Pay attention, C<400> and C<500> codes don't cause an exception. You should check C<Mojo::Transaction::HTTP/success> to determine a success of a request.

A promise will be rejected on network errors only:

  $ua->get("http://localhost:2222/")

    ->catch(sub($err) { say "CATCHED: $err" })
    ->finally(sub     { Mojo::IOLoop->stop; });

But if you want to make life easier, see L</want_code> promise onFulfill generator

=head1 DESCRIPTION

This module is based on L<Mojo::UserAgent> and allows you to use promises (L<Evo::Promise::Mojo>)

=head1 METHODS

All methods C<get, post ...> from L<Mojo::UserAgent> return a promise

=head1 FUNCTIONS

=head2 PUA

A single instance of C<Mojo::Pua>.

  use Evo 'Mojo::Pua PUA';
  PUA->get('http://mail.ru')->then(sub {...});

=head2 want_code

Return a promise onFulfill handler that will be fulfilled only if the response code matches a given one. Then it will pass a L<Mojo::Message::Response> object (not a transaction), or will throw an exception

  use Evo 'Mojo::Pua want_code';
  my $ua = Mojo::Pua->new();

  # accept only 200 code
  $ua->get("http://httpstat.us/200")->then(want_code 200)

    # pay attention, $res, not $tx
    ->then(sub ($res) { say $res->body })->finally(sub { Mojo::IOLoop->stop; });

  Mojo::IOLoop->start;

  # accept only 201 code
  $ua->get("http://httpstat.us/200")->then(want_code 201)

    # 201 != 200, promise is rejected
    ->catch(sub($err) { say "CATCHED: $err" })
    ->finally(sub     { Mojo::IOLoop->stop; });

  Mojo::IOLoop->start;

Return

=head1 SEE ALSO

L<Mojo::UserAgent>
L<Evo::Promise::Mojo>
L<https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Promise>

=head1 AUTHOR

alexbyk <alexbyk.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
