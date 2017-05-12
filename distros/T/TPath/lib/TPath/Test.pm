package TPath::Test;
$TPath::Test::VERSION = '1.007';
# ABSTRACT: interface of conditional expressions in predicates


use Moose::Role;


with 'TPath::Stringifiable';


requires 'test';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Test - interface of conditional expressions in predicates

=head1 VERSION

version 1.007

=head1 DESCRIPTION

Interface of objects expressing tests in predicate expressions. E.g., the C<@a or @b> in 
C<//foo[@a or @b]>. Not to be confused with L<TPath::Test::Node>, which is used to implement
the C<foo> portion of this expression.

=head1 ROLES

L<TPath::Stringifiable>

=head1 REQUIRED METHODS

=head2 test

Takes a L<TPath::Context> and returns whether the node passes the predicate.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
