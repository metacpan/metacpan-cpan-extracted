# -*- perl -*-
##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe.pm
## Version v2.0.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2018/07/19
## Modified 2022/10/29
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use common::sense;
    use parent qw( Module::Generic );
    use vars qw(
        $VERSION $VERBOSE $DEBUG $BROWSER $ERROR_CODE_TO_STRING $TYPE2CLASS 
        $EXPANDABLES_BY_CLASS $EXPANDABLES $EXPAND_MAX_DEPTH $EXCEPTION_CLASS
        $AUTOLOAD_SUBS $AUTOLOAD
    );
    use Cookie;
    use Encode ();
    use Data::UUID;
    # use Net::OAuth;
    # use Crypt::OpenSSL::RSA;
    use Data::Random qw( rand_chars );
    use DateTime;
    use DateTime::Format::Strptime;
    use Devel::Confess;
    use Digest::MD5 qw( md5_base64 );
    use Digest::SHA ();
    use HTTP::Promise;
    use HTTP::Promise::Headers;
    use HTTP::Promise::Message;
    use HTTP::Promise::Request;
    use JSON;
    use MIME::QuotedPrint ();
    use MIME::Base64 ();
    use Module::Generic::File qw( sys_tmpdir );
    use Net::IP;
    use Nice::Try;
    use Regexp::Common;
    use Scalar::Util ();
    use URI::Escape;
    use Want;
    use constant API_BASE => 'https://api.stripe.com/v1';
    use constant FILES_BASE => 'https://files.stripe.com/v1';
    use constant STRIPE_WEBHOOK_SOURCE_IP => [qw( 54.187.174.169 54.187.205.235 54.187.216.72 54.241.31.99 54.241.31.102 54.241.34.107 )];
    our $VERSION = 'v2.0.1';
    our $EXCEPTION_CLASS = 'Net::API::Stripe::Exception';
};

use strict;
use warnings;

our $VERBOSE = 0;
our $DEBUG   = 0;
our $BROWSER = 'Net::API::Stripe/' . $VERSION;

our $ERROR_CODE_TO_STRING =
{
400 => "The request was unacceptable, due to a missing required parameter.",
401 => "No valid API key provided.",
402 => "The parameters were valid but the request failed.",
403 => "The API key doesn't have permissions to perform the request.",
404 => "The requested resource doesn't exist.",
409 => "The request conflicts with another request.",
429 => "Too many requests hit the API too quickly. We recommend an exponential backoff of your requests.",
500 => "Something went wrong on Stripe's end.",
502 => "Something went wrong on Stripe's end.",
503 => "Something went wrong on Stripe's end.",
504 => "Something went wrong on Stripe's end.",
# Payout: https://stripe.com/docs/api/payouts/failures
account_closed          => "The bank account has been closed.",
# Payout
account_frozen          => "The bank account has been frozen.",
amount_too_large        => "The specified amount is greater than the maximum amount allowed. Use a lower amount and try again.",
amount_too_small        => "The specified amount is less than the minimum amount allowed. Use a higher amount and try again.",
api_connection_error    => "Failure to connect to Stripe's API.",
api_error               => "Striipe API error",
api_key_expired         => "The API key provided has expired",
authentication_error    => "Failure to properly authenticate yourself in the request.",
balance_insufficient    => "The transfer or payout could not be completed because the associated account does not have a sufficient balance available.",
bank_account_exists     => "The bank account provided already exists on the specified Customer object. If the bank account should also be attached to a different customer, include the correct customer ID when making the request again.",
# Payout: https://stripe.com/docs/api/payouts/failures
bank_account_restricted => "The bank account has restrictions on either the type, or the number, of payouts allowed. This normally indicates that the bank account is a savings or other non-checking account.",
bank_account_unusable   => "The bank account provided cannot be used for payouts. A different bank account must be used.",
bank_account_unverified => "Your Connect platform is attempting to share an unverified bank account with a connected account.",
# Payout
bank_ownership_changed  => "The destination bank account is no longer valid because its branch has changed ownership.",
card_declined           => "The card has been declined.",
card_error              => "Card error",
charge_already_captured => "The charge youâre attempting to refund has already been refunded.",
# Payout
could_not_process       => "The bank could not process this payout.",
# Payout
debit_not_authorized    => "Debit transactions are not approved on the bank account. (Stripe requires bank accounts to be set up for both credit and debit payouts.)",
# Payout
declined                => "The bank has declined this transfer. Please contact the bank before retrying.",
email_invalid           => "The email address is invalid.",
expired_card            => "The card has expired. Check the expiration date or use a different card.",
idempotency_error       => "Idempotency error",
# Payout
incorrect_account_holder_name => "Your bank notified us that the bank account holder name on file is incorrect.",
incorrect_cvc           => "The cardâs security code is incorrect. Check the cardâs security code or use a different card.",
incorrect_number        => "The card number is incorrect. Check the cardâs number or use a different card.",
incorrect_zip           => "The cardâs postal code is incorrect. Check the cardâs postal code or use a different card.",
instant_payouts_unsupported => "The debit card provided as an external account does not support instant payouts. Provide another debit card or use a bank account instead.",
# Payout
insufficient_funds      => "Your Stripe account has insufficient funds to cover the payout.",
# Payout
invalid_account_number  => "The routing number seems correct, but the account number is invalid.",
invalid_card_type       => "The card provided as an external account is not a debit card. Provide a debit card or use a bank account instead.",
invalid_charge_amount   => "The specified amount is invalid. The charge amount must be a positive integer in the smallest currency unit, and not exceed the minimum or maximum amount.",
# Payout
invalid_currency        => "The bank was unable to process this payout because of its currency. This is probably because the bank account cannot accept payments in that currency.",
invalid_cvc             => "The cardâs security code is invalid. Check the cardâs security code or use a different card.",
invalid_expiry_month    => "The cardâs expiration month is incorrect. Check the expiration date or use a different card.",
invalid_expiry_year     => "The cardâs expiration year is incorrect. Check the expiration date or use a different card.",
invalid_number          => "The card number is invalid. Check the card details or use a different card.",
invalid_request_error   => "Invalid request error. Request has invalid parameters.",
livemode_mismatch       => "Test and live mode API keys, requests, and objects are only available within the mode they are in.",
missing                 => "Both a customer and source ID have been provided, but the source has not been saved to the customer. ",
# Payout
no_account              => "The bank account details on file are probably incorrect. No bank account could be located with those details.",
parameter_invalid_empty => "One or more required values were not provided. Make sure requests include all required parameters.",
parameter_invalid_integer => "One or more of the parameters requires an integer, but the values provided were a different type. Make sure that only supported values are provided for each attribute.",
parameter_invalid_string_blank => "One or more values provided only included whitespace. Check the values in your request and update any that contain only whitespace.",
parameter_invalid_string_empty => "One or more required string values is empty. Make sure that string values contain at least one character.",
parameter_missing       => "One or more required values are missing.",
parameter_unknown       => "The request contains one or more unexpected parameters. Remove these and try again.",
payment_method_unactivated => "The charge cannot be created as the payment method used has not been activated.",
payouts_not_allowed     => "Payouts have been disabled on the connected account.",
platform_api_key_expired => "The API key provided by your Connect platform has expired.",
postal_code_invalid     => "The postal code provided was incorrect.",
processing_error        => "An error occurred while processing the card. Check the card details are correct or use a different card.",
rate_limit              => "Too many requests hit the API too quickly. We recommend an exponential backoff of your requests.",
rate_limit_error        => "Too many requests hit the API too quickly.",
testmode_charges_only   => "This account has not been activated and can only make test charges.",
tls_version_unsupported => "Your integration is using an older version of TLS that is unsupported. You must be using TLS 1.2 or above.",
token_already_used      => "The token provided has already been used. You must create a new token before you can retry this request.",
transfers_not_allowed   => "The requested transfer cannot be created. Contact us if you are receiving this error.",
# Payout
unsupported_card        => "The bank no longer supports payouts to this card.",
upstream_order_creation_failed => "The order could not be created. Check the order details and then try again.",
url_invalid             => "The URL provided is invalid.",
validation_error        => "Stripe client-side library error: improper field validation",
};

our $TYPE2CLASS =
{
  "account"                           => "Net::API::Stripe::Connect::Account",
  "account_bank_account"              => "Net::API::Stripe::Connect::ExternalAccount::Bank",
  "account_card"                      => "Net::API::Stripe::Connect::ExternalAccount::Card",
  "account_link"                      => "Net::API::Stripe::Connect::Account::Link",
  "ach_credit_transfer"               => "Net::API::Stripe::Payment::Source::ACHCreditTransfer",
  "ach_debit"                         => "Net::API::Stripe::Payment::Source::ACHDebit",
  "additional_document"               => "Net::API::Stripe::Connect::Account::Document",
  "address"                           => "Net::API::Stripe::Address",
  "address_kana"                      => "Net::API::Stripe::AddressKana",
  "address_kanji"                     => "Net::API::Stripe::AddressKanji",
  "application"                       => "Net::API::Stripe::Connect::Account",
  "application_fee"                   => "Net::API::Stripe::Connect::ApplicationFee",
  "authorization_controls"            => "Net::API::Stripe::Issuing::Card::AuthorizationsControl",
  "balance"                           => "Net::API::Stripe::Balance",
  "balance_transaction"               => "Net::API::Stripe::Balance::Transaction",
  # "bank_account"                      => "Net::API::Stripe::Connect::ExternalAccount::Bank",
  # which inherits from Net::API::Stripe::Connect::ExternalAccount::Bank
  "bank_account"                      => "Net::API::Stripe::Customer::BankAccount",
  "billing"                           => "Net::API::Stripe::Billing::Details",
  "billing_address"                   => "Net::API::Stripe::Address",
  "billing_details"                   => "Net::API::Stripe::Billing::Details",
  "billing_portal_configuration"      => "Net::API::Stripe::Billing::PortalConfiguration",
  "billing_portal.session"            => "Net::API::Stripe::Billing::PortalSession",
  "billing_thresholds"                => "Net::API::Stripe::Billing::Thresholds",
  "bitcoin_transaction"               => "Net::API::Stripe::Bitcoin::Transaction",
  "branding"                          => "Net::API::Stripe::Connect::Account::Branding",
  "business_profile"                  => "Net::API::Stripe::Connect::Business::Profile",
  "capability"                        => "Net::API::Stripe::Connect::Account::Capability",
  # "card"                              => "Net::API::Stripe::Connect::ExternalAccount::Card",
  # which inherits from Net::API::Stripe::Connect::ExternalAccount::Card
  "card"                              => "Net::API::Stripe::Customer::Card",
  "card_payments"                     => "Net::API::Stripe::Connect::Account::Settings::CardPayments",
  "cardholder"                        => "Net::API::Stripe::Issuing::Card::Holder",
  "cash_balance"                      => "Net::API::Stripe::Cash::Balance",
  "charge"                            => "Net::API::Stripe::Charge",
  "charges"                           => "Net::API::Stripe::List",
  "checkout.session"                  => "Net::API::Stripe::Checkout::Session",
  "checkout_session"                  => "Net::API::Stripe::Checkout::Session",
  "code_verification"                 => "Net::API::Stripe::Payment::Source::CodeVerification",
  "company"                           => "Net::API::Stripe::Connect::Account::Company",
  "country_spec"                      => "Net::API::Stripe::Connect::CountrySpec",
  "coupon"                            => "Net::API::Stripe::Billing::Coupon",
  "credit_note"                       => "Net::API::Stripe::Billing::CreditNote",
  "credit_note_line_item"             => "Net::API::Stripe::Billing::CreditNote::LineItem",
  "credit_noteline_item"              => "Net::API::Stripe::Billing::CreditNote::LineItem",
  "customer"                          => "Net::API::Stripe::Customer",
  "customer_address"                  => "Net::API::Stripe::Address",
  "customer_balance_transaction"      => "Net::API::Stripe::Customer::BalanceTransaction",
  "customer_bank_account"             => "Net::API::Stripe::Connect::ExternalAccount::Bank",
  "customer_cash_balance_transaction" => "Net::API::Stripe::Cash::Transaction",
  "customer_shipping"                 => "Net::API::Stripe::Shipping",
  "dashboard"                         => "Net::API::Stripe::Connect::Account::Settings::Dashboard",
  "data"                              => "Net::API::Stripe::Event::Data",
  "discount"                          => "Net::API::Stripe::Billing::Discount",
  "dispute"                           => "Net::API::Stripe::Dispute",
  "dispute_evidence"                  => "Net::API::Stripe::Dispute::Evidence",
  "document"                          => "Net::API::Stripe::Connect::Account::Document",
  "early_fraud_warning"               => "Net::API::Stripe::Fraud",
  "error"                             => "Net::API::Stripe::Error",
  "event"                             => "Net::API::Stripe::Event",
  "evidence"                          => "Net::API::Stripe::Issuing::Dispute::Evidence",
  "evidence_details"                  => "Net::API::Stripe::Dispute::EvidenceDetails",
  "external_accounts"                 => "Net::API::Stripe::List",
  "fee_refund"                        => "Net::API::Stripe::Connect::ApplicationFee::Refund",
  "file"                              => "Net::API::Stripe::File",
  "file_link"                         => "Net::API::Stripe::File::Link",
  "fraud_value_list"                  => "Net::API::Stripe::Fraud::ValueList",
  "fraud_value_list_item"             => "Net::API::Stripe::Fraud::ValueList::Item",
  "fraud_warning"                     => "Net::API::Stripe::Fraud",
  "fraudulent"                        => "Net::API::Stripe::Issuing::Dispute::Evidence::Fraudulent",
  "generated_from"                    => "Net::API::Stripe::Payment::GeneratedFrom",
  "identity_verification_report"      => "Net::API::Stripe::Identity::VerificationReport",
  "identity_verification_session"     => "Net::API::Stripe::Identity::VerificationSession",
  "individual"                        => "Net::API::Stripe::Connect::Person",
  "inventory"                         => "Net::API::Stripe::Order::SKU::Inventory",
  "invoice"                           => "Net::API::Stripe::Billing::Invoice",
  "invoice_customer_balance_settings" => "Net::API::Stripe::Billing::Invoice::BalanceSettings",
  "invoice_settings"                  => "Net::API::Stripe::Billing::Invoice::Settings",
  "invoiceitem"                       => "Net::API::Stripe::Billing::Invoice::Item",
  "invoice_item"                      => "Net::API::Stripe::Billing::Invoice::Item",
  "ip_address_location"               => "Net::API::Stripe::GeoLocation",
  "issuing.authorization"             => "Net::API::Stripe::Issuing::Authorization",
  "issuing.card"                      => "Net::API::Stripe::Issuing::Card",
  "issuing.cardholder"                => "Net::API::Stripe::Issuing::Card::Holder",
  "issuing.dispute"                   => "Net::API::Stripe::Issuing::Dispute",
  "issuing.transaction"               => "Net::API::Stripe::Issuing::Transaction",
  "issuing_authorization"             => "Net::API::Stripe::Issuing::Authorization",
  "issuing_card"                      => "Net::API::Stripe::Issuing::Card",
  "issuing_cardholder"                => "Net::API::Stripe::Issuing::Card::Holder",
  "issuing_dispute"                   => "Net::API::Stripe::Issuing::Dispute",
  "issuing_transaction"               => "Net::API::Stripe::Issuing::Transaction",
  "item"                              => "Net::API::Stripe::List::Item",
  "items"                             => "Net::API::Stripe::List",
  "last_payment_error"                => "Net::API::Stripe::Error",
  "last_setup_error"                  => "Net::API::Stripe::Error",
  "line_item"                         => "Net::API::Stripe::Billing::Invoice::LineItem",
  "lines"                             => "Net::API::Stripe::List",
  "links"                             => "Net::API::Stripe::List",
  "list"                              => "Net::API::Stripe::List",
  "list_items"                        => "Net::API::Stripe::List",
  "login_link"                        => "Net::API::Stripe::Connect::Account::LoginLink",
  "mandate"                           => "Net::API::Stripe::Mandate",
  "merchant_data"                     => "Net::API::Stripe::Issuing::MerchantData",
  "next_action"                       => "Net::API::Stripe::Payment::Intent::NextAction",
  "order"                             => "Net::API::Stripe::Order",
  "order_legacy"                      => "Net::API::Stripe::Order",
  "order_item"                        => "Net::API::Stripe::Order::Item",
  "order_return"                      => "Net::API::Stripe::Order::Return",
  "other"                             => "Net::API::Stripe::Issuing::Dispute::Evidence::Other",
  "outcome"                           => "Net::API::Stripe::Charge::Outcome",
  "owner"                             => "Net::API::Stripe::Payment::Source::Owner",
  "package_dimensions"                => "Net::API::Stripe::Order::SKU::PackageDimensions",
  "payment_intent"                    => "Net::API::Stripe::Payment::Intent",
  "payment_method"                    => "Net::API::Stripe::Payment::Method",
  "payment_method_details"            => "Net::API::Stripe::Payment::Method::Details",
  "payments"                          => "Net::API::Stripe::Connect::Account::Settings::Payments",
  "payout"                            => "Net::API::Stripe::Payout",
  "payouts"                           => "Net::API::Stripe::Connect::Account::Settings::Payouts",
  "pending_invoice_item_interval"     => "Net::API::Stripe::Billing::Plan",
  "period"                            => "Net::API::Stripe::Billing::Invoice::Period",
  "person"                            => "Net::API::Stripe::Connect::Person",
  "plan"                              => "Net::API::Stripe::Billing::Plan",
  "portal_configuration"              => "Net::API::Stripe::Billing::PortalConfiguration",
  "portal_session"                    => "Net::API::Stripe::Billing::PortalSession",
  "price"                             => "Net::API::Stripe::Price",
  "product"                           => "Net::API::Stripe::Product",
  "promotion_code"                    => "Net::API::Stripe::Billing::PromotionCode",
  "quote"                             => "Net::API::Stripe::Billing::Quote",
  "radar.early_fraud_warning"         => "Net::API::Stripe::Fraud",
  "radar.value_list"                  => "Net::API::Stripe::Fraud::ValueList",
  "radar.value_list_item"             => "Net::API::Stripe::Fraud::ValueList::Item",
  "radar_early_fraud_warning"         => "Net::API::Stripe::Fraud",
  "radar_value_list"                  => "Net::API::Stripe::Fraud::ValueList",
  "radar_value_list_item"             => "Net::API::Stripe::Fraud::ValueList::Item",
  "receiver"                          => "Net::API::Stripe::Payment::Source::Receiver",
  "redirect"                          => "Net::API::Stripe::Payment::Source::Redirect",
  "refund"                            => "Net::API::Stripe::Refund",
  "refunds"                           => "Net::API::Stripe::Charge::Refunds",
  "relationship"                      => "Net::API::Stripe::Connect::Account::Relationship",
  "report_run"                        => "Net::API::Stripe::Reporting::ReportRun",
  "report_type"                       => "Net::API::Stripe::Reporting::ReportType",
  "reporting.report_run"              => "Net::API::Stripe::Reporting::ReportRun",
  "reporting.report_type"             => "Net::API::Stripe::Reporting::ReportType",
  "reporting_report_run"              => "Net::API::Stripe::Reporting::ReportRun",
  "reporting_report_type"             => "Net::API::Stripe::Reporting::ReportType",
  "request"                           => "Net::API::Stripe::Event::Request",
  "requirements"                      => "Net::API::Stripe::Connect::Account::Requirements",
  "result"                            => "Net::API::Stripe::File",
  "returns"                           => "Net::API::Stripe::Order::Returns",
  "reversals"                         => "Net::API::Stripe::Connect::Transfer::Reversals",
  "review"                            => "Net::API::Stripe::Fraud::Review",
  "review_session"                    => "Net::API::Stripe::Fraud::Review::Session",
  "scheduled_query_run"               => "Net::API::Stripe::Sigma::ScheduledQueryRun",
  "settings"                          => "Net::API::Stripe::Connect::Account::Settings",
  "setup_attempt"                     => "Net::API::Stripe::SetupAttempt",
  "setup_intent"                      => "Net::API::Stripe::Payment::Intent::Setup",
  "shipping"                          => "Net::API::Stripe::Shipping",
  "shipping_address"                  => "Net::API::Stripe::Address",
  "shipping_rate"                     => "Net::API::Stripe::Shipping::Rate",
  "sku"                               => "Net::API::Stripe::Order::SKU",
  "source"                            => "Net::API::Stripe::Payment::Source",
  "source_order"                      => "Net::API::Stripe::Order",
  "sources"                           => "Net::API::Stripe::Customer::Sources",
  "status_transitions"                => "Net::API::Stripe::Billing::Invoice::StatusTransition",
  "subscription"                      => "Net::API::Stripe::Billing::Subscription",
  "subscription_item"                 => "Net::API::Stripe::Billing::Subscription::Item",
  "subscription_schedule"             => "Net::API::Stripe::Billing::Subscription::Schedule",
  "subscriptions"                     => "Net::API::Stripe::List",
  "support_address"                   => "Net::API::Stripe::Address",
  "tax_code"                          => "Net::API::Stripe::Product::TaxCode",
  "tax_id"                            => "Net::API::Stripe::Customer::TaxId",
  "tax_ids"                           => "Net::API::Stripe::Customer::TaxIds",
  "tax_info"                          => "Net::API::Stripe::Customer::TaxInfo",
  "tax_info_verification"             => "Net::API::Stripe::Customer::TaxInfoVerification",
  "tax_rate"                          => "Net::API::Stripe::Tax::Rate",
  "terminal.connection_token"         => "Net::API::Stripe::Terminal::ConnectionToken",
  "terminal.location"                 => "Net::API::Stripe::Terminal::Location",
  "terminal.reader"                   => "Net::API::Stripe::Terminal::Reader",
  "terminal_connection_token"         => "Net::API::Stripe::Terminal::ConnectionToken",
  "terminal_location"                 => "Net::API::Stripe::Terminal::Location",
  "terminal_reader"                   => "Net::API::Stripe::Terminal::Reader",
  "threshold_reason"                  => "Net::API::Stripe::Billing::Thresholds",
  "token"                             => "Net::API::Stripe::Token",
  "topup"                             => "Net::API::Stripe::Connect::TopUp",
  "tos_acceptance"                    => "Net::API::Stripe::Connect::Account::TosAcceptance",
  "transactions"                      => "Net::API::Stripe::List",
  "transfer"                          => "Net::API::Stripe::Connect::Transfer",
  "transfer_data"                     => "Net::API::Stripe::Payment::Intent::TransferData",
  "transfer_reversal"                 => "Net::API::Stripe::Connect::Transfer::Reversal",
  "transform_usage"                   => "Net::API::Stripe::Billing::Plan::TransformUsage",
  "usage_record"                      => "Net::API::Stripe::Billing::UsageRecord",
  "verification"                      => "Net::API::Stripe::Connect::Account::Verification",
  "verification_data"                 => "Net::API::Stripe::Issuing::Authorization::VerificationData",
  "verification_fields"               => "Net::API::Stripe::Connect::CountrySpec::VerificationFields",
  "verified_address"                  => "Net::API::Stripe::Address",
  "webhook_endpoint"                  => "Net::API::Stripe::WebHook::Object",
};

our $EXPANDABLES_BY_CLASS =
{
  "account"                                 => {},
  "account_bank_account"                    => { account => ["account"], customer => ["customer"] },
  "account_card"                            => { account => ["account"], customer => ["customer"] },
  "account_link"                            => {},
  "address"                                 => {},
  "address_kana"                            => {},
  "address_kanji"                           => {},
  "application_fee"                         => {
                                                 account => ["account"],
                                                 application => ["account"],
                                                 balance_transaction => ["balance_transaction"],
                                                 charge => ["charge"],
                                                 originating_transaction => ["charge"],
                                               },
  "apps.secret"                             => {},
  "balance"                                 => {},
  "balance_transaction"                     => {
                                                 source => [
                                                   "charge",
                                                   "dispute",
                                                   "fee_refund",
                                                   "payout",
                                                   "application_fee",
                                                   "refund",
                                                   "topup",
                                                   "issuing_transaction",
                                                   "transfer",
                                                   "transfer_reversal",
                                                 ],
                                               },
  "bank_account"                            => { account => ["account"], customer => ["customer"] },
  "billing_details"                         => {},
  "billing_portal.configuration"            => { application => ["account"] },
  "billing_portal.session"                  => { configuration => ["billing_portal.configuration"] },
  "billing_thresholds"                      => {},
  "business_profile"                        => {},
  "capability"                              => { account => ["account"] },
  "card"                                    => { account => ["account"], customer => ["customer"] },
  "cash_balance"                            => {},
  "charge"                                  => {
                                                 application                 => ["account"],
                                                 application_fee             => ["application_fee"],
                                                 balance_transaction         => ["balance_transaction"],
                                                 customer                    => ["customer"],
                                                 failure_balance_transaction => ["balance_transaction", "balance_transaction"],
                                                 invoice                     => ["invoice"],
                                                 on_behalf_of                => ["account"],
                                                 payment_intent              => ["payment_intent"],
                                                 review                      => ["review"],
                                                 source_transfer             => ["transfer"],
                                                 transfer                    => ["transfer"],
                                               },
  "checkout.session"                        => {
                                                 customer       => ["customer"],
                                                 payment_intent => ["payment_intent"],
                                                 payment_link   => ["payment_link"],
                                                 setup_intent   => ["setup_intent"],
                                                 subscription   => ["subscription"],
                                               },
  "code_verification"                       => {},
  "company"                                 => {},
  "country_spec"                            => {},
  "coupon"                                  => {},
  "credit_note"                             => {
                                                 customer => ["customer"],
                                                 customer_balance_transaction => ["customer_balance_transaction"],
                                                 invoice => ["invoice"],
                                                 refund => ["refund"],
                                               },
  "credit_note_line_item"                   => {},
  "customer"                                => {
                                                 default_source => ["bank_account", "card", "source"],
                                                 test_clock     => ["test_helpers.test_clock", "test_helpers.test_clock"],
                                               },
  "customer_balance_transaction"            => {
                                                 credit_note => ["credit_note"],
                                                 customer    => ["customer"],
                                                 invoice     => ["invoice"],
                                               },
  "customer_cash_balance_transaction"       => { customer => ["customer"] },
  "data"                                    => {},
  "discount"                                => { customer => ["customer"], promotion_code => ["promotion_code"] },
  "dispute"                                 => { charge => ["charge"], payment_intent => ["payment_intent"] },
  "dispute_evidence"                        => {
                                                 cancellation_policy            => ["file"],
                                                 customer_communication         => ["file"],
                                                 customer_signature             => ["file"],
                                                 duplicate_charge_documentation => ["file"],
                                                 receipt                        => ["file"],
                                                 refund_policy                  => ["file"],
                                                 service_documentation          => ["file"],
                                                 shipping_documentation         => ["file"],
                                                 uncategorized_file             => ["file"],
                                               },
  "document"                                => {},
  "error"                                   => {},
  "event"                                   => {},
  "evidence"                                => {},
  "evidence_details"                        => {},
  "fee_refund"                              => {
                                                 balance_transaction => ["balance_transaction"],
                                                 fee => ["application_fee"],
                                               },
  "file"                                    => {},
  "file_link"                               => { file => ["file"] },
  "financial_connections.account"           => {
                                                 ownership => [
                                                   "financial_connections.account_ownership",
                                                   "financial_connections.account_ownership",
                                                 ],
                                               },
  "financial_connections.account_owner"     => {},
  "financial_connections.account_ownership" => {},
  "financial_connections.session"           => {},
  "funding_instructions"                    => {},
  "identity.verification_report"            => {},
  "identity.verification_session"           => {
                                                 last_verification_report => [
                                                   "identity_verification_report",
                                                   "identity_verification_report",
                                                 ],
                                               },
  "invoice"                                 => {
                                                 account_tax_ids        => ["tax_id"],
                                                 application            => ["account"],
                                                 charge                 => ["charge"],
                                                 customer               => ["customer"],
                                                 default_payment_method => ["payment_method"],
                                                 default_source         => ["bank_account", "card", "source"],
                                                 discounts              => ["discount"],
                                                 on_behalf_of           => ["account"],
                                                 payment_intent         => ["payment_intent"],
                                                 quote                  => ["quote"],
                                                 subscription           => ["subscription"],
                                                 test_clock             => ["test_helpers.test_clock"],
                                               },
  "invoice_settings"                        => { default_payment_method => ["payment_method"] },
  "invoiceitem"                             => {
                                                 customer     => ["customer"],
                                                 discounts    => ["discount"],
                                                 invoice      => ["invoice"],
                                                 subscription => ["subscription"],
                                                 test_clock   => ["test_helpers.test_clock"],
                                               },
  "ip_address_location"                     => {},
  "issuing.authorization"                   => { cardholder => ["issuing_cardholder"] },
  "issuing.card"                            => {
                                                 replaced_by     => ["issuing_card"],
                                                 replacement_for => ["issuing_card"],
                                               },
  "issuing.cardholder"                      => {},
  "issuing.dispute"                         => { transaction => ["issuing_transaction"] },
  "issuing.transaction"                     => {
                                                 authorization => ["issuing_authorization"],
                                                 balance_transaction => ["balance_transaction"],
                                                 card => ["issuing_card"],
                                                 cardholder => ["issuing_cardholder"],
                                                 dispute => ["issuing_dispute"],
                                               },
  "item"                                    => {},
  "line_item"                               => { discounts => ["discount"] },
  "login_link"                              => {},
  "mandate"                                 => { payment_method => ["payment_method"] },
  "merchant_data"                           => {},
  "next_action"                             => {},
  "outcome"                                 => {},
  "owner"                                   => {},
  "package_dimensions"                      => {},
  "payment_intent"                          => {
                                                 application    => ["account"],
                                                 customer       => ["customer"],
                                                 invoice        => ["invoice"],
                                                 on_behalf_of   => ["account"],
                                                 payment_method => ["payment_method"],
                                                 review         => ["review"],
                                               },
  "payment_link"                            => { on_behalf_of => ["account"] },
  "payment_method"                          => { customer => ["customer"] },
  "payment_method_details"                  => {},
  "payout"                                  => {
                                                 balance_transaction         => ["balance_transaction"],
                                                 destination                 => ["card", "bank_account"],
                                                 failure_balance_transaction => ["balance_transaction"],
                                                 original_payout             => ["payout"],
                                                 reversed_by                 => ["payout"],
                                               },
  "period"                                  => {},
  "person"                                  => {},
  "plan"                                    => { product => ["product"] },
  "price"                                   => { product => ["product"] },
  "product"                                 => {
                                                 default_price => ["price", "price"],
                                                 tax_code => ["tax_code", "tax_code"],
                                               },
  "promotion_code"                          => { customer => ["customer"] },
  "quote"                                   => {
                                                 application           => ["account"],
                                                 customer              => ["customer"],
                                                 default_tax_rates     => ["tax_rate"],
                                                 discounts             => ["discount"],
                                                 invoice               => ["invoice"],
                                                 on_behalf_of          => ["account"],
                                                 subscription          => ["subscription"],
                                                 subscription_schedule => ["subscription_schedule"],
                                                 test_clock            => ["test_helpers.test_clock"],
                                               },
  "radar.early_fraud_warning"               => {
                                                 charge => ["charge"],
                                                 payment_intent => ["payment_intent", "payment_intent"],
                                               },
  "radar.value_list"                        => {},
  "radar.value_list_item"                   => {},
  "receiver"                                => {},
  "redirect"                                => {},
  "refund"                                  => {
                                                 balance_transaction => ["balance_transaction"],
                                                 charge => ["charge"],
                                                 failure_balance_transaction => ["balance_transaction"],
                                                 payment_intent => ["payment_intent"],
                                                 source_transfer_reversal => ["transfer_reversal"],
                                                 transfer_reversal => ["transfer_reversal"],
                                               },
  "relationship"                            => {},
  "reporting.report_run"                    => {},
  "reporting.report_type"                   => {},
  "request"                                 => {},
  "requirements"                            => {},
  "review"                                  => { charge => ["charge"], payment_intent => ["payment_intent"] },
  "scheduled_query_run"                     => {},
  "settings"                                => {},
  "setup_attempt"                           => {
                                                 application    => ["account"],
                                                 customer       => ["customer"],
                                                 on_behalf_of   => ["account"],
                                                 payment_method => ["payment_method"],
                                                 setup_intent   => ["setup_intent"],
                                               },
  "setup_intent"                            => {
                                                 application        => ["account"],
                                                 customer           => ["customer"],
                                                 latest_attempt     => ["setup_attempt"],
                                                 mandate            => ["mandate"],
                                                 on_behalf_of       => ["account"],
                                                 payment_method     => ["payment_method"],
                                                 single_use_mandate => ["mandate"],
                                               },
  "shipping"                                => {},
  "shipping_rate"                           => { tax_code => ["tax_code"] },
  "source"                                  => {},
  "source_order"                            => {},
  "status_transitions"                      => {},
  "subscription"                            => {
                                                 application            => ["account"],
                                                 customer               => ["customer"],
                                                 default_payment_method => ["payment_method"],
                                                 default_source         => ["bank_account", "card", "source"],
                                                 latest_invoice         => ["invoice"],
                                                 pending_setup_intent   => ["setup_intent"],
                                                 schedule               => ["subscription_schedule"],
                                                 test_clock             => ["test_helpers.test_clock"],
                                               },
  "subscription_item"                       => {},
  "subscription_schedule"                   => {
                                                 application  => ["account", "account"],
                                                 customer     => ["customer"],
                                                 subscription => ["subscription"],
                                                 test_clock   => ["test_helpers.test_clock", "test_helpers.test_clock"],
                                               },
  "tax_code"                                => {},
  "tax_id"                                  => { customer => ["customer"] },
  "tax_rate"                                => {},
  "terminal.configuration"                  => { splashscreen => ["file", "file"] },
  "terminal.connection_token"               => {},
  "terminal.location"                       => {},
  "terminal.reader"                         => { location => ["terminal_location"] },
  "test_helpers.test_clock"                 => {},
  "token"                                   => {},
  "topup"                                   => { balance_transaction => ["balance_transaction"] },
  "tos_acceptance"                          => {},
  "transfer"                                => {
                                                 balance_transaction => ["balance_transaction"],
                                                 destination         => ["account"],
                                                 destination_payment => ["charge"],
                                                 source_transaction  => ["charge"],
                                               },
  "transfer_data"                           => { destination => ["account"] },
  "transfer_reversal"                       => {
                                                 balance_transaction => ["balance_transaction"],
                                                 destination_payment_refund => ["refund"],
                                                 source_refund => ["refund"],
                                                 transfer => ["transfer"],
                                               },
  "transform_usage"                         => {},
  "treasury.credit_reversal"                => { transaction => ["treasury.transaction", "treasury.transaction"] },
  "treasury.debit_reversal"                 => { transaction => ["treasury.transaction", "treasury.transaction"] },
  "treasury.financial_account"              => {},
  "treasury.financial_account_features"     => {},
  "treasury.inbound_transfer"               => { transaction => ["treasury.transaction", "treasury.transaction"] },
  "treasury.outbound_payment"               => {
                                                 transaction => [
                                                   "treasury.transaction",
                                                   "treasury.transaction",
                                                   "treasury.transaction",
                                                 ],
                                               },
  "treasury.outbound_transfer"              => {
                                                 transaction => [
                                                   "treasury.transaction",
                                                   "treasury.transaction",
                                                   "treasury.transaction",
                                                 ],
                                               },
  "treasury.received_credit"                => { transaction => ["treasury.transaction", "treasury.transaction"] },
  "treasury.received_debit"                 => { transaction => ["treasury.transaction", "treasury.transaction"] },
  "treasury.transaction"                    => {},
  "treasury.transaction_entry"              => { transaction => ["treasury.transaction", "treasury.transaction"] },
  "usage_record"                            => {},
  "usage_record_summary"                    => {},
  "verification"                            => {},
  "verification_data"                       => {},
  "verification_fields"                     => {},
  "webhook_endpoint"                        => {},
};

# As per Stripe documentation: https://stripe.com/docs/api/expanding_objects
our $EXPANDABLES = {};
our $EXPAND_MAX_DEPTH = 4;

{
    my $get_expandables;
    $get_expandables = sub
    {
        my $class = shift( @_ ) || CORE::return;
        my $pref  = shift( @_ );
        my $depth = shift( @_ ) || 0;
        # print( "." x $depth, "Checking class \"$class\" with prefix \"$pref\" and depth $depth\n" );
        CORE::return if( $depth > $EXPAND_MAX_DEPTH );
        CORE::return if( !CORE::exists( $EXPANDABLES_BY_CLASS->{ $class } ) );
        my $ref = $EXPANDABLES_BY_CLASS->{ $class };
        my $list = [];
        CORE::push( @$list, $pref ) if( CORE::length( $pref ) );
        foreach my $prop ( sort( keys( %$ref ) ) )
        {
            my $target_classes = ref( $ref->{ $prop } ) eq 'ARRAY' ? $ref->{ $prop } : [ $ref->{ $prop } ];
            my $new_prefix = CORE::length( $pref ) ? "${pref}.${prop}" : $prop;
            my $this_path = [split(/\./, $new_prefix)];
            my $this_depth = scalar( @$this_path );
            foreach my $target_class ( @$target_classes )
            {
                my $res = $get_expandables->( $target_class, $new_prefix, $this_depth );
                CORE::push( @$list, @$res ) if( ref( $res ) && scalar( @$res ) );
            }
        }
        CORE::return( $list );
    };

    if( !scalar( keys( %$EXPANDABLES ) ) )
    {
        foreach my $prop ( sort( keys( %$EXPANDABLES_BY_CLASS ) ) )
        {
            if( !scalar( keys( %{$EXPANDABLES_BY_CLASS->{ $prop }} ) ) )
            {
                $EXPANDABLES->{ $prop } = [];
                next;
            }
            my $res = $get_expandables->( $prop, '', 0 );
            $EXPANDABLES->{ $prop } = $res if( ref( $res ) && scalar( @$res ) );
        }
        $EXPANDABLES->{invoice_item} = $EXPANDABLES->{invoiceitem};
    }
}

sub init;
sub api_uri;
sub auth;
sub browser;
sub code2error;
sub conf_file;
sub cookie_file;
sub currency;
sub delete;
sub encode_with_json;
sub expand;
sub fields;
sub file_api_uri;
sub generate_uuid;
sub get;
sub http_client;
sub http_request;
sub http_response;
sub ignore_unknown_parameters;
sub json;
sub key;
sub livemode;
sub post;
sub post_multipart;
sub version;
sub webhook_validate_signature;
sub webhook_validate_caller_ip;
sub account;
sub account_bank_account;
sub account_bank_account_create;
sub account_bank_account_delete;
sub account_bank_account_list;
sub account_bank_account_retrieve;
sub account_bank_account_update;
sub account_bank_accounts;
sub account_card;
sub account_card_create;
sub account_card_delete;
sub account_card_list;
sub account_card_retrieve;
sub account_card_update;
sub account_cards;
sub account_create;
sub account_delete;
sub account_link;
sub account_link_create;
sub account_links;
sub account_list;
sub account_reject;
sub account_retrieve;
sub account_token_create;
sub account_update;
sub accounts;
sub address;
sub address_kana;
sub address_kanji;
sub amount;
sub application_fee;
sub application_fee_list;
sub application_fee_refund;
sub application_fee_retrieve;
sub application_fees;
sub apps_secret;
sub apps_secret_delete;
sub apps_secret_find;
sub apps_secret_list;
sub apps_secret_set;
sub apps_secrets;
sub authorization;
sub balance;
sub balance_retrieve;
sub balance_transaction;
sub balance_transaction_list;
sub balance_transaction_retrieve;
sub balance_transactions;
sub balances;
sub bank_account;
sub bank_account_create;
sub bank_account_delete;
sub bank_account_list;
sub bank_account_retrieve;
sub bank_account_update;
sub bank_account_verify;
sub bank_accounts;
sub bank_token_create;
sub billing_details;
sub billing_portal_configuration;
sub billing_portal_configuration_create;
sub billing_portal_configuration_list;
sub billing_portal_configuration_retrieve;
sub billing_portal_configuration_update;
sub billing_portal_configurations;
sub billing_portal_session;
sub billing_portal_session_create;
sub billing_portal_sessions;
sub billing_thresholds;
sub business_profile;
sub capability;
sub capability_list;
sub capability_retrieve;
sub capability_update;
sub capabilitys;
sub card;
sub card_create;
sub card_delete;
sub card_holder;
sub card_list;
sub card_retrieve;
sub card_token_create;
sub card_update;
sub cards;
sub cash_balance;
sub cash_balance_retrieve;
sub cash_balance_update;
sub cash_balances;
sub cash_transction;
sub charge;
sub charge_capture;
sub charge_create;
sub charge_list;
sub charge_retrieve;
sub charge_search;
sub charge_update;
sub charges;
sub checkout_session;
sub checkout_session_create;
sub checkout_session_expire;
sub checkout_session_items;
sub checkout_session_list;
sub checkout_session_retrieve;
sub checkout_sessions;
sub code_verification;
sub company;
sub connection_token;
sub country_spec;
sub country_spec_list;
sub country_spec_retrieve;
sub country_specs;
sub coupon;
sub coupon_create;
sub coupon_delete;
sub coupon_list;
sub coupon_retrieve;
sub coupon_update;
sub coupons;
sub credit_note;
sub credit_note_create;
sub credit_note_line_item;
sub credit_note_line_item_list;
sub credit_note_line_items;
sub credit_note_lines;
sub credit_note_lines_preview;
sub credit_note_list;
sub credit_note_preview;
sub credit_note_retrieve;
sub credit_note_update;
sub credit_note_void;
sub credit_notes;
sub customer;
sub customer_balance_transaction;
sub customer_balance_transaction_create;
sub customer_balance_transaction_list;
sub customer_balance_transaction_retrieve;
sub customer_balance_transaction_update;
sub customer_balance_transactions;
sub customer_bank_account;
sub customer_bank_account_create;
sub customer_bank_account_delete;
sub customer_bank_account_list;
sub customer_bank_account_retrieve;
sub customer_bank_account_update;
sub customer_bank_account_verify;
sub customer_bank_accounts;
sub customer_cash_balance_transaction;
sub customer_cash_balance_transaction_fund_cash_balance;
sub customer_cash_balance_transaction_list;
sub customer_cash_balance_transaction_retrieve;
sub customer_cash_balance_transactions;
sub customer_create;
sub customer_delete;
sub customer_delete_discount;
sub customer_list;
sub customer_payment_method;
sub customer_payment_methods;
sub customer_retrieve;
sub customer_search;
sub customer_tax_id;
sub customer_update;
sub customers;
sub cvc_update_token_create;
sub data;
sub discount;
sub discount_delete;
sub discounts;
sub dispute;
sub dispute_close;
sub dispute_evidence;
sub dispute_list;
sub dispute_retrieve;
sub dispute_update;
sub disputes;
sub document;
sub event;
sub event_list;
sub event_retrieve;
sub events;
sub evidence;
sub evidence_details;
sub fee_refund;
sub fee_refund_create;
sub fee_refund_list;
sub fee_refund_retrieve;
sub fee_refund_update;
sub fee_refunds;
sub file;
sub file_create;
sub file_link;
sub file_link_create;
sub file_link_list;
sub file_link_retrieve;
sub file_link_update;
sub file_links;
sub file_list;
sub file_retrieve;
sub files;
sub financial_connections_account;
sub financial_connections_account_disconnect;
sub financial_connections_account_list;
sub financial_connections_account_owner;
sub financial_connections_account_owner_list;
sub financial_connections_account_owners;
sub financial_connections_account_ownership;
sub financial_connections_account_refresh;
sub financial_connections_account_retrieve;
sub financial_connections_accounts;
sub financial_connections_session;
sub financial_connections_session_create;
sub financial_connections_session_retrieve;
sub financial_connections_sessions;
sub fraud;
sub funding_instructions;
sub funding_instructions_create;
sub funding_instructions_fund;
sub funding_instructions_list;
sub funding_instructionss;
sub identity_verification_report;
sub identity_verification_report_list;
sub identity_verification_report_retrieve;
sub identity_verification_reports;
sub identity_verification_session;
sub identity_verification_session_cancel;
sub identity_verification_session_create;
sub identity_verification_session_list;
sub identity_verification_session_redact;
sub identity_verification_session_retrieve;
sub identity_verification_session_update;
sub identity_verification_sessions;
sub invoice;
sub invoice_create;
sub invoice_delete;
sub invoice_finalise;
sub invoice_finalize;
sub invoice_item;
sub invoice_item_create;
sub invoice_item_delete;
sub invoice_item_list;
sub invoice_item_retrieve;
sub invoice_item_update;
sub invoice_items;
sub invoice_line_item;
sub invoice_lines;
sub invoice_lines_upcoming;
sub invoice_list;
sub invoice_pay;
sub invoice_retrieve;
sub invoice_search;
sub invoice_send;
sub invoice_settings;
sub invoice_uncollectible;
sub invoice_upcoming;
sub invoice_update;
sub invoice_void;
sub invoice_write_off;
sub invoiceitem;
sub invoiceitem_create;
sub invoiceitem_delete;
sub invoiceitem_list;
sub invoiceitem_retrieve;
sub invoiceitem_update;
sub invoiceitems;
sub invoices;
sub ip_address_location;
sub issuing_authorization;
sub issuing_authorization_approve;
sub issuing_authorization_decline;
sub issuing_authorization_list;
sub issuing_authorization_retrieve;
sub issuing_authorization_update;
sub issuing_authorizations;
sub issuing_card;
sub issuing_card_create;
sub issuing_card_deliver;
sub issuing_card_fail;
sub issuing_card_list;
sub issuing_card_retrieve;
sub issuing_card_return;
sub issuing_card_ship;
sub issuing_card_update;
sub issuing_cardholder;
sub issuing_cardholder_create;
sub issuing_cardholder_list;
sub issuing_cardholder_retrieve;
sub issuing_cardholder_update;
sub issuing_cardholders;
sub issuing_cards;
sub issuing_dispute;
sub issuing_dispute_create;
sub issuing_dispute_list;
sub issuing_dispute_retrieve;
sub issuing_dispute_submit;
sub issuing_dispute_update;
sub issuing_disputes;
sub issuing_transaction;
sub issuing_transaction_list;
sub issuing_transaction_retrieve;
sub issuing_transaction_update;
sub issuing_transactions;
sub item;
sub line_item;
sub line_item_lines;
sub line_items;
sub location;
sub login_link;
sub login_link_create;
sub login_links;
sub mandate;
sub mandate_retrieve;
sub mandates;
sub merchant_data;
sub next_action;
sub order;
sub order_item;
sub outcome;
sub owner;
sub package_dimensions;
sub payment_intent;
sub payment_intent_apply_customer_balance;
sub payment_intent_cancel;
sub payment_intent_capture;
sub payment_intent_confirm;
sub payment_intent_create;
sub payment_intent_increment;
sub payment_intent_increment_authorization;
sub payment_intent_list;
sub payment_intent_reconcile;
sub payment_intent_retrieve;
sub payment_intent_search;
sub payment_intent_update;
sub payment_intent_verify;
sub payment_intent_verify_microdeposits;
sub payment_intents;
sub payment_link;
sub payment_link_create;
sub payment_link_items;
sub payment_link_line_items;
sub payment_link_list;
sub payment_link_retrieve;
sub payment_link_update;
sub payment_links;
sub payment_method;
sub payment_method_attach;
sub payment_method_create;
sub payment_method_detach;
sub payment_method_details;
sub payment_method_list;
sub payment_method_list_customer_payment_methods;
sub payment_method_retrieve;
sub payment_method_retrieve_customer_payment_method;
sub payment_method_update;
sub payment_methods;
sub payout;
sub payout_cancel;
sub payout_create;
sub payout_list;
sub payout_retrieve;
sub payout_reverse;
sub payout_update;
sub payouts;
sub period;
sub person;
sub person_create;
sub person_delete;
sub person_list;
sub person_retrieve;
sub person_token_create;
sub person_update;
sub persons;
sub pii_token_create;
sub plan;
sub plan_by_product;
sub plan_create;
sub plan_delete;
sub plan_list;
sub plan_retrieve;
sub plan_update;
sub plans;
sub portal_configuration;
sub portal_configuration_create;
sub portal_configuration_list;
sub portal_configuration_retrieve;
sub portal_configuration_update;
sub portal_configurations;
sub portal_session;
sub portal_session_create;
sub portal_sessions;
sub price;
sub price_create;
sub price_list;
sub price_retrieve;
sub price_search;
sub price_update;
sub prices;
sub product;
sub product_by_name;
sub product_create;
sub product_delete;
sub product_list;
sub product_retrieve;
sub product_search;
sub product_update;
sub products;
sub promotion_code;
sub promotion_code_create;
sub promotion_code_list;
sub promotion_code_retrieve;
sub promotion_code_update;
sub promotion_codes;
sub quote;
sub quote_accept;
sub quote_cancel;
sub quote_create;
sub quote_download;
sub quote_finalize;
sub quote_line_items;
sub quote_lines;
sub quote_list;
sub quote_retrieve;
sub quote_update;
sub quote_upfront_line_items;
sub quote_upfront_lines;
sub quotes;
sub radar_early_fraud_warning;
sub radar_early_fraud_warning_list;
sub radar_early_fraud_warning_retrieve;
sub radar_early_fraud_warnings;
sub radar_value_list;
sub radar_value_list_create;
sub radar_value_list_delete;
sub radar_value_list_item;
sub radar_value_list_item_create;
sub radar_value_list_item_delete;
sub radar_value_list_item_list;
sub radar_value_list_item_retrieve;
sub radar_value_list_items;
sub radar_value_list_list;
sub radar_value_list_retrieve;
sub radar_value_list_update;
sub radar_value_lists;
sub reader;
sub receiver;
sub redirect;
sub refund;
sub refund_cancel;
sub refund_create;
sub refund_list;
sub refund_retrieve;
sub refund_update;
sub refunds;
sub relationship;
sub reporting_report_run;
sub reporting_report_run_create;
sub reporting_report_run_list;
sub reporting_report_run_retrieve;
sub reporting_report_runs;
sub reporting_report_type;
sub reporting_report_type_list;
sub reporting_report_type_retrieve;
sub reporting_report_types;
sub request;
sub requirements;
sub return;
sub review;
sub review_approve;
sub review_list;
sub review_retrieve;
sub reviews;
sub schedule;
sub schedule_cancel;
sub schedule_create;
sub schedule_list;
sub schedule_query;
sub schedule_release;
sub schedule_retrieve;
sub schedule_update;
sub scheduled_query_run;
sub scheduled_query_run_list;
sub scheduled_query_run_retrieve;
sub scheduled_query_runs;
sub schedules;
sub session;
sub session_create;
sub session_expire;
sub session_list;
sub session_retrieve;
sub session_retrieve_items;
sub sessions;
sub settings;
sub setup_attempt;
sub setup_attempt_list;
sub setup_attempts;
sub setup_intent;
sub setup_intent_cancel;
sub setup_intent_confirm;
sub setup_intent_create;
sub setup_intent_list;
sub setup_intent_retrieve;
sub setup_intent_update;
sub setup_intent_verify;
sub setup_intent_verify_microdeposits;
sub setup_intents;
sub shipping;
sub shipping_rate;
sub shipping_rate_create;
sub shipping_rate_list;
sub shipping_rate_retrieve;
sub shipping_rate_update;
sub shipping_rates;
sub sku;
sub source;
sub source_attach;
sub source_create;
sub source_detach;
sub source_order;
sub source_retrieve;
sub source_update;
sub sources;
sub status_transitions;
sub subscription;
sub subscription_cancel;
sub subscription_create;
sub subscription_delete;
sub subscription_delete_discount;
sub subscription_item;
sub subscription_item_create;
sub subscription_item_delete;
sub subscription_item_list;
sub subscription_item_retrieve;
sub subscription_item_update;
sub subscription_items;
sub subscription_list;
sub subscription_retrieve;
sub subscription_schedule;
sub subscription_schedule_cancel;
sub subscription_schedule_create;
sub subscription_schedule_list;
sub subscription_schedule_release;
sub subscription_schedule_retrieve;
sub subscription_schedule_update;
sub subscription_schedules;
sub subscription_search;
sub subscription_update;
sub subscriptions;
sub tax_code;
sub tax_code_list;
sub tax_code_retrieve;
sub tax_codes;
sub tax_id;
sub tax_id_create;
sub tax_id_delete;
sub tax_id_list;
sub tax_id_retrieve;
sub tax_ids;
sub tax_rate;
sub tax_rate_create;
sub tax_rate_list;
sub tax_rate_retrieve;
sub tax_rate_update;
sub tax_rates;
sub terminal_configuration;
sub terminal_configuration_create;
sub terminal_configuration_delete;
sub terminal_configuration_list;
sub terminal_configuration_retrieve;
sub terminal_configuration_update;
sub terminal_configurations;
sub terminal_connection_token;
sub terminal_connection_token_create;
sub terminal_connection_tokens;
sub terminal_location;
sub terminal_location_create;
sub terminal_location_delete;
sub terminal_location_list;
sub terminal_location_retrieve;
sub terminal_location_update;
sub terminal_locations;
sub terminal_reader;
sub terminal_reader_cancel_action;
sub terminal_reader_create;
sub terminal_reader_delete;
sub terminal_reader_list;
sub terminal_reader_present_payment_method;
sub terminal_reader_process_payment_intent;
sub terminal_reader_process_setup_intent;
sub terminal_reader_retrieve;
sub terminal_reader_set_reader_display;
sub terminal_reader_update;
sub terminal_readers;
sub test_helpers_test_clock;
sub test_helpers_test_clock_advance;
sub test_helpers_test_clock_create;
sub test_helpers_test_clock_delete;
sub test_helpers_test_clock_list;
sub test_helpers_test_clock_retrieve;
sub test_helpers_test_clocks;
sub token;
sub token_create;
sub token_create_account;
sub token_create_bank_account;
sub token_create_card;
sub token_create_cvc_update;
sub token_create_person;
sub token_create_pii;
sub token_retrieve;
sub tokens;
sub topup;
sub topup_cancel;
sub topup_create;
sub topup_list;
sub topup_retrieve;
sub topup_update;
sub topups;
sub tos_acceptance;
sub transfer;
sub transfer_create;
sub transfer_data;
sub transfer_list;
sub transfer_retrieve;
sub transfer_reversal;
sub transfer_reversal_create;
sub transfer_reversal_list;
sub transfer_reversal_retrieve;
sub transfer_reversal_update;
sub transfer_reversals;
sub transfer_update;
sub transfers;
sub transform_usage;
sub treasury_credit_reversal;
sub treasury_credit_reversal_create;
sub treasury_credit_reversal_list;
sub treasury_credit_reversal_retrieve;
sub treasury_credit_reversals;
sub treasury_debit_reversal;
sub treasury_debit_reversal_create;
sub treasury_debit_reversal_list;
sub treasury_debit_reversal_retrieve;
sub treasury_debit_reversals;
sub treasury_financial_account;
sub treasury_financial_account_create;
sub treasury_financial_account_features;
sub treasury_financial_account_features_retrieve;
sub treasury_financial_account_features_update;
sub treasury_financial_account_featuress;
sub treasury_financial_account_list;
sub treasury_financial_account_retrieve;
sub treasury_financial_account_update;
sub treasury_financial_accounts;
sub treasury_inbound_transfer;
sub treasury_inbound_transfer_cancel;
sub treasury_inbound_transfer_create;
sub treasury_inbound_transfer_fail;
sub treasury_inbound_transfer_list;
sub treasury_inbound_transfer_retrieve;
sub treasury_inbound_transfer_return;
sub treasury_inbound_transfer_succeed;
sub treasury_inbound_transfers;
sub treasury_outbound_payment;
sub treasury_outbound_payment_cancel;
sub treasury_outbound_payment_create;
sub treasury_outbound_payment_fail;
sub treasury_outbound_payment_list;
sub treasury_outbound_payment_post;
sub treasury_outbound_payment_retrieve;
sub treasury_outbound_payment_return;
sub treasury_outbound_payments;
sub treasury_outbound_transfer;
sub treasury_outbound_transfer_cancel;
sub treasury_outbound_transfer_create;
sub treasury_outbound_transfer_fail;
sub treasury_outbound_transfer_list;
sub treasury_outbound_transfer_post;
sub treasury_outbound_transfer_retrieve;
sub treasury_outbound_transfer_return;
sub treasury_outbound_transfers;
sub treasury_received_credit;
sub treasury_received_credit_list;
sub treasury_received_credit_received_credit;
sub treasury_received_credit_retrieve;
sub treasury_received_credits;
sub treasury_received_debit;
sub treasury_received_debit_list;
sub treasury_received_debit_received_debit;
sub treasury_received_debit_retrieve;
sub treasury_received_debits;
sub treasury_transaction;
sub treasury_transaction_entry;
sub treasury_transaction_entry_list;
sub treasury_transaction_entry_retrieve;
sub treasury_transaction_entrys;
sub treasury_transaction_list;
sub treasury_transaction_retrieve;
sub treasury_transactions;
sub usage_record;
sub usage_record_create;
sub usage_record_list;
sub usage_record_summary;
sub usage_records;
sub value_list;
sub value_list_item;
sub verification;
sub verification_data;
sub verification_fields;
sub webhook;
sub webhook_endpoint;
sub webhook_endpoint_create;
sub webhook_endpoint_delete;
sub webhook_endpoint_list;
sub webhook_endpoint_retrieve;
sub webhook_endpoint_update;
sub webhook_endpoints;

sub init
{
    my $self = shift( @_ );
    # $self->{token}  = '' unless( length( $self->{token} ) );
    $self->{amount} = '' unless( length( $self->{amount} ) );
    $self->{currency} ||= 'jpy';
    $self->{description} = '' unless( length( $self->{description} ) );
    $self->{card} = '' unless( length( $self->{card} ) );
    $self->{version} = '' unless( length( $self->{version} ) );
    $self->{key} = '' unless( length( $self->{key} ) );
    $self->{cookie_file} = '' unless( length( $self->{cookie_file} ) );
    $self->{browser} = $BROWSER unless( length( $self->{browser} ) );
    $self->{encode_with_json} = 0 unless( length( $self->{encode_with_json} ) );
    $self->{api_uri} = URI->new( API_BASE ) unless( length( $self->{api_uri} ) );
    $self->{file_api_uri} = URI->new( FILES_BASE ) unless( length( $self->{file_api_uri} ) );
    # Ask Module::Generic to check if corresponding method exists for each parameter submitted, 
    # and if so, use it to set the value of the key in hash parameters
    $self->{_init_strict_use_sub} = 1;
    $self->{temp_dir} = sys_tmpdir() unless( length( $self->{temp_dir} ) );
    # Blank on purpose, which means it was not set. If it has a value like 0 or 1, the user has set it and it takes precedence.
    $self->{livemode} = '';
    $self->{ignore_unknown_parameters} = '' unless( length( $self->{ignore_unknown_parameters} ) );
    $self->{expand} = '' unless( length( $self->{expand} ) );
    # Json configuration file
    $self->{conf_file} = '';
    $self->{conf_data} = {};
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    if( $self->{conf_file} )
    {
        my $json = $self->{conf_data};
        $self->{livemode} = $json->{livemode} if( CORE::length( $json->{livemode} ) && !CORE::length( $self->{livemode} ) );
        if( !$self->{key} )
        {
            $self->{key} = $self->{livemode} ? $json->{live_secret_key} : $json->{test_secret_key};
        }
        for( qw( browser cookie_file temp_dir version ) )
        {
            $self->{ $_ } = $json->{ $_ } if( !$self->{ $_ } && length( $json->{ $_ } ) );
        }
    }
    $self->{stripe_error} = '';
    $self->{http_response} = '';
    $self->{http_request} = '';
    CORE::return( $self->error( "No Stripe API private key was provided!" ) ) if( !$self->{key} );
    CORE::return( $self->error( "No Stripe api version was specified. I was expecting something like ''." ) ) if( !$self->{version} );
    $self->key( $self->{key} );
    $self->livemode( $self->{key} =~ /_live/ ? 1 : 0 );
    CORE::return( $self );
}

# NOTE: core method
sub api_uri
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $url = shift( @_ );
        try
        {
            $self->{api_uri} = URI->new( $url );
        }
        catch( $e )
        {
            CORE::return( $self->error( "Bad URI ($url) provided for base Stripe api: $e" ) );
        }
    }
    CORE::return( $self->{api_uri}->clone ) if( Scalar::Util::blessed( $self->{api_uri} ) && $self->{api_uri}->isa( 'URI' ) );
    CORE::return( $self->{api_uri} );
}

# NOTE: core method
sub auth { CORE::return( shift->_set_get_scalar( 'auth', @_ ) ); }

# NOTE: core method
sub browser { CORE::return( shift->_set_get_scalar( 'browser', @_ ) ); }

# NOTE: core method
sub code2error
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || CORE::return( $self->error( "No code was provided to get the related error" ) );
    CORE::return( $self->error( "No code found for $code" ) ) if( !exists( $ERROR_CODE_TO_STRING->{ $code } ) );
    CORE::return( $ERROR_CODE_TO_STRING->{ $code } );
}

# sub connect { CORE::return( shift->_instantiate( 'connect', 'Net::API::Stripe::Connect' ) ) }
# NOTE: core method
sub conf_file
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $file = shift( @_ );
        my $f = Module::Generic::File::file( $file );
        if( !$f->exists )
        {
            CORE::return( $self->error( "Configuration file $file does not exist." ) );
        }
        elsif( $f->is_empty )
        {
            CORE::return( $self->error( "Configuration file $file is empty." ) );
        }
        my $data = $f->load_utf8 || 
            CORE::return( $self->error( "Unable to open configuration file $file: ", $f->error ) );
        try
        {
            my $json = JSON->new->relaxed->decode( $data );
            $self->{conf_data} = $json;
            $self->{conf_file} = $file;
        }
        catch( $e )
        {
            CORE::return( $self->error( "An error occured while json decoding configuration file $file: $e" ) );
        }
    }
    CORE::return( $self->{conf_data} );
}

# NOTE: core method
sub cookie_file { CORE::return( shift->_set_get_file( 'cookie_file', @_ ) ); }

# NOTE: core method
sub currency
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->_set_get( 'currency', lc( shift( @_ ) ) );
    }
    CORE::return( $self->{ 'currency' } );
}

# NOTE: core method
sub delete 
{
    my $self = shift( @_ );
    my $path = shift( @_ ) || CORE::return( $self->error( "No api endpoint (path) was provided." ) );
    my $args = shift( @_ );
    CORE::return( $self->error( "http query parameters provided were not a hash reference." ) ) if( $args && ref( $args ) ne 'HASH' );
    my $api  = $self->api_uri->clone;
    if( $self->_is_object( $path ) && $path->can( 'path' ) )
    {
        $api->path( undef() );
        $path = $path->path;
    }
    else
    {
        substr( $path, 0, 0 ) = '/' unless( substr( $path, 0, 1 ) eq '/' );
    }
    $path .= '?' . $self->_encode_params( $args ) if( $args && %$args );
    my $req = HTTP::Promise::Request->new( 'DELETE', $api . $path );
    CORE::return( $self->_make_request( $req ) );
}

# NOTE: core method
sub encode_with_json { CORE::return( shift->_set_get( 'encode_with_json', @_ ) ); }

# NOTE: core method
# Can be 'all' or an integer representing a depth
sub expand { CORE::return( shift->_set_get_scalar( 'expand', @_ ) ); }

# NOTE: core method
sub fields
{
    my $self = shift( @_ );
    my $type = shift( @_ ) || CORE::return( $self->error( "No object type was provided to get its list of methods." ) );
    my $class;
    if( $class = $self->_is_object( $type ) )
    {
    }
    else
    {
        $class = $self->_object_type_to_class( $type );
    }
    no strict 'refs';
    if( !$self->_is_class_loaded( $class ) )
    {
        $self->_load_class( $class );
    }
    my @methods = grep{ defined &{"${class}::$_"} } keys( %{"${class}::"} );
    CORE::return( \@methods );
}

# NOTE: core method
sub file_api_uri
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $url = shift( @_ );
        try
        {
            $self->{file_api_uri} = URI->new( $url );
        }
        catch( $e )
        {
            CORE::return( $self->error( "Bad URI ($url) provided for base files Stripe api: $e" ) );
        }
    }
    CORE::return( $self->{file_api_uri}->clone ) if( Scalar::Util::blessed( $self->{file_api_uri} ) && $self->{file_api_uri}->isa( 'URI' ) );
    CORE::return( $self->{file_api_uri} );
}

# NOTE: core method
sub generate_uuid
{
    CORE::return( Data::UUID->new->create_str );
}

# NOTE: core method
sub get
{
    my $self = shift( @_ );
    my $path = shift( @_ ) || CORE::return( $self->error( "No api endpoint (path) was provided." ) );
    my $args = shift( @_ );
    CORE::return( $self->error( "http query parameters provided were not a hash reference." ) ) if( $args && ref( $args ) ne 'HASH' );
    my $expand = $self->expand;
    if( ( !exists( $args->{expand} ) && 
          (
              $expand eq 'all' || 
              ( $expand =~ /^\d+$/ && $expand > 2 )
          )
        )
        ||
        (
          exists( $args->{expand} ) && 
          (
              $args->{expand} eq 'all' ||
              ( $args->{expand} =~ /^\d+$/ && $args->{expand} > 2 )
          )
        ) )
    {
        # Because anything more will likely trigger URI too long
        $args->{expand} = 2;
    }
    my $api  = CORE::exists( $args->{_file_api} ) ? $self->file_api_uri->clone : $self->api_uri->clone;
    if( $self->_is_object( $path ) && $path->can( 'path' ) )
    {
        $api->path( undef() );
        $path = $path->path;
    }
    else
    {
        substr( $path, 0, 0 ) = '/' unless( substr( $path, 0, 1 ) eq '/' );
    }
    $path .= '?' . $self->_encode_params( $args ) if( $args && %$args );
    my $req = HTTP::Promise::Request->new( 'GET', $api . $path );
    CORE::return( $self->_make_request( $req ) );
}

# NOTE: core method
sub http_client
{
    my $self = shift( @_ );
    CORE::return( $self->{ua} ) if( $self->{ua} );
    my $cookie_file = $self->cookie_file;
    my $browser = $self->browser;
    # To be safe and ensure this works everywhere, we use the 'file' medium as shared data space
    my $ua = HTTP::Promise->new(
        # medium => 'file',
        timeout => 5,
        use_promise => 0,
        ( $self->debug > 3 ? ( debug => $self->debug ) : () ),
    );
    if( defined( $browser ) &&
        length( $browser ) )
    {
        $ua->agent( $browser );
    }
    if( defined( $cookie_file ) &&
        length( $cookie_file ) )
    {
        my $jar = Cookie::Jar->new( file => $cookie_file );
        $ua->cookie_jar( $jar );
    }
    $self->{ua} = $ua;
    CORE::return( $ua );
}

# NOTE: core method
sub http_request { CORE::return( shift->_set_get_object( 'http_request', 'HTTP::Promise::Request', @_ ) ); }

# NOTE: core method
sub http_response { CORE::return( shift->_set_get_object( 'http_response', 'HTTP::Promise::Response', @_ ) ); }

# NOTE: core method
sub ignore_unknown_parameters { CORE::return( shift->_set_get_boolean( 'ignore_unknown_parameters', @_ ) ); }

# NOTE: core method
sub json { CORE::return( JSON->new->allow_nonref->allow_blessed->convert_blessed->relaxed ); }

# NOTE: core method
sub key
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $key = $self->{key} = shift( @_ );
        my $auth = 'Basic ' . MIME::Base64::encode_base64( $key . ':' );
        $self->auth( $auth );
    }
    CORE::return( $self->{key} );
}

# NOTE: core method
sub livemode { CORE::return( shift->_set_get_boolean( 'livemode', @_ ) ); }

# NOTE: core method
sub post
{
    my $self = shift( @_ );
    my $path = shift( @_ ) || CORE::return( $self->error( "No api endpoint (path) was provided." ) );
    my $args = shift( @_ );
    CORE::return( $self->error( "http query parameters provided were not a hash reference." ) ) if( $args && ref( $args ) ne 'HASH' );
    my $api  = $self->api_uri->clone;
    if( $self->_is_object( $path ) && $path->can( 'path' ) )
    {
        $api->path( undef() );
        $path = $path->path;
    }
    else
    {
        substr( $path, 0, 0 ) = '/' unless( substr( $path, 0, 1 ) eq '/' );
    }
#   my $ref = $self->_encode_params( $args );
#   $self->message( 3, $self->dump( $ref ) ); exit;
    my $h = [];
    if( exists( $args->{idempotency} ) )
    {
        $args->{idempotency} = $self->generate_uuid if( !length( $args->{idempotency} ) );
        push( @$h, 'Idempotency-Key', CORE::delete( $args->{idempotency} ) );
    }
    my $req = HTTP::Promise::Request->new(
        'POST', $api . $path, 
        $h,
        ( $args ? $self->_encode_params( $args ) : undef() )
    );
    CORE::return( $self->_make_request( $req ) );
}

# NOTE: core method
# Using rfc2388 rules
# https://tools.ietf.org/html/rfc2388
sub post_multipart
{
    my $self = shift( @_ );
    my $path = shift( @_ ) || CORE::return( $self->error( "No api endpoint (path) was provided." ) );
    my $args = shift( @_ );
    CORE::return( $self->error( "http query parameters provided were not a hash reference." ) ) if( $args && ref( $args ) ne 'HASH' );
    my $api  = $self->api_uri->clone;
    if( $self->_is_object( $path ) && $path->can( 'path' ) )
    {
        $api->path( undef() );
        $path = $path->path;
    }
    else
    {
        substr( $path, 0, 0 ) = '/' unless( substr( $path, 0, 1 ) eq '/' );
    }
    my $h = HTTP::Promise::Headers->new(
        Content_Type => 'multipart/form-data',
    );
    if( exists( $args->{idempotency} ) )
    {
        $args->{idempotency} = $self->generate_uuid if( !length( $args->{idempotency} ) );
        $h->header( 'Idempotency-Key' => CORE::delete( $args->{idempotency} ) );
    }
    my $req = HTTP::Promise::Request->new( POST => $api . $path, $h );
    my $data = $self->_encode_params_multipart( $args, { encoding => 'quoted-printable' } );
    foreach my $f ( keys( %$data ) )
    {
        foreach my $ref ( @{$data->{ $f }} )
        {
            if( $ref->{filename} )
            {
                my $fname = $ref->{filename};
                $req->add_part( HTTP::Promise::Message->new(
                    HTTP::Promise::Headers->new(
                        Content_Disposition => "form-data; name=\"${f}\"; filename=\"${fname}\"",
                        Content_Type => ( $ref->{type} ? $ref->{type} : 'application/octet-stream' ),
                        ( $ref->{encoding} ? ( Content_Transfer_Encoding => $ref->{encoding} ) : undef() ),
                        Content_Length => CORE::length( $ref->{value} ),
                    ),
                    $ref->{value}
                ));
            }
            else
            {
                $ref->{type} ||= 'text/plain';
                $req->add_part( HTTP::Promise::Message->new(
                    HTTP::Promise::Headers->new(
                        Content_Disposition => "form-data; name=\"${f}\"",
                        Content_Type => ( $ref->{type} eq 'text/plain' ? 'text/plain;charset="utf-8"' : $ref->{type} ),
                        Content_Length => CORE::length( $ref->{value} ),
                        Content_Transfer_Encoding => ( $ref->{encoding} ? $ref->{encoding} : '8bit' ),
                    ),
                    $ref->{value}
                ));
            }
        }
    }
    CORE::return( $self->_make_request( $req ) );
}

# NOTE: core method
sub version { CORE::return( shift->_set_get_scalar( 'version', @_ ) ); }

# NOTE: core method
sub webhook_validate_signature
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = shift( @_ ) if( @_ && ref( $_[0] ) eq 'HASH' );
    CORE::return( $self->error( "No webhook secret was provided." ) ) if( !$opts->{secret} );
    CORE::return( $self->error( "No Stripe signature was provided." ) ) if( !$opts->{signature} );
    CORE::return( $self->error( "No payload was provided." ) ) if( !CORE::length( $opts->{payload} ) );
    # 5 minutes
    $opts->{time_tolerance} ||= ( 5 * 60 );
    my $sig = $opts->{signature};
    my $max_time_spread = $opts->{time_tolerance};
    my $signing_secret = $opts->{secret};
    my $payload = $opts->{payload};
    $payload = Encode::decode_utf8( $payload ) if( !Encode::is_utf8( $payload ) );
    
    # Example:
    # Stripe-Signature: t=1492774577,
    #     v1=5257a869e7ecebeda32affa62cdca3fa51cad7e77a0e56ff536d0ce8e108d8bd,
    #     v0=6ffbb59b2300aae63f272406069a9788598b792a944a07aba816edb039989a39
    CORE::return( $self->error({ code => 400, message => "Event data received from Stripe is empty" }) ) if( !CORE::length( $sig ) );
    my @parts = split( /\,[[:blank:]]*/, $sig );
    my $q = {};
    for( @parts )
    {
        my( $n, $v ) = split( /[[:blank:]]*\=[[:blank:]]*/, $_, 2 );
        $q->{ $n } = $v;
    }
    CORE::return( $self->error({ code => 400, message => "No timestamp found in Stripe event data" }) ) if( !CORE::exists( $q->{t} ) );
    CORE::return( $self->error({ code => 400, message => "Timestamp is empty in Stripe event data received." }) ) if( !CORE::length( $q->{t} ) );
    CORE::return( $self->error({ code => 400, message => "No signature found in Stripe event data" }) ) if( !CORE::exists( $q->{v1} ) );
    CORE::return( $self->error({ code => 400, message => "Signature is empty in Stripe event data received." }) ) if( !CORE::length( $q->{v1} ) );
    # Must be a unix timestamp
    CORE::return( $self->error({ code => 400, message => "Invalid timestamp received in Stripe event data" }) ) if( $q->{t} !~ /^\d+$/ );
    # Must be a hash hmac with sha256, e.g. 5257a869e7ecebeda32affa62cdca3fa51cad7e77a0e56ff536d0ce8e108d8bd
    CORE::return( $self->error({ code => 400, message => "Invalid signature received in Stripe event data" }) ) if( $q->{v1} !~ /^[a-z0-9]{64}$/ );
    my $dt;
    try
    {
        $dt = DateTime->from_epoch( epoch => $q->{t}, time_zone => 'local' );
    }
    catch( $e )
    {
        CORE::return( $self->error({ code => 400, message => "Invalid timestamp ($q->{t}): $e" }) );
    }
    
    # This needs to be in real utf8, ie NOT perl internal utf8
    my $signed_payload = Encode::encode_utf8( join( '.', $q->{t}, $payload ) );
    my $expect_sign = Digest::SHA::hmac_sha256_hex( $signed_payload, $signing_secret );
    CORE::return( $self->error({ code => 401, message => "Invalid signature." }) ) if( $expect_sign ne $q->{v1} );
    my $time_diff = time() - $q->{t};
    CORE::return( $self->error({ code => 400, message => "Bad timestamp ($q->{t}). It is set in the future: $dt" }) ) if( $time_diff < 0 );
    CORE::return( $self->error({ code => 406, message => "Timestamp is too old." }) ) if( $time_diff >= $max_time_spread );
    CORE::return( 1 );
}

# NOTE: core method
# https://stripe.com/docs/ips
sub webhook_validate_caller_ip
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = shift( @_ ) if( @_ && ref( $_[0] ) eq 'HASH' );
    CORE::return( $self->error({ code => 500, message => "No ip address was provided to check." }) ) if( !$opts->{ip} );
    my $err = [];
    my $ips = STRIPE_WEBHOOK_SOURCE_IP;
    my $ip = Net::IP->new( $opts->{ip} ) || do
    {
        warn( "Warning only: IP '", ( $opts->{ip} // '' ), "' is not valid: ", Net::IP->Error, "\n" );
        push( @$err, sprintf( "IP '%s' is not valid: %s", ( $opts->{ip} // '' ), Net::IP->Error ) );
        CORE::return( '' );
    };
    foreach my $stripe_ip ( @$ips )
    {
        my $stripe_ip_object = Net::IP->new( $stripe_ip );
        # We found an existing ip same as the one we are adding, so we skip
        # If we are given a block that has some overlapping elements, we go ahead and add it
        # because it would become complicated and risky to only take the ips that do not overalp in the given block
        if( !( $ip->overlaps( $stripe_ip_object ) == $Net::IP::IP_NO_OVERLAP ) )
        {
            CORE::return( $ip );
        }
    }
    if( $opts->{ignore_ip} )
    {
        CORE::return( $ip );
    }
    else
    {
        CORE::return( $self->error({ code => 403, message => "IP address $opts->{ip} is not a valid Stripe ip and is not authorised to access this resource." }) );
    }
}

# NOTE: All methods below are auto-generated.
sub _autoload_subs
{
    $AUTOLOAD_SUBS = 
    {
    # NOTE: account()
    account => <<'PERL',
sub account { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account', @_ ) ); }
PERL
    # NOTE: account_bank_account()
    account_bank_account => <<'PERL',
sub account_bank_account { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ ) ); }
PERL
    # NOTE: account_bank_account_create()
    account_bank_account_create => <<'PERL',
sub account_bank_account_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_bank_account' } },
    default_for_currency => { type => "boolean" },
    external_account => { type => "string", required => 1 },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'account_bank_account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to create its information." ) );
    my $hash = $self->post( "accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}
PERL
    # NOTE: account_bank_account_delete()
    account_bank_account_delete => <<'PERL',
sub account_bank_account_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_bank_account' } },
    };
    $args = $self->_contract( 'account_bank_account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to delete its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account_bank_account id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "accounts/${parent_id}/external_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}
PERL
    # NOTE: account_bank_account_list()
    account_bank_account_list => <<'PERL',
sub account_bank_account_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list account bank account information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_bank_account' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to list its information." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "accounts/${id}?object=bank_account", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}
PERL
    # NOTE: account_bank_account_retrieve()
    account_bank_account_retrieve => <<'PERL',
sub account_bank_account_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_bank_account' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'account_bank_account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to retrieve its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account_bank_account id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "accounts/${parent_id}/external_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}
PERL
    # NOTE: account_bank_account_update()
    account_bank_account_update => <<'PERL',
sub account_bank_account_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_bank_account' } },
    account_holder_name => { type => "string" },
    account_holder_type => { type => "string" },
    account_type => { type => "string" },
    default_for_currency => { type => "boolean" },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'account_bank_account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to update its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account_bank_account id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "accounts/${parent_id}/external_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}
PERL
    # NOTE: account_bank_accounts()
    account_bank_accounts => <<'PERL',
# <https://stripe.com/docs/api/external_accounts>
sub account_bank_accounts
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'account_bank_account', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: account_card()
    account_card => <<'PERL',
sub account_card { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }
PERL
    # NOTE: account_card_create()
    account_card_create => <<'PERL',
sub account_card_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_card' } },
    default_for_currency => { type => "boolean" },
    external_account => { type => "string", required => 1 },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'account_card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to create its information." ) );
    my $hash = $self->post( "accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Card', $hash ) );
}
PERL
    # NOTE: account_card_delete()
    account_card_delete => <<'PERL',
sub account_card_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_card' } },
    };
    $args = $self->_contract( 'account_card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to delete its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account_card id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "accounts/${parent_id}/external_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Card', $hash ) );
}
PERL
    # NOTE: account_card_list()
    account_card_list => <<'PERL',
sub account_card_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list account card information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_card' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to list its information." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "accounts/${id}?object=card", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Card', $hash ) );
}
PERL
    # NOTE: account_card_retrieve()
    account_card_retrieve => <<'PERL',
sub account_card_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_card' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'account_card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to retrieve its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account_card id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "accounts/${parent_id}/external_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Card', $hash ) );
}
PERL
    # NOTE: account_card_update()
    account_card_update => <<'PERL',
sub account_card_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_card' } },
    address_city => { type => "string" },
    address_country => { type => "string" },
    address_line1 => { type => "string" },
    address_line2 => { type => "string" },
    address_state => { type => "string" },
    address_zip => { type => "string" },
    default_for_currency => { type => "boolean" },
    exp_month => { type => "integer" },
    exp_year => { type => "integer" },
    metadata => { type => "hash" },
    name => { type => "string" },
    };
    $args = $self->_contract( 'account_card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to update its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account_card id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "accounts/${parent_id}/external_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Card', $hash ) );
}
PERL
    # NOTE: account_cards()
    account_cards => <<'PERL',
# <https://stripe.com/docs/api/external_accounts>
sub account_cards
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'account_card', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: account_create()
    account_create => <<'PERL',
sub account_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account' } },
    account_token => { type => "string" },
    business_profile => { type => "hash" },
    business_type => { type => "string" },
    capabilities => { type => "hash" },
    company => { type => "hash" },
    country => { type => "string" },
    default_currency => { type => "string" },
    documents => { type => "object" },
    email => { type => "string" },
    external_account => { type => "string" },
    individual => { type => "hash" },
    metadata => { type => "hash" },
    settings => { type => "hash" },
    tos_acceptance => { type => "hash" },
    type => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "accounts", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account', $hash ) );
}
PERL
    # NOTE: account_delete()
    account_delete => <<'PERL',
sub account_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account' } },
    };
    $args = $self->_contract( 'account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account', $hash ) );
}
PERL
    # NOTE: account_link()
    account_link => <<'PERL',
sub account_link { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::Link', @_ ) ); }
PERL
    # NOTE: account_link_create()
    account_link_create => <<'PERL',
sub account_link_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account_link' } },
    account => { type => "string", required => 1 },
    collect => { type => "string" },
    refresh_url => { type => "string" },
    return_url => { type => "string" },
    type => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'account_link', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "account_links", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account::Link', $hash ) );
}
PERL
    # NOTE: account_links()
    account_links => <<'PERL',
# <https://stripe.com/docs/api/account_links>
sub account_links
{
    my $self = shift( @_ );
    my $allowed = [qw( create )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'account_link', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: account_list()
    account_list => <<'PERL',
sub account_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list account information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::Account', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "accounts", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account', $hash ) );
}
PERL
    # NOTE: account_reject()
    account_reject => <<'PERL',
sub account_reject
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account' } },
    reason => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to reject its information." ) );
    my $hash = $self->post( "accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account', $hash ) );
}
PERL
    # NOTE: account_retrieve()
    account_retrieve => <<'PERL',
sub account_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account', $hash ) );
}
PERL
    # NOTE: account_token_create()
    account_token_create => <<'PERL',
sub account_token_create { CORE::return( shift->token_create( @_ ) ); }
PERL
    # NOTE: account_update()
    account_update => <<'PERL',
sub account_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'account' } },
    account_token => { type => "string" },
    business_profile => { type => "hash" },
    business_type => { type => "string" },
    capabilities => { type => "hash" },
    company => { type => "hash" },
    default_currency => { type => "string" },
    documents => { type => "object" },
    email => { type => "string" },
    external_account => { type => "string" },
    individual => { type => "hash" },
    metadata => { type => "hash" },
    settings => { type => "hash" },
    tos_acceptance => { type => "hash" },
    };
    $args = $self->_contract( 'account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account', $hash ) );
}
PERL
    # NOTE: accounts()
    accounts => <<'PERL',
# <https://stripe.com/docs/api/accounts>
sub accounts
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list reject retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'account', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: address()
    address => <<'PERL',
sub address { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Address', @_ ) ); }
PERL
    # NOTE: address_kana()
    address_kana => <<'PERL',
sub address_kana { CORE::return( shift->_response_to_object( 'Net::API::Stripe::AddressKana', @_ ) ); }
PERL
    # NOTE: address_kanji()
    address_kanji => <<'PERL',
sub address_kanji { CORE::return( shift->_response_to_object( 'Net::API::Stripe::AddressKanji', @_ ) ); }
PERL
    # NOTE: amount()
    amount => <<'PERL',
sub amount { CORE::return( shift->_set_get_number( 'amount', @_ ) ); }
PERL
    # NOTE: application_fee()
    application_fee => <<'PERL',
sub application_fee { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee', @_ ) ); }
PERL
    # NOTE: application_fee_list()
    application_fee_list => <<'PERL',
sub application_fee_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list application fee information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ApplicationFee', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'application_fee' }, data_prefix_is_ok => 1 },
    charge => { type => "string" },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "application_fees", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee', $hash ) );
}
PERL
    # NOTE: application_fee_refund()
    application_fee_refund => <<'PERL',
sub application_fee_refund { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee::Refund', @_ ) ); }
PERL
    # NOTE: application_fee_retrieve()
    application_fee_retrieve => <<'PERL',
sub application_fee_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'application_fee' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'application_fee', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No application_fee id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "application_fees/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee', $hash ) );
}
PERL
    # NOTE: application_fees()
    application_fees => <<'PERL',
# <https://stripe.com/docs/api/application_fees>
sub application_fees
{
    my $self = shift( @_ );
    my $allowed = [qw( list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'application_fee', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: apps_secret()
    apps_secret => <<'PERL',
sub apps_secret { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::AppsSecret', @_ ) ); }
PERL
    # NOTE: apps_secret_delete()
    apps_secret_delete => <<'PERL',
sub apps_secret_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'apps.secret' } },
    name => { type => "string", required => 1 },
    scope => { type => "hash", required => 1 },
    };
    $args = $self->_contract( 'apps.secret', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "apps/secrets", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::AppsSecret', $hash ) );
}
PERL
    # NOTE: apps_secret_find()
    apps_secret_find => <<'PERL',
sub apps_secret_find
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'apps.secret' }, data_prefix_is_ok => 1 },
    name => { type => "string", required => 1 },
    scope => { type => "hash", required => 1 },
    };
    $args = $self->_contract( 'apps.secret', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->get( "apps/secrets", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::AppsSecret', $hash ) );
}
PERL
    # NOTE: apps_secret_list()
    apps_secret_list => <<'PERL',
sub apps_secret_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list apps secret information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::AppsSecret', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'apps.secret' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    scope => { type => "hash", required => 1 },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::AppsSecret', $hash ) );
}
PERL
    # NOTE: apps_secret_set()
    apps_secret_set => <<'PERL',
sub apps_secret_set
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'apps.secret' } },
    expires_at => { type => "timestamp" },
    name => { type => "string", required => 1 },
    payload => { type => "string", required => 1 },
    scope => { type => "hash", required => 1 },
    };
    $args = $self->_contract( 'apps.secret', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::AppsSecret', $hash ) );
}
PERL
    # NOTE: apps_secrets()
    apps_secrets => <<'PERL',
# <https://stripe.com/docs/api/secret_management>
sub apps_secrets
{
    my $self = shift( @_ );
    my $allowed = [qw( delete find list set )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'apps_secret', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: authorization()
    authorization => <<'PERL',
sub authorization { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Authorization', @_ ) ); }
PERL
    # NOTE: balance()
    balance => <<'PERL',
sub balance { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Balance', @_ ) ); }
PERL
    # NOTE: balance_retrieve()
    balance_retrieve => <<'PERL',
# Retrieves the current account balance, based on the authentication that was used to make the request.
sub balance_retrieve
{
    my $self = shift( @_ );
    # No argument
    # my $hash = $self->_get( 'balance' ) || CORE::return;
    my $hash = $self->get( 'balance' );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Balance', $hash ) );
}
PERL
    # NOTE: balance_transaction()
    balance_transaction => <<'PERL',
sub balance_transaction { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Balance::Transaction', @_ ) ); }
PERL
    # NOTE: balance_transaction_list()
    balance_transaction_list => <<'PERL',
# https://stripe.com/docs/api/balance/balance_history?lang=curl
sub balance_transaction_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{balance_transaction}, data_prefix_is_ok => 1 },
    'available_on'      => qr/^\d+$/,
    'available_on.gt'   => qr/^\d+$/,
    'available_on.gte'  => qr/^\d+$/,
    'available_on.lt'   => qr/^\d+$/,
    'available_on.lte'  => qr/^\d+$/,
    'created'           => qr/^\d+$/,
    'created.gt'        => qr/^\d+$/,
    'created.gte'       => qr/^\d+$/,
    'created.lt'        => qr/^\d+$/,
    'created.lte'       => qr/^\d+$/,
    'currency'          => qr/^[a-zA-Z]{3}$/,
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    'ending_before'     => qr/^\w+$/,
    'limit'             => qr/^\d+$/,
    # "For automatic Stripe payouts only, only returns transactions that were payed out on the specified payout ID."
    'payout'            => qr/^\w+$/,
    'source'            => qr/^\w+$/,
    'starting_after'    => qr/^\w+$/,
    # "Only returns transactions of the given type"
    'type'              => qr/^(?:charge|refund|adjustment|application_fee|application_fee_refund|transfer|payment|payout|payout_failure|stripe_fee|network_cost)$/,
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->get( 'balance_transactions', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: balance_transaction_retrieve()
    balance_transaction_retrieve => <<'PERL',
sub balance_transaction_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve balance transaction information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Balance::Transaction', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{balance_transaction}, data_prefix_is_ok => 1 },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No balance transaction id was provided to retrieve its information." ) );
    my $hash = $self->get( "balance/history/${id}" ) || CORE::return( $self->pass_error );
    CORE::return( $self->error( "Cannot find property 'object' in response hash reference: ", sub{ $self->dumper( $hash ) } ) ) if( !CORE::exists( $hash->{object} ) );
    my $class = $self->_object_type_to_class( $hash->{object} ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( $class, $hash ) );
}
PERL
    # NOTE: balance_transactions()
    balance_transactions => <<'PERL',
sub balance_transactions
{
    my $self = shift( @_ );
    my $allowed = [qw( retrieve list )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'balance_transaction', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: balances()
    balances => <<'PERL',
# Stripe access points in their order on the api documentation
sub balances
{
    my $self = shift( @_ );
    my $allowed = [qw( retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'balance', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: bank_account()
    bank_account => <<'PERL',
sub bank_account { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ ) ); }
PERL
    # NOTE: bank_account_create()
    bank_account_create => <<'PERL',
sub bank_account_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a bank account" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{bank_account} },
    account => { re => qr/^\w+$/, required => 1 },
    default_for_currency => {},
    external_account => {},
    metadata => { type => "hash" },
    source => { type => "string" },
    };

    if( $self->_is_hash( $args->{external_account} ) )
    {
        $okParams->{external_account} =
        {
        type => 'hash',
        fields => [qw( object! country! currency! account_holder_name account_holder_type routing_number account_number! )],
        };
    }
    else
    {
        $okParams->{external_account} = { type => 'scalar', re => qr/^\w+$/ };
    }
    my $id = CORE::delete( $args->{account} );
    $args = $self->_contract( 'bank_account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "accounts/${id}/external_accounts", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}
PERL
    # NOTE: bank_account_delete()
    bank_account_delete => <<'PERL',
sub bank_account_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete a bank account information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ );
    my $okParams = 
    {
    expandable => { allowed => $EXPANDABLES->{bank_account} },
    id          => { re => qr/^\w+$/, required => 1 },
    account     => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No bank account id was provided to delete its information." ) );
    my $acct = CORE::delete( $args->{account} );
    my $hash = $self->delete( "accounts/${acct}/external_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}
PERL
    # NOTE: bank_account_list()
    bank_account_list => <<'PERL',
sub bank_account_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams = 
    {
    expandable      => { allowed => $EXPANDABLES->{bank_account} },
    account         => { re => qr/^\w+$/, required => 1 },
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    'ending_before' => qr/^\w+$/,
    'limit'         => qr/^\d+$/,
    'starting_after' => qr/^\w+$/,
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{account} );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "accounts/$id/external_accounts", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: bank_account_retrieve()
    bank_account_retrieve => <<'PERL',
sub bank_account_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve a bank account information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{bank_account} },
    id          => { re => qr/^\w+$/, required => 1 },
    account     => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No bank account id was provided to retrieve its information." ) );
    my $acct = CORE::delete( $args->{account} );
    my $hash = $self->get( "accounts/${acct}/external_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}
PERL
    # NOTE: bank_account_update()
    bank_account_update => <<'PERL',
sub bank_account_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a bank account" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{bank_account} },
    account => { re => qr/^\w+$/, required => 1 },
    account_holder_name => { type => "string" },
    account_holder_type => { re => qr/^(company|individual)$/, type => "string" },
    default_for_currency => {},
    id => { re => qr/^\w+$/, required => 1 },
    metadata => { type => "hash" },
    };

    $args = $self->_contract( 'bank_account', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No bank account id was provided to update coupon's details" ) );
    my $acct = CORE::delete( $args->{account} );
    my $hash = $self->post( "accounts/${acct}/external_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}
PERL
    # NOTE: bank_account_verify()
    bank_account_verify => <<'PERL',
sub bank_account_verify
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'bank_account' } },
    amounts => { type => "array" },
    };
    $args = $self->_contract( 'bank_account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No customer id (with parameter 'parent_id') was provided to verify its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No source id (with parameter 'id') was provided to verify its information." ) );
    my $hash = $self->post( "customers/${parent_id}/sources/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::BankAccount', $hash ) );
}
PERL
    # NOTE: bank_accounts()
    bank_accounts => <<'PERL',
# <https://stripe.com/docs/api/customer_bank_accounts>
sub bank_accounts
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve update verify )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'bank_account', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: bank_token_create()
    bank_token_create => <<'PERL',
sub bank_token_create { CORE::return( shift->token_create( @_ ) ); }
PERL
    # NOTE: billing_details()
    billing_details => <<'PERL',
sub billing_details { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Details', @_ ) ); }
PERL
    # NOTE: billing_portal_configuration()
    billing_portal_configuration => <<'PERL',
sub billing_portal_configuration { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::PortalConfiguration', @_ ) ); }
PERL
    # NOTE: billing_portal_configuration_create()
    billing_portal_configuration_create => <<'PERL',
sub billing_portal_configuration_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'billing_portal.configuration' } },
    business_profile => { type => "hash", required => 1 },
    default_return_url => { type => "string" },
    features => { type => "hash", required => 1 },
    login_page => { type => "hash" },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'billing_portal.configuration', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::PortalConfiguration', $hash ) );
}
PERL
    # NOTE: billing_portal_configuration_list()
    billing_portal_configuration_list => <<'PERL',
sub billing_portal_configuration_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list billing portal configuration information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::PortalConfiguration', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'billing_portal.configuration' }, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    ending_before => { type => "string" },
    is_default => { type => "boolean" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::PortalConfiguration', $hash ) );
}
PERL
    # NOTE: billing_portal_configuration_retrieve()
    billing_portal_configuration_retrieve => <<'PERL',
sub billing_portal_configuration_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'billing_portal.configuration' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'billing_portal.configuration', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No billing_portal.configuration id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "billing_portal/configurations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::PortalConfiguration', $hash ) );
}
PERL
    # NOTE: billing_portal_configuration_update()
    billing_portal_configuration_update => <<'PERL',
sub billing_portal_configuration_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'billing_portal.configuration' } },
    active => { type => "boolean" },
    business_profile => { type => "hash" },
    default_return_url => { type => "string" },
    features => { type => "hash" },
    login_page => { type => "hash" },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'billing_portal.configuration', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No billing_portal.configuration id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "billing_portal/configurations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::PortalConfiguration', $hash ) );
}
PERL
    # NOTE: billing_portal_configurations()
    billing_portal_configurations => <<'PERL',
# <https://stripe.com/docs/api/customer_portal>
sub billing_portal_configurations
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'billing_portal_configuration', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: billing_portal_session()
    billing_portal_session => <<'PERL',
sub billing_portal_session { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::PortalSession', @_ ) ); }
PERL
    # NOTE: billing_portal_session_create()
    billing_portal_session_create => <<'PERL',
sub billing_portal_session_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'billing_portal.session' } },
    configuration => { type => "string" },
    customer => { type => "string", required => 1 },
    locale => { type => "string" },
    on_behalf_of => { type => "string" },
    return_url => { type => "string" },
    };
    $args = $self->_contract( 'billing_portal.session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::PortalSession', $hash ) );
}
PERL
    # NOTE: billing_portal_sessions()
    billing_portal_sessions => <<'PERL',
# <https://stripe.com/docs/api/customer_portal>
sub billing_portal_sessions
{
    my $self = shift( @_ );
    my $allowed = [qw( create )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'billing_portal_session', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: billing_thresholds()
    billing_thresholds => <<'PERL',
sub billing_thresholds { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Thresholds', @_ ) ); }
PERL
    # NOTE: business_profile()
    business_profile => <<'PERL',
sub business_profile { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Business::Profile', @_ ) ); }
PERL
    # NOTE: capability()
    capability => <<'PERL',
# sub billing { CORE::return( shift->_instantiate( 'billing', 'Net::API::Stripe::Billing' ) ) }
sub capability { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::Capability', @_ ) ); }
PERL
    # NOTE: capability_list()
    capability_list => <<'PERL',
sub capability_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list capability information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::Account::Capability', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'capability' }, data_prefix_is_ok => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to list its information." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "accounts/${id}/capabilities", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account::Capability', $hash ) );
}
PERL
    # NOTE: capability_retrieve()
    capability_retrieve => <<'PERL',
sub capability_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'capability' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'capability', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to retrieve its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account.capability id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "accounts/${parent_id}/capabilities/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account::Capability', $hash ) );
}
PERL
    # NOTE: capability_update()
    capability_update => <<'PERL',
sub capability_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'capability' } },
    requested => { type => "boolean" },
    };
    $args = $self->_contract( 'capability', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to update its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account.capability id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "accounts/${parent_id}/capabilities/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account::Capability', $hash ) );
}
PERL
    # NOTE: capabilitys()
    capabilitys => <<'PERL',
# <https://stripe.com/docs/api/capabilities>
sub capabilitys
{
    my $self = shift( @_ );
    my $allowed = [qw( list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'capability', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: card()
    card => <<'PERL',
sub card { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }
PERL
    # NOTE: card_create()
    card_create => <<'PERL',
sub card_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create card" ) ) if( !scalar( @_ ) );
    my $args = {};
    my $card_fields = [qw( object number exp_month exp_year cvc currency name metadata default_for_currency address_line1 address_line2 address_city address_state address_zip address_country )];
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{card} },
    id          => { re => qr/^\w+$/, required => 1 },
    # Token
    source      => { type => 'hash', required => 1 },
    metadata    => { type => 'hash' },
    };
    
    if( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Customer' ) )
    {
        $args = $_[0]->as_hash({ json => 1 });
        $okParams->{_cleanup} = 1;
    }
    elsif( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Payment::Card' ) )
    {
        $args = $_[0]->as_hash({ json => 1 });
        $args->{id} = CORE::delete( $args->{customer} );
        my $ref = {};
        @$ref{ @$card_fields } = @$args{ @$card_fields };
        $args->{source} = $ref;
        $okParams->{_cleanup} = 1;
    }
    else
    {
        $args = $self->_get_args( @_ );
    }
    
    $args = $self->_contract( 'card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id   = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to create a card for the customer" ) );
    my $hash = $self->post( "customers/${id}/sources", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->error( "Cannot find property 'object' in response hash reference: ", sub{ $self->dumper( $hash ) } ) ) if( !CORE::exists( $hash->{object} ) );
    my $class = $self->_object_type_to_class( $hash->{object} ) || CORE::return( $self->pass_error );
    # CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Card', $hash ) );
    CORE::return( $self->_response_to_object( $class, $hash ) );
}
PERL
    # NOTE: card_delete()
    card_delete => <<'PERL',
sub card_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete card" ) ) if( !scalar( @_ ) );
    my $args = {};
    if( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Customer' ) )
    {
        my $cust = shift( @_ );
        CORE::return( $self->error( "No customer id was found in this customer object." ) ) if( !$cust->id );
        CORE::return( $self->error( "No source is set for the credit card to delete for this customer." ) ) if( !$cust->source );
        CORE::return( $self->error( "No credit card id found for this customer source to delete." ) ) if( !$cust->source->id );
        $args->{id} = $cust->id;
        $args->{card_id} = $cust->source->id;
        $args->{expand} = 'all';
    }
    elsif( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Payment::Card' ) )
    {
        my $card = shift( @_ );
        CORE::return( $self->error( "No card id was found in this card object." ) ) if( !$card->id );
        CORE::return( $self->error( "No customer object is set for this card object." ) ) if( !$card->customer );
        CORE::return( $self->error( "No customer id found in the customer object in this card object." ) ) if( !$card->customer->id );
        $args->{card_id} = $card->id;
        $args->{id} = $card->customer->id;
        $args->{expand} = 'all';
    }
    else
    {
        $args = $self->_get_args( @_ );
    }
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{card} },
    id          => { re => qr/^\w+$/, required => 1 },
    card_id     => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to delete his/her card" ) );
    my $cardId = CORE::delete( $args->{card_id} ) || CORE::return( $self->error( "No card id was provided to delete customer's card" ) );
    my $hash = $self->delete( "customers/${id}/sources/${cardId}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Card', $hash ) );
}
PERL
    # NOTE: card_holder()
    card_holder => <<'PERL',
sub card_holder { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Card::Holder', @_ ) ); }
PERL
    # NOTE: card_list()
    card_list => <<'PERL',
sub card_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list customer's cards." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
    my $okParams = 
    {
    expandable      => { allowed => $EXPANDABLES->{card}, data_prefix_is_ok => 1 },
    ending_before   => qr/^\w+$/,
    id              => { re => /^\w+$/, required => 1 },
    limit           => qr/^\d+$/,
    starting_after  => qr/^\w+$/,
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to list his/her cards" ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "customers/${id}/sources", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Card::List', $hash ) );
}
PERL
    # NOTE: card_retrieve()
    card_retrieve => <<'PERL',
sub card_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve card information." ) ) if( !scalar( @_ ) );
    # my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Card', @_ );
    my $args = {};
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{card} },
    id          => { re => qr/^\w+$/, required => 1 },
    customer    => { re => qr/^\w+$/, required => 1 },
    };
    if( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Customer' ) )
    {
        my $cust = shift( @_ );
        CORE::return( $self->error( "No customer id was found in this customer object." ) ) if( !$cust->id );
        CORE::return( $self->error( "No source is set for the credit card to delete for this customer." ) ) if( !$cust->source );
        CORE::return( $self->error( "No credit card id found for this customer source to delete." ) ) if( !$cust->source->id );
        $args->{customer} = $cust->id;
        $args->{id} = $cust->source->id;
        $args->{expand} = 'all';
        $okParams->{_cleanup} = 1;
    }
    elsif( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Payment::Card' ) )
    {
        my $card = shift( @_ );
        CORE::return( $self->error( "No card id was found in this card object." ) ) if( !$card->id );
        CORE::return( $self->error( "No customer object is set for this card object." ) ) if( !$card->customer );
        CORE::return( $self->error( "No customer id found in the customer object in this card object." ) ) if( !$card->customer->id );
        $args->{customer} = $card->customer->id;
        $args->{expand} = 'all';
        $okParams->{_cleanup} = 1;
    }
    else
    {
        $args = $self->_get_args( @_ );
    }
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to retrieve his/her card" ) );
    my $cardId = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No card id was provided to retrieve customer's card" ) );
    my $hash = $self->get( "customers/${id}/sources/${cardId}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Card', $hash ) );
}
PERL
    # NOTE: card_token_create()
    card_token_create => <<'PERL',
sub card_token_create { CORE::return( shift->token_create( @_ ) ); }
PERL
    # NOTE: card_update()
    card_update => <<'PERL',
sub card_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update card." ) ) if( !scalar( @_ ) );
    my $args = {};
    my $okParams = 
    {
    expandable      => { allowed => $EXPANDABLES->{card} },
    id              => { re => qr/^\w+$/, required => 1 },
    customer        => { re => qr/^\w+$/, required => 1 },
    address_city    => qr/^.*?$/,
    address_country => qr/^[a-zA-Z]{2}$/,
    address_line1   => qr/^.*?$/,
    address_line2   => qr/^.*?$/,
    address_state   => qr/^.*?$/,
    address_zip     => qr/^.*?$/,
    exp_month       => qr/^\d{1,2}$/,
    exp_year        => qr/^\d{1,2}$/,
    metadata        => sub{ CORE::return( ref( $_[0] ) eq 'HASH' ? undef() : sprintf( "A hash ref was expected, but instead received '%s'", $_[0] ) ) },
    name            => qr/^.*?$/,
    };
    if( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Customer' ) )
    {
        my $cust = shift( @_ );
        CORE::return( $self->error( "No customer id was found in this customer object." ) ) if( !$cust->id );
        CORE::return( $self->error( "No source is set for the credit card to delete for this customer." ) ) if( !$cust->source );
        CORE::return( $self->error( "No credit card id found for this customer source to delete." ) ) if( !$cust->source->id );
        $args = $cust->source->as_hash({ json => 1 });
        $args->{customer} = $cust->id;
        $args->{expand} = 'all';
        $okParams->{_cleanup} = 1;
    }
    elsif( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Payment::Card' ) )
    {
        my $card = shift( @_ );
        CORE::return( $self->error( "No card id was found in this card object." ) ) if( !$card->id );
        CORE::return( $self->error( "No customer object is set for this card object." ) ) if( !$card->customer );
        CORE::return( $self->error( "No customer id found in the customer object in this card object." ) ) if( !$card->customer->id );
        $args = $card->as_hash({ json => 1 });
        $args->{customer} = $card->customer->id;
        $args->{expand} = 'all';
        $okParams->{_cleanup} = 1;
    }
    else
    {
        $args = $self->_get_args( @_ );
    }
    $args = $self->_contract( 'card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to update his/her card." ) );
    my $cardId = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No card id was provided to update customer's card" ) );
    my $hash = $self->post( "customers/${id}/sources/${cardId}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Card', $hash ) );
}
PERL
    # NOTE: cards()
    cards => <<'PERL',
sub cards
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update delete list )];
    my $meth = $self->_get_method( 'card', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: cash_balance()
    cash_balance => <<'PERL',
sub cash_balance { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Cash::Balance', @_ ) ); }
PERL
    # NOTE: cash_balance_retrieve()
    cash_balance_retrieve => <<'PERL',
sub cash_balance_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve a customer cash balance" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Cash::Balance', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{cash_balance} },
    customer    => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to retrieve his/her cash balance details" ) );
    my $hash = $self->get( "customers/${cust}/cash_balance", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Cash::Balance', $hash ) );
}
PERL
    # NOTE: cash_balance_update()
    cash_balance_update => <<'PERL',
sub cash_balance_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a customer cash balance" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Cash::Balance', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{cash_balance} },
    customer => { re => qr/^\w+$/, required => 1 },
    settings => { fields => ["reconciliation_mode"], type => "hash" },
    };

    $args = $self->_contract( 'cash_balance', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to update his/her cash balance details" ) );
    my $hash = $self->post( "customers/${cust}/cash_balance", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Cash::Balance', $hash ) );
}
PERL
    # NOTE: cash_balances()
    cash_balances => <<'PERL',
sub cash_balances
{
    my $self = shift( @_ );
    my $allowed = [qw( retrieve update )];
    my $action = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to retrieve or update its cash balance details" ) );
    my $meth = $self->_get_method( "customers/${cust}/cash_balance", $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( $args ) );
}
PERL
    # NOTE: cash_transction()
    cash_transction => <<'PERL',
sub cash_transction { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Cash::Transaction', @_ ) ); }
PERL
    # NOTE: charge()
    charge => <<'PERL',
sub charge { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Charge', @_ ) ); }
PERL
    # NOTE: charge_capture()
    charge_capture => <<'PERL',
sub charge_capture
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a charge." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Charge', @_ );
    my $okParams = 
    {
    id                          => { re => qr/^\w+$/, required => 1 },
    amount                      => qr/^\d+$/,
    application_fee_amount      => qr/^\d+$/,
    destination                 => [qw( amount )],
    expandable                  => { allowed => $EXPANDABLES->{charge} },
    receipt_email               => qr/.*?/,
    statement_descriptor        => qr/^.*?$/,
    statement_descriptor_suffix => qr/^.*?$/,
    transfer_data               => [qw( amount )],
    transfer_group              => qr/^.*?$/,
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No charge id was provided to update its charge details." ) );
    CORE::return( $self->error( "Destination specified, but not account property provided" ) ) if( exists( $args->{destination} ) && !scalar( grep( /^account$/, @{$args->{destination}} ) ) );
    my $hash = $self->post( "charges/${id}/capture", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Charge', $hash ) );
}
PERL
    # NOTE: charge_create()
    charge_create => <<'PERL',
# https://stripe.com/docs/api/charges/create
sub charge_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create charge." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Charge', @_ );
    CORE::return( $self->error( "No amount was provided" ) ) if( !exists( $args->{amount} ) || !length( $args->{amount} ) );
    $args->{currency} ||= $self->currency;
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{charge} },
    amount => { re => qr/^\d+$/, required => 1, type => "integer" },
    application_fee_amount => qr/^\d+$/,
    capture => { type => "boolean" },
    currency => { re => qr/^[a-zA-Z]{3}$/, required => 1 },
    customer => qr/^\w+$/,
    description => qr/^.*?$/,
    destination => ["account", "amount"],
    idempotency => qr/^.*?$/,
    metadata => { type => "hash" },
    on_behalf_of => qr/^\w+$/,
    radar_options => { type => "hash" },
    receipt_email => qr/.*?/,
    shipping => {
        fields => ["address", "name", "carrier", "phone", "tracking_number"],
        type   => "hash",
    },
    source => qr/^\w+$/,
    statement_descriptor => qr/^.*?$/,
    statement_descriptor_suffix => qr/^.*?$/,
    transfer_data => { fields => ["destination", "amount"], type => "hash" },
    transfer_group => qr/^.*?$/,
    };

    
    $args = $self->_contract( 'charge', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    
    $args->{currency} = lc( $args->{currency} );
    CORE::return( $self->error( "Destination specified, but no account property provided" ) ) if( exists( $args->{destination} ) && !scalar( grep( /^account$/, @{$args->{destination}} ) ) );
    my $hash = $self->post( 'charges', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Charge', $hash ) );
}
PERL
    # NOTE: charge_list()
    charge_list => <<'PERL',
sub charge_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams = 
    {
    expandable      => { allowed => $EXPANDABLES->{charge}, data_prefix_is_ok => 1 },
    'created'       => qr/^\d+$/,
    'created.gt'    => qr/^\d+$/,
    'created.gte'   => qr/^\d+$/,
    'created.lt'    => qr/^\d+$/,
    'created.lte'   => qr/^\d+$/,
    'customer'      => qr/^\w+$/,
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    'ending_before' => qr/^\w+$/,
    'limit'         => qr/^\d+$/,
    'payment_intent' => qr/^\w+$/,
    'source'        => [qw( object )],
    'starting_after' => qr/^\w+$/,
    'transfer_group' => qr/^.*?$/,
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{source} )
    {
        CORE::return( $self->error( "Invalid source value. It should one of all, alipay_account, bank_account, bitcoin_receiver or card" ) ) if( $args->{source}->{object} !~ /^(?:all|alipay_account|bank_account|bitcoin_receiver|card)$/ );
    }
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'charges', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Charge::List', $hash ) );
}
PERL
    # NOTE: charge_retrieve()
    charge_retrieve => <<'PERL',
sub charge_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve a charge" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Charge', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{charge} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No charge id was provided to retrieve its charge details" ) );
    my $hash = $self->get( "charges/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Charge', $hash ) );
}
PERL
    # NOTE: charge_search()
    charge_search => <<'PERL',
sub charge_search
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to search charges." ) ) if( !scalar( @_ ) );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{charge}, data_prefix_is_ok => 1 },
    limit => qr/^\d+$/,
    page => qr/^\d+$/,
    query => { re => qr/^.*?$/, required => 1, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "charges/search", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Charge::List', $hash ) );
}
PERL
    # NOTE: charge_update()
    charge_update => <<'PERL',
sub charge_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a charge" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Charge', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{charge} },
    customer => qr/^\w+$/,
    description => qr/^.*?$/,
    fraud_details => { fields => ["user_report"], type => "hash" },
    id => { re => qr/^\w+$/, required => 1 },
    metadata => { type => "hash" },
    receipt_email => qr/.*?/,
    shipping => {
        fields => ["address", "name", "carrier", "phone", "tracking_number"],
        type   => "hash",
    },
    transfer_group => qr/^.*?$/,
    };

    $args = $self->_contract( 'charge', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    if( $args->{fraud_details} )
    {
        my $this = $args->{fraud_details};
        if( $this->{user_report} !~ /^(?:fraudulent|safe)$/ )
        {
            CORE::return( $self->error( "Invalid value for fraud_details. It should be either fraudulent or safe" ) );
        }
    }
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No charge id was provided to update its charge details" ) );
    my $hash = $self->post( "charges/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Charge', $hash ) );
}
PERL
    # NOTE: charges()
    charges => <<'PERL',
sub charges
{
    my $self = shift( @_ );
    my $allowed = [qw( create retrieve update capture list search )];
    my $action = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $meth = $self->_get_method( 'charge', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( $args ) );
}
PERL
    # NOTE: checkout_session()
    checkout_session => <<'PERL',
sub checkout_session { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Checkout::Session', @_ ) ); }
PERL
    # NOTE: checkout_session_create()
    checkout_session_create => <<'PERL',
sub checkout_session_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'checkout.session' } },
    after_expiration => { type => "hash" },
    allow_promotion_codes => { type => "boolean" },
    automatic_tax => { type => "hash" },
    billing_address_collection => { type => "string" },
    cancel_url => { type => "string", required => 1 },
    client_reference_id => { type => "string" },
    consent_collection => { type => "hash" },
    currency => { type => "string" },
    customer => { type => "string" },
    customer_creation => { type => "string" },
    customer_email => { type => "string" },
    customer_update => { type => "object" },
    discounts => { type => "array" },
    expires_at => { type => "timestamp" },
    line_items => { type => "hash" },
    locale => { type => "string" },
    metadata => { type => "hash" },
    mode => { type => "string" },
    payment_intent_data => { type => "object" },
    payment_method_collection => { type => "string" },
    payment_method_options => { type => "hash" },
    payment_method_types => { type => "array" },
    phone_number_collection => { type => "hash" },
    setup_intent_data => { type => "object" },
    shipping_address_collection => { type => "hash" },
    shipping_options => { type => "array" },
    submit_type => { type => "string" },
    subscription_data => { type => "object" },
    success_url => { type => "string", required => 1 },
    tax_id_collection => { type => "hash" },
    };
    $args = $self->_contract( 'checkout.session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Checkout::Session', $hash ) );
}
PERL
    # NOTE: checkout_session_expire()
    checkout_session_expire => <<'PERL',
sub checkout_session_expire
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'checkout.session' } },
    };
    $args = $self->_contract( 'checkout.session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Checkout::Session', $hash ) );
}
PERL
    # NOTE: checkout_session_items()
    checkout_session_items => <<'PERL',
sub checkout_session_items
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to items checkout session information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Checkout::Session', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'checkout.session' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Checkout::Session', $hash ) );
}
PERL
    # NOTE: checkout_session_list()
    checkout_session_list => <<'PERL',
sub checkout_session_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list checkout session information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Checkout::Session', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'checkout.session' }, data_prefix_is_ok => 1 },
    customer => { type => "string" },
    customer_details => { type => "hash" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    payment_intent => { type => "string" },
    starting_after => { type => "string" },
    subscription => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Checkout::Session', $hash ) );
}
PERL
    # NOTE: checkout_session_retrieve()
    checkout_session_retrieve => <<'PERL',
sub checkout_session_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'checkout.session' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'checkout.session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No checkout.session id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "checkout/sessions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Checkout::Session', $hash ) );
}
PERL
    # NOTE: checkout_sessions()
    checkout_sessions => <<'PERL',
# <https://stripe.com/docs/api/checkout/sessions>
sub checkout_sessions
{
    my $self = shift( @_ );
    my $allowed = [qw( create expire items list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'checkout_session', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: code_verification()
    code_verification => <<'PERL',
sub code_verification { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Source::CodeVerification', @_ ) ); }
PERL
    # NOTE: company()
    company => <<'PERL',
sub company { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::Company', @_ ) ); }
PERL
    # NOTE: connection_token()
    connection_token => <<'PERL',
sub connection_token { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Terminal::ConnectionToken', @_ ) ); }
PERL
    # NOTE: country_spec()
    country_spec => <<'PERL',
sub country_spec { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::CountrySpec', @_ ) ); }
PERL
    # NOTE: country_spec_list()
    country_spec_list => <<'PERL',
sub country_spec_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list country spec information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::CountrySpec', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'country_spec' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "country_specs", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::CountrySpec', $hash ) );
}
PERL
    # NOTE: country_spec_retrieve()
    country_spec_retrieve => <<'PERL',
sub country_spec_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'country_spec' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'country_spec', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No country_spec id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "country_specs/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::CountrySpec', $hash ) );
}
PERL
    # NOTE: country_specs()
    country_specs => <<'PERL',
# <https://stripe.com/docs/api/country_specs>
sub country_specs
{
    my $self = shift( @_ );
    my $allowed = [qw( list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'country_spec', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: coupon()
    coupon => <<'PERL',
sub coupon { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Product::Coupon', @_ ) ); }
PERL
    # NOTE: coupon_create()
    coupon_create => <<'PERL',
sub coupon_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a coupon" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product::Coupon', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{coupon} },
    amount_off => { re => qr/^\d+$/, type => "integer" },
    applies_to => { type => "hash" },
    currency => { re => qr/^[a-zA-Z]{3}$/, type => "string" },
    currency_options => { type => "hash" },
    duration => { re => qr/^(forever|once|repeating)$/, type => "string" },
    duration_in_months => { re => qr/^\d+$/, type => "integer" },
    id => { type => "string" },
    max_redemptions => { re => qr/^\d+$/, type => "integer" },
    metadata => { type => "hash" },
    name => { type => "string" },
    percent_off => sub { ... },
    redeem_by => { type => "timestamp" },
    };

    $args = $self->_contract( 'coupon', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'coupons', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product::Coupon', $hash ) );
}
PERL
    # NOTE: coupon_delete()
    coupon_delete => <<'PERL',
sub coupon_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete coupon information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product::Coupon', @_ );
    my $okParams = 
    {
    expandable => { allowed => $EXPANDABLES->{coupon} },
    id => { re => qr/^\S+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No coupon id was provided to delete its information." ) );
    my $hash = $self->delete( "coupons/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product::Coupon', $hash ) );
}
PERL
    # NOTE: coupon_list()
    coupon_list => <<'PERL',
sub coupon_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams = 
    {
    expandable => { allowed => $EXPANDABLES->{coupon} },
    'created'       => qr/^\d+$/,
    'created.gt'    => qr/^\d+$/,
    'created.gte'   => qr/^\d+$/,
    'created.lt'    => qr/^\d+$/,
    'created.lte'   => qr/^\d+$/,
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    'ending_before' => qr/^\w+$/,
    'limit'         => qr/^\d+$/,
    'starting_after' => qr/^\w+$/,
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'coupons', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: coupon_retrieve()
    coupon_retrieve => <<'PERL',
sub coupon_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve coupon information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product::Coupon', @_ );
    my $okParams = 
    {
    expandable => { allowed => $EXPANDABLES->{coupon} },
    id => { re => qr/^\S+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No coupon id was provided to retrieve its information." ) );
    my $hash = $self->get( "coupons/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product::Coupon', $hash ) );
}
PERL
    # NOTE: coupon_update()
    coupon_update => <<'PERL',
sub coupon_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a coupon" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product::Coupon', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{coupon} },
    currency_options => { type => "hash" },
    id => { re => qr/^\S+$/, required => 1 },
    metadata => { type => "hash" },
    name => { type => "string" },
    };

    $args = $self->_contract( 'coupon', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No coupon id was provided to update coupon's details" ) );
    my $hash = $self->post( "coupons/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product::Coupon', $hash ) );
}
PERL
    # NOTE: coupons()
    coupons => <<'PERL',
sub coupons
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update delete list )];
    my $meth = $self->_get_method( 'coupon', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: credit_note()
    credit_note => <<'PERL',
sub credit_note { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', @_ ) ); }
PERL
    # NOTE: credit_note_create()
    credit_note_create => <<'PERL',
sub credit_note_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a credit note" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
    # If we are provided with an invoice object, we change our value for only its id
    if( $args->{_object} && 
        $self->_is_object( $args->{_object}->{invoice} ) && 
        $args->{_object}->invoice->isa( 'Net::API::Stripe::Billing::Invoice' ) )
    {
        my $cred = CORE::delete( $args->{_object} );
        $args->{invoice} = $cred->invoice->id || CORE::return( $self->error( "The Invoice object provided for this credit note has no id." ) );
    }
    
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{credit_note} },
    amount => { re => qr/^\d+$/, type => "integer" },
    credit_amount => { re => qr/^\d+$/, type => "integer" },
    invoice => { re => qr/^\w+$/, required => 1, type => "string" },
    lines => {
        fields => [
                      "amount",
                      "description",
                      "invoice_line_item",
                      "quantity",
                      "tax_rates",
                      "type",
                      "unit_amount",
                      "unit_amount_decimal",
                  ],
        type   => "array",
    },
    memo => { type => "string" },
    metadata => { type => "hash" },
    out_of_band_amount => { re => qr/^\d+$/, type => "integer" },
    reason => {
        re => qr/^(duplicate|fraudulent|order_change|product_unsatisfactory)$/,
        type => "string",
    },
    refund => { re => qr/^\w+$/, type => "string" },
    refund_amount => { re => qr/^\d+$/, type => "integer" },
    };

    $args = $self->_contract( 'credit_note', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'credit_notes', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', $hash ) );
}
PERL
    # NOTE: credit_note_line_item()
    credit_note_line_item => <<'PERL',
sub credit_note_line_item { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::CreditNote::LineItem', @_ ) ); }
PERL
    # NOTE: credit_note_line_item_list()
    credit_note_line_item_list => <<'PERL',
sub credit_note_line_item_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list credit note line item information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote::LineItem', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'credit_note_line_item' }, data_prefix_is_ok => 1 },
    amount => { type => "integer" },
    credit_amount => { type => "string" },
    ending_before => { type => "string" },
    invoice => { type => "string", required => 1 },
    limit => { type => "string" },
    lines => { type => "string" },
    memo => { type => "string" },
    metadata => { type => "string" },
    out_of_band_amount => { type => "string" },
    reason => { type => "string" },
    refund => { type => "string" },
    refund_amount => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "credit_notes/preview/lines", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote::LineItem', $hash ) );
}
PERL
    # NOTE: credit_note_line_items()
    credit_note_line_items => <<'PERL',
# <https://stripe.com/docs/api/credit_notes>
sub credit_note_line_items
{
    my $self = shift( @_ );
    my $allowed = [qw( list )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'credit_note_line_item', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: credit_note_lines()
    credit_note_lines => <<'PERL',
sub credit_note_lines
{
    my $self = shift( @_ );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
    CORE::return( $self->error( "No credit note id was provided to retrieve its information." ) ) if( !CORE::length( $args->{id} ) );
    my $okParams = 
    {
    id              => { re => qr/^\w+$/, required => 1 },
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    ending_before   => { re => qr/^\w+$/ },
    limit           => { re => qr/^\d+$/ },
    starting_after  => { re => qr/^\w+$/ },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} );
    my $hash = $self->get( "credit_notes/${id}/lines", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: credit_note_lines_preview()
    credit_note_lines_preview => <<'PERL',
sub credit_note_lines_preview
{
    my $self = shift( @_ );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
    # CORE::return( $self->error( "No credit note id was provided to retrieve its information." ) ) if( !CORE::length( $args->{id} ) );
    CORE::return( $self->error( "No invoice id or object was provided." ) ) if( !CORE::length( $args->{invoice} ) );
    if( $args->{_object} && 
        $self->_is_object( $args->{_object}->{invoice} ) && 
        $args->{_object}->invoice->isa( 'Net::API::Stripe::Billing::Invoice' ) )
    {
        my $cred = CORE::delete( $args->{_object} );
        $args->{invoice} = $cred->invoice->id || CORE::return( $self->error( "The Invoice object provided for this credit note has no id." ) );
    }
    
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{credit_note_lines} },
    # id                    => { re => qr/^\w+$/, required => 1 },
    invoice             => { re => qr/^\w+$/, required => 1 },
    amount              => { re => qr/^\d+$/ },
    credit_amount       => { re => qr/^\d+$/ },
    ending_before       => { re => qr/^\w+$/ },
    limit               => { re => qr/^\d+$/ },
    lines               => { type => 'array', fields => [qw( amount description invoice_line_item quantity tax_rates type unit_amount unit_amount_decimal )] },
    memo                => {},
    metadata            => { type => 'hash' },
    out_of_band_amount  => { re => qr/^\d+$/ },
    reason              => { re => qr/^(duplicate|fraudulent|order_change|product_unsatisfactory)$/ },
    refund              => { re => qr/^\w+$/ },
    refund_amount       => { re => qr/^\d+$/ },
    starting_after      => { re => qr/^\w+$/ },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} );
    my $hash = $self->get( "credit_notes/preview/${id}/lines", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: credit_note_list()
    credit_note_list => <<'PERL',
sub credit_note_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{credit_note}, data_prefix_is_ok => 1 },
    created => qr/^\d+$/,
    'created.gt' => qr/^\d+$/,
    'created.gte' => qr/^\d+$/,
    'created.lt' => qr/^\d+$/,
    'created.lte' => qr/^\d+$/,
    customer => { type => "string" },
    ending_before => qr/^\w+$/,
    invoice => { type => "string" },
    limit => qr/^\d+$/,
    starting_after => qr/^\w+$/,
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'coupons', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: credit_note_preview()
    credit_note_preview => <<'PERL',
sub credit_note_preview
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to preview a credit note" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
    
    my $obj = $args->{_object};
    # If we are provided with an invoice object, we change our value for only its id
    if( $obj && $obj->invoice )
    {
        $args->{invoice} = $obj->invoice->id || CORE::return( $self->error( "The Invoice object provided for this credit note has no id." ) );
    }
    
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{credit_note}, data_prefix_is_ok => 1 },
    amount => { re => qr/^\d+$/, type => "integer" },
    credit_amount => { re => qr/^\d+$/, type => "string" },
    invoice => { required => 1, type => "string" },
    lines => {
        fields => [
                      "amount",
                      "description",
                      "invoice_line_item",
                      "quantity",
                      "tax_rates",
                      "type",
                      "unit_amount",
                      "unit_amount_decimal",
                  ],
        type   => "array",
    },
    memo => { type => "string" },
    metadata => { type => "hash" },
    out_of_band_amount => { re => qr/^\d+$/, type => "integer" },
    reason => {
        re => qr/^(duplicate|fraudulent|order_change|product_unsatisfactory)$/,
        type => "string",
    },
    refund => { re => qr/^\w+$/, type => "string" },
    refund_amount => { re => qr/^\d+$/, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'credit_notes/preview', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', $hash ) );
}
PERL
    # NOTE: credit_note_retrieve()
    credit_note_retrieve => <<'PERL',
sub credit_note_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve credit note information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{credit_note} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No credit note id was provided to retrieve its information." ) );
    my $hash = $self->get( "credit_notes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', $hash ) );
}
PERL
    # NOTE: credit_note_update()
    credit_note_update => <<'PERL',
sub credit_note_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a credit note" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{credit_note} },
    id => { re => qr/^\w+$/, required => 1 },
    memo => { type => "string" },
    metadata => { type => "hash" },
    };

    $args = $self->_contract( 'credit_note', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No credit note id was provided to update credit note's details" ) );
    my $hash = $self->post( "credit_notes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', $hash ) );
}
PERL
    # NOTE: credit_note_void()
    credit_note_void => <<'PERL',
sub credit_note_void
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to void credit note information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{credit_note} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No credit note id was provided to void it." ) );
    my $hash = $self->post( "credit_notes/${id}/void", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', $hash ) );
}
PERL
    # NOTE: credit_notes()
    credit_notes => <<'PERL',
sub credit_notes
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    # delete is an alias of void to make it more mnemotechnical to remember
    $action = 'void' if( $action eq 'delete' );
    my $allowed = [qw( preview create lines lines_preview retrieve update void list )];
    my $meth = $self->_get_method( 'coupons', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: customer()
    customer => <<'PERL',
sub customer { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Customer', @_ ) ); }
PERL
    # NOTE: customer_balance_transaction()
    customer_balance_transaction => <<'PERL',
sub customer_balance_transaction { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Customer::BalanceTransaction', @_ ) ); }
PERL
    # NOTE: customer_balance_transaction_create()
    customer_balance_transaction_create => <<'PERL',
sub customer_balance_transaction_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a customer balance transaction" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer::BalanceTransaction', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{customer_balance_transaction} },
    amount => { re => qr/^\d+$/, required => 1, type => "integer" },
    currency => { re => qr/^[A-Z]{3}$/, required => 1, type => "string" },
    customer => { re => qr/^\w+$/, required => 1 },
    description => { type => "string" },
    metadata => { type => "hash" },
    };

    $args = $self->_contract( 'customer_balance_transaction', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to create a balance transaction." ) );
    my $hash = $self->post( "customers/${id}/balance_transactions" ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::BalanceTransaction', $hash ) );
}
PERL
    # NOTE: customer_balance_transaction_list()
    customer_balance_transaction_list => <<'PERL',
sub customer_balance_transaction_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{customer_balance_transaction}, data_prefix_is_ok => 1 },
    customer    => { re => qr/^\w+$/, required => 1 },
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    'ending_before' => qr/^\w+$/,
    'limit'         => qr/^\d+$/,
    'starting_after' => qr/^\w+$/,
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to get a list of his/her balance transactions." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "customers/${cust}/balance_transactions", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: customer_balance_transaction_retrieve()
    customer_balance_transaction_retrieve => <<'PERL',
sub customer_balance_transaction_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve customer balance transaction information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer::BalanceTransaction', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{customer_balance_transaction} },
    id          => { re => qr/^\w+$/, required => 1 },
    customer    => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to retrieve his/her bank account information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer balance transaction information id was provided to retrieve its information." ) );
    my $hash = $self->get( "customers/${cust}/balance_transactions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::BalanceTransaction', $hash ) );
}
PERL
    # NOTE: customer_balance_transaction_update()
    customer_balance_transaction_update => <<'PERL',
sub customer_balance_transaction_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update the customer balance transaction" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer::BalanceTransaction', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{customer_balance_transaction} },
    customer => { re => qr/^\w+$/, required => 1 },
    description => { type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    metadata => { type => "hash" },
    };

    $args = $self->_contract( 'customer_bank_account', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to update the customer's balance transaction details" ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No balance transaction id was provided to update its details" ) );
    my $hash = $self->post( "customers/${cust}/balance_transactions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::BalanceTransaction', $hash ) );
}
PERL
    # NOTE: customer_balance_transactions()
    customer_balance_transactions => <<'PERL',
sub customer_balance_transactions
{
    my $self = shift( @_ );
    my $allowed = [qw( create retrieve update list )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'customer_balance_transaction', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: customer_bank_account()
    customer_bank_account => <<'PERL',
sub customer_bank_account { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Customer::BankAccount', @_ ) ); }
PERL
    # NOTE: customer_bank_account_create()
    customer_bank_account_create => <<'PERL',
sub customer_bank_account_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a customer bank account" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Source', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{customer_bank_account} },
    id                  => { re => qr/^\w+$/, required => 1 },
    object              => { type => 'string', re => qr/^bank_account$/ },
    country             => { re => qr/^[A-Z]{2}$/, required => 1 },
    currency            => { re => qr/^[A-Z]{3}$/, required => 1 },
    account_holder_name => { re => qr/^.*?$/ },
    account_holder_type => { re => qr/^.*?$/ },
    routing_number      => {},
    account_number      => {},
    metadata            => { type => 'hash' },
    };
    $args = $self->_contract( 'customer_bank_account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to create a bank account." ) );
    my $hash = $self->post( "customers/${id}/sources" ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::BankAccount', $hash ) );
}
PERL
    # NOTE: customer_bank_account_delete()
    customer_bank_account_delete => <<'PERL',
sub customer_bank_account_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete customer bank account." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer::BankAccount', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{customer_bank_account} },
    id          => { re => qr/^\w+$/, required => 1 },
    customer    => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to delete his/her bank account." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer bank accuont id was provided to delete." ) );
    my $hash = $self->delete( "customers/${cust}/sources/${id}" ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::BankAccount', $hash ) );
}
PERL
    # NOTE: customer_bank_account_list()
    customer_bank_account_list => <<'PERL',
sub customer_bank_account_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams = 
    {
    expandable      => { allowed => $EXPANDABLES->{customer_bank_account}, data_prefix_is_ok => 1 },
    customer    => { re => qr/^\w+$/, required => 1 },
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    'ending_before' => qr/^\w+$/,
    'limit'         => qr/^\d+$/,
    'starting_after' => qr/^\w+$/,
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to get a list of his/her bank accounts." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "customers/${cust}/sources", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: customer_bank_account_retrieve()
    customer_bank_account_retrieve => <<'PERL',
sub customer_bank_account_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve customer bank account information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer::BankAccount', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{customer_bank_account} },
    id          => { re => qr/^\w+$/, required => 1 },
    customer    => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to retrieve his/her bank account information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer bank account id was provided to retrieve its information." ) );
    my $hash = $self->get( "customers/${cust}/sources/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::BankAccount', $hash ) );
}
PERL
    # NOTE: customer_bank_account_update()
    customer_bank_account_update => <<'PERL',
sub customer_bank_account_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update the customer bank account" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer::BankAccount', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{customer_bank_account} },
    id                  => { re => qr/^\w+$/, required => 1 },
    customer            => { re => qr/^\w+$/, required => 1 },
    account_holder_name => { re => qr/^.*?$/ },
    account_holder_type => {},
    metadata            => { type => 'hash' },
    };
    $args = $self->_contract( 'customer_bank_account', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to update the customer's bank account details" ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No bank account id was provided to update its details" ) );
    my $hash = $self->post( "customers/${cust}/sources/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::BankAccount', $hash ) );
}
PERL
    # NOTE: customer_bank_account_verify()
    customer_bank_account_verify => <<'PERL',
sub customer_bank_account_verify
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to verify customer bank account information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer::BankAccount', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{customer_bank_account} },
    id          => { re => qr/^\w+$/, required => 1 },
    customer    => { re => qr/^\w+$/, required => 1 },
    amounts     => { type => 'array', re => qr/^\d+$/ },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to verify his/her bank account." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer bank account id was provided to verify." ) );
    my $hash = $self->post( "customers/${cust}/sources/${id}/verify", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::BankAccount', $hash ) );
}
PERL
    # NOTE: customer_bank_accounts()
    customer_bank_accounts => <<'PERL',
sub customer_bank_accounts
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update verify delete list )];
    my $meth = $self->_get_method( 'customer', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: customer_cash_balance_transaction()
    customer_cash_balance_transaction => <<'PERL',
sub customer_cash_balance_transaction { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Cash::Transaction', @_ ) ); }
PERL
    # NOTE: customer_cash_balance_transaction_fund_cash_balance()
    customer_cash_balance_transaction_fund_cash_balance => <<'PERL',
sub customer_cash_balance_transaction_fund_cash_balance
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'customer_cash_balance_transaction' } },
    amount => { type => "integer", required => 1 },
    currency => { type => "string", required => 1 },
    reference => { type => "string" },
    };
    $args = $self->_contract( 'customer_cash_balance_transaction', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $customer = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id (with parameter 'customer') was provided to fund_cash_balance its information." ) );
    my $hash = $self->post( "test_helpers/customers/${customer}/fund_cash_balance", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Cash::Transaction', $hash ) );
}
PERL
    # NOTE: customer_cash_balance_transaction_list()
    customer_cash_balance_transaction_list => <<'PERL',
sub customer_cash_balance_transaction_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list customer cash balance transaction information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Cash::Transaction', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'customer_cash_balance_transaction' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id (with parameter 'id') was provided to list its information." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "customers/${id}/cash_balance_transactions", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Cash::Transaction', $hash ) );
}
PERL
    # NOTE: customer_cash_balance_transaction_retrieve()
    customer_cash_balance_transaction_retrieve => <<'PERL',
sub customer_cash_balance_transaction_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'customer_cash_balance_transaction' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'customer_cash_balance_transaction', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No customer id (with parameter 'parent_id') was provided to retrieve its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer_cash_balance_transaction id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "customers/${parent_id}/cash_balance_transactions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Cash::Transaction', $hash ) );
}
PERL
    # NOTE: customer_cash_balance_transactions()
    customer_cash_balance_transactions => <<'PERL',
# <https://stripe.com/docs/api/cash_balance>
sub customer_cash_balance_transactions
{
    my $self = shift( @_ );
    my $allowed = [qw( fund_cash_balance list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'customer_cash_balance_transaction', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: customer_create()
    customer_create => <<'PERL',
# https://stripe.com/docs/api/customers/create?lang=curl
sub customer_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create customer" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{customer} },
    account_balance => { re => qr/^\-?\d+$/ },
    address => {
        fields  => ["line1", "city", "country", "line2", "postal_code", "state"],
        package => "Net::API::Stripe::Address",
        type    => "hash",
    },
    balance => { re => qr/^\-?\d+$/, type => "integer" },
    cash_balance => { type => "hash" },
    coupon => { type => "string" },
    default_source => { re => qr/^\w+$/ },
    description => { type => "string" },
    email => { type => "string" },
    id => {},
    invoice_prefix => { re => qr/^[A-Z0-9]{3,12}$/, type => "string" },
    invoice_settings => {
        fields  => ["custom_fields", "default_payment_method", "footer"],
        package => "Net::API::Stripe::Billing::Invoice::Settings",
        type    => "hash",
    },
    metadata => { type => "hash" },
    name => { type => "string" },
    next_invoice_sequence => { type => "integer" },
    payment_method => { type => "string" },
    phone => { type => "string" },
    preferred_locales => { type => "array" },
    promotion_code => { type => "string" },
    shipping => {
        fields  => ["address", "name", "carrier", "phone", "tracking_number"],
        package => "Net::API::Stripe::Shipping",
        type    => "hash",
    },
    source => { re => qr/^\w+$/, type => "string" },
    tax => { type => "hash" },
    tax_exempt => { re => qr/^(none|exempt|reverse)$/, type => "string" },
    tax_id_data => { package => "Net::API::Stripe::Customer::TaxId", type => "array" },
    tax_info => {
        fields  => ["tax_id", "type"],
        package => "Net::API::Stripe::Customer::TaxInfo",
    },
    test_clock => { type => "string" },
    };

    $args = $self->_contract( 'customer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    CORE::return( $self->error( "Invalid tax type value provided. It can only be set to vat" ) ) if( $args->{tax_info} && $args->{tax_info}->{type} ne 'vat' );
    my $hash = $self->post( 'customers', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer', $hash ) );
}
PERL
    # NOTE: customer_delete()
    customer_delete => <<'PERL',
# https://stripe.com/docs/api/customers/delete?lang=curl
# "Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer."
sub customer_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete customer information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
    my $okParams = 
    {
    expandable      => { allowed => $EXPANDABLES->{customer} },
    id              => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to delete its information." ) );
    my $hash = $self->delete( "customers/${id}" ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer', $hash ) );
}
PERL
    # NOTE: customer_delete_discount()
    customer_delete_discount => <<'PERL',
sub customer_delete_discount
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete customer discount." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{discount}},
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to delete its coupon." ) );
    my $hash = $self->delete( "customers/${id}/discount", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Discount', $hash ) );
}
PERL
    # NOTE: customer_list()
    customer_list => <<'PERL',
sub customer_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{customer}, data_prefix_is_ok => 1 },
    created => qr/^\d+$/,
    'created.gt' => qr/^\d+$/,
    'created.gte' => qr/^\d+$/,
    'created.lt' => qr/^\d+$/,
    'created.lte' => qr/^\d+$/,
    email => qr/.*?/,
    ending_before => qr/^\w+$/,
    limit => qr/^\d+$/,
    starting_after => qr/^\w+$/,
    test_clock => { type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{source} )
    {
        CORE::return( $self->error( "Invalid source value. It should one of all, alipay_account, bank_account, bitcoin_receiver or card" ) ) if( $args->{source}->{object} !~ /^(?:all|alipay_account|bank_account|bitcoin_receiver|card)$/ );
    }
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'customers', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::List', $hash ) );
}
PERL
    # NOTE: customer_payment_method()
    customer_payment_method => <<'PERL',
sub customer_payment_method
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve customer payment method information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{payment_method} },
    # Payment method id
    id          => { re => qr/^\w+$/, required => 1 },
    # Customer id
    customer    => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $cust = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to retrieve its payment method information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment method id was provided to retrieve its information." ) );
    my $hash = $self->get( "customers/${cust}/payment_methods/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}
PERL
    # NOTE: customer_payment_methods()
    customer_payment_methods => <<'PERL',
sub customer_payment_methods
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list a customer payment methods" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{payment_method}, data_prefix_is_ok => 1 },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to get the list of his/her payment methods." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "customers/${id}/payment_methods", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: customer_retrieve()
    customer_retrieve => <<'PERL',
sub customer_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve customer information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{customer} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to retrieve its information." ) );
    my $hash = $self->get( "customers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer', $hash ) );
}
PERL
    # NOTE: customer_search()
    customer_search => <<'PERL',
sub customer_search
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to search customers." ) ) if( !scalar( @_ ) );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{customer}, data_prefix_is_ok => 1 },
    limit => qr/^\d+$/,
    page => qr/^\d+$/,
    query => { re => qr/^.*?$/, required => 1, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "customers/search", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer::List', $hash ) );
}
PERL
    # NOTE: customer_tax_id()
    customer_tax_id => <<'PERL',
sub customer_tax_id { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Customer::TaxId', @_ ) ); }
PERL
    # NOTE: customer_update()
    customer_update => <<'PERL',
# https://stripe.com/docs/api/customers/update?lang=curl
sub customer_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a customer" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{customer} },
    account_balance => { re => qr/^\d+$/ },
    address => {
        fields => ["line1", "line2", "city", "postal_code", "state", "country"],
        type   => "hash",
    },
    balance => { type => "integer" },
    cash_balance => { type => "hash" },
    coupon => { type => "string" },
    default_source => { re => qr/^\w+$/, type => "string" },
    description => { type => "string" },
    email => { type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    invoice_prefix => { re => qr/^[A-Z0-9]{3,12}$/, type => "string" },
    invoice_settings => {
        fields => ["custom_fields", "default_payment_method", "footer"],
        type   => "hash",
    },
    metadata => { type => "hash" },
    name => { type => "string" },
    next_invoice_sequence => { type => "integer" },
    phone => { type => "string" },
    preferred_locales => { type => "array" },
    promotion_code => { type => "string" },
    shipping => {
        fields => ["address", "name", "carrier", "phone", "tracking_number"],
        type   => "hash",
    },
    source => { re => qr/^\w+$/, type => "string" },
    tax => { type => "hash" },
    tax_exempt => { re => qr/^(none|exempt|reverse)$/, type => "string" },
    tax_info => { fields => ["tax_id", "type"] },
    };

    $args = $self->_contract( 'customer', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    if( $args->{fraud_details} )
    {
        my $this = $args->{fraud_details};
        if( $this->{user_report} !~ /^(?:fraudulent|safe)$/ )
        {
            CORE::return( $self->error( "Invalid value for fraud_details. It should be either fraudulent or safe" ) );
        }
    }
    if( $self->_is_object( $args->{invoice_settings}->{default_payment_method} ) )
    {
        $args->{invoice_settings}->{default_payment_method} = $args->{invoice_settings}->{default_payment_method}->id;
    }
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to update customer's details" ) );
    my $hash = $self->post( "customers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Customer', $hash ) );
}
PERL
    # NOTE: customers()
    customers => <<'PERL',
sub customers
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update delete delete_discount list search payment_methods )];
    my $meth = $self->_get_method( 'customer', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: cvc_update_token_create()
    cvc_update_token_create => <<'PERL',
sub cvc_update_token_create { CORE::return( shift->token_create( @_ ) ); }
PERL
    # NOTE: data()
    data => <<'PERL',
sub data { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Event::Data', @_ ) ); }
PERL
    # NOTE: discount()
    discount => <<'PERL',
sub discount { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Discount', @_ ) ); }
PERL
    # NOTE: discount_delete()
    discount_delete => <<'PERL',
sub discount_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete discount information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Discount', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'discount' } },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "subscriptions/${id}/discount", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Discount', $hash ) );
}
PERL
    # NOTE: discounts()
    discounts => <<'PERL',
# <https://stripe.com/docs/api/discounts>
sub discounts
{
    my $self = shift( @_ );
    my $allowed = [qw( delete delete_customer delete_subscription )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'discount', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: dispute()
    dispute => <<'PERL',
sub dispute { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Dispute', @_ ) ); }
PERL
    # NOTE: dispute_close()
    dispute_close => <<'PERL',
sub dispute_close
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to close dispute." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Dispute', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{dispute} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No dispute id was provided to close." ) );
    my $hash = $self->delete( "disputes/${id}/close", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Dispute', $hash ) );
}
PERL
    # NOTE: dispute_evidence()
    dispute_evidence => <<'PERL',
sub dispute_evidence { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Dispute', @_ ) ); }
PERL
    # NOTE: dispute_list()
    dispute_list => <<'PERL',
sub dispute_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{dispute}, data_prefix_is_ok => 1 },
    charge => { re => qr/.*?/, type => "string" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    ending_before => { re => qr/^\w+$/, type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    payment_intent => { re => qr/^\w+$/, type => "string" },
    starting_after => { re => qr/^\w+$/, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'disputes', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: dispute_retrieve()
    dispute_retrieve => <<'PERL',
sub dispute_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve dispute information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Dispute', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{dispute} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No dispute id was provided to retrieve its information." ) );
    my $hash = $self->get( "disputes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Dispute', $hash ) );
}
PERL
    # NOTE: dispute_update()
    dispute_update => <<'PERL',
sub dispute_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a dispute" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Dispute', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{dispute} },
    evidence => {
        fields => [
                      "access_activity_log",
                      "billing_address",
                      "cancellation_policy",
                      "cancellation_policy_disclosure",
                      "cancellation_rebuttal",
                      "customer_communication",
                      "customer_email_address",
                      "customer_name",
                      "customer_purchase_ip",
                      "customer_signature",
                      "duplicate_charge_documentation",
                      "duplicate_charge_explanation",
                      "duplicate_charge_id",
                      "product_description",
                      "receipt",
                      "refund_policy",
                      "refund_policy_disclosure",
                      "refund_refusal_explanation",
                      "service_date",
                      "service_documentation",
                      "shipping_address",
                      "shipping_carrier",
                      "shipping_date",
                      "shipping_documentation",
                      "shipping_tracking_number",
                      "uncategorized_file",
                      "uncategorized_text",
                  ],
        type   => "hash",
    },
    id => { re => qr/^\w+$/, required => 1 },
    metadata => { type => "hash" },
    submit => { type => "boolean" },
    };

    $args = $self->_contract( 'dispute', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No dispute id was provided to update dispute's details" ) );
    my $hash = $self->post( "disputes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Dispute', $hash ) );
}
PERL
    # NOTE: disputes()
    disputes => <<'PERL',
sub disputes
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( close retrieve update list )];
    my $meth = $self->_get_method( 'dispute', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: document()
    document => <<'PERL',
sub document { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::Document', @_ ) ); }
PERL
    # NOTE: event()
    event => <<'PERL',
sub event { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Event', @_ ) ); }
PERL
    # NOTE: event_list()
    event_list => <<'PERL',
sub event_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{event}, data_prefix_is_ok => 1 },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    delivery_success => { re => qr/.*?/, type => "string" },
    ending_before => { re => qr/^\w+$/, type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    starting_after => { re => qr/^\w+$/, type => "string" },
    type => { re => qr/^\w+$/, type => "string" },
    types => { type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'events', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: event_retrieve()
    event_retrieve => <<'PERL',
sub event_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve event information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Event', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{event} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No event id was provided to retrieve its information." ) );
    my $hash = $self->get( "events/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Event', $hash ) );
}
PERL
    # NOTE: events()
    events => <<'PERL',
sub events
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( retrieve list )];
    my $meth = $self->_get_method( 'events', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: evidence()
    evidence => <<'PERL',
sub evidence { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Dispute::Evidence', @_ ) ); }
PERL
    # NOTE: evidence_details()
    evidence_details => <<'PERL',
sub evidence_details { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Dispute::EvidenceDetails', @_ ) ); }
PERL
    # NOTE: fee_refund()
    fee_refund => <<'PERL',
sub fee_refund { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee::Refund', @_ ) ); }
PERL
    # NOTE: fee_refund_create()
    fee_refund_create => <<'PERL',
sub fee_refund_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'fee_refund' } },
    amount => { type => "integer" },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'fee_refund', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No application_fee id (with parameter 'id') was provided to create its information." ) );
    my $hash = $self->post( "application_fees/${id}/refunds", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee::Refund', $hash ) );
}
PERL
    # NOTE: fee_refund_list()
    fee_refund_list => <<'PERL',
sub fee_refund_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list fee refund information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ApplicationFee::Refund', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'fee_refund' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No application_fee id (with parameter 'id') was provided to list its information." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "application_fees/${id}/refunds", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee::Refund', $hash ) );
}
PERL
    # NOTE: fee_refund_retrieve()
    fee_refund_retrieve => <<'PERL',
sub fee_refund_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'fee_refund' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'fee_refund', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No application_fee id (with parameter 'parent_id') was provided to retrieve its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No refund id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "application_fees/${parent_id}/refunds/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee::Refund', $hash ) );
}
PERL
    # NOTE: fee_refund_update()
    fee_refund_update => <<'PERL',
sub fee_refund_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'fee_refund' } },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'fee_refund', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No application_fee id (with parameter 'parent_id') was provided to update its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No refund id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "application_fees/${parent_id}/refunds/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee::Refund', $hash ) );
}
PERL
    # NOTE: fee_refunds()
    fee_refunds => <<'PERL',
# <https://stripe.com/docs/api/fee_refunds>
sub fee_refunds
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'fee_refund', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: file()
    file => <<'PERL',
sub file { CORE::return( shift->_response_to_object( 'Net::API::Stripe::File', @_ ) ); }
PERL
    # NOTE: file_create()
    file_create => <<'PERL',
sub file_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a file" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::File', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{file} },
    expand => { allowed => [] },
    file => { required => 1, type => "string" },
    file_link_data => { field => ["create", "expires_at", "metadata"], type => "hash" },
    purpose => {
        re => qr/^(business_icon|business_logo|customer_signature|dispute_evidence|identity_document|pci_document|tax_document_user_upload)$/,
        required => 1,
        type => "string",
    },
    };

    $args = $self->_contract( 'file', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( !CORE::length( $args->{file} ) )
    {
        CORE::return( $self->error( "No file was provided to upload." ) );
    }
    my $file = Module::Generic::File::file( $args->{file} );
    if( !$file->exists )
    {
        CORE::return( $self->error( "File \"$file\" does not exist." ) );
    }
    elsif( $file->is_empty )
    {
        CORE::return( $self->error( "File \"$file\" is empty." ) );
    }
    elsif( !$file->can_read )
    {
        CORE::return( $self->error( "File \"$file\" does not have read permission for us (uid = $>)." ) );
    }
    $args->{file} = { _filepath => $file };
    my $hash = $self->post_multipart( 'files', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::File', $hash ) );
}
PERL
    # NOTE: file_link()
    file_link => <<'PERL',
sub file_link { CORE::return( shift->_response_to_object( 'Net::API::Stripe::File::Link', @_ ) ); }
PERL
    # NOTE: file_link_create()
    file_link_create => <<'PERL',
sub file_link_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a file link" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::File::Link', @_ );
    
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{file_link} },
    expires_at => { type => "timestamp" },
    file => { package => "Net::API::Stripe::File", required => 1, type => "string" },
    metadata => { type => "hash" },
    };

    $args = $self->_contract( 'file_link', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'file_links', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::File::Link', $hash ) );
}
PERL
    # NOTE: file_link_list()
    file_link_list => <<'PERL',
sub file_link_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    if( $self->_is_object( $args->{file} ) && $args->{file}->isa( 'Net::API::Stripe::File' ) )
    {
        $args->{file} = $args->{file}->id || CORE::return( $self->error( "No file id could be found in this file object." ) );
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{file_link}, data_prefix_is_ok => 1 },
    created => qr/^\d+$/,
    'created.gt' => qr/^\d+$/,
    'created.gte' => qr/^\d+$/,
    'created.lt' => qr/^\d+$/,
    'created.lte' => qr/^\d+$/,
    ending_before => qr/^\w+$/,
    expand => { allowed => ["file"] },
    expired => { type => "boolean" },
    file => { type => "string" },
    limit => qr/^\d+$/,
    starting_after => qr/^\w+$/,
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'file_links', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: file_link_retrieve()
    file_link_retrieve => <<'PERL',
sub file_link_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve file link information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::File::Link', @_ );
    my $okParams = 
    {
    expand  => { allowed => $EXPANDABLES->{file_link} },
    id      => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No file link id was provided to retrieve its information." ) );
    my $hash = $self->get( "file_links/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::File::Link', $hash ) );
}
PERL
    # NOTE: file_link_update()
    file_link_update => <<'PERL',
sub file_link_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a file link" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::File::Link', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{file_link} },
    expires_at => { type => "timestamp" },
    id => { re => qr/^\w+$/, required => 1 },
    metadata => { type => "hash" },
    };

    $args = $self->_contract( 'file_link', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No file link id was provided to update its details" ) );
    my $hash = $self->post( "file_links/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::File::Link', $hash ) );
}
PERL
    # NOTE: file_links()
    file_links => <<'PERL',
sub file_links
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update list )];
    my $meth = $self->_get_method( 'file_links', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: file_list()
    file_list => <<'PERL',
sub file_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{file}, data_prefix_is_ok => 1 },
    created => qr/^\d+$/,
    'created.gt' => qr/^\d+$/,
    'created.gte' => qr/^\d+$/,
    'created.lt' => qr/^\d+$/,
    'created.lte' => qr/^\d+$/,
    ending_before => qr/^\w+$/,
    expand => { allowed => [] },
    limit => qr/^\d+$/,
    purpose => { type => "string" },
    starting_after => qr/^\w+$/,
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'files', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: file_retrieve()
    file_retrieve => <<'PERL',
sub file_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve file information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::File', @_ );
    my $okParams = 
    {
    expand => { allowed => $EXPANDABLES->{file} },
    id => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No file id was provided to retrieve its information." ) );
    my $hash = $self->get( "files/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::File', $hash ) );
}
PERL
    # NOTE: files()
    files => <<'PERL',
# sub fraud { CORE::return( shift->_instantiate( 'fraud', 'Net::API::Stripe::Fraud' ) ) }
sub files
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve list )];
    my $meth = $self->_get_method( 'files', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: financial_connections_account()
    financial_connections_account => <<'PERL',
sub financial_connections_account { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Financial::Connections::Account', @_ ) ); }
PERL
    # NOTE: financial_connections_account_disconnect()
    financial_connections_account_disconnect => <<'PERL',
sub financial_connections_account_disconnect
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'financial_connections.account' } },
    };
    $args = $self->_contract( 'financial_connections.account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Financial::Connections::Account', $hash ) );
}
PERL
    # NOTE: financial_connections_account_list()
    financial_connections_account_list => <<'PERL',
sub financial_connections_account_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list financial connections account information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Financial::Connections::Account', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'financial_connections.account' }, data_prefix_is_ok => 1 },
    account_holder => { type => "hash" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    session => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "financial_connections/accounts", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Financial::Connections::Account', $hash ) );
}
PERL
    # NOTE: financial_connections_account_owner()
    financial_connections_account_owner => <<'PERL',
sub financial_connections_account_owner { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Financial::Connections::AccountOwner', @_ ) ); }
PERL
    # NOTE: financial_connections_account_owner_list()
    financial_connections_account_owner_list => <<'PERL',
sub financial_connections_account_owner_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list financial connections account owner information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Financial::Connections::AccountOwner', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'financial_connections.account_owner' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    ownership => { type => "string", required => 1 },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "?ownership=:ownership_id", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Financial::Connections::AccountOwner', $hash ) );
}
PERL
    # NOTE: financial_connections_account_owners()
    financial_connections_account_owners => <<'PERL',
# <https://stripe.com/docs/api/financial_connections/ownership>
sub financial_connections_account_owners
{
    my $self = shift( @_ );
    my $allowed = [qw( list )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'financial_connections_account_owner', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: financial_connections_account_ownership()
    financial_connections_account_ownership => <<'PERL',
sub financial_connections_account_ownership { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Financial::Connections::AccountOwnership', @_ ) ); }
PERL
    # NOTE: financial_connections_account_refresh()
    financial_connections_account_refresh => <<'PERL',
sub financial_connections_account_refresh
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to refresh financial connections account information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Financial::Connections::Account', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'financial_connections.account' } },
    features => { type => "array", required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Financial::Connections::Account', $hash ) );
}
PERL
    # NOTE: financial_connections_account_retrieve()
    financial_connections_account_retrieve => <<'PERL',
sub financial_connections_account_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'financial_connections.account' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'financial_connections.account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "financial_connections/accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Financial::Connections::Account', $hash ) );
}
PERL
    # NOTE: financial_connections_accounts()
    financial_connections_accounts => <<'PERL',
# <https://stripe.com/docs/api/financial_connections/accounts>
sub financial_connections_accounts
{
    my $self = shift( @_ );
    my $allowed = [qw( disconnect list refresh retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'financial_connections_account', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: financial_connections_session()
    financial_connections_session => <<'PERL',
sub financial_connections_session { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Financial::Connections::Session', @_ ) ); }
PERL
    # NOTE: financial_connections_session_create()
    financial_connections_session_create => <<'PERL',
sub financial_connections_session_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'financial_connections.session' } },
    account_holder => { type => "hash", required => 1 },
    filters => { type => "hash" },
    permissions => { type => "array", required => 1 },
    };
    $args = $self->_contract( 'financial_connections.session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "financial_connections/sessions", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Financial::Connections::Session', $hash ) );
}
PERL
    # NOTE: financial_connections_session_retrieve()
    financial_connections_session_retrieve => <<'PERL',
sub financial_connections_session_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'financial_connections.session' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'financial_connections.session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No financial_connections.session id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "financial_connections/sessions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Financial::Connections::Session', $hash ) );
}
PERL
    # NOTE: financial_connections_sessions()
    financial_connections_sessions => <<'PERL',
# <https://stripe.com/docs/api/financial_connections/session>
sub financial_connections_sessions
{
    my $self = shift( @_ );
    my $allowed = [qw( create retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'financial_connections_session', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: fraud()
    fraud => <<'PERL',
sub fraud { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Fraud', @_ ) ); }
PERL
    # NOTE: funding_instructions()
    funding_instructions => <<'PERL',
sub funding_instructions { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::FundingInstructions', @_ ) ); }
PERL
    # NOTE: funding_instructions_create()
    funding_instructions_create => <<'PERL',
sub funding_instructions_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'funding_instructions' } },
    bank_transfer => { type => "hash", required => 1 },
    currency => { type => "string", required => 1 },
    funding_type => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'funding_instructions', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "issuing/funding_instructions", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::FundingInstructions', $hash ) );
}
PERL
    # NOTE: funding_instructions_fund()
    funding_instructions_fund => <<'PERL',
sub funding_instructions_fund
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'funding_instructions' } },
    amount => { type => "string", required => 1 },
    currency => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'funding_instructions', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "test_helpers/issuing/fund_balance", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::FundingInstructions', $hash ) );
}
PERL
    # NOTE: funding_instructions_list()
    funding_instructions_list => <<'PERL',
sub funding_instructions_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list funding instructions information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Issuing::FundingInstructions', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'funding_instructions' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "issuing/funding_instructions", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::FundingInstructions', $hash ) );
}
PERL
    # NOTE: funding_instructionss()
    funding_instructionss => <<'PERL',
# <https://stripe.com/docs/api/issuing/funding_instructions>
sub funding_instructionss
{
    my $self = shift( @_ );
    my $allowed = [qw( create fund list )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'funding_instructions', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: identity_verification_report()
    identity_verification_report => <<'PERL',
sub identity_verification_report { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Identity::VerificationReport', @_ ) ); }
PERL
    # NOTE: identity_verification_report_list()
    identity_verification_report_list => <<'PERL',
sub identity_verification_report_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list identity verification report information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Identity::VerificationReport', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'identity.verification_report' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    type => { type => "string" },
    verification_session => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Identity::VerificationReport', $hash ) );
}
PERL
    # NOTE: identity_verification_report_retrieve()
    identity_verification_report_retrieve => <<'PERL',
sub identity_verification_report_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'identity.verification_report' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'identity.verification_report', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No identity.verification_report id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "identity/verification_reports/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Identity::VerificationReport', $hash ) );
}
PERL
    # NOTE: identity_verification_reports()
    identity_verification_reports => <<'PERL',
# <https://stripe.com/docs/api/identity/verification_reports>
sub identity_verification_reports
{
    my $self = shift( @_ );
    my $allowed = [qw( list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'identity_verification_report', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: identity_verification_session()
    identity_verification_session => <<'PERL',
sub identity_verification_session { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Identity::VerificationSession', @_ ) ); }
PERL
    # NOTE: identity_verification_session_cancel()
    identity_verification_session_cancel => <<'PERL',
sub identity_verification_session_cancel
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'identity.verification_session' } },
    };
    $args = $self->_contract( 'identity.verification_session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Identity::VerificationSession', $hash ) );
}
PERL
    # NOTE: identity_verification_session_create()
    identity_verification_session_create => <<'PERL',
sub identity_verification_session_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'identity.verification_session' } },
    metadata => { type => "hash" },
    options => { type => "hash" },
    return_url => { type => "string" },
    type => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'identity.verification_session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Identity::VerificationSession', $hash ) );
}
PERL
    # NOTE: identity_verification_session_list()
    identity_verification_session_list => <<'PERL',
sub identity_verification_session_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list identity verification session information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Identity::VerificationSession', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'identity.verification_session' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Identity::VerificationSession', $hash ) );
}
PERL
    # NOTE: identity_verification_session_redact()
    identity_verification_session_redact => <<'PERL',
sub identity_verification_session_redact
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'identity.verification_session' } },
    };
    $args = $self->_contract( 'identity.verification_session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Identity::VerificationSession', $hash ) );
}
PERL
    # NOTE: identity_verification_session_retrieve()
    identity_verification_session_retrieve => <<'PERL',
sub identity_verification_session_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'identity.verification_session' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'identity.verification_session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No identity.verification_session id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "identity/verification_sessions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Identity::VerificationSession', $hash ) );
}
PERL
    # NOTE: identity_verification_session_update()
    identity_verification_session_update => <<'PERL',
sub identity_verification_session_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'identity.verification_session' } },
    metadata => { type => "hash" },
    options => { type => "hash" },
    type => { type => "string" },
    };
    $args = $self->_contract( 'identity.verification_session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No identity.verification_session id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "identity/verification_sessions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Identity::VerificationSession', $hash ) );
}
PERL
    # NOTE: identity_verification_sessions()
    identity_verification_sessions => <<'PERL',
# <https://stripe.com/docs/api/identity/verification_sessions>
sub identity_verification_sessions
{
    my $self = shift( @_ );
    my $allowed = [qw( cancel create list redact retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'identity_verification_session', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: invoice()
    invoice => <<'PERL',
sub invoice { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice', @_ ) ); }
PERL
    # NOTE: invoice_create()
    invoice_create => <<'PERL',
sub invoice_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create an invoice" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    my $obj = $args->{_object};
    # If we are provided with an invoice object, we change our value for only its id
    if( ( $obj && $obj->customer ) || 
        ( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) ) )
    {
        my $cust = $obj ? $obj->customer : $args->{customer};
        $args->{customer} = $cust->id || CORE::return( $self->error( "The Customer object provided for this invoice has no id." ) );
    }
    
    if( ( $obj && $obj->subscription ) || 
        ( $args->{subscription} && $self->_is_object( $args->{subscription} ) && $args->{subscription}->isa( 'Net::API::Stripe::Billing::Subscription' ) ) )
    {
        my $sub = $obj ? $obj->subscription : $args->{subscription};
        $args->{subscription} = $sub->id || CORE::return( $self->error( "The Subscription object provided for this invoice has no id." ) );
    }
    
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{invoice} },
    account_tax_ids => { type => "array" },
    application_fee_amount => { re => qr/^\d+$/, type => "integer" },
    auto_advance => { type => "boolean" },
    automatic_tax => { fields => ["enabled"], type => "hash" },
    collection_method => { re => qr/^(charge_automatically|send_invoice)$/, type => "string" },
    currency => { type => "currency" },
    custom_fields => { fields => ["name", "value"], type => "array" },
    customer => { re => qr/^\w+$/, type => "string" },
    days_until_due => { re => qr/^\d+$/, type => "integer" },
    default_payment_method => { re => qr/^\w+$/, type => "string" },
    default_source => { re => qr/^\w+$/, type => "string" },
    default_tax_rates => { re => qr/^\d+(?:\.\d+)?$/, type => "array" },
    description => { type => "string" },
    discounts => { fields => ["coupon", "discount"], type => "array" },
    due_date => { type => "timestamp" },
    footer => { type => "string" },
    metadata => { type => "hash" },
    on_behalf_of => { re => qr/^\w+$/, type => "string" },
    payment_settings => {
        fields => [
                      "payment_method_options.acss_debit",
                      "payment_method_options.acss_debit.mandate_options",
                      "payment_method_options.acss_debit.mandate_options.transaction_type",
                      "payment_method_options.acss_debit.verification_method",
                      "payment_method_options.bancontact",
                      "payment_method_options.bancontact.preferred_language",
                      "payment_method_options.card",
                      "payment_method_options.card.request_three_d_secure",
                      "payment_method_options.customer_balance",
                      "payment_method_options.customer_balance.bank_transfer",
                      "payment_method_options.customer_balance.bank_transfer.eu_bank_transfer",
                      "payment_method_options.customer_balance.bank_transfer.eu_bank_transfer.country",
                      "payment_method_options.customer_balance.bank_transfer.type",
                      "payment_method_options.customer_balance.funding_type",
                      "payment_method_options.konbini",
                      "payment_method_options.us_bank_account",
                      "payment_method_options.us_bank_account.financial_connections",
                      "payment_method_options.us_bank_account.financial_connections.permissions",
                      "payment_method_options.us_bank_account.verification_method",
                      "payment_method_types",
                  ],
        type   => "hash",
    },
    pending_invoice_items_behavior => { type => "string" },
    rendering_options => { fields => ["amount_tax_display"], type => "hash" },
    statement_descriptor => { type => "string" },
    subscription => { re => qr/^\w+$/, type => "string" },
    tax_percent => { re => qr/^\d+(?:\.\d+)?$/ },
    transfer_data => { fields => ["destination", "amount"], type => "hash" },
    };

    $args = $self->_contract( 'invoice', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'invoices', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_delete()
    invoice_delete => <<'PERL',
# NOTE: Delete a draft invoice
sub invoice_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete a draft invoice." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{invoice} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No draft invoice id was provided to delete its information." ) );
    my $hash = $self->delete( "invoices/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_finalise()
    invoice_finalise => <<'PERL',
sub invoice_finalise
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to pay invoice." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    my $okParams = 
    {
    expandable      => { allowed => $EXPANDABLES->{invoice} },
    id              => { re => qr/^\w+$/, required => 1 },
    auto_advance    => {},
    };
    $args = $self->_contract( 'invoice', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice id was provided to pay it." ) );
    my $hash = $self->post( "invoices/${id}/finalize", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_finalize()
    invoice_finalize => <<'PERL',
sub invoice_finalize
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'invoice' } },
    auto_advance => { type => "boolean" },
    };
    $args = $self->_contract( 'invoice', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice id (with parameter 'id') was provided to finalize its information." ) );
    my $hash = $self->post( "invoices/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_item()
    invoice_item => <<'PERL',
# Make everyone happy, British English and American English
sub invoice_item { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', @_ ) ); }
PERL
    # NOTE: invoice_item_create()
    invoice_item_create => <<'PERL',
sub invoice_item_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create an invoice item" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice::Item', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{invoiceitem} },
    customer            => { re => qr/^\w+$/, required => 1 },
    amount              => { type => 'integer' },
    currency            => { type => 'string' },
    description         => {},
    metadata            => { type => 'hash' },
    period              => { fields => [qw( end! start! )] },
    price               => { re => qr/^\w+$/ },
    discountable        => { type => 'boolean' },
    discounts           => { type => 'array', fields => [qw( coupon discount )] },
    invoice             => { re => qr/^\w+$/ },
    price_data          => { fields => [qw(
            currency!
            product!
            unit_amount_decimal!
            tax_behavior
            unit_amount
        )] },
    quantity            => { type => 'integer' },
    subscription        => { re => qr/^\w+$/ },
    tax_rates           => { type => 'array' },
    unit_amount         => { type => 'integer' },
    unit_amount_decimal => { type => 'decimal' },
    };
    $args = $self->_contract( 'invoiceitem', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'invoiceitems', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', $hash ) );
}
PERL
    # NOTE: invoice_item_delete()
    invoice_item_delete => <<'PERL',
sub invoice_item_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete an invoice item information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice::Item', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{invoiceitem} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice item id was provided to delete its information." ) );
    my $hash = $self->delete( "invoiceitems/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', $hash ) );
}
PERL
    # NOTE: invoice_item_list()
    invoice_item_list => <<'PERL',
sub invoice_item_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{invoiceitem} },
    created             => { re => qr/^\d+$/ },
    'created.gt'        => { re => qr/^\d+$/ },
    'created.gte'       => { re => qr/^\d+$/ },
    'created.lt'        => { re => qr/^\d+$/ },
    'created.lte'       => { re => qr/^\d+$/ },
    invoice             => { re => qr/^\w+$/ },
    ending_before       => {},
    limit               => { re => qr/^\d+$/ },
    pending             => { type => 'boolean' },
    starting_after      => {},
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'invoiceitems', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: invoice_item_retrieve()
    invoice_item_retrieve => <<'PERL',
sub invoice_item_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve invoice item information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice::Item', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{invoiceitem} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice item id was provided to retrieve its information." ) );
    my $hash = $self->get( "invoiceitems/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', $hash ) );
}
PERL
    # NOTE: invoice_item_update()
    invoice_item_update => <<'PERL',
sub invoice_item_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update an invoice item." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice::Item', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{invoiceitem} },
    id                  => { re => qr/^\w+$/, required => 1 },
    amount              => { type => 'integer' },
    description         => {},
    metadata            => { type => 'hash' },
    period              => { fields => [qw( end! start! )] },
    price               => { re => qr/^\w+$/ },
    discountable        => { type => 'boolean' },
    discounts           => { type => 'array', fields => [qw( coupon discount )] },
    price_data          => { fields => [qw(
            currency!
            product!
            unit_amount_decimal!
            tax_behavior
            unit_amount
        )] },
    quantity            => { type => 'integer' },
    tax_rates           => { type => 'array' },
    unit_amount         => { type => 'integer' },
    unit_amount_decimal => { type => 'decimal' },
    };
    $args = $self->_contract( 'invoiceitem', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No product id was provided to update product's details" ) );
    my $hash = $self->post( "invoiceitems/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', $hash ) );
}
PERL
    # NOTE: invoice_items()
    invoice_items => <<'PERL',
sub invoice_items
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update list delete )];
    my $meth = $self->_get_method( 'invoice_item', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: invoice_line_item()
    invoice_line_item => <<'PERL',
sub invoice_line_item { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice::LineItem', @_ ) ); }
PERL
    # NOTE: invoice_lines()
    invoice_lines => <<'PERL',
sub invoice_lines
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to get the invoice line items." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    # There are no expandable properties as of 2020-02-14
    my $okParams = 
    {
    id              => { re => qr/^\w+$/, required => 1 },
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    ending_before   => { re => qr/^\w+$/ },
    limit           => { re => qr/^\d+$/ },
    starting_after  => { re => qr/^\w+$/ },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "invoices/${id}/lines", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: invoice_lines_upcoming()
    invoice_lines_upcoming => <<'PERL',
# NOTE: Retrieve an upcoming invoice's line items
sub invoice_lines_upcoming
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to get the incoming invoice line items." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    # If any
    my $obj = $args->{_object};
    if( ( $obj && $obj->customer ) || 
        ( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) ) )
    {
        my $cust = $obj ? $obj-customer : $args->{customer};
        $args->{customer} = $cust->id || CORE::return( $self->error( "No customer id could be found in this customer object." ) );
    }
    
    if( ( $obj && $obj->schedule && $obj->schedule->id ) || 
        ( $args->{schedule} && $self->_is_object( $args->{schedule} ) && $args->{schedule}->isa( 'Net::API::Stripe::Billing::Subscription::Schedule' ) ) ) 
    {
        my $sched = $obj ? $obj->schedule : $args->{schedule};
        $args->{schedule} = $sched->id || CORE::return( $self->error( "No subscription schedule id could be found in this subscription schedule object." ) );
    }
    
    if( ( $obj && $obj->subscription && $obj->subscription->id ) ||
        ( $args->{subscription} && $self->_is_object( $args->{subscription} ) && $args->{subscription}->isa( 'Net::API::Stripe::Billing::Subscription' ) ) )
    {
        my $sub = $obj ? $obj->subscription : $args->{subscription};
        $args->{subscription} = $sub->id || CORE::return( $self->error( "No subscription id could be found in this subscription object." ) );
    }
    
    my $okParams = 
    {
    customer                => { re => qr/^\w+$/ },
    coupon                  => {},
    ending_before           => { re => qr/^\w+$/ },
    invoice_items           => { type => 'array', fields => [qw( amount currency description discountable invoiceitem metadata period.end period.start quantity tax_rates unit_amount unit_amount_decimal )] },
    limit                   => { re => qr/^\d+$/ },
    schedule                => { re => qr/^\w+$/ },
    starting_after          => { re => qr/^\w+$/ },
    subscription            => { re => qr/^\w+$/ },
    # A timestamp
    subscription_billing_cycle_anchor => {},
    # A timestamp
    subscription_cancel_at  => {},
    # Boolean
    subscription_cancel_at_period_end => {},
    # "This simulates the subscription being canceled or expired immediately."
    subscription_cancel_now => {},
    subscription_default_tax_rates => { type => 'array' },
    subscription_items      => {},
    subscription_prorate    => { re => qr/^(subscription_items|subscription|subscription_items|subscription_trial_end)$/ },
    subscription_proration_behavior => { re => qr/^(create_prorations|none|always_invoice)$/ },
    # Timestamp
    subscription_proration_date => {},
    # Timestamp
    subscription_start_date => {},
    subscription_tax_percent=> { re => qr/^\d+(\.\d+)?$/ },
    subscription_trial_end  => {},
    subscription_trial_from_plan => {},
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'invoices/upcoming/lines', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: invoice_list()
    invoice_list => <<'PERL',
sub invoice_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    if( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) )
    {
        $args->{customer} = $args->{customer}->id || CORE::return( $self->error( "No customer id could be found in this customer object." ) );
    }
    
    if( $args->{subscription} && $self->_is_object( $args->{subscription} ) && $args->{subscription}->isa( 'Net::API::Stripe::Billing::Subscription' ) )
    {
        $args->{subscription} = $args->{subscription}->id || CORE::return( $self->error( "No subscription id could be found in this subscription object." ) );
    }
    
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{invoice}, data_prefix_is_ok => 1 },
    collection_method => { re => qr/^(charge_automatically|send_invoice)$/, type => "string" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    customer => { re => qr/^\w+$/, type => "string" },
    due_date => { type => "timestamp" },
    'due_date.gt' => { re => qr/^\d+$/ },
    'due_date.gte' => { re => qr/^\d+$/ },
    'due_date.lt' => { re => qr/^\d+$/ },
    'due_date.lte' => { re => qr/^\d+$/ },
    ending_before => { re => qr/^\w+$/, type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    starting_after => { re => qr/^\w+$/, type => "string" },
    status => { re => qr/^(draft|open|paid|uncollectible|void)$/, type => "string" },
    subscription => { re => qr/^\w+$/, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'invoices', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: invoice_pay()
    invoice_pay => <<'PERL',
sub invoice_pay
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to pay invoice." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    my $obj = $args->{_object};
    if( ( $obj && $obj->payment_method ) ||
        ( $args->{payment_method} && $self->_is_object( $args->{payment_method} ) && $args->{payment_method}->isa( 'Net::API::Stripe::Payment::Method' ) ) )
    {
        my $pm = $obj ? $obj->payment_method : $args->{payment_method};
        $args->{payment_method} = $pm->id || CORE::return( $self->error( "No payment method id could be found in this payment method object." ) );
    }
    
    if( ( $obj && $obj->source ) || 
        ( $args->{source} && $self->_is_object( $args->{source} ) && $args->{source}->isa( 'Net::API::Stripe::Payment::Source' ) ) )
    {
        my $src = $obj ? $obj->source : $args->{source};
        $args->{source} = $src->id || CORE::return( $self->error( "No payment source id could be found in this payment source object." ) );
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{invoice} },
    forgive => { type => "boolean" },
    id => { re => qr/^\w+$/, required => 1 },
    mandate => { type => "string" },
    off_session => { type => "boolean" },
    paid_out_of_band => { type => "boolean" },
    payment_method => { re => qr/^\w+$/, type => "string" },
    source => { re => qr/^\w+$/, type => "string" },
    };

    $args = $self->_contract( 'invoice', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice id was provided to pay it." ) );
    my $hash = $self->post( "invoices/${id}/pay", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_retrieve()
    invoice_retrieve => <<'PERL',
sub invoice_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve invoice information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{invoice} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice id was provided to retrieve its information." ) );
    my $hash = $self->get( "invoices/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_search()
    invoice_search => <<'PERL',
sub invoice_search
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to search for an invoice information." ) ) if( !scalar( @_ ) );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{invoice}, data_prefix_is_ok => 1 },
    limit => qr/^\d+$/,
    page => qr/^\d+$/,
    query => { re => qr/^.*?$/, required => 1, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "invoices/search", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: invoice_send()
    invoice_send => <<'PERL',
# NOTE: Send an invoice for manual payment
sub invoice_send
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to send invoice." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{invoice} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    $args = $self->_contract( 'invoice', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice id was provided to send it." ) );
    my $hash = $self->post( "invoices/${id}/send", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_settings()
    invoice_settings => <<'PERL',
sub invoice_settings { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Settings', @_ ) ); }
PERL
    # NOTE: invoice_uncollectible()
    invoice_uncollectible => <<'PERL',
sub invoice_uncollectible
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'invoice' } },
    };
    $args = $self->_contract( 'invoice', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice id (with parameter 'id') was provided to uncollectible its information." ) );
    my $hash = $self->post( "invoices/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_upcoming()
    invoice_upcoming => <<'PERL',
sub invoice_upcoming
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve an upcoming invoice." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    
    my $obj = $args->{_object};
    if( ( $obj && $obj->customer ) ||
        ( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) ) )
    {
        my $cust = $obj ? $obj->customer : $args->{customer};
        $args->{customer} = $cust->id || CORE::return( $self->error( "No customer id could be found in this customer object." ) );
    }
    
    if( ( $obj && $obj->schedule ) ||
        ( $args->{schedule} && $self->_is_object( $args->{schedule} ) && $args->{schedule}->isa( 'Net::API::Stripe::Billing::Subscription::Schedule' ) ) )
    {
        my $sched = $obj ? $obj->schedule : $args->{schedule};
        $args->{schedule} = $sched->id || CORE::return( $self->error( "No subscription schedule id could be found in this subscription schedule object." ) );
    }
    
    if( ( $obj && $obj->subscription ) ||
        ( $args->{subscription} && $self->_is_object( $args->{subscription} ) && $args->{subscription}->isa( 'Net::API::Stripe::Billing::Subscription' ) ) )
    {
        my $sub = $obj ? $obj->subscription : $args->{subscription};
        $args->{subscription} = $sub->id || CORE::return( $self->error( "No subscription id could be found in this subscription object." ) );
    }
    
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{invoice}, data_prefix_is_ok => 1 },
    automatic_tax => { type => "boolean" },
    coupon => { type => "string" },
    currency => { type => "currency" },
    customer => { re => qr/^\w+$/, type => "string" },
    customer_details => {
        fields => [
                      "address",
                      "address.city",
                      "address.country",
                      "address.line1",
                      "address.line2",
                      "address.postal_code",
                      "address.state",
                      "shipping",
                      "shipping.address",
                      "shipping.address.city",
                      "shipping.address.country",
                      "shipping.address.line1",
                      "shipping.address.line2",
                      "shipping.address.postal_code",
                      "shipping.address.state",
                      "shipping.name",
                      "shipping.phone",
                      "tax",
                      "tax.ip_address",
                      "tax_exempt",
                      "tax_ids",
                      "tax_ids.type",
                      "tax_ids.value",
                  ],
        type   => "hash",
    },
    discounts => { fields => ["coupon", "discount"], type => "array" },
    invoice_items => {
        fields => [
                      "amount",
                      "currency",
                      "description",
                      "discountable",
                      "discounts",
                      "discounts.coupon",
                      "discounts.discount",
                      "invoiceitem",
                      "metadata",
                      "period.end!",
                      "period.start!",
                      "quantity",
                      "tax_rates",
                      "unit_amount",
                      "unit_amount_decimal",
                  ],
        type   => "array",
    },
    schedule => { re => qr/^\w+$/, type => "string" },
    subscription => { re => qr/^\w+$/, type => "string" },
    subscription_billing_cycle_anchor => { type => "string" },
    subscription_cancel_at => { type => "string" },
    subscription_cancel_at_period_end => { type => "string" },
    subscription_cancel_now => { type => "string" },
    subscription_default_tax_rates => { type => "array" },
    subscription_items => { type => "string" },
    subscription_prorate => {
        re => qr/^(subscription_items|subscription|subscription_items|subscription_trial_end)$/,
    },
    subscription_proration_behavior => {
        re => qr/^(create_prorations|none|always_invoice)$/,
        type => "string",
    },
    subscription_proration_date => { type => "integer" },
    subscription_start_date => { type => "string" },
    subscription_tax_percent => { re => qr/^\d+(\.\d+)?$/ },
    subscription_trial_end => { type => "string" },
    subscription_trial_from_plan => { type => "string" },
    };

    $args = $self->_contract( 'invoice', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'invoices/upcoming', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_update()
    invoice_update => <<'PERL',
sub invoice_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update an invoice" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{invoice} },
    account_tax_ids => { type => "array" },
    application_fee_amount => { re => qr/^\d+$/, type => "integer" },
    auto_advance => { type => "boolean" },
    automatic_tax => { fields => ["enabled"], type => "hash" },
    collection_method => { re => qr/^(charge_automatically|send_invoice)$/, type => "string" },
    custom_fields => { fields => ["name", "value"], type => "array" },
    days_until_due => { re => qr/^\d+$/, type => "integer" },
    default_payment_method => { re => qr/^\w+$/, type => "string" },
    default_source => { re => qr/^\w+$/, type => "string" },
    default_tax_rates => { re => qr/^\d+(?:\.\d+)?$/, type => "array" },
    description => { type => "string" },
    discounts => { fields => ["coupon", "discount"], type => "array" },
    due_date => { type => "timestamp" },
    footer => { type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    metadata => { type => "hash" },
    on_behalf_of => { re => qr/^\w+$/, type => "string" },
    payment_settings => {
        fields => [
                      "payment_method_options.acss_debit",
                      "payment_method_options.acss_debit.mandate_options",
                      "payment_method_options.acss_debit.mandate_options.transaction_type",
                      "payment_method_options.acss_debit.verification_method",
                      "payment_method_options.bancontact",
                      "payment_method_options.bancontact.preferred_language",
                      "payment_method_options.card",
                      "payment_method_options.card.request_three_d_secure",
                      "payment_method_options.customer_balance",
                      "payment_method_options.customer_balance.bank_transfer",
                      "payment_method_options.customer_balance.bank_transfer.eu_bank_transfer",
                      "payment_method_options.customer_balance.bank_transfer.eu_bank_transfer.country",
                      "payment_method_options.customer_balance.bank_transfer.type",
                      "payment_method_options.customer_balance.funding_type",
                      "payment_method_options.konbini",
                      "payment_method_options.us_bank_account",
                      "payment_method_options.us_bank_account.financial_connections",
                      "payment_method_options.us_bank_account.financial_connections.permissions",
                      "payment_method_options.us_bank_account.verification_method",
                      "payment_method_types",
                  ],
        type   => "hash",
    },
    rendering_options => { fields => ["amount_tax_display"], type => "hash" },
    statement_descriptor => { type => "string" },
    transfer_data => { fields => ["destination", "amount"], type => "hash" },
    };

    $args = $self->_contract( 'invoice', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice id was provided to update invoice's details" ) );
    my $hash = $self->post( "invoices/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_void()
    invoice_void => <<'PERL',
sub invoice_void
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to void invoice information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{invoice} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice id was provided to void it." ) );
    my $hash = $self->post( "invoices/${id}/void", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoice_write_off()
    invoice_write_off => <<'PERL',
# NOTE: Mark an invoice as uncollectible
sub invoice_write_off
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to make invoice uncollectible." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{invoice} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoice id was provided to make it uncollectible." ) );
    my $hash = $self->post( "invoices/${id}/mark_uncollectible", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}
PERL
    # NOTE: invoiceitem()
    invoiceitem => <<'PERL',
sub invoiceitem { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', @_ ) ); }
PERL
    # NOTE: invoiceitem_create()
    invoiceitem_create => <<'PERL',
sub invoiceitem_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'invoiceitem' } },
    amount => { type => "integer" },
    currency => { type => "string" },
    customer => { type => "string", required => 1 },
    description => { type => "string" },
    discountable => { type => "boolean" },
    discounts => { type => "array" },
    invoice => { type => "string" },
    metadata => { type => "hash" },
    period => { type => "hash" },
    price => { type => "hash" },
    price_data => { type => "object" },
    quantity => { type => "integer" },
    subscription => { type => "string" },
    tax_rates => { type => "array" },
    unit_amount => { type => "integer" },
    unit_amount_decimal => { type => "decimal" },
    };
    $args = $self->_contract( 'invoiceitem', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "invoiceitems", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', $hash ) );
}
PERL
    # NOTE: invoiceitem_delete()
    invoiceitem_delete => <<'PERL',
sub invoiceitem_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'invoiceitem' } },
    };
    $args = $self->_contract( 'invoiceitem', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoiceitem id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "invoiceitems/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', $hash ) );
}
PERL
    # NOTE: invoiceitem_list()
    invoiceitem_list => <<'PERL',
sub invoiceitem_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list invoiceitem information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice::Item', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'invoiceitem' }, data_prefix_is_ok => 1 },
    created => { type => "hash" },
    customer => { type => "string" },
    ending_before => { type => "string" },
    invoice => { type => "string" },
    limit => { type => "string" },
    pending => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "invoiceitems", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', $hash ) );
}
PERL
    # NOTE: invoiceitem_retrieve()
    invoiceitem_retrieve => <<'PERL',
sub invoiceitem_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'invoiceitem' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'invoiceitem', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoiceitem id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "invoiceitems/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', $hash ) );
}
PERL
    # NOTE: invoiceitem_update()
    invoiceitem_update => <<'PERL',
sub invoiceitem_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'invoiceitem' } },
    amount => { type => "integer" },
    description => { type => "string" },
    discountable => { type => "boolean" },
    discounts => { type => "array" },
    metadata => { type => "hash" },
    period => { type => "hash" },
    price => { type => "hash" },
    price_data => { type => "object" },
    quantity => { type => "integer" },
    tax_rates => { type => "array" },
    unit_amount => { type => "integer" },
    unit_amount_decimal => { type => "decimal" },
    };
    $args = $self->_contract( 'invoiceitem', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No invoiceitem id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "invoiceitems/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', $hash ) );
}
PERL
    # NOTE: invoiceitems()
    invoiceitems => <<'PERL',
# <https://stripe.com/docs/api/invoiceitems>
sub invoiceitems
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'invoiceitem', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: invoices()
    invoices => <<'PERL',
# <https://stripe.com/docs/api/invoices>
sub invoices
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete finalise finalize invoice_write_off lines lines_upcoming list pay retrieve search send uncollectible upcoming update void )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'invoice', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: ip_address_location()
    ip_address_location => <<'PERL',
sub ip_address_location { CORE::return( shift->_response_to_object( 'Net::API::Stripe::GeoLocation', @_ ) ); }
PERL
    # NOTE: issuing_authorization()
    issuing_authorization => <<'PERL',
sub issuing_authorization { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Authorization', @_ ) ); }
PERL
    # NOTE: issuing_authorization_approve()
    issuing_authorization_approve => <<'PERL',
sub issuing_authorization_approve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.authorization' } },
    amount => { type => "integer" },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'issuing.authorization', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Authorization', $hash ) );
}
PERL
    # NOTE: issuing_authorization_decline()
    issuing_authorization_decline => <<'PERL',
sub issuing_authorization_decline
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.authorization' } },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'issuing.authorization', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Authorization', $hash ) );
}
PERL
    # NOTE: issuing_authorization_list()
    issuing_authorization_list => <<'PERL',
sub issuing_authorization_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list issuing authorization information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Issuing::Authorization', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.authorization' }, data_prefix_is_ok => 1 },
    card => { type => "hash" },
    cardholder => { type => "string" },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Authorization', $hash ) );
}
PERL
    # NOTE: issuing_authorization_retrieve()
    issuing_authorization_retrieve => <<'PERL',
sub issuing_authorization_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.authorization' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'issuing.authorization', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No issuing.authorization id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "issuing/authorizations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Authorization', $hash ) );
}
PERL
    # NOTE: issuing_authorization_update()
    issuing_authorization_update => <<'PERL',
sub issuing_authorization_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.authorization' } },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'issuing.authorization', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No issuing.authorization id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "issuing/authorizations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Authorization', $hash ) );
}
PERL
    # NOTE: issuing_authorizations()
    issuing_authorizations => <<'PERL',
# <https://stripe.com/docs/api/issuing/authorizations>
sub issuing_authorizations
{
    my $self = shift( @_ );
    my $allowed = [qw( approve decline list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'issuing_authorization', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: issuing_card()
    issuing_card => <<'PERL',
# sub issuing { CORE::return( shift->_instantiate( 'issuing', 'Net::API::Stripe::Issuing' ) ) }
sub issuing_card { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Card', @_ ) ); }
PERL
    # NOTE: issuing_card_create()
    issuing_card_create => <<'PERL',
sub issuing_card_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.card' } },
    cardholder => { type => "hash" },
    currency => { type => "string", required => 1 },
    metadata => { type => "hash" },
    replacement_for => { type => "string" },
    replacement_reason => { type => "string" },
    shipping => { type => "hash" },
    spending_controls => { type => "hash" },
    status => { type => "string" },
    type => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'issuing.card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card', $hash ) );
}
PERL
    # NOTE: issuing_card_deliver()
    issuing_card_deliver => <<'PERL',
sub issuing_card_deliver
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.card' } },
    };
    $args = $self->_contract( 'issuing.card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $card = CORE::delete( $args->{card} ) || CORE::return( $self->error( "No issuing.card id (with parameter 'card') was provided to deliver its information." ) );
    my $hash = $self->post( "test_helpers/issuing/cards/${card}/shipping", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card', $hash ) );
}
PERL
    # NOTE: issuing_card_fail()
    issuing_card_fail => <<'PERL',
sub issuing_card_fail
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.card' } },
    };
    $args = $self->_contract( 'issuing.card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $card = CORE::delete( $args->{card} ) || CORE::return( $self->error( "No issuing.card id (with parameter 'card') was provided to fail its information." ) );
    my $hash = $self->post( "test_helpers/issuing/cards/${card}/shipping", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card', $hash ) );
}
PERL
    # NOTE: issuing_card_list()
    issuing_card_list => <<'PERL',
sub issuing_card_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list issuing card information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Issuing::Card', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.card' }, data_prefix_is_ok => 1 },
    cardholder => { type => "hash" },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    exp_month => { type => "integer" },
    exp_year => { type => "integer" },
    last4 => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    type => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card', $hash ) );
}
PERL
    # NOTE: issuing_card_retrieve()
    issuing_card_retrieve => <<'PERL',
sub issuing_card_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.card' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'issuing.card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No issuing.card id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "issuing/cards/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card', $hash ) );
}
PERL
    # NOTE: issuing_card_return()
    issuing_card_return => <<'PERL',
sub issuing_card_return
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.card' } },
    };
    $args = $self->_contract( 'issuing.card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $card = CORE::delete( $args->{card} ) || CORE::return( $self->error( "No issuing.card id (with parameter 'card') was provided to return its information." ) );
    my $hash = $self->post( "test_helpers/issuing/cards/${card}/shipping", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card', $hash ) );
}
PERL
    # NOTE: issuing_card_ship()
    issuing_card_ship => <<'PERL',
sub issuing_card_ship
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.card' } },
    };
    $args = $self->_contract( 'issuing.card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $card = CORE::delete( $args->{card} ) || CORE::return( $self->error( "No issuing.card id (with parameter 'card') was provided to ship its information." ) );
    my $hash = $self->post( "test_helpers/issuing/cards/${card}/shipping", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card', $hash ) );
}
PERL
    # NOTE: issuing_card_update()
    issuing_card_update => <<'PERL',
sub issuing_card_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.card' } },
    cancellation_reason => { type => "string" },
    metadata => { type => "hash" },
    pin => { type => "object" },
    spending_controls => { type => "hash" },
    status => { type => "string" },
    };
    $args = $self->_contract( 'issuing.card', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No issuing.card id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "issuing/cards/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card', $hash ) );
}
PERL
    # NOTE: issuing_cardholder()
    issuing_cardholder => <<'PERL',
sub issuing_cardholder { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Card::Holder', @_ ) ); }
PERL
    # NOTE: issuing_cardholder_create()
    issuing_cardholder_create => <<'PERL',
sub issuing_cardholder_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.cardholder' } },
    billing => { type => "hash", required => 1 },
    company => { type => "hash" },
    email => { type => "string" },
    individual => { type => "hash" },
    metadata => { type => "hash" },
    name => { type => "string", required => 1 },
    phone_number => { type => "string" },
    spending_controls => { type => "hash" },
    status => { type => "string" },
    type => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'issuing.cardholder', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card::Holder', $hash ) );
}
PERL
    # NOTE: issuing_cardholder_list()
    issuing_cardholder_list => <<'PERL',
sub issuing_cardholder_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list issuing cardholder information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Issuing::Card::Holder', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.cardholder' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    email => { type => "string" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    phone_number => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    type => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card::Holder', $hash ) );
}
PERL
    # NOTE: issuing_cardholder_retrieve()
    issuing_cardholder_retrieve => <<'PERL',
sub issuing_cardholder_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.cardholder' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'issuing.cardholder', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No issuing.cardholder id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "issuing/cardholders/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card::Holder', $hash ) );
}
PERL
    # NOTE: issuing_cardholder_update()
    issuing_cardholder_update => <<'PERL',
sub issuing_cardholder_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.cardholder' } },
    billing => { type => "hash" },
    company => { type => "hash" },
    email => { type => "string" },
    individual => { type => "hash" },
    metadata => { type => "hash" },
    phone_number => { type => "string" },
    spending_controls => { type => "hash" },
    status => { type => "string" },
    };
    $args = $self->_contract( 'issuing.cardholder', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No issuing.cardholder id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "issuing/cardholders/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Card::Holder', $hash ) );
}
PERL
    # NOTE: issuing_cardholders()
    issuing_cardholders => <<'PERL',
# <https://stripe.com/docs/api/issuing/cardholders>
sub issuing_cardholders
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'issuing_cardholder', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: issuing_cards()
    issuing_cards => <<'PERL',
# <https://stripe.com/docs/api/issuing/cards>
sub issuing_cards
{
    my $self = shift( @_ );
    my $allowed = [qw( create deliver fail list retrieve return ship update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'issuing_card', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: issuing_dispute()
    issuing_dispute => <<'PERL',
sub issuing_dispute { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Dispute', @_ ) ); }
PERL
    # NOTE: issuing_dispute_create()
    issuing_dispute_create => <<'PERL',
sub issuing_dispute_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.dispute' } },
    evidence => { type => "hash" },
    metadata => { type => "hash" },
    transaction => { type => "string" },
    };
    $args = $self->_contract( 'issuing.dispute', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Dispute', $hash ) );
}
PERL
    # NOTE: issuing_dispute_list()
    issuing_dispute_list => <<'PERL',
sub issuing_dispute_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list issuing dispute information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Issuing::Dispute', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.dispute' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    transaction => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Dispute', $hash ) );
}
PERL
    # NOTE: issuing_dispute_retrieve()
    issuing_dispute_retrieve => <<'PERL',
sub issuing_dispute_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.dispute' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'issuing.dispute', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No issuing.dispute id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "issuing/disputes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Dispute', $hash ) );
}
PERL
    # NOTE: issuing_dispute_submit()
    issuing_dispute_submit => <<'PERL',
sub issuing_dispute_submit
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.dispute' } },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'issuing.dispute', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Dispute', $hash ) );
}
PERL
    # NOTE: issuing_dispute_update()
    issuing_dispute_update => <<'PERL',
sub issuing_dispute_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.dispute' } },
    evidence => { type => "hash" },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'issuing.dispute', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No issuing.dispute id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "issuing/disputes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Dispute', $hash ) );
}
PERL
    # NOTE: issuing_disputes()
    issuing_disputes => <<'PERL',
# <https://stripe.com/docs/api/issuing/disputes>
sub issuing_disputes
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve submit update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'issuing_dispute', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: issuing_transaction()
    issuing_transaction => <<'PERL',
sub issuing_transaction { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Transaction', @_ ) ); }
PERL
    # NOTE: issuing_transaction_list()
    issuing_transaction_list => <<'PERL',
sub issuing_transaction_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list issuing transaction information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Issuing::Transaction', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.transaction' }, data_prefix_is_ok => 1 },
    card => { type => "string" },
    cardholder => { type => "string" },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    type => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Transaction', $hash ) );
}
PERL
    # NOTE: issuing_transaction_retrieve()
    issuing_transaction_retrieve => <<'PERL',
sub issuing_transaction_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.transaction' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'issuing.transaction', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No issuing.transaction id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "issuing/transactions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Transaction', $hash ) );
}
PERL
    # NOTE: issuing_transaction_update()
    issuing_transaction_update => <<'PERL',
sub issuing_transaction_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'issuing.transaction' } },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'issuing.transaction', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No issuing.transaction id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "issuing/transactions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Issuing::Transaction', $hash ) );
}
PERL
    # NOTE: issuing_transactions()
    issuing_transactions => <<'PERL',
# <https://stripe.com/docs/api/issuing/transactions>
sub issuing_transactions
{
    my $self = shift( @_ );
    my $allowed = [qw( list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'issuing_transaction', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: item()
    item => <<'PERL',
sub item { CORE::return( shift->_response_to_object( 'Net::API::Stripe::List::Item', @_ ) ); }
PERL
    # NOTE: line_item()
    line_item => <<'PERL',
sub line_item { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice::LineItem', @_ ) ); }
PERL
    # NOTE: line_item_lines()
    line_item_lines => <<'PERL',
sub line_item_lines
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to lines line item information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice::LineItem', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'line_item' }, data_prefix_is_ok => 1 },
    automatic_tax => { type => "hash" },
    coupon => { type => "string" },
    currency => { type => "string" },
    customer => { type => "string" },
    customer_details => { type => "hash" },
    discounts => { type => "array" },
    ending_before => { type => "string" },
    invoice_items => { type => "string" },
    limit => { type => "string" },
    schedule => { type => "string" },
    starting_after => { type => "string" },
    subscription => { type => "string" },
    subscription_billing_cycle_anchor => { type => "string" },
    subscription_cancel_at => { type => "string" },
    subscription_cancel_at_period_end => { type => "string" },
    subscription_cancel_now => { type => "string" },
    subscription_default_tax_rates => { type => "string" },
    subscription_items => { type => "string" },
    subscription_proration_behavior => { type => "string" },
    subscription_proration_date => { type => "string" },
    subscription_start_date => { type => "string" },
    subscription_trial_end => { type => "string" },
    subscription_trial_from_plan => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->get( "invoices/upcoming", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice::LineItem', $hash ) );
}
PERL
    # NOTE: line_items()
    line_items => <<'PERL',
# <https://stripe.com/docs/api/invoices>
sub line_items
{
    my $self = shift( @_ );
    my $allowed = [qw( lines )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'line_item', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: location()
    location => <<'PERL',
sub location { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Terminal::Location', @_ ) ); }
PERL
    # NOTE: login_link()
    login_link => <<'PERL',
sub login_link { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::LoginLink', @_ ) ); }
PERL
    # NOTE: login_link_create()
    login_link_create => <<'PERL',
sub login_link_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'login_link' } },
    };
    $args = $self->_contract( 'login_link', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to create its information." ) );
    my $hash = $self->post( "accounts/${id}/login_links", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Account::LoginLink', $hash ) );
}
PERL
    # NOTE: login_links()
    login_links => <<'PERL',
# <https://stripe.com/docs/api/accounts>
sub login_links
{
    my $self = shift( @_ );
    my $allowed = [qw( create )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'login_link', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: mandate()
    mandate => <<'PERL',
sub mandate { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Mandate' ) ) }
PERL
    # NOTE: mandate_retrieve()
    mandate_retrieve => <<'PERL',
sub mandate_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve a mandate" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Mandate', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{mandate} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No mandate id was provided to retrieve its information." ) );
    my $hash = $self->get( "mandates/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Mandate', $hash ) );
}
PERL
    # NOTE: mandates()
    mandates => <<'PERL',
sub mandates
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( retrieve )];
    my $meth = $self->_get_method( 'mandate', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: merchant_data()
    merchant_data => <<'PERL',
sub merchant_data { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::MerchantData', @_ ) ); }
PERL
    # NOTE: next_action()
    next_action => <<'PERL',
sub next_action { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Intent::NextAction', @_ ) ); }
PERL
    # NOTE: order()
    order => <<'PERL',
sub order { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Order' ) ) }
PERL
    # NOTE: order_item()
    order_item => <<'PERL',
sub order_item { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Order::Item' ) ) }
PERL
    # NOTE: outcome()
    outcome => <<'PERL',
sub outcome { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Charge::Outcome', @_ ) ); }
PERL
    # NOTE: owner()
    owner => <<'PERL',
sub owner { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Source::Owner', @_ ) ); }
PERL
    # NOTE: package_dimensions()
    package_dimensions => <<'PERL',
sub package_dimensions { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Order::SKU::PackageDimensions', @_ ) ); }
PERL
    # NOTE: payment_intent()
    payment_intent => <<'PERL',
# subs to access child packages
sub payment_intent { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Intent', @_ ) ); }
PERL
    # NOTE: payment_intent_apply_customer_balance()
    payment_intent_apply_customer_balance => <<'PERL',
sub payment_intent_apply_customer_balance
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'payment_intent' } },
    amount => { type => "integer" },
    currency => { type => "string" },
    };
    $args = $self->_contract( 'payment_intent', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment_intent id (with parameter 'id') was provided to apply_customer_balance its information." ) );
    my $hash = $self->post( "payment_intents/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_cancel()
    payment_intent_cancel => <<'PERL',
sub payment_intent_cancel
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to cancel a payment intent" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_intent} },
    amount_to_capture => {},
    cancellation_reason => { type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    };

    $args = $self->_contract( 'payment_intent', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment intent id was provided to cancel it." ) );
    my $hash = $self->post( "payment_intents/${id}/cancel", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_capture()
    payment_intent_capture => <<'PERL',
sub payment_intent_capture
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to capture a payment intent" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_intent} },
    amount_to_capture => { type => "integer" },
    application_fee_amount => { type => "integer" },
    id => { re => qr/^\w+$/, required => 1 },
    statement_descriptor => { type => "string" },
    statement_descriptor_suffix => { type => "string" },
    transfer_data => { fields => ["amount"], type => "hash" },
    };

    $args = $self->_contract( 'payment_intent', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment intent id was provided to capture it." ) );
    my $hash = $self->post( "payment_intents/${id}/capture", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_confirm()
    payment_intent_confirm => <<'PERL',
sub payment_intent_confirm
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to confirm a payment intent" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_intent} },
    capture_method => { type => "string" },
    error_on_requires_action => { type => "boolean" },
    id => { re => qr/^\w+$/, required => 1 },
    mandate => { type => "string" },
    mandate_data => {
        fields => [
                      "customer_acceptance.accepted_at",
                      "customer_acceptance.offline",
                      "customer_acceptance.online",
                      "customer_acceptance.online.ip_address",
                      "customer_acceptance.online.user_agent",
                      "customer_acceptance.type",
                  ],
        type   => "hash",
    },
    off_session => { type => "string" },
    payment_method => { package => "Net::API::Stripe::Payment::Method", type => "string" },
    payment_method_data => {
        fields => [
                      "alipay",
                      "au_becs_debit",
                      "au_becs_debit.account_number!",
                      "au_becs_debit.bsb_number!",
                      "bacs_debit",
                      "bacs_debit.account_number",
                      "bacs_debit.sort_code",
                      "bancontact",
                      "billing_details",
                      "billing_details.address",
                      "billing_details.address.city",
                      "billing_details.address.country",
                      "billing_details.address.line1",
                      "billing_details.address.line2",
                      "billing_details.address.postal_code",
                      "billing_details.address.state",
                      "billing_details.email",
                      "billing_details.name",
                      "billing_details.phone",
                      "eps",
                      "fpx",
                      "fpx.bank!",
                      "giropay",
                      "grabpay",
                      "ideal",
                      "ideal.bank",
                      "interac_present",
                      "metadata",
                      "oxxo",
                      "p24",
                      "p24.bank",
                      "sepa_debit",
                      "sepa_debit.iban!",
                      "sofort",
                      "sofort.country!",
                      "type",
                  ],
        type   => "object",
    },
    payment_method_options => {
        fields => [
                      "alipay",
                      "bancontact",
                      "bancontact.preferred_language",
                      "card",
                      "card.cvc_token",
                      "card.installments",
                      "card.installments.enabled",
                      "card.installments.plan",
                      "card.installments.plan.count!",
                      "card.installments.plan.interval!",
                      "card.installments.plan.type!",
                      "card.network",
                      "card.request_three_d_secure",
                      "oxxo.expires_after_days",
                      "p24",
                      "sepa_debit",
                      "sepa_debit.mandate_options",
                      "sofort",
                      "sofort.preferred_language",
                      "type",
                  ],
        type   => "hash",
    },
    payment_method_types => { type => "array" },
    radar_options => { type => "object" },
    receipt_email => { type => "string" },
    return_url => { type => "string" },
    setup_future_usage => { type => "string" },
    shipping => { package => "Net::API::Stripe::Shipping", type => "hash" },
    use_stripe_sdk => { type => "boolean" },
    };

    $args = $self->_contract( 'payment_intent', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment intent id was provided to confirm it." ) );
    my $hash = $self->post( "payment_intents/${id}/confirm", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_create()
    payment_intent_create => <<'PERL',
sub payment_intent_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a payment intent" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_intent} },
    amount => { required => 1, type => "integer" },
    application_fee_amount => { type => "integer" },
    automatic_payment_methods => { type => "hash" },
    capture_method => { type => "string" },
    confirm => { required => 1, type => "boolean" },
    confirmation_method => { type => "string" },
    currency => { required => 1, type => "string" },
    customer => { re => qr/^\w+$/, type => "string" },
    description => { type => "string" },
    error_on_requires_action => { type => "boolean" },
    mandate => { re => qr/^\w+$/, type => "string" },
    mandate_data => {
        fields => [
                      "customer_acceptance!",
                      "customer_acceptance.type!",
                      "customer_acceptance.accepted_at",
                      "customer_acceptance.offline",
                      "customer_acceptance.online",
                      "customer_acceptance.online.ip_address!",
                      "customer_acceptance.online.user_agent!",
                  ],
        type   => "object",
    },
    metadata => { type => "hash" },
    off_session => { type => "boolean" },
    on_behalf_of => { re => qr/^\w+$/, type => "string" },
    payment_method => { re => qr/^\w+$/, type => "string" },
    payment_method_data => {
        fields => [
                      "alipay",
                      "au_becs_debit",
                      "au_becs_debit.account_number!",
                      "au_becs_debit.bsb_number!",
                      "bacs_debit",
                      "bacs_debit.account_number",
                      "bacs_debit.sort_code",
                      "bancontact",
                      "billing_details",
                      "billing_details.address",
                      "billing_details.address.city",
                      "billing_details.address.country",
                      "billing_details.address.line1",
                      "billing_details.address.line2",
                      "billing_details.address.postal_code",
                      "billing_details.address.state",
                      "billing_details.email",
                      "billing_details.name",
                      "billing_details.phone",
                      "eps",
                      "fpx",
                      "fpx.bank!",
                      "giropay",
                      "grabpay",
                      "ideal",
                      "ideal.bank",
                      "interac_present",
                      "metadata",
                      "oxxo",
                      "p24",
                      "p24.bank",
                      "sepa_debit",
                      "sepa_debit.iban!",
                      "sofort",
                      "sofort.country!",
                      "type!",
                  ],
        type   => "object",
    },
    payment_method_options => {
        fields => [
                      "alipay",
                      "bancontact",
                      "bancontact.preferred_language",
                      "card",
                      "card.cvc_token",
                      "card.installments",
                      "card.installments.enabled",
                      "card.installments.plan",
                      "card.installments.plan.count!",
                      "card.installments.plan.interval!",
                      "card.installments.plan.type!",
                      "card.network",
                      "card.request_three_d_secure",
                      "oxxo.expires_after_days",
                      "p24",
                      "sepa_debit",
                      "sepa_debit.mandate_options",
                      "sofort",
                      "sofort.preferred_language",
                      "type",
                  ],
        type   => "hash",
    },
    payment_method_types => { type => "array" },
    radar_options => { type => "object" },
    receipt_email => { type => "string" },
    return_url => { type => "string" },
    setup_future_usage => { type => "string" },
    shipping => {
        fields => ["address!", "carrier", "name!", "phone", "tracking_number"],
        type   => "hash",
    },
    statement_descriptor => { type => "string" },
    statement_descriptor_suffix => { type => "string" },
    transfer_data => { type => "hash" },
    transfer_group => { type => "string" },
    use_stripe_sdk => { type => "boolean" },
    };

    $args = $self->_contract( 'payment_intent', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'payment_intents', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_increment()
    payment_intent_increment => <<'PERL',
sub payment_intent_increment
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to increment a payment intent" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent', @_ );
    my $okParams = 
    {
    expandable              => { allowed => $EXPANDABLES->{payment_intent} },
    id                      => { re => qr/^\w+$/, required => 1 },
    amount                  => { re => qr/^\d+$/, required => 1 },
    description             => { re => qr/^.*?$/ },
    metadata                => {},
    application_fee_amount  => { re => qr/^\d+$/ },
    transfer_data           => { fields => [qw( amount )] },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment intent id was provided to increment it." ) );
    my $hash = $self->post( "payment_intents/${id}/increment_authorization", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_increment_authorization()
    payment_intent_increment_authorization => <<'PERL',
sub payment_intent_increment_authorization
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'payment_intent' } },
    amount => { type => "integer", required => 1 },
    application_fee_amount => { type => "integer" },
    description => { type => "string" },
    metadata => { type => "hash" },
    transfer_data => { type => "hash" },
    };
    $args = $self->_contract( 'payment_intent', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment_intent id (with parameter 'id') was provided to increment_authorization its information." ) );
    my $hash = $self->post( "payment_intents/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_list()
    payment_intent_list => <<'PERL',
sub payment_intent_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_intent}, data_prefix_is_ok => 1 },
    created => qr/^\d+$/,
    'created.gt' => qr/^\d+$/,
    'created.gte' => qr/^\d+$/,
    'created.lt' => qr/^\d+$/,
    'created.lte' => qr/^\d+$/,
    customer => { type => "string" },
    ending_before => qr/^\w+$/,
    limit => qr/^\d+$/,
    starting_after => qr/^\w+$/,
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'payment_methods', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: payment_intent_reconcile()
    payment_intent_reconcile => <<'PERL',
sub payment_intent_reconcile
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to reconcile a customer balance payment intent" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent', @_ );
    my $okParams = 
    {
    expandable              => { allowed => $EXPANDABLES->{payment_intent} },
    id                      => { re => qr/^\w+$/, required => 1 },
    amount                  => { re => qr/^\d+$/ },
    currency                => { re => qr/^[a-zA-Z]{3}$/ },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment intent id was provided to reconcile its customer balance." ) );
    my $hash = $self->post( "payment_intents/${id}/apply_customer_balance", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_retrieve()
    payment_intent_retrieve => <<'PERL',
sub payment_intent_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve a payment intent" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_intent}, data_prefix_is_ok => 1 },
    client_secret => { required => 1, type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment intent id was provided to retrieve it." ) );
    my $hash = $self->get( "payment_intents/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_search()
    payment_intent_search => <<'PERL',
sub payment_intent_search
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to search payment intents." ) ) if( !scalar( @_ ) );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_intent}, data_prefix_is_ok => 1 },
    limit => qr/^\d+$/,
    page => qr/^\d+$/,
    query => { re => qr/^.*?$/, required => 1, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "payment_methods/search", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: payment_intent_update()
    payment_intent_update => <<'PERL',
sub payment_intent_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a payment intent" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_intent} },
    amount => { required => 1, type => "integer" },
    application_fee_amount => { type => "integer" },
    capture_method => { type => "string" },
    currency => { type => "string" },
    customer => { re => qr/^\w+$/, type => "string" },
    description => { type => "string" },
    metadata => { type => "hash" },
    payment_method => { re => qr/^\w+$/, type => "string" },
    payment_method_data => {
        fields => [
                      "alipay",
                      "au_becs_debit",
                      "au_becs_debit.account_number!",
                      "au_becs_debit.bsb_number!",
                      "bacs_debit",
                      "bacs_debit.account_number",
                      "bacs_debit.sort_code",
                      "bancontact",
                      "billing_details",
                      "billing_details.address",
                      "billing_details.address.city",
                      "billing_details.address.country",
                      "billing_details.address.line1",
                      "billing_details.address.line2",
                      "billing_details.address.postal_code",
                      "billing_details.address.state",
                      "billing_details.email",
                      "billing_details.name",
                      "billing_details.phone",
                      "eps",
                      "fpx",
                      "fpx.bank!",
                      "giropay",
                      "grabpay",
                      "ideal",
                      "ideal.bank",
                      "interac_present",
                      "metadata",
                      "oxxo",
                      "p24",
                      "p24.bank",
                      "sepa_debit",
                      "sepa_debit.iban!",
                      "sofort",
                      "sofort.country!",
                      "type!",
                  ],
        type   => "object",
    },
    payment_method_options => {
        fields => [
                      "alipay",
                      "bancontact",
                      "bancontact.preferred_language",
                      "card",
                      "card.cvc_token",
                      "card.installments",
                      "card.installments.enabled",
                      "card.installments.plan",
                      "card.installments.plan.count!",
                      "card.installments.plan.interval!",
                      "card.installments.plan.type!",
                      "card.network",
                      "card.request_three_d_secure",
                      "oxxo.expires_after_days",
                      "p24",
                      "sepa_debit",
                      "sepa_debit.mandate_options",
                      "sofort",
                      "sofort.preferred_language",
                      "type",
                  ],
        type   => "hash",
    },
    payment_method_types => { type => "array" },
    receipt_email => { type => "string" },
    setup_future_usage => { type => "string" },
    shipping => {
        fields => ["address!", "carrier", "name!", "phone", "tracking_number"],
        type   => "hash",
    },
    statement_descriptor => { type => "string" },
    statement_descriptor_suffix => { type => "string" },
    transfer_data => { type => "hash" },
    transfer_group => { type => "string" },
    };

    $args = $self->_contract( 'payment_intent', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment intent id was provided to capture it." ) );
    my $hash = $self->post( "payment_intents/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_verify()
    payment_intent_verify => <<'PERL',
sub payment_intent_verify
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to verify microdeposits on a payment intent" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent', @_ );
    my $okParams = 
    {
    expandable              => { allowed => $EXPANDABLES->{payment_intent} },
    id                      => { re => qr/^\w+$/, required => 1 },
    client_secret           => {},
    amounts                 => { type => 'array', re => qr/^\d+$/ },
    descriptor_code         => { re => qr/^.*?$/ },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment intent id was provided to verify microdeposits on it." ) );
    my $hash = $self->post( "payment_intents/${id}/verify_microdeposits", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intent_verify_microdeposits()
    payment_intent_verify_microdeposits => <<'PERL',
sub payment_intent_verify_microdeposits
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to verify_microdeposits payment intent information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'payment_intent' } },
    amounts => { type => "array" },
    client_secret => { type => "string", required => 1 },
    descriptor_code => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment_intent id (with parameter 'id') was provided to verify_microdeposits its information." ) );
    my $hash = $self->post( "payment_intents/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent', $hash ) );
}
PERL
    # NOTE: payment_intents()
    payment_intents => <<'PERL',
# <https://stripe.com/docs/api/payment_intents>
sub payment_intents
{
    my $self = shift( @_ );
    my $allowed = [qw( apply_customer_balance cancel capture confirm create increment increment_authorization list reconcile retrieve search update verify verify_microdeposits )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'payment_intent', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: payment_link()
    payment_link => <<'PERL',
sub payment_link { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Link', @_ ) ); }
PERL
    # NOTE: payment_link_create()
    payment_link_create => <<'PERL',
sub payment_link_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a payment link." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Link', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_link} },
    after_completion => {
        fields => [
                      "type!",
                      "hosted_confirmation",
                      "hosted_confirmation.custom_message",
                      "redirect",
                      "redirect.url!",
                  ],
        type   => "hash",
    },
    allow_promotion_codes => { type => "boolean" },
    application_fee_amount => { type => "integer" },
    application_fee_percent => { type => "decimal" },
    automatic_tax => { fields => ["enabled!"], type => "hash" },
    billing_address_collection => { type => "string" },
    consent_collection => { fields => ["promotions"], type => "hash" },
    currency => { type => "currency" },
    customer_creation => { type => "string" },
    line_items => {
        fields => [
            "price!",
            "quantity!",
            "adjustable_quantity.enabled!",
            "adjustable_quantity.maximum",
            "adjustable_quantity.minimum",
        ],
        required => 1,
        type => "array",
    },
    metadata => { type => "hash" },
    on_behalf_of => { re => qr/^\w+$/, type => "string" },
    payment_intent_data => { fields => ["capture_method", "setup_future_usage"], type => "hash" },
    payment_method_collection => { type => "string" },
    payment_method_type => { type => "string" },
    payment_method_types => { type => "array" },
    phone_number_collection => { fields => ["enabled!"], type => "hash" },
    shipping_address_collection => { fields => ["allowed_countries"], type => "hash" },
    shipping_options => { fields => ["shipping_rate"], type => "array" },
    submit_type => { type => "string" },
    subscription_data => { fields => ["trial_period_days"], type => "hash" },
    tax_id_collection => { fields => ["enabled"], type => "hash" },
    transfer_data => { fields => ["destination!", "amount"], type => "hash" },
    };

    $args = $self->_contract( 'payment_link', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'payment_links', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Link', $hash ) );
}
PERL
    # NOTE: payment_link_items()
    payment_link_items => <<'PERL',
sub payment_link_items
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve payment link information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Link', @_ );
    my $okParams = 
    {
    expandable      => { allowed => $EXPANDABLES->{payment_link} },
    id              => { re => qr/^\w+$/, required => 1 },
    ending_before   => { re => qr/^\w+$/ },
    limit           => { re => qr/^\d+$/ },
    starting_after  => { re => qr/^\w+$/ },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No product id was provided to retrieve its information." ) );
    my $hash = $self->get( "payment_links/${id}/line_items", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: payment_link_line_items()
    payment_link_line_items => <<'PERL',
sub payment_link_line_items
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to line_items payment link information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Link', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'payment_link' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment_link id (with parameter 'id') was provided to line_items its information." ) );
    my $hash = $self->get( "payment_links/${id}/line_items", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Link', $hash ) );
}
PERL
    # NOTE: payment_link_list()
    payment_link_list => <<'PERL',
sub payment_link_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_link}, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    arrival_date => { re => qr/^\d+$/ },
    'arrival_date.gt' => { re => qr/^\d+$/ },
    'arrival_date.gte' => { re => qr/^\d+$/ },
    'arrival_date.lt' => { re => qr/^\d+$/ },
    'arrival_date.lte' => { re => qr/^\d+$/ },
    created => { re => qr/^\d+$/ },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    destination => { re => qr/^\w+$/ },
    ending_before => { re => qr/^\w+$/, type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    starting_after => { re => qr/^\w+$/, type => "string" },
    status => { re => qr/^(pending|paid|failed|canceled)$/ },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'payment_links', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: payment_link_retrieve()
    payment_link_retrieve => <<'PERL',
sub payment_link_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve payment link information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Link', @_ );
    my $okParams = 
    {
    expandable => { allowed => $EXPANDABLES->{payment_link} },
    id => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment link id was provided to retrieve its information." ) );
    my $hash = $self->get( "payment_links/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Link', $hash ) );
}
PERL
    # NOTE: payment_link_update()
    payment_link_update => <<'PERL',
sub payment_link_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a payment link" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payout', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_link} },
    active => { type => "boolean" },
    after_completion => { type => "hash" },
    allow_promotion_codes => { type => "boolean" },
    automatic_tax => { type => "hash" },
    billing_address_collection => { type => "string" },
    customer_creation => { type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    line_items => { type => "hash" },
    metadata => { type => "hash" },
    payment_method_collection => { type => "string" },
    payment_method_types => { type => "array" },
    shipping_address_collection => { type => "hash" },
    };

    $args = $self->_contract( 'payment_link', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment id was provided to update its details" ) );
    my $hash = $self->post( "payment_links/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payout', $hash ) );
}
PERL
    # NOTE: payment_links()
    payment_links => <<'PERL',
# <https://stripe.com/docs/api/payment_links/payment_links>
sub payment_links
{
    my $self = shift( @_ );
    my $allowed = [qw( create items line_items list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'payment_link', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: payment_method()
    payment_method => <<'PERL',
sub payment_method { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Method', @_ ) ); }
PERL
    # NOTE: payment_method_attach()
    payment_method_attach => <<'PERL',
sub payment_method_attach
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to attach a payment method" ) ) if( !scalar( @_ ) );
    my $args;
    if( $self->_is_object( $_[0] ) )
    {
        if( $_[0]->isa( 'Net::API::Stripe::Customer' ) )
        {
            $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
            my $obj = $args->{_object};
            $args->{customer} = $obj->id;
            $args->{id} = $obj->payment_method->id if( $obj->payment_method );
        }
        elsif( $_[0]->isa( 'Net::API::Stripe::Payment::Method' ) )
        {
            $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
        }
    }
    else
    {
        $args = $self->_get_args( @_ );
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_method} },
    customer => { re => qr/^\w+$/, required => 1, type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    };

    $args = $self->_contract( 'payment_method', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment method id was provided to attach to attach it to the customer with id \"$args->{customer}\"." ) );
    my $hash = $self->post( "payment_methods/${id}/attach", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}
PERL
    # NOTE: payment_method_create()
    payment_method_create => <<'PERL',
sub payment_method_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a payment_method" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_method} },
    acss_debit => { type => "hash" },
    affirm => { type => "hash" },
    afterpay_clearpay => { type => "hash" },
    alipay => { type => "hash" },
    au_becs_debit => { type => "hash" },
    bacs_debit => { type => "hash" },
    bancontact => { type => "hash" },
    billing_details => {
        fields => [
                      "address.city",
                      "address.country",
                      "address.line1",
                      "address.line2",
                      "address.postal_code",
                      "address.state",
                      "email",
                      "name",
                      "phone",
                  ],
        type   => "hash",
    },
    blik => { type => "hash" },
    boleto => { type => "hash" },
    card => {
        fields => ["exp_month", "exp_year", "number", "cvc"],
        type   => "hash",
    },
    customer_balance => { type => "hash" },
    eps => { type => "hash" },
    fpx => { fields => ["bank"], type => "hash" },
    giropay => { type => "hash" },
    grabpay => { type => "hash" },
    ideal => { fields => ["bank"], type => "hash" },
    interac_present => { type => "hash" },
    klarna => { type => "hash" },
    konbini => { type => "hash" },
    link => { type => "hash" },
    metadata => { type => "hash" },
    oxxo => { type => "hash" },
    p24 => { type => "hash" },
    paynow => { type => "hash" },
    promptpay => { type => "hash" },
    radar_options => { type => "hash" },
    sepa_debit => { fields => ["iban"], type => "hash" },
    sofort => { type => "hash" },
    type => {
        re => qr/^(?:card|fpx|ideal|sepa_debit)$/,
        required => 1,
        type => "string",
    },
    us_bank_account => { type => "hash" },
    wechat_pay => { type => "hash" },
    };

    $args = $self->_contract( 'payment_method', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'payment_methods', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}
PERL
    # NOTE: payment_method_detach()
    payment_method_detach => <<'PERL',
# https://stripe.com/docs/api/payment_methods/detach
sub payment_method_detach
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to detach a payment method." ) ) if( !scalar( @_ ) );
    my $args;
    if( $self->_is_object( $_[0] ) )
    {
        if( $_[0]->isa( 'Net::API::Stripe::Customer' ) )
        {
            $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
            my $obj = $args->{_object};
            $args->{customer} = $obj->id;
            if( $obj->payment_method )
            {
                $args->{id} = $obj->payment_method->id;
            }
            elsif( $obj->invoice_settings->default_payment_method )
            {
                $args->{id} = $obj->invoice_settings->default_payment_method->id;
            }
            CORE::return( $self->error( "No payent method id could be found in this customer object." ) ) if( !$args->{id} );
        }
        elsif( $_[0]->isa( 'Net::API::Stripe::Payment::Method' ) )
        {
            $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
        }
    }
    else
    {
        $args = $self->_get_args( @_ );
    }
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{payment_method} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment method id was provided to attach it to the customer with id \"$args->{customer}\"." ) );
    my $hash = $self->post( "payment_methods/${id}/detach", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}
PERL
    # NOTE: payment_method_details()
    payment_method_details => <<'PERL',
sub payment_method_details { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Method::Details', @_ ) ); }
PERL
    # NOTE: payment_method_list()
    payment_method_list => <<'PERL',
sub payment_method_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_method}, data_prefix_is_ok => 1 },
    customer => { required => 1, type => "string" },
    ending_before => { type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    starting_after => { type => "string" },
    type => {
        re => qr/^(?:card|fpx|ideal|sepa_debit)$/,
        required => 1,
        type => "string",
    },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'payment_methods', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: payment_method_list_customer_payment_methods()
    payment_method_list_customer_payment_methods => <<'PERL',
sub payment_method_list_customer_payment_methods
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list_customer_payment_methods payment method information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'payment_method' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    type => { type => "string", required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $customer = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id (with parameter 'customer') was provided to list_customer_payment_methods its information." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "customers/${customer}/payment_methods", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}
PERL
    # NOTE: payment_method_retrieve()
    payment_method_retrieve => <<'PERL',
sub payment_method_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve payment method information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{payment_method} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment method id was provided to retrieve its information." ) );
    my $hash = $self->get( "payment_methods/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}
PERL
    # NOTE: payment_method_retrieve_customer_payment_method()
    payment_method_retrieve_customer_payment_method => <<'PERL',
sub payment_method_retrieve_customer_payment_method
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve_customer_payment_method payment method information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'payment_method' }, data_prefix_is_ok => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $customer = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id (with parameter 'customer') was provided to retrieve_customer_payment_method its information." ) );
    my $payment_method = CORE::delete( $args->{payment_method} ) || CORE::return( $self->error( "No payment_method id (with parameter 'payment_method') was provided to retrieve_customer_payment_method its information." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "customers/${customer}/payment_methods/${payment_method}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}
PERL
    # NOTE: payment_method_update()
    payment_method_update => <<'PERL',
# https://stripe.com/docs/api/payment_methods/update
sub payment_method_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a payment method" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payment_method} },
    billing_details => {
        fields => [
                      "address.city",
                      "address.country",
                      "address.line1",
                      "address.line2",
                      "address.postal_code",
                      "address.state",
                      "email",
                      "name",
                      "phone",
                  ],
        type   => "hash",
    },
    card => { fields => ["exp_month", "exp_year"], type => "hash" },
    id => { re => qr/^\w+$/, required => 1 },
    link => { type => "hash" },
    metadata => { type => "hash" },
    sepa_debit => { fields => ["iban"] },
    us_bank_account => { type => "hash" },
    };

    $args = $self->_contract( 'payment_method', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payment method id was provided to update payment method's details" ) );
    my $hash = $self->post( "payment_methods/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}
PERL
    # NOTE: payment_methods()
    payment_methods => <<'PERL',
# <https://stripe.com/docs/api/payment_methods>
sub payment_methods
{
    my $self = shift( @_ );
    my $allowed = [qw( attach create detach list list_customer_payment_methods retrieve retrieve_customer_payment_method update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'payment_method', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: payout()
    payout => <<'PERL',
sub payout { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payout', @_ ) ); }
PERL
    # NOTE: payout_cancel()
    payout_cancel => <<'PERL',
sub payout_cancel
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to cancel a payout" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payout', @_ );
    my $okParams = 
    {
    expandable              => { allowed => $EXPANDABLES->{payout} },
    id                      => { re => qr/^\w+$/, required => 1 },
    };
    $args = $self->_contract( 'payout', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payout id was provided to cancel it." ) );
    my $hash = $self->post( "payouts/${id}/cancel", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payout', $hash ) );
}
PERL
    # NOTE: payout_create()
    payout_create => <<'PERL',
sub payout_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a payout" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payout', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payout} },
    amount => { required => 1, type => "integer" },
    currency => { required => 1, type => "string" },
    description => { type => "string" },
    destination => { re => qr/^\w+$/, type => "string" },
    metadata => { type => "hash" },
    method => { re => qr/^(standard|instant)$/, type => "string" },
    source_type => { re => qr/^(bank_account|card|fpx)$/, type => "string" },
    statement_descriptor => { type => "string" },
    };

    $args = $self->_contract( 'payout', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'payouts', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payout', $hash ) );
}
PERL
    # NOTE: payout_list()
    payout_list => <<'PERL',
sub payout_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{payout}, data_prefix_is_ok => 1 },
    arrival_date => { re => qr/^\d+$/, type => "timestamp" },
    'arrival_date.gt' => { re => qr/^\d+$/ },
    'arrival_date.gte' => { re => qr/^\d+$/ },
    'arrival_date.lt' => { re => qr/^\d+$/ },
    'arrival_date.lte' => { re => qr/^\d+$/ },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    destination => { re => qr/^\w+$/, type => "string" },
    ending_before => { re => qr/^\w+$/, type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    starting_after => { re => qr/^\w+$/, type => "string" },
    status => { re => qr/^(pending|paid|failed|canceled)$/, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'payment_methods', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: payout_retrieve()
    payout_retrieve => <<'PERL',
sub payout_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve payout information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payout', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{payout} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payout id was provided to retrieve its information." ) );
    my $hash = $self->get( "payouts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payout', $hash ) );
}
PERL
    # NOTE: payout_reverse()
    payout_reverse => <<'PERL',
sub payout_reverse
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to reverse payout information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payout', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{payout} },
    id          => { re => qr/^\w+$/, required => 1 },
    metadata    => { type => 'hash' },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payout id was provided to reverse it." ) );
    my $hash = $self->get( "payouts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payout', $hash ) );
}
PERL
    # NOTE: payout_update()
    payout_update => <<'PERL',
sub payout_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a payout" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payout', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{payout} },
    id                  => { re => qr/^\w+$/, required => 1 },
    metadata            => { type => 'hash' },
    };
    $args = $self->_contract( 'payout', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No payout id was provided to update its details" ) );
    my $hash = $self->post( "payouts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payout', $hash ) );
}
PERL
    # NOTE: payouts()
    payouts => <<'PERL',
sub payouts
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update list cancel reverse )];
    my $meth = $self->_get_method( 'payout', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: period()
    period => <<'PERL',
sub period { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Period', @_ ) ); }
PERL
    # NOTE: person()
    person => <<'PERL',
sub person { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Person', @_ ) ); }
PERL
    # NOTE: person_create()
    person_create => <<'PERL',
sub person_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'person' } },
    address => { type => "hash" },
    address_kana => { type => "hash" },
    address_kanji => { type => "hash" },
    dob => { type => "hash" },
    documents => { type => "object" },
    email => { type => "string" },
    first_name => { type => "string" },
    first_name_kana => { type => "string" },
    first_name_kanji => { type => "string" },
    full_name_aliases => { type => "array" },
    gender => { type => "string" },
    id_number => { type => "string" },
    id_number_secondary => { type => "string" },
    last_name => { type => "string" },
    last_name_kana => { type => "string" },
    last_name_kanji => { type => "string" },
    maiden_name => { type => "string" },
    metadata => { type => "hash" },
    nationality => { type => "string" },
    person_token => { type => "string" },
    phone => { type => "string" },
    political_exposure => { type => "string" },
    registered_address => { type => "hash" },
    relationship => { type => "hash" },
    ssn_last_4 => { type => "string" },
    verification => { type => "hash" },
    };
    $args = $self->_contract( 'person', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to create its information." ) );
    my $hash = $self->post( "accounts/${id}/persons", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Person', $hash ) );
}
PERL
    # NOTE: person_delete()
    person_delete => <<'PERL',
sub person_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'person' } },
    };
    $args = $self->_contract( 'person', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to delete its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No person id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "accounts/${parent_id}/persons/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Person', $hash ) );
}
PERL
    # NOTE: person_list()
    person_list => <<'PERL',
sub person_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list person information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::Person', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'person' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    relationship => { type => "hash" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No account id (with parameter 'id') was provided to list its information." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "accounts/${id}/persons", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Person', $hash ) );
}
PERL
    # NOTE: person_retrieve()
    person_retrieve => <<'PERL',
sub person_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'person' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'person', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to retrieve its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No person id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "accounts/${parent_id}/persons/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Person', $hash ) );
}
PERL
    # NOTE: person_token_create()
    person_token_create => <<'PERL',
sub person_token_create { CORE::return( shift->token_create( @_ ) ); }
PERL
    # NOTE: person_update()
    person_update => <<'PERL',
sub person_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'person' } },
    address => { type => "hash" },
    address_kana => { type => "hash" },
    address_kanji => { type => "hash" },
    dob => { type => "hash" },
    documents => { type => "object" },
    email => { type => "string" },
    first_name => { type => "string" },
    first_name_kana => { type => "string" },
    first_name_kanji => { type => "string" },
    full_name_aliases => { type => "array" },
    gender => { type => "string" },
    id_number => { type => "string" },
    id_number_secondary => { type => "string" },
    last_name => { type => "string" },
    last_name_kana => { type => "string" },
    last_name_kanji => { type => "string" },
    maiden_name => { type => "string" },
    metadata => { type => "hash" },
    nationality => { type => "string" },
    person_token => { type => "string" },
    phone => { type => "string" },
    political_exposure => { type => "string" },
    registered_address => { type => "hash" },
    relationship => { type => "hash" },
    ssn_last_4 => { type => "string" },
    verification => { type => "hash" },
    };
    $args = $self->_contract( 'person', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No account id (with parameter 'parent_id') was provided to update its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No person id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "accounts/${parent_id}/persons/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Person', $hash ) );
}
PERL
    # NOTE: persons()
    persons => <<'PERL',
# <https://stripe.com/docs/api/persons>
sub persons
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'person', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: pii_token_create()
    pii_token_create => <<'PERL',
sub pii_token_create { CORE::return( shift->token_create( @_ ) ); }
PERL
    # NOTE: plan()
    plan => <<'PERL',
sub plan { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Plan', @_ ) ); }
PERL
    # NOTE: plan_by_product()
    plan_by_product => <<'PERL',
# Find plan by product id or nickname
sub plan_by_product
{
    my $self = shift( @_ );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product', @_ );
    my $id = CORE::delete( $args->{id} );
    my $nickname = CORE::delete( $args->{nickname} );
    CORE::return( $self->error( "No product id or plan name was provided to find its related product." ) ) if( !$id && !$nickname );
    $args->{product} = $id if( $id );
    my $check_both_active_and_inactive = 0;
    if( !CORE::length( $args->{active} ) )
    {
        $check_both_active_and_inactive++;
        $args->{active} = $self->true;
    }
    my $list = $self->plans( list => $args ) || CORE::return( $self->pass_error );
    my $objects = [];
    while( my $this = $list->next )
    {
        # If this was specified, this is a restrictive query
        if( $nickname && $this->nickname eq $nickname )
        {
            CORE::push( @$objects, $this );
        }
        # or at least we have this
        elsif( $id )
        {
            CORE::push( @$objects, $this );
        }
    }
    # Now, we also have to check for inactive plans, because Stripe requires the active parameter to be provided or else it defaults to inactive
    # How inefficient...
    if( $check_both_active_and_inactive )
    {
        $args->{active} = $self->false;
        my $list = $self->plans( list => $args ) || CORE::return( $self->pass_error );
        my $objects = [];
        while( my $this = $list->next )
        {
            if( $nickname && $this->nickname eq $nickname )
            {
                CORE::push( @$objects, $this );
            }
            elsif( $id )
            {
                CORE::push( @$objects, $this );
            }
        }
    }
    CORE::return( $objects );
}
PERL
    # NOTE: plan_create()
    plan_create => <<'PERL',
sub plan_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a plan" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Plan', @_ );
    my $obj = $args->{_object};
    if( $self->_is_object( $args->{product} ) && $args->{product}->isa( 'Net::API::Stripe::Product' ) )
    {
        my $prod_hash = $args->{product}->as_hash({ json => 1 });
        $args->{product} = $prod_hash;
    }
    #exit;
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{plan} },
    active => { type => "boolean" },
    aggregate_usage => { type => "string" },
    amount => { required => 1, type => "integer" },
    amount_decimal => { type => "decimal" },
    billing_scheme => { type => "string" },
    currency => { required => 1, type => "string" },
    id => { type => "string" },
    interval => { re => qr/^(?:day|week|month|year)$/, required => 1, type => "string" },
    interval_count => { type => "integer" },
    metadata => { type => "hash" },
    nickname => { type => "string" },
    product => { required => 1, type => "string" },
    tiers => {
        fields => [
                      "up_to",
                      "flat_amount",
                      "flat_amount_decimal",
                      "unit_amount",
                      "unit_amount_decimal",
                  ],
        type   => "array",
    },
    tiers_mode => { re => qr/^(graduated|volume)$/, type => "string" },
    transform_usage => { fields => ["divide_by", "round"], type => "hash" },
    trial_period_days => { type => "integer" },
    usage_type => { re => qr/^(?:metered|licensed)$/, type => "string" },
    };

    $args = $self->_contract( 'plan', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'plans', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Plan', $hash ) );
}
PERL
    # NOTE: plan_delete()
    plan_delete => <<'PERL',
# https://stripe.com/docs/api/customers/delete?lang=curl
# "Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer."
sub plan_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete plan information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Plan', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{plan} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No plan id was provided to delete its information." ) );
    my $hash = $self->delete( "plans/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Plan', $hash ) );
}
PERL
    # NOTE: plan_list()
    plan_list => <<'PERL',
sub plan_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    if( $self->_is_object( $args->{product} ) && $args->{product}->isa( 'Net::API::Stripe::Product' ) )
    {
        my $prod_hash = $args->{product}->as_hash({ json => 1 });
        $args->{product} = $prod_hash->{id} ? $prod_hash->{id} : undef();
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{plan}, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    ending_before => { type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    product => { re => qr/^\w+$/, type => "string" },
    starting_after => { type => "string" },
    };

    foreach my $bool ( qw( active ) )
    {
        next if( !CORE::length( $args->{ $bool } ) );
        $args->{ $bool } = ( $args->{ $bool } eq 'true' || ( $args->{ $bool } ne 'false' && $args->{ $bool } ) ) ? 'true' : 'false';
    }
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'plans', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: plan_retrieve()
    plan_retrieve => <<'PERL',
sub plan_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve plan information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Plan', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{plan} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No plan id was provided to retrieve its information." ) );
    my $hash = $self->get( "plans/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Plan', $hash ) );
}
PERL
    # NOTE: plan_update()
    plan_update => <<'PERL',
# https://stripe.com/docs/api/customers/update?lang=curl
sub plan_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a plan" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Plan', @_ );
    if( $self->_is_object( $args->{product} ) && $args->{product}->isa( 'Net::API::Stripe::Product' ) )
    {
        $args->{product} = $args->{product}->id;
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{plan} },
    active => { re => qr/^(?:true|False)$/, type => "boolean" },
    id => { required => 1 },
    metadata => { type => "hash" },
    nickname => { type => "string" },
    product => { re => qr/^\w+$/, type => "string" },
    trial_period_days => { type => "integer" },
    };

    $args = $self->_contract( 'plan', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No plan id was provided to update plan's details" ) );
    my $hash = $self->post( "plans/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Plan', $hash ) );
}
PERL
    # NOTE: plans()
    plans => <<'PERL',
sub plans
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update list delete )];
    my $meth = $self->_get_method( 'plan', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: portal_configuration()
    portal_configuration => <<'PERL',
sub portal_configuration { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Plan', @_ ) ); }
PERL
    # NOTE: portal_configuration_create()
    portal_configuration_create => <<'PERL',
sub portal_configuration_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a portal configuration" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::PortalConfiguration', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{portal_configuration} },
    business_profile    => { fields => [qw( headline privacy_policy_url terms_of_service_url )], required => 1 },
    default_return_url  => { type => 'utl' },
    features            => { fields => [qw(
            customer_update.enabled!
            customer_update.allowed_updates
            invoice_history.enabled!
            payment_method_update.enabled!
            subscription_cancel.enabled!
            subscription_cancel.cancellation_reason.enabled!
            subscription_cancel.cancellation_reason.options!
            subscription_cancel.mode
            subscription_cancel.proration_behavior
            subscription_pause.enabled
            subscription_update.default_allowed_updates!
            subscription_update.enabled!
            subscription_update.products!
            subscription_update.proration_behavior
        )], required => 1 },
    metadata            => { type => 'hash' },
    };
    $args = $self->_contract( 'portal_configuration', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'billing_portal/configurations', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::PortalConfiguration', $hash ) );
}
PERL
    # NOTE: portal_configuration_list()
    portal_configuration_list => <<'PERL',
sub portal_configuration_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{portal_configuration}, data_prefix_is_ok => 1 },
    active              => { type => 'boolean' },
    is_default          => { type => 'boolean' },
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    ending_before       => {},
    limit               => { re => qr/^\d+$/ },
    starting_after      => {},
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'billing_portal/configurations', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: portal_configuration_retrieve()
    portal_configuration_retrieve => <<'PERL',
sub portal_configuration_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve the portal configuration." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::PortalConfiguration', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{portal_configuration} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No portal configuration id was provided to retrieve its information." ) );
    my $hash = $self->get( "billing_portal/configurations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::PortalConfiguration', $hash ) );
}
PERL
    # NOTE: portal_configuration_update()
    portal_configuration_update => <<'PERL',
# https://stripe.com/docs/api/customers/update?lang=curl
sub portal_configuration_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a portal configuration" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::PortalConfiguration', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{portal_configuration} },
    id                  => { required => 1 },
    active              => { type => 'boolean' },
    business_profile    => { fields => [qw( headline privacy_policy_url terms_of_service_url )] },
    default_return_url  => { type => 'utl' },
    features            => { fields => [qw(
            customer_update.enabled customer_update.allowed_updates
            invoice_history.enabled!
            payment_method_update.enabled!
            subscription_cancel.enabled
                subscription_cancel.cancellation_reason.enabled!
                subscription_cancel.cancellation_reason.options
            subscription_cancel.mode
            subscription_cancel.proration_behavior
            subscription_pause.enabled
            subscription_update.default_allowed_updates
            subscription_update.enabled
            subscription_update.products
            subscription_update.proration_behavior
        )] },
    metadata            => { type => 'hash' },
    };
    $args = $self->_contract( 'portal_configuration', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No portal configuration id was provided to update its information." ) );
    my $hash = $self->post( "billing_portal/configurations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::PortalConfiguration', $hash ) );
}
PERL
    # NOTE: portal_configurations()
    portal_configurations => <<'PERL',
sub portal_configurations
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update list )];
    my $meth = $self->_get_method( 'plan', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: portal_session()
    portal_session => <<'PERL',
sub portal_session { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::PortalSession', @_ ) ); }
PERL
    # NOTE: portal_session_create()
    portal_session_create => <<'PERL',
sub portal_session_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a portal session" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::PortalSession', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{portal_session} },
    customer            => { re => qr/^\w+$/, required => 1 },
    configuration       => { re => qr/^\w+$/ },
    locale              => {},
    on_behalf_of        => { re => qr/^\w+$/ },
    return_url          => { type => 'url' },
    };
    $args = $self->_contract( 'portal_session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'billing_portal/sessions', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::PortalSession', $hash ) );
}
PERL
    # NOTE: portal_sessions()
    portal_sessions => <<'PERL',
sub portal_sessions
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create )];
    my $meth = $self->_get_method( 'plan', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: price()
    price => <<'PERL',
sub price { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Price', @_ ) ); }
PERL
    # NOTE: price_create()
    price_create => <<'PERL',
sub price_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a price" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Price', @_ );
    my $obj = $args->{_object};
    if( $self->_is_object( $args->{product} ) && $args->{product}->isa( 'Net::API::Stripe::Product' ) )
    {
        my $prod_hash = $args->{product}->as_hash({ json => 1 });
        $args->{product} = $prod_hash;
    }
    #exit;
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{price} },
    active => { type => "boolean" },
    billing_scheme => { type => "string" },
    currency => { required => 1, type => "string" },
    currency_options => { type => "hash" },
    custom_unit_amount => { type => "hash" },
    id => {},
    lookup_key => { type => "string" },
    metadata => { type => "hash" },
    nickname => { type => "string" },
    product => { required => 1, type => "string" },
    product_data => {
        fields => [
                      "id",
                      "name",
                      "active",
                      "metadata",
                      "statement_descriptor",
                      "unit_label",
                  ],
        type   => "object",
    },
    recurring => {
        fields => [
                      "interval",
                      "aggregate_usage",
                      "interval_count",
                      "trial_period_days",
                      "usage_type",
                  ],
        type   => "hash",
    },
    tax_behavior => { type => "string" },
    tiers => {
        fields => [
                      "up_to",
                      "flat_amount",
                      "flat_amount_decimal",
                      "unit_amount",
                      "unit_amount_decimal",
                  ],
        type   => "array",
    },
    tiers_mode => { re => qr/^(graduated|volume)$/, type => "string" },
    transfer_lookup_key => { type => "boolean" },
    transform_quantity => { fields => ["divide_by", "round"], type => "hash" },
    unit_amount => { required => 1, type => "integer" },
    unit_amount_decimal => { type => "decimal" },
    };

    $args = $self->_contract( 'price', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'prices', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Price', $hash ) );
}
PERL
    # NOTE: price_list()
    price_list => <<'PERL',
sub price_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    if( $self->_is_object( $args->{product} ) && $args->{product}->isa( 'Net::API::Stripe::Product' ) )
    {
        my $prod_hash = $args->{product}->as_hash({ json => 1 });
        $args->{product} = $prod_hash->{id} ? $prod_hash->{id} : undef();
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{price}, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    currency => { type => "string" },
    ending_before => { type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    lookup_keys => { type => "string" },
    product => { re => qr/^\w+$/, type => "string" },
    recurring => { fields => ["interval", "usage_type"], type => "hash" },
    starting_after => { type => "string" },
    type => { type => "string" },
    };

    foreach my $bool ( qw( active ) )
    {
        next if( !CORE::length( $args->{ $bool } ) );
        $args->{ $bool } = ( $args->{ $bool } eq 'true' || ( $args->{ $bool } ne 'false' && $args->{ $bool } ) ) ? 'true' : 'false';
    }
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'prices', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: price_retrieve()
    price_retrieve => <<'PERL',
sub price_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve price information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Price', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{price} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No price id was provided to retrieve its information." ) );
    my $hash = $self->get( "prices/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Price', $hash ) );
}
PERL
    # NOTE: price_search()
    price_search => <<'PERL',
sub price_search
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to search for a price information." ) ) if( !scalar( @_ ) );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{price}, data_prefix_is_ok => 1 },
    limit => qr/^\d+$/,
    page => qr/^\d+$/,
    query => { re => qr/^.*?$/, required => 1, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "prices/search", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product', $hash ) );
}
PERL
    # NOTE: price_update()
    price_update => <<'PERL',
# https://stripe.com/docs/api/customers/update?lang=curl
sub price_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a price object" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Price', @_ );
    if( $self->_is_object( $args->{product} ) && $args->{product}->isa( 'Net::API::Stripe::Product' ) )
    {
        $args->{product} = $args->{product}->id;
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{price} },
    active => { re => qr/^(?:true|False)$/, type => "boolean" },
    currency_options => { type => "hash" },
    id => { required => 1 },
    lookup_key => { type => "string" },
    metadata => { type => "hash" },
    nickname => { type => "string" },
    recurring => {
        fields => [
            "interval",
            "aggregate_usage",
            "interval_count",
            "trial_period_days",
            "usage_type",
        ],
    },
    tax_behavior => { type => "string" },
    transfer_lookup_key => { type => "boolean" },
    };

    $args = $self->_contract( 'price', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No price id was provided to update price's details" ) );
    my $hash = $self->post( "prices/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Price', $hash ) );
}
PERL
    # NOTE: prices()
    prices => <<'PERL',
# <https://stripe.com/docs/api/prices>
sub prices
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve search update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'price', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: product()
    product => <<'PERL',
sub product { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Product', @_ ) ); }
PERL
    # NOTE: product_by_name()
    product_by_name => <<'PERL',
sub product_by_name
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $name = CORE::delete( $args->{name} );
    my $nickname = CORE::delete( $args->{nickname} );
    my $list = $self->products( list => $args ) || CORE::return( $self->pass_error );
    my $objects = [];
    while( my $this = $list->next )
    {
        if( ( $name && $this->name eq $name ) ||
            ( $nickname && $this->nickname eq $nickname ) )
        {
            CORE::push( @$objects, $this );
        }
    }
    CORE::return( $objects );
}
PERL
    # NOTE: product_create()
    product_create => <<'PERL',
sub product_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a product" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{product} },
    active => { type => "boolean" },
    attributes => sub { ... },
    caption => {},
    deactivate_on => { type => "array" },
    default_price_data => { type => "object" },
    description => { type => "string" },
    id => { type => "string" },
    images => sub { ... },
    metadata => { type => "hash" },
    name => { required => 1, type => "string" },
    package_dimensions => { type => "hash" },
    shippable => { type => "boolean" },
    statement_descriptor => { type => "string" },
    tax_code => { type => "string" },
    type => { re => qr/^(good|service)$/, required => 1 },
    unit_label => { type => "string" },
    url => { type => "string" },
    };

    $args = $self->_contract( 'product', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'products', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product', $hash ) );
}
PERL
    # NOTE: product_delete()
    product_delete => <<'PERL',
# https://stripe.com/docs/api/customers/delete?lang=curl
# "Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer."
sub product_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete product information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product', @_ );
    my $okParams = 
    {
    expandable => { allowed => $EXPANDABLES->{product} },
    id => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No product id was provided to delete its information." ) );
    my $hash = $self->delete( "products/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product', $hash ) );
}
PERL
    # NOTE: product_list()
    product_list => <<'PERL',
sub product_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{product}, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    ending_before => { type => "string" },
    ids => { type => "array" },
    limit => { re => qr/^\d+$/, type => "string" },
    shippable => { type => "boolean" },
    starting_after => { type => "string" },
    type => {},
    url => { type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'products', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: product_retrieve()
    product_retrieve => <<'PERL',
sub product_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve product information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product', @_ );
    my $okParams = 
    {
    expandable => { allowed => $EXPANDABLES->{product} },
    id => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No product id was provided to retrieve its information." ) );
    my $hash = $self->get( "products/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product', $hash ) );
}
PERL
    # NOTE: product_search()
    product_search => <<'PERL',
sub product_search
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to search for a product information." ) ) if( !scalar( @_ ) );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{product}, data_prefix_is_ok => 1 },
    limit => qr/^\d+$/,
    page => qr/^\d+$/,
    query => { re => qr/^.*?$/, required => 1, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "products/search", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product', $hash ) );
}
PERL
    # NOTE: product_update()
    product_update => <<'PERL',
# https://stripe.com/docs/api/customers/update?lang=curl
sub product_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a product" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{product} },
    HASH(0x55bef17244e8) => "type",
    HASH(0x55bef172f668) => undef,
    HASH(0x55bef17416b8) => "unit_label",
    HASH(0x55bef174e1e8) => "statement_descriptor",
    HASH(0x55bef17598f0) => "url",
    HASH(0x55bef27d6400) => "shippable",
    active => { type => "boolean" },
    attributes => sub { ... },
    caption => {},
    deactivate_on => { type => "array" },
    default_price => { type => "string" },
    description => { type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    images => sub { ... },
    metadata => { type => "hash" },
    name => "HASH(0x55bef173a200)package_dimensions",
    package_dimensions => { type => "hash" },
    shippable => { type => "boolean" },
    statement_descriptor => { type => "string" },
    tax_code => { type => "string" },
    unit_label => { type => "string" },
    url => { type => "string" },
    };

    $args = $self->_contract( 'product', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No product id was provided to update product's details" ) );
    my $hash = $self->post( "products/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product', $hash ) );
}
PERL
    # NOTE: products()
    products => <<'PERL',
sub products
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update list delete search )];
    my $meth = $self->_get_method( 'product', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: promotion_code()
    promotion_code => <<'PERL',
sub promotion_code { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Product::PromotionCode', @_ ) ); }
PERL
    # NOTE: promotion_code_create()
    promotion_code_create => <<'PERL',
sub promotion_code_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a promotion code" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product::PromotionCode', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{promotion_code} },
    active => { type => "boolean" },
    code => { re => qr/^.*?$/, type => "string" },
    coupon => { re => qr/^\w+$/, required => 1, type => "hash" },
    customer => { re => qr/^\w+$/, type => "string" },
    expires_at => { type => "timestamp" },
    max_redemptions => { type => "integer" },
    metadata => { type => "hash" },
    restrictions => {
        fields => [
                      "restrictions.first_time_transaction",
                      "restrictions.minimum_amount",
                      "restrictions.minimum_amount_currency",
                  ],
        type   => "hash",
    },
    };

    $args = $self->_contract( 'promotion_code', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'promotion_codes', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product::PromotionCode', $hash ) );
}
PERL
    # NOTE: promotion_code_list()
    promotion_code_list => <<'PERL',
sub promotion_code_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{promotion_code}, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    code => { re => qr/^.*?$/, type => "string" },
    coupon => { re => qr/^\w+$/, type => "hash" },
    created => qr/^\d+$/,
    'created.gt' => qr/^\d+$/,
    'created.gte' => qr/^\d+$/,
    'created.lt' => qr/^\d+$/,
    'created.lte' => qr/^\d+$/,
    customer => { re => qr/^\w+$/, type => "string" },
    ending_before => qr/^\w+$/,
    limit => qr/^\d+$/,
    starting_after => qr/^\w+$/,
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'promotion_codes', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: promotion_code_retrieve()
    promotion_code_retrieve => <<'PERL',
sub promotion_code_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve promotion code information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product::PromotionCode', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{promotion_code} },
    id          => { re => qr/^\S+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No promotion code id was provided to retrieve its information." ) );
    my $hash = $self->get( "promotion_codes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product::PromotionCode', $hash ) );
}
PERL
    # NOTE: promotion_code_update()
    promotion_code_update => <<'PERL',
sub promotion_code_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a promotion code" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product::PromotionCode', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{promotion_code} },
    active => { type => "boolean" },
    id => { re => qr/^\S+$/, required => 1 },
    metadata => { type => "hash" },
    restrictions => { type => "hash" },
    };

    $args = $self->_contract( 'promotion_code', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No promotion code id was provided to update its details" ) );
    my $hash = $self->post( "promotion_codes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product::PromotionCode', $hash ) );
}
PERL
    # NOTE: promotion_codes()
    promotion_codes => <<'PERL',
sub promotion_codes
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update list )];
    my $meth = $self->_get_method( 'promotion_code', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: quote()
    quote => <<'PERL',
sub quote { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Quote', @_ ) ); }
PERL
    # NOTE: quote_accept()
    quote_accept => <<'PERL',
sub quote_accept
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to accept a quote." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Quote', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{quote} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No quote id was provided to accept it." ) );
    my $hash = $self->post( "quotes/${id}/accept", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Quote', $hash ) );
}
PERL
    # NOTE: quote_cancel()
    quote_cancel => <<'PERL',
sub quote_cancel
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to cancel a quote." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Quote', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{quote} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No quote id was provided to cancel it." ) );
    my $hash = $self->post( "quotes/${id}/cancel", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Quote', $hash ) );
}
PERL
    # NOTE: quote_create()
    quote_create => <<'PERL',
sub quote_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a quote" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Quote', @_ );
    my $obj = $args->{_object};
    if( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) )
    {
        $args->{customer} = $args->{customer}->id;
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{quote} },
    application_fee_amount => { type => "integer" },
    application_fee_percent => { type => "decomal" },
    automatic_tax => { fields => ["enabled!"], type => "hash" },
    collection_method => { type => "string" },
    customer => { re => qr/^\w+$/, type => "string" },
    default_tax_rates => { type => "array" },
    description => { type => "string" },
    discounts => { fields => ["coupon", "discount"], type => "array" },
    expires_at => { type => "datetime" },
    footer => { type => "string" },
    from_quote => { fields => ["qoute!", "is_revision"], type => "hash" },
    header => { type => "string" },
    invoice_settings => { fields => ["days_until_due"], type => "hash" },
    line_items => {
        fields => [
                      "price",
                      "price_data",
                      "price_data.currency!",
                      "price_data.product!",
                      "price_data.unit_amount_decimal!",
                      "price_data.recurring.interval!",
                      "price_data.recurring.interval_count",
                      "price_data.tax_behavior",
                      "price_data.unit_amount",
                      "quantity",
                      "tax_rates",
                  ],
        type   => "hash",
    },
    metadata => { type => "hash" },
    on_behalf_of => { re => qr/^\w+$/, type => "string" },
    subscription_data => { fields => ["effective_date", "trial_period_days"], type => "hash" },
    test_clock => { re => qr/^\w+$/, type => "string" },
    transfer_data => {
        fields => ["destination!", "amount", "amount_percent"],
        type   => "hash",
    },
    };

    $args = $self->_contract( 'quote', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'quotes', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Quote', $hash ) );
}
PERL
    # NOTE: quote_download()
    quote_download => <<'PERL',
sub quote_download
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to download quote as pdf." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Quote', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{quote} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No quote id was provided to download it as pdf." ) );
    $args->{_file_api} = 1;
    my $hash = $self->get( "quotes/${id}/pdf", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Quote', $hash ) );
}
PERL
    # NOTE: quote_finalize()
    quote_finalize => <<'PERL',
sub quote_finalize
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to finalize a quote." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Quote', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{quote} },
    id          => { re => qr/^\w+$/, required => 1 },
    expires_at  => { type => 'datetime' },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No quote id was provided to finalize it." ) );
    my $hash = $self->post( "quotes/${id}/finalize", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Quote', $hash ) );
}
PERL
    # NOTE: quote_line_items()
    quote_line_items => <<'PERL',
sub quote_line_items
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to line_items quote information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Quote', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'quote' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No quote id (with parameter 'id') was provided to line_items its information." ) );
    my $hash = $self->get( "quotes/${id}/line_items", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Quote', $hash ) );
}
PERL
    # NOTE: quote_lines()
    quote_lines => <<'PERL',
sub quote_lines
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve a quote line items." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_as_hash( @_ );
    if( $self->_is_object( $args->{quote} ) && $args->{quote}->isa( 'Net::API::Stripe::Billing::Quote' ) )
    {
        $args->{id} = $args->{quote}->id;
    }
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{quote} },
    id                  => { re => qr/^\w+$/, required => 1 },
    ending_before       => {},
    limit               => { re => qr/^\d+$/ },
    starting_after      => {},
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No quote id was provided to retrieve its line items." ) );
    my $hash = $self->get( "quotes/${id}/line_items", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: quote_list()
    quote_list => <<'PERL',
sub quote_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    if( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) )
    {
        $args->{customer} = $args->{customer}->id;
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{quote}, data_prefix_is_ok => 1 },
    customer => { re => qr/^\w+$/, type => "string" },
    ending_before => { type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    test_clock => { type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'quotes', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: quote_retrieve()
    quote_retrieve => <<'PERL',
sub quote_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve quote information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Quote', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{quote} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No quote id was provided to retrieve its information." ) );
    my $hash = $self->get( "quotes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Quote', $hash ) );
}
PERL
    # NOTE: quote_update()
    quote_update => <<'PERL',
# https://stripe.com/docs/api/quotes/update
sub quote_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a quote" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Quote', @_ );
    if( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) )
    {
        $args->{customer} = $args->{customer}->id;
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{quote} },
    application_fee_amount => { type => "integer" },
    application_fee_percent => { type => "decomal" },
    automatic_tax => { fields => ["enabled!"], type => "hash" },
    collection_method => { type => "string" },
    customer => { re => qr/^\w+$/, type => "string" },
    default_tax_rates => { type => "array" },
    description => { type => "string" },
    discounts => { fields => ["coupon", "discount"], type => "array" },
    expires_at => { type => "datetime" },
    footer => { type => "string" },
    from_quote => { fields => ["qoute!", "is_revision"] },
    header => { type => "string" },
    id => { required => 1 },
    invoice_settings => { fields => ["days_until_due"], type => "hash" },
    line_items => {
        fields => [
                      "id",
                      "price",
                      "price_data",
                      "price_data.currency!",
                      "price_data.product!",
                      "price_data.unit_amount_decimal!",
                      "price_data.recurring.interval!",
                      "price_data.recurring.interval_count",
                      "price_data.tax_behavior",
                      "price_data.unit_amount",
                      "quantity",
                      "tax_rates",
                  ],
        type   => "hash",
    },
    metadata => { type => "hash" },
    on_behalf_of => { re => qr/^\w+$/, type => "string" },
    subscription_data => { fields => ["effective_date", "trial_period_days"], type => "hash" },
    test_clock => { re => qr/^\w+$/ },
    transfer_data => {
        fields => ["destination!", "amount", "amount_percent"],
        type   => "hash",
    },
    };

    $args = $self->_contract( 'quote', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No quote id was provided to update quote's details" ) );
    my $hash = $self->post( "quotes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Quote', $hash ) );
}
PERL
    # NOTE: quote_upfront_line_items()
    quote_upfront_line_items => <<'PERL',
sub quote_upfront_line_items
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to upfront_line_items quote information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Quote', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'quote' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No quote id (with parameter 'id') was provided to upfront_line_items its information." ) );
    my $hash = $self->get( "quotes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Quote', $hash ) );
}
PERL
    # NOTE: quote_upfront_lines()
    quote_upfront_lines => <<'PERL',
sub quote_upfront_lines
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve a quote upfront line items." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_as_hash( @_ );
    if( $self->_is_object( $args->{quote} ) && $args->{quote}->isa( 'Net::API::Stripe::Billing::Quote' ) )
    {
        $args->{id} = $args->{quote}->id;
    }
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{quote} },
    id                  => { re => qr/^\w+$/, required => 1 },
    ending_before       => {},
    limit               => { re => qr/^\d+$/ },
    starting_after      => {},
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No quote id was provided to retrieve its upfront line items." ) );
    my $hash = $self->get( "quotes/${id}/computed_upfront_line_items", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: quotes()
    quotes => <<'PERL',
# <https://stripe.com/docs/api/quotes>
sub quotes
{
    my $self = shift( @_ );
    my $allowed = [qw( accept cancel create download finalize line_items lines list retrieve update upfront_line_items upfront_lines )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'quote', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: radar_early_fraud_warning()
    radar_early_fraud_warning => <<'PERL',
sub radar_early_fraud_warning { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Fraud', @_ ) ); }
PERL
    # NOTE: radar_early_fraud_warning_list()
    radar_early_fraud_warning_list => <<'PERL',
sub radar_early_fraud_warning_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list radar early fraud warning information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Fraud', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.early_fraud_warning' }, data_prefix_is_ok => 1 },
    charge => { type => "string" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    payment_intent => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud', $hash ) );
}
PERL
    # NOTE: radar_early_fraud_warning_retrieve()
    radar_early_fraud_warning_retrieve => <<'PERL',
sub radar_early_fraud_warning_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.early_fraud_warning' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'radar.early_fraud_warning', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No radar.early_fraud_warning id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "radar/early_fraud_warnings/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud', $hash ) );
}
PERL
    # NOTE: radar_early_fraud_warnings()
    radar_early_fraud_warnings => <<'PERL',
# <https://stripe.com/docs/api/radar/early_fraud_warnings>
sub radar_early_fraud_warnings
{
    my $self = shift( @_ );
    my $allowed = [qw( list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'radar_early_fraud_warning', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: radar_value_list()
    radar_value_list => <<'PERL',
sub radar_value_list { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Fraud::ValueList', @_ ) ); }
PERL
    # NOTE: radar_value_list_create()
    radar_value_list_create => <<'PERL',
sub radar_value_list_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.value_list' } },
    alias => { type => "string", required => 1 },
    item_type => { type => "string" },
    metadata => { type => "hash" },
    name => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'radar.value_list', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::ValueList', $hash ) );
}
PERL
    # NOTE: radar_value_list_delete()
    radar_value_list_delete => <<'PERL',
sub radar_value_list_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.value_list' } },
    };
    $args = $self->_contract( 'radar.value_list', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No radar.value_list id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "radar/value_lists/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::ValueList', $hash ) );
}
PERL
    # NOTE: radar_value_list_item()
    radar_value_list_item => <<'PERL',
sub radar_value_list_item { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Fraud::ValueList::Item', @_ ) ); }
PERL
    # NOTE: radar_value_list_item_create()
    radar_value_list_item_create => <<'PERL',
sub radar_value_list_item_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.value_list_item' } },
    value => { type => "string", required => 1 },
    value_list => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'radar.value_list_item', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::ValueList::Item', $hash ) );
}
PERL
    # NOTE: radar_value_list_item_delete()
    radar_value_list_item_delete => <<'PERL',
sub radar_value_list_item_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.value_list_item' } },
    };
    $args = $self->_contract( 'radar.value_list_item', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No radar.value_list_item id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "radar/value_list_items/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::ValueList::Item', $hash ) );
}
PERL
    # NOTE: radar_value_list_item_list()
    radar_value_list_item_list => <<'PERL',
sub radar_value_list_item_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list radar value list item information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Fraud::ValueList::Item', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.value_list_item' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    value => { type => "string" },
    value_list => { type => "string", required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::ValueList::Item', $hash ) );
}
PERL
    # NOTE: radar_value_list_item_retrieve()
    radar_value_list_item_retrieve => <<'PERL',
sub radar_value_list_item_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.value_list_item' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'radar.value_list_item', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No radar.value_list_item id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "radar/value_list_items/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::ValueList::Item', $hash ) );
}
PERL
    # NOTE: radar_value_list_items()
    radar_value_list_items => <<'PERL',
# <https://stripe.com/docs/api/radar/value_list_items>
sub radar_value_list_items
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'radar_value_list_item', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: radar_value_list_list()
    radar_value_list_list => <<'PERL',
sub radar_value_list_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list radar value list information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Fraud::ValueList', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.value_list' }, data_prefix_is_ok => 1 },
    alias => { type => "string" },
    contains => { type => "string" },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::ValueList', $hash ) );
}
PERL
    # NOTE: radar_value_list_retrieve()
    radar_value_list_retrieve => <<'PERL',
sub radar_value_list_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.value_list' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'radar.value_list', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No radar.value_list id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "radar/value_lists/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::ValueList', $hash ) );
}
PERL
    # NOTE: radar_value_list_update()
    radar_value_list_update => <<'PERL',
sub radar_value_list_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'radar.value_list' } },
    alias => { type => "string" },
    metadata => { type => "hash" },
    name => { type => "string" },
    };
    $args = $self->_contract( 'radar.value_list', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No radar.value_list id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "radar/value_lists/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::ValueList', $hash ) );
}
PERL
    # NOTE: radar_value_lists()
    radar_value_lists => <<'PERL',
# <https://stripe.com/docs/api/radar/value_lists>
sub radar_value_lists
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'radar_value_list', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: reader()
    reader => <<'PERL',
sub reader { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Terminal::Reader' ) ) }
PERL
    # NOTE: receiver()
    receiver => <<'PERL',
sub receiver { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Source::Receiver', @_ ) ); }
PERL
    # NOTE: redirect()
    redirect => <<'PERL',
sub redirect { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Source::Redirect', @_ ) ); }
PERL
    # NOTE: refund()
    refund => <<'PERL',
sub refund { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Refund', @_ ) ); }
PERL
    # NOTE: refund_cancel()
    refund_cancel => <<'PERL',
sub refund_cancel
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to cancel a refund." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Refund', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{refund} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No refund id was provided to cancel." ) );
    my $hash = $self->post( "refunds/${id}/cancel", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Refund', $hash ) );
}
PERL
    # NOTE: refund_create()
    refund_create => <<'PERL',
sub refund_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a payout" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Refund', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{refund} },
    amount => { required => 1, type => "integer" },
    charge => { re => qr/^\w+$/, type => "string" },
    metadata => { type => "hash" },
    payment_intent => { re => qr/^\w+$/, type => "string" },
    reason => {
        re => qr/^(duplicate|fraudulent|requested_by_customer)$/,
        type => "string",
    },
    refund_application_fee => { type => "boolean" },
    reverse_transfer => { type => "boolean" },
    };

    $args = $self->_contract( 'refund', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'refunds', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Refund', $hash ) );
}
PERL
    # NOTE: refund_list()
    refund_list => <<'PERL',
sub refund_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{refund}, data_prefix_is_ok => 1 },
    charge => { re => qr/^\w+$/, type => "string" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    ending_before => { re => qr/^\w+$/, type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    payment_intent => { re => qr/^\w+$/, type => "string" },
    starting_after => { re => qr/^\w+$/, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'refunds', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: refund_retrieve()
    refund_retrieve => <<'PERL',
sub refund_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve refund information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Refund', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{refund} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No refund id was provided to retrieve its information." ) );
    my $hash = $self->get( "refunds/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Refund', $hash ) );
}
PERL
    # NOTE: refund_update()
    refund_update => <<'PERL',
sub refund_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a refund" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Refund', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{refund} },
    id                  => { re => qr/^\w+$/, required => 1 },
    metadata            => { type => 'hash' },
    };
    $args = $self->_contract( 'refund', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No refund id was provided to update its details" ) );
    my $hash = $self->post( "refunds/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Refund', $hash ) );
}
PERL
    # NOTE: refunds()
    refunds => <<'PERL',
sub refunds
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update cancel list )];
    my $meth = $self->_get_method( 'refund', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: relationship()
    relationship => <<'PERL',
sub relationship { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::Relationship', @_ ) ); }
PERL
    # NOTE: reporting_report_run()
    reporting_report_run => <<'PERL',
sub reporting_report_run { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Reporting::ReportRun', @_ ) ); }
PERL
    # NOTE: reporting_report_run_create()
    reporting_report_run_create => <<'PERL',
sub reporting_report_run_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'reporting.report_run' } },
    parameters => { type => "hash" },
    report_type => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'reporting.report_run', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Reporting::ReportRun', $hash ) );
}
PERL
    # NOTE: reporting_report_run_list()
    reporting_report_run_list => <<'PERL',
sub reporting_report_run_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list reporting report run information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Reporting::ReportRun', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'reporting.report_run' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Reporting::ReportRun', $hash ) );
}
PERL
    # NOTE: reporting_report_run_retrieve()
    reporting_report_run_retrieve => <<'PERL',
sub reporting_report_run_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'reporting.report_run' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'reporting.report_run', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No reporting.report_run id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "reporting/report_runs/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Reporting::ReportRun', $hash ) );
}
PERL
    # NOTE: reporting_report_runs()
    reporting_report_runs => <<'PERL',
# <https://stripe.com/docs/api/reporting/report_run>
sub reporting_report_runs
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'reporting_report_run', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: reporting_report_type()
    reporting_report_type => <<'PERL',
sub reporting_report_type { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Reporting::ReportType', @_ ) ); }
PERL
    # NOTE: reporting_report_type_list()
    reporting_report_type_list => <<'PERL',
sub reporting_report_type_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list reporting report type information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Reporting::ReportType', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'reporting.report_type' }, data_prefix_is_ok => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Reporting::ReportType', $hash ) );
}
PERL
    # NOTE: reporting_report_type_retrieve()
    reporting_report_type_retrieve => <<'PERL',
sub reporting_report_type_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'reporting.report_type' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'reporting.report_type', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No reporting.report_type id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "reporting/report_types/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Reporting::ReportType', $hash ) );
}
PERL
    # NOTE: reporting_report_types()
    reporting_report_types => <<'PERL',
# <https://stripe.com/docs/api/reporting/report_type>
sub reporting_report_types
{
    my $self = shift( @_ );
    my $allowed = [qw( list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'reporting_report_type', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: request()
    request => <<'PERL',
sub request { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Event::Request', @_ ) ); }
PERL
    # NOTE: requirements()
    requirements => <<'PERL',
sub requirements { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::Requirements', @_ ) ); }
PERL
    # NOTE: return()
    return => <<'PERL',
sub return { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Order::Return' ) ) }
PERL
    # NOTE: review()
    review => <<'PERL',
sub review { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Fraud::Review', @_ ) ); }
PERL
    # NOTE: review_approve()
    review_approve => <<'PERL',
sub review_approve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'review' } },
    };
    $args = $self->_contract( 'review', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No review id (with parameter 'id') was provided to approve its information." ) );
    my $hash = $self->post( "reviews/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::Review', $hash ) );
}
PERL
    # NOTE: review_list()
    review_list => <<'PERL',
sub review_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list review information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Fraud::Review', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'review' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "reviews", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::Review', $hash ) );
}
PERL
    # NOTE: review_retrieve()
    review_retrieve => <<'PERL',
sub review_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'review' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'review', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No review id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "reviews/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Fraud::Review', $hash ) );
}
PERL
    # NOTE: reviews()
    reviews => <<'PERL',
# <https://stripe.com/docs/api/radar/reviews>
sub reviews
{
    my $self = shift( @_ );
    my $allowed = [qw( approve list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'review', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: schedule()
    schedule => <<'PERL',
sub schedule { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ ) ); }
PERL
    # NOTE: schedule_cancel()
    schedule_cancel => <<'PERL',
# https://stripe.com/docs/api/subscription_schedules/cancel?lang=curl
# "Cancels a subscription schedule and its associated subscription immediately (if the subscription schedule has an active subscription). A subscription schedule can only be canceled if its status is not_started or active."
sub schedule_cancel
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to cancel subscription schedule information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{schedule} },
    id          => { re => qr/^\w+$/, required => 1 },
    # "If the subscription schedule is active, indicates whether or not to generate a final invoice that contains any un-invoiced metered usage and new/pending proration invoice items. Defaults to true."
    invoice_now => { type => 'boolean' },
    # "If the subscription schedule is active, indicates if the cancellation should be prorated. Defaults to true."
    prorate     => { type => 'boolean' },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription schedule id was provided to cancel." ) );
    my $hash = $self->post( "subscription_schedules/${id}/cancel", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: schedule_create()
    schedule_create => <<'PERL',
sub schedule_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a subscription schedule" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{schedule} },
    customer            => {},
    default_settings    => { fields => [qw( billing_thresholds.amount_gte billing_thresholds.reset_billing_cycle_anchor collection_method default_payment_method invoice_settings.days_until_due )] },
    end_behavior        => { re => qr/^(release|cancel)$/ },
    from_subscription   => {},
    metadata            => {},
    phases              => { type => 'array', fields => [qw(
                            add_invoice_items.price
                            add_invoice_items.price_data.currency!
                            add_invoice_items.price_data.product!
                            add_invoice_items.price_data.unit_amount_decimal
                            add_invoice_items.price_data.unit_amount
                            add_invoice_items.quantity
                            add_invoice_items.tax_rates
                            
                            application_fee_percent

                            billing_cycle_anchor
                            
                            billing_thresholds.amount_gte
                            billing_thresholds.reset_billing_cycle_anchor
                            
                            collection_method
                            
                            coupon
                            
                            default_payment_method
                            
                            default_tax_rates

                            end_date
                            
                            invoice_settings.days_until_due
                            
                            items!
                            items.billing_thresholds.usage_gte!
                            items.price
                            items.price_data.currency!
                            items.price_data.product!
                            items.price_data.recurring!
                            items.price_data.recurring.interval!
                            items.price_data.recurring.interval_count
                            items.price_data.unit_amount_decimal
                            items.price_data.unit_amount
                            items.quantity
                            items.tax_rates
                            
                            iterations
                            
                            plans.plan
                            plans.billing_thresholds.usage_gte
                            plans.quantity
                            plans.tax_rates
                            
                            proration_behavior
                            
                            tax_percent
                            
                            transfer_data.destination!
                            transfer_data.amount_percent
                            
                            trial
                            trial_end
                            )]},
    start_date          => { type => 'datetime' },
    };
    
    my $obj = $args->{_object};
    if( $obj && !length( $args->{start_date} ) && $obj->current_phase->start_date )
    {
        $args->{start_date} = $obj->current_phase->start_date->epoch;
    }
    $args = $self->_contract( 'schedule', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'subscription_schedules', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: schedule_list()
    schedule_list => <<'PERL',
sub schedule_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{schedule}, data_prefix_is_ok => 1 },
    'canceled_at'       => { re => qr/^\d+$/ },
    'canceled_at.gt'    => { re => qr/^\d+$/ },
    'canceled_at.gte'   => { re => qr/^\d+$/ },
    'canceled_at.lt'    => { re => qr/^\d+$/ },
    'canceled_at.lte'   => { re => qr/^\d+$/ },
    'completed_at'      => { re => qr/^\d+$/ },
    'completed_at.gt'   => { re => qr/^\d+$/ },
    'completed_at.gte'  => { re => qr/^\d+$/ },
    'completed_at.lt'   => { re => qr/^\d+$/ },
    'completed_at.lte'  => { re => qr/^\d+$/ },
    'created'           => { re => qr/^\d+$/ },
    'created.gt'        => { re => qr/^\d+$/ },
    'created.gte'       => { re => qr/^\d+$/ },
    'created.lt'        => { re => qr/^\d+$/ },
    'created.lte'       => { re => qr/^\d+$/ },
    'customer'          => {},
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    'ending_before'     => {},
    'limit'             => { re => qr/^\d+$/ },
    'released_at'       => { re => qr/^\d+$/ },
    'released_at.gt'    => { re => qr/^\d+$/ },
    'released_at.gte'   => { re => qr/^\d+$/ },
    'released_at.lt'    => { re => qr/^\d+$/ },
    'released_at.lte'   => { re => qr/^\d+$/ },
    'scheduled'         => { type => 'boolean' },
    'starting_after'    => {},
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'subscription_schedules', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: schedule_query()
    schedule_query => <<'PERL',
# sub session { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Session', @_ ) ); }
sub schedule_query { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Sigma::ScheduledQueryRun' ) ) }
PERL
    # NOTE: schedule_release()
    schedule_release => <<'PERL',
# "Releases the subscription schedule immediately, which will stop scheduling of its phases, but leave any existing subscription in place. A schedule can only be released if its status is not_started or active. If the subscription schedule is currently associated with a subscription, releasing it will remove its subscription property and set the subscriptionâs ID to the released_subscription property."
# https://stripe.com/docs/api/subscription_schedules/release
sub schedule_release
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve subscription schedule information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
    my $okParams = 
    {
    expandable              => { allowed => $EXPANDABLES->{schedule} },
    id                      => { re => qr/^\w+$/, required => 1 },
    preserve_cancel_date    => { type => 'boolean' },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription schedule id was provided to retrieve its information." ) );
    my $hash = $self->post( "subscription_schedules/${id}/release", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: schedule_retrieve()
    schedule_retrieve => <<'PERL',
sub schedule_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve subscription schedule information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{schedule} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription schedule id was provided to retrieve its information." ) );
    my $hash = $self->get( "subscription_schedules/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: schedule_update()
    schedule_update => <<'PERL',
# https://stripe.com/docs/api/customers/update?lang=curl
sub schedule_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a subscription schedule" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{schedule} },
    id                  => { re => qr/^\w+$/, required => 1 },
    default_settings    => { fields => [qw( billing_thresholds.amount_gte billing_thresholds.reset_billing_cycle_anchor collection_method default_payment_method invoice_settings.days_until_due )] },
    end_behavior        => { re => qr/^(release|cancel)$/ },
    from_subscription   => {},
    metadata            => { type => 'hash' },
    phases              => { type => 'array', fields => [qw(
                            add_invoice_items.price
                            add_invoice_items.price_data.currency!
                            add_invoice_items.price_data.product!
                            add_invoice_items.price_data.unit_amount_decimal
                            add_invoice_items.price_data.unit_amount
                            add_invoice_items.quantity
                            add_invoice_items.tax_rates
                            
                            application_fee_percent
                            
                            billing_cycle_anchor
                            
                            billing_thresholds.amount_gte
                            billing_thresholds.reset_billing_cycle_anchor
                            
                            collection_method
                            coupon

                            default_payment_method
                            default_tax_rates

                            end_date
                            
                            invoice_settings.days_until_due
                            
                            items!
                            items.billing_thresholds
                            items.billing_thresholds.usage_gte!
                            items.price
                            items.price_data.currency!
                            items.price_data.product!
                            items.price_data.recurring!
                            items.price_data.recurring.interval!
                            items.price_data.recurring.interval_count
                            items.price_data.unit_amount_decimal
                            items.price_data.unit_amount
                            items.quantity
                            items.tax_rates
                            
                            iterations
                            
                            plans.plan
                            plans.billing_thresholds.usage_gte
                            plans.quantity
                            plans.tax_rates
                            
                            proration_behavior
                            
                            start_date
                            
                            tax_percent
                            
                            transfer_data.destination!
                            transfer_data.amount_percent
                            
                            trial
                            trial_end
                            )]},
    prorate             => { type => 'boolean' },
    proration_behavior  => { type => 'scalar' },
    start_date          => { type => 'datetime' },
    };
    $args = $self->_contract( 'schedule', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription schedule id was provided to update subscription schedule's details" ) );
    my $hash = $self->post( "subscription_schedules/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: scheduled_query_run()
    scheduled_query_run => <<'PERL',
sub scheduled_query_run { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Sigma::ScheduledQueryRun', @_ ) ); }
PERL
    # NOTE: scheduled_query_run_list()
    scheduled_query_run_list => <<'PERL',
sub scheduled_query_run_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list scheduled query run information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Sigma::ScheduledQueryRun', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'scheduled_query_run' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "sigma/scheduled_query_runs", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Sigma::ScheduledQueryRun', $hash ) );
}
PERL
    # NOTE: scheduled_query_run_retrieve()
    scheduled_query_run_retrieve => <<'PERL',
sub scheduled_query_run_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'scheduled_query_run' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'scheduled_query_run', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No scheduled_query_run id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "sigma/scheduled_query_runs/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Sigma::ScheduledQueryRun', $hash ) );
}
PERL
    # NOTE: scheduled_query_runs()
    scheduled_query_runs => <<'PERL',
# <https://stripe.com/docs/api/sigma/scheduled_queries>
sub scheduled_query_runs
{
    my $self = shift( @_ );
    my $allowed = [qw( list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'scheduled_query_run', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: schedules()
    schedules => <<'PERL',
sub schedules
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update list cancel release )];
    my $meth = $self->_get_method( 'schedule', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: session()
    session => <<'PERL',
sub session { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Checkout::Session', @_ ) ); }
PERL
    # NOTE: session_create()
    session_create => <<'PERL',
# https://stripe.com/docs/api/checkout/sessions/create
# https://stripe.com/docs/payments/checkout/fulfillment#webhooks
# See webhook event checkout.session.completed
sub session_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a checkout session" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Checkout::Session', @_ );
    my $okParams = 
    {
    expandable              => { allowed => $EXPANDABLES->{session} },
    cancel_url              => { required => 1 },
    payment_method_types    => { required => 1, re => qr/^(card|ideal)$/ },
    success_url             => { required => 1 },
    billing_address_collection  => { re => qr/^(auto|required)$/ },
    client_reference_id     => {},
    # ID of an existing customer, if one exists.
    customer                => {},
    customer_email          => {},
    # array of hash reference
    line_items              => { type => 'array', fields => [qw( amount currency name quantity description images )] },
    locale                  => { re => qr/^(local|[a-z]{2})$/ },
    mode                    => { re => qr/^(setup|subscription)$/ },
    payment_intent_data     => { fields => [qw( application_fee_amount capture_method description metadata on_behalf_of receipt_email setup_future_usage shipping.address.line1 shipping.address.line2 shipping.address.city shipping.address.country shipping.address.postal_code shipping.address.state shipping.name shipping.carrier shipping.phone shipping.tracking_number statement_descriptor transfer_data.destination )] },
    setup_intent_data       => { fields => [qw( description metadata on_behalf_of )] },
    submit_type             => { re => qr/^(auto|book|donate|pay)$/ },
    subscription_data       => { fields => [qw( items.plan items.quantity application_fee_percent metadata trial_end trial_from_plan trial_period_days )] },
    };
    $args = $self->_contract( 'session', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'checkout/sessions', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Checkout::Session', $hash ) );
}
PERL
    # NOTE: session_expire()
    session_expire => <<'PERL',
sub session_expire
{
    my $self = shift( @_ );
    my $args = shift( @_ ) || CORE::return( $self->error( "No parameters were provided to expire a checkout session" ) );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{session} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No tax id was provided to retrieve its details" ) );
    my $hash = $self->get( "checkout/sessions/${id}/expire", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Checkout::Session', $hash ) );
}
PERL
    # NOTE: session_list()
    session_list => <<'PERL',
sub session_list
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{session}, data_prefix_is_ok => 1 },
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    'ending_before'     => {},
    'limit'             => { re => qr/^\d+$/ },
    'payment_intent'    => { type => 'scalar' },
    'subscription'      => { re => qr/^\w+$/ },
    'starting_after'    => {},
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'checkout/sessions', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: session_retrieve()
    session_retrieve => <<'PERL',
sub session_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ ) || CORE::return( $self->error( "No parameters were provided to retrieve a checkout session" ) );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{session} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No checkout session id was provided to retrieve its details" ) );
    my $hash = $self->get( "checkout/sessions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Checkout::Session', $hash ) );
}
PERL
    # NOTE: session_retrieve_items()
    session_retrieve_items => <<'PERL',
sub session_retrieve_items
{
    my $self = shift( @_ );
    my $args = shift( @_ ) || CORE::return( $self->error( "No parameters were provided to retrieve a checkout session items" ) );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{item} },
    id          => { re => qr/^\w+$/, required => 1 },
    ending_before     => {},
    limit             => { re => qr/^\d+$/ },
    starting_after    => {},
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No checkout session id was provided to retrieve its items details" ) );
    my $hash = $self->get( "checkout/sessions/${id}/line_items", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: sessions()
    sessions => <<'PERL',
sub sessions
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create expire retrieve list retrieve_items )];
    my $meth = $self->_get_method( 'session', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: settings()
    settings => <<'PERL',
sub settings { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::Settings', @_ ) ); }
PERL
    # NOTE: setup_attempt()
    setup_attempt => <<'PERL',
sub setup_attempt { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Intent::Attempt', @_ ) ); }
PERL
    # NOTE: setup_attempt_list()
    setup_attempt_list => <<'PERL',
sub setup_attempt_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{setup_attempt}, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    ending_before => { type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    setup_intent => { re => qr/^\w+$/, required => 1, type => "string" },
    starting_after => { type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'setup_attempts', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: setup_attempts()
    setup_attempts => <<'PERL',
sub setup_attempts
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( list )];
    my $meth = $self->_get_method( 'setup_attempts', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: setup_intent()
    setup_intent => <<'PERL',
sub setup_intent { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Intent::Attempt', @_ ) ); }
PERL
    # NOTE: setup_intent_cancel()
    setup_intent_cancel => <<'PERL',
sub setup_intent_cancel
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to cancel the setup intent." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent::Setup', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{setup_intent} },
    cancellation_reason => {
        re => qr/^(?:abandoned|requested_by_customer|duplicate)$/,
        type => "string",
    },
    id => { re => qr/^\w+$/, required => 1 },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No setup intent id was provided to cancel." ) );
    my $hash = $self->post( "setup_intents/${id}/cancel", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent::Setup', $hash ) );
}
PERL
    # NOTE: setup_intent_confirm()
    setup_intent_confirm => <<'PERL',
sub setup_intent_confirm
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to confirm the setup intent." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent::Setup', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{setup_intent} },
    id => { re => qr/^\w+$/, required => 1 },
    mandate_data => {
        fields => [
                      "customer_acceptance.type",
                      "customer_acceptance.accepted_at",
                      "customer_acceptance.offline",
                      "customer_acceptance.online.ip_address",
                      "customer_acceptance.online.user_agent",
                  ],
        type   => "hash",
    },
    payment_method => { re => qr/^\w+$/, type => "string" },
    payment_method_data => { type => "object" },
    payment_method_options => {
        fields => [
                      "acss_debit.currency",
                      "acss_debit.mandate_options.custom_mandate_url",
                      "acss_debit.mandate_options.default_for",
                      "acss_debit.mandate_options.interval_description",
                      "acss_debit.mandate_options.payment_schedule",
                      "acss_debit.mandate_options.transaction_type",
                      "acss_debit.verification_method",
                      "card.request_three_d_secure",
                      "sepa_debit.mandate_options",
                  ],
        type   => "hash",
    },
    return_url => { type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No setup intent id was provided to confirm." ) );
    my $hash = $self->post( "setup_intents/${id}/confirm", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent::Setup', $hash ) );
}
PERL
    # NOTE: setup_intent_create()
    setup_intent_create => <<'PERL',
sub setup_intent_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a the setup intent." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent::Setup', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{setup_intent} },
    attach_to_self => { type => "boolean" },
    confirm => { type => "boolean" },
    customer => { type => "string" },
    description => { type => "string" },
    flow_directions => { type => "array" },
    id => { re => qr/^\w+$/, required => 1 },
    mandate_data => {
        fields => [
                      "customer_acceptance.type",
                      "customer_acceptance.accepted_at",
                      "customer_acceptance.offline",
                      "customer_acceptance.online.ip_address",
                      "customer_acceptance.online.user_agent",
                  ],
        type   => "object",
    },
    metadata => { type => "hash" },
    on_behalf_of => { type => "string" },
    payment_method => { re => qr/^\w+$/, type => "string" },
    payment_method_data => { type => "object" },
    payment_method_options => {
        fields => [
                      "acss_debit.currency",
                      "acss_debit.mandate_options.custom_mandate_url",
                      "acss_debit.mandate_options.default_for",
                      "acss_debit.mandate_options.interval_description",
                      "acss_debit.mandate_options.payment_schedule",
                      "acss_debit.mandate_options.transaction_type",
                      "acss_debit.verification_method",
                      "card.request_three_d_secure",
                      "sepa_debit.mandate_options",
                  ],
        type   => "hash",
    },
    payment_method_types => { type => "array" },
    return_url => { type => "string" },
    single_use => { fields => ["amount", "currency"], type => "object" },
    usage => { type => "string" },
    };

    $args = $self->_contract( 'setup_intent', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'setup_intents', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent::Setup', $hash ) );
}
PERL
    # NOTE: setup_intent_list()
    setup_intent_list => <<'PERL',
sub setup_intent_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{setup_intent}, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    attach_to_self => { type => "boolean" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    customer => { re => qr/^\w+$/, type => "string" },
    ending_before => { type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    payment_method => { type => "string" },
    starting_after => { type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'setup_intents', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: setup_intent_retrieve()
    setup_intent_retrieve => <<'PERL',
sub setup_intent_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve setup intent information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent::Setup', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{setup_intent}, data_prefix_is_ok => 1 },
    client_secret => { required => 1, type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No setup intent id was provided to retrieve its information." ) );
    my $hash = $self->get( "setup_intents/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent::Setup', $hash ) );
}
PERL
    # NOTE: setup_intent_update()
    setup_intent_update => <<'PERL',
sub setup_intent_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update the setup intent." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent::Setup', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{setup_intent} },
    attach_to_self => { type => "boolean" },
    customer => { type => "string" },
    description => { type => "string" },
    flow_directions => { type => "array" },
    id => { re => qr/^\w+$/, required => 1 },
    metadata => { type => "hash" },
    payment_method => { re => qr/^\w+$/, type => "string" },
    payment_method_data => { type => "object" },
    payment_method_options => {
        fields => [
                      "acss_debit.currency",
                      "acss_debit.mandate_options.custom_mandate_url",
                      "acss_debit.mandate_options.default_for",
                      "acss_debit.mandate_options.interval_description",
                      "acss_debit.mandate_options.payment_schedule",
                      "acss_debit.mandate_options.transaction_type",
                      "acss_debit.verification_method",
                      "card.request_three_d_secure",
                      "sepa_debit.mandate_options",
                  ],
        type   => "hash",
    },
    payment_method_types => { type => "array" },
    };

    $args = $self->_contract( 'setup_intent', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No setup intent id was provided to update its details" ) );
    my $hash = $self->post( "setup_intents/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent::Setup', $hash ) );
}
PERL
    # NOTE: setup_intent_verify()
    setup_intent_verify => <<'PERL',
sub setup_intent_verify
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to verify microdeposits on the setup intent." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent::Setup', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{setup_intent} },
    id                  => { re => qr/^\w+$/, required => 1 },
    client_secret       => {},
    amounts             => { type => 'array', re => qr/^\d+$/ },
    descriptor_code     => { re => qr/^.*?$/ },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No setup intent id was provided to verify microdeposits on it." ) );
    my $hash = $self->post( "setup_intents/${id}/verify_microdeposits", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent::Setup', $hash ) );
}
PERL
    # NOTE: setup_intent_verify_microdeposits()
    setup_intent_verify_microdeposits => <<'PERL',
sub setup_intent_verify_microdeposits
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to verify_microdeposits setup intent information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Intent::Setup', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'setup_intent' } },
    amounts => { type => "array" },
    client_secret => { type => "string", required => 1 },
    descriptor_code => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No setup_intent id (with parameter 'id') was provided to verify_microdeposits its information." ) );
    my $hash = $self->post( "setup_intents/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Intent::Setup', $hash ) );
}
PERL
    # NOTE: setup_intents()
    setup_intents => <<'PERL',
# <https://stripe.com/docs/api/setup_intents>
sub setup_intents
{
    my $self = shift( @_ );
    my $allowed = [qw( cancel confirm create list retrieve update verify verify_microdeposits )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'setup_intent', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: shipping()
    shipping => <<'PERL',
# sub sigma { CORE::return( shift->_instantiate( 'sigma', 'Net::API::Stripe::Sigma' ) ) }
sub shipping { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Shipping', @_ ) ); }
PERL
    # NOTE: shipping_rate()
    shipping_rate => <<'PERL',
sub shipping_rate { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Shipping::Rate', @_ ) ); }
PERL
    # NOTE: shipping_rate_create()
    shipping_rate_create => <<'PERL',
sub shipping_rate_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a shipping rate" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Shipping::Rate', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{shipping_rate} },
    delivery_estimate => {
        fields => [
                      "maximum.unit",
                      "maximum.value",
                      "minimum.unit",
                      "minimum.value",
                  ],
        type   => "hash",
    },
    display_name => { re => qr/^.+$/, required => 1, type => "string" },
    fixed_amount => { fields => ["amount", "currency"], required => 1, type => "hash" },
    metadata => { type => "hash" },
    tax_behavior => { type => "string" },
    tax_code => { type => "string" },
    type => { re => qr/^\w+$/, required => 1, type => "string" },
    };

    $args = $self->_contract( 'shipping_rate', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "shipping_rates", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Shipping::Rate', $hash ) );
}
PERL
    # NOTE: shipping_rate_list()
    shipping_rate_list => <<'PERL',
sub shipping_rate_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list shipping rates" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Shipping::Rate', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{shipping_rate}, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    currency => { re => qr/^[A-Z]+$/, type => "string" },
    ending_before => { re => qr/^\w+$/, type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    limit => { re => qr/^\d+$/, type => "string" },
    starting_after => { re => qr/^\w+$/, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "shipping_rates", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: shipping_rate_retrieve()
    shipping_rate_retrieve => <<'PERL',
sub shipping_rate_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve a shipping rate" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Shipping::Rate', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{shipping_rate} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No shipping rate id was provided to retrieve its information" ) );
    my $hash = $self->get( "shipping_rates/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Shipping::Rate', $hash ) );
}
PERL
    # NOTE: shipping_rate_update()
    shipping_rate_update => <<'PERL',
sub shipping_rate_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a shipping rate" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Shipping::Rate', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{shipping_rate} },
    active => { type => "boolean" },
    fixed_amount => { type => "hash" },
    id => { re => qr/^\w+$/, required => 1 },
    metadata => { type => "hash" },
    tax_behavior => { type => "string" },
    };

    $args = $self->_contract( 'shipping_rate', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No shipping rate id was provided to update its details" ) );
    my $hash = $self->post( "shipping_rates/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Shipping::Rate', $hash ) );
}
PERL
    # NOTE: shipping_rates()
    shipping_rates => <<'PERL',
sub shipping_rates
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update list )];
    my $meth = $self->_get_method( 'shipping_rate', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: sku()
    sku => <<'PERL',
sub sku { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Order::SKU' ) ) }
PERL
    # NOTE: source()
    source => <<'PERL',
sub source { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Source', @_ ) ); }
PERL
    # NOTE: source_attach()
    source_attach => <<'PERL',
sub source_attach
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to attach a source." ) ) if( !scalar( @_ ) );
    my $args;
    if( $self->_is_object( $_[0] ) )
    {
        if( $_[0]->isa( 'Net::API::Stripe::Customer' ) )
        {
            $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
        }
        elsif( $_[0]->isa( 'Net::API::Stripe::Payment::Source' ) )
        {
            $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Source', @_ );
            my $obj = $args->{_object};
            $args->{source} = $obj->id;
            $args->{id} = $obj->customer->id if( $obj->customer );
        }
    }
    else
    {
        $args = $self->_get_args( @_ );
    }
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{source} },
    id => { re => qr/^\w+$/, required => 1 },
    source => { re => qr/^\w+$/, required => 1, type => "string" },
    };

    $args = $self->_contract( 'source', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to attach the source to." ) );
    my $hash = $self->post( "customers/${id}/sources", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Source', $hash ) );
}
PERL
    # NOTE: source_create()
    source_create => <<'PERL',
sub source_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a source" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Source', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{source} },
    amount => { type => "integer" },
    currency => { type => "string" },
    flow => { type => "string" },
    mandate => {
        fields => [
                      "acceptance",
                      "acceptance.status",
                      "acceptance.date",
                      "acceptance.ip",
                      "acceptance.offline.contact_email",
                      "acceptance.online",
                      "acceptance.type",
                      "acceptance.user_agent",
                      "amount",
                      "currency",
                      "interval",
                      "notification_method",
                  ],
        type   => "object",
    },
    metadata => { type => "hash" },
    owner => {
        fields => [
                      "address.city",
                      "address.country",
                      "address.line1",
                      "address.line2",
                      "address.postal_code",
                      "address.state",
                      "email",
                      "name",
                      "phone",
                  ],
        type   => "hash",
    },
    receiver => { fields => ["refund_attributes_method"], type => "hash" },
    redirect => { fields => ["return_url"], type => "hash" },
    source_order => {
        fields => [
                      "items.amount",
                      "items.currency",
                      "items.description",
                      "items.parent",
                      "items.quantity",
                      "items.type",
                      "shipping.address.city",
                      "shipping.address.country",
                      "shipping.address.line1",
                      "shipping.address.line2",
                      "shipping.address.postal_code",
                      "shipping.address.state",
                      "shipping.carrier",
                      "shipping.name",
                      "shipping.phone",
                      "shipping.tracking_number",
                  ],
        type   => "hash",
    },
    statement_descriptor => { type => "string" },
    token => { type => "string" },
    type => { required => 1, type => "string" },
    usage => { type => "string" },
    };

    $args = $self->_contract( 'source', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'sources', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Source', $hash ) );
}
PERL
    # NOTE: source_detach()
    source_detach => <<'PERL',
# https://stripe.com/docs/api/customers/delete?lang=curl
# "Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer."
sub source_detach
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to detach a source." ) ) if( !scalar( @_ ) );
    my $args;
    if( $self->_is_object( $_[0] ) )
    {
        if( $_[0]->isa( 'Net::API::Stripe::Customer' ) )
        {
            $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
        }
        elsif( $_[0]->isa( 'Net::API::Stripe::Payment::Source' ) )
        {
            $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Source', @_ );
            my $obj = $args->{_object};
            $args->{source} = $obj->id;
            $args->{id} = $obj->customer->id if( $obj->customer );
        }
    }
    else
    {
        $args = $self->_get_args( @_ );
    }
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{source} },
    id          => { re => qr/^\w+$/, required => 1 },
    source      => { re => qr/^\w+$/, required => 1 },
    };
    $args = $self->_contract( 'source', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to detach the source from it." ) );
    my $src_id = CORE::delete( $args->{source} ) || CORE::return( $self->error( "No source id was provided to detach." ) );
    my $hash = $self->delete( "customers/${id}/sources/${src_id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Source', $hash ) );
}
PERL
    # NOTE: source_order()
    source_order => <<'PERL',
sub source_order { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Order', @_ ) ); }
PERL
    # NOTE: source_retrieve()
    source_retrieve => <<'PERL',
sub source_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve source information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Source', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{source}, data_prefix_is_ok => 1 },
    client_secret => { type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    };

    $args = $self->_contract( 'source', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No source id was provided to retrieve its information." ) );
    my $hash = $self->get( "sources/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Source', $hash ) );
}
PERL
    # NOTE: source_update()
    source_update => <<'PERL',
# https://stripe.com/docs/api/sources/update?lang=curl
sub source_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a source" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Source', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{source} },
    amount => { type => "integer" },
    id => { re => qr/^\w+$/, required => 1 },
    mandate => {
        fields => [
                      "acceptance",
                      "acceptance.status",
                      "acceptance.date",
                      "acceptance.ip",
                      "acceptance.offline.contact_email",
                      "acceptance.online",
                      "acceptance.type",
                      "acceptance.user_agent",
                      "amount",
                      "currency",
                      "interval",
                      "notification_method",
                  ],
        type   => "object",
    },
    metadata => { type => "hash" },
    owner => {
        fields => [
                      "address.city",
                      "address.country",
                      "address.line1",
                      "address.line2",
                      "address.postal_code",
                      "address.state",
                      "email",
                      "name",
                      "phone",
                  ],
        type   => "hash",
    },
    source_order => {
        fields => [
                      "items.amount",
                      "items.currency",
                      "items.description",
                      "items.parent",
                      "items.quantity",
                      "items.type",
                      "shipping.address.city",
                      "shipping.address.country",
                      "shipping.address.line1",
                      "shipping.address.line2",
                      "shipping.address.postal_code",
                      "shipping.address.state",
                      "shipping.carrier",
                      "shipping.name",
                      "shipping.phone",
                      "shipping.tracking_number",
                  ],
        type   => "hash",
    },
    };

    $args = $self->_contract( 'source', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No source id was provided to update source's details" ) );
    my $hash = $self->post( "sources/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Payment::Source', $hash ) );
}
PERL
    # NOTE: sources()
    sources => <<'PERL',
sub sources
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update detach attach )];
    my $meth = $self->_get_method( 'source', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: status_transitions()
    status_transitions => <<'PERL',
sub status_transitions { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice::StatusTransition', @_ ) ); }
PERL
    # NOTE: subscription()
    subscription => <<'PERL',
sub subscription { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Subscription', @_ ) ); }
PERL
    # NOTE: subscription_cancel()
    subscription_cancel => <<'PERL',
# https://stripe.com/docs/api/customers/delete?lang=curl
# "Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer."
sub subscription_cancel
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to cancel subscription information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{subscription} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription id was provided to cancel." ) );
    my $hash = $self->delete( "subscriptions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription', $hash ) );
}
PERL
    # NOTE: subscription_create()
    subscription_create => <<'PERL',
sub subscription_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a subscription" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{subscription} },
    add_invoice_items => {
        fields => ["price", "price_data", "quantity", "tax_rates"],
        type   => "array",
    },
    application_fee_percent => { re => qr/^[0-100]$/, type => "decimal" },
    automatic_tax => { fields => ["enabled!"], type => "hash" },
    backdate_start_date => { type => "datetime" },
    billing_cycle_anchor => { type => "datetime" },
    billing_thresholds => {
        fields => ["amount_gte", "reset_billing_cycle_anchor"],
        type   => "hash",
    },
    cancel_at => { type => "datetime" },
    cancel_at_period_end => { type => "boolean" },
    collection_method => { re => qr/^(?:charge_automatically|send_invoice)$/, type => "string" },
    coupon => { type => "string" },
    currency => { type => "currency" },
    customer => { required => 1, type => "string" },
    days_until_due => { type => "integer" },
    default_payment_method => { type => "string" },
    default_source => { type => "string" },
    default_tax_rates => { type => "array" },
    description => { type => "string" },
    items => {
        fields => [
            "billing_thresholds.usage_gte",
            "metadata",
            "plan",
            "price",
            "price_data.currency!",
            "price_data.product!",
            "price_data.recurring!",
            "price_data.recurring.interval!",
            "price_data.recurring.interval_count",
            "price_data.tax_behavior",
            "price_data.unit_amount_decimal!",
            "price_data.unit_amount",
            "quantity",
            "tax_rates",
        ],
        required => 1,
        type => "array",
    },
    metadata => { type => "hash" },
    off_session => { type => "boolean" },
    payment_behavior => {
        re => qr/^(?:allow_incomplete|error_if_incomplete)$/,
        type => "string",
    },
    payment_settings => { class => "Net::API::Stripe::Payment::Settings", type => "object" },
    pending_invoice_item_interval => { fields => ["interval", "interval_count"], type => "hash" },
    promotion_code => { type => "string" },
    prorate => {},
    proration_behavior => {
        re => qr/^(billing_cycle_anchor|create_prorations|none)$/,
        type => "string",
    },
    tax_percent => { re => qr/^[0-100]$/ },
    transfer_data => { fields => ["desination", "amount_percent"], type => "hash" },
    trial_end => { re => qr/^(?:\d+|now)$/, type => "timestamp" },
    trial_from_plan => { type => "boolean" },
    trial_period_days => { type => "integer" },
    };

    $args = $self->_contract( 'subscription', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'subscriptions', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription', $hash ) );
}
PERL
    # NOTE: subscription_delete()
    subscription_delete => <<'PERL',
sub subscription_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription' } },
    invoice_now => { type => "boolean" },
    prorate => { type => "boolean" },
    };
    $args = $self->_contract( 'subscription', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "subscriptions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription', $hash ) );
}
PERL
    # NOTE: subscription_delete_discount()
    subscription_delete_discount => <<'PERL',
sub subscription_delete_discount
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete subscription discount." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription', @_ );
    my $okParams = 
    {
    expandable => { allowed => $EXPANDABLES->{discount} },
    id => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription id was provided to delete its coupon." ) );
    my $hash = $self->delete( "subscriptions/${id}/discount", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Discount', $hash ) );
}
PERL
    # NOTE: subscription_item()
    subscription_item => <<'PERL',
sub subscription_item { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Item', @_ ) ); }
PERL
    # NOTE: subscription_item_create()
    subscription_item_create => <<'PERL',
sub subscription_item_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_item' } },
    billing_thresholds => { type => "hash" },
    metadata => { type => "hash" },
    payment_behavior => { type => "string" },
    price => { type => "hash" },
    price_data => { type => "object" },
    proration_behavior => { type => "string" },
    proration_date => { type => "integer" },
    quantity => { type => "integer" },
    subscription => { type => "string", required => 1 },
    tax_rates => { type => "array" },
    };
    $args = $self->_contract( 'subscription_item', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "subscription_items", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Item', $hash ) );
}
PERL
    # NOTE: subscription_item_delete()
    subscription_item_delete => <<'PERL',
sub subscription_item_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_item' } },
    clear_usage => { type => "boolean" },
    proration_behavior => { type => "string" },
    proration_date => { type => "integer" },
    };
    $args = $self->_contract( 'subscription_item', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription_item id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "subscription_items/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Item', $hash ) );
}
PERL
    # NOTE: subscription_item_list()
    subscription_item_list => <<'PERL',
sub subscription_item_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list subscription item information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Item', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_item' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    subscription => { type => "string", required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "subscription_items", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Item', $hash ) );
}
PERL
    # NOTE: subscription_item_retrieve()
    subscription_item_retrieve => <<'PERL',
sub subscription_item_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_item' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'subscription_item', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription_item id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "subscription_items/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Item', $hash ) );
}
PERL
    # NOTE: subscription_item_update()
    subscription_item_update => <<'PERL',
sub subscription_item_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_item' } },
    billing_thresholds => { type => "hash" },
    metadata => { type => "hash" },
    off_session => { type => "boolean" },
    payment_behavior => { type => "string" },
    price => { type => "hash" },
    price_data => { type => "object" },
    proration_behavior => { type => "string" },
    proration_date => { type => "integer" },
    quantity => { type => "integer" },
    tax_rates => { type => "array" },
    };
    $args = $self->_contract( 'subscription_item', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription_item id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "subscription_items/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Item', $hash ) );
}
PERL
    # NOTE: subscription_items()
    subscription_items => <<'PERL',
# <https://stripe.com/docs/api/subscription_items>
sub subscription_items
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'subscription_item', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: subscription_list()
    subscription_list => <<'PERL',
sub subscription_list
{
    my $self = shift( @_ );
    my $args = $self->_get_args( @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{subscription}, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    collection_method => { type => "string" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    current_period_end => { type => "timestamp" },
    current_period_start => { type => "timestamp" },
    customer => { type => "string" },
    ending_before => { type => "string" },
    ids => { type => "array" },
    limit => { re => qr/^\d+$/, type => "string" },
    price => { type => "string" },
    shippable => { type => "boolean" },
    starting_after => { type => "string" },
    status => { type => "string" },
    test_clock => { type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( 'subscriptions', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: subscription_retrieve()
    subscription_retrieve => <<'PERL',
sub subscription_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve subscription information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{subscription} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription id was provided to retrieve its information." ) );
    my $hash = $self->get( "subscriptions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription', $hash ) );
}
PERL
    # NOTE: subscription_schedule()
    subscription_schedule => <<'PERL',
sub subscription_schedule { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ ) ); }
PERL
    # NOTE: subscription_schedule_cancel()
    subscription_schedule_cancel => <<'PERL',
sub subscription_schedule_cancel
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_schedule' } },
    invoice_now => { type => "boolean" },
    prorate => { type => "boolean" },
    };
    $args = $self->_contract( 'subscription_schedule', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription_schedule id (with parameter 'id') was provided to cancel its information." ) );
    my $hash = $self->post( "subscription_schedules/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: subscription_schedule_create()
    subscription_schedule_create => <<'PERL',
sub subscription_schedule_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_schedule' } },
    customer => { type => "string" },
    default_settings => { type => "hash" },
    end_behavior => { type => "string" },
    from_subscription => { type => "string" },
    metadata => { type => "hash" },
    phases => { type => "array" },
    start_date => { type => "string" },
    };
    $args = $self->_contract( 'subscription_schedule', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "subscription_schedules", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: subscription_schedule_list()
    subscription_schedule_list => <<'PERL',
sub subscription_schedule_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list subscription schedule information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_schedule' }, data_prefix_is_ok => 1 },
    canceled_at => { type => "timestamp" },
    completed_at => { type => "timestamp" },
    created => { type => "timestamp" },
    customer => { type => "string" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    released_at => { type => "timestamp" },
    scheduled => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "subscription_schedules", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: subscription_schedule_release()
    subscription_schedule_release => <<'PERL',
sub subscription_schedule_release
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_schedule' } },
    preserve_cancel_date => { type => "boolean" },
    };
    $args = $self->_contract( 'subscription_schedule', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription_schedule id (with parameter 'id') was provided to release its information." ) );
    my $hash = $self->post( "subscription_schedules/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: subscription_schedule_retrieve()
    subscription_schedule_retrieve => <<'PERL',
sub subscription_schedule_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_schedule' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'subscription_schedule', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription_schedule id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "subscription_schedules/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: subscription_schedule_update()
    subscription_schedule_update => <<'PERL',
sub subscription_schedule_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription_schedule' } },
    default_settings => { type => "hash" },
    end_behavior => { type => "string" },
    metadata => { type => "hash" },
    phases => { type => "array" },
    proration_behavior => { type => "string" },
    };
    $args = $self->_contract( 'subscription_schedule', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription_schedule id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "subscription_schedules/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}
PERL
    # NOTE: subscription_schedules()
    subscription_schedules => <<'PERL',
# <https://stripe.com/docs/api/subscription_schedules>
sub subscription_schedules
{
    my $self = shift( @_ );
    my $allowed = [qw( cancel create list release retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'subscription_schedule', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: subscription_search()
    subscription_search => <<'PERL',
sub subscription_search
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'subscription' }, data_prefix_is_ok => 1 },
    limit => { type => "string" },
    page => { type => "string" },
    query => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'subscription', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->get( "subscriptions", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription', $hash ) );
}
PERL
    # NOTE: subscription_update()
    subscription_update => <<'PERL',
# https://stripe.com/docs/api/customers/update?lang=curl
sub subscription_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a subscription" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{subscription} },
    add_invoice_items => { type => "array" },
    application_fee_percent => { re => qr/^[0-100]$/, type => "decimal" },
    automatic_tax => { type => "hash" },
    billing_cycle_anchor => { re => qr/^\d+$/, type => "timestamp" },
    billing_thresholds => {
        fields => ["amount_gte", "reset_billing_cycle_anchor"],
        type   => "hash",
    },
    cancel_at => { type => "timestamp" },
    cancel_at_period_end => { type => "boolean" },
    collection_method => { re => qr/^(?:charge_automatically|send_invoice)$/, type => "string" },
    coupon => { type => "string" },
    days_until_due => { type => "integer" },
    default_payment_method => { re => qr/^[\w\_]+$/, type => "string" },
    default_source => { type => "string" },
    default_tax_rates => { type => "array" },
    description => { type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    items => {
        fields => [
                      "id",
                      "plan",
                      "billing_thresholds.usage_gte",
                      "clear_usage",
                      "deleted",
                      "metadata",
                      "quantity",
                      "tax_rates",
                  ],
        type   => "array",
    },
    metadata => { type => "hash" },
    off_session => { type => "boolean" },
    pause_collection => { fields => ["behavior", "resumes_at"], type => "string" },
    payment_behavior => {
        re => qr/^(?:allow_incomplete|error_if_incomplete)$/,
        type => "string",
    },
    payment_settings => { type => "hash" },
    pending_invoice_item_interval => { fields => ["interval", "interval_count"], type => "hash" },
    promotion_code => { type => "string" },
    prorate => {},
    proration_behavior => { type => "string" },
    proration_date => { type => "datetime" },
    tax_percent => { re => qr/^[0-100]$/ },
    transfer_data => { type => "hash" },
    trial_end => { re => qr/^(?:\d+|now)$/, type => "timestamp" },
    trial_from_plan => { type => "boolean" },
    };

    $args = $self->_contract( 'subscription', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription id was provided to update subscription's details" ) );
    my $hash = $self->post( "subscriptions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription', $hash ) );
}
PERL
    # NOTE: subscriptions()
    subscriptions => <<'PERL',
# <https://stripe.com/docs/api/subscriptions>
sub subscriptions
{
    my $self = shift( @_ );
    my $allowed = [qw( cancel create delete delete_discount list retrieve search update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'subscription', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: tax_code()
    tax_code => <<'PERL',
sub tax_code { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Product::TaxCode', @_ ) ); }
PERL
    # NOTE: tax_code_list()
    tax_code_list => <<'PERL',
sub tax_code_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list tax codes" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product::TaxCode', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{tax_code}, data_prefix_is_ok => 1 },
    ending_before => { re => qr/^\w+$/, type => "string" },
    limit => { re => qr/^\d+$/, type => "string" },
    starting_after => { re => qr/^\w+$/, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No tax code id was provided to list its information" ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "tax_codes", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: tax_code_retrieve()
    tax_code_retrieve => <<'PERL',
sub tax_code_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve tax code" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product::TaxCode', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{tax_code} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No tax id was provided to retrieve tax code information" ) );
    my $hash = $self->get( "tax_codes/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Product::TaxCode', $hash ) );
}
PERL
    # NOTE: tax_codes()
    tax_codes => <<'PERL',
sub tax_codes
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( retrieve list )];
    my $meth = $self->_get_method( 'tax_code', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: tax_id()
    tax_id => <<'PERL',
sub tax_id { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::TaxID', @_ ) ); }
PERL
    # NOTE: tax_id_create()
    tax_id_create => <<'PERL',
sub tax_id_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a tax_id" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::TaxID', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{tax_id} },
    customer => { re => qr/^\w+$/, required => 1 },
    type => { re => qr/^\w+$/, required => 1, type => "string" },
    value => { required => 1, type => "string" },
    };

    $args = $self->_contract( 'tax_id', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to create a tax_id for the customer" ) );
    my $hash = $self->post( "customers/$id/tax_ids", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::TaxID', $hash ) );
}
PERL
    # NOTE: tax_id_delete()
    tax_id_delete => <<'PERL',
sub tax_id_delete
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to delete a tax_id" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::TaxID', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{tax_id} },
    id          => { re => qr/^\w+$/, required => 1 },
    customer    => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No tax id was provided to delete." ) );
    my $cust_id = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to delete his/her tax_id" ) );
    my $hash = $self->delete( "customers/${cust_id}/tax_ids/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::TaxID', $hash ) );
}
PERL
    # NOTE: tax_id_list()
    tax_id_list => <<'PERL',
sub tax_id_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list customer's tax ids" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
    my $okParams = 
    {
    expandable      => { allowed => $EXPANDABLES->{tax_id}, data_prefix_is_ok => 1 },
    customer        => { re => qr/^\w+$/, required => 1 },
    # "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
    ending_before   => qr/^\w+$/,
    limit           => qr/^\d+$/,
    starting_after  => qr/^\w+$/,
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{customer} ) || CORE::delete( $args->{id} ) || CORE::return( $self->error( "No customer id was provided to list his/her tax ids" ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "customers/${id}/tax_ids", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: tax_id_retrieve()
    tax_id_retrieve => <<'PERL',
sub tax_id_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve tax_id" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::TaxID', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{tax_id} },
    id          => { re => qr/^\w+$/, required => 1 },
    customer    => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No tax id was provided to retrieve customer's tax_id" ) );
    my $cust_id = CORE::delete( $args->{customer} ) || CORE::return( $self->error( "No customer id was provided to retrieve his/her tax_id" ) );
    my $hash = $self->get( "customers/${cust_id}/tax_ids/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::TaxID', $hash ) );
}
PERL
    # NOTE: tax_ids()
    tax_ids => <<'PERL',
sub tax_ids
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve delete list )];
    my $meth = $self->_get_method( 'tax_id', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: tax_rate()
    tax_rate => <<'PERL',
sub tax_rate { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Tax::Rate', @_ ) ); }
PERL
    # NOTE: tax_rate_create()
    tax_rate_create => <<'PERL',
sub tax_rate_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a tax rate" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Tax::Rate', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{tax_rate} },
    active => { type => "boolean" },
    country => { re => qr/^[A-Z]+$/, type => "string" },
    description => { type => "string" },
    display_name => { re => qr/^.+$/, required => 1, type => "string" },
    inclusive => { required => 1, type => "boolean" },
    jurisdiction => { re => qr/^[A-Z]+$/, type => "string" },
    metadata => { type => "hash" },
    percentage => { required => 1, type => "integer" },
    state => { type => "string" },
    tax_type => { type => "string" },
    };

    $args = $self->_contract( 'tax_rate', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "tax_rates", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Tax::Rate', $hash ) );
}
PERL
    # NOTE: tax_rate_list()
    tax_rate_list => <<'PERL',
sub tax_rate_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list tax rates" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Tax::Rate', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{tax_rate}, data_prefix_is_ok => 1 },
    active => { type => "boolean" },
    created => { re => qr/^\d+$/, type => "timestamp" },
    'created.gt' => { re => qr/^\d+$/ },
    'created.gte' => { re => qr/^\d+$/ },
    'created.lt' => { re => qr/^\d+$/ },
    'created.lte' => { re => qr/^\d+$/ },
    ending_before => { re => qr/^\w+$/, type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    inclusive => { type => "boolean" },
    limit => { re => qr/^\d+$/, type => "string" },
    starting_after => { re => qr/^\w+$/, type => "string" },
    };

    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "tax_rates", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}
PERL
    # NOTE: tax_rate_retrieve()
    tax_rate_retrieve => <<'PERL',
sub tax_rate_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve a tax rate" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Tax::Rate', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{tax_rate} },
    id          => { re => qr/^\w+$/, required => 1 },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No tax id was provided to retrieve a tax rate" ) );
    my $hash = $self->get( "tax_rates/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Tax::Rate', $hash ) );
}
PERL
    # NOTE: tax_rate_update()
    tax_rate_update => <<'PERL',
sub tax_rate_update
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to update a tax rate" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Tax::Rate', @_ );
    my $okParams =
    {
    expandable => { allowed => $EXPANDABLES->{tax_rate} },
    active => { type => "boolean" },
    country => { re => qr/^[A-Z]+$/, type => "string" },
    description => { type => "string" },
    display_name => { re => qr/^.+$/, required => 1, type => "string" },
    id => { re => qr/^\w+$/, required => 1 },
    jurisdiction => { re => qr/^[A-Z]+$/, type => "string" },
    metadata => { type => "hash" },
    state => { type => "string" },
    tax_type => { type => "string" },
    };

    $args = $self->_contract( 'tax_rate', $args ) || CORE::return( $self->pass_error );
    # We found some errors
    my $err = $self->_check_parameters( $okParams, $args );
    # $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No tax rate id was provided to update its details" ) );
    my $hash = $self->post( "tax_rates/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Tax::Rate', $hash ) );
}
PERL
    # NOTE: tax_rates()
    tax_rates => <<'PERL',
sub tax_rates
{
    my $self = shift( @_ );
    my $action = shift( @_ );
    my $allowed = [qw( create retrieve update list )];
    my $meth = $self->_get_method( 'tax_rate', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: terminal_configuration()
    terminal_configuration => <<'PERL',
sub terminal_configuration { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Terminal::Configuration', @_ ) ); }
PERL
    # NOTE: terminal_configuration_create()
    terminal_configuration_create => <<'PERL',
sub terminal_configuration_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.configuration' } },
    bbpos_wisepos_e => { type => "hash" },
    tipping => { type => "hash" },
    verifone_p400 => { type => "hash" },
    };
    $args = $self->_contract( 'terminal.configuration', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Configuration', $hash ) );
}
PERL
    # NOTE: terminal_configuration_delete()
    terminal_configuration_delete => <<'PERL',
sub terminal_configuration_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.configuration' } },
    };
    $args = $self->_contract( 'terminal.configuration', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No terminal.configuration id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "terminal/configurations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Configuration', $hash ) );
}
PERL
    # NOTE: terminal_configuration_list()
    terminal_configuration_list => <<'PERL',
sub terminal_configuration_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list terminal configuration information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Terminal::Configuration', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.configuration' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    is_account_default => { type => "boolean" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Configuration', $hash ) );
}
PERL
    # NOTE: terminal_configuration_retrieve()
    terminal_configuration_retrieve => <<'PERL',
sub terminal_configuration_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.configuration' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'terminal.configuration', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No terminal.configuration id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "terminal/configurations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Configuration', $hash ) );
}
PERL
    # NOTE: terminal_configuration_update()
    terminal_configuration_update => <<'PERL',
sub terminal_configuration_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.configuration' } },
    bbpos_wisepos_e => { type => "hash" },
    tipping => { type => "hash" },
    verifone_p400 => { type => "hash" },
    };
    $args = $self->_contract( 'terminal.configuration', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No terminal.configuration id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "terminal/configurations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Configuration', $hash ) );
}
PERL
    # NOTE: terminal_configurations()
    terminal_configurations => <<'PERL',
# <https://stripe.com/docs/api/terminal/configuration>
sub terminal_configurations
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'terminal_configuration', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: terminal_connection_token()
    terminal_connection_token => <<'PERL',
sub terminal_connection_token { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Terminal::ConnectionToken', @_ ) ); }
PERL
    # NOTE: terminal_connection_token_create()
    terminal_connection_token_create => <<'PERL',
sub terminal_connection_token_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.connection_token' } },
    location => { type => "string" },
    };
    $args = $self->_contract( 'terminal.connection_token', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::ConnectionToken', $hash ) );
}
PERL
    # NOTE: terminal_connection_tokens()
    terminal_connection_tokens => <<'PERL',
# <https://stripe.com/docs/api/terminal/connection_tokens>
sub terminal_connection_tokens
{
    my $self = shift( @_ );
    my $allowed = [qw( create )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'terminal_connection_token', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: terminal_location()
    terminal_location => <<'PERL',
sub terminal_location { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Terminal::Location', @_ ) ); }
PERL
    # NOTE: terminal_location_create()
    terminal_location_create => <<'PERL',
sub terminal_location_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.location' } },
    address => { type => "hash", required => 1 },
    configuration_overrides => { type => "string" },
    display_name => { type => "string", required => 1 },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'terminal.location', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Location', $hash ) );
}
PERL
    # NOTE: terminal_location_delete()
    terminal_location_delete => <<'PERL',
sub terminal_location_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.location' } },
    };
    $args = $self->_contract( 'terminal.location', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No terminal.location id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "terminal/locations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Location', $hash ) );
}
PERL
    # NOTE: terminal_location_list()
    terminal_location_list => <<'PERL',
sub terminal_location_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list terminal location information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Terminal::Location', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.location' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Location', $hash ) );
}
PERL
    # NOTE: terminal_location_retrieve()
    terminal_location_retrieve => <<'PERL',
sub terminal_location_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.location' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'terminal.location', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No terminal.location id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "terminal/locations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Location', $hash ) );
}
PERL
    # NOTE: terminal_location_update()
    terminal_location_update => <<'PERL',
sub terminal_location_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.location' } },
    address => { type => "hash" },
    configuration_overrides => { type => "string" },
    display_name => { type => "string" },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'terminal.location', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No terminal.location id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "terminal/locations/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Location', $hash ) );
}
PERL
    # NOTE: terminal_locations()
    terminal_locations => <<'PERL',
# <https://stripe.com/docs/api/terminal/locations>
sub terminal_locations
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'terminal_location', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: terminal_reader()
    terminal_reader => <<'PERL',
sub terminal_reader { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Terminal::Reader', @_ ) ); }
PERL
    # NOTE: terminal_reader_cancel_action()
    terminal_reader_cancel_action => <<'PERL',
sub terminal_reader_cancel_action
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.reader' } },
    };
    $args = $self->_contract( 'terminal.reader', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Reader', $hash ) );
}
PERL
    # NOTE: terminal_reader_create()
    terminal_reader_create => <<'PERL',
sub terminal_reader_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.reader' } },
    label => { type => "string" },
    location => { type => "string" },
    metadata => { type => "hash" },
    registration_code => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'terminal.reader', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Reader', $hash ) );
}
PERL
    # NOTE: terminal_reader_delete()
    terminal_reader_delete => <<'PERL',
sub terminal_reader_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.reader' } },
    };
    $args = $self->_contract( 'terminal.reader', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No terminal.reader id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "terminal/readers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Reader', $hash ) );
}
PERL
    # NOTE: terminal_reader_list()
    terminal_reader_list => <<'PERL',
sub terminal_reader_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list terminal reader information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Terminal::Reader', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.reader' }, data_prefix_is_ok => 1 },
    device_type => { type => "string" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    location => { type => "string" },
    serial_number => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Reader', $hash ) );
}
PERL
    # NOTE: terminal_reader_present_payment_method()
    terminal_reader_present_payment_method => <<'PERL',
sub terminal_reader_present_payment_method
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.reader' } },
    card_present => { type => "object" },
    type => { type => "string" },
    };
    $args = $self->_contract( 'terminal.reader', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No terminal.reader id (with parameter 'id') was provided to present_payment_method its information." ) );
    my $hash = $self->post( "test_helpers/terminal/readers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Reader', $hash ) );
}
PERL
    # NOTE: terminal_reader_process_payment_intent()
    terminal_reader_process_payment_intent => <<'PERL',
sub terminal_reader_process_payment_intent
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.reader' } },
    payment_intent => { type => "string", required => 1 },
    process_config => { type => "object" },
    };
    $args = $self->_contract( 'terminal.reader', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Reader', $hash ) );
}
PERL
    # NOTE: terminal_reader_process_setup_intent()
    terminal_reader_process_setup_intent => <<'PERL',
sub terminal_reader_process_setup_intent
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.reader' } },
    customer_consent_collected => { type => "boolean", required => 1 },
    setup_intent => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'terminal.reader', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Reader', $hash ) );
}
PERL
    # NOTE: terminal_reader_retrieve()
    terminal_reader_retrieve => <<'PERL',
sub terminal_reader_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.reader' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'terminal.reader', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No terminal.reader id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "terminal/readers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Reader', $hash ) );
}
PERL
    # NOTE: terminal_reader_set_reader_display()
    terminal_reader_set_reader_display => <<'PERL',
sub terminal_reader_set_reader_display
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.reader' } },
    cart => { type => "object" },
    type => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'terminal.reader', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Reader', $hash ) );
}
PERL
    # NOTE: terminal_reader_update()
    terminal_reader_update => <<'PERL',
sub terminal_reader_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'terminal.reader' } },
    label => { type => "string" },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'terminal.reader', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No terminal.reader id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "terminal/readers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Terminal::Reader', $hash ) );
}
PERL
    # NOTE: terminal_readers()
    terminal_readers => <<'PERL',
# <https://stripe.com/docs/api/terminal/readers>
sub terminal_readers
{
    my $self = shift( @_ );
    my $allowed = [qw( cancel_action create delete list present_payment_method process_payment_intent process_setup_intent retrieve set_reader_display update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'terminal_reader', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: test_helpers_test_clock()
    test_helpers_test_clock => <<'PERL',
sub test_helpers_test_clock { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::TestHelpersTestClock', @_ ) ); }
PERL
    # NOTE: test_helpers_test_clock_advance()
    test_helpers_test_clock_advance => <<'PERL',
sub test_helpers_test_clock_advance
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'test_helpers.test_clock' } },
    frozen_time => { type => "timestamp", required => 1 },
    };
    $args = $self->_contract( 'test_helpers.test_clock', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No test_helpers.test_clock id (with parameter 'id') was provided to advance its information." ) );
    my $hash = $self->post( "test_helpers/test_clocks/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::TestHelpersTestClock', $hash ) );
}
PERL
    # NOTE: test_helpers_test_clock_create()
    test_helpers_test_clock_create => <<'PERL',
sub test_helpers_test_clock_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'test_helpers.test_clock' } },
    frozen_time => { type => "timestamp", required => 1 },
    name => { type => "string" },
    };
    $args = $self->_contract( 'test_helpers.test_clock', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::TestHelpersTestClock', $hash ) );
}
PERL
    # NOTE: test_helpers_test_clock_delete()
    test_helpers_test_clock_delete => <<'PERL',
sub test_helpers_test_clock_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'test_helpers.test_clock' } },
    };
    $args = $self->_contract( 'test_helpers.test_clock', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No test_helpers.test_clock id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "test_helpers/test_clocks/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::TestHelpersTestClock', $hash ) );
}
PERL
    # NOTE: test_helpers_test_clock_list()
    test_helpers_test_clock_list => <<'PERL',
sub test_helpers_test_clock_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list test helpers test clock information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::TestHelpersTestClock', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'test_helpers.test_clock' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::TestHelpersTestClock', $hash ) );
}
PERL
    # NOTE: test_helpers_test_clock_retrieve()
    test_helpers_test_clock_retrieve => <<'PERL',
sub test_helpers_test_clock_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'test_helpers.test_clock' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'test_helpers.test_clock', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No test_helpers.test_clock id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "test_helpers/test_clocks/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::TestHelpersTestClock', $hash ) );
}
PERL
    # NOTE: test_helpers_test_clocks()
    test_helpers_test_clocks => <<'PERL',
# <https://stripe.com/docs/api/test_clocks>
sub test_helpers_test_clocks
{
    my $self = shift( @_ );
    my $allowed = [qw( advance create delete list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'test_helpers_test_clock', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: token()
    token => <<'PERL',
# sub terminal { CORE::return( shift->_instantiate( 'terminal', 'Net::API::Stripe::Terminal' ) ) }
sub token { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Token', @_ ) ); }
PERL
    # NOTE: token_create()
    token_create => <<'PERL',
sub token_create
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to create a token" ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Token', @_ );
    my $okParams = 
    {
    expandable          => { allowed => $EXPANDABLES->{token} },
    account             => { fields => [qw( business_type company individual tos_shown_and_accepted )] },
    bank_account        => { fields => [qw( country currency account_holder_name account_holder_type routing_number account_number )] },
    card                => { fields => [qw( exp_month exp_year number currency cvc name address_line1 address_line2 address_city address_state address_zip address_country )] },
    customer            => { re => qr/^\w+$/ },
    cvc_update          => { fields => [qw( cvc )] },
    person              => { re => [qw( address.city address.country address.line1 address.line2 address.postal_code address.state
                                        address_kana.city address_kanji.line1 address_kanji.line2 address_kanji.postal_code address_kanji.state address_kanji.town
                                        address_kanji.city address_kanji.line1 address_kanji.line2 address_kanji.postal_code address_kanji.state address_kanji.town
                                        dob.day dob.month dob.year
                                        documents.company_authorization.files documents.passport.files documents.visa.files
                                        email first_name first_name.kana first_name.kanji
                                        full_name_aliases gender id_number
                                        last_name last_name.kana last_name.kanji
                                        maiden_name metadata nationality phone political_exposure
                                        relationship.director relationship.executive relationship.owner relationship.percent_ownership relationship.representative relationship.title
                                        ssn_last_4 verification.additional_document.back verification.additional_document.front 
                                        verification.document.back verification.document.front )] },
    pii                 => { fiekds => [qw( id_number )] },
    };
    $args = $self->_contract( 'token', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( 'tokens', $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Token', $hash ) );
}
PERL
    # NOTE: token_create_account()
    token_create_account => <<'PERL',
sub token_create_account
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'token' } },
    account => { type => "object", required => 1 },
    };
    $args = $self->_contract( 'token', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "tokens", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Token', $hash ) );
}
PERL
    # NOTE: token_create_bank_account()
    token_create_bank_account => <<'PERL',
sub token_create_bank_account
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'token' } },
    bank_account => { type => "hash" },
    customer => { type => "string" },
    };
    $args = $self->_contract( 'token', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "tokens", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Token', $hash ) );
}
PERL
    # NOTE: token_create_card()
    token_create_card => <<'PERL',
sub token_create_card
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'token' } },
    card => { type => "hash" },
    customer => { type => "string" },
    };
    $args = $self->_contract( 'token', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "tokens", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Token', $hash ) );
}
PERL
    # NOTE: token_create_cvc_update()
    token_create_cvc_update => <<'PERL',
sub token_create_cvc_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'token' } },
    cvc_update => { type => "object", required => 1 },
    };
    $args = $self->_contract( 'token', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "tokens", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Token', $hash ) );
}
PERL
    # NOTE: token_create_person()
    token_create_person => <<'PERL',
sub token_create_person
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'token' } },
    person => { type => "object", required => 1 },
    };
    $args = $self->_contract( 'token', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "tokens", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Token', $hash ) );
}
PERL
    # NOTE: token_create_pii()
    token_create_pii => <<'PERL',
sub token_create_pii
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'token' } },
    pii => { type => "object", required => 1 },
    };
    $args = $self->_contract( 'token', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "tokens", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Token', $hash ) );
}
PERL
    # NOTE: token_retrieve()
    token_retrieve => <<'PERL',
sub token_retrieve
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to retrieve token information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Token', @_ );
    my $okParams = 
    {
    expandable  => { allowed => $EXPANDABLES->{token} },
    id          => { re => qr/^\w+$/, required => 1 }
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No token id was provided to retrieve its information." ) );
    my $hash = $self->get( "tokens/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Token', $hash ) );
}
PERL
    # NOTE: tokens()
    tokens => <<'PERL',
# <https://stripe.com/docs/api/tokens>
sub tokens
{
    my $self = shift( @_ );
    my $allowed = [qw( create create_account create_bank_account create_card create_cvc_update create_person create_pii retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'token', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: topup()
    topup => <<'PERL',
sub topup { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::TopUp', @_ ) ); }
PERL
    # NOTE: topup_cancel()
    topup_cancel => <<'PERL',
sub topup_cancel
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'topup' } },
    };
    $args = $self->_contract( 'topup', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No topup id (with parameter 'id') was provided to cancel its information." ) );
    my $hash = $self->post( "topups/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::TopUp', $hash ) );
}
PERL
    # NOTE: topup_create()
    topup_create => <<'PERL',
sub topup_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'topup' } },
    amount => { type => "integer", required => 1 },
    currency => { type => "string", required => 1 },
    description => { type => "string" },
    metadata => { type => "hash" },
    source => { type => "hash" },
    statement_descriptor => { type => "string" },
    transfer_group => { type => "string" },
    };
    $args = $self->_contract( 'topup', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "topups", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::TopUp', $hash ) );
}
PERL
    # NOTE: topup_list()
    topup_list => <<'PERL',
sub topup_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list topup information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::TopUp', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'topup' }, data_prefix_is_ok => 1 },
    amount => { type => "integer" },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "topups", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::TopUp', $hash ) );
}
PERL
    # NOTE: topup_retrieve()
    topup_retrieve => <<'PERL',
sub topup_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'topup' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'topup', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No topup id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "topups/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::TopUp', $hash ) );
}
PERL
    # NOTE: topup_update()
    topup_update => <<'PERL',
sub topup_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'topup' } },
    description => { type => "string" },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'topup', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No topup id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "topups/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::TopUp', $hash ) );
}
PERL
    # NOTE: topups()
    topups => <<'PERL',
# <https://stripe.com/docs/api/topups>
sub topups
{
    my $self = shift( @_ );
    my $allowed = [qw( cancel create list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'topup', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: tos_acceptance()
    tos_acceptance => <<'PERL',
sub tos_acceptance { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::TosAcceptance', @_ ) ); }
PERL
    # NOTE: transfer()
    transfer => <<'PERL',
sub transfer { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Transfer', @_ ) ); }
PERL
    # NOTE: transfer_create()
    transfer_create => <<'PERL',
sub transfer_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'transfer' } },
    amount => { type => "integer" },
    currency => { type => "string", required => 1 },
    description => { type => "string" },
    destination => { type => "string", required => 1 },
    metadata => { type => "hash" },
    source_transaction => { type => "string" },
    source_type => { type => "string" },
    transfer_group => { type => "string" },
    };
    $args = $self->_contract( 'transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "transfers", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Transfer', $hash ) );
}
PERL
    # NOTE: transfer_data()
    transfer_data => <<'PERL',
sub transfer_data { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Payment::Intent::TransferData', @_ ) ); }
PERL
    # NOTE: transfer_list()
    transfer_list => <<'PERL',
sub transfer_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list transfer information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::Transfer', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'transfer' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    destination => { type => "string" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    transfer_group => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "transfers", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Transfer', $hash ) );
}
PERL
    # NOTE: transfer_retrieve()
    transfer_retrieve => <<'PERL',
sub transfer_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'transfer' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No transfer id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Transfer', $hash ) );
}
PERL
    # NOTE: transfer_reversal()
    transfer_reversal => <<'PERL',
sub transfer_reversal { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Transfer::Reversal', @_ ) ); }
PERL
    # NOTE: transfer_reversal_create()
    transfer_reversal_create => <<'PERL',
sub transfer_reversal_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'transfer_reversal' } },
    amount => { type => "integer" },
    description => { type => "string" },
    metadata => { type => "hash" },
    refund_application_fee => { type => "boolean" },
    };
    $args = $self->_contract( 'transfer_reversal', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No transfer id (with parameter 'id') was provided to create its information." ) );
    my $hash = $self->post( "transfers/${id}/reversals", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Transfer::Reversal', $hash ) );
}
PERL
    # NOTE: transfer_reversal_list()
    transfer_reversal_list => <<'PERL',
sub transfer_reversal_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list transfer reversal information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::Transfer::Reversal', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'transfer_reversal' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No transfer id (with parameter 'id') was provided to list its information." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "transfers/${id}/reversals", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Transfer::Reversal', $hash ) );
}
PERL
    # NOTE: transfer_reversal_retrieve()
    transfer_reversal_retrieve => <<'PERL',
sub transfer_reversal_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'transfer_reversal' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'transfer_reversal', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No transfer id (with parameter 'parent_id') was provided to retrieve its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No transfer_reversal id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "transfers/${parent_id}/reversals/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Transfer::Reversal', $hash ) );
}
PERL
    # NOTE: transfer_reversal_update()
    transfer_reversal_update => <<'PERL',
sub transfer_reversal_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'transfer_reversal' } },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'transfer_reversal', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $parent_id = CORE::delete( $args->{parent_id} ) || CORE::return( $self->error( "No transfer id (with parameter 'parent_id') was provided to update its information." ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No transfer_reversal id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "transfers/${parent_id}/reversals/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Transfer::Reversal', $hash ) );
}
PERL
    # NOTE: transfer_reversals()
    transfer_reversals => <<'PERL',
# <https://stripe.com/docs/api/transfer_reversals>
sub transfer_reversals
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'transfer_reversal', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: transfer_update()
    transfer_update => <<'PERL',
sub transfer_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'transfer' } },
    description => { type => "string" },
    metadata => { type => "hash" },
    };
    $args = $self->_contract( 'transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No transfer id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Connect::Transfer', $hash ) );
}
PERL
    # NOTE: transfers()
    transfers => <<'PERL',
# <https://stripe.com/docs/api/transfers>
sub transfers
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'transfer', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: transform_usage()
    transform_usage => <<'PERL',
sub transform_usage { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::Plan::TransformUsage', @_ ) ); }
PERL
    # NOTE: treasury_credit_reversal()
    treasury_credit_reversal => <<'PERL',
sub treasury_credit_reversal { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::CreditReversal', @_ ) ); }
PERL
    # NOTE: treasury_credit_reversal_create()
    treasury_credit_reversal_create => <<'PERL',
sub treasury_credit_reversal_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.credit_reversal' } },
    metadata => { type => "hash" },
    received_credit => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'treasury.credit_reversal', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::CreditReversal', $hash ) );
}
PERL
    # NOTE: treasury_credit_reversal_list()
    treasury_credit_reversal_list => <<'PERL',
sub treasury_credit_reversal_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list treasury credit reversal information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Treasury::CreditReversal', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.credit_reversal' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    financial_account => { type => "string", required => 1 },
    limit => { type => "string" },
    received_credit => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::CreditReversal', $hash ) );
}
PERL
    # NOTE: treasury_credit_reversal_retrieve()
    treasury_credit_reversal_retrieve => <<'PERL',
sub treasury_credit_reversal_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.credit_reversal' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.credit_reversal', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.credit_reversal id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/credit_reversals/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::CreditReversal', $hash ) );
}
PERL
    # NOTE: treasury_credit_reversals()
    treasury_credit_reversals => <<'PERL',
# <https://stripe.com/docs/api/treasury/credit_reversals>
sub treasury_credit_reversals
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_credit_reversal', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: treasury_debit_reversal()
    treasury_debit_reversal => <<'PERL',
sub treasury_debit_reversal { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::DebitReversal', @_ ) ); }
PERL
    # NOTE: treasury_debit_reversal_create()
    treasury_debit_reversal_create => <<'PERL',
sub treasury_debit_reversal_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.debit_reversal' } },
    metadata => { type => "hash" },
    received_debit => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'treasury.debit_reversal', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::DebitReversal', $hash ) );
}
PERL
    # NOTE: treasury_debit_reversal_list()
    treasury_debit_reversal_list => <<'PERL',
sub treasury_debit_reversal_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list treasury debit reversal information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Treasury::DebitReversal', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.debit_reversal' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    financial_account => { type => "string", required => 1 },
    limit => { type => "string" },
    received_debit => { type => "string" },
    resolution => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::DebitReversal', $hash ) );
}
PERL
    # NOTE: treasury_debit_reversal_retrieve()
    treasury_debit_reversal_retrieve => <<'PERL',
sub treasury_debit_reversal_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.debit_reversal' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.debit_reversal', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.debit_reversal id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/debit_reversals/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::DebitReversal', $hash ) );
}
PERL
    # NOTE: treasury_debit_reversals()
    treasury_debit_reversals => <<'PERL',
# <https://stripe.com/docs/api/treasury/debit_reversals>
sub treasury_debit_reversals
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_debit_reversal', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: treasury_financial_account()
    treasury_financial_account => <<'PERL',
sub treasury_financial_account { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::FinancialAccount', @_ ) ); }
PERL
    # NOTE: treasury_financial_account_create()
    treasury_financial_account_create => <<'PERL',
sub treasury_financial_account_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.financial_account' } },
    features => { type => "hash" },
    metadata => { type => "hash" },
    platform_restrictions => { type => "hash" },
    supported_currencies => { type => "array", required => 1 },
    };
    $args = $self->_contract( 'treasury.financial_account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::FinancialAccount', $hash ) );
}
PERL
    # NOTE: treasury_financial_account_features()
    treasury_financial_account_features => <<'PERL',
sub treasury_financial_account_features { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::FinancialAccountFeatures', @_ ) ); }
PERL
    # NOTE: treasury_financial_account_features_retrieve()
    treasury_financial_account_features_retrieve => <<'PERL',
sub treasury_financial_account_features_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.financial_account_features' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.financial_account_features', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.financial_account id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/financial_accounts/${id}/features", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::FinancialAccountFeatures', $hash ) );
}
PERL
    # NOTE: treasury_financial_account_features_update()
    treasury_financial_account_features_update => <<'PERL',
sub treasury_financial_account_features_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.financial_account_features' } },
    card_issuing => { type => "hash" },
    deposit_insurance => { type => "hash" },
    financial_addresses => { type => "hash" },
    inbound_transfers => { type => "hash" },
    intra_stripe_flows => { type => "hash" },
    outbound_payments => { type => "hash" },
    outbound_transfers => { type => "hash" },
    };
    $args = $self->_contract( 'treasury.financial_account_features', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.financial_account id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "treasury/financial_accounts/${id}/features", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::FinancialAccountFeatures', $hash ) );
}
PERL
    # NOTE: treasury_financial_account_featuress()
    treasury_financial_account_featuress => <<'PERL',
# <https://stripe.com/docs/api/treasury/financial_account_features>
sub treasury_financial_account_featuress
{
    my $self = shift( @_ );
    my $allowed = [qw( retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_financial_account_features', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: treasury_financial_account_list()
    treasury_financial_account_list => <<'PERL',
sub treasury_financial_account_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list treasury financial account information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Treasury::FinancialAccount', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.financial_account' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::FinancialAccount', $hash ) );
}
PERL
    # NOTE: treasury_financial_account_retrieve()
    treasury_financial_account_retrieve => <<'PERL',
sub treasury_financial_account_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.financial_account' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.financial_account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.financial_account id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/financial_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::FinancialAccount', $hash ) );
}
PERL
    # NOTE: treasury_financial_account_update()
    treasury_financial_account_update => <<'PERL',
sub treasury_financial_account_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.financial_account' } },
    features => { type => "hash" },
    metadata => { type => "hash" },
    platform_restrictions => { type => "hash" },
    };
    $args = $self->_contract( 'treasury.financial_account', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.financial_account id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "treasury/financial_accounts/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::FinancialAccount', $hash ) );
}
PERL
    # NOTE: treasury_financial_accounts()
    treasury_financial_accounts => <<'PERL',
# <https://stripe.com/docs/api/treasury/financial_accounts>
sub treasury_financial_accounts
{
    my $self = shift( @_ );
    my $allowed = [qw( create list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_financial_account', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: treasury_inbound_transfer()
    treasury_inbound_transfer => <<'PERL',
sub treasury_inbound_transfer { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::InboundTransfer', @_ ) ); }
PERL
    # NOTE: treasury_inbound_transfer_cancel()
    treasury_inbound_transfer_cancel => <<'PERL',
sub treasury_inbound_transfer_cancel
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.inbound_transfer' } },
    };
    $args = $self->_contract( 'treasury.inbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.inbound_transfer id (with parameter 'id') was provided to cancel its information." ) );
    my $hash = $self->post( "treasury/inbound_transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::InboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_inbound_transfer_create()
    treasury_inbound_transfer_create => <<'PERL',
sub treasury_inbound_transfer_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.inbound_transfer' } },
    amount => { type => "integer", required => 1 },
    currency => { type => "string", required => 1 },
    description => { type => "string" },
    financial_account => { type => "string", required => 1 },
    metadata => { type => "hash" },
    origin_payment_method => { type => "string", required => 1 },
    statement_descriptor => { type => "string" },
    };
    $args = $self->_contract( 'treasury.inbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::InboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_inbound_transfer_fail()
    treasury_inbound_transfer_fail => <<'PERL',
sub treasury_inbound_transfer_fail
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.inbound_transfer' } },
    failure_details => { type => "hash" },
    };
    $args = $self->_contract( 'treasury.inbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.inbound_transfer id (with parameter 'id') was provided to fail its information." ) );
    my $hash = $self->post( "test_helpers/treasury/inbound_transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::InboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_inbound_transfer_list()
    treasury_inbound_transfer_list => <<'PERL',
sub treasury_inbound_transfer_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list treasury inbound transfer information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Treasury::InboundTransfer', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.inbound_transfer' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    financial_account => { type => "string", required => 1 },
    limit => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::InboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_inbound_transfer_retrieve()
    treasury_inbound_transfer_retrieve => <<'PERL',
sub treasury_inbound_transfer_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.inbound_transfer' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.inbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.inbound_transfer id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/inbound_transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::InboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_inbound_transfer_return()
    treasury_inbound_transfer_return => <<'PERL',
sub treasury_inbound_transfer_return
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.inbound_transfer' } },
    };
    $args = $self->_contract( 'treasury.inbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.inbound_transfer id (with parameter 'id') was provided to return its information." ) );
    my $hash = $self->post( "test_helpers/treasury/inbound_transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::InboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_inbound_transfer_succeed()
    treasury_inbound_transfer_succeed => <<'PERL',
sub treasury_inbound_transfer_succeed
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.inbound_transfer' } },
    };
    $args = $self->_contract( 'treasury.inbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.inbound_transfer id (with parameter 'id') was provided to succeed its information." ) );
    my $hash = $self->post( "test_helpers/treasury/inbound_transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::InboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_inbound_transfers()
    treasury_inbound_transfers => <<'PERL',
# <https://stripe.com/docs/api/treasury/inbound_transfers>
sub treasury_inbound_transfers
{
    my $self = shift( @_ );
    my $allowed = [qw( cancel create fail list retrieve return succeed )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_inbound_transfer', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: treasury_outbound_payment()
    treasury_outbound_payment => <<'PERL',
sub treasury_outbound_payment { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::OutboundPayment', @_ ) ); }
PERL
    # NOTE: treasury_outbound_payment_cancel()
    treasury_outbound_payment_cancel => <<'PERL',
sub treasury_outbound_payment_cancel
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_payment' } },
    };
    $args = $self->_contract( 'treasury.outbound_payment', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.outbound_payment id (with parameter 'id') was provided to cancel its information." ) );
    my $hash = $self->post( "treasury/outbound_payments/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundPayment', $hash ) );
}
PERL
    # NOTE: treasury_outbound_payment_create()
    treasury_outbound_payment_create => <<'PERL',
sub treasury_outbound_payment_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_payment' } },
    amount => { type => "integer", required => 1 },
    currency => { type => "string", required => 1 },
    customer => { type => "string" },
    description => { type => "string" },
    destination_payment_method => { type => "string" },
    destination_payment_method_data => { type => "object" },
    destination_payment_method_options => { type => "object" },
    end_user_details => { type => "hash" },
    financial_account => { type => "string", required => 1 },
    metadata => { type => "hash" },
    statement_descriptor => { type => "string" },
    };
    $args = $self->_contract( 'treasury.outbound_payment', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundPayment', $hash ) );
}
PERL
    # NOTE: treasury_outbound_payment_fail()
    treasury_outbound_payment_fail => <<'PERL',
sub treasury_outbound_payment_fail
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_payment' } },
    };
    $args = $self->_contract( 'treasury.outbound_payment', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.outbound_payment id (with parameter 'id') was provided to fail its information." ) );
    my $hash = $self->post( "test_helpers/treasury/outbound_payments/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundPayment', $hash ) );
}
PERL
    # NOTE: treasury_outbound_payment_list()
    treasury_outbound_payment_list => <<'PERL',
sub treasury_outbound_payment_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list treasury outbound payment information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Treasury::OutboundPayment', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_payment' }, data_prefix_is_ok => 1 },
    customer => { type => "string" },
    ending_before => { type => "string" },
    financial_account => { type => "string", required => 1 },
    limit => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundPayment', $hash ) );
}
PERL
    # NOTE: treasury_outbound_payment_post()
    treasury_outbound_payment_post => <<'PERL',
sub treasury_outbound_payment_post
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_payment' } },
    };
    $args = $self->_contract( 'treasury.outbound_payment', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.outbound_payment id (with parameter 'id') was provided to post its information." ) );
    my $hash = $self->post( "test_helpers/treasury/outbound_payments/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundPayment', $hash ) );
}
PERL
    # NOTE: treasury_outbound_payment_retrieve()
    treasury_outbound_payment_retrieve => <<'PERL',
sub treasury_outbound_payment_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_payment' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.outbound_payment', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.outbound_payment id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/outbound_payments/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundPayment', $hash ) );
}
PERL
    # NOTE: treasury_outbound_payment_return()
    treasury_outbound_payment_return => <<'PERL',
sub treasury_outbound_payment_return
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_payment' } },
    returned_details => { type => "hash" },
    };
    $args = $self->_contract( 'treasury.outbound_payment', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.outbound_payment id (with parameter 'id') was provided to return its information." ) );
    my $hash = $self->post( "test_helpers/treasury/outbound_payments/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundPayment', $hash ) );
}
PERL
    # NOTE: treasury_outbound_payments()
    treasury_outbound_payments => <<'PERL',
# <https://stripe.com/docs/api/treasury/outbound_payments>
sub treasury_outbound_payments
{
    my $self = shift( @_ );
    my $allowed = [qw( cancel create fail list post retrieve return )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_outbound_payment', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: treasury_outbound_transfer()
    treasury_outbound_transfer => <<'PERL',
sub treasury_outbound_transfer { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::OutboundTransfer', @_ ) ); }
PERL
    # NOTE: treasury_outbound_transfer_cancel()
    treasury_outbound_transfer_cancel => <<'PERL',
sub treasury_outbound_transfer_cancel
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_transfer' } },
    };
    $args = $self->_contract( 'treasury.outbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.outbound_transfer id (with parameter 'id') was provided to cancel its information." ) );
    my $hash = $self->post( "treasury/outbound_transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_outbound_transfer_create()
    treasury_outbound_transfer_create => <<'PERL',
sub treasury_outbound_transfer_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_transfer' } },
    amount => { type => "integer", required => 1 },
    currency => { type => "string", required => 1 },
    description => { type => "string" },
    destination_payment_method => { type => "string" },
    destination_payment_method_options => { type => "object" },
    financial_account => { type => "string", required => 1 },
    metadata => { type => "hash" },
    statement_descriptor => { type => "string" },
    };
    $args = $self->_contract( 'treasury.outbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_outbound_transfer_fail()
    treasury_outbound_transfer_fail => <<'PERL',
sub treasury_outbound_transfer_fail
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_transfer' } },
    };
    $args = $self->_contract( 'treasury.outbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.outbound_transfer id (with parameter 'id') was provided to fail its information." ) );
    my $hash = $self->post( "test_helpers/treasury/outbound_transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_outbound_transfer_list()
    treasury_outbound_transfer_list => <<'PERL',
sub treasury_outbound_transfer_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list treasury outbound transfer information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Treasury::OutboundTransfer', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_transfer' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    financial_account => { type => "string", required => 1 },
    limit => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_outbound_transfer_post()
    treasury_outbound_transfer_post => <<'PERL',
sub treasury_outbound_transfer_post
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_transfer' } },
    };
    $args = $self->_contract( 'treasury.outbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.outbound_transfer id (with parameter 'id') was provided to post its information." ) );
    my $hash = $self->post( "test_helpers/treasury/outbound_transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_outbound_transfer_retrieve()
    treasury_outbound_transfer_retrieve => <<'PERL',
sub treasury_outbound_transfer_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_transfer' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.outbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.outbound_transfer id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/outbound_transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_outbound_transfer_return()
    treasury_outbound_transfer_return => <<'PERL',
sub treasury_outbound_transfer_return
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.outbound_transfer' } },
    returned_details => { type => "hash" },
    };
    $args = $self->_contract( 'treasury.outbound_transfer', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.outbound_transfer id (with parameter 'id') was provided to return its information." ) );
    my $hash = $self->post( "test_helpers/treasury/outbound_transfers/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::OutboundTransfer', $hash ) );
}
PERL
    # NOTE: treasury_outbound_transfers()
    treasury_outbound_transfers => <<'PERL',
# <https://stripe.com/docs/api/treasury/outbound_transfers>
sub treasury_outbound_transfers
{
    my $self = shift( @_ );
    my $allowed = [qw( cancel create fail list post retrieve return )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_outbound_transfer', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: treasury_received_credit()
    treasury_received_credit => <<'PERL',
sub treasury_received_credit { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::ReceivedCredit', @_ ) ); }
PERL
    # NOTE: treasury_received_credit_list()
    treasury_received_credit_list => <<'PERL',
sub treasury_received_credit_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list treasury received credit information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Treasury::ReceivedCredit', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.received_credit' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    financial_account => { type => "string", required => 1 },
    limit => { type => "string" },
    linked_flows => { type => "hash" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::ReceivedCredit', $hash ) );
}
PERL
    # NOTE: treasury_received_credit_received_credit()
    treasury_received_credit_received_credit => <<'PERL',
sub treasury_received_credit_received_credit
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.received_credit' } },
    amount => { type => "integer", required => 1 },
    currency => { type => "string", required => 1 },
    description => { type => "string" },
    financial_account => { type => "string", required => 1 },
    initiating_payment_method_details => { type => "hash" },
    network => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'treasury.received_credit', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "test_helpers/treasury/received_credits", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::ReceivedCredit', $hash ) );
}
PERL
    # NOTE: treasury_received_credit_retrieve()
    treasury_received_credit_retrieve => <<'PERL',
sub treasury_received_credit_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.received_credit' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.received_credit', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.received_credit id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/received_credits/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::ReceivedCredit', $hash ) );
}
PERL
    # NOTE: treasury_received_credits()
    treasury_received_credits => <<'PERL',
# <https://stripe.com/docs/api/treasury/received_credits>
sub treasury_received_credits
{
    my $self = shift( @_ );
    my $allowed = [qw( list received_credit retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_received_credit', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: treasury_received_debit()
    treasury_received_debit => <<'PERL',
sub treasury_received_debit { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::ReceivedDebit', @_ ) ); }
PERL
    # NOTE: treasury_received_debit_list()
    treasury_received_debit_list => <<'PERL',
sub treasury_received_debit_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list treasury received debit information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Treasury::ReceivedDebit', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.received_debit' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    financial_account => { type => "string", required => 1 },
    limit => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::ReceivedDebit', $hash ) );
}
PERL
    # NOTE: treasury_received_debit_received_debit()
    treasury_received_debit_received_debit => <<'PERL',
sub treasury_received_debit_received_debit
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.received_debit' } },
    amount => { type => "integer", required => 1 },
    currency => { type => "string", required => 1 },
    description => { type => "string" },
    financial_account => { type => "string", required => 1 },
    initiating_payment_method_details => { type => "hash" },
    network => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'treasury.received_debit', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "test_helpers/treasury/received_debits", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::ReceivedDebit', $hash ) );
}
PERL
    # NOTE: treasury_received_debit_retrieve()
    treasury_received_debit_retrieve => <<'PERL',
sub treasury_received_debit_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.received_debit' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.received_debit', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.received_debit id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/received_debits/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::ReceivedDebit', $hash ) );
}
PERL
    # NOTE: treasury_received_debits()
    treasury_received_debits => <<'PERL',
# <https://stripe.com/docs/api/treasury/received_debits>
sub treasury_received_debits
{
    my $self = shift( @_ );
    my $allowed = [qw( list received_debit retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_received_debit', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: treasury_transaction()
    treasury_transaction => <<'PERL',
sub treasury_transaction { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::Transaction', @_ ) ); }
PERL
    # NOTE: treasury_transaction_entry()
    treasury_transaction_entry => <<'PERL',
sub treasury_transaction_entry { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Treasury::TransactionEntry', @_ ) ); }
PERL
    # NOTE: treasury_transaction_entry_list()
    treasury_transaction_entry_list => <<'PERL',
sub treasury_transaction_entry_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list treasury transaction entry information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Treasury::TransactionEntry', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.transaction_entry' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    effective_at => { type => "timestamp" },
    ending_before => { type => "string" },
    financial_account => { type => "string", required => 1 },
    limit => { type => "string" },
    order_by => { type => "string" },
    starting_after => { type => "string" },
    transaction => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "treasury/transaction_entries", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::TransactionEntry', $hash ) );
}
PERL
    # NOTE: treasury_transaction_entry_retrieve()
    treasury_transaction_entry_retrieve => <<'PERL',
sub treasury_transaction_entry_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.transaction_entry' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.transaction_entry', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.transaction_entry id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/transaction_entries/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::TransactionEntry', $hash ) );
}
PERL
    # NOTE: treasury_transaction_entrys()
    treasury_transaction_entrys => <<'PERL',
# <https://stripe.com/docs/api/treasury/transaction_entries>
sub treasury_transaction_entrys
{
    my $self = shift( @_ );
    my $allowed = [qw( list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_transaction_entry', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: treasury_transaction_list()
    treasury_transaction_list => <<'PERL',
sub treasury_transaction_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list treasury transaction information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Treasury::Transaction', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.transaction' }, data_prefix_is_ok => 1 },
    created => { type => "timestamp" },
    ending_before => { type => "string" },
    financial_account => { type => "string", required => 1 },
    limit => { type => "string" },
    order_by => { type => "string" },
    starting_after => { type => "string" },
    status => { type => "string" },
    status_transitions => { type => "hash" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::Transaction', $hash ) );
}
PERL
    # NOTE: treasury_transaction_retrieve()
    treasury_transaction_retrieve => <<'PERL',
sub treasury_transaction_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'treasury.transaction' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'treasury.transaction', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No treasury.transaction id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "treasury/transactions/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Treasury::Transaction', $hash ) );
}
PERL
    # NOTE: treasury_transactions()
    treasury_transactions => <<'PERL',
# <https://stripe.com/docs/api/treasury/transactions>
sub treasury_transactions
{
    my $self = shift( @_ );
    my $allowed = [qw( list retrieve )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'treasury_transaction', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: usage_record()
    usage_record => <<'PERL',
sub usage_record { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::UsageRecord', @_ ) ); }
PERL
    # NOTE: usage_record_create()
    usage_record_create => <<'PERL',
sub usage_record_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'usage_record' } },
    action => { type => "string" },
    quantity => { type => "integer", required => 1 },
    timestamp => { type => "timestamp" },
    };
    $args = $self->_contract( 'usage_record', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription_item id (with parameter 'id') was provided to create its information." ) );
    my $hash = $self->post( "subscription_items/${id}/usage_records", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::UsageRecord', $hash ) );
}
PERL
    # NOTE: usage_record_list()
    usage_record_list => <<'PERL',
sub usage_record_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list usage record information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::UsageRecord', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'usage_record' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No subscription_item id (with parameter 'id') was provided to list its information." ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "subscription_items/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::Billing::UsageRecord', $hash ) );
}
PERL
    # NOTE: usage_record_summary()
    usage_record_summary => <<'PERL',
sub usage_record_summary { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Billing::UserRecord::Summary', @_ ) ); }
PERL
    # NOTE: usage_records()
    usage_records => <<'PERL',
# <https://stripe.com/docs/api/usage_records>
sub usage_records
{
    my $self = shift( @_ );
    my $allowed = [qw( create list )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'usage_record', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    # NOTE: value_list()
    value_list => <<'PERL',
sub value_list { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Fraud::ValueList', @_ ) ); }
PERL
    # NOTE: value_list_item()
    value_list_item => <<'PERL',
sub value_list_item { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Fraud::ValueList::Item', @_ ) ); }
PERL
    # NOTE: verification()
    verification => <<'PERL',
sub verification { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::Verification', @_ ) ); }
PERL
    # NOTE: verification_data()
    verification_data => <<'PERL',
sub verification_data { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Authorization::VerificationData', @_ ) ); }
PERL
    # NOTE: verification_fields()
    verification_fields => <<'PERL',
sub verification_fields { CORE::return( shift->_response_to_object( 'Net::API::Stripe::Connect::CountrySpec::VerificationFields', @_ ) ); }
PERL
    # NOTE: webhook()
    webhook => <<'PERL',
sub webhook { CORE::return( shift->_response_to_object( 'Net::API::Stripe::WebHook::Object' ) ) }
PERL
    # NOTE: webhook_endpoint()
    webhook_endpoint => <<'PERL',
sub webhook_endpoint { CORE::return( shift->_response_to_object( 'Net::API::Stripe::WebHook::Object', @_ ) ); }
PERL
    # NOTE: webhook_endpoint_create()
    webhook_endpoint_create => <<'PERL',
sub webhook_endpoint_create
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'webhook_endpoint' } },
    api_version => { type => "string" },
    connect => { type => "boolean" },
    description => { type => "string" },
    enabled_events => { type => "array", required => 1 },
    metadata => { type => "hash" },
    url => { type => "string", required => 1 },
    };
    $args = $self->_contract( 'webhook_endpoint', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $hash = $self->post( "webhook_endpoints", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::WebHook::Object', $hash ) );
}
PERL
    # NOTE: webhook_endpoint_delete()
    webhook_endpoint_delete => <<'PERL',
sub webhook_endpoint_delete
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'webhook_endpoint' } },
    };
    $args = $self->_contract( 'webhook_endpoint', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No webhook_endpoint id (with parameter 'id') was provided to delete its information." ) );
    my $hash = $self->delete( "webhook_endpoints/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::WebHook::Object', $hash ) );
}
PERL
    # NOTE: webhook_endpoint_list()
    webhook_endpoint_list => <<'PERL',
sub webhook_endpoint_list
{
    my $self = shift( @_ );
    CORE::return( $self->error( "No parameters were provided to list webhook endpoint information." ) ) if( !scalar( @_ ) );
    my $args = $self->_get_args_from_object( 'Net::API::Stripe::WebHook::Object', @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'webhook_endpoint' }, data_prefix_is_ok => 1 },
    ending_before => { type => "string" },
    limit => { type => "string" },
    starting_after => { type => "string" },
    };
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    if( $args->{expand} )
    {
        $self->_adjust_list_expandables( $args ) || CORE::return( $self->pass_error );
    }
    my $hash = $self->get( "webhook_endpoints", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::WebHook::Object', $hash ) );
}
PERL
    # NOTE: webhook_endpoint_retrieve()
    webhook_endpoint_retrieve => <<'PERL',
sub webhook_endpoint_retrieve
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'webhook_endpoint' }, data_prefix_is_ok => 1 },
    };
    $args = $self->_contract( 'webhook_endpoint', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No webhook_endpoint id (with parameter 'id') was provided to retrieve its information." ) );
    my $hash = $self->get( "webhook_endpoints/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::WebHook::Object', $hash ) );
}
PERL
    # NOTE: webhook_endpoint_update()
    webhook_endpoint_update => <<'PERL',
sub webhook_endpoint_update
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $okParams =
    {
    expandable  => { allowed => $EXPANDABLES->{ 'webhook_endpoint' } },
    description => { type => "string" },
    disabled => { type => "boolean" },
    enabled_events => { type => "array" },
    metadata => { type => "hash" },
    url => { type => "string" },
    };
    $args = $self->_contract( 'webhook_endpoint', $args ) || CORE::return( $self->pass_error );
    my $err = $self->_check_parameters( $okParams, $args );
    CORE::return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
    my $id = CORE::delete( $args->{id} ) || CORE::return( $self->error( "No webhook_endpoint id (with parameter 'id') was provided to update its information." ) );
    my $hash = $self->post( "webhook_endpoints/${id}", $args ) || CORE::return( $self->pass_error );
    CORE::return( $self->_response_to_object( 'Net::API::Stripe::WebHook::Object', $hash ) );
}
PERL
    # NOTE: webhook_endpoints()
    webhook_endpoints => <<'PERL',
# <https://stripe.com/docs/api/webhook_endpoints>
sub webhook_endpoints
{
    my $self = shift( @_ );
    my $allowed = [qw( create delete list retrieve update )];
    my $action = shift( @_ );
    my $meth = $self->_get_method( 'webhook_endpoint', $action, $allowed ) || CORE::return( $self->pass_error );
    CORE::return( $self->$meth( @_ ) );
}
PERL
    };
}
# NOTE: End of auto-generated methods


sub _adjust_list_expandables
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    CORE::return( $self->error( "User parameters list provided is '$args' and I was expecting a hash reference." ) ) if( ref( $args ) ne 'HASH' );
    if( ref( $args->{expand} ) eq 'ARRAY' )
    {
        my $new = [];
        for( my $i = 0; $i < scalar( @{$args->{expand}} ); $i++ )
        {
            substr( $args->{expand}->[$i], 0, 0 ) = 'data.' if( substr( $args->{expand}->[$i], 0, 5 ) ne 'data.' );
            my $path = [split( /\./, $args->{expand}->[$i] )];
            # Make sure that with the new 'data' prefix, this does not exceed 4 level of depth
            push( @$new, $args->{expand}->[$i] ) if( scalar( @$path ) <= $EXPAND_MAX_DEPTH );
        }
        $args->{expand} = $new;
    }
    CORE::return( $self );
}

sub _as_hash
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    my $opts = {};
    $opts = shift( @_ ) if( @_ && ref( $_[0] ) eq 'HASH' );
    $opts->{seen} = {} if( !$opts->{seen} );
    my $ref = {};
    if( $self->_is_object( $this ) )
    {
        $ref = $this->as_hash if( $this->can( 'as_hash' ) );
    }
    # Recursively transform into hash
    elsif( ref( $this ) eq 'HASH' )
    {
        # Prevent recursion
        my $ref_addr = Scalar::Util::refaddr( $this );
        CORE::return( $opts->{seen}->{ $ref_addr } ) if( $opts->{seen}->{ $ref_addr } );
        $opts->{seen}->{ $ref_addr } = $this;
        # $ref = $hash;
        foreach my $k ( keys( %$this ) )
        {
            if( ref( $this->{ $k } ) eq 'HASH' || $self->_is_object( $this->{ $k } ) )
            {
                my $rv = $self->_as_hash( $this->{ $k }, $opts );
                $ref->{ $k } = $rv if( scalar( keys( %$rv ) ) );
            }
            elsif( ref( $this->{ $k } ) eq 'ARRAY' )
            {
                my $new = [];
                foreach my $that ( @{$this->{ $k }} )
                {
                    if( ref( $that ) eq 'HASH' || $self->_is_object( $that ) )
                    {
                        my $rv = $self->_as_hash( $that, $opts );
                        push( @$new, $rv ) if( scalar( keys( %$rv ) ) );
                    }
                }
                $ref->{ $k } = $new if( scalar( @$new ) );
            }
            # For stringification
            elsif( CORE::length( "$this->{$k}" ) )
            {
                $ref->{ $k } = $this->{ $k };
            }
        }
    }
    else
    {
        CORE::return( $self->error( "Unknown data type $this to be converted into hash for api call." ) );
    }
    CORE::return( $ref );
}

sub _check_parameters
{
    my $self = shift( @_ );
    my $okParams = shift( @_ );
    my $args   = shift( @_ );
    # $self->dumpto_dumper( $args, '/home/ai/legal/var/check_parameters.pl' );
    my $err = [];
    
    my $seen = {};
    my $check_fields_recursive;
    $check_fields_recursive = sub
    {
        my( $hash, $mirror, $field, $required ) = @_;
        my $errors = [];
        #   push( @$err, "Unknown property $v for key $k." ) if( !scalar( grep( /^$v$/, @$this ) ) );
        foreach my $k ( sort( keys( %$hash ) ) )
        {
            if( !CORE::exists( $mirror->{ $k } ) )
            {
                push( @$errors, "Unknown property \"$k\" for key \"$field\"." );
                next;
            }
            my $addr;
            $addr = Scalar::Util::refaddr( $hash->{ $k } ) if( ref( $hash->{ $k } ) eq 'HASH' );
            # Found a hash, check recursively and avoid looping endlessly
            if( ref( $hash->{ $k } ) eq 'HASH' && 
                ref( $mirror->{ $k } ) eq 'HASH' &&
                # ++$hash->{ $k }->{__check_fields_recursive_looping} == 1 )
                ++$seen->{ $addr } == 1 )
            {
                my $deep_errors = $check_fields_recursive->( $hash->{ $k }, $mirror->{ $k }, $k, CORE::exists( $required->{ $k } ) ? $required->{ $k } : {} );
                CORE::push( @$errors, @$deep_errors );
            }
        }
        
        # Check required fields
        # if in the mirror structure, the field value is 1, the field is required, otherwise with 0 the field is not required
        foreach my $k ( sort( keys( %$mirror ) ) )
        {
            next if( $k eq '_required' );
            # If this property contains sub properties, we look at the sub hash entry _required to check if this property is required or not
            if( ref( $mirror->{ $k } ) eq 'HASH' )
            {
                if( !CORE::exists( $hash->{ $k } ) && $mirror->{ $k }->{_required} )
                {
                    CORE::push( @$errors, "Hash property \"$k\" is required but missing in hash provided for parent field \"$field\"." );
                }
            }
            else
            {
                if( ( !CORE::exists( $hash->{ $k } ) || !CORE::length( $hash->{ $k } ) ) &&
                    $mirror->{ $k } )
                {
                    CORE::push( @$errors, "Field \"$k\" is required but missing in hash provided for parent field \"$field\"." );
                }
            }
        }
        CORE::return( $errors );
    };
    
    foreach my $k ( keys( %$args ) )
    {
        # Special case for expand and for private parameters starting with '_'
        next if( $k eq 'expand' || $k eq 'expandable' || substr( $k, 0, 1 ) eq '_' );
#         if( !CORE::exists( $okParams->{ $k } ) )
#         {
#             # This is handy when an object was passed to one of the api method and 
#             # the object contains a bunch of data not all relevant to the api call
#             # It makes it easy to pass the object and let this interface take only what is relevant
#             if( $okParams->{_cleanup} || $args->{_cleanup} || $self->ignore_unknown_parameters )
#             {
#                 CORE::delete( $args->{ $k } );
#             }
#             else
#             {
#                 push( @$err, "Unknown parameter \"$k\"." );
#             }
#             next;
#         }
        # $dict is either a hash dictionary or a sub
        my $dict = $okParams->{ $k };
        if( ref( $dict ) eq 'HASH' )
        {
            my $pkg;
#             if( $dict->{fields} && ref( $dict->{fields} ) eq 'ARRAY' )
#             {
#                 my $this = $dict->{fields};
#                 if( ref( $args->{ $k } ) eq 'ARRAY' && $dict->{type} eq 'array' )
#                 {
#                     # Just saying it's ok
#                 }
#                 elsif( ref( $args->{ $k } ) ne 'HASH' )
#                 {
#                     push( @$err, sprintf( "Parameter \"$k\" must be a dictionary definition with following possible hash keys: \"%s\". Did you forget type => 'array' ?", join( ', ', @$this ) ) );
#                     next;
#                 }
#                 
#                 # We build a test mirror hash structure against which we will check if actual data fields exist or not
#                 my $mirror = {};
#                 # $self->messagef( 7, "Building mirror check data structure fpr '$k' with %d fields.", scalar( @$this ) );
#                 foreach my $f ( @$this )
#                 {
#                     my @path = CORE::split( /\./, $f );
#                     # $self->message( 7, "\tProcessing '$f'." );
#                     my $parent_hash = $mirror;
#                     for( my $i = 0; $i < scalar( @path ); $i++ )
#                     {
#                         my $p = $path[$i];
#                         my $is_required = 0;
#                         if( substr( $p, -1, 1 ) eq '!' )
#                         {
#                             $p = substr( $p, 0, CORE::length( $p ) - 1 );
#                             $is_required = 1;
#                         }
#                         # $self->message( 7, "\t\t$p is ", ( $is_required ? '' : 'not ' ), "required." );
#                         
#                         if( $i == $#path )
#                         {
#                             $parent_hash->{ $p } = $is_required;
#                         }
#                         else
#                         {
#                             my $prev_val = $parent_hash->{ $p };
#                             $parent_hash->{ $p } = {} unless( CORE::exists( $parent_hash->{ $p } ) && ref( $parent_hash->{ $p } ) eq 'HASH' );
#                             $parent_hash = $parent_hash->{ $p };
#                             unless( exists( $parent_hash->{_required} ) )
#                             {
#                                 $parent_hash->{_required} = $is_required ? $is_required : ref( $prev_val ) ne 'HASH' ? $prev_val : $is_required;
#                             }
#                         }
#                     }
#                 }
#                 
#                 # $self->message( 7, "Mirror is: ", sub{ $self->dump( $mirror ); } );
#                 
#                 # Do we have dots in field names? If so, this is a multi dimensional hash we are potentially looking at
#                 if( ref( $args->{ $k } ) eq 'HASH' )
#                 {
#                     my $res = $check_fields_recursive->( $args->{ $k }, $mirror, $k, ( exists( $dict->{required} ) ? $dict->{required} : {} ) );
#                     push( @$err, @$res ) if( scalar( @$res ) );
#                 }
#                 elsif( ref( $args->{ $k } ) eq 'ARRAY' && $dict->{type} eq 'array' )
#                 {
#                     my $arr = $args->{ $k };
#                     for( my $i = 0; $i < scalar( @$arr ); $i++ )
#                     {
#                         if( ref( $arr->[ $i ] ) ne 'HASH' )
#                         {
#                             push( @$err, sprintf( "Invalid data type at offset $i. Parameter \"$k\" must be a dictionary definition with following possible hash keys: \"%s\"", join( ', ', @$this ) ) );
#                             next;
#                         }
#                         my $res = $check_fields_recursive->( $arr->[ $i ], $mirror, $k, ( exists( $dict->{required} ) ? $dict->{required} : {} ) );
#                         push( @$err, @$res ) if( scalar( @$res ) );
#                     }
#                 }
#                 # $clean_up_check_fields_recursive->( $args->{ $k } );
#             }
            
            if( defined( $dict->{required} ) && 
                $dict->{required} && 
                !CORE::exists( $args->{ $k } ) )
            {
                push( @$err, "Parameter \"$k\" is required, but missing" );
            }
            elsif( !defined( $args->{ $k } ) || 
                   !length( $args->{ $k } ) )
            {
                push( @$err, "Empty value provided for parameter \"$k\"." );
            }
            # _is_object is inherited from Module::Object
            elsif( ( $pkg = $self->_is_object( $args->{ $k } ) ) && $dict->{package} && $dict->{package} ne $pkg )
            {
                push( @$err, "Parameter \"$k\" value is a package \"$pkg\", but I was expecting \"$dict->{package}\"" );
            }
            elsif( $dict->{re} && ref( $dict->{re} ) eq 'Regexp' && $args->{ $k } !~ /$dict->{re}/ )
            {
                push( @$err, "Parameter \"$k\" with value \"$args->{$k}\" does not have a legitimate value." );
            }
            elsif( defined( $dict->{type} ) &&
                   $dict->{type} && 
                   ( 
                       ( $dict->{type} eq 'scalar' && ref( $args->{ $k } ) ) ||
                       ( $dict->{type} ne 'scalar' && ref( $args->{ $k } ) && lc( ref( $args->{ $k } ) ) ne $dict->{type} )
                   )
                 )
            {
                push( @$err, "I was expecting a data of type $dict->{type}, but got " . lc( ref( $args->{ $k } ) ) );
            }
            elsif( defined( $dict->{type} ) &&
                   $dict->{type} eq 'boolean' && 
                   defined( $args->{ $k } ) && 
                   CORE::length( $args->{ $k } ) )
            {
                $args->{ $k } = ( $args->{ $k } eq 'true' || ( $args->{ $k } ne 'false' && $args->{ $k } ) ) ? 'true' : 'false';
            }
            elsif( defined( $dict->{type} ) &&
                   $dict->{type} eq 'integer' )
            {
                push( @$err, "Parameter \"$k\" value \" $args->{$k}\" is not an integer." ) if( $args->{ $k } !~ /^[-+]?\d+$/ );
            }
            elsif( defined( $dict->{type} ) &&
                   (
                       $dict->{type} eq 'number' || 
                       $dict->{type} eq 'decimal' || 
                       $dict->{type} eq 'float' || 
                       $dict->{type} eq 'double'
                   ) )
            {
                push( @$err, "Parameter \"$k\" value \" $args->{$k}\" is not a $dict->{type}." ) if( $args->{ $k } !~ /^$RE{num}{real}$/ );
            }
            elsif( defined( $dict->{type} ) &&
                   (
                       $dict->{type} eq 'date' || 
                       $dict->{type} eq 'datetime' ||
                       $dict->{type} eq 'timestamp' 
                   ) )
            {
                unless( $self->_is_object( $args->{ $k } ) && $args->{ $k }->isa( 'DateTime' ) )
                {
                    my $tz = $dict->{time_zone} ? $dict->{time_zone} : 'GMT';
                    my $dt;
                    if( $dict->{type} eq 'date' &&
                        $args->{ $k } =~ /^(?<year>\d{4})[\.|\-](?<month>\d{1,2})[\.|\-](?<day>\d{1,2})$/ )
                    {
                        try
                        {
                            $dt = DateTime(
                                year => int( $+{year} ),
                                month => int( $+{month} ),
                                day => int( $+{day} ),
                                hour => 0,
                                minute => 0,
                                second => 0,
                                time_zone => $tz
                            );
                            $args->{ $k } = $dt;
                        }
                        catch( $e )
                        {
                            push( @$err, "Invalid date (" . $args->{ $k } . ") provided for parameter \"$k\": $e" );
                        }
                    }
                    elsif( $dict->{type} eq 'datetime' &&
                        $args->{ $k } =~ /^(?<year>\d{4})[\.|\-](?<month>\d{1,2})[\.|\-](?<day>\d{1,2})[T|[:blank:]]+(?<hour>\d{1,2}):(?<minute>\d{1,2}):(?<second>\d{1,2})$/ )
                    {
                        try
                        {
                            $dt = DateTime(
                                year => int( $+{year} ),
                                month => int( $+{month} ),
                                day => int( $+{day} ),
                                hour => int( $+{hour} ),
                                minute => int( $+{minute} ),
                                second => int( $+{second} ),
                                time_zone => $tz
                            );
                            $args->{ $k } = $dt;
                        }
                        catch( $e )
                        {
                            push( @$err, "Invalid datetime (" . $args->{ $k } . ") provided for parameter \"$k\": $e" );
                        }
                    }
                    elsif( $args->{ $k } =~ /^\d+$/ )
                    {
                        try
                        {
                            $dt = DateTime->from_epoch(
                                epoch => $args->{ $k },
                                time_zone => $tz,
                            );
                        }
                        catch( $e )
                        {
                            push( @$err, "Invalid timestamp (" . $args->{ $k } . ") provided for parameter \"$k\": $e" );
                        }
                    }
                    if( $dt )
                    {
                        my $pattern = $dict->{pattern} ? $dict->{pattern} : '%s';
                        my $strp = DateTime::Format::Strptime->new(
                            pattern => $pattern,
                            locale => 'en_GB',
                            time_zone => $tz,
                        );
                        $dt->set_formatter( $strp );
                        $args->{ $k } = $dt;
                    }
                }
            }
        }
        elsif( ref( $dict ) eq 'CODE' )
        {
            my $res = $dict->( $args->{ $k } );
            push( @$err, "Invalid parameter \"$k\" with value \"$args->{$k}\": $res" ) if( $res );
        }
    }
    
    $args->{expand} = $self->expand if( !CORE::length( $args->{expand} ) );
    if( exists( $args->{expand} ) )
    {
        my $depth;
        my $no_need_to_check = 0;
        if( $args->{expand} eq 'all' || $args->{expand} =~ /^\d+$/ )
        {
            $no_need_to_check++;
            if( $args->{expand} =~ /^\d+$/ )
            {
                $depth = int( $args->{expand} );
            }
            else
            {
                $depth = $EXPAND_MAX_DEPTH;
            }
            if( exists( $okParams->{expandable} ) && exists( $okParams->{expandable}->{allowed} ) && ref( $okParams->{expandable}->{allowed} ) eq 'ARRAY' )
            {
                # We duplicate the array, so the original array does not get modified
                # This is important, because methods that list objects such as customer_list use the 'data' property
                $args->{expand} = [ @{$okParams->{expandable}->{allowed}} ];
            }
            # There is no allowed expandable properties, but it was called anyway, so we do this to avoid an error below
            else
            {
                $args->{expand} = [];
            }
        }
        push( @$err, sprintf( "expand property should be an array, but instead '%s' was provided", $args->{expand} ) ) if( ref( $args->{expand} ) ne 'ARRAY' );
        if( scalar( @{$args->{expand}} ) && exists( $okParams->{expandable} ) )
        {
            CORE::return( $self->error( "expandable parameter is not a hash (", ref( $okParams->{expandable} ), ")." ) ) if( ref( $okParams->{expandable} ) ne 'HASH' );
            CORE::return( $self->error( "No \"allowed\" attribute in the expandable parameter hash." ) ) if( !CORE::exists( $okParams->{expandable}->{allowed} ) );
            my $expandable = $okParams->{expandable}->{allowed};
            my $errExpandables = [];
            if( !$no_need_to_check )
            {
                if( scalar( @$expandable ) )
                {
                    CORE::return( $self->error( "List of expandable attributes needs to be an array reference, but found instead a ", ref( $expandable ) ) ) if( ref( $expandable ) ne 'ARRAY' );
                    # Return a list with the dot prefixed with backslash
                    my $list = join( '|', map( quotemeta( $_ ), @$expandable ) );
                    my $re = $okParams->{expandable}->{data_prefix_is_ok} ? qr/^(?:data\.)?($list)$/ : qr/^($list)$/;
                    foreach my $k ( @{$args->{expand}} )
                    {
                        if( $k !~ /$re/ )
                        {
                            push( @$errExpandables, $k );
                        }
                    }
                }
                else
                {
                    push( @$errExpandables, @{$args->{expand}} );
                }
            }
            elsif( $depth )
            {
                my $max_depth = CORE::length( $depth ) ? $depth : $EXPAND_MAX_DEPTH;
                for( my $i = 0; $i < scalar( @{$args->{expand}} ); $i++ )
                {
                    # Count the number of dots. Make sure this does not exceed the $EXPAND_MAX_DEPTH which is 4 as of today (2020-02-23)
                    # my $this_depth = scalar( () = $args->{expand}->[$i] =~ /\./g );
                    my $path_parts = [split( /\./, $args->{expand}->[$i] )];
                    if( scalar( @$path_parts ) > $max_depth )
                    {
                        my $old = [CORE::splice( @$path_parts, $max_depth - 1 )];
                        $args->{expand}->[$i] = $path_parts;
                    }
                }
            }
            push( @$err, sprintf( "The following properties are not allowed to expand: %s", join( ', ', @$errExpandables ) ) ) if( scalar( @$errExpandables ) );
        }
        elsif( !exists( $okParams->{expandable} ) )
        {
            push( @$err, sprintf( "Following elements were provided to be expanded, but no expansion is supported: '%s'.", CORE::join( "', '", @{$args->{expand}} ) ) ) if( scalar( @{$args->{expand}} ) );
        }
    }
    else
    {
    }
    my @private_params = grep( /^_/, keys( %$args ) );
    CORE::delete( @$args{ @private_params } );
    CORE::return( $err );
}

sub _check_required
{
    my $self = shift( @_ );
    my $required = shift( @_ );
    CORE::return( $self->error( "I was expecting an array reference of required field." ) ) if( ref( $required ) ne 'ARRAY' );
    my $args = shift( @_ );
    CORE::return( $self->error( "I was expecting an hash reference of parameters." ) ) if( ref( $args ) ne 'HASH' );
    my $err = [];
    foreach my $f ( @$required )
    {
        push( @$err, "Parameter $f is missing, and is required." ) if( !CORE::exists( $args->{ $f } ) || !CORE::length( $args->{ $f } ) );
    }
    CORE::return( $args );
}

# As in opposite of expand
# This is used for switching object to their id for Stripe api methods that post data.
# Objects are expanded when retrieving data, but when posting data, objects should be represented to Stripe by their id
sub _contract
{
    my $self  = shift( @_ );
    my $class = shift( @_ ) || CORE::return( $self->error( "No object class was provided to contract objects within." ) );
    my $args  = shift( @_ ) || CORE::return( $self->error( "No data to process for class \"$class\" was provided." ) );
    CORE::return( $self->error( "Data provided to contract for class \"$class\" is not an hash reference nor an object. I received '$args'." ) ) if( ref( $args ) ne 'HASH' && ref( $args ) ne 'Module::Generic::Hash' && !$self->_is_object( $args ) );
    CORE::return( $self->error( "No class \"$class\" found to contract the possible objects contained." ) ) if( !exists( $EXPANDABLES_BY_CLASS->{ $class } ) );
    my $ref = $EXPANDABLES_BY_CLASS->{ $class };
    CORE::return( $self->error( "Definition hash found for class \"$class\" is not an hash! This should not happen." ) ) if( ref( $ref ) ne 'HASH' );
    PROPERTY: foreach my $p ( sort( keys( %$ref ) ) )
    {
        if( CORE::index( $p, '.' ) != -1 )
        {
            my @parts = split( /\./, $p );
            # Can be an object or just a hash
            my $obj = $args;
            PART: for( my $i = 0; $i < scalar( @parts ); $i++ )
            {
                my $prop = $parts[ $i ];
                my $this;
                my $type;
                if( $self->_is_object( $obj ) )
                {
                    $type = 'object';
                    if( !( defined( my $code = $obj->can( $prop ) ) ) )
                    {
                        CORE::return( $self->error( "Property \"$prop\" is part of the path to object to contract, but there is no such method in package \"", ref( $obj ), "\" as provided in property path \"$p\"." ) );
                    }
                    $this = $obj->$prop();
                }
                elsif( ref( $obj ) eq 'HASH' || ref( $obj ) eq 'Module::Generic::Hash' )
                {
                    $type = 'hash';
                    $this = $obj->{ $prop };
                }
                next PROPERTY if( !length( $this ) );
                
                # If this is an object, we convert it to its id string representation for Stripe, or
                # we continue to drill down if the path continues
                if( $self->_is_object( $this ) )
                {
                    # If this is the last element of this property path
                    if( $i == $#parts )
                    {
                        if( $type eq 'object' )
                        {
                            $obj->$prop( $this->id );
                        }
                        elsif( $type eq 'hash' )
                        {
                            $obj->{ $prop } = $this->id;
                        }
                    }
                    # Continue to drill down the property path
                    $obj = $this;
                }
                elsif( ref( $this ) eq 'HASH' || ref( $this ) eq 'Module::Generic::Hash' )
                {
                    if( $i == $#parts )
                    {
                        if( $type eq 'object' )
                        {
                            $obj->$prop( $this->{id} );
                        }
                        elsif( $type eq 'hash' )
                        {
                            $obj->{ $prop } = $this->{id};
                        }
                    }
                    $obj = $this;
                }
            }
        }
        else
        {
            if( $self->_is_object( $args ) )
            {
                my $this = $args->$p();
                next if( !length( $this ) );
                if( $self->_is_object( $this ) )
                {
                    $args->$p( $this->id );
                }
                elsif( ref( $this ) eq 'HASH' || ref( $this ) eq 'Module::Generic::Hash' )
                {
                    $args->$p( $this->{id} );
                }
            }
            elsif( ref( $args ) eq 'HASH' || ref( $args ) eq 'Module::Generic::Hash' )
            {
                my $this = $args->{ $p };
                next if( !length( $this ) );
                if( $self->_is_object( $this ) )
                {
                    $args->{ $p } = $this->id;
                }
                elsif( ref( $this ) eq 'HASH' || ref( $this ) eq 'Module::Generic::Hash' )
                {
                    $args->{ $p } = $this->{id};
                }
            }
        }
    }
    CORE::return( $args );
}

sub _convert_boolean_for_json
{
    my $self = shift( @_ );
    my $hash = shift( @_ ) || CORE::return( $self->pass_error );
    my $seen = {};
    my $crawl;
    $crawl = sub
    {
        my $this = shift( @_ );
        foreach my $k ( keys( %$this ) )
        {
            if( ref( $this->{ $k } ) eq 'HASH' )
            {
                my $addr = Scalar::Util::refaddr( $this->{ $k } );
                next if( ++$seen->{ $addr } > 1 );
                $crawl->( $this->{ $k } );
            }
            elsif( $self->_is_object( $this->{ $k } ) && $this->{ $k }->isa( 'Module::Generic::Boolean' ) )
            {
                $this->{ $k } = $this->{ $k } ? 'true' : 'false';
            }
        }
    };
    $crawl->( $hash );
}

sub _encode_params
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    if( $self->{ '_encode_with_json' } )
    {
        CORE::return( $self->json->utf8->allow_blessed->encode( $args ) );
    }
    my $encode;
    $encode = sub
    {
        my( $pref, $data ) = @_;
        my $ref = ref( $data );
        my $type = lc( ref( $data ) );
        my $comp = [];
        if( $type eq 'hash' || $ref eq 'Module::Generic::Hash' )
        {
            foreach my $k ( sort( keys( %$data ) ) )
            {
                my $ke = URI::Escape::uri_escape( $k );
                my $pkg = Scalar::Util::blessed( $data->{ $k } );
                if( $pkg && $pkg =~ /^Net::API::Stripe/ && 
                    $data->{ $k }->can( 'id' ) && 
                    $data->{ $k }->id )
                {
                    push( @$comp, "${pref}${ke}" . '=' . $data->{ $k }->id );
                    next;
                }
                my $res = $encode->( ( $pref ? sprintf( '%s[%s]', $pref, $ke ) : $ke ), $data->{ $k } );
                push( @$comp, @$res );
            }
        }
        elsif( $type eq 'array' || $ref eq 'Module::Generic::Array' )
        {
            # According to Stripe's response to my mail inquiry of 2019-11-04 on how to structure array of hash in url encoded form data
            for( my $i = 0; $i < scalar( @$data ); $i++ )
            {
                my $res = $encode->( ( $pref ? sprintf( '%s[%d]', $pref, $i ) : sprintf( '[%d]', $i ) ), $data->[$i] );
                push( @$comp, @$res );
            }
        }
        elsif( ref( $data ) eq 'JSON::PP::Boolean' || ref( $data ) eq 'Module::Generic::Boolean' )
        {
            push( @$comp, sprintf( '%s=%s', $pref, $data ? 'true' : 'false' ) );
        }
        elsif( ref( $data ) eq 'SCALAR' && ( $$data == 1 || $$data == 0 ) )
        {
            push( @$comp, sprintf( '%s=%s', $pref, $$data ? 'true' : 'false' ) );
        }
        # Other type of scalar like Module::Generic
        elsif( $ref && Scalar::Util::reftype( $data ) eq 'SCALAR' )
        {
            push( @$comp, sprintf( '%s=%s', $pref, $$data ) );
        }
        elsif( $type eq 'datetime' )
        {
            push( @$comp, sprintf( '%s=%s', $pref, $data->epoch ) );
        }
        elsif( $type )
        {
            die( "Don't know what to do with data type $type\n" );
        }
        else
        {
            push( @$comp, sprintf( '%s=%s', $pref, URI::Escape::uri_escape_utf8( "$data" ) ) );
        }
        CORE::return( $comp );
    };
    my $res = $encode->( '', $args );
    CORE::return( join( '&', @$res ) );
}

sub _encode_params_multipart
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( scalar( @_ ) && ref( $_[-1] ) eq 'HASH' );
    my $set_value = sub
    {
        my( $key, $val, $ref, $param ) = @_;
        $param = {} if( !CORE::length( $param ) );
        $param->{encoding} = $opts->{encoding} if( !CORE::length( $param->{encoding} ) );
        if( !CORE::exists( $ref->{ $key } ) )
        {
            $ref->{ $key } = [];
        }
        my $this = {};
        $this->{filename} = $param->{filename} if( CORE::length( $param->{filename} ) );
        $this->{type} = $param->{type} if( CORE::length( $param->{type} ) );
        $val = Encode::encode_utf8( $val ) if( substr( $this->{type}, 0, 4 ) eq 'text' );
        if( $param->{encoding} )
        {
            if( $param->{encoding} eq 'qp' || $param->{encoding} eq 'quoted-printable' )
            {
                $this->{value} = MIME::QuotedPrint::encode_qp( $val );
                $this->{encoding} = 'Quoted-Printable';
            }
            elsif( $param->{encoding} eq 'base64' )
            {
                $this->{value} = MIME::Base64::encode_base64( $val );
                $this->{encoding} = 'Base64';
            }
            else
            {
                die( "Unknown encoding method \"", $param->{encoding}, "\"\n" );
            }
        }
        else
        {
            $this->{value} = $val;
        }
        CORE::push( @{$ref->{ $key }}, $this );
    };
    
    my $encode;
    $encode = sub
    {
        my( $pref, $data, $hash ) = @_;
        my $type = lc( ref( $data ) );
        if( $type eq 'hash' )
        {
            foreach my $k ( sort( keys( %$data ) ) )
            {
                # my $ke = URI::Escape::uri_escape( $k );
                my $ke = $k;
                $ke =~ s/([\\\"])/\\$1/g;
                my $pkg = Scalar::Util::blessed( $data->{ $k } );
                if( $pkg && $pkg =~ /^Net::API::Stripe/ && 
                    $data->{ $k }->can( 'id' ) && 
                    $data->{ $k }->id )
                {
                    $set_value->( "${pref}${ke}", $data->{ $k }->id, $hash, { type => 'text/plain' } );
                    next;
                }
                # This is a file
                elsif( ref( $data->{ $k } ) eq 'HASH' && 
                       CORE::exists( $data->{ $k }->{_filepath} ) )
                {
                    CORE::return( $self->error( "File path argument is actually empty" ) ) if( !CORE::length( $data->{ $k }->{_filepath} ) );
                    my $this_file = Module::Generic::File::file( $data->{ $k }->{_filepath} );
                    my $fname = $this_file->basename;
                    if( !$this_file->exists )
                    {
                        $self->error( "File \"$this_file\" does not exist." );
                        next;
                    }
                    elsif( !$this_file->can_read )
                    {
                        $self->error( "File \"$this_file\" is not reaable by uid $>." );
                        next;
                    }
                    my $binary = $this_file->load ||
                        return( $self->pass_error( $this_file->error ) );
                    my $mime_type = $this_file->finfo->mime_type;
                    $fname =~ s/([\\\"])/\\$1/g;
                    $set_value->( "${pref}${ke}", $binary, $hash, { encoding => 'base64', filename => $fname, type => $mime_type } );
                    next;
                }
                $encode->( ( $pref ? sprintf( '%s[%s]', $pref, $ke ) : $ke ), $data->{ $k }, $hash );
            }
        }
        elsif( $type eq 'array' )
        {
            # According to Stripe's response to my mail inquiry of 2019-11-04 on how to structure array of hash in url encoded form data
            for( my $i = 0; $i < scalar( @$data ); $i++ )
            {
                $encode->( ( $pref ? sprintf( '%s[%d]', $pref, $i ) : sprintf( '[%d]', $i ) ), $data->[$i], $hash );
            }
        }
        elsif( ref( $data ) eq 'JSON::PP::Boolean' || ref( $data ) eq 'Module::Generic::Boolean' )
        {
            $set_value->( $pref, $data ? 'true' : 'false', $hash, { type => 'text/plain' } );
        }
        elsif( ref( $data ) eq 'SCALAR' && ( $$data == 1 || $$data == 0 ) )
        {
            $set_value->( $pref, $$data ? 'true' : 'false', $hash, { type => 'text/plain' } );
        }
        elsif( $type )
        {
            die( "Don't know what to do with data type $type\n" );
        }
        else
        {
            $set_value->( $pref, $data, $hash, { type => 'text/plain' } );
        }
    };
    my $result = {};
    $encode->( '', $args, $result );
    CORE::return( $result );
}

sub _get_args
{
    my $self = shift( @_ );
    CORE::return( {} ) if( !scalar( @_ ) || ( scalar( @_ ) == 1 && !defined( $_[0] ) ) );
    # Arg is one unique object
    CORE::return( $_[0] ) if( $self->_is_object( $_[0] ) );
    my $args = ref( $_[0] ) eq 'HASH' ? $_[0] : { @_ == 1 ? ( id => $_[0] ) : @_ };
    CORE::return( $args );
}

sub _get_args_from_object
{
    my $self  = shift( @_ );
    my $class = shift( @_ ) || CORE::return( $self->error( "No class was provided to get its information as parameters." ) );
    my $args = {};
    if( $self->_is_object( $_[0] ) && $_[0]->isa( $class ) )
    {
        my $obj = shift( @_ );
        $args = $obj->as_hash({ json => 1 });
        $args->{expand} = 'all';
        $args->{_cleanup} = 1;
        $args->{_object} = $obj;
    }
    else
    {
        $args = $self->_get_args( @_ );
    }
    CORE::return( $args );
}

sub _get_method
{
    my $self = shift( @_ );
    my( $type, $action, $allowed ) = @_;
    CORE::return( $self->error( "No action was provided to get the associated method." ) ) if( !CORE::length( $action ) );
    CORE::return( $self->error( "Allowed method list provided is not an array reference." ) ) if( ref( $allowed ) ne 'ARRAY' );
    CORE::return( $self->error( "Allowed method list provided is empty." ) ) if( !scalar( @$allowed ) );
    if( $action eq 'remove' )
    {
        $action = 'delete';
    }
    elsif( $action eq 'add' )
    {
        $action = 'create';
    }
    if( !scalar( grep( /^$action$/, @$allowed ) ) )
    {
        CORE::return( $self->error( "Method $action is not authorised for $type" ) );
    }
    my $meth = $self->can( "${type}_${action}" );
    CORE::return( $self->error( "Method ${type}_${action} is not implemented in class '", ref( $self ), "'" ) ) if( !$meth );
    CORE::return( $meth );
}

sub _instantiate
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    CORE::return( $self->{ $name } ) if( exists( $self->{ $name } ) && Scalar::Util::blessed( $self->{ $name } ) );
    my $class = shift( @_ );
    my $this;
    try
    {
        # https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
        # require $class unless( defined( *{"${class}::"} ) );
        my $rc = eval{ $self->_load_class( $class ) };
        CORE::return( $self->error( "Unable to load class $class: $@" ) ) if( $@ );
        $this  = $class->new(
            'debug'     => $self->debug,
            'verbose'   => $self->verbose,
        ) || CORE::return( $self->pass_error( $class->error ) );
        $this->{parent} = $self;
    }
    catch( $e ) 
    {
        CORE::return( $self->error({ code => 500, message => $e }) );
    }
    CORE::return( $this );
}

sub _make_error 
{
    my $self  = shift( @_ );
    my $args  = shift( @_ );
    $args->{skip_frames} = 1 if( !exists( $args->{skip_frames} ) && !defined( $args->{skip_frames} ) );
    CORE::return( $self->error( $args ) );
}

sub _make_request
{
    my $self = shift( @_ );
    my $req  = shift( @_ );
    my( $e, $resp, $ret, $is_error );
    $ret = eval 
    {
        $req->header( 'Authorization'  => $self->{auth} );
        $req->header( 'Stripe_Version' => $self->{version} );
        $req->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
        $req->header( 'Content-Type' => 'application/json' ) if( $self->encode_with_json );
        $req->header( 'Accept' => 'application/json' );

        # This commented out block below is used when we use HTTP::Promise while enabling the use of promise, but since we do not need
#         my $prom = $self->http_client->request( $req )->then(sub
#         {
#             my( $resolve, $reject ) = @$_;
#             $resolve->( @_ );
#         })->wait;
#         $resp = $prom->result;
        # We use this more straightforward approach:
        $resp = $self->http_client->request( $req );
        return( $self->pass_error( $self->http_client->error ) ) if( !defined( $resp ) );
        $self->{http_request} = $req;
        $self->{http_response} = $resp;
        if( $self->_is_a( $resp => 'HTTP::Promise::Exception' ) )
        {
            return( $self->pass_error( $resp ) );
        }
        
        # if( $resp->code == 200 ) 
        if( $resp->is_success || $resp->is_redirect )
        {
            my $content = $resp->decoded_content;
            # decoded_content returns a scalar object, which we force into regular string, otherwise JSON complains it cannot parse it.
            my $hash = $self->json->utf8->decode( "${content}" );
            # $ret = data_object( $hash );
            CORE::return( $hash );
        }
        else 
        {
            if( $resp->header( 'Content_Type' ) =~ m{text/html} ) 
            {
                CORE::return( $self->error({
                    code    => $resp->code,
                    type    => $resp->status,
                    message => $resp->status
                }) );
            }
            else 
            {
                my $content = $resp->decoded_content;
                # decoded_content returns a scalar object, which we force into regular string, otherwise JSON complains it cannot parse it.
                my $hash = $self->json->utf8->decode( "${content}" );
                # For example:
                # {
                #     "error" => {
                #         "message" => "Search is not supported on api version 2020-03-02. Update your API version, or set the API Version of this request to 2020-08-27 or greater.",
                #         "request_log_url" => "https://dashboard.stripe.com/test/logs/req_1Gy9CkPgC0eTw1?t=1666611614",
                #         "type" => "invalid_request_error"
                #     }
                # }
                my $ref = {};
                if( exists( $hash->{error} ) &&
                    defined( $hash->{error} ) )
                {
                    if( ref( $hash->{error} ) eq 'HASH' &&
                        exists( $hash->{error}->{message} ) )
                    {
                        $ref->{message} = $hash->{error}->{message};
                        $ref->{type} = $hash->{error}->{type} if( exists( $hash->{error}->{type} ) );
                        $ref->{request_log_url} = $hash->{error}->{request_log_url} if( exists( $hash->{error}->{request_log_url} ) );
                    }
                }
                else
                {
                    $ref = $hash;
                }
                CORE::return( $self->error( $ref ) );
            }
        }
    };
    if( $@ ) 
    {
        CORE::return( $self->error({
            # type => "Could not decode HTTP response: $@", 
            $resp
                ? ( message => ( "Could not decode HTTP response: $@\n" ) . $resp->status_line . ' - ' . $resp->content )
                : ( message => "Could not decode HTTP response: $@" ),
        }) );
    }
    # CORE::return( $ret ) if( $ret );
    CORE::return( $ret );
}

sub _object_class_to_type
{
    my $self = shift( @_ );
    my $class = shift( @_ ) || CORE::return( $self->error( "No class was provided to find its associated type." ) );
    $class = ref( $class ) if( $self->_is_object( $class ) );
    my $ref  = $Net::API::Stripe::TYPE2CLASS;
    foreach my $c ( keys( %$ref ) )
    {
        CORE::return( $c ) if( $ref->{ $c } eq $class );
    }
    CORE::return;
}

sub _object_type_to_class
{
    my $self = shift( @_ );
    my $type = shift( @_ ) || CORE::return( $self->error( "No object type was provided" ) );
    my $ref  = $Net::API::Stripe::TYPE2CLASS;
    CORE::return( $self->error( "No object type '$type' known to get its related class for field $self->{_field}" ) ) if( !exists( $ref->{ $type } ) );
    CORE::return( $ref->{ $type } );
}

sub _process_array_objects
{
    my $self = shift( @_ );
    my $class = shift( @_ );
    my $ref  = shift( @_ ) || CORE::return( $self->error( "No array reference provided" ) );
    CORE::return( $self->error( "Reference provided ($ref) is not an array reference." ) ) if( !ref( $ref ) || ref( $ref ) ne 'ARRAY' );
    for( my $i = 0; $i < scalar( @$ref ); $i++ )
    {
        my $hash = $ref->[$i];
        next if( ref( $hash ) ne 'HASH' );
        my $o = $class->new( %$hash );
        $ref->[$i] = $o;
    }
    CORE::return( $ref );
}

sub _response_to_object
{
    my $self  = shift( @_ );
    my $class = shift( @_ );
    CORE::return( $self->error( "No hash was provided" ) ) if( !scalar( @_ ) );
    my $hash  = $self->_get_args( @_ );
    # my $callbacks = $CALLBACKS->{ $class };
    my $o;
    try
    {
        # https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
        # eval( "require $class;" ) unless( defined( *{"${class}::"} ) );
        my $rc = eval{ $self->_load_class( $class ) };
        CORE::return( $self->error( "An error occured while trying to load the module $class: $@" ) ) if( $@ );
        $o = $class->new({
            '_parent' => $self,
            '_debug' => $self->{debug},
            '_dbh' => $self->{_dbh},
        }, $hash ) || CORE::return( $self->pass_error( $class->error ) );
    }
    catch( $e )
    {
        CORE::return( $self->error( $e ) );
    }
    CORE::return( $self->pass_error( $class->error ) ) if( !defined( $o ) );
    CORE::return( $o );
}

# NOTE:: AUTOLOAD
AUTOLOAD
{
    my $self;
    $self = shift( @_ ) if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Net::API::Stripe' ) );
    my( $class, $meth );
    $class = ref( $self ) || __PACKAGE__;
    $meth = $AUTOLOAD;
    if( CORE::index( $meth, '::' ) != -1 )
    {
        my $idx = rindex( $meth, '::' );
        $class = substr( $meth, 0, $idx );
        $meth  = substr( $meth, $idx + 2 );
    }
    
    # printf( STDERR __PACKAGE__ . "::AUTOLOAD: %d autoload subs found.\n", scalar( keys( %$AUTOLOAD_SUBS ) ) ) if( $DEBUG >= 4 );
    unless( scalar( keys( %$AUTOLOAD_SUBS ) ) )
    {
        &Net::API::Stripe::_autoload_subs();
        # printf( STDERR __PACKAGE__ . "::AUTOLOAD: there are now %d autoload classes found: %s\n", scalar( keys( %$AUTOLOAD_SUBS ) ), join( ', ', sort( keys( %$AUTOLOAD_SUBS ) ) ) ) if( $DEBUG >= 4 );
    }
    
    # print( STDERR "Checking if sub '$meth' from class '$class' ($AUTOLOAD) is within the autoload subroutines\n" ) if( $DEBUG >= 4 );
    my $code;
    if( CORE::exists( $AUTOLOAD_SUBS->{ $meth } ) )
    {
        $code = $AUTOLOAD_SUBS->{ $meth };
    }
    
    if( CORE::defined( $code ) )
    {
        $code = Nice::Try->implement( $code ) if( CORE::index( $code, 'try' ) != -1 );
        # print( STDERR __PACKAGE__, "::AUTOLOAD: updated code for method \"$meth\" ($AUTOLOAD) and \$self '$self' is:\n$code\n" ) if( $DEBUG >= 4 );
        my $saved = $@;
        {
            no strict;
            eval( $code );
        }
        if( $@ )
        {
            $@ =~ s/ at .*\n//;
            die( $@ );
        }
        $@ = $saved;
        # defined( &$AUTOLOAD ) || die( "AUTOLOAD inconsistency error for dynamic sub \"$meth\"." );
        my $ref = $class->can( $meth ) || die( "AUTOLOAD inconsistency error for dynamic sub \"$meth\"." );
        # No need to keep it in the cache
        # delete( $AUTOLOAD_SUBS->{ $meth } );
        # goto( &$AUTOLOAD );
        # return( &$meth( $self, @_ ) ) if( $self );
        return( $ref->( $self, @_ ) ) if( $self );
        no strict 'refs';
        return( &$AUTOLOAD( @_ ) );
    }
    die( "Method \"${meth}\" is not defined in Net::API::Stripe" );
};

DESTROY
{
    # Do nothing; just avoid calling AUTOLOAD
};

1;

__END__
