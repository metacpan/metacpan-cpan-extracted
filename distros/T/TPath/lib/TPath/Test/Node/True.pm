package TPath::Test::Node::True;
$TPath::Test::Node::True::VERSION = '1.007';
# ABSTRACT: TPath::Test::Node implementing the wildcard; e.g., //*

use Moose;
use namespace::autoclean;


with 'TPath::Test::Node';

# required by TPath::Test::Node
sub passes { 1 }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Test::Node::True - TPath::Test::Node implementing the wildcard; e.g., //*

=head1 VERSION

version 1.007

=head1 ROLES

L<TPath::Test::Node>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
