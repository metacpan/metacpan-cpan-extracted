package Shipment::FedEx::WSDL::ShipTypes::PackageRating;
$Shipment::FedEx::WSDL::ShipTypes::PackageRating::VERSION = '3.10';
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://fedex.com/ws/ship/v9' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %ActualRateType_of :ATTR(:get<ActualRateType>);
my %EffectiveNetDiscount_of :ATTR(:get<EffectiveNetDiscount>);
my %PackageRateDetails_of :ATTR(:get<PackageRateDetails>);

__PACKAGE__->_factory(
    [ qw(        ActualRateType
        EffectiveNetDiscount
        PackageRateDetails

    ) ],
    {
        'ActualRateType' => \%ActualRateType_of,
        'EffectiveNetDiscount' => \%EffectiveNetDiscount_of,
        'PackageRateDetails' => \%PackageRateDetails_of,
    },
    {
        'ActualRateType' => 'Shipment::FedEx::WSDL::ShipTypes::ReturnedRateType',
        'EffectiveNetDiscount' => 'Shipment::FedEx::WSDL::ShipTypes::Money',
        'PackageRateDetails' => 'Shipment::FedEx::WSDL::ShipTypes::PackageRateDetail',
    },
    {

        'ActualRateType' => 'ActualRateType',
        'EffectiveNetDiscount' => 'EffectiveNetDiscount',
        'PackageRateDetails' => 'PackageRateDetails',
    }
);

} # end BLOCK







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx::WSDL::ShipTypes::PackageRating

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
PackageRating from the namespace http://fedex.com/ws/ship/v9.

This class groups together for a single package all package-level rate data (across all rate types) as part of the response to a shipping request, which groups shipment-level data together and groups package-level data by package.

=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * ActualRateType (min/maxOccurs: 0/1)

=item * EffectiveNetDiscount (min/maxOccurs: 0/1)

=item * PackageRateDetails (min/maxOccurs: 0/unbounded)

=back

=head1 NAME

Shipment::FedEx::WSDL::ShipTypes::PackageRating

=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Shipment::FedEx::WSDL::ShipTypes::PackageRating
   ActualRateType => $some_value, # ReturnedRateType
   EffectiveNetDiscount =>  { # Shipment::FedEx::WSDL::ShipTypes::Money
     Currency =>  $some_value, # string
     Amount =>  $some_value, # decimal
   },
   PackageRateDetails =>  { # Shipment::FedEx::WSDL::ShipTypes::PackageRateDetail
     RateType => $some_value, # ReturnedRateType
     RatedWeightMethod => $some_value, # RatedWeightMethod
     MinimumChargeType => $some_value, # MinimumChargeType
     BillingWeight =>  { # Shipment::FedEx::WSDL::ShipTypes::Weight
       Units => $some_value, # WeightUnits
       Value =>  $some_value, # decimal
     },
     DimWeight => {}, # Shipment::FedEx::WSDL::ShipTypes::Weight
     OversizeWeight => {}, # Shipment::FedEx::WSDL::ShipTypes::Weight
     BaseCharge => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     TotalFreightDiscounts => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     NetFreight => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     TotalSurcharges => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     NetFedExCharge => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     TotalTaxes => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     NetCharge => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     TotalRebates => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     FreightDiscounts =>  { # Shipment::FedEx::WSDL::ShipTypes::RateDiscount
       RateDiscountType => $some_value, # RateDiscountType
       Description =>  $some_value, # string
       Amount => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
       Percent =>  $some_value, # decimal
     },
     Rebates =>  { # Shipment::FedEx::WSDL::ShipTypes::Rebate
       RebateType => $some_value, # RebateType
       Description =>  $some_value, # string
       Amount => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
       Percent =>  $some_value, # decimal
     },
     Surcharges =>  { # Shipment::FedEx::WSDL::ShipTypes::Surcharge
       SurchargeType => $some_value, # SurchargeType
       Level => $some_value, # SurchargeLevelType
       Description =>  $some_value, # string
       Amount => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     },
     Taxes =>  { # Shipment::FedEx::WSDL::ShipTypes::Tax
       TaxType => $some_value, # TaxType
       Description =>  $some_value, # string
       Amount => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     },
     VariableHandlingCharges =>  { # Shipment::FedEx::WSDL::ShipTypes::VariableHandlingCharges
       VariableHandlingCharge => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
       TotalCustomerCharge => {}, # Shipment::FedEx::WSDL::ShipTypes::Money
     },
   },
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
