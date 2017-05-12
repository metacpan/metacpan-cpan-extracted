package Net::PMP::CollectionDoc;
use Moose;
use Carp;
use Data::Dump qw( dump );
use Net::PMP::TypeConstraints;
use Net::PMP::CollectionDoc::Links;
use Net::PMP::CollectionDoc::Items;
use UUID::Tiny ':std';
use JSON;
use Try::Tiny;

our $VERSION = '0.006';

# the 'required' flag on these attributes should match
# the core CollectionDoc schema:
# https://api.pmp.io/schemas/core

has 'href' => (
    is       => 'rw',
    isa      => 'Net::PMP::Type::Href',
    required => 0,
    coerce   => 1,
);
has 'links'      => ( is => 'ro', isa => 'HashRef', required => 0, );
has 'attributes' => ( is => 'ro', isa => 'HashRef', required => 0, );
has 'version' =>
    ( is => 'ro', isa => 'Str', required => 1, default => sub {'1.0'}, );
has 'items' => ( is => 'ro', isa => 'ArrayRef', required => 0, );

=head1 NAME

Net::PMP::CollectionDoc - Collection.doc+JSON object for Net::PMP::Client

=head1 SYNOPSIS

 my $doc = $pmp_client->get_doc();
 printf("API version: %s\n", $doc->version);
 my $query_links = $doc->get_links('query');

=head1 DESCRIPTION

Net::PMP::CollectionDoc represents the PMP API media type L<https://github.com/publicmediaplatform/pmpdocs/wiki/Collection.doc-JSON-Media-Type>.

=head1 METHODS

=head2 href

The unique identifier. See L<http://cdoc.io/spec.html#guid-vs-href>.

=head2 items

Returns arrayref of child items. These are returned as a convenience from the server
and are not a native part of the CollectionDoc.

=head2 get_links( I<type> )

Returns Net::PMP::CollectionDoc::Links object for I<type>, which may be one of (for example):

=over

=item creator

=item edit

=item navigation

=item query

=item permission

=back

=head2 links

Returns hashref of link data.

=head2 attributes

Returns hashref of attribute data.

=head2 version

Returns API version string.

=cut

sub get_links {
    my $self  = shift;
    my $type  = shift or croak "type required";
    my $links = $self->links->{$type} or croak "No such type $type";
    return Net::PMP::CollectionDoc::Links->new(
        type  => $type,
        links => $links
    );
}

=head2 get_items

Returns L<Net::PMP::CollectionDoc::Items> object, unlike the B<items>
accessor method, which returns the raw arrayref.

=cut

sub get_items {
    my $self = shift;
    if ( !$self->items ) {
        croak "No items defined for CollectionDoc";
    }
    my $navlinks = $self->get_links('navigation');
    my $navself  = $navlinks->rels('self')->[0];
    my $total    = $navself->totalitems;
    return Net::PMP::CollectionDoc::Items->new(
        items    => $self->items,
        navlinks => $navlinks,
        total    => $total,
    );
}

=head2 has_items

Returns total number of items this CollectionDoc refers to.
B<NOTE> this is not the current result set, but the server-side total.
I.e., paging is ignored.

=cut

sub has_items {
    my $self = shift;
    if ( !$self->items ) {
        return 0;
    }
    my $navlinks = $self->get_links('navigation');
    my $navself  = $navlinks->rels('self')->[0];
    return $navself->totalitems;
}

=head2 query(I<urn>)

Returns L<Net::PMP::CollectionDoc::Link> object matching I<urn>,
or undef if no match is found.

=cut

sub query {
    my $self        = shift;
    my $urn         = shift or croak "URN required";
    my $query_links = $self->get_links('query');
    my $rels        = $query_links->rels($urn);
    if (@$rels) {
        return $rels->[0];    # first link found
    }
    return undef;
}

=head2 get_title

Returns C<title> attribute value.

=cut

sub get_title {
    my $self = shift;
    return $self->attributes->{title};
}

=head2 get_profile

Returns first C<profile> link C<href> value.

=cut

sub get_profile {
    my $self = shift;
    return $self->links->{profile}->[0]->{href};
}

=head2 get_uri

Returns the C<href> string from the C<navigation> link
representing this CollectionDoc.

=cut

sub get_uri {
    my $self = shift;
    if ( $self->href ) { return $self->href }
    if ( $self->links and $self->links->{navigation} ) {
        my $nav      = $self->get_links('navigation');
        my $nav_self = $nav->rels('self')->[0];
        if ($nav_self) {
            return $nav_self->href;
        }
        else {
            return $self->links->{navigation}->[0]->{href};
        }
    }

    return $self->get_self_uri();
}

=head2 get_publish_uri([I<edit_link>])

Returns the C<href> string from the C<edit> link
representing this CollectionDoc.

I<edit_link> may be passed explicitly, which is
usually necessary for saving a doc the first time.

=cut

