package Shipment::Purolator::WSDLV2::Types::OtherInformation;
$Shipment::Purolator::WSDLV2::Types::OtherInformation::VERSION = '3.10';
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

my %CostCentre_of :ATTR(:get<CostCentre>);
my %SpecialInstructions_of :ATTR(:get<SpecialInstructions>);

__PACKAGE__->_factory(
    [ qw(        CostCentre
        SpecialInstructions

    ) ],
    {
        'CostCentre' => \%CostCentre_of,
        'SpecialInstructions' => \%SpecialInstructions_of,
    },
    {
        'CostCentre' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'SpecialInstructions' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'CostCentre' => 'CostCentre',
        'SpecialInstructions' => 'SpecialInstructions',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::Purolator::WSDLV2::Types::OtherInformation

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
OtherInformation from the namespace http://purolator.com/pws/datatypes/v2.

OtherInformation

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * CostCentre (min/maxOccurs: 0/1)

=item * SpecialInstructions (min/maxOccurs: 0/1)

=back

=head1 NAME

Shipment::Purolator::WSDLV2::Types::OtherInformation

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::Purolator::WSDLV2::Types::OtherInformation
   CostCentre =>  $some_value, # string
   SpecialInstructions =>  $some_value, # string
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
