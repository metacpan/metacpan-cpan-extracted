use utf8;

package SemanticWeb::Schema::ProductReturnPolicy;

# ABSTRACT: A ProductReturnPolicy provides information about product return policies associated with an Organization or Product .

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'ProductReturnPolicy';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


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





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ProductReturnPolicy - A ProductReturnPolicy provides information about product return policies associated with an Organization or Product .

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

=for html <p>A ProductReturnPolicy provides information about product return policies
associated with an <a class="localLink"
href="http://schema.org/Organization">Organization</a> or <a
class="localLink" href="http://schema.org/Product">Product</a>.<p>

=head1 ATTRIBUTES

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
