package Shipment::FedEx;
$Shipment::FedEx::VERSION = '3.10';
use strict;
use warnings;


use Try::Tiny;
use Shipment::SOAP::WSDL;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

use DateTime::Format::ISO8601;

extends 'Shipment::Base';


has 'meter' => (
  is => 'rw',
  isa => Str,
);

has 'key' => (
  is => 'rw',
  isa => Str,
);

has 'password' => (
  is => 'rw',
  isa => Str,
);


has 'proxy_domain' => (
  is => 'rw',
  isa => Enum[ qw(
    wsbeta.fedex.com:443
    ws.fedex.com:443
  ) ],
  default => 'wsbeta.fedex.com:443',
);


has 'shipment_special_service_types' => (
  is => 'rw',
  isa => ArrayRef[Str],
  default => sub { [] },
);


has 'residential_address' => (
  is => 'rw',
  isa => Bool,
  default => 0,
);


has 'label_stock_type' => (
    is  => 'rw',
    isa => Enum [
        qw(
          STOCK_4X6
          STOCK_4X6.75_LEADING_DOC_TAB
          STOCK_4X6.75_TRAILING_DOC_TAB
          STOCK_4X8
          STOCK_4X9_LEADING_DOC_TAB
          STOCK_4X9_TRAILING_DOC_TAB
          PAPER_4X6
          PAPER_4X8
          PAPER_4X9
          PAPER_7X4.75
          PAPER_8.5X11_BOTTOM_HALF_LABEL
          PAPER_8.5X11_TOP_HALF_LABEL
          PAPER_LETTER
          )
    ],
    lazy    => 1,
    builder => 1,
);

sub _build_label_stock_type {
    my $self = shift;
    return 'STOCK_4X6' if $self->printer_type eq 'thermal'
                       or $self->printer_type eq 'ZPLII'
                       or $self->printer_type eq 'EPL2'
                       or $self->printer_type eq 'DPL';
    return 'PAPER_4X6';
}



has '+bill_type' => (
  isa => Enum[qw( sender recipient third_party collect )],
);

my %bill_type_map = (
  'sender'      => 'SENDER',
  'recipient'   => 'RECIPIENT',
  'third_party' => 'THIRD_PARTY',
  'collect'     => 'COLLECT',
);

my %signature_type_map = (
  'default'      => 'SERVICE_DEFAULT',
  'required'     => 'DIRECT',
  'not_required' => 'NO_SIGNATURE_REQUIRED',
  'adult'        => 'ADULT',
);

my %pickup_type_map = (
  'pickup'      => 'REGULAR_PICKUP',
  'dropoff'     => 'STATION',
);

my %package_type_map = (
  'custom'      => 'YOUR_PACKAGING',
  'envelope'    => 'FEDEX_ENVELOPE',
  'tube'        => 'FEDEX_TUBE',
  'box'         => 'FEDEX_BOX',
  'pack'        => 'FEDEX_PAK',
);

my %units_type_map = (
  'lb'          => 'LB',
  'kg'          => 'KG',
  'in'          => 'IN',
  'cm'          => 'CM',
);

my %printer_type_map = (
  'pdf'        => 'PDF',
  'thermal'        => 'EPL2',
  'image'      => 'PNG',
);

my %label_content_type_map = (
  'pdf'        => 'application/pdf',
  'thermal'        => 'text/fedex-epl',
  'ZPLII'      => 'text/fedex-zplii',
  'EPL2'       => 'text/fedex-epl',
  'DPL'        => 'text/fedex-dpl',
  'image'      => 'image/png',
);


has '+package_type' => (
  isa => Enum[qw( custom envelope tube box pack FEDEX_10KG_BOX FEDEX_25KG_BOX )]
);


has '+currency' => (
  default => 'USD',
);


