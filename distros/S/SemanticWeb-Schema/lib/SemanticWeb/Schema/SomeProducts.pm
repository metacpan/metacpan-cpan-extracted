use utf8;

package SemanticWeb::Schema::SomeProducts;

# ABSTRACT: A placeholder for multiple similar products of the same kind.

use Moo;

extends qw/ SemanticWeb::Schema::Product /;


use MooX::JSON_LD 'SomeProducts';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has inventory_level => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'inventoryLevel',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SomeProducts - A placeholder for multiple similar products of the same kind.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A placeholder for multiple similar products of the same kind.

=head1 ATTRIBUTES

=head2 C<inventory_level>

C<inventoryLevel>

The current approximate inventory level for the item or items.

A inventory_level should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Product>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
