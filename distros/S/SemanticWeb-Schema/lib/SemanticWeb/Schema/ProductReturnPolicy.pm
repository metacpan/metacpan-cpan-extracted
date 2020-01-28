use utf8;

package SemanticWeb::Schema::ProductReturnPolicy;

# ABSTRACT: A ProductReturnPolicy provides information about product return policies associated with an Organization or Product .

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'ProductReturnPolicy';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.0';


has in_store_returns_offered => (
    is        => 'rw',
    predicate => '_has_in_store_returns_offered',
    json_ld   => 'inStoreReturnsOffered',
);



has product_return_days => (
    is        => 'rw',
    predicate => '_has_product_return_days',
    json_ld   => 'productReturnDays',
);



has product_return_link => (
    is        => 'rw',
    predicate => '_has_product_return_link',
    json_ld   => 'productReturnLink',
);



has refund_type => (
    is        => 'rw',
    predicate => '_has_refund_type',
    json_ld   => 'refundType',
);



has return_fees => (
    is        => 'rw',
    predicate => '_has_return_fees',
    json_ld   => 'returnFees',
);



has return_policy_category => (
    is        => 'rw',
    predicate => '_has_return_policy_category',
    json_ld   => 'returnPolicyCategory',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ProductReturnPolicy - A ProductReturnPolicy provides information about product return policies associated with an Organization or Product .

=head1 VERSION

version v6.0.0

=head1 DESCRIPTION

=for html <p>A ProductReturnPolicy provides information about product return policies
associated with an <a class="localLink"
href="http://schema.org/Organization">Organization</a> or <a
class="localLink" href="http://schema.org/Product">Product</a>.<p>

=head1 ATTRIBUTES

=head2 C<in_store_returns_offered>

C<inStoreReturnsOffered>

Are in-store returns offered?

A in_store_returns_offered should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_in_store_returns_offered>

A predicate for the L</in_store_returns_offered> attribute.

=head2 C<product_return_days>

C<productReturnDays>

The productReturnDays property indicates the number of days (from purchase)
within which relevant product return policy is applicable.

A product_return_days should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_product_return_days>

A predicate for the L</product_return_days> attribute.

=head2 C<product_return_link>

C<productReturnLink>

Indicates a Web page or service by URL, for product return.

A product_return_link should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_product_return_link>

A predicate for the L</product_return_link> attribute.

=head2 C<refund_type>

C<refundType>

A refundType, from an enumerated list.

A refund_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::RefundTypeEnumeration']>

=back

=head2 C<_has_refund_type>

A predicate for the L</refund_type> attribute.

=head2 C<return_fees>

C<returnFees>

Indicates (via enumerated options) the return fees policy for a
ProductReturnPolicy

A return_fees should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ReturnFeesEnumeration']>

=back

=head2 C<_has_return_fees>

A predicate for the L</return_fees> attribute.

=head2 C<return_policy_category>

C<returnPolicyCategory>

A returnPolicyCategory expresses at most one of several enumerated kinds of
return.

A return_policy_category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ProductReturnEnumeration']>

=back

=head2 C<_has_return_policy_category>

A predicate for the L</return_policy_category> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

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
