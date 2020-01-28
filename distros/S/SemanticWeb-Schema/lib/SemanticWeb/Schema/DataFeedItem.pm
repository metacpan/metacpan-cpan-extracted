use utf8;

package SemanticWeb::Schema::DataFeedItem;

# ABSTRACT: A single item within a larger data feed.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'DataFeedItem';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.0';


has date_created => (
    is        => 'rw',
    predicate => '_has_date_created',
    json_ld   => 'dateCreated',
);



has date_deleted => (
    is        => 'rw',
    predicate => '_has_date_deleted',
    json_ld   => 'dateDeleted',
);



has date_modified => (
    is        => 'rw',
    predicate => '_has_date_modified',
    json_ld   => 'dateModified',
);



has item => (
    is        => 'rw',
    predicate => '_has_item',
    json_ld   => 'item',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DataFeedItem - A single item within a larger data feed.

=head1 VERSION

version v6.0.0

=head1 DESCRIPTION

A single item within a larger data feed.

=head1 ATTRIBUTES

=head2 C<date_created>

C<dateCreated>

The date on which the CreativeWork was created or the item was added to a
DataFeed.

A date_created should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_created>

A predicate for the L</date_created> attribute.

=head2 C<date_deleted>

C<dateDeleted>

The datetime the item was removed from the DataFeed.

A date_deleted should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_deleted>

A predicate for the L</date_deleted> attribute.

=head2 C<date_modified>

C<dateModified>

The date on which the CreativeWork was most recently modified or when the
item's entry was modified within a DataFeed.

A date_modified should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_modified>

A predicate for the L</date_modified> attribute.

=head2 C<item>

An entity represented by an entry in a list or data feed (e.g. an 'artist'
in a list of 'artists')â.

A item should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<_has_item>

A predicate for the L</item> attribute.

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
