package Shipment::UPS::WSDL::ShipTypes::ShipToType;
$Shipment::UPS::WSDL::ShipTypes::ShipToType::VERSION = '3.10';
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://www.ups.com/XMLSchema/XOLTWS/Ship/v1.0' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Shipment::UPS::WSDL::ShipTypes::CompanyInfoType);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %Name_of :ATTR(:get<Name>);
my %AttentionName_of :ATTR(:get<AttentionName>);
my %TaxIdentificationNumber_of :ATTR(:get<TaxIdentificationNumber>);
my %Phone_of :ATTR(:get<Phone>);
my %FaxNumber_of :ATTR(:get<FaxNumber>);
my %EMailAddress_of :ATTR(:get<EMailAddress>);
my %Address_of :ATTR(:get<Address>);
my %LocationID_of :ATTR(:get<LocationID>);

__PACKAGE__->_factory(
    [ qw(        Name
        AttentionName
        TaxIdentificationNumber
        Phone
        FaxNumber
        EMailAddress
        Address
        LocationID

    ) ],
    {
        'Name' => \%Name_of,
        'AttentionName' => \%AttentionName_of,
        'TaxIdentificationNumber' => \%TaxIdentificationNumber_of,
        'Phone' => \%Phone_of,
        'FaxNumber' => \%FaxNumber_of,
        'EMailAddress' => \%EMailAddress_of,
        'Address' => \%Address_of,
        'LocationID' => \%LocationID_of,
    },
    {
        'Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'AttentionName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'TaxIdentificationNumber' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Phone' => 'Shipment::UPS::WSDL::ShipTypes::ShipPhoneType',
        'FaxNumber' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'EMailAddress' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Address' => 'Shipment::UPS::WSDL::ShipTypes::ShipToAddressType',
        'LocationID' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'Name' => 'Name',
        'AttentionName' => 'AttentionName',
        'TaxIdentificationNumber' => 'TaxIdentificationNumber',
        'Phone' => 'Phone',
        'FaxNumber' => 'FaxNumber',
        'EMailAddress' => 'EMailAddress',
        'Address' => 'Address',
        'LocationID' => 'LocationID',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::UPS::WSDL::ShipTypes::ShipToType

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
ShipToType from the namespace http://www.ups.com/XMLSchema/XOLTWS/Ship/v1.0.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * FaxNumber (min/maxOccurs: 0/1)

=item * EMailAddress (min/maxOccurs: 0/1)

=item * Address (min/maxOccurs: 1/1)

=item * LocationID (min/maxOccurs: 0/1)

=back

=head1 NAME

Shipment::UPS::WSDL::ShipTypes::ShipToType

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::UPS::WSDL::ShipTypes::ShipToType
   FaxNumber =>  $some_value, # string
   EMailAddress =>  $some_value, # string
   Address =>  { # Shipment::UPS::WSDL::ShipTypes::ShipToAddressType
     ResidentialAddressIndicator =>  $some_value, # string
   },
   LocationID =>  $some_value, # string
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
