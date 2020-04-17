package Mojo::UserAgent::Signature::Base;
use Mojo::Base -base;

sub apply_signature {
  my ($self, $tx, $args) = @_;
  return $tx if _is_signed($tx);
  $tx->req->headers->add('X-Mojo-Signature' => _pkg_name $self);
  $self->sign_tx($tx, $args);
}

sub init {
  my ($self, $ua) = (shift, shift);

  $self = $self->new(@_);
  $ua->signature($self)->transactor->add_generator(
    sign => sub {
      my ($t, $tx) = (shift, shift);
      return $tx if _is_signed($tx);

      # Apply Signature
      my $args = shift if ref $_[0];
      $self->apply_signature($tx, $args);

      # Next Generator
      if (@_ > 1) {
        my $cb = $t->generators->{shift()};
        $t->$cb($tx, @_);
      }

      # Body
      elsif (@_) { $tx->req->body(shift) }

      return $tx;
    }
  );
  return $self;
}

sub sign_tx { $_[1] }

sub _is_signed { shift->req->headers->header('X-Mojo-Signature') }

sub _pkg_name ($) { ((split /::/, ref $_[0] || $_[0])[-1]) }

package Mojo::UserAgent::Signature::None;
use Mojo::Base 'Mojo::UserAgent::Signature::Base';

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::Signature::Base - Signature base class

=head1 SYNOPSIS

  package Mojo::UserAgent::Signature::SomeService;
  use Mojo::Base 'Mojo::UserAgent::Signature::Base;

  sub sign_tx {
    my ($self, $tx, $args) = @_;

    # Magic here! :)
  }

=head1 DESCRIPTION

L<Mojo::UserAgent::Signature::Base> is an abstract base class for
L<Mojo::UserAgent> signatures.

=head1 METHODS

L<Mojo::UserAgent::Signature::Base> inherits all methods from
L<Mojo::UserAgent::Signature> and implements the following new ones.

=head2 apply_signature

  $signed_tx = $signature->apply_signature($tx, $args);

Applies the signature produced by L</"sign_tx"> to L<Mojo::UserAgent>
transaction. Also adds a header to the transaction,
C<X-Mojo-Signature: SomeService>, to indicate that this transaction has been
signed -- this prevents the automatic signature handling from applying the
signature a second time, after the generator.

=head2 init

  $signature = $signature->init($ua);

Adds a transactor generator named C<sign> to the supplied C<$ua> instance for
applying a signature to a transaction. Useful for overriding the signature
details in the L</"signature"> instance.

Another generator can follow the use of the C<sign> generator.

  $ua->get($url => sign => {%args});

=head2 sign_tx

  $signed_tx = $signature->sign_tx($tx, {%args});

This method will be called by L</"apply_signature">, either automatically when
the L<transaction is built|Mojo::UserAgent/"build_tx">, or explicitly via the
transaction L<generator|Mojo::UserAgent::Transactor/"GENERATORS">.
Meant to be overloaded in a subclass.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020, Stefan Adams.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://github.com/stefanadams/mojo-useragent-role-signature>, L<Mojo::UserAgent>.

=cut
