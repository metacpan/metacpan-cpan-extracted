use v5.36.0;
package Sieve::Generator::Element 0.003;
# ABSTRACT: role for objects that render as Sieve code

use Moo::Role;

#pod =head1 DESCRIPTION
#pod
#pod This role is consumed by all objects that can render themselves as Sieve code.
#pod It requires a single method, C<as_sieve>.
#pod
#pod =method as_sieve
#pod
#pod   my $sieve_text = $element->as_sieve;
#pod   my $sieve_text = $element->as_sieve($indent_level);
#pod
#pod This method renders the object as a string of Sieve code.  The optional
#pod C<$indent_level> argument is a non-negative integer controlling the
#pod indentation depth; each level adds two spaces.  If not given, no indenting is
#pod added.
#pod
#pod =method children
#pod
#pod   my @children = $element->children;
#pod
#pod Returns all child Elements of this node.  Leaf nodes return an empty list.
#pod Container nodes return their direct children.  This is used by
#pod C<find_elements> to walk the tree.
#pod
#pod =cut

sub children ($self) { () }

#pod =method find_elements
#pod
#pod   my @found = $element->find_elements(\&predicate);
#pod
#pod Walks the element tree depth-first, returning all elements (including
#pod C<$element> itself) for which the predicate returns true.  Descends into
#pod matching nodes, so all matches at any depth are returned.
#pod
#pod =cut

sub find_elements ($self, $code) {
  my @found;
  push @found, $self if $code->($self);
  push @found, $_->find_elements($code) for $self->children;
  return @found;
}

requires 'as_sieve';

no Moo::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Element - role for objects that render as Sieve code

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This role is consumed by all objects that can render themselves as Sieve code.
It requires a single method, C<as_sieve>.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 METHODS

=head2 as_sieve

  my $sieve_text = $element->as_sieve;
  my $sieve_text = $element->as_sieve($indent_level);

This method renders the object as a string of Sieve code.  The optional
C<$indent_level> argument is a non-negative integer controlling the
indentation depth; each level adds two spaces.  If not given, no indenting is
added.

=head2 children

  my @children = $element->children;

Returns all child Elements of this node.  Leaf nodes return an empty list.
Container nodes return their direct children.  This is used by
C<find_elements> to walk the tree.

=head2 find_elements

  my @found = $element->find_elements(\&predicate);

Walks the element tree depth-first, returning all elements (including
C<$element> itself) for which the predicate returns true.  Descends into
matching nodes, so all matches at any depth are returned.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
