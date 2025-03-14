package Shipment::FedEx::WSDL::TrackTypes::TrackReconciliation;
$Shipment::FedEx::WSDL::TrackTypes::TrackReconciliation::VERSION = '3.10';
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

my %Status_of :ATTR(:get<Status>);
my %Description_of :ATTR(:get<Description>);

__PACKAGE__->_factory(
    [ qw(        Status
        Description

    ) ],
    {
        'Status' => \%Status_of,
        'Description' => \%Description_of,
    },
    {
        'Status' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Description' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'Status' => 'Status',
        'Description' => 'Description',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::TrackTypes::TrackReconciliation

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
TrackReconciliation from the namespace http://fedex.com/ws/track/v9.

Used to report the status of a piece of a multiple piece shipment which is no longer traveling with the rest of the packages in the shipment or has not been accounted for.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * Status

=item * Description

=back

=head1 NAME

Shipment::FedEx::WSDL::TrackTypes::TrackReconciliation

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::TrackTypes::TrackReconciliation
   Status =>  $some_value, # string
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
