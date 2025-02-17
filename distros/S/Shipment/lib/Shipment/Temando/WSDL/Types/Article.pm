package Shipment::Temando::WSDL::Types::Article;
$Shipment::Temando::WSDL::Types::Article::VERSION = '3.10';
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(0);

sub get_xmlns { 'http://' . $Shipment::Temando::WSDL::Interfaces::quoting_Service::quoting_port::ns_url . '/schema/2009_06/common.xsd' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %anythingIndex_of :ATTR(:get<anythingIndex>);
my %articleNumber_of :ATTR(:get<articleNumber>);
my %labelDocument_of :ATTR(:get<labelDocument>);
my %labelDocumentType_of :ATTR(:get<labelDocumentType>);

__PACKAGE__->_factory(
    [ qw(        anythingIndex
        articleNumber
        labelDocument
        labelDocumentType

    ) ],
    {
        'anythingIndex' => \%anythingIndex_of,
        'articleNumber' => \%articleNumber_of,
        'labelDocument' => \%labelDocument_of,
        'labelDocumentType' => \%labelDocumentType_of,
    },
    {
        'anythingIndex' => 'Shipment::Temando::WSDL::Types::AnythingIndex',
        'articleNumber' => 'Shipment::Temando::WSDL::Types::ArticleNumber',
        'labelDocument' => 'Shipment::Temando::WSDL::Types::LabelDocument',
        'labelDocumentType' => 'Shipment::Temando::WSDL::Types::LabelDocumentType',
    },
    {

        'anythingIndex' => 'anythingIndex',
        'articleNumber' => 'articleNumber',
        'labelDocument' => 'labelDocument',
        'labelDocumentType' => 'labelDocumentType',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::Temando::WSDL::Types::Article

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Article from the namespace http://' . $Shipment::Temando::WSDL::Interfaces::quoting_Service::quoting_port::ns_url . '/schema/2009_06/common.xsd.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * anythingIndex (min/maxOccurs: 0/1)

=item * articleNumber (min/maxOccurs: 0/1)

=item * labelDocument (min/maxOccurs: 0/1)

=item * labelDocumentType (min/maxOccurs: 0/1)

=back

=head1 NAME

Shipment::Temando::WSDL::Types::Article

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::Temando::WSDL::Types::Article
   anythingIndex => $some_value, # AnythingIndex
   articleNumber => $some_value, # ArticleNumber
   labelDocument => $some_value, # LabelDocument
   labelDocumentType => $some_value, # LabelDocumentType
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
