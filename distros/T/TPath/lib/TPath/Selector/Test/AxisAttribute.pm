package TPath::Selector::Test::AxisAttribute;
$TPath::Selector::Test::AxisAttribute::VERSION = '1.007';
# ABSTRACT: handles C</ancestor::@foo> or C</preceding::@foo> where this is not the first step in the path, or C<ancestor::@foo>, etc.

use Moose;
use TPath::Test::Node::Attribute;
use TPath::TypeConstraints;
use namespace::autoclean;


with 'TPath::Selector::Test';

has a => ( is => 'ro', isa => 'TPath::Attribute', required => 1 );

sub BUILD {
    my $self = shift;
    my $nt = TPath::Test::Node::Attribute->new( a => $self->a );
    $self->_node_test($nt);
}

sub to_string {
    my ( $self, $first ) = @_;
    my $s = $first ? '' : '/';
    $s .= $self->axis . '::';
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

TPath::Selector::Test::AxisAttribute - handles C</ancestor::@foo> or C</preceding::@foo> where this is not the first step in the path, or C<ancestor::@foo>, etc.

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