sub _build_services {
  my $self = shift;

  use Shipment::Package;
  use Shipment::Service;
  use Shipment::FedEx::WSDL::RateInterfaces::RateService::RateServicePort;

  my $interface = Shipment::FedEx::WSDL::RateInterfaces::RateService::RateServicePort->new(
    {
      proxy_domain => $self->proxy_domain,
    }
  );
  my $response;

  my %services;

  my @to_streetlines;
  push @to_streetlines, $self->to_address()->address1;
  push @to_streetlines, $self->to_address()->address2 if $self->to_address()->address2;

  my @from_streetlines;
  push @from_streetlines, $self->from_address()->address1;
  push @from_streetlines, $self->from_address()->address2 if $self->from_address()->address2;

  my $total_weight;
  $total_weight += $_->weight for @{ $self->packages };
  $total_weight ||= 1;

  my $options;
  $options->{SpecialServiceTypes} = 'SIGNATURE_OPTION';
  $options->{SignatureOptionDetail}->{OptionType} = $signature_type_map{$self->signature_type} || $self->signature_type;

  my @pieces;
  if ($self->count_packages) {
    my $sequence = 1;
    foreach (@{ $self->packages }) {
      push @pieces,
        { 
            SequenceNumber => $sequence,
            InsuredValue =>  {
              Currency =>  $_->insured_value->code || $self->currency,
              Amount =>  $_->insured_value->value,
            },
            Weight => {
              Value => $_->weight,
              Units => $units_type_map{$self->weight_unit} || $self->weight_unit,
            },
            Dimensions => {
              Length => $_->length,
              Width => $_->width,
              Height => $_->height,
              Units => $units_type_map{$self->dim_unit} || $self->dim_unit,
            },
            SpecialServicesRequested => $options,
        };
      $sequence++;
    }
  }
  else {
    push @pieces,
      {
        Weight => {
          Value => $total_weight,
          Units => $units_type_map{$self->weight_unit} || $self->weight_unit,
        }, 
      };
  }

  my $shipment_options;
  my @shipment_special_service_types;
  push @shipment_special_service_types,
    @{$self->shipment_special_service_types};
  $shipment_options->{SpecialServiceTypes} =
    \@shipment_special_service_types;

  try {
    $Shipment::SOAP::WSDL::Debug = 1 if $self->debug > 1;
    $response = $interface->getRates( 
      { 
        WebAuthenticationDetail =>  {
          UserCredential =>  { 
            Key =>  $self->key,
            Password => $self->password,
          },
        },
        ClientDetail =>  { 
          AccountNumber =>  $self->account,
          MeterNumber =>  $self->meter,
        },
        Version =>  {
          ServiceId =>  'crs',
          Major =>  9,
          Intermediate =>  0,
          Minor =>  0,
        },
        ReturnTransitAndCommit =>  1,
        RequestedShipment =>  {
          ShipTimestamp => $self->pickup_date->datetime,
          DropoffType => $pickup_type_map{$self->pickup_type} || $self->pickup_type,
          PackagingType => 'YOUR_PACKAGING',
          Shipper =>  {
            Address =>  { 
              StreetLines         =>  \@from_streetlines,
              City                =>  $self->from_address()->city,
              StateOrProvinceCode =>  $self->from_address()->province_code,
              PostalCode          =>  $self->from_address()->postal_code,
              CountryCode         =>  $self->from_address()->country_code,
            },
          },
          Recipient =>  {
            Address =>  { 
              StreetLines         =>  \@to_streetlines,
              City                =>  $self->to_address()->city,
              StateOrProvinceCode =>  $self->to_address()->province_code,
              PostalCode          =>  $self->to_address()->postal_code,
              CountryCode         =>  $self->to_address()->country_code,
              Residential         =>  $self->residential_address,
            },
          },
          RateRequestTypes => 'LIST',
          PackageCount =>  $self->count_packages || 1,
          PackageDetail => 'INDIVIDUAL_PACKAGES',
          RequestedPackageLineItems =>  \@pieces,
          SpecialServicesRequested => $shipment_options,
        },
      },
    );
    $Shipment::SOAP::WSDL::Debug = 0;
    warn "Response\n" . $response if $self->debug > 1;

    $self->notice('');
    foreach my $notification (@{ $response->get_Notifications() }) {
      warn $notification->get_Message->get_value if $self->debug;
      $self->add_notice( $notification->get_Message->get_value . "\n" );
    }

    foreach my $service (@{ $response->get_RateReplyDetails() }) {
      $services{$service->get_ServiceType()->get_value} = Shipment::Service->new(
          id => $service->get_ServiceType()->get_value,
          name => $service->get_ServiceType()->get_value,
          package => Shipment::Package->new(
            id => 'YOUR_PACKAGING',
            name => 'Customer Supplied',
          ),
          cost => Data::Currency->new(
            $service->get_RatedShipmentDetails->[0]->get_ShipmentRateDetail->get_TotalNetCharge->get_Amount,
            $service->get_RatedShipmentDetails->[0]->get_ShipmentRateDetail->get_TotalNetCharge->get_Currency
          ),
          discount => Data::Currency->new(
                                $service
                                  ->get_RatedShipmentDetails->[0]
                                  ->get_EffectiveNetDiscount->get_Amount,
                            ),
        );
    }
    $services{ground} = $services{'FEDEX_GROUND'} || $services{'GROUND_HOME_DELIVERY'} || $services{'INTERNATIONAL_GROUND'} || Shipment::Service->new();
    $services{express} = $services{'FEDEX_2_DAY'} || $services{'INTERNATIONAL_ECONOMY'} || Shipment::Service->new();
    $services{priority} = $services{'PRIORITY_OVERNIGHT'} || $services{'INTERNATIONAL_PRIORITY'} || Shipment::Service->new();

  } catch {
      warn $_ if $self->debug;
      try {
        $self->error( $response->get_Notifications()->[0]->get_Message->get_value );
        warn $response->get_Notifications()->[0]->get_Message->get_value if $self->debug;
      } catch {
        $self->error( $response->get_faultstring->get_value );
        warn $response->get_faultstring->get_value if $self->debug;
      };
  };

  \%services;
}


