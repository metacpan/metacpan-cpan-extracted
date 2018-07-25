package NpsSDK::Constants;

use warnings; 
use strict;

our $VERSION = '1.9'; # VERSION
our $LANGUAGE = "Perl";

our $SANDBOX_ENV = 2;
our $STAGING_ENV = 1;
our $PRODUCTION_ENV = 0;

our $PRODUCTION_URL = "https://services2.nps.com.ar:443/ws.php";
our $SANDBOX_URL = "https://sandbox.nps.com.ar:443/ws.php";
our $STAGING_URL = "https://implementacion.nps.com.ar:443/ws.php";
 
our %SANITIZE = (
    "psp_Person.FirstName.max_length"=> "128",
    "psp_Person.LastName.max_length" => "64",
    "psp_Person.MiddleName.max_length" => "64",
    "psp_Person.PhoneNumber1.max_length" => "32",
    "psp_Person.PhoneNumber2.max_length" => "32",
    "psp_Person.Gender.max_length" => "1",
    "psp_Person.Nationality.max_length" => "3",
    "psp_Person.IDNumber.max_length" => "40",
    "psp_Person.IDType.max_length" => "5",
    "psp_Address.Street.max_length" => "128",
    "psp_Address.HouseNumber.max_length" => "32",
    "psp_Address.AdditionalInfo.max_length" => "128",
    "psp_Address.City.max_length" => "40",
    "psp_Address.StateProvince.max_length" => "40",
    "psp_Address.Country.max_length" => "3",
    "psp_Address.ZipCode.max_length" => "10",
    "psp_OrderItem.Description.max_length" => "127",
    "psp_OrderItem.Type.max_length" => "20",
    "psp_OrderItem.SkuCode.max_length" => "48",
    "psp_OrderItem.ManufacturerPartNumber.max_length" => "30",
    "psp_OrderItem.Risk.max_length" => "1",
    "psp_Leg.DepartureAirport.max_length" => "3",
    "psp_Leg.ArrivalAirport.max_length" => "3",
    "psp_Leg.CarrierCode.max_length" => "2",
    "psp_Leg.FlightNumber.max_length" => "5",
    "psp_Leg.FareBasisCode.max_length" => "15",
    "psp_Leg.FareClassCode.max_length" => "3",
    "psp_Leg.BaseFareCurrency.max_length" => "3",
    "psp_Passenger.FirstName.max_length" => "50",
    "psp_Passenger.LastName.max_length" => "30",
    "psp_Passenger.MiddleName.max_length" => "30",
    "psp_Passenger.Type.max_length" => "1",
    "psp_Passenger.Nationality.max_length" => "3",
    "psp_Passenger.IDNumber.max_length" => "40",
    "psp_Passenger.IDType.max_length" => "10",
    "psp_Passenger.IDCountry.max_length" => "3",
    "psp_Passenger.LoyaltyNumber.max_length" => "20",
    "psp_SellerDetails.IDNumber.max_length" => "40",
    "psp_SellerDetails.IDType.max_length" => "10",
    "psp_SellerDetails.Name.max_length" => "128",
    "psp_SellerDetails.Invoice.max_length" => "32",
    "psp_SellerDetails.PurchaseDescription.max_length" => "32",
    "psp_SellerDetails.MCC.max_length" => "5",
    "psp_SellerDetails.ChannelCode.max_length" => "3",
    "psp_SellerDetails.GeoCode.max_length" => "5",
    "psp_TaxesRequest.TypeId.max_length" => "5",
    "psp_MerchantAdditionalDetails.Type.max_length" => "1",
    "psp_MerchantAdditionalDetails.SdkInfo.max_length" => "48",
    "psp_MerchantAdditionalDetails.ShoppingCartInfo.max_length" => "48",
    "psp_MerchantAdditionalDetails.ShoppingCartPluginInfo.max_length" => "48",
    "psp_CustomerAdditionalDetails.IPAddress.max_length" => "45",
    "psp_CustomerAdditionalDetails.AccountID.max_length" => "128",
    "psp_CustomerAdditionalDetails.DeviceFingerPrint.max_length" => "4000",
    "psp_CustomerAdditionalDetails.BrowserLanguage.max_length" => "2",
    "psp_CustomerAdditionalDetails.HttpUserAgent.max_length" => "255",
    "psp_BillingDetails.Invoice.max_length" => "32",
    "psp_BillingDetails.InvoiceCurrency.max_length" => "3",
    "psp_ShippingDetails.TrackingNumber.max_length" => "24",
    "psp_ShippingDetails.Method.max_length" => "3",
    "psp_ShippingDetails.Carrier.max_length" => "3",
    "psp_ShippingDetails.GiftMessage.max_length" => "200",
    "psp_AirlineDetails.TicketNumber.max_length" => "14",
    "psp_AirlineDetails.PNR.max_length" => "10",
    "psp_VaultReference.PaymentMethodToken.max_length" => "64",
    "psp_VaultReference.PaymentMethodId.max_length" => "64",
    "psp_VaultReference.CustomerId.max_length" => "64",
    "psp_CardInputDetails.Number.max_length"=> "19",
    "psp_CardInputDetails.SecurityCode.max_length" => "4",
    "psp_CardInputDetails.HolderName.max_length" => "26"
);

1;
