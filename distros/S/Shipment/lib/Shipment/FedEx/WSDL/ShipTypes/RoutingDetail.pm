package Shipment::FedEx::WSDL::ShipTypes::RoutingDetail;
$Shipment::FedEx::WSDL::ShipTypes::RoutingDetail::VERSION = '3.10';
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://fedex.com/ws/ship/v9' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %ShipmentRoutingDetail_of :ATTR(:get<ShipmentRoutingDetail>);
my %AstraDetails_of :ATTR(:get<AstraDetails>);

__PACKAGE__->_factory(
    [ qw(        ShipmentRoutingDetail
        AstraDetails

    ) ],
    {
        'ShipmentRoutingDetail' => \%ShipmentRoutingDetail_of,
        'AstraDetails' => \%AstraDetails_of,
    },
    {
        'ShipmentRoutingDetail' => 'Shipment::FedEx::WSDL::ShipTypes::ShipmentRoutingDetail',
        'AstraDetails' => 'Shipment::FedEx::WSDL::ShipTypes::RoutingAstraDetail',
    },
    {

        'ShipmentRoutingDetail' => 'ShipmentRoutingDetail',
        'AstraDetails' => 'AstraDetails',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::ShipTypes::RoutingDetail

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
RoutingDetail from the namespace http://fedex.com/ws/ship/v9.

Information about the routing, origin, destination and delivery of a shipment.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * ShipmentRoutingDetail (min/maxOccurs: 0/1)

=item * AstraDetails (min/maxOccurs: 0/unbounded)

=back

=head1 NAME

Shipment::FedEx::WSDL::ShipTypes::RoutingDetail

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::ShipTypes::RoutingDetail
   ShipmentRoutingDetail =>  { # Shipment::FedEx::WSDL::ShipTypes::ShipmentRoutingDetail
     UrsaPrefixCode =>  $some_value, # string
     UrsaSuffixCode =>  $some_value, # string
     OriginLocationId =>  $some_value, # string
     OriginServiceArea =>  $some_value, # string
     DestinationLocationId =>  $some_value, # string
     DestinationServiceArea =>  $some_value, # string
     DestinationLocationStateOrProvinceCode =>  $some_value, # string
     DeliveryDate =>  $some_value, # date
     DeliveryDay => $some_value, # DayOfWeekType
     CommitDate =>  $some_value, # date
     CommitDay => $some_value, # DayOfWeekType
     TransitTime => $some_value, # TransitTimeType
     MaximumTransitTime => $some_value, # TransitTimeType
     AstraPlannedServiceLevel =>  $some_value, # string
     AstraDescription =>  $some_value, # string
     PostalCode =>  $some_value, # string
     StateOrProvinceCode =>  $some_value, # string
     CountryCode =>  $some_value, # string
     AirportId =>  $some_value, # string
   },
   AstraDetails =>  { # Shipment::FedEx::WSDL::ShipTypes::RoutingAstraDetail
     TrackingId =>  { # Shipment::FedEx::WSDL::ShipTypes::TrackingId
       TrackingIdType => $some_value, # TrackingIdType
       FormId =>  $some_value, # string
       UspsApplicationId =>  $some_value, # string
       TrackingNumber =>  $some_value, # string
     },
     Barcode =>  { # Shipment::FedEx::WSDL::ShipTypes::StringBarcode
       Type => $some_value, # StringBarcodeType
       Value =>  $some_value, # string
     },
     AstraHandlingText =>  $some_value, # string
     AstraLabelElements =>  { # Shipment::FedEx::WSDL::ShipTypes::AstraLabelElement
       Number =>  $some_value, # int
       Content =>  $some_value, # string
     },
   },
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=head1 AUTHOR

Andrew Baerg <baergaj@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andrew Baerg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
