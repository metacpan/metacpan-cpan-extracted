package Net::Async::Webservice::UPS::Response::QV::Generic;
$Net::Async::Webservice::UPS::Response::QV::Generic::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::QV::Generic::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Types::Standard qw(Str ArrayRef HashRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use Net::Async::Webservice::UPS::Response::Utils qw(:all);
use Types::DateTime DateTime => { -as => 'DateTimeT' };
use DateTime::Format::Strptime;
use List::AllUtils 'any';
use namespace::autoclean;

# ABSTRACT: a Quantum View "generic" event


has package_reference => (
    is => 'ro',
    isa => ArrayRef[QVReference],
);


has shipment_reference => (
    is => 'ro',
    isa => ArrayRef[QVReference],
);


has shipper_number => (
    is => 'ro',
    isa => Str,
);


has tracking_number => (
    is => 'ro',
    isa => Str,
);


has date_time => (
    is => 'ro',
    isa => DateTimeT,
);


has activity_type => (
    is => 'ro',
    isa => Str,
);


has service => (
    is => 'ro',
    isa => HashRef,
);


has rescheduled_delivery_date => (
    is => 'ro',
    isa => DateTimeT,
);


has bill_to_account_number => (
    is => 'ro',
    isa => Str,
);


has bill_to_account_option => (
    is => 'ro',
    isa => Str,
);


has ship_to_location_id => (
    is => 'ro',
    isa => Str,
);


has ship_to_receiving_name => (
    is => 'ro',
    isa => Str,
);


has ship_to_bookmark => (
    is => 'ro',
    isa => Str,
);


has failure_email => (
    is => 'ro',
    isa => Str,
);


has failure_code => (
    is => 'ro',
    isa => Str,
);

sub BUILDARGS {
    my ($class,$hashref) = @_;
    if (@_>2) { shift; $hashref={@_} };

    if (any { /^[A-Z]/ } keys %$hashref) {
        state $date_parser = DateTime::Format::Strptime->new(
            pattern => '%Y%m%d',
        );

        set_implied_argument($hashref);
        return {
            in_if(activity_type=>'ActivityType'),
            in_if(tracking_number=>'TrackingNumber'),
            in_if(shipper_number=>'ShipperNumber'),
            in_object_array_if(shipment_reference => 'ShipmentReferenceNumber', 'Net::Async::Webservice::UPS::Response::QV::Reference'),
            in_object_array_if(package_reference => 'PackageReferenceNumber', 'Net::Async::Webservice::UPS::Response::QV::Reference'),
            in_if(service => 'Service'),
            in_datetime_if(date_time => 'Activity'),
            pair_if(bill_to_account_number => $hashref->{BillToAccount}{Number}),
            pair_if(bill_to_account_option => $hashref->{BillToAccount}{Option}),
            pair_if(ship_to_location_id => $hashref->{ShipTo}{LocationID}),
            pair_if(ship_to_receiving_name => $hashref->{ShipTo}{ReceivingAddressName}),
            pair_if(ship_to_bookmark => $hashref->{ShipTo}{Bookmark}),

            ( $hashref->{RescheduledDeliveryDate} ? ( rescheduled_delivery_date => $date_parser->parse_datetime($hashref->{RescheduledDeliveryDate}) ) : () ),

            pair_if(failure_email => $hashref->{FailureNotification}{FailedEmailAddress} ),
            pair_if(failure_code => $hashref->{FailureNotification}{FailureNotificationCode}{Code} ),
        }
    }
    return $hashref;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::QV::Generic - a Quantum View "generic" event

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Object representing the
C<QuantumViewEvents/SubscriptionEvents/SubscriptionFile/Generic>
elements in the Quantum View response. Attribute descriptions come
from the official UPS documentation.

=head1 ATTRIBUTES

=head2 C<package_reference>

Optional array of
L<Net::Async::Webservice::UPS::Response::QV::Reference>, package-level
reference numbers.

=head2 C<shipment_reference>

Optional array of
L<Net::Async::Webservice::UPS::Response::QV::Reference>, shipment-level
reference numbers.

=head2 C<shipper_number>

Optional string, shipper's six digit alphanumeric account number.

=head2 C<tracking_number>

Optional string, package's 1Z tracking number.

=head2 C<date_time>

Optional L<DateTime>, date and time of package activity, most probably
with a floating timezone.. If L</activity_type> is C<TC> then this is
the date of first USPS scan.

=head2 C<activity_type>

Optional string, unique identifier that defines the type of
activity. C<VM> = Void for Manifest C<UR> = Undeliverable
Returns. C<IR> = Invoice Removal Successful. C<TC> = Transport Company
USPS scan C<PS> = 'Postal Service Possession Scan'. C<FN> = UPS Access
Point/Alternate Delivery Location Email Notification Failure. C<DS> =
Destination Scan.

=head2 C<service>

Optional hashref, service code (key C<Code>) and description (key
C<Description>, optional).

=head2 C<rescheduled_delivery_date>

Optional string,

=head2 C<bill_to_account_number>

Optional string, the UPS Account number to which the shipping charges
were billed.

=head2 C<bill_to_account_option>

Optional string, indicates how shipping charges for the package were
billed. Valid Values: 01 Shipper, 02 Consignee Billing , 03 Third
Party, 04 Freight Collect, 99 International Bill Option.

=head2 C<ship_to_location_id>

Optional string, location name that the package is shipped to.

=head2 C<ship_to_receiving_name>

Optional string, alias of the location where the package is received.

=head2 C<ship_to_bookmark>

Optional string. If the package data is not inside this
L<Net::Async::Webservice::UPS::Response::QV>, it will be in the
response you get by repeating the call to
L<Net::Async::Webservice::UPS/qv_events> with this bookmark.

=head2 C<failure_email>

Optional string, email address that failed when an attempt was made to
send email to the customer.

=head2 C<failure_code>

Optional string, failure notification code.

=for Pod::Coverage BUILDARGS

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
