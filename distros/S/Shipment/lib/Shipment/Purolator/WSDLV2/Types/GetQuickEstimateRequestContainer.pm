package Shipment::Purolator::WSDLV2::Types::GetQuickEstimateRequestContainer;
$Shipment::Purolator::WSDLV2::Types::GetQuickEstimateRequestContainer::VERSION = '3.10';
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://purolator.com/pws/datatypes/v2' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Shipment::Purolator::WSDLV2::Types::RequestContainer);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %BillingAccountNumber_of :ATTR(:get<BillingAccountNumber>);
my %SenderPostalCode_of :ATTR(:get<SenderPostalCode>);
my %ReceiverAddress_of :ATTR(:get<ReceiverAddress>);
my %PackageType_of :ATTR(:get<PackageType>);
my %TotalWeight_of :ATTR(:get<TotalWeight>);

__PACKAGE__->_factory(
    [ qw(        BillingAccountNumber
        SenderPostalCode
        ReceiverAddress
        PackageType
        TotalWeight

    ) ],
    {
        'BillingAccountNumber' => \%BillingAccountNumber_of,
        'SenderPostalCode' => \%SenderPostalCode_of,
        'ReceiverAddress' => \%ReceiverAddress_of,
        'PackageType' => \%PackageType_of,
        'TotalWeight' => \%TotalWeight_of,
    },
    {
        'BillingAccountNumber' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'SenderPostalCode' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'ReceiverAddress' => 'Shipment::Purolator::WSDLV2::Types::ShortAddress',
        'PackageType' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'TotalWeight' => 'Shipment::Purolator::WSDLV2::Types::TotalWeight',
    },
    {

        'BillingAccountNumber' => 'BillingAccountNumber',
        'SenderPostalCode' => 'SenderPostalCode',
        'ReceiverAddress' => 'ReceiverAddress',
        'PackageType' => 'PackageType',
        'TotalWeight' => 'TotalWeight',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::Purolator::WSDLV2::Types::GetQuickEstimateRequestContainer

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
GetQuickEstimateRequestContainer from the namespace http://purolator.com/pws/datatypes/v2.

GetQuickEstimateRequest

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * BillingAccountNumber (min/maxOccurs: 1/1)

=item * SenderPostalCode (min/maxOccurs: 1/1)

=item * ReceiverAddress (min/maxOccurs: 1/1)

=item * PackageType (min/maxOccurs: 1/1)

=item * TotalWeight (min/maxOccurs: 0/1)

=back

=head1 NAME

Shipment::Purolator::WSDLV2::Types::GetQuickEstimateRequestContainer

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::Purolator::WSDLV2::Types::GetQuickEstimateRequestContainer
   BillingAccountNumber =>  $some_value, # string
   SenderPostalCode =>  $some_value, # string
   ReceiverAddress =>  { # Shipment::Purolator::WSDLV2::Types::ShortAddress
     City =>  $some_value, # string
     Province =>  $some_value, # string
     Country =>  $some_value, # string
     PostalCode =>  $some_value, # string
   },
   PackageType =>  $some_value, # string
   TotalWeight =>  { # Shipment::Purolator::WSDLV2::Types::TotalWeight
     Value =>  $some_value, # int
     WeightUnit => $some_value, # WeightUnit
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