sub get_publish_uri {
    my $self      = shift;
    my $edit_link = shift;
    if (    $self->links
        and $self->links->{edit} )
    {
        $edit_link
            = $self->get_links('edit')
            ->rels('urn:collectiondoc:form:documentsave')->[0];
    }
    if ($edit_link) {
        my $guid = $self->get_guid() || $self->create_guid();
        my $uri = $edit_link->as_uri( { guid => $guid } );
        return $uri;
    }
    croak "No edit link defined in Doc and none passed to get_publish_uri()";
}

=head2 get_self_uri

Returns canonical URI for Doc per 'self' link.

=cut

sub get_self_uri {
    my $self = shift;
    if ( $self->links and exists $self->links->{self} ) {
        return $self->links->{self}->[0]->{href};
    }
    return '';
}

=head2 set_uri(I<uri>)

Sets the C<href> string for the C<navigation> link
representing this CollectionDoc.

=cut

sub set_uri {
    my $self = shift;
    my $uri = shift or croak "uri required";
    if ( $self->links and $self->links->{self} ) {
        $self->links->{self}->[0]->{href} = $uri;
    }
    elsif ( $self->links and $self->links->{navigation} ) {
        for my $link ( @{ $self->links->{navigation} } ) {
            if ( $link->{rel} eq 'urn:collectiondoc:navigation:self' ) {
                $link->{href} = $uri;
            }
        }
    }
    else {
        $self->{links}->{self}->[0]->{href} = $uri;
    }
}

=head2 get_guid

Returns the C<guid> attribute.

=cut

sub get_guid {
    my $self = shift;
    if ( $self->attributes and $self->attributes->{guid} ) {
        return $self->attributes->{guid};
    }
    return undef;
}

=head2 create_guid([I<use_remote>])

Returns a v4-compliant UUID per PMP spec.

NOTE the I<use_remote> flag is currently ignored.

=cut

sub create_guid {
    my $self = shift;
    my $use_remote = shift || 0;
    if ($use_remote) {

        # TODO use PMP API to create a GUID
    }
    else {
        return lc( create_uuid_as_string(UUID_V4) );
    }
}

=head2 set_guid([<Iguid>])

Sets the guid attribute to I<guid>. If I<guid> is omitted,
the return value of create_guid() is used.

=cut

sub set_guid {
    my $self = shift;
    my $guid = shift || $self->create_guid();
    $self->attributes->{guid} = $guid;
    return $guid;
}

=head2 as_hash

Returns the CollectionDoc as a hashref. as_json() calls this method
internally.

=cut

sub as_hash {
    my $self = shift;
    my %hash;
    for my $m (qw( version attributes href )) {
        next if !defined $self->$m;
        $hash{$m} = $self->$m;
    }

    # must be defined but can be blank and server will set it
    $hash{href} ||= "";

    # items are Docs
    # but top-level "items" are just convenience.
    # only those in links are authoritative
    if ( $self->links and $self->links->{item} and @{ $self->links->{item} } )
    {
        $hash{links}->{item} = [];
        for my $item ( @{ $self->links->{item} } ) {
            if ( blessed $item) {
                push @{ $hash{links}->{item} }, $item->as_link_hash;
            }
            else {
                push @{ $hash{links}->{item} }, $item;
            }
        }
    }

    # flesh out links with anything required for save
    $hash{links}->{profile} = $self->links->{profile};
    if ( $self->get_uri and !$self->get_self_uri ) {
        $hash{links}->{self} = [ { href => $self->get_uri } ];
        $hash{href} ||= $self->get_uri;
    }

    # blacklist read-only links that come from the server
    # in order to make round-trips safe
    my %ro_links = map { $_ => 1 } qw( query edit auth navigation creator );
    for my $link ( keys %{ $self->links } ) {
        next if exists $hash{links}->{$link};
        next if exists $ro_links{$link};
        $hash{links}->{$link} = $self->links->{$link};
    }

    return \%hash;
}

=head2 as_link_hash

Returns minimal hashref describing CollectionDoc, suitable
for B<links> B<item> attribute. This method is called internally
by as_hash(); it automatically recurses for any descendent items.

=cut

sub as_link_hash {
    my $self = shift;
    my %hash = ( href => $self->get_uri() );
    if ( $self->links and $self->links->{item} ) {
        for my $iitem ( @{ $self->links->{item} } ) {
            if ( blessed $iitem) {
                push @{ $hash{links}->{item} }, $iitem->as_link_hash();
            }
            else {
                push @{ $hash{links}->{item} }, $iitem;
            }
        }
    }
    return \%hash;
}

=head2 as_json

Returns the CollectionDoc as a JSON-encoded string suitable for saving.

=cut

sub as_json {
    my $self = shift;
    my $json = try {
        encode_json( $self->as_hash );
    }
    catch {
        confess $_;    # re-throw with full stack trace.
        return '';     # we can't get here can we?
    };
    return $json;
}

=head2 add_item( I<child> )

Shortcut for:

  push @{ $doc->links->{item} }, $child->as_link_hash;

=cut

sub add_item {
    my $self = shift;
    my $child = shift or croak "child required";
    if ( !$child->isa('Net::PMP::CollectionDoc') ) {
        croak "child must be a Net::PMP::CollectionDoc object";
    }
    push @{ $self->{links}->{item} }, $child->as_link_hash;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::CollectionDoc


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-PMP/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut
