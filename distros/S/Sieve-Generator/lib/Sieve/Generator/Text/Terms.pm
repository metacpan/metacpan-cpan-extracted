use v5.36.0;
package Sieve::Generator::Text::Terms 0.001;
# ABSTRACT: a sequence of Sieve terms joined by spaces

use Moo;
with 'Sieve::Generator::Text';

#pod =head1 DESCRIPTION
#pod
#pod A C<Terms> object renders a sequence of terms as a space-joined inline Sieve
#pod expression.  It is the general-purpose building block for Sieve test
#pod expressions and argument sequences.
#pod
#pod =attr terms
#pod
#pod This attribute holds the arrayref of terms.  Each term may be a plain string or
#pod an object doing L<Sieve::Generator::Text>; all terms are joined with single
#pod spaces when rendered.
#pod
#pod =cut

has terms => (is => 'ro', required => 1);

sub as_sieve ($self, $i = undef) {
  my $str = (q{  } x ($i // 0))
          . join q{ },
            map {; ref($_) ? $_->as_sieve : $_ }
            $self->terms->@*;

  return $str;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Text::Terms - a sequence of Sieve terms joined by spaces

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A C<Terms> object renders a sequence of terms as a space-joined inline Sieve
expression.  It is the general-purpose building block for Sieve test
expressions and argument sequences.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 terms

This attribute holds the arrayref of terms.  Each term may be a plain string or
an object doing L<Sieve::Generator::Text>; all terms are joined with single
spaces when rendered.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
