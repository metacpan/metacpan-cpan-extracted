use v5.36.0;
package Sieve::Generator::Element::Num 0.003;
# ABSTRACT: a Sieve numeric literal

use Moo;
with 'Sieve::Generator::Element';

use Carp ();

#pod =head1 DESCRIPTION
#pod
#pod A C<Num> renders a non-negative integer, optionally followed by a size suffix
#pod (C<K>, C<M>, or C<G>), as a Sieve number literal per RFC 5228 section 2.4.1.
#pod
#pod =attr value
#pod
#pod This attribute holds the non-negative integer value.
#pod
#pod =cut

has value => (
  is  => 'ro',
  isa => sub {
    Carp::croak("value must be a non-negative integer")
      unless defined $_[0] && $_[0] =~ /\A[0-9]+\z/;
  },
  required => 1,
);

#pod =attr suffix
#pod
#pod This attribute holds an optional size suffix: C<K>, C<M>, or C<G> (case
#pod insensitive on input, always rendered uppercase).  If not provided, no suffix
#pod is appended.
#pod
#pod =cut

has suffix => (
  is  => 'ro',
  isa => sub {
    return unless defined $_[0];
    Carp::croak("suffix must be K, M, or G")
      unless $_[0] =~ /\A[KMGkmg]\z/;
  },
  coerce => sub { defined $_[0] ? uc $_[0] : $_[0] },
);

sub as_sieve ($self, $i = undef) {
  $i //= 0;
  return (q{  } x $i) . $self->value . ($self->suffix // '');
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Element::Num - a Sieve numeric literal

=head1 VERSION

version 0.003

=head1 DESCRIPTION

A C<Num> renders a non-negative integer, optionally followed by a size suffix
(C<K>, C<M>, or C<G>), as a Sieve number literal per RFC 5228 section 2.4.1.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 value

This attribute holds the non-negative integer value.

=head2 suffix

This attribute holds an optional size suffix: C<K>, C<M>, or C<G> (case
insensitive on input, always rendered uppercase).  If not provided, no suffix
is appended.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
