package Shipment::FedEx::WSDL::RateTypes::WebAuthenticationCredential;
$Shipment::FedEx::WSDL::RateTypes::WebAuthenticationCredential::VERSION = '3.10';
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

my %Key_of :ATTR(:get<Key>);
my %Password_of :ATTR(:get<Password>);

__PACKAGE__->_factory(
    [ qw(        Key
        Password

    ) ],
    {
        'Key' => \%Key_of,
        'Password' => \%Password_of,
    },
    {
        'Key' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Password' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'Key' => 'Key',
        'Password' => 'Password',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::RateTypes::WebAuthenticationCredential

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
WebAuthenticationCredential from the namespace http://fedex.com/ws/rate/v9.

Two part authentication string used for the sender's identity

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * Key (min/maxOccurs: 1/1)

=item * Password (min/maxOccurs: 1/1)

=back

=head1 NAME

Shipment::FedEx::WSDL::RateTypes::WebAuthenticationCredential

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::RateTypes::WebAuthenticationCredential
   Key =>  $some_value, # string
   Password =>  $some_value, # string
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