sub rate {
  my ( $self, $service_id ) = @_;

  try { 
    $service_id = $self->services->{$service_id}->id;
  } catch {
    warn $_ if $self->debug;
    warn "service ($service_id) not available" if $self->debug;
    $self->error( "service ($service_id) not available" );
    $service_id = '';
  };
  return unless $service_id;

  my $total_weight;
  $total_weight += $_->weight for @{ $self->packages };

  my $total_insured_value;
  $total_insured_value += $_->insured_value->value for @{ $self->packages };

  use Shipment::Package;
  use Shipment::Service;
  use Shipment::FedEx::WSDL::RateInterfaces::RateService::RateServicePort;

  my $interface = Shipment::FedEx::WSDL::RateInterfaces::RateService::RateServicePort->new(
    {
      proxy_domain => $self->proxy_domain,
    }
  );
  my $response;

  my $options;
  $options->{SpecialServiceTypes} = 'SIGNATURE_OPTION';
  $options->{SignatureOptionDetail}->{OptionType} = $signature_type_map{$self->signature_type} || $self->signature_type;

  my @pieces;
  my $sequence = 1;
  foreach (@{ $self->packages }) {
    push @pieces,
      { 
          SequenceNumber => $sequence,
          InsuredValue =>  {
            Currency =>  $_->insured_value->code || $self->currency,
            Amount =>  $_->insured_value->value,
          },
          Weight => {
            Value => $_->weight,
            Units => $units_type_map{$self->weight_unit} || $self->weight_unit,
          },
          Dimensions => {
            Length => $_->length,
            Width => $_->width,
            Height => $_->height,
            Units => $units_type_map{$self->dim_unit} || $self->dim_unit,
          },
          SpecialServicesRequested => $options,
      };
    $sequence++;
  }

  my $shipment_options;
  my @shipment_special_service_types;
  push @shipment_special_service_types,
    @{$self->shipment_special_service_types};
  $shipment_options->{SpecialServiceTypes} =
    \@shipment_special_service_types;

  my @to_streetlines;
  push @to_streetlines, $self->to_address()->address1;
  push @to_streetlines, $self->to_address()->address2 if $self->to_address()->address2;

  my @from_streetlines;
  push @from_streetlines, $self->from_address()->address1;
  push @from_streetlines, $self->from_address()->address2 if $self->from_address()->address2;

  my %services;

  try {
    $Shipment::SOAP::WSDL::Debug = 1 if $self->debug > 1;
    $response = $interface->getRates( 
      { 
        WebAuthenticationDetail =>  {
          UserCredential =>  { 
            Key =>  $self->key,
            Password => $self->password,
          },
        },
        ClientDetail =>  { 
          AccountNumber =>  $self->account,
          MeterNumber =>  $self->meter,
        },
        Version =>  {
          ServiceId =>  'crs',
          Major =>  9,
          Intermediate =>  0,
          Minor =>  0,
        },
        ReturnTransitAndCommit =>  1,
        RequestedShipment =>  {
          ShipTimestamp => $self->pickup_date->datetime,
          ServiceType => $service_id,
          DropoffType => 'REGULAR_PICKUP',
          PackagingType => 'YOUR_PACKAGING',
          TotalWeight => {
            Value => $total_weight,
            Units => $units_type_map{$self->weight_unit} || $self->weight_unit,
          },
          TotalInsuredValue =>  {
            Currency =>  $self->currency,
            Amount =>  $total_insured_value,
          },
          Shipper =>  {
            Address =>  { 
              StreetLines         =>  \@from_streetlines,
              City                =>  $self->from_address()->city,
              StateOrProvinceCode =>  $self->from_address()->province_code,
              PostalCode          =>  $self->from_address()->postal_code,
              CountryCode         =>  $self->from_address()->country_code,
            },
          },
          Recipient =>  {
            Address =>  { 
              StreetLines         =>  \@to_streetlines,
              City                =>  $self->to_address()->city,
              StateOrProvinceCode =>  $self->to_address()->province_code,
              PostalCode          =>  $self->to_address()->postal_code,
              CountryCode         =>  $self->to_address()->country_code,
              Residential         =>  $self->residential_address,
            },
          },
          RateRequestTypes => 'LIST',
          PackageCount =>  $self->count_packages,
          PackageDetail => 'INDIVIDUAL_PACKAGES',
          RequestedPackageLineItems =>  \@pieces,
          SpecialServicesRequested => $shipment_options,
        },
      },
    );
    $Shipment::SOAP::WSDL::Debug = 0;
    warn "Response\n" . $response if $self->debug > 1;

    $self->notice('');
    foreach my $notification (@{ $response->get_Notifications() }) {
      warn $notification->get_Message->get_value if $self->debug;
      $self->add_notice( $notification->get_Message->get_value . "\n" );
    }

    use Data::Currency;
    use Shipment::Service;
    $self->service( 
       Shipment::Service->new( 
        id        => $service_id,
        name      => $self->services->{$service_id}->name,
        cost      => Data::Currency->new(
            $response->get_RateReplyDetails()->get_RatedShipmentDetails->[0]->get_ShipmentRateDetail->get_TotalNetCharge->get_Amount, 
            $response->get_RateReplyDetails()->get_RatedShipmentDetails->[0]->get_ShipmentRateDetail->get_TotalNetCharge->get_Currency, 
          ),
          discount => Data::Currency->new(
                                $response->get_RateReplyDetails()
                                  ->get_RatedShipmentDetails->[0]
                                  ->get_EffectiveNetDiscount->get_Amount,
                            ),
      )
    );
  } catch {
      warn $_ if $self->debug;
      try {
        $self->error( $response->get_Notifications()->[0]->get_Message->get_value );
        warn $response->get_Notifications()->[0]->get_Message->get_value if $self->debug;
      } catch {
        $self->error( $response->get_faultstring->get_value );
        warn $response->get_faultstring->get_value if $self->debug;
      };
  };
}


