
package Shipment::Purolator::WSDLV2::Elements::PhoneNumber;
$Shipment::Purolator::WSDLV2::Elements::PhoneNumber::VERSION = '3.10';
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'http://purolator.com/pws/datatypes/v2' }

__PACKAGE__->__set_name('PhoneNumber');
__PACKAGE__->__set_nillable(1);
__PACKAGE__->__set_minOccurs();
__PACKAGE__->__set_maxOccurs();
__PACKAGE__->__set_ref();
use base qw(
    SOAP::WSDL::XSD::Typelib::Element
    Shipment::Purolator::WSDLV2::Types::PhoneNumber
);

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::Purolator::WSDLV2::Elements::PhoneNumber

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
PhoneNumber from the namespace http://purolator.com/pws/datatypes/v2.

=head1 NAME

Shipment::Purolator::WSDLV2::Elements::PhoneNumber

=head1 METHODS

=head2 new

 my $element = Shipment::Purolator::WSDLV2::Elements::PhoneNumber->new($data);

Constructor. The following data structure may be passed to new():

 { # Shipment::Purolator::WSDLV2::Types::PhoneNumber
   CountryCode =>  $some_value, # string
   AreaCode =>  $some_value, # string
   Phone =>  $some_value, # string
   Extension =>  $some_value, # string
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
