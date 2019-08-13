use utf8;

package SemanticWeb::Schema::ProductReturnPolicy;

# ABSTRACT: A ProductReturnPolicy provides information about product return policies associated with an <a class="localLink" href="http://schema

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'ProductReturnPolicy';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';


has in_store_returns_offered => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'inStoreReturnsOffered',
);



has product_return_days => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'productReturnDays',
);



has product_return_link => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'productReturnLink',
);



has refund_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'refundType',
);



has return_fees => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'returnFees',
);



has return_policy_category => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'returnPolicyCategory',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ProductReturnPolicy - A ProductReturnPolicy provides information about product return policies associated with an <a class="localLink" href="http://schema

=head1 VERSION

version v3.9.0

=head1 DESCRIPTION

=for html A ProductReturnPolicy provides information about product return policies
associated with an <a class="localLink"
href="http://schema.org/Organization">Organization</a> or <a
class="localLink" href="http://schema.org/Product">Product</a>.

=head1 ATTRIBUTES

=head2 C<in_store_returns_offered>

C<inStoreReturnsOffered>

Are in-store returns offered?

A in_store_returns_offered should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<product_return_days>

C<productReturnDays>

The productReturnDays property indicates the number of days (from purchase)
within which relevant product return policy is applicable.

A product_return_days should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<product_return_link>

C<productReturnLink>

Indicates a Web page or service by URL, for product return.

A product_return_link should be one of the following types:

=over

=item C<Str>

=back

=head2 C<refund_type>

C<refundType>

A refundType, from an enumerated list.

A refund_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::RefundTypeEnumeration']>

=back

=head2 C<return_fees>

C<returnFees>

Indicates (via enumerated options) the return fees policy for a
ProductReturnPolicy

A return_fees should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ReturnFeesEnumeration']>

=back

=head2 C<return_policy_category>

C<returnPolicyCategory>

A returnPolicyCategory expresses at most one of several enumerated kinds of
return.

A return_policy_category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ProductReturnEnumeration']>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
