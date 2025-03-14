package Shipment::UPS::WSDL::TrackTypes::PickupDateRangeType;
$Shipment::UPS::WSDL::TrackTypes::PickupDateRangeType::VERSION = '3.10';
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://www.ups.com/XMLSchema/XOLTWS/Track/v2.0' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %BeginDate_of :ATTR(:get<BeginDate>);
my %EndDate_of :ATTR(:get<EndDate>);

__PACKAGE__->_factory(
    [ qw(        BeginDate
        EndDate

    ) ],
    {
        'BeginDate' => \%BeginDate_of,
        'EndDate' => \%EndDate_of,
    },
    {
        'BeginDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'EndDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'BeginDate' => 'BeginDate',
        'EndDate' => 'EndDate',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::UPS::WSDL::TrackTypes::PickupDateRangeType

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
PickupDateRangeType from the namespace http://www.ups.com/XMLSchema/XOLTWS/Track/v2.0.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * BeginDate

=item * EndDate

=back

=head1 NAME

Shipment::UPS::WSDL::TrackTypes::PickupDateRangeType

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::UPS::WSDL::TrackTypes::PickupDateRangeType
   BeginDate =>  $some_value, # string
   EndDate =>  $some_value, # string
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
