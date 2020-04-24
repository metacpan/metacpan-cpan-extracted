use utf8;

package SemanticWeb::Schema::OfferShippingDetails;

# ABSTRACT: OfferShippingDetails represents information about shipping destinations

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'OfferShippingDetails';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has shipping_destination => (
    is        => 'rw',
    predicate => '_has_shipping_destination',
    json_ld   => 'shippingDestination',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::OfferShippingDetails - OfferShippingDetails represents information about shipping destinations

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

=for html <p>OfferShippingDetails represents information about shipping
destinations.<br/><br/> Multiple of these entities can be used to represent
different shipping rates for different destinations:<br/><br/> One entity
for Alaska/Hawaii. A different one for continental US.A different one for
all France.<br/><br/> Multiple of these entities can be used to represent
different shipping costs and delivery times.<br/><br/> Two entities that
are identical but differ in rate and time:<br/><br/> e.g. Cheaper and
slower: $5 in 5-7days or Fast and expensive: $15 in 1-2 days<p>

=head1 ATTRIBUTES

=head2 C<shipping_destination>

C<shippingDestination>

indicates (posssibly multiple) shipping destinations. These can be defined
in several ways e.g. postalCode ranges.

A shipping_destination should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedRegion']>

=back

=head2 C<_has_shipping_destination>

A predicate for the L</shipping_destination> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::StructuredValue>

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
