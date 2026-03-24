use v5.36.0;
package Sieve::Generator::Text::Qstr 0.001;
# ABSTRACT: a Sieve quoted string

use Moo;
with 'Sieve::Generator::Text';

#pod =head1 DESCRIPTION
#pod
#pod A C<Qstr> renders a single Perl string as a Sieve quoted string.
#pod
#pod =attr str
#pod
#pod This attribute holds the string to be quoted.
#pod
#pod =cut

has str => (is => 'ro', init_arg => 'str', required => 1);

sub as_sieve ($self, $i = undef) {
  # Sieve strings and string lists are compatible with JSON
  # https://tools.ietf.org/html/rfc5228#section-2.4.2
  #
  # Keep everything as a unicode string
  state $JSON = JSON::MaybeXS->new->utf8(0)->allow_nonref;
  Carp::confess("can't encode undef") unless defined $self->str; # XXX

  return (q{  } x ($i // 0)) . $JSON->encode("" . $self->str);
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Text::Qstr - a Sieve quoted string

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A C<Qstr> renders a single Perl string as a Sieve quoted string.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 str

This attribute holds the string to be quoted.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