sub ship {
  my ( $self, $service_id ) = @_;

  try { 
    $service_id = $self->services->{$service_id}->id;
  } catch {
    warn $_ if $self->debug;
    warn "service ($service_id) not available" if $self->debug;
    $self->error( "service ($service_id) not available" );
    $service_id = '';
  };
  return unless $service_id;

  my $total_weight;
  $total_weight += $_->weight for @{ $self->packages };

  my $total_insured_value;
  $total_insured_value += $_->insured_value->value for @{ $self->packages };

  my $package_options;
  $package_options->{SpecialServiceTypes} = 'SIGNATURE_OPTION';
  $package_options->{SignatureOptionDetail}->{OptionType} = $signature_type_map{$self->signature_type} || $self->signature_type;

  my $shipment_options;

  my @shipment_special_service_types;

  push @shipment_special_service_types, @{$self->shipment_special_service_types};

  my @email_notifications;
  if ($self->to_address->email) {
    push @email_notifications, {
      EMailNotificationRecipientType => 'RECIPIENT',
      EMailAddress => $self->to_address->email,
      NotifyOnShipment => 1,
      Format => 'TEXT',
      Localization => {
        LanguageCode => 'EN',
      },
    };
    push @shipment_special_service_types, 'EMAIL_NOTIFICATION';
    $shipment_options->{EMailNotificationDetail}->{Recipients} = \@email_notifications;
  }

  $shipment_options->{SpecialServiceTypes}  = \@shipment_special_service_types;

  my @references;
  push @references, {
    CustomerReferenceType => 'CUSTOMER_REFERENCE',
    Value => $self->get_reference(0),
  } if $self->get_reference(0);
  push @references, {
    CustomerReferenceType => 'INVOICE_NUMBER',
    Value => $self->get_reference(1),
  } if $self->get_reference(1);
  push @references, {
    CustomerReferenceType => 'P_O_NUMBER',
    Value => $self->get_reference(2),
  } if $self->get_reference(2);

  my @to_streetlines;
  push @to_streetlines, $self->to_address()->address1;
  push @to_streetlines, $self->to_address()->address2 if $self->to_address()->address2;

  my @from_streetlines;
  push @from_streetlines, $self->from_address()->address1;
  push @from_streetlines, $self->from_address()->address2 if $self->from_address()->address2;

    my $response;
    my $sequence = 1;
    my $master_tracking_id = {};

    use Shipment::Label;
    use MIME::Base64;
    use Data::Currency;
    use Shipment::Service;
    use DateTime;

    use Shipment::FedEx::WSDL::ShipInterfaces::ShipService::ShipServicePort;

    my $interface = Shipment::FedEx::WSDL::ShipInterfaces::ShipService::ShipServicePort->new(
      {
        proxy_domain => $self->proxy_domain,
      }
    );

    foreach (@{ $self->packages }) {

      try {
        $Shipment::SOAP::WSDL::Debug = 1 if $self->debug > 1;
        $response = $interface->processShipment( 
          { 
            WebAuthenticationDetail =>  {
              UserCredential =>  { 
                Key =>  $self->key,
                Password => $self->password,
              },
            },
            ClientDetail =>  { 
              AccountNumber =>  $self->account,
              MeterNumber =>  $self->meter,
            },
            Version =>  {
              ServiceId =>  'ship',
              Major =>  9,
              Intermediate =>  0,
              Minor =>  0,
            },
            RequestedShipment => {
              ShipTimestamp => $self->pickup_date->datetime,
              ServiceType => $service_id,
              DropoffType => $pickup_type_map{$self->pickup_type} || $self->pickup_type,
              PackagingType => $package_type_map{$self->package_type} || $self->package_type,
              TotalWeight => {
                Value => $total_weight,
                Units => $units_type_map{$self->weight_unit} || $self->weight_unit,
              },
              TotalInsuredValue =>  {
                Currency =>  $self->currency,
                Amount =>  $total_insured_value,
              },
              Shipper =>  {
                Contact => {
                  PersonName          =>  $self->from_address()->name,
                  CompanyName         =>  $self->from_address()->company,
                  PhoneNumber         =>  $self->from_address()->phone,
                },
                Address =>  { 
                  StreetLines         =>  \@from_streetlines,
                  City                =>  $self->from_address()->city,
                  StateOrProvinceCode =>  $self->from_address()->province_code,
                  PostalCode          =>  $self->from_address()->postal_code,
                  CountryCode         =>  $self->from_address()->country_code,
                },
              },
              Recipient =>  {
                Contact => {
                  PersonName          =>  $self->to_address()->name,
                  CompanyName         =>  $self->to_address()->company,
                  PhoneNumber         =>  $self->to_address()->phone,
                },
                Address =>  { 
                  StreetLines         =>  \@to_streetlines,
                  City                =>  $self->to_address()->city,
                  StateOrProvinceCode =>  $self->to_address()->province_code,
                  PostalCode          =>  $self->to_address()->postal_code,
                  CountryCode         =>  $self->to_address()->country_code,
                  Residential         =>  $self->residential_address,
                },
              },
              ShippingChargesPayment =>  { 
                PaymentType => $bill_type_map{$self->bill_type} || $self->bill_type,
                Payor =>  { 
                  AccountNumber =>  $self->bill_account,
                  CountryCode   =>  ($self->bill_address) ? $self->bill_address->country_code : $self->from_address->country_code,
                },
              },
              SpecialServicesRequested => $shipment_options,
              RateRequestTypes => 'ACCOUNT',
              PackageCount =>  $self->count_packages,
              PackageDetail => 'INDIVIDUAL_PACKAGES',
              MasterTrackingId => $master_tracking_id,
              RequestedPackageLineItems => {
                SequenceNumber => $sequence,
                InsuredValue =>  {
                  Currency =>  $self->currency,
                  Amount =>  $_->insured_value->value,
                },
                Weight => {
                  Value => $_->weight,
                  Units => $units_type_map{$self->weight_unit} || $self->weight_unit,
                },
                Dimensions => {
                  Length => $_->length,
                  Width => $_->width,
                  Height => $_->height,
                  Units => $units_type_map{$self->dim_unit} || $self->dim_unit,
                },
                SpecialServicesRequested => $package_options,
                CustomerReferences => \@references,
              },
              LabelSpecification =>  {
                LabelFormatType => 'COMMON2D',
                ImageType       => $printer_type_map{$self->printer_type} || $self->printer_type,
                LabelStockType  => $self->label_stock_type,
              },
            },
          },
        );
        $Shipment::SOAP::WSDL::Debug = 0;
        warn "Response\n" . $response if $self->debug > 1;

        $self->notice('');
        foreach my $notification (@{ $response->get_Notifications() }) {
          warn $notification->get_Message->get_value if $self->debug;
          $self->add_notice( $notification->get_Message->get_value . "\n" );
        }

        my $package_details = $response->get_CompletedShipmentDetail->get_CompletedPackageDetails;
        
        if ($self->count_packages > 1) {
          my $master_tracking = $response->get_CompletedShipmentDetail->get_MasterTrackingId;
          $self->tracking_id( $master_tracking->get_TrackingNumber->get_value );
          $master_tracking_id = {
                TrackingIdType => $master_tracking->get_TrackingIdType->get_value,
                TrackingNumber => $master_tracking->get_TrackingNumber->get_value,
          };
        } else {
          $self->tracking_id( $package_details->get_TrackingIds->get_TrackingNumber->get_value );
        }
        $_->tracking_id( $package_details->get_TrackingIds->get_TrackingNumber->get_value );

        if ($package_details->get_PackageRating) {
          $_->cost(
            Data::Currency->new(
              $package_details->get_PackageRating->get_PackageRateDetails->[0]->get_NetCharge->get_Amount->get_value,
              $package_details->get_PackageRating->get_PackageRateDetails->[0]->get_NetCharge->get_Currency->get_value,
            ) 
          );
        } elsif ($response->get_CompletedShipmentDetail->get_ShipmentRating) {
          $_->cost(
            Data::Currency->new(
              $response->get_CompletedShipmentDetail->get_ShipmentRating->get_ShipmentRateDetails->[0]->get_TotalNetCharge->get_Amount->get_value,
              $response->get_CompletedShipmentDetail->get_ShipmentRating->get_ShipmentRateDetails->[0]->get_TotalNetCharge->get_Currency->get_value,
            ) 
          );
        }
        $_->label(
          Shipment::Label->new(
            {
              tracking_id => $package_details->get_TrackingIds->get_TrackingNumber->get_value,
              content_type => $label_content_type_map{$self->printer_type},
              data => decode_base64($package_details->get_Label->get_Parts->get_Image->get_value),
              file_name => $package_details->get_TrackingIds->get_TrackingNumber->get_value . '.' . lc $printer_type_map{$self->printer_type},
            },
          )
        );
        
      } catch {
          warn $_ if $self->debug;
          try {
            $self->error( $response->get_Notifications()->[0]->get_Message->get_value );
            warn $response->get_Notifications()->[0]->get_Message->get_value if $self->debug;
          } catch {
            $self->error( $response->get_faultstring->get_value );
            warn $response->get_faultstring->get_value if $self->debug;
          };
      };
    last if $self->error;
    $sequence++;
  }

  if (!$self->error) {
    my $total_charge_amount = 0;
    my $total_charge_currency = $self->currency;
    try {
      my $total_charge = $response->get_CompletedShipmentDetail->get_ShipmentRating->get_ShipmentRateDetails->[0]->get_TotalNetCharge;
      $total_charge_amount = $total_charge->get_Amount->get_value;
      $total_charge_currency = $total_charge->get_Currency->get_value;
    } catch {
      # for other billing (recipient/third_party/collect), no rate details are returned, so we ignore the caught error
      #warn $_;
    };
    $self->service( 
       Shipment::Service->new( 
        id        => $service_id,
        name      => $self->services->{$service_id}->name,
        cost      => Data::Currency->new(
            $total_charge_amount,
            $total_charge_currency,
          ),
      )
    );
  }

}



