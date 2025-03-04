package Shipment::FedEx::WSDL::ShipTypes::TrackingId;
$Shipment::FedEx::WSDL::ShipTypes::TrackingId::VERSION = '3.10';
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

my %TrackingIdType_of :ATTR(:get<TrackingIdType>);
my %FormId_of :ATTR(:get<FormId>);
my %UspsApplicationId_of :ATTR(:get<UspsApplicationId>);
my %TrackingNumber_of :ATTR(:get<TrackingNumber>);

__PACKAGE__->_factory(
    [ qw(        TrackingIdType
        FormId
        UspsApplicationId
        TrackingNumber

    ) ],
    {
        'TrackingIdType' => \%TrackingIdType_of,
        'FormId' => \%FormId_of,
        'UspsApplicationId' => \%UspsApplicationId_of,
        'TrackingNumber' => \%TrackingNumber_of,
    },
    {
        'TrackingIdType' => 'Shipment::FedEx::WSDL::ShipTypes::TrackingIdType',
        'FormId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'UspsApplicationId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'TrackingNumber' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'TrackingIdType' => 'TrackingIdType',
        'FormId' => 'FormId',
        'UspsApplicationId' => 'UspsApplicationId',
        'TrackingNumber' => 'TrackingNumber',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::ShipTypes::TrackingId

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
TrackingId from the namespace http://fedex.com/ws/ship/v9.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * TrackingIdType (min/maxOccurs: 0/1)

=item * FormId (min/maxOccurs: 0/1)

=item * UspsApplicationId (min/maxOccurs: 0/1)

=item * TrackingNumber (min/maxOccurs: 0/1)

=back

=head1 NAME

Shipment::FedEx::WSDL::ShipTypes::TrackingId

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::ShipTypes::TrackingId
   TrackingIdType => $some_value, # TrackingIdType
   FormId =>  $some_value, # string
   UspsApplicationId =>  $some_value, # string
   TrackingNumber =>  $some_value, # string
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
