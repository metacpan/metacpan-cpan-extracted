package TPath::Selector::Test::ChildAttribute;
$TPath::Selector::Test::ChildAttribute::VERSION = '1.007';
# ABSTRACT: handles C</@foo> where this is not the first step in the path, or C<child::@foo>

use Moose;
use TPath::Test::Node::Attribute;
use TPath::TypeConstraints;
use namespace::autoclean;


with 'TPath::Selector::Test';

has a => ( is => 'ro', isa => 'TPath::Attribute', required => 1 );

sub BUILD {
    my $self = shift;
    $self->_node_test( TPath::Test::Node::Attribute->new( a => $self->a ) );
}

sub to_string {
    my ( $self, $first ) = @_;
    my $s = $first ? '' : '/';
    $s .= '^' if $self->is_inverted;
    $s .= $self->a->to_string;
    return $s;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Test::ChildAttribute - handles C</@foo> where this is not the first step in the path, or C<child::@foo>

=head1 VERSION

version 1.007

=head1 ROLES

L<TPath::Selector::Test>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
