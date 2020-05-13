use utf8;

package SemanticWeb::Schema::MenuItem;

# ABSTRACT: A food or drink item listed in a menu or menu section.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'MenuItem';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has menu_add_on => (
    is        => 'rw',
    predicate => '_has_menu_add_on',
    json_ld   => 'menuAddOn',
);



has nutrition => (
    is        => 'rw',
    predicate => '_has_nutrition',
    json_ld   => 'nutrition',
);



has offers => (
    is        => 'rw',
    predicate => '_has_offers',
    json_ld   => 'offers',
);



has suitable_for_diet => (
    is        => 'rw',
    predicate => '_has_suitable_for_diet',
    json_ld   => 'suitableForDiet',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MenuItem - A food or drink item listed in a menu or menu section.

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

A food or drink item listed in a menu or menu section.

=head1 ATTRIBUTES

=head2 C<menu_add_on>

C<menuAddOn>

Additional menu item(s) such as a side dish of salad or side order of fries
that can be added to this menu item. Additionally it can be a menu section
containing allowed add-on menu items for this menu item.

A menu_add_on should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MenuItem']>

=item C<InstanceOf['SemanticWeb::Schema::MenuSection']>

=back

=head2 C<_has_menu_add_on>

A predicate for the L</menu_add_on> attribute.

=head2 C<nutrition>

Nutrition information about the recipe or menu item.

A nutrition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::NutritionInformation']>

=back

=head2 C<_has_nutrition>

A predicate for the L</nutrition> attribute.

=head2 C<offers>

=for html <p>An offer to provide this item&#x2014;for example, an offer to sell a
product, rent the DVD of a movie, perform a service, or give away tickets
to an event. Use <a class="localLink"
href="http://schema.org/businessFunction">businessFunction</a> to indicate
the kind of transaction offered, i.e. sell, lease, etc. This property can
also be used to describe a <a class="localLink"
href="http://schema.org/Demand">Demand</a>. While this property is listed
as expected on a number of common types, it can be used in others. In that
case, using a second type, such as Product or a subtype of Product, can
clarify the nature of the offer.<p>

A offers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Demand']>

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<_has_offers>

A predicate for the L</offers> attribute.

=head2 C<suitable_for_diet>

C<suitableForDiet>

Indicates a dietary restriction or guideline for which this recipe or menu
item is suitable, e.g. diabetic, halal etc.

A suitable_for_diet should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::RestrictedDiet']>

=back

=head2 C<_has_suitable_for_diet>

A predicate for the L</suitable_for_diet> attribute.

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
