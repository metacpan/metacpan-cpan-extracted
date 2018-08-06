package SemanticWeb::Schema::MenuItem;

# ABSTRACT: A food or drink item listed in a menu or menu section.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'MenuItem';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has nutrition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'nutrition',
);



has offers => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'offers',
);



has suitable_for_diet => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'suitableForDiet',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MenuItem - A food or drink item listed in a menu or menu section.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A food or drink item listed in a menu or menu section.

=head1 ATTRIBUTES

=head2 C<nutrition>

Nutrition information about the recipe or menu item.

A nutrition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::NutritionInformation']>

=back

=head2 C<offers>

An offer to provide this item&#x2014;for example, an offer to sell a
product, rent the DVD of a movie, perform a service, or give away tickets
to an event.

A offers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<suitable_for_diet>

C<suitableForDiet>

Indicates a dietary restriction or guideline for which this recipe or menu
item is suitable, e.g. diabetic, halal etc.

A suitable_for_diet should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::RestrictedDiet']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
