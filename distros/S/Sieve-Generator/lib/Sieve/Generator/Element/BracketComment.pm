use v5.36.0;
package Sieve::Generator::Element::BracketComment 0.003;
# ABSTRACT: a Sieve bracket comment (/* ... */)

use Moo;
with 'Sieve::Generator::Element';

#pod =head1 DESCRIPTION
#pod
#pod A bracket comment renders as a C</* ... */> comment block as defined in
#pod RFC 5228.
#pod
#pod =attr content
#pod
#pod This attribute holds the text content of the comment.
#pod
#pod =cut

has content => (is => 'ro', required => 1);

sub as_sieve ($self, $i = undef) {
  $i //= 0;

  my $indent = q{  } x $i;
  return "${indent}/* " . $self->content . " */";
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Element::BracketComment - a Sieve bracket comment (/* ... */)

=head1 VERSION

version 0.003

=head1 DESCRIPTION

A bracket comment renders as a C</* ... */> comment block as defined in
RFC 5228.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 content

This attribute holds the text content of the comment.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
