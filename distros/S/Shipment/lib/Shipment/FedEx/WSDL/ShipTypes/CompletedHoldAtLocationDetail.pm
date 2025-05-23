package Shipment::FedEx::WSDL::ShipTypes::CompletedHoldAtLocationDetail;
$Shipment::FedEx::WSDL::ShipTypes::CompletedHoldAtLocationDetail::VERSION = '3.10';
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

my %HoldingLocation_of :ATTR(:get<HoldingLocation>);
my %HoldingLocationType_of :ATTR(:get<HoldingLocationType>);

__PACKAGE__->_factory(
    [ qw(        HoldingLocation
        HoldingLocationType

    ) ],
    {
        'HoldingLocation' => \%HoldingLocation_of,
        'HoldingLocationType' => \%HoldingLocationType_of,
    },
    {
        'HoldingLocation' => 'Shipment::FedEx::WSDL::ShipTypes::ContactAndAddress',
        'HoldingLocationType' => 'Shipment::FedEx::WSDL::ShipTypes::FedExLocationType',
    },
    {

        'HoldingLocation' => 'HoldingLocation',
        'HoldingLocationType' => 'HoldingLocationType',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::ShipTypes::CompletedHoldAtLocationDetail

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
CompletedHoldAtLocationDetail from the namespace http://fedex.com/ws/ship/v9.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * HoldingLocation (min/maxOccurs: 0/1)

=item * HoldingLocationType (min/maxOccurs: 0/1)

=back

=head1 NAME

Shipment::FedEx::WSDL::ShipTypes::CompletedHoldAtLocationDetail

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::ShipTypes::CompletedHoldAtLocationDetail
   HoldingLocation =>  { # Shipment::FedEx::WSDL::ShipTypes::ContactAndAddress
     Contact =>  { # Shipment::FedEx::WSDL::ShipTypes::Contact
       ContactId =>  $some_value, # string
       PersonName =>  $some_value, # string
       Title =>  $some_value, # string
       CompanyName =>  $some_value, # string
       PhoneNumber =>  $some_value, # string
       PhoneExtension =>  $some_value, # string
       PagerNumber =>  $some_value, # string
       FaxNumber =>  $some_value, # string
       EMailAddress =>  $some_value, # string
     },
     Address =>  { # Shipment::FedEx::WSDL::ShipTypes::Address
       StreetLines =>  $some_value, # string
       City =>  $some_value, # string
       StateOrProvinceCode =>  $some_value, # string
       PostalCode =>  $some_value, # string
       UrbanizationCode =>  $some_value, # string
       CountryCode =>  $some_value, # string
       Residential =>  $some_value, # boolean
     },
   },
   HoldingLocationType => $some_value, # FedExLocationType
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
