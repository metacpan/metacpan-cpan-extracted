package Shipment::FedEx::WSDL::RateTypes::ContentRecord;
$Shipment::FedEx::WSDL::RateTypes::ContentRecord::VERSION = '3.10';
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

my %PartNumber_of :ATTR(:get<PartNumber>);
my %ItemNumber_of :ATTR(:get<ItemNumber>);
my %ReceivedQuantity_of :ATTR(:get<ReceivedQuantity>);
my %Description_of :ATTR(:get<Description>);

__PACKAGE__->_factory(
    [ qw(        PartNumber
        ItemNumber
        ReceivedQuantity
        Description

    ) ],
    {
        'PartNumber' => \%PartNumber_of,
        'ItemNumber' => \%ItemNumber_of,
        'ReceivedQuantity' => \%ReceivedQuantity_of,
        'Description' => \%Description_of,
    },
    {
        'PartNumber' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'ItemNumber' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'ReceivedQuantity' => 'SOAP::WSDL::XSD::Typelib::Builtin::nonNegativeInteger',
        'Description' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'PartNumber' => 'PartNumber',
        'ItemNumber' => 'ItemNumber',
        'ReceivedQuantity' => 'ReceivedQuantity',
        'Description' => 'Description',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::RateTypes::ContentRecord

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
ContentRecord from the namespace http://fedex.com/ws/rate/v9.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * PartNumber (min/maxOccurs: 0/1)

=item * ItemNumber (min/maxOccurs: 0/1)

=item * ReceivedQuantity (min/maxOccurs: 0/1)

=item * Description (min/maxOccurs: 0/1)

=back

=head1 NAME

Shipment::FedEx::WSDL::RateTypes::ContentRecord

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::RateTypes::ContentRecord
   PartNumber =>  $some_value, # string
   ItemNumber =>  $some_value, # string
   ReceivedQuantity =>  $some_value, # nonNegativeInteger
   Description =>  $some_value, # string
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
