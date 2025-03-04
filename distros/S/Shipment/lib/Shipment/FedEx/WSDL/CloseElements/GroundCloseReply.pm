
package Shipment::FedEx::WSDL::CloseElements::GroundCloseReply;
$Shipment::FedEx::WSDL::CloseElements::GroundCloseReply::VERSION = '3.10';
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'http://fedex.com/ws/close/v2' }

__PACKAGE__->__set_name('GroundCloseReply');
__PACKAGE__->__set_nillable();
__PACKAGE__->__set_minOccurs();
__PACKAGE__->__set_maxOccurs();
__PACKAGE__->__set_ref();
use base qw(
    SOAP::WSDL::XSD::Typelib::Element
    Shipment::FedEx::WSDL::CloseTypes::GroundCloseReply
);

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::CloseElements::GroundCloseReply

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
GroundCloseReply from the namespace http://fedex.com/ws/close/v2.

=head1 NAME

Shipment::FedEx::WSDL::CloseElements::GroundCloseReply

=head1 METHODS

=head2 new

 my $element = Shipment::FedEx::WSDL::CloseElements::GroundCloseReply->new($data);

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::CloseTypes::GroundCloseReply
   HighestSeverity => $some_value, # NotificationSeverityType
   Notifications =>  { # Shipment::FedEx::WSDL::CloseTypes::Notification
     Severity => $some_value, # NotificationSeverityType
     Source =>  $some_value, # string
     Code =>  $some_value, # string
     Message =>  $some_value, # string
     LocalizedMessage =>  $some_value, # string
     MessageParameters =>  { # Shipment::FedEx::WSDL::CloseTypes::NotificationParameter
       Id =>  $some_value, # string
       Value =>  $some_value, # string
     },
   },
   TransactionDetail =>  { # Shipment::FedEx::WSDL::CloseTypes::TransactionDetail
     CustomerTransactionId =>  $some_value, # string
     Localization =>  { # Shipment::FedEx::WSDL::CloseTypes::Localization
       LanguageCode =>  $some_value, # string
       LocaleCode =>  $some_value, # string
     },
   },
   Version =>  { # Shipment::FedEx::WSDL::CloseTypes::VersionId
     ServiceId =>  $some_value, # string
     Major =>  $some_value, # int
     Intermediate =>  $some_value, # int
     Minor =>  $some_value, # int
   },
   CodReport =>  $some_value, # base64Binary
   HazMatCertificate =>  $some_value, # base64Binary
   Manifest =>  { # Shipment::FedEx::WSDL::CloseTypes::ManifestFile
     FileName =>  $some_value, # string
     File =>  $some_value, # base64Binary
   },
   MultiweightReport =>  $some_value, # base64Binary
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
