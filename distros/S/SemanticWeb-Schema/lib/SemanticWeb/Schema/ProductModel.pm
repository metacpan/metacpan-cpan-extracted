use utf8;

package SemanticWeb::Schema::ProductModel;

# ABSTRACT: A datasheet or vendor specification of a product (in the sense of a prototypical description).

use Moo;

extends qw/ SemanticWeb::Schema::Product /;


use MooX::JSON_LD 'ProductModel';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has is_variant_of => (
    is        => 'rw',
    predicate => '_has_is_variant_of',
    json_ld   => 'isVariantOf',
);



has predecessor_of => (
    is        => 'rw',
    predicate => '_has_predecessor_of',
    json_ld   => 'predecessorOf',
);



has successor_of => (
    is        => 'rw',
    predicate => '_has_successor_of',
    json_ld   => 'successorOf',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ProductModel - A datasheet or vendor specification of a product (in the sense of a prototypical description).

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

A datasheet or vendor specification of a product (in the sense of a
prototypical description).

=head1 ATTRIBUTES

=head2 C<is_variant_of>

C<isVariantOf>

A pointer to a base product from which this product is a variant. It is
safe to infer that the variant inherits all product features from the base
model, unless defined locally. This is not transitive.

A is_variant_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ProductModel']>

=back

=head2 C<_has_is_variant_of>

A predicate for the L</is_variant_of> attribute.

=head2 C<predecessor_of>

C<predecessorOf>

A pointer from a previous, often discontinued variant of the product to its
newer variant.

A predecessor_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ProductModel']>

=back

=head2 C<_has_predecessor_of>

A predicate for the L</predecessor_of> attribute.

=head2 C<successor_of>

C<successorOf>

A pointer from a newer variant of a product to its previous, often
discontinued predecessor.

A successor_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ProductModel']>

=back

=head2 C<_has_successor_of>

A predicate for the L</successor_of> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Product>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
