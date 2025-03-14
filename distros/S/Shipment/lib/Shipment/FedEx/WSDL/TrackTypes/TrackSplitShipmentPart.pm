package Shipment::FedEx::WSDL::TrackTypes::TrackSplitShipmentPart;
$Shipment::FedEx::WSDL::TrackTypes::TrackSplitShipmentPart::VERSION = '3.10';
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://fedex.com/ws/track/v9' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %PieceCount_of :ATTR(:get<PieceCount>);
my %Timestamp_of :ATTR(:get<Timestamp>);
my %StatusCode_of :ATTR(:get<StatusCode>);
my %StatusDescription_of :ATTR(:get<StatusDescription>);

__PACKAGE__->_factory(
    [ qw(        PieceCount
        Timestamp
        StatusCode
        StatusDescription

    ) ],
    {
        'PieceCount' => \%PieceCount_of,
        'Timestamp' => \%Timestamp_of,
        'StatusCode' => \%StatusCode_of,
        'StatusDescription' => \%StatusDescription_of,
    },
    {
        'PieceCount' => 'SOAP::WSDL::XSD::Typelib::Builtin::positiveInteger',
        'Timestamp' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
        'StatusCode' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'StatusDescription' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'PieceCount' => 'PieceCount',
        'Timestamp' => 'Timestamp',
        'StatusCode' => 'StatusCode',
        'StatusDescription' => 'StatusDescription',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::TrackTypes::TrackSplitShipmentPart

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
TrackSplitShipmentPart from the namespace http://fedex.com/ws/track/v9.

Used when a cargo shipment is split across vehicles. This is used to give the status of each part of the shipment.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * PieceCount

=item * Timestamp

=item * StatusCode

=item * StatusDescription

=back

=head1 NAME

Shipment::FedEx::WSDL::TrackTypes::TrackSplitShipmentPart

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::TrackTypes::TrackSplitShipmentPart
   PieceCount =>  $some_value, # positiveInteger
   Timestamp =>  $some_value, # dateTime
   StatusCode =>  $some_value, # string
   StatusDescription =>  $some_value, # string
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
