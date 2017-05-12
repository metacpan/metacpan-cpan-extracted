package Object::eBay::Item;
our $VERSION = '0.5.1';

use Class::Std; {
    use warnings;
    use strict;
    use base qw( Object::eBay );
    use overload '""' => 'item_id', fallback => 1;
    use Object::eBay::Boolean;
    use Object::eBay::Attributes;
    use Object::eBay::Condition;

    sub api_call       { "GetItem" };
    sub response_field { "Item"    };

    __PACKAGE__->simple_attributes(qw{
        Country
        Title
        Quantity
    });

    __PACKAGE__->complex_attributes({
        AttributeSetArray => {
            class       => 'Attributes',
            DetailLevel => 'ItemReturnAttributes',
        },
        BuyItNowPrice => {
            class => 'Currency',
        },
        Seller => {
            class => 'User',
        },
        SellingStatus => {
            class => 'SellingStatus',
        },
        ListingDetails => {
            class => 'ListingDetails',
        },
        Description => {
            DetailLevel => 'ItemReturnDescription',
        },
        WatchCount => {
            IncludeWatchCount => 'true',
        },
    });

    sub item_id  { shift->api_inputs->{ItemID} }

    sub attributes {
        my $attributes = eval { shift->attribute_set_array };
        return $attributes if $attributes;

        # some auctions have no attributes at all
        # in this case, we want an empty Attributes object
        return Object::eBay::Attributes->new({ object_details => 'none' });
    }

    sub is_ended {
        my ($self) = @_;
        my $status = $self->selling_status->listing_status;
        die "eBay item #$self has no listing status\n" if not defined $status;

        my $true = Object::eBay::Boolean->true;
        my $false = Object::eBay::Boolean->false;

        return $false if $status eq 'Active';
        return $true  if $status eq 'Ended';
        return $true  if $status eq 'Completed';
        die "eBay item #$self has an unknown listing status: $status\n";
    }

    #########################################################################
    # Usage     : my @images = $item->pictures()
    # Purpose   : Combine various sources of pictures into one method
    # Returns   : a list of image URLs
    # Arguments : none
    # Throws    : no exceptions
    # Comments  : none
    # See Also  : n/a
    sub pictures {
        my ($self) = @_;

        # TODO this should probably be implemented in terms of other
        # methods instead of manually searching the details hash
        # but I haven't implement those other methods yet.

        my @places = (
            [qw( PictureDetails      GalleryURL    )],
            [qw( PictureDetails      PictureURL    )],
            [qw( SiteHostedPicture   PictureURL    )],  # deprecated
            [qw( VendorHostedPicture SelfHostedURL )],  # deprecated
        );
        
        my $details = $self->get_details();
        return if !$details;

        my @image_urls;
        PLACE:
        for my $place (@places) {
            my ($major, $minor) = @$place;
            next PLACE if !exists $details->{$major};
            next PLACE if !exists $details->{$major}{$minor};

            my $url = $details->{$major}{$minor};
            next PLACE if !defined $url;
            push @image_urls, ( ref $url eq 'ARRAY' ? @$url : $url );
        }

        return @image_urls;
    }

    # can't be done with complex_attributes because ConditionID and
    # ConditionDisplayName are at the same depth in the Item response
    sub condition {
        my ($self) = @_;
        my $id   = $self->get_details->{ConditionID};
        my $name = $self->get_details->{ConditionDisplayName};
        return if !$id && !$name;
        return Object::eBay::Condition->new({
            id   => $id,
            name => $name,
        });
    }
}

1;

__END__

=head1 NAME

Object::eBay::Item - Represents an item listed on eBay

=head1 SYNOPSIS

    # assuming that Object::eBay has already been initialized
    use Object::eBay::Item;
    my $item = Object::eBay::Item->new({ item_id => 12345678 });

    print "The item is titled '", $item->title(), "'\n";

=head1 DESCRIPTION

An Object::eBay::Item object represents an item that has been listed for sale
on eBay.

=head1 METHODS 

=head2 new

A single 'item_id' argument is required.  The value of the argument should be
the eBay item ID of the item you want to represent.

=head2 attributes

Returns an L<Object::eBay::Attributes> object representing all the attributes
about this item.  If you plan to use this method, you must specify
'attribute_set_array' (sorry) in the C<needs_methods> list when creating the
object (see L<Object::eBay/new>).  If you don't specify C<needs_methods>
correctly, this method will return incorrect results.

=head2 buy_it_now_price

Returns an L<Object::eBay::Currency> object indicating the "Buy It Now" price
for this item.  If the item has no Buy It Now price, a price of "0" is
returned.  Although this may not be optimal behavior, it adhere's to eBay's
usage.

=head2 condition

Returns an L<Object::eBay::Condition> object representing this item's
condition.  If condition information is not available, returns C<undef>.

=head2 country

Returns a code indicating the item's country.  This method may need to be
deprecated because the docs on eBay are contradictory.  Use it with caution.

=head2 description

Returns the HTML text of the item's description.  If you plan to use this
method, please specify 'description' in the C<needs_methods> list when
creating the object (see L<Object::eBay/new>).  If you don't specify
C<needs_methods> correctly, this method will return incorrect results.

=head2 is_ended

Returns an L<Object::eBay::Boolean> true value if the eBay auction for this
item has ended.  Otherwise, it returns a false object.

=head2 item_id

Returns the eBay item ID for this auction.  This is the same as the
"item_id" argument to L</new>.  This method also provides the value
when an Item object is used in string context.

=head2 listing_details

Returns a L<Object::eBay::ListingDetails> object.

=head2 pictures

Returns a list of URLs for the pictures associated with this item.  The eBay
API defines multiple ways in which images can be associated with a particular
item.  This method searches each of those ways and returns a list of all the
image URLs that it found.  If no images are found, an empty list is returned.
At this time, the URLs are simple scalars and not objects, however that may
change.  If the return value changes, the string context will still represent
the URL as it does now.

=head2 quantity

Returns the quantity for sale with this item.

=head2 seller

Returns a L<Object::eBay::User> object representing the item's seller.  Not
all methods of L<Object::eBay::User> are necessarily available.

=head2 selling_status

Returns a L<Object::eBay::SellingStatus> object 

=head2 title

Returns the title of the item.

=head2 watch_count

Returns the number of watches that have been place on this item via "My eBay"
If you plan to use this
method on an Object::eBay::Item object, please specify 'watch_count' in the
C<needs_methods> list when creating the object (see L</new>).  If you don't
specify C<needs_methods> correctly, this method will not be available.

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

Object::eBay::Item requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over 4

=item * Class::Std

=item * Object::eBay

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-object-ebay-item at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-eBay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Object::eBay

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Object-eBay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Object-eBay>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-eBay>

=item * Search CPAN

L<http://search.cpan.org/dist/Object-eBay>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2006 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
