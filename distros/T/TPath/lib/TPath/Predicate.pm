package TPath::Predicate;
$TPath::Predicate::VERSION = '1.007';
# ABSTRACT: interface of square bracket sub-expressions in TPath expressions

use Moose::Role;


with 'TPath::Stringifiable';


requires 'filter';


has outer => ( is => 'ro', isa => 'Bool', default => 0 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Predicate - interface of square bracket sub-expressions in TPath expressions

=head1 VERSION

version 1.007

=head1 ATTRIBUTES

=head2 outer

Whether the predicate is inside or outside any grouping parentheses.

  //*[foo]    # inside  -- outer is false
  (//*)[foo]  # outside -- outer is true

This distinction, though available to all predicates, is especially important to index predicates.

  //*[0]

Means the root and any element which is the first child of its parents. While

  (//*)[0]

means the first of all elements -- the root.

=head1 METHODS

=head2 filter

Takes an index and  a collection of L<TPath::Context> objects and returns the collection of contexts
for which the predicate is true.

=head1 ROLES

L<TPath::Stringifiable>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
