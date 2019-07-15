use utf8;

package SemanticWeb::Schema::ItemList;

# ABSTRACT: A list of items of any sort&#x2014;for example

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'ItemList';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has item_list_element => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'itemListElement',
);



has item_list_order => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'itemListOrder',
);



has number_of_items => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfItems',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ItemList - A list of items of any sort&#x2014;for example

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A list of items of any sort&#x2014;for example, Top 10 Movies About
Weathermen, or Top 100 Party Songs. Not to be confused with HTML lists,
which are often used only for formatting.

=head1 ATTRIBUTES

=head2 C<item_list_element>

C<itemListElement>

=for html For itemListElement values, you can use simple strings (e.g. "Peter",
"Paul", "Mary"), existing entities, or use ListItem.<br/><br/> Text values
are best if the elements in the list are plain strings. Existing entities
are best for a simple, unordered list of existing things in your data.
ListItem is used with ordered lists when you want to provide additional
context about the element in that list or when the same item might be in
different places in different lists.<br/><br/> Note: The order of elements
in your mark-up is not sufficient for indicating the order or elements. Use
ListItem with a 'position' property in such cases.

A item_list_element should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ListItem']>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head2 C<item_list_order>

C<itemListOrder>

Type of ordering (e.g. Ascending, Descending, Unordered).

A item_list_order should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ItemListOrderType']>

=item C<Str>

=back

=head2 C<number_of_items>

C<numberOfItems>

The number of items in an ItemList. Note that some descriptions might not
fully describe all items in a list (e.g., multi-page pagination); in such
cases, the numberOfItems would be for the entire list.

A number_of_items should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

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
