# ABSTRACT: a {json:api} document building class
package PONAPI::Document;

use strict;
use warnings;

use parent 'PONAPI::Document::Builder::Document';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Document - a {json:api} document building class

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

    use PONAPI::Document;

    my $document = PONAPI::Document->new(
        version  => $version,
        req_path => $req_path,
        req_base => $req_base,
    );

    my $resource = $document->add_resource( type => 'foo', id => 1 )
                            ->add_attributes({ ... })
                            ->add_self_link;
    $resource->add_relationship(%$_) for ...;

    # If we want multiple resources in one response:
    $document->convert_to_collection;
    $document->add_resource() # go crazy!

    # If we have an error at some point:
    $document->raise_error( 418, 'TEA TIME' );

    # And once we are done, return a valid {json:api} document
    # as a perl hash, which you can later turn into JSON.
    my $result = $document->build;

=head1 DESCRIPTION

C<PONAPI::Document> lets you build {json:api} compliant documents.

You'll want to refer to the L<{json:api} spec|http://jsonapi.org/format>
when using this class.

=head1 METHODS

=over

=item * new

Creates a new document object.  Requires C<version>.

You may optionally provide C<req_base> and C<req_path>.

=item * req_base

The base of the request.  Used to create links.  Empty string by default.

    # Without req_base set:
    '/authors/1'

    # With req_base set to 'http://www.mygreatponapisite.com/'
    'http://www.mygreatponapisite.com/authors/1'

=item * req_path

Path to the current request.  Used to create pagination links.

=item * set_status

=item * status

HTTP status for the request.  Default is C<200>.

=item * version

C<{json:api}> version of the request.  This B<must> be set when creating the
object.

=item * add_meta( $meta_key => $value )

Adds an entry to the meta section of the document, under $meta_key.

=item * add_resource({ type => $type, id => $id })

Creates a new L<PONAPI::Document::Builder::Resource> object, with
type $type and id $id, and adds it to the document.

You can then call C<add_relationship> and C<add_attributes> on
this object, amongst other things;  See L<PONAPI::Document::Builder::Resource>
for all the ways to add information to this object.

=item * add_null_resource

Adds a null resource to the object.

=item * convert_to_collection

By default, all documents hold a single resource in their data section.
However, if C<convert_to_collection> is called on a resource, the data
section will instead hold an arrayref of resources.

    # Originally:
    { data: { type => 'foo', id => 1, attributes => ... } }

    # After convert_to_collection
    { data: [ { type => 'foo', id => 1, attributes => ... }, ] }

=item * is_collection

Returns true if the object holds a collection.

=item * add_included({ type => $type, id => $id })

Similarly to C<add_resource>, returns a L<PONAPI::Document::Builder::Resource>
object of the given type and id, and adds it to the C<included> section
of the document.

=item * add_link( $link_type => $url )

=item * add_links( $link_type => $url, ... )

Adds links to the C<links> section of the document.

=item * add_self_link

Convenience method that adds a link to the current object into the C<links>
section.

=item * add_pagination_links(%links)

Adds the provided pagination links to the C<links> section.

    $obj->add_pagination_links(
        first => ...,
        self  => ...,
        prev  => ...,
        next  => ...,
    );

=item * build

Creates a document out of the current state of the object.

=item * parent

Returns the immediate parent of this object, or undef.  See also L<is_root>

=item * is_root

Returns true if we are the root of the document tree.

=item * find_root

Returns the root document.

=item * raise_error( $http_status, $reason )

Creates an error document.

=item * has_errors

=item * has_errors_builder

=item * has_included

=item * has_link

=item * has_links

=item * has_links_builder

=item * has_parent

=item * has_resource

=item * has_resource_builders

=item * has_resources

=item * has_status

=item * has_meta

These do what you would expect.

=back

=head1 BUGS, CONTACT AND SUPPORT

For reporting bugs or submitting patches, please use the github
bug tracker at L<https://github.com/mickeyn/PONAPI>.

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
