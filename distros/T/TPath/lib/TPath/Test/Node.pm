package TPath::Test::Node;
$TPath::Test::Node::VERSION = '1.007';
# ABSTRACT: role for tests determining whether a node has some property


use Moose::Role;


requires 'passes';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Test::Node - role for tests determining whether a node has some property

=head1 VERSION

version 1.007

=head1 DESCRIPTION

C<TPath::Test::Node> is the interface for objects testing whether a node has
some property. It is not to be confused with L<TPath::Test>. C<TPath::Test::Node>
implements the C<foo> portion of C<//foo[@a or @b]>. C<TPath::Test> implements the
C<@a or @b> portion. Their tests have different signatures.

=head1 REQUIRED METHODS

=head2 passes

Expects a node and an index and returns whether the node passes its test.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
