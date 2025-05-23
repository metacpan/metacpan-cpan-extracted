package Shipment::FedEx::WSDL::RateTypes::CustomLabelGraphicEntry;
$Shipment::FedEx::WSDL::RateTypes::CustomLabelGraphicEntry::VERSION = '3.10';
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

my %Position_of :ATTR(:get<Position>);
my %PrinterGraphicId_of :ATTR(:get<PrinterGraphicId>);
my %FileGraphicFullName_of :ATTR(:get<FileGraphicFullName>);

__PACKAGE__->_factory(
    [ qw(        Position
        PrinterGraphicId
        FileGraphicFullName

    ) ],
    {
        'Position' => \%Position_of,
        'PrinterGraphicId' => \%PrinterGraphicId_of,
        'FileGraphicFullName' => \%FileGraphicFullName_of,
    },
    {
        'Position' => 'Shipment::FedEx::WSDL::RateTypes::CustomLabelPosition',
        'PrinterGraphicId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'FileGraphicFullName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'Position' => 'Position',
        'PrinterGraphicId' => 'PrinterGraphicId',
        'FileGraphicFullName' => 'FileGraphicFullName',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::RateTypes::CustomLabelGraphicEntry

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
CustomLabelGraphicEntry from the namespace http://fedex.com/ws/rate/v9.

Image to be included from printer's memory, or from a local file for offline clients.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * Position (min/maxOccurs: 0/1)

=item * PrinterGraphicId (min/maxOccurs: 0/1)

=item * FileGraphicFullName (min/maxOccurs: 0/1)

=back

=head1 NAME

Shipment::FedEx::WSDL::RateTypes::CustomLabelGraphicEntry

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::RateTypes::CustomLabelGraphicEntry
   Position =>  { # Shipment::FedEx::WSDL::RateTypes::CustomLabelPosition
     X =>  $some_value, # nonNegativeInteger
     Y =>  $some_value, # nonNegativeInteger
   },
   PrinterGraphicId =>  $some_value, # string
   FileGraphicFullName =>  $some_value, # string
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
