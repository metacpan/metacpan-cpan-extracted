package TPath::Selector;
$TPath::Selector::VERSION = '1.007';
# ABSTRACT: an interface for classes that select nodes from a candidate collection

use Moose::Role;


with 'TPath::Stringifiable';


requires 'select';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector - an interface for classes that select nodes from a candidate collection

=head1 VERSION

version 1.007

=head1 ROLES

L<TPath::Stringifiable>

=head1 REQUIRED METHODS

=head2 select

Takes L<TPath::Context> and whether the selection concerns the initial node
and returns a collection of nodes.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
