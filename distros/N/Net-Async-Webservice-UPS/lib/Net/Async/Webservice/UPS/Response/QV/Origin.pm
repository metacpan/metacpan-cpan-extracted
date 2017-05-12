package Net::Async::Webservice::UPS::Response::QV::Origin;
$Net::Async::Webservice::UPS::Response::QV::Origin::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::QV::Origin::DIST = 'Net-Async-Webservice-UPS';
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

# ABSTRACT: a Quantum View "origin" event


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


has activity_location => (
    is => 'ro',
    isa => Address,
);


has bill_to_account_number => (
    is => 'ro',
    isa => Str,
);


has bill_to_account_option => (
    is => 'ro',
    isa => Str,
);


has scheduled_delivery_date_time => (
    is => 'ro',
    isa => DateTimeT,
);

sub BUILDARGS {
    my ($class,$hashref) = @_;
    if (@_>2) { shift; $hashref={@_} };

    if (any { /^[A-Z]/ } keys %$hashref) {
        state $date_parser = DateTime::Format::Strptime->new(
            pattern => '%Y%m%d%H%M%S',
        );
        set_implied_argument($hashref);

        return {
            in_if(tracking_number=>'TrackingNumber'),
            in_if(shipper_number=>'ShipperNumber'),
            in_object_array_if(shipment_reference => 'ShipmentReferenceNumber', 'Net::Async::Webservice::UPS::Response::QV::Reference'),
            in_object_array_if(package_reference => 'PackageReferenceNumber', 'Net::Async::Webservice::UPS::Response::QV::Reference'),
            ( $hashref->{Date} ? ( date_time => $date_parser->parse_datetime($hashref->{Date}.$hashref->{Time}) ) : () ),
            in_object_if(activity_location => 'ActivityLocation', 'Net::Async::Webservice::UPS::Address'),
            pair_if(bill_to_account_number => $hashref->{BillToAccount}{Number}),
            pair_if(bill_to_account_option => $hashref->{BillToAccount}{Option}),
            ( $hashref->{ScheduledDeliveryDate} ? ( scheduled_delivery_date_time => $date_parser->parse_datetime($hashref->{ScheduledDeliveryDate}.$hashref->{ScheduledDeliveryTime}) ) : () ),
        };
    }
    return $hashref;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::QV::Origin - a Quantum View "origin" event

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Object representing the
C<QuantumViewEvents/SubscriptionEvents/SubscriptionFile/Origin>
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

Optional L<DateTime>, date and time that the package is picked up at
the origin, most probably with a floating timezone.

=head2 C<activity_location>

Optional L<Net::Async::Webservice::UPS::Address>, geographic location
where an activity occurred during a movement of a package or shipment.

=head2 C<bill_to_account_number>

Optional string, the UPS Account number to which the shipping charges
were billed.

=head2 C<bill_to_account_option>

Optional string, indicates how shipping charges for the package were
billed. Valid Values: 01 Shipper, 02 Consignee Billing , 03 Third
Party, 04 Freight Collect.

=head2 C<scheduled_delivery_date_time>

Optional L<DateTime>, scheduled delivery date for destination address,
most probably with a floating timezone.

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
