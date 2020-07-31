use utf8;

package SemanticWeb::Schema::ProductGroup;

# ABSTRACT: A ProductGroup represents a group of Product s that vary only in certain well-described ways

use Moo;

extends qw/ SemanticWeb::Schema::Product /;


use MooX::JSON_LD 'ProductGroup';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has has_variant => (
    is        => 'rw',
    predicate => '_has_has_variant',
    json_ld   => 'hasVariant',
);



has product_group_id => (
    is        => 'rw',
    predicate => '_has_product_group_id',
    json_ld   => 'productGroupID',
);



has varies_by => (
    is        => 'rw',
    predicate => '_has_varies_by',
    json_ld   => 'variesBy',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ProductGroup - A ProductGroup represents a group of Product s that vary only in certain well-described ways

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

=for html <p>A ProductGroup represents a group of <a class="localLink"
href="http://schema.org/Product">Product</a>s that vary only in certain
well-described ways, such as by <a class="localLink"
href="http://schema.org/size">size</a>, <a class="localLink"
href="http://schema.org/color">color</a>, <a class="localLink"
href="http://schema.org/material">material</a> etc.<br/><br/> While a
ProductGroup itself is not directly offered for sale, the various varying
products that it represents can be. The ProductGroup serves as a prototype
or template, standing in for all of the products who have an <a
class="localLink" href="http://schema.org/isVariantOf">isVariantOf</a>
relationship to it. As such, properties (including additional types) can be
applied to the ProductGroup to represent characteristics shared by each of
the (possibly very many) variants. Properties that reference a ProductGroup
are not included in this mechanism; neither are the following specific
properties <a class="localLink"
href="http://schema.org/variesBy">variesBy</a>, <a class="localLink"
href="http://schema.org/hasVariant">hasVariant</a>, <a class="localLink"
href="http://schema.org/url">url</a>.<p>

=head1 ATTRIBUTES

=head2 C<has_variant>

C<hasVariant>

=for html <p>Indicates a <a class="localLink"
href="http://schema.org/Product">Product</a> that is a member of this <a
class="localLink" href="http://schema.org/ProductGroup">ProductGroup</a>
(or <a class="localLink"
href="http://schema.org/ProductModel">ProductModel</a>).<p>

A has_variant should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=back

=head2 C<_has_has_variant>

A predicate for the L</has_variant> attribute.

=head2 C<product_group_id>

C<productGroupID>

Indicates a textual identifier for a ProductGroup.

A product_group_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_product_group_id>

A predicate for the L</product_group_id> attribute.

=head2 C<varies_by>

C<variesBy>

=for html <p>Indicates the property or properties by which the variants in a <a
class="localLink" href="http://schema.org/ProductGroup">ProductGroup</a>
vary, e.g. their size, color etc. Schema.org properties can be referenced
by their short name e.g. "color"; terms defined elsewhere can be referenced
with their URIs.<p>

A varies_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTerm']>

=item C<Str>

=back

=head2 C<_has_varies_by>

A predicate for the L</varies_by> attribute.

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
