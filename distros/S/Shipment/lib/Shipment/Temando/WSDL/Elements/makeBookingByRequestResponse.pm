
package Shipment::Temando::WSDL::Elements::makeBookingByRequestResponse;
$Shipment::Temando::WSDL::Elements::makeBookingByRequestResponse::VERSION = '2.03';
use strict;
use warnings;

{    # BLOCK to scope variables

    sub get_xmlns {
        'http://'
          . $Shipment::Temando::WSDL::Interfaces::quoting_Service::quoting_port::ns_url
          . '/schema/2009_06/server.xsd';
    }

    __PACKAGE__->__set_name('makeBookingByRequestResponse');
    __PACKAGE__->__set_nillable();
    __PACKAGE__->__set_minOccurs();
    __PACKAGE__->__set_maxOccurs();
    __PACKAGE__->__set_ref();

    use base qw(
      SOAP::WSDL::XSD::Typelib::Element
      SOAP::WSDL::XSD::Typelib::ComplexType
    );

    our $XML_ATTRIBUTE_CLASS;
    undef $XML_ATTRIBUTE_CLASS;

    sub __get_attr_class {
        return $XML_ATTRIBUTE_CLASS;
    }

    use Class::Std::Fast::Storable constructor => 'none';
    use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

    Class::Std::initialize();

    {    # BLOCK to scope variables

        my %requestId_of : ATTR(:get<requestId>);
        my %bookingNumber_of : ATTR(:get<bookingNumber>);
        my %consignmentNumber_of : ATTR(:get<consignmentNumber>);
        my %consignmentDocument_of : ATTR(:get<consignmentDocument>);
        my %consignmentDocumentType_of : ATTR(:get<consignmentDocumentType>);
        my %labelDocument_of : ATTR(:get<labelDocument>);
        my %labelDocumentType_of : ATTR(:get<labelDocumentType>);
        my %anytime_of : ATTR(:get<anytime>);
        my %quote_of : ATTR(:get<quote>);
        my %manifestNumber_of : ATTR(:get<manifestNumber>);
        my %articles_of : ATTR(:get<articles>);

        __PACKAGE__->_factory(
            [   qw(        requestId
                  bookingNumber
                  consignmentNumber
                  consignmentDocument
                  consignmentDocumentType
                  labelDocument
                  labelDocumentType
                  anytime
                  quote
                  manifestNumber
                  articles

                  )
            ],
            {   'requestId'               => \%requestId_of,
                'bookingNumber'           => \%bookingNumber_of,
                'consignmentNumber'       => \%consignmentNumber_of,
                'consignmentDocument'     => \%consignmentDocument_of,
                'consignmentDocumentType' => \%consignmentDocumentType_of,
                'labelDocument'           => \%labelDocument_of,
                'labelDocumentType'       => \%labelDocumentType_of,
                'anytime'                 => \%anytime_of,
                'quote'                   => \%quote_of,
                'manifestNumber'          => \%manifestNumber_of,
                'articles'                => \%articles_of,
            },
            {   'requestId' =>
                  'SOAP::WSDL::XSD::Typelib::Builtin::positiveInteger',
                'bookingNumber' =>
                  'Shipment::Temando::WSDL::Types::BookingNumber',
                'consignmentNumber' =>
                  'Shipment::Temando::WSDL::Types::ConsignmentNumber',
                'consignmentDocument' =>
                  'Shipment::Temando::WSDL::Types::ConsignmentDocument',
                'consignmentDocumentType' =>
                  'Shipment::Temando::WSDL::Types::ConsignmentDocumentType',
                'labelDocument' =>
                  'Shipment::Temando::WSDL::Types::LabelDocument',
                'labelDocumentType' =>
                  'Shipment::Temando::WSDL::Types::LabelDocumentType',
                'anytime' => 'Shipment::Temando::WSDL::Types::Anytime',
                'quote'   => 'Shipment::Temando::WSDL::Types::AvailableQuote',
                'manifestNumber' =>
                  'Shipment::Temando::WSDL::Types::ManifestNumber',

                'articles' =>
                  'Shipment::Temando::WSDL::Elements::makeBookingByRequestResponse::_articles',
            },
            {

                'requestId'               => 'requestId',
                'bookingNumber'           => 'bookingNumber',
                'consignmentNumber'       => 'consignmentNumber',
                'consignmentDocument'     => 'consignmentDocument',
                'consignmentDocumentType' => 'consignmentDocumentType',
                'labelDocument'           => 'labelDocument',
                'labelDocumentType'       => 'labelDocumentType',
                'anytime'                 => 'anytime',
                'quote'                   => 'quote',
                'manifestNumber'          => 'manifestNumber',
                'articles'                => 'articles',
            }
        );

    }    # end BLOCK


    package Shipment::Temando::WSDL::Elements::makeBookingByRequestResponse::_articles;
    $Shipment::Temando::WSDL::Elements::makeBookingByRequestResponse::_articles::VERSION
      = '2.03';
    use strict;
    use warnings;
    {
        our $XML_ATTRIBUTE_CLASS;
        undef $XML_ATTRIBUTE_CLASS;

        sub __get_attr_class {
            return $XML_ATTRIBUTE_CLASS;
        }

        use Class::Std::Fast::Storable constructor => 'none';
        use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

        Class::Std::initialize();

        {    # BLOCK to scope variables

            my %article_of : ATTR(:get<article>);

            __PACKAGE__->_factory(
                [   qw(        article

                      )
                ],
                {'article' => \%article_of,},
                {'article' => 'Shipment::Temando::WSDL::Types::Article',},
                {

                    'article' => 'article',
                }
            );

        }    # end BLOCK


    }


}    # end of BLOCK


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::Temando::WSDL::Elements::makeBookingByRequestResponse