sub cancel {
  my $self = shift;

  if (!$self->tracking_id) {
    $self->error('no tracking id provided');
    return;
  }

  use Shipment::FedEx::WSDL::ShipInterfaces::ShipService::ShipServicePort;

  my $interface = Shipment::FedEx::WSDL::ShipInterfaces::ShipService::ShipServicePort->new(
    {
      proxy_domain => $self->proxy_domain,
    }
  );
  my $response;

  my $type = (length $self->tracking_id > 12) ? 'GROUND' : 'EXPRESS';
  my $success;

  try {
    $Shipment::SOAP::WSDL::Debug = 1 if $self->debug > 1;
    $response = $interface->deleteShipment(
          { 
            WebAuthenticationDetail =>  {
              UserCredential =>  { 
                Key =>  $self->key,
                Password => $self->password,
              },
            },
            ClientDetail =>  { 
              AccountNumber =>  $self->account,
              MeterNumber =>  $self->meter,
            },
            Version =>  {
              ServiceId =>  'ship',
              Major =>  9,
              Intermediate =>  0,
              Minor =>  0,
            },
            TrackingId =>  { 
              TrackingIdType => $type,
              TrackingNumber => $self->tracking_id,
            },
            DeletionControl => 'DELETE_ONE_PACKAGE',
          },
        );
    $Shipment::SOAP::WSDL::Debug = 0;
    warn "Response\n" . $response if $self->debug > 1;

    $self->notice('');
    foreach my $notification (@{ $response->get_Notifications() }) {
      warn $notification->get_Message->get_value if $self->debug;
      $self->add_notice( $notification->get_Message->get_value . "\n" );
    }

    $success = $response->get_HighestSeverity->get_value; 
  } catch {
      warn $_ if $self->debug;
      try {
        $self->error( $response->get_Notifications()->[0]->get_Message->get_value );
        warn $response->get_Notifications()->[0]->get_Message->get_value if $self->debug;
      } catch {
        $self->error( $response->get_faultstring->get_value );
        warn $response->get_faultstring->get_value if $self->debug;
      };
  };

  return $success;
}



