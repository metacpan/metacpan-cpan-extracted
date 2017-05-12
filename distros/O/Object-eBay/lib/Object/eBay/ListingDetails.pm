package Object::eBay::ListingDetails;
our $VERSION = '0.5.1';

use Class::Std; {
    use warnings;
    use strict;
    use base qw( Object::eBay );

    # ListingDetails is a second-class citizen because there's no eBay API
    # call that returns just a ListingDetails object.
    sub api_call       { q{} };
    sub response_field { q{} };

    __PACKAGE__->simple_attributes(qw{
        EndTime
        StartTime
    });

    __PACKAGE__->complex_attributes({
        BuyItNowAvailable => {  # we'll wrap this in is_buy_it_now_available
            class => 'Boolean',
        }
    });

    # this is necessary because BuyItNowAvailable is missing
    # if the BIN price is 0
    sub is_buy_it_now_available {
        my ($self) = @_;
        my $answer = eval { $self->buy_it_now_available };
        my $exception = $@;
        return $answer if not $exception;

        if ( $exception =~ m/Can't find 'BuyItNowAvailable' via/ ) {
            return Object::eBay::Boolean->new({
                object_details => 'false',
            });
        }
        die $exception;  # rethrow the exception
    }

    sub end_datetime {
        my ($self) = @_;
        my $iso = $self->end_time or die "EndTime was unavailable\n";
        return $self->_make_datetime($iso);
    }

    sub start_datetime {
        my ($self) = @_;
        my $iso = $self->start_time or die "StartTime was unavailable\n";
        return $self->_make_datetime($iso);
    }
}

1;

__END__

=head1 NAME

Object::eBay::ListingDetails - Represents an item's listing details

=head1 SYNOPSIS

    # assuming that $item contains an Object::eBay::Item object
    my $end_time = $item->listing_details->end_time();
    print "Ends: $end_time\n";   # "Ends: 2005-09-03T12:18:19.21.000Z"

=head1 DESCRIPTION

Represents listing details about an eBay item.

=head1 METHODS 

=head2 new

Objects of class Object::eBay::ListingDetails cannot be constructed directly.

=head2 end_datetime

Similar to L</end_time> except it returns a L<DateTime> object.
If this method is invoked, you must have a version of the L<DateTime>
package installed.

=head2 end_time

Returns an ISO8601 formatted string indicating the UTC time that the item
is scheduled to end.  If the item has ended, it indicates the time when
the item ended.

=head2 is_buy_it_now_available

Returns an L<Object::eBay::Boolean> object indicating whether or not
this auction has buy it now available at the moment.  An auction might
be listed with a Buy It Now price but once a bid is placed, Buy It Now
is no longer available.  There are some other business rules which
might affect whether or not Buy It Now is available.  See
L<http://xrl.us/dwo72> for some details.

=head2 start_datetime

Similar to L</start_time> except it returns a L<DateTime> object.
If this method is invoked, you must have a version of the L<DateTime>
package installed.

=head2 start_time

Returns an ISO8601 formatted string indicating the UTC time that the item
started.


=head1 DIAGNOSTICS

None

=head1 CONFIGURATION AND ENVIRONMENT

Object::eBay::ListingDetails requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over 4

=item * Class::Std

=item * Object::eBay

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-object-ebay-listingdetails at rt.cpan.org>, or through the web interface at
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
 
