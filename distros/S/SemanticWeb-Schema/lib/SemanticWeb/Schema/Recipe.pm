use utf8;

package SemanticWeb::Schema::Recipe;

# ABSTRACT: A recipe

use Moo;

extends qw/ SemanticWeb::Schema::HowTo /;


use MooX::JSON_LD 'Recipe';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has cook_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'cookTime',
);



has cooking_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'cookingMethod',
);



has ingredients => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'ingredients',
);



has nutrition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'nutrition',
);



has recipe_category => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recipeCategory',
);



has recipe_cuisine => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recipeCuisine',
);



has recipe_ingredient => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recipeIngredient',
);



has recipe_instructions => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recipeInstructions',
);



has recipe_yield => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recipeYield',
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

SemanticWeb::Schema::Recipe - A recipe

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A recipe. For dietary restrictions covered by the recipe, a few common
restrictions are enumerated via <a class="localLink"
href="http://schema.org/suitableForDiet">suitableForDiet</a>. The <a
class="localLink" href="http://schema.org/keywords">keywords</a> property
can also be used to add more detail.

=head1 ATTRIBUTES

=head2 C<cook_time>

C<cookTime>

=for html The time it takes to actually cook the dish, in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 duration format</a>.

A cook_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<cooking_method>

C<cookingMethod>

The method of cooking, such as Frying, Steaming, ...

A cooking_method should be one of the following types:

=over

=item C<Str>

=back

=head2 C<ingredients>

A single ingredient used in the recipe, e.g. sugar, flour or garlic.

A ingredients should be one of the following types:

=over

=item C<Str>

=back

=head2 C<nutrition>

Nutrition information about the recipe or menu item.

A nutrition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::NutritionInformation']>

=back

=head2 C<recipe_category>

C<recipeCategory>

The category of the recipeâfor example, appetizer, entree, etc.

A recipe_category should be one of the following types:

=over

=item C<Str>

=back

=head2 C<recipe_cuisine>

C<recipeCuisine>

The cuisine of the recipe (for example, French or Ethiopian).

A recipe_cuisine should be one of the following types:

=over

=item C<Str>

=back

=head2 C<recipe_ingredient>

C<recipeIngredient>

A single ingredient used in the recipe, e.g. sugar, flour or garlic.

A recipe_ingredient should be one of the following types:

=over

=item C<Str>

=back

=head2 C<recipe_instructions>

C<recipeInstructions>

A step in making the recipe, in the form of a single item (document, video,
etc.) or an ordered list with HowToStep and/or HowToSection items.

A recipe_instructions should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<InstanceOf['SemanticWeb::Schema::ItemList']>

=item C<Str>

=back

=head2 C<recipe_yield>

C<recipeYield>

The quantity produced by the recipe (for example, number of people served,
number of servings, etc).

A recipe_yield should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Str>

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

L<SemanticWeb::Schema::HowTo>

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