sub track {
  my $self = shift;
  
  use Shipment::Activity;

  if (!$self->tracking_id) {
    $self->error('no tracking id provided');
    return;
  }

  use Shipment::FedEx::WSDL::TrackInterfaces::TrackService::TrackServicePort;

  my $interface = Shipment::FedEx::WSDL::TrackInterfaces::TrackService::TrackServicePort->new(
    {
      proxy_domain => $self->proxy_domain,
    }
  );
  my $response;

  try {
    $Shipment::SOAP::WSDL::Debug = 1 if $self->debug > 1;
    $response = $interface->track(
          { 
            WebAuthenticationDetail =>  {
              UserCredential =>  { 
                Key =>  $self->key,
                Password => $self->password,
              },
            },
            ClientDetail =>  { 
              AccountNumber =>  $self->account,
              MeterNumber =>  $self->meter,
            },
            Version =>  {
              ServiceId =>  'trck',
              Major =>  9,
              Intermediate =>  0,
              Minor =>  0,
            },
            SelectionDetails => {
              PackageIdentifier => {
                Type => 'TRACKING_NUMBER_OR_DOORTAG',
                Value => $self->tracking_id,
              }
            },
            ProcessingOptions => 'INCLUDE_DETAILED_SCANS',
          },
        );
    $Shipment::SOAP::WSDL::Debug = 0;
    warn "Response\n" . $response if $self->debug > 1;

    $self->notice('');
    foreach my $notification (@{ $response->get_Notifications() }) {
      warn $notification->get_Message->get_value if $self->debug;
      $self->add_notice( $notification->get_Message->get_value . "\n" );
    }


    if ($response->get_CompletedTrackDetails()->get_TrackDetails()->get_Notification()->get_Severity()->get_value() eq 'ERROR') {
      $self->error($response->get_CompletedTrackDetails()->get_TrackDetails()->get_Notification()->get_Message()->get_value());
    }
    else {

      foreach my $event (@{ $response->get_CompletedTrackDetails()->get_TrackDetails()->get_Events() }) {
        $self->add_activity(
          Shipment::Activity->new(
            description => $event->get_EventDescription()->get_value(),
            date => DateTime::Format::ISO8601->parse_datetime($event->get_Timestamp()->get_value()),
            location => Shipment::Address->new(
              city => ($event->get_Address()->get_City() ? $event->get_Address()->get_City()->get_value() : ''),
              state => ($event->get_Address()->get_StateOrProvinceCode() ? $event->get_Address()->get_StateOrProvinceCode()->get_value() : ''),
              country => ($event->get_Address()->get_CountryCode() ? $event->get_Address()->get_CountryCode()->get_value() : ''),
            ),
          )
        );
      }
     $self->ship_date( DateTime::Format::ISO8601->parse_datetime($response->get_CompletedTrackDetails()->get_TrackDetails()->get_ShipTimestamp->get_value()) );

    }

  } catch {
      warn $_ if $self->debug;
      try {
        $self->error( $response->get_Notifications()->[0]->get_Message->get_value );
        warn $response->get_Notifications()->[0]->get_Message->get_value if $self->debug;
      } catch {
        $self->error( $response->get_faultstring->get_value );
        warn $response->get_faultstring->get_value if $self->debug;
      };
  };

  return;
}



