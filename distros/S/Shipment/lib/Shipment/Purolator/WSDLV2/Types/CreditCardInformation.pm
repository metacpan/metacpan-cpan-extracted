package Shipment::Purolator::WSDLV2::Types::CreditCardInformation;
$Shipment::Purolator::WSDLV2::Types::CreditCardInformation::VERSION = '3.10';
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://purolator.com/pws/datatypes/v2' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %Type_of :ATTR(:get<Type>);
my %Number_of :ATTR(:get<Number>);
my %Name_of :ATTR(:get<Name>);
my %ExpiryMonth_of :ATTR(:get<ExpiryMonth>);
my %ExpiryYear_of :ATTR(:get<ExpiryYear>);
my %CVV_of :ATTR(:get<CVV>);

__PACKAGE__->_factory(
    [ qw(        Type
        Number
        Name
        ExpiryMonth
        ExpiryYear
        CVV

    ) ],
    {
        'Type' => \%Type_of,
        'Number' => \%Number_of,
        'Name' => \%Name_of,
        'ExpiryMonth' => \%ExpiryMonth_of,
        'ExpiryYear' => \%ExpiryYear_of,
        'CVV' => \%CVV_of,
    },
    {
        'Type' => 'Shipment::Purolator::WSDLV2::Types::CreditCardType',
        'Number' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'ExpiryMonth' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'ExpiryYear' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'CVV' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'Type' => 'Type',
        'Number' => 'Number',
        'Name' => 'Name',
        'ExpiryMonth' => 'ExpiryMonth',
        'ExpiryYear' => 'ExpiryYear',
        'CVV' => 'CVV',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::Purolator::WSDLV2::Types::CreditCardInformation

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
CreditCardInformation from the namespace http://purolator.com/pws/datatypes/v2.

CreditCardInformation

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * Type (min/maxOccurs: 1/1)

=item * Number (min/maxOccurs: 1/1)

=item * Name (min/maxOccurs: 1/1)

=item * ExpiryMonth (min/maxOccurs: 1/1)

=item * ExpiryYear (min/maxOccurs: 1/1)

=item * CVV (min/maxOccurs: 1/1)

=back

=head1 NAME

Shipment::Purolator::WSDLV2::Types::CreditCardInformation

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::Purolator::WSDLV2::Types::CreditCardInformation
   Type => $some_value, # CreditCardType
   Number =>  $some_value, # string
   Name =>  $some_value, # string
   ExpiryMonth =>  $some_value, # int
   ExpiryYear =>  $some_value, # int
   CVV =>  $some_value, # string
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
