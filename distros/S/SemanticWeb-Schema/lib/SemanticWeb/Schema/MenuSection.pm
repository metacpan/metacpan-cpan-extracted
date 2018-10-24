use utf8;

package SemanticWeb::Schema::MenuSection;

# ABSTRACT: A sub-grouping of food or drink items in a menu

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'MenuSection';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has has_menu_item => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasMenuItem',
);



has has_menu_section => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasMenuSection',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MenuSection - A sub-grouping of food or drink items in a menu

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A sub-grouping of food or drink items in a menu. E.g. courses (such as
'Dinner', 'Breakfast', etc.), specific type of dishes (such as 'Meat',
'Vegan', 'Drinks', etc.), or some other classification made by the menu
provider.

=head1 ATTRIBUTES

=head2 C<has_menu_item>

C<hasMenuItem>

A food or drink item contained in a menu or menu section.

A has_menu_item should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MenuItem']>

=back

=head2 C<has_menu_section>

C<hasMenuSection>

A subgrouping of the menu (by dishes, course, serving time period, etc.).

A has_menu_section should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MenuSection']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