=head1 VERSION

version 2.03

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
makeBookingByRequestResponse from the namespace http://' . $Shipment::Temando::WSDL::Interfaces::quoting_Service::quoting_port::ns_url . '/schema/2009_06/server.xsd.

=head1 NAME

Shipment::Temando::WSDL::Elements::makeBookingByRequestResponse

=head1 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * requestId

 $element->set_requestId($data);
 $element->get_requestId();

=item * bookingNumber

 $element->set_bookingNumber($data);
 $element->get_bookingNumber();

=item * consignmentNumber

 $element->set_consignmentNumber($data);
 $element->get_consignmentNumber();

=item * consignmentDocument

 $element->set_consignmentDocument($data);
 $element->get_consignmentDocument();

=item * consignmentDocumentType

 $element->set_consignmentDocumentType($data);
 $element->get_consignmentDocumentType();

=item * labelDocument

 $element->set_labelDocument($data);
 $element->get_labelDocument();

=item * labelDocumentType

 $element->set_labelDocumentType($data);
 $element->get_labelDocumentType();

=item * anytime

 $element->set_anytime($data);
 $element->get_anytime();

=item * quote

 $element->set_quote($data);
 $element->get_quote();

=item * manifestNumber

 $element->set_manifestNumber($data);
 $element->get_manifestNumber();

=item * articles

 $element->set_articles($data);
 $element->get_articles();

=back

=head1 METHODS

=head2 new

 my $element = Shipment::Temando::WSDL::Elements::makeBookingByRequestResponse->new($data);

