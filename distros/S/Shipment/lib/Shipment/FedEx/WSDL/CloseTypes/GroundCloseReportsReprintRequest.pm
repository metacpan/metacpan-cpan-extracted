package Shipment::FedEx::WSDL::CloseTypes::GroundCloseReportsReprintRequest;
$Shipment::FedEx::WSDL::CloseTypes::GroundCloseReportsReprintRequest::VERSION = '3.10';
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://fedex.com/ws/close/v2' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %WebAuthenticationDetail_of :ATTR(:get<WebAuthenticationDetail>);
my %ClientDetail_of :ATTR(:get<ClientDetail>);
my %TransactionDetail_of :ATTR(:get<TransactionDetail>);
my %Version_of :ATTR(:get<Version>);
my %ReportDate_of :ATTR(:get<ReportDate>);
my %TrackingNumber_of :ATTR(:get<TrackingNumber>);
my %CloseReportType_of :ATTR(:get<CloseReportType>);

__PACKAGE__->_factory(
    [ qw(        WebAuthenticationDetail
        ClientDetail
        TransactionDetail
        Version
        ReportDate
        TrackingNumber
        CloseReportType

    ) ],
    {
        'WebAuthenticationDetail' => \%WebAuthenticationDetail_of,
        'ClientDetail' => \%ClientDetail_of,
        'TransactionDetail' => \%TransactionDetail_of,
        'Version' => \%Version_of,
        'ReportDate' => \%ReportDate_of,
        'TrackingNumber' => \%TrackingNumber_of,
        'CloseReportType' => \%CloseReportType_of,
    },
    {
        'WebAuthenticationDetail' => 'Shipment::FedEx::WSDL::CloseTypes::WebAuthenticationDetail',
        'ClientDetail' => 'Shipment::FedEx::WSDL::CloseTypes::ClientDetail',
        'TransactionDetail' => 'Shipment::FedEx::WSDL::CloseTypes::TransactionDetail',
        'Version' => 'Shipment::FedEx::WSDL::CloseTypes::VersionId',
        'ReportDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::date',
        'TrackingNumber' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'CloseReportType' => 'Shipment::FedEx::WSDL::CloseTypes::CloseReportType',
    },
    {

        'WebAuthenticationDetail' => 'WebAuthenticationDetail',
        'ClientDetail' => 'ClientDetail',
        'TransactionDetail' => 'TransactionDetail',
        'Version' => 'Version',
        'ReportDate' => 'ReportDate',
        'TrackingNumber' => 'TrackingNumber',
        'CloseReportType' => 'CloseReportType',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::CloseTypes::GroundCloseReportsReprintRequest

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
GroundCloseReportsReprintRequest from the namespace http://fedex.com/ws/close/v2.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * WebAuthenticationDetail (min/maxOccurs: 1/1)

=item * ClientDetail (min/maxOccurs: 1/1)

=item * TransactionDetail (min/maxOccurs: 0/1)

=item * Version (min/maxOccurs: 1/1)

=item * ReportDate (min/maxOccurs: 0/1)

=item * TrackingNumber (min/maxOccurs: 0/1)

=item * CloseReportType (min/maxOccurs: 0/1)

=back

=head1 NAME

Shipment::FedEx::WSDL::CloseTypes::GroundCloseReportsReprintRequest

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::CloseTypes::GroundCloseReportsReprintRequest
   WebAuthenticationDetail =>  { # Shipment::FedEx::WSDL::CloseTypes::WebAuthenticationDetail
     UserCredential =>  { # Shipment::FedEx::WSDL::CloseTypes::WebAuthenticationCredential
       Key =>  $some_value, # string
       Password =>  $some_value, # string
     },
   },
   ClientDetail =>  { # Shipment::FedEx::WSDL::CloseTypes::ClientDetail
     AccountNumber =>  $some_value, # string
     MeterNumber =>  $some_value, # string
     IntegratorId =>  $some_value, # string
     Localization =>  { # Shipment::FedEx::WSDL::CloseTypes::Localization
       LanguageCode =>  $some_value, # string
       LocaleCode =>  $some_value, # string
     },
   },
   TransactionDetail =>  { # Shipment::FedEx::WSDL::CloseTypes::TransactionDetail
     CustomerTransactionId =>  $some_value, # string
     Localization => {}, # Shipment::FedEx::WSDL::CloseTypes::Localization
   },
   Version =>  { # Shipment::FedEx::WSDL::CloseTypes::VersionId
     ServiceId =>  $some_value, # string
     Major =>  $some_value, # int
     Intermediate =>  $some_value, # int
     Minor =>  $some_value, # int
   },
   ReportDate =>  $some_value, # date
   TrackingNumber =>  $some_value, # string
   CloseReportType => $some_value, # CloseReportType
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