sub end_of_day {
  my $self = shift;
  
  use Shipment::FedEx::WSDL::CloseInterfaces::CloseService::CloseServicePort;
  my $interface = Shipment::FedEx::WSDL::CloseInterfaces::CloseService::CloseServicePort->new(
    {
      proxy_domain => $self->proxy_domain,
    }
  );
  my $response;

  try {
    $Shipment::SOAP::WSDL::Debug = 1 if $self->debug > 1;
    $response = $interface->groundClose(
      { 
        WebAuthenticationDetail =>  {
          UserCredential =>  { 
            Key =>  $self->key,
            Password => $self->password,
          },
        },
        ClientDetail =>  { 
          AccountNumber =>  $self->account,
          MeterNumber =>  $self->meter,
        },
        Version =>  {
          ServiceId =>  'clos',
          Major =>  2,
          Intermediate =>  1,
          Minor =>  0,
        },
        TimeUpToWhichShipmentsAreToBeClosed =>  DateTime->now->datetime,
      },
    );
    $Shipment::SOAP::WSDL::Debug = 0;
    warn "Response\n" . $response if $self->debug > 1;

    $self->notice('');
    foreach my $notification (@{ $response->get_Notifications() }) {
      warn $notification->get_Message->get_value if $self->debug;
      $self->add_notice( $notification->get_Message->get_value . "\n" );
    }
    
    $self->manifest(
      Shipment::Label->new(
        content_type => 'text/plain',
        data => decode_base64($response->get_Manifest->get_File->get_value),
        file_name => 'manifest_' . DateTime->now->ymd('_') . '.txt',
      )
    );
  } catch {
    warn $_ if $self->debug;
    try {
      $self->error( $response->get_Notifications()->[0]->get_Message->get_value );
      warn $response->get_Notifications()->[0]->get_Message->get_value if $self->debug;
    } catch {
      $self->error( $response->get_faultstring->get_value );
      warn $response->get_faultstring->get_value if $self->debug;
    };
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shipment::FedEx

=head1 VERSION

version 3.10

=head1 SYNOPSIS

  use Shipment::FedEx;
  use Shipment::Address;
  use Shipment::Package;

  my $shipment = Shipment::FedEx->new(
    from_address => Shipment::Address->new( ... ),
    to_address => Shipment::Address->new( ... ),
    packages => [ Shipment::Package->new( ... ), ],
  );

  foreach my $service ( $shipment->all_services ) {
    print $service->id . "\n";
  }

  $shipment->rate( 'express' );
  print $shipment->service->cost . "\n";

  $shipment->ship( 'ground' );
  $shipment->get_package(0)->label->save;

=head1 NAME

Shipment::FedEx - Interface to FedEx Shipping Web Services

=head1 ABOUT

This class provides an interface to the FedEx Web Services for Shipping.

For code examples, see https://github.com/pullingshots/Shipment/tree/master/eg

You must sign up for a developer test key in order to make use of this module.

https://www.fedex.com/wpor/web/jsp/drclinks.jsp?links=techresources/index.html

See related modules for documentation on options and how to access rates and labels:

L<Shipment::Base> - common attributes and methods for all interfaces

L<Shipment::Address> - define an from or to address

L<Shipment::Package> - define package details, weight, dimensions, etc

L<Shipment::Service> - access information about a service, rate, etd, etc

L<Shipment::Label> - access the label file

It makes extensive use of SOAP::WSDL in order to create/decode xml requests and responses. The Shipment::FedEx::WSDL interface was created primarily using the wsdl2perl.pl script from SOAP::WSDL.

=head1 Class Attributes

=head2 meter, key, password

Credentials required to access FedEx Web Services

=head2 proxy_domain

This determines whether you will use the FedEx Web Services Testing Environment or the production (live) environment
  * wsbeta.fedex.com:443 (testing)
  * ws.fedex.com:443 (live)

=head2 shipment_special_service_types

special services offered by FedEx, for example SATURDAY_DELIVERY

=head2 residential_address

Flag the ship to address as residential.

Default is false.

=head2 label_stock_type

The label dimensions/type. 

Default: 4x6

=head1 Type Maps

=head2 Shipment::Base type maps

Shipment::Base provides abstract types which need to be mapped to FedEx codes (i.e. bill_type of "sender" maps to FedEx "SENDER")

=head2 Collect billing

FedEx offers collect billing (without the need for a billing account #)

=head2 custom package types

FedEx provides package types in addition to the defaults in Shipment::Base
  * FEDEX_10KG_BOX
  * FEDEX_25KG_BOX

=head2 default currency

The default currency is USD

=head1 Class Methods

=head2 _build_services

This calls getRates from the Rate Services API

Each Service that is returned is added to services

The following service mapping is used:
  * ground => FEDEX_GROUND or GROUND_HOME_DELIVERY or INTERNATIONAL_GROUND
  * express => FEDEX_2_DAY or INTERNATIONAL_ECONOMY
  * priority => PRIORITY_OVERNIGHT or INTERNATIONAL_PRIORITY

This method ignores what is in $self->packages and uses a single package weighing 1 pound for rating. The idea is to list what services are available, but for accurate rate comparisons, the rate method should be used.

=head2 rate

This calls getRates from the Rate Services API

=head2 ship

This method calls processShipment from the Ship Services API

=head2 cancel

This method calls deleteShipment from the Ship Services API

If the tracking id is greater than 12 digits, it assumes that it is a Ground shipment.

Currently only supports deleting one package (tracking id) at a time - DeletionControl = 'DELETE_ONE_PACKAGE'

returns "SUCCESS" if successful

=head2 track

This method calls track from the Tracking Services API

Currently only supports tracking using a valid tracking number: Type => 'TRACKING_NUMBER_OR_DOORTAG'

Result is added to $self->activities, accessible using $self->status

Also sets $self->ship_date

=head2 end_of_day

This method calls groundClose from the Close Services API

The manifest is a plain text file intended to be printed off on standard letter paper

=head1 AUTHOR

Andrew Baerg @ <andrew at pullingshots dot ca>

http://pullingshots.ca/

=head1 BUGS

Issues can be submitted at https://github.com/pullingshots/Shipment/issues

=head1 COPYRIGHT

Copyright (C) 2016 Andrew J Baerg, All Rights Reserved

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Andrew Baerg <baergaj@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andrew Baerg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