Constructor. The following data structure may be passed to new():

 {
   requestId =>  $some_value, # positiveInteger
   bookingNumber => $some_value, # BookingNumber
   consignmentNumber => $some_value, # ConsignmentNumber
   consignmentDocument => $some_value, # ConsignmentDocument
   consignmentDocumentType => $some_value, # ConsignmentDocumentType
   labelDocument => $some_value, # LabelDocument
   labelDocumentType => $some_value, # LabelDocumentType
   anytime =>  { # Shipment::Temando::WSDL::Types::Anytime
     readyDate => $some_value, # Date
     readyTime => $some_value, # ReadyTime
   },
   quote =>  { # Shipment::Temando::WSDL::Types::AvailableQuote
     generated => $some_value, # GeneratedType
     accepted => $some_value, # YesNoOption
     bookingNumber => $some_value, # BookingNumber
     consignmentNumber => $some_value, # ConsignmentNumber
     consignmentDocument => $some_value, # ConsignmentDocument
     consignmentDocumentType => $some_value, # ConsignmentDocumentType
     labelDocument => $some_value, # LabelDocument
     labelDocumentType => $some_value, # LabelDocumentType
     manifestNumber => $some_value, # ManifestNumber
     articles =>  {
       article =>  { # Shipment::Temando::WSDL::Types::Article
         anythingIndex => $some_value, # AnythingIndex
         articleNumber => $some_value, # ArticleNumber
         labelDocument => $some_value, # LabelDocument
         labelDocumentType => $some_value, # LabelDocumentType
       },
     },
     trackingStatus => $some_value, # TrackingStatus
     trackingStatusOccurred => $some_value, # Datetime
     trackingLastChecked => $some_value, # Datetime
     trackingFurtherDetails => $some_value, # TrackingFurtherDetails
     totalPrice => $some_value, # CurrencyAmount
     basePrice => $some_value, # CurrencyAmount
     tax => $some_value, # CurrencyAmount
     currency => $some_value, # CurrencyType
     deliveryMethod => $some_value, # DeliveryMethod
     usingGeneralRail => $some_value, # YesNoOption
     usingGeneralRoad => $some_value, # YesNoOption
     usingGeneralSea => $some_value, # YesNoOption
     usingExpressAir => $some_value, # YesNoOption
     usingExpressRoad => $some_value, # YesNoOption
     etaFrom => $some_value, # Eta
     etaTo => $some_value, # Eta
     guaranteedEta => $some_value, # YesNoOption
     adjustments =>  {
       adjustment =>  { # Shipment::Temando::WSDL::Types::Adjustment
         description => $some_value, # AdjustmentDescription
         amount => $some_value, # CurrencyAmount
         tax => $some_value, # CurrencyAmount
       },
     },
     inclusions =>  {
       inclusion =>  { # Shipment::Temando::WSDL::Types::Inclusion
         summary => $some_value, # InclusionSummary
         details => $some_value, # InclusionDetails
       },
     },
     extras =>  {
       extra =>  { # Shipment::Temando::WSDL::Types::Extra
         summary => $some_value, # ExtraSummary
         details => $some_value, # ExtraDetails
         totalPrice => $some_value, # CurrencyAmount
         basePrice => $some_value, # CurrencyAmount
         tax => $some_value, # CurrencyAmount
         adjustments =>  {
           adjustment => {}, # Shipment::Temando::WSDL::Types::Adjustment
         },
       },
     },
     carrier =>  { # Shipment::Temando::WSDL::Types::Carrier
       id => $some_value, # CarrierId
       companyName => $some_value, # CompanyName
       companyContact => $some_value, # ContactName
       streetAddress => $some_value, # Address
       streetSuburb => $some_value, # Suburb
       streetCity => $some_value, # City
       streetState => $some_value, # State
       streetCode => $some_value, # PostalCode
       streetCountry => $some_value, # CountryCode
       postalAddress => $some_value, # Address
       postalSuburb => $some_value, # Suburb
       postalCity => $some_value, # City
       postalState => $some_value, # State
       postalCode => $some_value, # PostalCode
       postalCountry => $some_value, # CountryCode
       phone1 => $some_value, # Phone
       phone2 => $some_value, # Phone
       email => $some_value, # Email
       website => $some_value, # Website
       conditions => $some_value, # CarrierConditions
     },
     originatingDepot =>  { # Shipment::Temando::WSDL::Types::Depot
       name => $some_value, # DepotName
       street => $some_value, # Address
       suburb => $some_value, # Suburb
       city => $some_value, # City
       state => $some_value, # State
       code => $some_value, # PostalCode
       country => $some_value, # CountryCode
       phone1 => $some_value, # Phone
       phone2 => $some_value, # Phone
       fax => $some_value, # Fax
       instructions => $some_value, # DepotInstructions
     },
     destinationDepot => {}, # Shipment::Temando::WSDL::Types::Depot
   },
   manifestNumber => $some_value, # ManifestNumber
   articles =>  {
     article =>  { # Shipment::Temando::WSDL::Types::Article
       anythingIndex => $some_value, # AnythingIndex
       articleNumber => $some_value, # ArticleNumber
       labelDocument => $some_value, # LabelDocument
       labelDocumentType => $some_value, # LabelDocumentType
     },
   },
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=head1 AUTHOR

Andrew Baerg <baergaj@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Andrew Baerg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
