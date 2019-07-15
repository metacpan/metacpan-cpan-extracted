use utf8;

package SemanticWeb::Schema::ListItem;

# ABSTRACT: An list item, e

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'ListItem';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has item => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'item',
);



has next_item => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'nextItem',
);



has position => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'position',
);



has previous_item => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'previousItem',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ListItem - An list item, e

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

An list item, e.g. a step in a checklist or how-to description.

=head1 ATTRIBUTES

=head2 C<item>

An entity represented by an entry in a list or data feed (e.g. an 'artist'
in a list of 'artists')â.

A item should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<next_item>

C<nextItem>

A link to the ListItem that follows the current one.

A next_item should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ListItem']>

=back

=head2 C<position>

The position of an item in a series or sequence of items.

A position should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<Str>

=back

=head2 C<previous_item>

C<previousItem>

A link to the ListItem that preceeds the current one.

A previous_item should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ListItem']>

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
