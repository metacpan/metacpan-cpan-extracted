package Shipment::FedEx::WSDL::RateTypes::CommercialInvoice;
$Shipment::FedEx::WSDL::RateTypes::CommercialInvoice::VERSION = '3.10';
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://fedex.com/ws/rate/v9' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %Comments_of :ATTR(:get<Comments>);
my %FreightCharge_of :ATTR(:get<FreightCharge>);
my %TaxesOrMiscellaneousCharge_of :ATTR(:get<TaxesOrMiscellaneousCharge>);
my %PackingCosts_of :ATTR(:get<PackingCosts>);
my %HandlingCosts_of :ATTR(:get<HandlingCosts>);
my %SpecialInstructions_of :ATTR(:get<SpecialInstructions>);
my %DeclarationStatment_of :ATTR(:get<DeclarationStatment>);
my %PaymentTerms_of :ATTR(:get<PaymentTerms>);
my %Purpose_of :ATTR(:get<Purpose>);
my %PurposeOfShipmentDescription_of :ATTR(:get<PurposeOfShipmentDescription>);
my %CustomerInvoiceNumber_of :ATTR(:get<CustomerInvoiceNumber>);
my %OriginatorName_of :ATTR(:get<OriginatorName>);
my %TermsOfSale_of :ATTR(:get<TermsOfSale>);

__PACKAGE__->_factory(
    [ qw(        Comments
        FreightCharge
        TaxesOrMiscellaneousCharge
        PackingCosts
        HandlingCosts
        SpecialInstructions
        DeclarationStatment
        PaymentTerms
        Purpose
        PurposeOfShipmentDescription
        CustomerInvoiceNumber
        OriginatorName
        TermsOfSale

    ) ],
    {
        'Comments' => \%Comments_of,
        'FreightCharge' => \%FreightCharge_of,
        'TaxesOrMiscellaneousCharge' => \%TaxesOrMiscellaneousCharge_of,
        'PackingCosts' => \%PackingCosts_of,
        'HandlingCosts' => \%HandlingCosts_of,
        'SpecialInstructions' => \%SpecialInstructions_of,
        'DeclarationStatment' => \%DeclarationStatment_of,
        'PaymentTerms' => \%PaymentTerms_of,
        'Purpose' => \%Purpose_of,
        'PurposeOfShipmentDescription' => \%PurposeOfShipmentDescription_of,
        'CustomerInvoiceNumber' => \%CustomerInvoiceNumber_of,
        'OriginatorName' => \%OriginatorName_of,
        'TermsOfSale' => \%TermsOfSale_of,
    },
    {
        'Comments' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'FreightCharge' => 'Shipment::FedEx::WSDL::RateTypes::Money',
        'TaxesOrMiscellaneousCharge' => 'Shipment::FedEx::WSDL::RateTypes::Money',
        'PackingCosts' => 'Shipment::FedEx::WSDL::RateTypes::Money',
        'HandlingCosts' => 'Shipment::FedEx::WSDL::RateTypes::Money',
        'SpecialInstructions' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'DeclarationStatment' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'PaymentTerms' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Purpose' => 'Shipment::FedEx::WSDL::RateTypes::PurposeOfShipmentType',
        'PurposeOfShipmentDescription' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'CustomerInvoiceNumber' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'OriginatorName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'TermsOfSale' => 'Shipment::FedEx::WSDL::RateTypes::TermsOfSaleType',
    },
    {

        'Comments' => 'Comments',
        'FreightCharge' => 'FreightCharge',
        'TaxesOrMiscellaneousCharge' => 'TaxesOrMiscellaneousCharge',
        'PackingCosts' => 'PackingCosts',
        'HandlingCosts' => 'HandlingCosts',
        'SpecialInstructions' => 'SpecialInstructions',
        'DeclarationStatment' => 'DeclarationStatment',
        'PaymentTerms' => 'PaymentTerms',
        'Purpose' => 'Purpose',
        'PurposeOfShipmentDescription' => 'PurposeOfShipmentDescription',
        'CustomerInvoiceNumber' => 'CustomerInvoiceNumber',
        'OriginatorName' => 'OriginatorName',
        'TermsOfSale' => 'TermsOfSale',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::RateTypes::CommercialInvoice

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
CommercialInvoice from the namespace http://fedex.com/ws/rate/v9.

CommercialInvoice element is required for electronic upload of CI data. It will serve to create/transmit an Electronic Commercial Invoice through the FedEx Systems. Customers are responsible for printing their own Commercial Invoice.If you would likeFedEx to generate a Commercial Invoice and transmit it to Customs. for clearance purposes, you need to specify that in the ShippingDocumentSpecification element. If you would like a copy of the Commercial Invoice that FedEx generated returned to you in reply it needs to be specified in the ETDDetail/RequestedDocumentCopies element. Commercial Invoice support consists of maximum of 99 commodity line items.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * Comments (min/maxOccurs: 0/99)

=item * FreightCharge (min/maxOccurs: 0/1)

=item * TaxesOrMiscellaneousCharge (min/maxOccurs: 0/1)

=item * PackingCosts (min/maxOccurs: 0/1)

=item * HandlingCosts (min/maxOccurs: 0/1)

=item * SpecialInstructions (min/maxOccurs: 0/1)

=item * DeclarationStatment (min/maxOccurs: 0/1)

=item * PaymentTerms (min/maxOccurs: 0/1)

=item * Purpose (min/maxOccurs: 0/1)

=item * PurposeOfShipmentDescription (min/maxOccurs: 0/1)

=item * CustomerInvoiceNumber (min/maxOccurs: 0/1)

=item * OriginatorName (min/maxOccurs: 0/1)

=item * TermsOfSale (min/maxOccurs: 0/1)

=back

=head1 NAME

Shipment::FedEx::WSDL::RateTypes::CommercialInvoice

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::RateTypes::CommercialInvoice
   Comments =>  $some_value, # string
   FreightCharge =>  { # Shipment::FedEx::WSDL::RateTypes::Money
     Currency =>  $some_value, # string
     Amount =>  $some_value, # decimal
   },
   TaxesOrMiscellaneousCharge => {}, # Shipment::FedEx::WSDL::RateTypes::Money
   PackingCosts => {}, # Shipment::FedEx::WSDL::RateTypes::Money
   HandlingCosts => {}, # Shipment::FedEx::WSDL::RateTypes::Money
   SpecialInstructions =>  $some_value, # string
   DeclarationStatment =>  $some_value, # string
   PaymentTerms =>  $some_value, # string
   Purpose => $some_value, # PurposeOfShipmentType
   PurposeOfShipmentDescription =>  $some_value, # string
   CustomerInvoiceNumber =>  $some_value, # string
   OriginatorName =>  $some_value, # string
   TermsOfSale => $some_value, # TermsOfSaleType
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
