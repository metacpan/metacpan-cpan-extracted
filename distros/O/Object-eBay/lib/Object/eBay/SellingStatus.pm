package Object::eBay::SellingStatus;
our $VERSION = '0.5.1';

use Class::Std; {
    use warnings;
    use strict;
    use base qw( Object::eBay );

    # SellingStatus is a second-class citizen because there's no eBay API
    # call that returns just a SellingStatus object.
    sub api_call       { q{} };
    sub response_field { q{} };

    __PACKAGE__->simple_attributes(qw(
        BidCount
        ListingStatus
        QuantitySold
    ));
    __PACKAGE__->complex_attributes({
        CurrentPrice => {
            class => 'Currency',
        },
        ConvertedCurrentPrice => {
            class => 'Currency',
        },
        HighBidder => {
            class => 'User',
        },
    });
}

1;

__END__

=head1 NAME

Object::eBay::SellingStatus - Represents an item's selling status

=head1 SYNOPSIS

    # Assuming that $item has an Object::eBay::Item object
    my $price = $item->selling_status->current_price;

=head1 DESCRIPTION

Represents the selling status information for an eBay item.

=head1 METHODS 

=head2 new

Objects of this class cannot be constructed directly.  They are returned as
the result of method calls on other objects.

=head2 bid_count

Returns the number of bids which have been placed on this item so far.

=head2 converted_current_price

Returns an L<Object::eBay::Currency> object indicating the price of an item
converted to the currency of the site which responded to the API call.  This
is probably going to be in U.S. Dollars.

=head2 current_price

Returns an L<Object::eBay::Currency> object indicating the price of an item.
The price will be in whatever currency the seller designated.

=head2 high_bidder

Returns an L<Object::eBay::User> object indicating which user is the current
high bidder.

=head2 listing_status

Returns one of the following statuses about the listing.  See eBay's
GetItem documentation at
L<http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/GetItem.html> for
the meaning of each term.

    * Active
    * Completed
    * Ended
    * Custom (eBay internal or future use only)
    * CustomCode (eBay internal or future use only)

See also L<Object::eBay::Item/is_ended>.

=head2 quantity_sold

Returns the number of items sold during this auction.  If the auction had a
successful buyer, the value will be greater than 0.  Otherwise, it will be 0.

=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

Object::eBay::SellingStatus requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over 4

=item * Class::Std

=item * Object::eBay

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-object-ebay-sellingstatus at rt.cpan.org>, or through the web interface at
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
 
