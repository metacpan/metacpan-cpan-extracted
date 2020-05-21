# -*- perl -*-
##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe.pm
## Version v1.0.4
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2018/07/19
## Modified 2020/05/21
## 
##----------------------------------------------------------------------------
package Net::API::Stripe;
BEGIN
{
	use strict;
	use common::sense;
	use parent qw( Module::Generic );
	use Encode ();
	use IO::File;
	use Data::UUID;
	use Net::OAuth;
	use Crypt::OpenSSL::RSA;
	use Digest::MD5 qw( md5_base64 );
	use Data::Random qw( rand_chars );
	use HTTP::Cookies;
	use HTTP::Request;
	use LWP::UserAgent;
	use MIME::QuotedPrint ();
	use MIME::Base64 ();
	use LWP::MediaTypes ();
	use JSON;
	use Scalar::Util ();
	use Data::Dumper;
	use URI::Query;
	use URI::Escape;
	use File::Basename;
	use File::Spec;
	use Cwd ();
	use DateTime;
	use DateTime::Format::Strptime;
	use Nice::Try;
	use Want;
	use Digest::SHA ();
	use Net::IP;
	use Devel::Confess;
	use constant API_BASE => 'https://api.stripe.com/v1';
	use constant STRIPE_WEBHOOK_SOURCE_IP => [qw( 54.187.174.169 54.187.205.235 54.187.216.72 54.241.31.99 54.241.31.102 54.241.34.107 )];
	our $VERSION = 'v1.0.4';
};

{
	our $VERBOSE = 0;
	our $DEBUG   = 0;
	our $BROWSER = 'Net::API::Stripe/' . $VERSION;
	
	our $ERROR_CODE_TO_STRING =
	{
	400	=> "The request was unacceptable, due to a missing required parameter.",
	401	=> "No valid API key provided.",
	402	=> "The parameters were valid but the request failed.",
	403 => "The API key doesn't have permissions to perform the request.",
	404 => "The requested resource doesn't exist.",
	409	=> "The request conflicts with another request.",
	429	=> "Too many requests hit the API too quickly. We recommend an exponential backoff of your requests.",
	500 => "Something went wrong on Stripe's end.",
	502 => "Something went wrong on Stripe's end.",
	503 => "Something went wrong on Stripe's end.",
	504 => "Something went wrong on Stripe's end.",
	## Payout: https://stripe.com/docs/api/payouts/failures
	account_closed			=> "The bank account has been closed.",
	## Payout
	account_frozen			=> "The bank account has been frozen.",
	amount_too_large		=> "The specified amount is greater than the maximum amount allowed. Use a lower amount and try again.",
	amount_too_small		=> "The specified amount is less than the minimum amount allowed. Use a higher amount and try again.",
	api_connection_error	=> "Failure to connect to Stripe's API.",
	api_error				=> "Striipe API error",
	api_key_expired			=> "The API key provided has expired",
	authentication_error	=> "Failure to properly authenticate yourself in the request.",
	balance_insufficient	=> "The transfer or payout could not be completed because the associated account does not have a sufficient balance available.",
	bank_account_exists		=> "The bank account provided already exists on the specified Customer object. If the bank account should also be attached to a different customer, include the correct customer ID when making the request again.",
	## Payout: https://stripe.com/docs/api/payouts/failures
	bank_account_restricted	=> "The bank account has restrictions on either the type, or the number, of payouts allowed. This normally indicates that the bank account is a savings or other non-checking account.",
	bank_account_unusable	=> "The bank account provided cannot be used for payouts. A different bank account must be used.",
	bank_account_unverified	=> "Your Connect platform is attempting to share an unverified bank account with a connected account.",
	## Payout
	bank_ownership_changed	=> "The destination bank account is no longer valid because its branch has changed ownership.",
	card_declined			=> "The card has been declined.",
	card_error				=> "Card error",
	charge_already_captured	=> "The charge you’re attempting to refund has already been refunded.",
	## Payout
	could_not_process		=> "The bank could not process this payout.",
	## Payout
	debit_not_authorized	=> "Debit transactions are not approved on the bank account. (Stripe requires bank accounts to be set up for both credit and debit payouts.)",
	## Payout
	declined				=> "The bank has declined this transfer. Please contact the bank before retrying.",
	email_invalid			=> "The email address is invalid.",
	expired_card			=> "The card has expired. Check the expiration date or use a different card.",
	idempotency_error		=> "Idempotency error",
	## Payout
	incorrect_account_holder_name => "Your bank notified us that the bank account holder name on file is incorrect.",
	incorrect_cvc			=> "The card’s security code is incorrect. Check the card’s security code or use a different card.",
	incorrect_number		=> "The card number is incorrect. Check the card’s number or use a different card.",
	incorrect_zip			=> "The card’s postal code is incorrect. Check the card’s postal code or use a different card.",
	instant_payouts_unsupported => "The debit card provided as an external account does not support instant payouts. Provide another debit card or use a bank account instead.",
	## Payout
	insufficient_funds		=> "Your Stripe account has insufficient funds to cover the payout.",
	## Payout
	invalid_account_number	=> "The routing number seems correct, but the account number is invalid.",
	invalid_card_type		=> "The card provided as an external account is not a debit card. Provide a debit card or use a bank account instead.",
	invalid_charge_amount	=> "The specified amount is invalid. The charge amount must be a positive integer in the smallest currency unit, and not exceed the minimum or maximum amount.",
	## Payout
	invalid_currency		=> "The bank was unable to process this payout because of its currency. This is probably because the bank account cannot accept payments in that currency.",
	invalid_cvc				=> "The card’s security code is invalid. Check the card’s security code or use a different card.",
	invalid_expiry_month	=> "The card’s expiration month is incorrect. Check the expiration date or use a different card.",
	invalid_expiry_year		=> "The card’s expiration year is incorrect. Check the expiration date or use a different card.",
	invalid_number			=> "The card number is invalid. Check the card details or use a different card.",
	invalid_request_error	=> "Invalid request error. Request has invalid parameters.",
	livemode_mismatch		=> "Test and live mode API keys, requests, and objects are only available within the mode they are in.",
	missing					=> "Both a customer and source ID have been provided, but the source has not been saved to the customer. ",
	## Payout
	no_account				=> "The bank account details on file are probably incorrect. No bank account could be located with those details.",
	parameter_invalid_empty	=> "One or more required values were not provided. Make sure requests include all required parameters.",
	parameter_invalid_integer => "One or more of the parameters requires an integer, but the values provided were a different type. Make sure that only supported values are provided for each attribute.",
	parameter_invalid_string_blank => "One or more values provided only included whitespace. Check the values in your request and update any that contain only whitespace.",
	parameter_invalid_string_empty => "One or more required string values is empty. Make sure that string values contain at least one character.",
	parameter_missing		=> "One or more required values are missing.",
	parameter_unknown		=> "The request contains one or more unexpected parameters. Remove these and try again.",
	payment_method_unactivated => "The charge cannot be created as the payment method used has not been activated.",
	payouts_not_allowed		=> "Payouts have been disabled on the connected account.",
	platform_api_key_expired => "The API key provided by your Connect platform has expired.",
	postal_code_invalid		=> "The postal code provided was incorrect.",
	processing_error		=> "An error occurred while processing the card. Check the card details are correct or use a different card.",
	rate_limit				=> "Too many requests hit the API too quickly. We recommend an exponential backoff of your requests.",
	rate_limit_error		=> "Too many requests hit the API too quickly.",
	testmode_charges_only	=> "This account has not been activated and can only make test charges.",
	tls_version_unsupported	=> "Your integration is using an older version of TLS that is unsupported. You must be using TLS 1.2 or above.",
	token_already_used		=> "The token provided has already been used. You must create a new token before you can retry this request.",
	transfers_not_allowed	=> "The requested transfer cannot be created. Contact us if you are receiving this error.",
	## Payout
	unsupported_card		=> "The bank no longer supports payouts to this card.",
	upstream_order_creation_failed => "The order could not be created. Check the order details and then try again.",
	url_invalid				=> "The URL provided is invalid.",
	validation_error		=> "Stripe client-side library error: improper field validation",
	};
	
	our $TYPE2CLASS =
	{
	account 				=> 'Net::API::Stripe::Connect::Account',
	ach_credit_transfer		=> 'Net::API::Stripe::Payment::Source::ACHCreditTransfer',
	ach_debit				=> 'Net::API::Stripe::Payment::Source::ACHDebit',
	account_link			=> 'Net::API::Stripe::Connect::Account::Link',
	additional_document		=> 'Net::API::Stripe::Connect::Account::Document',
	address					=> 'Net::API::Stripe::Address',
	address_kana			=> 'Net::API::Stripe::Address',
	address_kanji			=> 'Net::API::Stripe::Address',
	application_fee 		=> 'Net::API::Stripe::Connect::ApplicationFee',
	authorization_controls	=> 'Net::API::Stripe::Issuing::Card::AuthorizationsControl',
	balance 				=> 'Net::API::Stripe::Balance',
	balance_transaction 	=> 'Net::API::Stripe::Balance::Transaction',
	bank_account 			=> 'Net::API::Stripe::Connect::ExternalAccount::Bank',
	billing					=> 'Net::API::Stripe::Billing::Details',
	billing_address			=> 'Net::API::Stripe::Address',
	billing_details			=> 'Net::API::Stripe::Billing::Details',
	billing_thresholds		=> 'Net::API::Stripe::Billing::Thresholds',
	bitcoin_transaction		=> 'Net::API::Stripe::Bitcoin::Transaction',
	branding				=> 'Net::API::Stripe::Connect::Account::Branding',
	business_profile		=> 'Net::API::Stripe::Connect::Business::Profile',
	capability 				=> 'Net::API::Stripe::Connect::Account::Capability',
	card 					=> 'Net::API::Stripe::Connect::ExternalAccount::Card',
	card_payments 			=> 'Net::API::Stripe::Connect::Account::Settings::CardPayments',
	cardholder 				=> 'Net::API::Stripe::Issuing::Card::Holder',
	charge 					=> 'Net::API::Stripe::Charge',
	charges					=> 'Net::API::Stripe::List',
	'checkout.session'		=> 'Net::API::Stripe::Checkout::Session',
	code_verification 		=> 'Net::API::Stripe::Payment::Source::CodeVerification',
	company 				=> 'Net::API::Stripe::Connect::Account::Company',
	country_spec 			=> 'Net::API::Stripe::Connect::CountrySpec',
	coupon 					=> 'Net::API::Stripe::Billing::Coupon',
	credit_note				=> 'Net::API::Stripe::Billing::CreditNote',
	credit_noteline_item	=> 'Net::API::Stripe::Billing::CreditNote::LineItem',
	customer 				=> 'Net::API::Stripe::Customer',
	customer_address 		=> 'Net::API::Stripe::Address',
	customer_balance_transaction => 'Net::API::Stripe::Customer::BalanceTransaction',
	customer_shipping 		=> 'Net::API::Stripe::Shipping',
	dashboard 				=> 'Net::API::Stripe::Connect::Account::Settings::Dashboard',
	data 					=> 'Net::API::Stripe::Event::Data',
	discount 				=> 'Net::API::Stripe::Billing::Discount',
	dispute 				=> 'Net::API::Stripe::Dispute',
	dispute_evidence		=> 'Net::API::Stripe::Dispute::Evidence',
	document 				=> 'Net::API::Stripe::Connect::Account::Document',
	error 					=> 'Net::API::Stripe::Error',
	event 					=> 'Net::API::Stripe::Event',
	evidence 				=> 'Net::API::Stripe::Issuing::Dispute::Evidence',
	evidence_details 		=> 'Net::API::Stripe::Dispute::EvidenceDetails',
	external_accounts 		=> 'Net::API::Stripe::List',
	fee_refund 				=> 'Net::API::Stripe::Connect::ApplicationFee::Refund',
	file 					=> 'Net::API::Stripe::File',
	file_link 				=> 'Net::API::Stripe::File::Link',
	fraudulent 				=> 'Net::API::Stripe::Issuing::Dispute::Evidence::Fraudulent',
	generated_from			=> 'Net::API::Stripe::Payment::GeneratedFrom',
	individual 				=> 'Net::API::Stripe::Connect::Person',
	inventory 				=> 'Net::API::Stripe::Order::SKU::Inventory',
	invoice 				=> 'Net::API::Stripe::Billing::Invoice',
	invoice_customer_balance_settings => 'Net::API::Stripe::Billing::Invoice::BalanceSettings',
	invoice_settings 		=> 'Net::API::Stripe::Billing::Invoice::Settings',
	invoiceitem 			=> 'Net::API::Stripe::Billing::Invoice::Item',
	ip_address_location 	=> 'Net::API::Stripe::GeoLocation',
	'issuing.authorization'	=> 'Net::API::Stripe::Issuing::Authorization',
	'issuing.card' 			=> 'Net::API::Stripe::Issuing::Card',
	'issuing.cardholder' 	=> 'Net::API::Stripe::Issuing::Card::Holder',
	'issuing.dispute' 		=> 'Net::API::Stripe::Issuing::Dispute',
	'issuing.transaction' 	=> 'Net::API::Stripe::Issuing::Transaction',
	items 					=> 'Net::API::Stripe::List',
	last_payment_error		=> 'Net::API::Stripe::Error',
	last_setup_error		=> 'Net::API::Stripe::Error',
	line_item 				=> 'Net::API::Stripe::Billing::Invoice::LineItem',
	list					=> 'Net::API::Stripe::List',
	list_items 				=> 'Net::API::Stripe::List',
	lines 					=> 'Net::API::Stripe::List',
	links 					=> 'Net::API::Stripe::List',
	login_link 				=> 'Net::API::Stripe::Connect::Account::LoginLink',
	mandate					=> 'Net::API::Stripe::Mandate',
	merchant_data 			=> 'Net::API::Stripe::Issuing::MerchantData',
	next_action				=> 'Net::API::Stripe::Payment::Intent::NextAction',
	order 					=> 'Net::API::Stripe::Order',
	order_item 				=> 'Net::API::Stripe::Order::Item',
	order_return 			=> 'Net::API::Stripe::Order::Return',
	other 					=> 'Net::API::Stripe::Issuing::Dispute::Evidence::Other',
	outcome 				=> 'Net::API::Stripe::Charge::Outcome',
	owner 					=> 'Net::API::Stripe::Payment::Source::Owner',
	package_dimensions 		=> 'Net::API::Stripe::Order::SKU::PackageDimensions',
	payment_intent 			=> 'Net::API::Stripe::Payment::Intent',
	payment_method 			=> 'Net::API::Stripe::Payment::Method',
	payment_method_details	=> 'Net::API::Stripe::Payment::Method::Details',
	payments 				=> 'Net::API::Stripe::Connect::Account::Settings::Payments',
	payout 					=> 'Net::API::Stripe::Payout',
	payouts 				=> 'Net::API::Stripe::Connect::Account::Settings::Payouts',
	pending_invoice_item_interval => 'Net::API::Stripe::Billing::Plan',
	period 					=> 'Net::API::Stripe::Billing::Invoice::Period',
	person					=> 'Net::API::Stripe::Connect::Person',
	plan 					=> 'Net::API::Stripe::Billing::Plan',
	# plan					=> 'Net::API::Stripe::Payment::Plan',
	product 				=> 'Net::API::Stripe::Product',
	'radar.early_fraud_warning' => 'Net::API::Stripe::Fraud',
	'radar.value_list'		=> 'Net::API::Stripe::Fraud::ValueList',
	'radar.value_list_item' => 'Net::API::Stripe::Fraud::ValueList::Item',
	receiver 				=> 'Net::API::Stripe::Payment::Source::Receiver',
	redirect 				=> 'Net::API::Stripe::Payment::Source::Redirect',
	refund 					=> 'Net::API::Stripe::Refund',
	refunds 				=> 'Net::API::Stripe::Charge::Refunds',
	relationship 			=> 'Net::API::Stripe::Connect::Account::Relationship',
	'reporting.report_run'	=> 'Net::API::Stripe::Reporting::ReportRun',
	request 				=> 'Net::API::Stripe::Event::Request',
	requirements 			=> 'Net::API::Stripe::Connect::Account::Requirements',
	## Used in Net::API::Stripe::Reporting::ReportRun
	result					=> 'Net::API::Stripe::File',
	returns 				=> 'Net::API::Stripe::Order::Returns',
	reversals 				=> 'Net::API::Stripe::Connect::Transfer::Reversals',
	review 					=> 'Net::API::Stripe::Fraud::Review',
	review_session 			=> 'Net::API::Stripe::Fraud::Review::Session',
	scheduled_query_run 	=> 'Net::API::Stripe::Sigma::ScheduledQueryRun',
	settings 				=> 'Net::API::Stripe::Connect::Account::Settings',
	setup_intent 			=> 'Net::API::Stripe::Payment::Intent::Setup',
	shipping				=> 'Net::API::Stripe::Shipping',
	shipping_address		=> 'Net::API::Stripe::Address',
	sku 					=> 'Net::API::Stripe::Order::SKU',
	source 					=> 'Net::API::Stripe::Payment::Source',
	source_order 			=> 'Net::API::Stripe::Order',
	sources 				=> 'Net::API::Stripe::Customer::Sources',
	status_transitions 		=> 'Net::API::Stripe::Billing::Invoice::StatusTransition',
	subscription 			=> 'Net::API::Stripe::Billing::Subscription',
	subscriptions 			=> 'Net::API::Stripe::List',
	subscription_item 		=> 'Net::API::Stripe::Billing::Subscription::Item',
	subscription_schedule	=> 'Net::API::Stripe::Billing::Subscription::Schedule',
	support_address 		=> 'Net::API::Stripe::Address',
	tax_id					=> 'Net::API::Stripe::Customer::TaxId',
	tax_ids 				=> 'Net::API::Stripe::Customer::TaxIds',
	tax_info 				=> 'Net::API::Stripe::Customer::TaxInfo',
	tax_info_verification 	=> 'Net::API::Stripe::Customer::TaxInfoVerification',
	tax_rate				=> 'Net::API::Stripe::Tax::Rate',
	'terminal.connection_token' => 'Net::API::Stripe::Terminal::ConnectionToken',
	'terminal.location' 	=> 'Net::API::Stripe::Terminal::Location',
	'terminal.reader' 		=> 'Net::API::Stripe::Terminal::Reader',
	token 					=> 'Net::API::Stripe::Token',
	topup 					=> 'Net::API::Stripe::Connect::TopUp',
	transactions 			=> 'Net::API::Stripe::List',
	transfer 				=> 'Net::API::Stripe::Connect::Transfer',
	transfer_data			=> 'Net::API::Stripe::Payment::Intent::TransferData',
	transfer_reversal 		=> 'Net::API::Stripe::Connect::Transfer::Reversal',
	threshold_reason 		=> 'Net::API::Stripe::Billing::Thresholds',
	tos_acceptance 			=> 'Net::API::Stripe::Connect::Account::TosAcceptance',
	transform_usage 		=> 'Net::API::Stripe::Billing::Plan::TransformUsage',
	usage_record 			=> 'Net::API::Stripe::Billing::UsageRecord',
	verification 			=> 'Net::API::Stripe::Connect::Account::Verification',
	verification_data 		=> 'Net::API::Stripe::Issuing::Authorization::VerificationData',
	verification_fields 	=> 'Net::API::Stripe::Connect::CountrySpec::VerificationFields',
	verified_address 		=> 'Net::API::Stripe::Address',
	webhook_endpoint		=> 'Net::API::Stripe::WebHook::Object',
	};

	our $EXPANDABLES_BY_CLASS =
	{
	## Nothing
	account					=> {},
	account_link			=> {},
	application_fee			=>
		{
		account => 'account',
		application => 'account',
		balance_transaction => 'balance_transaction',
		charge => 'charge',
		## Actually either a charge or a transfer
		originating_transaction => 'charge',
		},
	## Nothing
	balance					=> {},
	balance_transaction		=>
		{
		source => 'source',
		},
	bank_account			=>
		{
		account => 'account',
		customer => 'customer',
		},
	capability				=>
		{
		account => 'account',
		},
	card					=>
		{
		account => 'account',
		customer => 'customer',
		recipient => 'account',
		},
	charge					=>
		{
		application => 'account',
		balance_transaction => 'balance_transaction',
		customer => 'customer',
		dispute => 'dispute',
		invoice => 'invoice',
		on_behalf_of => 'acount',
		order => 'order',
		review => 'review',
		source_transfer => 'transfer',
		transfer => 'transfer',
		},
	'checkout.session'		=>
		{
		customer => 'customer',
		payment_intent => 'payment_intent',
		setup_intent => 'setup_intent',
		subscription => 'subscription',
		},
	country_spec			=> {},
	coupon					=> {},
	credit_note				=>
		{
		customer => 'customer',
		customer_balance_transaction => 'customer_balance_transaction',
		invoice => 'invoice',
		refund => 'refund',
		},
	customer				=>
		{
		default_source => 'source',
		'invoice_settings.default_payment_method' => 'payment_method',
		},
	customer_balance_transaction =>
		{
		credit_note => 'credit_note',
		customer => 'customer',
		invoice => 'invoice',
		},
	discount				=>
		{
		customer => 'customer',
		},
	dispute					=>
		{
		charge => 'charge',
		# "This property cannot be expanded (latest_invoice.charge.dispute.disputed_transaction)"
		# disputed_transaction => 'balance_transaction',
		},
	event					=> {},
	fee_refund				=>
		{
		fee => 'application_fee',
		balance_transaction => 'balance_transaction',
		},
	file					=> {},
	file_link				=>
		{
		file => 'file',
		},
	invoice					=>
		{
		charge => 'charge',
		customer => 'customer',
		default_payment_method => 'payment_method',
		default_source => 'source',
		payment_intent => 'payment_intent',
		subscription => 'subscription',
		},
	invoiceitem				=>
		{
		customer => 'customer',
		invoice => 'invoice',
		subscription => 'subscription',
		},
	'issuing.authorization'	=>
		{
		cardholder => 'issuing.cardholder',
		},
	'issuing.card'			=> 
		{
		replacement_for => 'issuing.card',
		},
	'issuing.cardholder'	=> {},
	'issuing.dispute'		=> 
		{
		disputed_transaction => 'issuing.transaction',
		},
	'issuing.transaction'	=> 
		{
		authorization => 'issuing.authorization',
		balance_transaction => 'balance_transaction',
		card => 'issuing.card',
		cardholder => 'issuing.cardholder',
		dispute => 'issuing.dispute',
		},
	mandate					=>
		{
		payment_method => 'payment_method',
		},
	order					=>
		{
		charge => 'charge',
		customer => 'customer',
		},
	order_item				=> 
		{
		## Can be either parent or sku actually
		parent => 'discount',
		},
	order_return			=>
		{
		order => 'order',
		refund => 'refund',
		},
	payment_intent			=>
		{
		application => 'account',
		customer => 'customer',
		invoice => 'invoice',
		on_behalf_of => 'account',
		payment_method => 'payment_method',
		review => 'review',
		},
	payment_method			=>
		{
		customer => 'customer',
		},
	payout					=>
		{
		balance_transaction => 'balance_transaction',
		destination => 'account',
		failure_balance_transaction => 'balance_transaction',
		},
	person					=> {},
	plan					=>
		{
		product => 'product',
		},
	product					=> {},
	'radar.early_fraud_warning' => 
		{
		charge => 'charge',
		},
	'radar.value_list'		=> {},
	'radar.value_list_item'	=> {},
	refund					=>
		{
		balance_transaction => 'balance_transaction',
		charge => 'charge',
		failure_balance_transaction => 'balance_transaction',
		payment_intent => 'payment_intent',
		source_transfer_reversal => 'transfer_reversal',
		transfer_reversal => 'transfer_reversal',
		},
	'reporting.report_run'	=> {},
	'reporting.report_type' => {},
	review					=>
		{
		charge => 'charge',
		payment_intent => 'payment_intent',
		},
	schedule				=>
		{
		customer => 'customer',
		subscription => 'subscription',
		},
	scheduled_query_run		=> {},
	setup_intent			=>
		{
		customer => 'customer',
		payment_method => 'payment_method',
		application => 'account',
		mandate => 'mandate',
		on_behalf_of => 'account',
		single_use_mandate => 'mandate',
		},
	sku						=>
		{
		product => 'product',
		},
	source					=> {},
	subscription			=>
		{
		customer => 'customer',
		default_payment_method => 'payment_method',
		default_source => 'source',
		latest_invoice => 'invoice',
		pending_setup_intent => 'setup_intent',
		schedule => 'schedule',
		},
	subscription_item		=> {},
	subscription_schedule	=> 
		{
		customer => 'customer',
		subscription => 'subscription',
		},
	tax_id					=>
		{
		customer => 'customer',
		},
	tax_rate				=> {},
	'terminal.connection_token' => {},
	'terminal.location'		=> {},
	'terminal.reader'		=> {},
	token					=> {},
	topup					=>
		{
		balance_transaction => 'balance_transaction',
		},
	transfer				=>
		{
		destination => 'account',
		balance_transaction => 'balance_transaction',
		## Clueless. It is said to be a payment object (py_GmRo7h8TKguoNX), but cannot find the api documentation for it
		destination_payment => '',
		## charge or payment
		source_transaction	=> 'charge',
		},
	transfer_reversal		=> 
		{
		balance_transaction => 'balance_transaction',
		destination_payment_refund => 'refund',
		source_refund => 'refund',
		transfer => 'transfer',
		},
	usage_record			=> {},
	webhook_endpoint		=> {},
	};
	
	## As per Stripe documentation: https://stripe.com/docs/api/expanding_objects
	our $EXPAND_MAX_DEPTH = 4;
	
	local $get_expandables = sub
	{
		my $class = shift( @_ ) || return;
		my $pref  = shift( @_ );
		my $depth = shift( @_ ) || 0;
		## print( "." x $depth, "Checking class \"$class\" with prefix \"$pref\" and depth $depth\n" );
		return if( $depth > $EXPAND_MAX_DEPTH );
		return if( !CORE::exists( $EXPANDABLES_BY_CLASS->{ $class } ) );
		my $ref = $EXPANDABLES_BY_CLASS->{ $class };
		my $list = [];
		CORE::push( @$list, $pref ) if( CORE::length( $pref ) );
		foreach my $prop ( sort( keys( %$ref ) ) )
		{
			my $target_class = $ref->{ $prop };
			my $new_prefix = CORE::length( $pref ) ? "${pref}.${prop}" : $prop;
			my $this_path = [split(/\./, $new_prefix)];
			my $this_depth = scalar( @$this_path );
			my $res = $get_expandables->( $target_class, $new_prefix, $this_depth );
			CORE::push( @$list, @$res ) if( ref( $res ) && scalar( @$res ) );
		}
		return( $list );
	};
	
	our $EXPANDABLES = {};
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
	}
	## print( Data::Dumper::Dumper( $EXPANDABLES ), "\n" ); exit;
}

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
	## Ask Module::Generic to check if corresponding method exists for each parameter submitted, 
	## and if so, use it to set the value of the key in hash parameters
	$self->{_init_strict_use_sub} = 1;
	$self->{temp_dir} = File::Spec->tmpdir unless( length( $self->{temp_dir} ) );
	## Blank on purpose, which means it was not set. If it has a value like 0 or 1, the user has set it and it takes precedence.
	$self->{livemode} = '';
	$self->{ignore_unknown_parameters} = '' unless( length( $self->{ignore_unknown_parameters} ) );
	$self->{expand} = '' unless( length( $self->{expand} ) );
	## Json configuration file
	$self->{conf_file} = '';
	$self->{conf_data} = {};
	$self->SUPER::init( @_ );
	$self->message( 3, "Config file is $self->{conf_file}" );
	if( $self->{conf_file} )
	{
		my $json = $self->{conf_data};
		$self->message( 3, "config file parameters are: ", sub{ $self->dumper( $json ) } );
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
	return( $self->error( "No Stripe API private key was provided!" ) ) if( !$self->{key} );
	return( $self->error( "No Stripe api version was specified. I was expecting something like ''." ) ) if( !$self->{version} );
	$self->key( $self->{key} );
	$self->livemode( $self->{key} =~ /_live/ ? 1 : 0 );
	return( $self );
}

sub account { return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub account_link { return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::Link', @_ ) ); }

sub address { return( shift->_response_to_object( 'Net::API::Stripe::Address', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

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
			return( $self->error( "Ba URI ($url) provided for base Stripe api: $e" ) );
		}
	}
	return( $self->{api_uri}->clone ) if( Scalar::Util::blessed( $self->{api_uri} ) && $self->{api_uri}->isa( 'URI' ) );
	return( $self->{api_uri} );
}

sub application_fee { return( shift->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee', @_ ) ); }

sub application_fee_refund { return( shift->_response_to_object( 'Net::API::Stripe::Connect::ApplicationFee::Refund', @_ ) ); }

sub auth { return( shift->_set_get_scalar( 'auth', @_ ) ); }

sub authorization { return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Authorization', @_ ) ); }

sub balance { return( shift->_response_to_object( 'Net::API::Stripe::Balance', @_ ) ); }

## Stripe access points in their order on the api documentation
sub balances
{
	my $self = shift( @_ );
	my $allowed = [qw( retrieve )];
	my $action = shift( @_ );
	my $meth = $self->_get_method( 'balance', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

## Retrieves the current account balance, based on the authentication that was used to make the request.
sub balance_retrieve
{
	my $self = shift( @_ );
	## No argument
	#my $hash = $self->_get( 'balance' ) || return;
	my $hash = $self->get( 'balance' );
	$self->message( 3, "Received '$hash' in return, calling _response_to_object()" );
	return( $self->_response_to_object( 'Net::API::Stripe::Balance', $hash ) );
}

sub balance_transaction { return( shift->_response_to_object( 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub balance_transactions
{
	my $self = shift( @_ );
	my $allowed = [qw( retrieve list )];
	my $action = shift( @_ );
	my $meth = $self->_get_method( 'balance_transaction', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

## https://stripe.com/docs/api/balance/balance_history?lang=curl
sub balance_transaction_list
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	my $okParams = 
	{
	expandable 			=> { allowed => $EXPANDABLES->{balance_transaction}, data_prefix_is_ok => 1 },
	'available_on' 		=> qr/^\d+$/,
	'available_on.gt' 	=> qr/^\d+$/,
	'available_on.gte' 	=> qr/^\d+$/,
	'available_on.lt' 	=> qr/^\d+$/,
	'available_on.lte' 	=> qr/^\d+$/,
	'created' 			=> qr/^\d+$/,
	'created.gt' 		=> qr/^\d+$/,
	'created.gte' 		=> qr/^\d+$/,
	'created.lt' 		=> qr/^\d+$/,
	'created.lte' 		=> qr/^\d+$/,
	'currency' 			=> qr/^[a-zA-Z]{3}$/,
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before' 	=> qr/^\w+$/,
	'limit' 			=> qr/^\d+$/,
	## "For automatic Stripe payouts only, only returns transactions that were payed out on the specified payout ID."
	'payout' 			=> qr/^\w+$/,
	'source' 			=> qr/^\w+$/,
	'starting_after' 	=> qr/^\w+$/,
	## "Only returns transactions of the given type"
	'type' 				=> qr/^(?:charge|refund|adjustment|application_fee|application_fee_refund|transfer|payment|payout|payout_failure|stripe_fee|network_cost)$/,
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->get( 'balance_transactions', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub balance_transaction_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve balance transaction information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Balance::Transaction', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{balance_transaction}, data_prefix_is_ok => 1 },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No balance transaction id was provided to retrieve its information." ) );
	my $hash = $self->get( "balance/history/${id}" ) || return;
	return( $self->error( "Cannot find property 'object' in response hash reference: ", sub{ $self->dumper( $hash ) } ) ) if( !CORE::exists( $hash->{object} ) );
	my $class = $self->_object_type_to_class( $hash->{object} ) || return;
	return( $self->_response_to_object( $class, $hash ) );
}

sub bank_account { return( shift->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ ) ); }

sub bank_accounts
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve update delete list )];
	my $meth = $self->_get_method( 'bank_account', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub bank_account_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a bank account" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{bank_account} },
	external_account	=> {},
	account				=> { re => qr/^\w+$/, required => 1 },
	metadata 			=> { type => 'hash' },
	default_for_currency => {},
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
	my $id = $args->{account};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( "accounts/${id}/external_accounts", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}

sub bank_account_delete
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to delete a bank account information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ );
	my $okParams = 
	{
	expandable => { allowed => $EXPANDABLES->{coupon} },
	id 			=> { re => qr/^\w+$/, required => 1 },
	account		=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No bank account id was provided to delete its information." ) );
	my $acct = CORE::delete( $args->{account} );
	my $hash = $self->delete( "accounts/${acct}/external_accounts/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}

sub bank_account_list
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	my $okParams = 
	{
	expandable		=> { allowed => $EXPANDABLES->{coupon} },
	account			=> { re => qr/^\w+$/, required => 1 },
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before' => qr/^\w+$/,
	'limit' 		=> qr/^\d+$/,
	'starting_after' => qr/^\w+$/,
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'coupons', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub bank_account_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve a bank account information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{coupon} },
	id 			=> { re => qr/^\w+$/, required => 1 },
	account		=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No bank account id was provided to retrieve its information." ) );
	my $acct = CORE::delete( $args->{account} );
	my $hash = $self->get( "accounts/${acct}/external_accounts/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}

sub bank_account_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a bank account" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ );
	my $okParams = 
	{
	expandable 	=> { allowed => $EXPANDABLES->{coupon} },
	id 			=> { re => qr/^\w+$/, required => 1 },
	account		=> { re => qr/^\w+$/, required => 1 },
	account_holder_name => {},
	account_holder_type => { re => qr/^(company|individual)$/ },
	default_for_currency => {},
	## Return true only if there is an error
	metadata 	=> { type => 'hash' },
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No bank account id was provided to update coupon's details" ) );
	my $acct = CORE::delete( $args->{account} );
	my $hash = $self->post( "accounts/${acct}/external_accounts/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Bank', $hash ) );
}

sub browser { return( shift->_set_get_scalar( 'browser', @_ ) ); }

# sub billing { return( shift->_instantiate( 'billing', 'Net::API::Stripe::Billing' ) ) }

sub capability { return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::Capability', @_ ) ); }

sub card_holder { return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Card::Holder', @_ ) ); }

sub card { return( shift->_response_to_object( 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub cards
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve update delete list )];
	my $meth = $self->_get_method( 'card', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub card_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create card" ) ) if( !scalar( @_ ) );
	my $args = {};
	my $card_fields = [qw( object number exp_month exp_year cvc currency name metadata default_for_currency address_line1 address_line2 address_city address_state address_zip address_country )];
	my $okParams = 
	{
	expandable 	=> { allowed => $EXPANDABLES->{card} },
	id			=> { re => qr/^\w+$/, required => 1 },
	## Token
	source 		=> { type => 'hash', fields => $card_fields, required => 1 },
	metadata 	=> { type => 'hash' },
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
	
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id   = CORE::delete( $args->{id} ) || return( $self->error( "No customer id was provided to create a card for the customer" ) );
	my $hash = $self->post( "customers/${id}/sources", $args ) || return;
	return( $self->error( "Cannot find property 'object' in response hash reference: ", sub{ $self->dumper( $hash ) } ) ) if( !CORE::exists( $hash->{object} ) );
	my $class = $self->_object_type_to_class( $hash->{object} ) || return;
	# return( $self->_response_to_object( 'Net::API::Stripe::Payment::Card', $hash ) );
	return( $self->_response_to_object( $class, $hash ) );
}

sub card_delete
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to delete card" ) ) if( !scalar( @_ ) );
	my $args = {};
	if( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Customer' ) )
	{
		my $cust = shift( @_ );
		return( $self->error( "No customer id was found in this customer object." ) ) if( !$cust->id );
		return( $self->error( "No source is set for the credit card to delete for this customer." ) ) if( !$cust->source );
		return( $self->error( "No credit card id found for this customer source to delete." ) ) if( !$cust->source->id );
		$args->{id} = $cust->id;
		$args->{card_id} = $cust->source->id;
		$args->{expand} = 'all';
	}
	elsif( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Payment::Card' ) )
	{
		my $card = shift( @_ );
		return( $self->error( "No card id was found in this card object." ) ) if( !$card->id );
		return( $self->error( "No customer object is set for this card object." ) ) if( !$card->customer );
		return( $self->error( "No customer id found in the customer object in this card object." ) ) if( !$card->customer->id );
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
	expandable 	=> { allowed => $EXPANDABLES->{card} },
	id 			=> { re => qr/^\w+$/, required => 1 },
	card_id 	=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No customer id was provided to delete his/her card" ) );
	my $cardId = CORE::delete( $args->{card_id} ) || return( $self->error( "No card id was provided to delete customer's card" ) );
	my $hash = $self->delete( "customers/${id}/sources/${cardId}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Card', $hash ) );
}

sub card_list
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to list customer's cards." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
	my $okParams = 
	{
	expandable		=> { allowed => $EXPANDABLES->{card}, data_prefix_is_ok => 1 },
	ending_before 	=> qr/^\w+$/,
	id				=> { re => /^\w+$/, required => 1 },
	limit 			=> qr/^\d+$/,
	starting_after 	=> qr/^\w+$/,
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No customer id was provided to list his/her cards" ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( "customers/${id}/sources", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Card::List', $hash ) );
}

sub card_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve card information." ) ) if( !scalar( @_ ) );
	## my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Card', @_ );
	my $args = {};
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{card} },
	id 			=> { re => qr/^\w+$/, required => 1 },
	customer	=> { re => qr/^\w+$/, required => 1 },
	};
	if( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Customer' ) )
	{
		my $cust = shift( @_ );
		return( $self->error( "No customer id was found in this customer object." ) ) if( !$cust->id );
		return( $self->error( "No source is set for the credit card to delete for this customer." ) ) if( !$cust->source );
		return( $self->error( "No credit card id found for this customer source to delete." ) ) if( !$cust->source->id );
		$args->{customer} = $cust->id;
		$args->{id} = $cust->source->id;
		$args->{expand} = 'all';
		$okParams->{_cleanup} = 1;
	}
	elsif( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Payment::Card' ) )
	{
		my $card = shift( @_ );
		return( $self->error( "No card id was found in this card object." ) ) if( !$card->id );
		return( $self->error( "No customer object is set for this card object." ) ) if( !$card->customer );
		return( $self->error( "No customer id found in the customer object in this card object." ) ) if( !$card->customer->id );
		$args->{customer} = $card->customer->id;
		$args->{expand} = 'all';
		$okParams->{_cleanup} = 1;
	}
	else
	{
		$args = $self->_get_args( @_ );
	}
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{customer} ) || return( $self->error( "No customer id was provided to retrieve his/her card" ) );
	my $cardId = CORE::delete( $args->{id} ) || return( $self->error( "No card id was provided to retrieve customer's card" ) );
	my $hash = $self->get( "customers/${id}/sources/${cardId}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Card', $hash ) );
}

sub card_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update card." ) ) if( !scalar( @_ ) );
	my $args = {};
	my $okParams = 
	{
	expandable 		=> { allowed => $EXPANDABLES->{card} },
	id 				=> { re => qr/^\w+$/, required => 1 },
	customer		=> { re => qr/^\w+$/, required => 1 },
	address_city	=> qr/^.*?$/,
	address_country => qr/^[a-zA-Z]{2}$/,
	address_line1	=> qr/^.*?$/,
	address_line2	=> qr/^.*?$/,
	address_state	=> qr/^.*?$/,
	address_zip		=> qr/^.*?$/,
	exp_month		=> qr/^\d{1,2}$/,
	exp_year		=> qr/^\d{1,2}$/,
	metadata		=> sub{ return( ref( $_[0] ) eq 'HASH' ? undef() : sprintf( "A hash ref was expected, but instead received '%s'", $_[0] ) ) },
	name			=> qr/^.*?$/,
	};
	if( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Customer' ) )
	{
		my $cust = shift( @_ );
		return( $self->error( "No customer id was found in this customer object." ) ) if( !$cust->id );
		return( $self->error( "No source is set for the credit card to delete for this customer." ) ) if( !$cust->source );
		return( $self->error( "No credit card id found for this customer source to delete." ) ) if( !$cust->source->id );
		$args = $cust->source->as_hash({ json => 1 });
		$args->{customer} = $cust->id;
		$args->{expand} = 'all';
		$okParams->{_cleanup} = 1;
	}
	elsif( $self->_is_object( $_[0] ) && $_[0]->isa( 'Net::API::Stripe::Payment::Card' ) )
	{
		my $card = shift( @_ );
		return( $self->error( "No card id was found in this card object." ) ) if( !$card->id );
		return( $self->error( "No customer object is set for this card object." ) ) if( !$card->customer );
		return( $self->error( "No customer id found in the customer object in this card object." ) ) if( !$card->customer->id );
		$args = $card->as_hash({ json => 1 });
		$args->{customer} = $card->customer->id;
		$args->{expand} = 'all';
		$okParams->{_cleanup} = 1;
	}
	else
	{
		$args = $self->_get_args( @_ );
	}
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{customer} ) || return( $self->error( "No customer id was provided to update his/her card." ) );
	my $cardId = CORE::delete( $args->{id} ) || return( $self->error( "No card id was provided to update customer's card" ) );
	my $hash = $self->post( "customers/${id}/sources/${cardId}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Card', $hash ) );
}

sub charge { return( shift->_response_to_object( 'Net::API::Stripe::Charge', @_ ) ); }

sub charges
{
	my $self = shift( @_ );
	my $allowed = [qw( create retrieve update capture list )];
	my $action = shift( @_ );
	my $args = $self->_get_args( @_ );
	my $meth = $self->_get_method( 'charge', $action, $allowed ) || return;
	return( $self->$meth( $args ) );
}

sub charge_capture
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a charge." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Charge', @_ );
	my $okParams = 
	{
	id 							=> { re => qr/^\w+$/, required => 1 },
	amount 						=> qr/^\d+$/,
	application_fee_amount 		=> qr/^\d+$/,
	destination 				=> [qw( amount )],
	expandable 					=> { allowed => $EXPANDABLES->{charge} },
	receipt_email 				=> qr/.*?/,
	statement_descriptor 		=> qr/^.*?$/,
	statement_descriptor_suffix => qr/^.*?$/,
	transfer_data 				=> [qw( amount )],
	transfer_group 				=> qr/^.*?$/,
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No charge id was provided to update its charge details." ) );
	return( $self->error( "Destination specified, but not account property provided" ) ) if( exists( $args->{destination} ) && !scalar( grep( /^account$/, @{$args->{destination}} ) ) );
	my $hash = $self->post( "charges/${id}/capture", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Charge', $hash ) );
}

## https://stripe.com/docs/api/charges/create
sub charge_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create charge." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Charge', @_ );
	return( $self->error( "No amount was provided" ) ) if( !exists( $args->{amount} ) || !length( $args->{amount} ) );
	$args->{currency} ||= $self->currency;
	my $okParams = 
	{
	expandable				=> { allowed => $EXPANDABLES->{charge} },
	amount					=> { re => qr/^\d+$/, required => 1 },
	currency 				=> qr/^[a-zA-Z]{3}$/,
	application_fee_amount 	=> qr/^\d+$/,
	## Boolean
	capture 				=> { type => 'boolean' },
	customer 				=> qr/^\w+$/,
	description 			=> qr/^.*?$/,
	destination 			=> [qw( account amount )],
	metadata 				=> { type => 'hash' },
	on_behalf_of 			=> qr/^\w+$/,
	## No way, I am going to indulge in any regex on an e-mail address.
	receipt_email 			=> qr/.*?/,
	shipping 				=> { fields => [qw( address name carrier phone tracking_number )] },
	source 					=> qr/^\w+$/,
	statement_descriptor 	=> qr/^.*?$/,
	statement_descriptor_suffix => qr/^.*?$/,
	transfer_data 			=> { fields => [qw( destination amount )] },
	transfer_group 			=> qr/^.*?$/,
	idempotency 			=> qr/^.*?$/,
	};
	
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	
	$args->{currency} = lc( $args->{currency} );
	return( $self->error( "Destination specified, but no account property provided" ) ) if( exists( $args->{destination} ) && !scalar( grep( /^account$/, @{$args->{destination}} ) ) );
	my $hash = $self->post( 'charges', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Charge', $hash ) );
}

sub charge_list
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	my $okParams = 
	{
	expandable		=> { allowed => $EXPANDABLES->{charge}, data_prefix_is_ok => 1 },
	'created'		=> qr/^\d+$/,
	'created.gt'	=> qr/^\d+$/,
	'created.gte'	=> qr/^\d+$/,
	'created.lt'	=> qr/^\d+$/,
	'created.lte'	=> qr/^\d+$/,
	'customer'		=> qr/^\w+$/,
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before' => qr/^\w+$/,
	'limit' 		=> qr/^\d+$/,
	'payment_intent' => qr/^\w+$/,
	'source' 		=> [qw( object )],
	'starting_after' => qr/^\w+$/,
	'transfer_group' => qr/^.*?$/,
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{source} )
	{
		return( $self->error( "Invalid source value. It should one of all, alipay_account, bank_account, bitcoin_receiver or card" ) ) if( $args->{source}->{object} !~ /^(?:all|alipay_account|bank_account|bitcoin_receiver|card)$/ );
	}
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'charges', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Charge::List', $hash ) );
}

sub charge_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve a charge" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Charge', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{charge} },
	id			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No charge id was provided to retrieve its charge details" ) );
	my $hash = $self->get( "charges/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Charge', $hash ) );
}

sub charge_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a charge" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Charge', @_ );
	my $okParams = 
	{
	id				=> { re => qr/^\w+$/, required => 1 },
	expandable		=> { allowed => $EXPANDABLES->{charge} },
	customer		=> qr/^\w+$/,
	description		=> qr/^.*?$/,
	fraud_details	=> { fields => [qw( user_report )] },
	metadata		=> { type => 'hash' },
	receipt_email	=> qr/.*?/,
	shipping		=> { fields => [qw( address name carrier phone tracking_number )] },
	transfer_group	=> qr/^.*?$/,
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	if( $args->{fraud_details} )
	{
		my $this = $args->{fraud_details};
		if( $this->{user_report} !~ /^(?:fraudulent|safe)$/ )
		{
			return( $self->error( "Invalid value for fraud_details. It should be either fraudulent or safe" ) );
		}
	}
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No charge id was provided to update its charge details" ) );
	my $hash = $self->post( "charges/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Charge', $hash ) );
}

sub code2error
{
	my $self = shift( @_ );
	my $code = shift( @_ ) || return( $self->error( "No code was provided to get the related error" ) );
	return( $self->error( "No code found for $code" ) ) if( !exists( $ERROR_CODE_TO_STRING->{ $code } ) );
	return( $ERROR_CODE_TO_STRING->{ $code } );
}

# sub connect { return( shift->_instantiate( 'connect', 'Net::API::Stripe::Connect' ) ) }

sub conf_file
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $file = shift( @_ );
		# $self->message( 3, "Config file provided: $file" );
		if( !-e( $file ) )
		{
			return( $self->error( "Configuration file $file does not exist." ) );
		}
		elsif( -z( $file ) )
		{
			return( $self->error( "Configuration file $file is empty." ) );
		}
		my $fh = IO::File->new( "<$file" ) || return( $self->error( "Unable to open configuration file $file: $!" ) );
		$fh->binmode( ':utf8' );
		my $data = join( '', $fh->getlines );
		$fh->close;
		try
		{
			my $json = JSON->new->relaxed->decode( $data );
			$self->{conf_data} = $json;
			$self->{conf_file} = $file;
			# $self->message( 3, "Successfully decoded json data: ", sub{ $self->dumper( $json ) } );
		}
		catch( $e )
		{
			return( $self->error( "An error occured while json decoding configuration file $file: $e" ) );
		}
	}
	return( $self->{conf_data} );
}

sub connection_token { return( shift->_response_to_object( 'Net::API::Stripe::Terminal::ConnectionToken', @_ ) ); }

sub country_spec { return( shift->_response_to_object( 'Net::API::Stripe::Connect::CountrySpec', @_ ) ); }

sub coupon { return( shift->_response_to_object( 'Net::API::Stripe::Billing::Coupon', @_ ) ); }

sub coupons
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve update delete list )];
	my $meth = $self->_get_method( 'coupon', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub coupon_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a coupon" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Coupon', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{coupon} },
	duration 			=> { re => qr/^(forever|once|repeating)$/ },
	amount_off 			=> { re => qr/^\d+$/ },
	currency 			=> { re => qr/^[a-zA-Z]{3}$/ },
	duration_in_months	=> { re => qr/^\d+$/ },
	## The id is the coupon code and can and should be provided by the user
	id					=> {},
	max_redemptions		=> { re => qr/^\d+$/ },
	metadata 			=> { type => 'hash' },
	name				=> {},
	percent_off			=> sub{ return( $_[0] =~ /^\d+(\.\d+)?$/ && $_[0] > 0 && $_[0] <= 100 ? undef() : "Value provided is not a legitimate percentage off. It should be a float bigger than 0 and smaller of equal to 100." ) },
	redeem_by			=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'coupons', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Coupon', $hash ) );
}

sub coupon_delete
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to delete coupon information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Coupon', @_ );
	my $okParams = 
	{
	expandable => { allowed => $EXPANDABLES->{coupon} },
	id => { re => qr/^\S+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No coupon id was provided to delete its information." ) );
	my $hash = $self->delete( "coupons/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Coupon', $hash ) );
}

sub coupon_list
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	my $okParams = 
	{
	expandable => { allowed => $EXPANDABLES->{coupon} },
	'created' 		=> qr/^\d+$/,
	'created.gt' 	=> qr/^\d+$/,
	'created.gte' 	=> qr/^\d+$/,
	'created.lt' 	=> qr/^\d+$/,
	'created.lte' 	=> qr/^\d+$/,
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before' => qr/^\w+$/,
	'limit' 		=> qr/^\d+$/,
	'starting_after' => qr/^\w+$/,
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'coupons', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub coupon_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve coupon information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Coupon', @_ );
	my $okParams = 
	{
	expandable => { allowed => $EXPANDABLES->{coupon} },
	id => { re => qr/^\S+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No coupon id was provided to retrieve its information." ) );
	my $hash = $self->get( "coupons/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Coupon', $hash ) );
}

sub coupon_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a coupon" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Coupon', @_ );
	my $okParams = 
	{
	expandable 	=> { allowed => $EXPANDABLES->{coupon} },
	id 			=> { re => qr/^\S+$/, required => 1 },
	## Return true only if there is an error
	metadata 	=> { type => 'hash' },
	name 		=> {},
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No coupon id was provided to update coupon's details" ) );
	my $hash = $self->post( "coupons/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Coupon', $hash ) );
}

sub credit_note { return( shift->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', @_ ) ); }

sub credit_notes
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	## delete is an alias of void to make it more mnemotechnical to remember
	$action = 'void' if( $action eq 'delete' );
	my $allowed = [qw( preview create lines lines_preview retrieve update void list )];
	my $meth = $self->_get_method( 'coupons', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub credit_note_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a credit note" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
	## If we are provided with an invoice object, we change our value for only its id
	if( $args->{_object} && 
		$self->_is_object( $args->{_object}->{invoice} ) && 
		$args->{_object}->invoice->isa( 'Net::API::Stripe::Billing::Invoice' ) )
	{
		my $cred = CORE::delete( $args->{_object} );
		$args->{invoice} = $cred->invoice->id || return( $self->error( "The Invoice object provided for this credit note has no id." ) );
	}
	
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{credit_note} },
	invoice				=> { re => qr/^\w+$/, required => 1 },
	amount				=> { re => qr/^\d+$/ },
	credit_amount		=> { re => qr/^\d+$/ },
	lines				=> { type => 'array', fields => [qw( amount description invoice_line_item quantity tax_rates type unit_amount unit_amount_decimal )] },
	memo				=> {},
	metadata 			=> { type => 'hash' },
	out_of_band_amount	=> { re => qr/^\d+$/ },
	reason				=> { re => qr/^(duplicate|fraudulent|order_change|product_unsatisfactory)$/ },
	refund				=> { re => qr/^\w+$/ },
	refund_amount		=> { re => qr/^\d+$/ },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'credit_notes', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', $hash ) );
}

sub credit_note_line_item { return( shift->_response_to_object( 'Net::API::Stripe::Billing::CreditNote::LineItem', @_ ) ); }

sub credit_note_lines
{
	my $self = shift( @_ );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
	return( $self->error( "No credit note id was provided to retrieve its information." ) ) if( !CORE::length( $args->{id} ) );
	my $okParams = 
	{
	id				=> { re => qr/^\w+$/, required => 1 },
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	ending_before	=> { re => qr/^\w+$/ },
	limit			=> { re => qr/^\d+$/ },
	starting_after	=> { re => qr/^\w+$/ },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} );
	my $hash = $self->get( "credit_notes/${id}/lines", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub credit_note_lines_preview
{
	my $self = shift( @_ );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
	# return( $self->error( "No credit note id was provided to retrieve its information." ) ) if( !CORE::length( $args->{id} ) );
	return( $self->error( "No invoice id or object was provided." ) ) if( !CORE::length( $args->{invoice} ) );
	if( $args->{_object} && 
		$self->_is_object( $args->{_object}->{invoice} ) && 
		$args->{_object}->invoice->isa( 'Net::API::Stripe::Billing::Invoice' ) )
	{
		my $cred = CORE::delete( $args->{_object} );
		$args->{invoice} = $cred->invoice->id || return( $self->error( "The Invoice object provided for this credit note has no id." ) );
	}
	
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{credit_note_lines} },
	# id 					=> { re => qr/^\w+$/, required => 1 },
	invoice				=> { re => qr/^\w+$/, required => 1 },
	amount				=> { re => qr/^\d+$/ },
	credit_amount		=> { re => qr/^\d+$/ },
	ending_before		=> { re => qr/^\w+$/ },
	limit				=> { re => qr/^\d+$/ },
	lines				=> { type => 'array', fields => [qw( amount description invoice_line_item quantity tax_rates type unit_amount unit_amount_decimal )] },
	memo				=> {},
	metadata 			=> { type => 'hash' },
	out_of_band_amount	=> { re => qr/^\d+$/ },
	reason				=> { re => qr/^(duplicate|fraudulent|order_change|product_unsatisfactory)$/ },
	refund				=> { re => qr/^\w+$/ },
	refund_amount		=> { re => qr/^\d+$/ },
	starting_after 		=> { re => qr/^\w+$/ },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} );
	my $hash = $self->get( "credit_notes/preview/${id}/lines", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub credit_note_list
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	my $okParams = 
	{
	expandable		=> { allowed => $EXPANDABLES->{credit_note}, data_prefix_is_ok => 1 },
	'created' 		=> qr/^\d+$/,
	'created.gt' 	=> qr/^\d+$/,
	'created.gte' 	=> qr/^\d+$/,
	'created.lt' 	=> qr/^\d+$/,
	'created.lte' 	=> qr/^\d+$/,
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before' => qr/^\w+$/,
	'limit' 		=> qr/^\d+$/,
	'starting_after' => qr/^\w+$/,
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'coupons', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub credit_note_preview
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to preview a credit note" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
	
	my $obj = $args->{_object};
	## If we are provided with an invoice object, we change our value for only its id
	if( $obj && $obj->invoice )
	{
		$args->{invoice} = $obj->invoice->id || return( $self->error( "The Invoice object provided for this credit note has no id." ) );
	}
	
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{credit_note} },
	invoice				=> { required => 1 },
	amount				=> { re => qr/^\d+$/ },
	credit_amount		=> { re => qr/^\d+$/ },
	lines				=> { type => 'array', fields => [qw( amount description invoice_line_item quantity tax_rates type unit_amount unit_amount_decimal )] },
	memo				=> {},
	metadata 			=> { type => 'hash' },
	out_of_band_amount	=> { re => qr/^\d+$/ },
	reason				=> { re => qr/^(duplicate|fraudulent|order_change|product_unsatisfactory)$/ },
	refund				=> { re => qr/^\w+$/ },
	refund_amount		=> { re => qr/^\d+$/ },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'credit_notes/preview', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', $hash ) );
}

sub credit_note_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve credit note information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{credit_note} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No credit note id was provided to retrieve its information." ) );
	my $hash = $self->get( "credit_notes/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', $hash ) );
}

sub credit_note_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a credit note" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{credit_note} },
	id 			=> { re => qr/^\w+$/, required => 1 },
	memo 		=> {},
	## Return true only if there is an error
	metadata 	=> { type => 'hash' },
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No credit note id was provided to update credit note's details" ) );
	my $hash = $self->post( "credit_notes/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', $hash ) );
}

sub credit_note_void
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to void credit note information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::CreditNote', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{credit_note} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No credit note id was provided to void it." ) );
	my $hash = $self->post( "credit_notes/${id}/void", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::CreditNote', $hash ) );
}

sub currency
{
	my $self = shift( @_ );
	if( @_ )
	{
		$self->_set_get( 'currency', lc( shift( @_ ) ) );
	}
	return( $self->{ 'currency' } );
}

sub customer { return( shift->_response_to_object( 'Net::API::Stripe::Customer', @_ ) ); }

sub customer_balance_transaction { return( shift->_response_to_object( 'Net::API::Stripe::Customer::BalanceTransaction', @_ ) ); }

sub customer_tax_id { return( shift->_response_to_object( 'Net::API::Stripe::Customer::TaxId', @_ ) ); }

sub customers
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve update delete delete_discount list )];
	my $meth = $self->_get_method( 'customer', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

## https://stripe.com/docs/api/customers/create?lang=curl
sub customer_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create customer" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{customer} },
	account_balance 	=> { re => qr/^\-?\d+$/ },
	address 			=> { fields => [qw( line1 city country line2 postal_code state )], package => 'Net::API::Stripe::Address' },
	balance 			=> { re => qr/^\-?\d+$/ },
	## Anything goes
	coupon 				=> {},
	default_source 		=> { re => qr/^\w+$/ },
	description 		=> {},
	email 				=> {},
	## A possible custom unique identifier
	id					=> {},
	## "The prefix for the customer used to generate unique invoice numbers. Must be 3–12 uppercase letters or numbers."
	invoice_prefix 		=> { re => qr/^[A-Z0-9]{3,12}$/ },
	invoice_settings 	=> { fields => [qw( custom_fields default_payment_method footer )], package => 'Net::API::Stripe::Billing::Invoice::Settings' },
	metadata 			=> { type => 'hash' },
	name 				=> {},
	payment_method 		=> {},
	phone 				=> {},
	preferred_locales => { type => 'array' },
	shipping 			=> { fields => [qw( address name carrier phone tracking_number )], package => 'Net::API::Stripe::Shipping' },
	source 				=> { re => qr/^\w+$/ },
	tax_exempt 			=> { re => qr/^(none|exempt|reverse)$/ },
	## array of hash
	tax_id_data 		=> { type => 'array', package => 'Net::API::Stripe::Customer::TaxId' },
	## "The customer’s tax ID number. This will be unset if you POST an empty value."
	## "The type of ID number. The only possible value is vat"
	tax_info 			=> { fields => [qw( tax_id type )], package => 'Net::API::Stripe::Customer::TaxInfo' },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	return( $self->error( "Invalid tax type value provided. It can only be set to vat" ) ) if( $args->{tax_info} && $args->{tax_info}->{type} ne 'vat' );
	my $hash = $self->post( 'customers', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Customer', $hash ) );
}

## https://stripe.com/docs/api/customers/delete?lang=curl
## "Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer."
sub customer_delete
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to delete customer information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
	my $okParams = 
	{
	expandable		=> { allowed => $EXPANDABLES->{customer} },
	id				=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No customer id was provided to delete its information." ) );
	my $hash = $self->delete( "customers/${id}" ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Customer', $hash ) );
}

sub customer_delete_discount
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to delete customer discount." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{discount}},
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No customer id was provided to delete its coupon." ) );
	my $hash = $self->delete( "customers/${id}/discount", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Discount', $hash ) );
}

sub customer_list
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	my $okParams = 
	{
	expandable		=> { allowed => $EXPANDABLES->{customer}, data_prefix_is_ok => 1 },
	'created' 		=> qr/^\d+$/,
	'created.gt' 	=> qr/^\d+$/,
	'created.gte' 	=> qr/^\d+$/,
	'created.lt' 	=> qr/^\d+$/,
	'created.lte' 	=> qr/^\d+$/,
	'email' 		=> qr/.*?/,
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before' => qr/^\w+$/,
	'limit' 		=> qr/^\d+$/,
	'starting_after' => qr/^\w+$/,
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{source} )
	{
		return( $self->error( "Invalid source value. It should one of all, alipay_account, bank_account, bitcoin_receiver or card" ) ) if( $args->{source}->{object} !~ /^(?:all|alipay_account|bank_account|bitcoin_receiver|card)$/ );
	}
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'customers', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Customer::List', $hash ) );
}

sub customer_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve customer information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{customer} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No customer id was provided to retrieve its information." ) );
	my $hash = $self->get( "customers/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Customer', $hash ) );
}

## https://stripe.com/docs/api/customers/update?lang=curl
sub customer_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a customer" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{customer} },
	id 					=> { re => qr/^\w+$/, required => 1 },
	account_balance 	=> { re => qr/^\d+$/ },
	address				=> { fields => [qw( line1 line2 city postal_code state country )] },
	balance				=> {},
	## Anything goes
	coupon 				=> {},
	default_source 		=> { re => qr/^\w+$/ },
	description 		=> {},
	email 				=> {},
	## "The prefix for the customer used to generate unique invoice numbers. Must be 3–12 uppercase letters or numbers."
	invoice_prefix 		=> { re => qr/^[A-Z0-9]{3,12}$/ },
	invoice_settings	=> { fields => [qw( custom_fields default_payment_method footer )] },
	## Return true only if there is an error
	metadata 			=> { type => 'hash' },
	name				=> {},
	next_invoice_sequence => {},
	phone				=> {},
	preferred_locales	=> { type => 'array' },
	shipping 			=> { fields => [qw( address name carrier phone tracking_number )] },
	source 				=> { re => qr/^\w+$/ },
	tax_exempt			=> { re => qr/^(none|exempt|reverse)$/ },
	## "The customer’s tax ID number. This will be unset if you POST an empty value."
	## "The type of ID number. The only possible value is vat"
	tax_info 			=> { fields => [qw( tax_id type )] },
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	if( $args->{fraud_details} )
	{
		my $this = $args->{fraud_details};
		if( $this->{user_report} !~ /^(?:fraudulent|safe)$/ )
		{
			return( $self->error( "Invalid value for fraud_details. It should be either fraudulent or safe" ) );
		}
	}
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No customer id was provided to update customer's details" ) );
	my $hash = $self->post( "customers/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Customer', $hash ) );
}

sub delete 
{
	my $self = shift( @_ );
	my $path = shift( @_ ) || return( $self->error( "No api endpoint (path) was provided." ) );
	my $args = shift( @_ );
	return( $self->error( "http query parameters provided were not a hash reference." ) ) if( $args && ref( $args ) ne 'HASH' );
	my $api  = $self->api_uri->clone;
	if( $self->_is_object( $path ) && $path->can( 'path' ) )
	{
		$self->message( 3, "$path is a URI object" );
		$api->path( undef() );
		$path = $path->path;
	}
	else
	{
		substr( $path, 0, 0 ) = '/' unless( substr( $path, 0, 1 ) eq '/' );
	}
    $path .= '?' . $self->_encode_params( $args ) if( $args && %$args );
    my $req = HTTP::Request->new( 'DELETE', $api . $path );
	return( $self->_make_request( $req ) );
}

sub discount { return( shift->_response_to_object( 'Net::API::Stripe::Billing::Discount', @_ ) ); }

sub discounts
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( delete_customer delete_subscription )];
	return( $self->error( "Unknown action \"$action\" for discounts." ) ) if( !scalar( grep( /^$action$/, @$allowed ) ) );
	if( $action eq 'delete_customer' )
	{
		return( $self->customers( delete_discount => @_ ) );
	}
	elsif( $action eq 'delete_subscription' )
	{
		return( $self->subscriptions( delete_discount => @_ ) );
	}
	## Should not reach here
	else
	{
		return( $self->error( "Unknown and untrapped action \"$action\" for discount." ) );
	}
}

sub dispute { return( shift->_response_to_object( 'Net::API::Stripe::Dispute', @_ ) ); }

sub disputes
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( close retrieve update list )];
	my $meth = $self->_get_method( 'dispute', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub dispute_close
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to close dispute." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Dispute', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{dispute} },
	id			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No dispute id was provided to close." ) );
	my $hash = $self->delete( "disputes/${id}/close", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Dispute', $hash ) );
}

sub dispute_evidence { return( shift->_response_to_object( 'Net::API::Stripe::Dispute', @_ ) ); }

sub dispute_list
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{dispute}, data_prefix_is_ok => 1 },
	'created'			=> { re => qr/^\d+$/ },
	'created.gt' 		=> { re => qr/^\d+$/ },
	'created.gte' 		=> { re => qr/^\d+$/ },
	'created.lt' 		=> { re => qr/^\d+$/ },
	'created.lte' 		=> { re => qr/^\d+$/ },
	'charge' 			=> { re => qr/.*?/ },
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before' 	=> { re => qr/^\w+$/ },
	'limit' 			=> { re => qr/^\d+$/ },
	'payment_intent'	=> { re => qr/^\w+$/ },
	'starting_after' 	=> { re => qr/^\w+$/ },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'disputes', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub dispute_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve dispute information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Dispute', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{dispute} },
	id			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No dispute id was provided to retrieve its information." ) );
	my $hash = $self->get( "disputes/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Dispute', $hash ) );
}

sub dispute_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a dispute" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Dispute', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{dispute} },
	id 			=> { re => qr/^\w+$/, required => 1 },
	evidence	=> { fields => [qw( access_activity_log billing_address cancellation_policy cancellation_policy_disclosure cancellation_rebuttal customer_communication customer_email_address customer_name customer_purchase_ip customer_signature duplicate_charge_documentation duplicate_charge_explanation duplicate_charge_id product_description receipt refund_policy refund_policy_disclosure refund_refusal_explanation service_date service_documentation shipping_address shipping_carrier shipping_date shipping_documentation shipping_tracking_number uncategorized_file uncategorized_text )] },
	metadata 	=> { type => 'hash' },
	submit		=> {},
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No dispute id was provided to update dispute's details" ) );
	my $hash = $self->post( "disputes/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Dispute', $hash ) );
}

sub encode_with_json { return( shift->_set_get( 'encode_with_json', @_ ) ) };

sub event { return( shift->_response_to_object( 'Net::API::Stripe::Event', @_ ) ); }

## Can be 'all' or an integer representing a depth
sub expand { return( shift->_set_get_scalar( 'expand', @_ ) ); }

sub fields
{
	my $self = shift( @_ );
	my $type = shift( @_ ) || return( $self->error( "No object type was provided to get its list of methods." ) );
	my $class;
	if( $class = $self->_is_object( $type ) )
	{
		$self->message( 3, "Was provided an object with class name \"$class\"." );
	}
	else
	{
		$self->message( 3, "Getting object class for type '$type'." );
		$class = $self->_object_type_to_class( $type );
	}
	$self->message( 3, "Class found is '$class'." );
	no strict 'refs';
	if( !$self->_is_class_loaded( $class ) )
	{
		$self->message( 3, "Loading class '$class'." );
		$self->_load_class( $class );
	}
	my @methods = grep{ defined &{"${class}::$_"} } keys( %{"${class}::"} );
	return( \@methods );
}

sub file { return( shift->_response_to_object( 'Net::API::Stripe::File', @_ ) ); }

sub file_link { return( shift->_response_to_object( 'Net::API::Stripe::File::Link', @_ ) ); }

# sub fraud { return( shift->_instantiate( 'fraud', 'Net::API::Stripe::Fraud' ) ) }

sub files
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve list )];
	my $meth = $self->_get_method( 'files', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub file_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a file" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::File', @_ );
	my $okParams = 
	{
	expand				=> { allowed => $EXPANDABLES->{file} },
	file				=> {},
	purpose				=> { re => qr/^(business_icon|business_logo|customer_signature|dispute_evidence|identity_document|pci_document|tax_document_user_upload)$/ },
	file_link_data		=> { type => 'hash', field => [qw( create expires_at metadata )] },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( !CORE::length( $args->{file} ) )
	{
		return( $self->error( "No file was provided to upload." ) );
	}
	my $file = Cwd::abs_path( $args->{file} );
	if( !-e( $file ) )
	{
		return( $self->error( "File \"$file\" does not exist." ) );
	}
	elsif( -z( $file ) )
	{
		return( $self->error( "File \"$file\" is empty." ) );
	}
	elsif( !-r( $file ) )
	{
		return( $self->error( "File \"$file\" does not have read permission for us (uid = $>)." ) );
	}
	$args->{file} = { _filepath => $file };
	my $hash = $self->post_multipart( 'files', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::File', $hash ) );
}

sub file_list
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	my $okParams = 
	{
	expand			=> { allowed => $EXPANDABLES->{file} },
	'created'		=> qr/^\d+$/,
	'created.gt'	=> qr/^\d+$/,
	'created.gte'	=> qr/^\d+$/,
	'created.lt'	=> qr/^\d+$/,
	'created.lte'	=> qr/^\d+$/,
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	ending_before	=> qr/^\w+$/,
	limit			=> qr/^\d+$/,
	purpose			=> {},
	starting_after	=> qr/^\w+$/,
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'files', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub file_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve file information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::File', @_ );
	my $okParams = 
	{
	expand => { allowed => $EXPANDABLES->{file} },
	id => { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No file id was provided to retrieve its information." ) );
	my $hash = $self->get( "files/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::File', $hash ) );
}

sub fraud { return( shift->_response_to_object( 'Net::API::Stripe::Fraud', @_ ) ); }

sub generate_uuid
{
	return( Data::UUID->new->create_str );
}

sub get
{
	my $self = shift( @_ );
	my $path = shift( @_ ) || return( $self->error( "No api endpoint (path) was provided." ) );
	my $args = shift( @_ );
	return( $self->error( "http query parameters provided were not a hash reference." ) ) if( $args && ref( $args ) ne 'HASH' );
	my $api  = $self->api_uri->clone;
	if( $self->_is_object( $path ) && $path->can( 'path' ) )
	{
		$self->message( 3, "$path is a URI object" );
		$api->path( undef() );
		$path = $path->path;
	}
	else
	{
		substr( $path, 0, 0 ) = '/' unless( substr( $path, 0, 1 ) eq '/' );
	}
    $path .= '?' . $self->_encode_params( $args ) if( $args && %$args );
    $self->message( 3, "Preparing get request to ${api}${path}" );
    my $req = HTTP::Request->new( 'GET', $api . $path );
	return( $self->_make_request( $req ) );
}

sub http_client
{
	my $self = shift( @_ );
	return( $self->{ua} ) if( $self->{ua} );
	my $cookie_file = $self->cookie_file;
	my $browser = $self->browser;
	my $ua = LWP::UserAgent->new;
	$ua->timeout( 5 );
	$ua->agent( $browser );
	$ua->cookie_jar({ file => $cookie_file });
	$self->{ua} = $ua;
	return( $ua );
}

sub http_request { return( shift->_set_get_object( 'http_request', 'HTTP::Request', @_ ) ); }

sub http_response { return( shift->_set_get_object( 'http_response', 'HTTP::Response', @_ ) ); }

sub ignore_unknown_parameters { return( shift->_set_get_boolean( 'ignore_unknown_parameters', @_ ) ); }

sub invoice { return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice', @_ ) ); }

sub invoices
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	## Stripe use this api end point uncollectible, but this is prone to mispelling and not easy to remember
	## So we use write off and convert one into another transparently
	$action = 'invoice_write_off' if( $action eq 'invoice_uncollectible' );
	my $allowed = [qw( create delete finalise lines lines_upcoming invoice_write_off upcoming pay retrieve send update void list )];
	my $meth = $self->_get_method( 'coupons', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub invoice_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create an invoice" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	my $obj = $args->{_object};
	## If we are provided with an invoice object, we change our value for only its id
	if( ( $obj && $obj->customer ) || 
		( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) ) )
	{
		my $cust = $obj ? $obj->customer : $args->{customer};
		$args->{customer} = $cust->id || return( $self->error( "The Customer object provided for this invoice has no id." ) );
	}
	
	if( ( $obj && $obj->subscription ) || 
		( $args->{subscription} && $self->_is_object( $args->{subscription} ) && $args->{subscription}->isa( 'Net::API::Stripe::Billing::Subscription' ) ) )
	{
		my $sub = $obj ? $obj->subscription : $args->{subscription};
		$args->{subscription} = $sub->id || return( $self->error( "The Subscription object provided for this invoice has no id." ) );
	}
	
	my $okParams = 
	{
	expandable				=> { allowed => $EXPANDABLES->{invoice} },
	customer				=> { required => 1 },
	application_fee_amount	=> { re => qr/^\d+$/ },
	auto_advance			=> {},
	collection_method		=> { re => qr/^(charge_automatically|send_invoice)$/ },
	custom_fields			=> { fields => [qw( name value )], type => 'array' },
	days_until_due			=> { re => qr/^\d+$/ },
	default_payment_method	=> { re => qr/^\w+$/ },
	default_source			=> { re => qr/^\w+$/ },
	default_tax_rates		=> { re => qr/^\d+(?:\.\d+)?$/ },
	description				=> {},
	due_date				=> {},
	footer					=> {},
	metadata 				=> { type => 'hash' },
	statement_descriptor	=> {},
	subscription			=> { re => qr/^\w+$/ },
	tax_percent				=> { re => qr/^\d+(?:\.\d+)?$/ },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'invoices', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}

## Delete a draft invoice
sub invoice_delete
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to delete a draft invoice." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{invoice} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No draft invoice id was provided to delete its information." ) );
	my $hash = $self->delete( "invoices/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}

sub invoice_finalise
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to pay invoice." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	my $okParams = 
	{
	expandable		=> { allowed => $EXPANDABLES->{invoice} },
	id				=> { re => qr/^\w+$/, required => 1 },
	auto_advance	=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No invoice id was provided to pay it." ) );
	my $hash = $self->post( "invoices/${id}/finalize", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}

## Make everyone happy, British English and American English
*invoice_finalize = \&invoice_finalise;

sub invoice_lines
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to get the invoice line items." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	## There are no expandable properties as of 2020-02-14
	my $okParams = 
	{
	id				=> { re => qr/^\w+$/, required => 1 },
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	ending_before 	=> { re => qr/^\w+$/ },
	limit 			=> { re => qr/^\d+$/ },
	starting_after 	=> { re => qr/^\w+$/ },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( "invoices/${id}/lines", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub invoice_lines_upcoming
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to get the incoming invoice line items." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	## If any
	my $obj = $args->{_object};
	if( ( $obj && $obj->customer ) || 
		( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) ) )
	{
		my $cust = $obj ? $obj-customer : $args->{customer};
		$args->{customer} = $cust->id || return( $self->error( "No customer id could be found in this customer object." ) );
	}
	
	if( ( $obj && $obj->schedule && $obj->schedule->id ) || 
		( $args->{schedule} && $self->_is_object( $args->{schedule} ) && $args->{schedule}->isa( 'Net::API::Stripe::Billing::Subscription::Schedule' ) ) ) 
	{
		my $sched = $obj ? $obj-schedule : $args->{schedule};
		$args->{schedule} = $sched->id || return( $self->error( "No subscription schedule id could be found in this subscription schedule object." ) );
	}
	
	if( ( $obj && $obj->subscription && $obj->subscription->id ) ||
		( $args->{subscription} && $self->_is_object( $args->{subscription} ) && $args->{subscription}->isa( 'Net::API::Stripe::Billing::Subscription' ) ) )
	{
		my $sub = $obj ? $obj-subscription : $args->{subscription};
		$args->{subscription} = $sub->id || return( $self->error( "No subscription id could be found in this subscription object." ) );
	}
	
	my $okParams = 
	{
	customer				=> { re => qr/^\w+$/ },
	coupon					=> {},
	ending_before			=> { re => qr/^\w+$/ },
	invoice_items			=> { type => 'array', fields => [qw( amount currency description discountable invoiceitem metadata period.end period.start quantity tax_rates unit_amount unit_amount_decimal )] },
	limit					=> { re => qr/^\d+$/ },
	schedule				=> { re => qr/^\w+$/ },
	starting_after 			=> { re => qr/^\w+$/ },
	subscription			=> { re => qr/^\w+$/ },
	## A timestamp
	subscription_billing_cycle_anchor => {},
	## A timestamp
	subscription_cancel_at	=> {},
	## Boolean
	subscription_cancel_at_period_end => {},
	## "This simulates the subscription being canceled or expired immediately."
	subscription_cancel_now	=> {},
	subscription_default_tax_rates => { type => 'array' },
	subscription_items		=> {},
	subscription_prorate	=> { re => qr/^(subscription_items|subscription|subscription_items|subscription_trial_end)$/ },
	subscription_proration_behavior => { re => qr/^(create_prorations|none|always_invoice)$/ },
	## Timestamp
	subscription_proration_date => {},
	## Timestamp
	subscription_start_date	=> {},
	subscription_tax_percent=> { re => qr/^\d+(\.\d+)?$/ },
	subscription_trial_end	=> {},
	subscription_trial_from_plan => {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'invoices/upcoming/lines', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub invoice_list
{
	my $self = shift( @_ );
	my $args = $self->_get_args( @_ );
	if( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) )
	{
		$args->{customer} = $args->{customer}->id || return( $self->error( "No customer id could be found in this customer object." ) );
	}
	
	if( $args->{subscription} && $self->_is_object( $args->{subscription} ) && $args->{subscription}->isa( 'Net::API::Stripe::Billing::Subscription' ) )
	{
		$args->{subscription} = $args->{subscription}->id || return( $self->error( "No subscription id could be found in this subscription object." ) );
	}
	
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{invoice}, data_prefix_is_ok => 1 },
	collection_method	=> { re => qr/^(charge_automatically|send_invoice)$/ },
	created 			=> { re => qr/^\d+$/ },
	'created.gt' 		=> { re => qr/^\d+$/ },
	'created.gte' 		=> { re => qr/^\d+$/ },
	'created.lt' 		=> { re => qr/^\d+$/ },
	'created.lte' 		=> { re => qr/^\d+$/ },
	customer			=> { re => qr/^\w+$/ },
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'due_date.gt' 		=> { re => qr/^\d+$/ },
	'due_date.gte' 		=> { re => qr/^\d+$/ },
	'due_date.lt' 		=> { re => qr/^\d+$/ },
	'due_date.lte' 		=> { re => qr/^\d+$/ },
	ending_before 		=> { re => qr/^\w+$/ },
	limit 				=> { re => qr/^\d+$/ },
	starting_after 		=> { re => qr/^\w+$/ },
	status				=> { re => qr/^(draft|open|paid|uncollectible|void)$/ },
	subscription		=> { re => qr/^\w+$/ },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'invoices', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub invoice_pay
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to pay invoice." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	my $obj = $args->{_object};
	if( ( $obj && $obj->payment_method ) ||
		( $args->{payment_method} && $self->_is_object( $args->{payment_method} ) && $args->{payment_method}->isa( 'Net::API::Stripe::Payment::Method' ) ) )
	{
		my $pm = $obj ? $obj->payment_method : $args->{payment_method};
		$args->{payment_method} = $pm->id || return( $self->error( "No payment method id could be found in this payment method object." ) );
	}
	
	if( ( $obj && $obj->source ) || 
		( $args->{source} && $self->_is_object( $args->{source} ) && $args->{source}->isa( 'Net::API::Stripe::Payment::Source' ) ) )
	{
		my $src = $obj ? $obj->source : $args->{source};
		$args->{source} = $src->id || return( $self->error( "No payment source id could be found in this payment source object." ) );
	}
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{invoice} },
	id 					=> { re => qr/^\w+$/, required => 1 },
	## Boolean for the case where the amount received is not the exact one claimed and to basically give it up
	forgive				=> {},
	## Boolean
	off_session			=> {},
	## Boolean: paid outside of Stripe
	paid_out_of_band	=> {},
	payment_method		=> { re => qr/^\w+$/ },
	source				=> { re => qr/^\w+$/ },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No invoice id was provided to pay it." ) );
	my $hash = $self->post( "invoices/${id}/pay", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}

sub invoice_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve invoice information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{invoice} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No invoice id was provided to retrieve its information." ) );
	my $hash = $self->get( "invoices/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}

sub invoice_send
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to send invoice." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{invoice} },
	id 			=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No invoice id was provided to send it." ) );
	my $hash = $self->post( "invoices/${id}/send", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}

sub invoice_upcoming
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve an upcoming invoice." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	
	my $obj = $args->{_object};
	if( ( $obj && $obj->customer ) ||
		( $self->_is_object( $args->{customer} ) && $args->{customer}->isa( 'Net::API::Stripe::Customer' ) ) )
	{
		my $cust = $obj ? $obj->customer : $args->{customer};
		$args->{customer} = $cust->id || return( $self->error( "No customer id could be found in this customer object." ) );
	}
	
	if( ( $obj && $obj->schedule ) ||
		( $args->{schedule} && $self->_is_object( $args->{schedule} ) && $args->{schedule}->isa( 'Net::API::Stripe::Billing::Subscription::Schedule' ) ) )
	{
		my $sched = $obj ? $obj->schedule : $args->{schedule};
		$args->{schedule} = $sched->id || return( $self->error( "No subscription schedule id could be found in this subscription schedule object." ) );
	}
	
	if( ( $obj && $obj->subscription ) ||
		( $args->{subscription} && $self->_is_object( $args->{subscription} ) && $args->{subscription}->isa( 'Net::API::Stripe::Billing::Subscription' ) ) )
	{
		my $sub = $obj ? $obj->subscription : $args->{subscription};
		$args->{subscription} = $sub->id || return( $self->error( "No subscription id could be found in this subscription object." ) );
	}
	
	my $okParams = 
	{
	expandable					=> { allowed => $EXPANDABLES->{invoice} },
	customer					=> { re => qr/^\w+$/ },
	coupon						=> {},
	invoice_items				=> { type => 'array', fields => [qw( amount currency description discountable invoiceitem metadata period.end period.start quantity tax_rates unit_amount unit_amount_decimal )] },
	schedule					=> { re => qr/^\w+$/ },
	subscription				=> { re => qr/^\w+$/ },
	## A timestamp
	subscription_billing_cycle_anchor => {},
	## A timestamp
	subscription_cancel_at		=> {},
	## Boolean
	subscription_cancel_at_period_end => {},
	## "This simulates the subscription being canceled or expired immediately."
	subscription_cancel_now		=> {},
	subscription_default_tax_rates => { type => 'array' },
	subscription_items			=> {},
	subscription_prorate		=> { re => qr/^(subscription_items|subscription|subscription_items|subscription_trial_end)$/ },
	subscription_proration_behavior => { re => qr/^(create_prorations|none|always_invoice)$/ },
	## Timestamp
	subscription_proration_date => {},
	## Timestamp
	subscription_start_date		=> {},
	subscription_tax_percent	=> { re => qr/^\d+(\.\d+)?$/ },
	subscription_trial_end		=> {},
	subscription_trial_from_plan => {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'invoices/upcoming', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}

sub invoice_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update an invoice" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	
	my $okParams = 
	{
	expandable				=> { allowed => $EXPANDABLES->{invoice} },
	id 						=> { re => qr/^\w+$/, required => 1 },
	application_fee_amount	=> { re => qr/^\d+$/ },
	auto_advance			=> {},
	collection_method		=> { re => qr/^(charge_automatically|send_invoice)$/ },
	custom_fields			=> { fields => [qw( name value )], type => 'array' },
	days_until_due			=> { re => qr/^\d+$/ },
	default_payment_method	=> { re => qr/^\w+$/ },
	default_source			=> { re => qr/^\w+$/ },
	default_tax_rates		=> { re => qr/^\d+(?:\.\d+)?$/ },
	description				=> {},
	due_date				=> {},
	footer					=> {},
	metadata 				=> { type => 'hash' },
	statement_descriptor	=> {},
	tax_percent				=> { re => qr/^\d+(?:\.\d+)?$/ },
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No invoice id was provided to update invoice's details" ) );
	my $hash = $self->post( "invoices/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}

sub invoice_void
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to void invoice information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{invoice} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No invoice id was provided to void it." ) );
	my $hash = $self->post( "invoices/${id}/void", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}

sub invoice_write_off
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to make invoice uncollectible." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Invoice', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{invoice} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No invoice id was provided to make it uncollectible." ) );
	my $hash = $self->post( "invoices/${id}/mark_uncollectible", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Invoice', $hash ) );
}

sub invoice_item { return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Item', @_ ) ); }

sub invoice_line_item { return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice::LineItem', @_ ) ); }

sub invoice_settings { return( shift->_response_to_object( 'Net::API::Stripe::Billing::Invoice::Settings', @_ ) ); }

# sub issuing { return( shift->_instantiate( 'issuing', 'Net::API::Stripe::Issuing' ) ) }

sub issuing_card { return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Card', @_ ) ); }

sub issuing_dispute { return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Dispute', @_ ) ); }

sub issuing_transaction { return( shift->_response_to_object( 'Net::API::Stripe::Issuing::Transaction', @_ ) ); }

sub json { return( JSON->new->allow_nonref ); }

sub key
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $key = $self->{key} = shift( @_ );
		my $auth = 'Basic ' . MIME::Base64::encode_base64( $key . ':' );
		$self->auth( $auth );
	}
	return( $self->{key} );
}

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub location { return( shift->_response_to_object( 'Net::API::Stripe::Terminal::Location', @_ ) ); }

sub login_link { return( shift->_response_to_object( 'Net::API::Stripe::Connect::Account::LoginLink', @_ ) ); }

sub order { return( shift->_response_to_object( 'Net::API::Stripe::Order' ) ) }

sub order_item { return( shift->_response_to_object( 'Net::API::Stripe::Order::Item' ) ) }

## subs to access child packages
sub payment_intent { return( shift->_response_to_object( 'Net::API::Stripe::Payment::Intent', @_ ) ); }

sub payment_method { return( shift->_response_to_object( 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub payment_methods
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve update list attach detach )];
	my $meth = $self->_get_method( 'payment_method', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub payment_method_attach
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to attach a payment method" ) ) if( !scalar( @_ ) );
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
	expandable	=> { allowed => $EXPANDABLES->{payment_method} },
	id			=> { re => qr/^\w+$/, required => 1 },
	customer	=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No payment method id was provided to attach to attach it to the customer with id \"$args->{customer}\"." ) );
	my $hash = $self->post( "payment_methods/${id}/attach", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}

sub payment_method_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a payment_method" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{payment_method} },
	type				=> { re => qr/^(?:card|fpx|ideal|sepa_debit)$/, required => 1 },
	billing_details		=> { fields => [qw( address.city address.country address.line1 address.line2 address.postal_code address.state email name phone )] },
	metadata			=> { type => 'hash' },
	card				=> { fields => [qw( exp_month exp_year number cvc )] },
	fpx					=> { fields => [qw( bank )] },
	ideal				=> { fields => [qw( bank )] },
	sepa_debit			=> { fields => [qw( iban )] },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'payment_methods', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}

## https://stripe.com/docs/api/payment_methods/detach
sub payment_method_detach
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to detach a payment method." ) ) if( !scalar( @_ ) );
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
			return( $self->error( "No payent method id could be found in this customer object." ) ) if( !$args->{id} );
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
	expandable	=> { allowed => $EXPANDABLES->{payment_method} },
	id			=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No payment method id was provided to attach to attach it to the customer with id \"$args->{customer}\"." ) );
	my $hash = $self->post( "payment_methods/${id}/detach", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}

sub payment_method_list
{
	my $self = shift( @_ );
	my $args = $self->_get_args( @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{payment_method}, data_prefix_is_ok => 1 },
	customer			=> { required => },
	type				=> { re => qr/^(?:card|fpx|ideal|sepa_debit)$/, required => 1 },
	ending_before		=> {},
	limit				=> { re => qr/^\d+$/ },
	starting_after		=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'payment_methods', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub payment_method_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve payment method information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{payment_method} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No payment method id was provided to retrieve its information." ) );
	my $hash = $self->get( "payment_methods/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}

## https://stripe.com/docs/api/payment_methods/update
sub payment_method_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a payment method" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Method', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{payment_method} },
	id					=> { re => qr/^\w+$/, required => 1 },
	billing_details		=> { fields => [qw( address.city address.country address.line1 address.line2 address.postal_code address.state email name phone )] },
	metadata			=> { type => 'hash' },
	card				=> { fields => [qw( exp_month exp_year )] },
	sepa_debit			=> { fields => [qw( iban )] },
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No payment method id was provided to update payment method's details" ) );
	my $hash = $self->post( "payment_methods/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Method', $hash ) );
}

sub payout { return( shift->_response_to_object( 'Net::API::Stripe::Payout', @_ ) ); }

sub person { return( shift->_response_to_object( 'Net::API::Stripe::Connect::Person', @_ ) ); }

sub plan { return( shift->_response_to_object( 'Net::API::Stripe::Billing::Plan', @_ ) ); }

sub plans
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve update list delete )];
	my $meth = $self->_get_method( 'plan', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

## Find plan by product id or nickname
sub plan_by_product
{
	my $self = shift( @_ );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product', @_ );
	my $id = CORE::delete( $args->{id} );
	my $nickname = CORE::delete( $args->{nickname} );
	return( $self->error( "No product id or plan name was provided to find its related product." ) ) if( !$id && !$nickname );
	$self->message( 3, "Finding the plans associated with a product using product id '$id' and product nickname '$nickname'." );
	$args->{product} = $id if( $id );
	my $check_both_active_and_inactive = 0;
	if( !CORE::length( $args->{active} ) )
	{
		$check_both_active_and_inactive++;
		$args->{active} = $self->true;
	}
	my $list = $self->plans( list => $args ) || return;
	$self->message( 3, "http request issued is: ", $self->http_request->as_string );
	my $objects = [];
	while( my $this = $list->next )
	{
		## If this was specified, this is a restrictive query
		if( $nickname && $this->nickname eq $nickname )
		{
			CORE::push( @$objects, $this );
		}
		## or at least we have this
		elsif( $id )
		{
			CORE::push( @$objects, $this );
		}
	}
	## Now, we also have to check for inactive plans, because Stripe requires the active parameter to be provided or else it defaults to inactive
	## How inefficient...
	if( $check_both_active_and_inactive )
	{
		$args->{active} = $self->false;
		my $list = $self->plans( list => $args ) || return;
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
	return( $objects );
}

sub plan_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a plan" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Plan', @_ );
	my $obj = $args->{_object};
	if( $self->_is_object( $args->{product} ) && $args->{product}->isa( 'Net::API::Stripe::Product' ) )
	{
		my $prod_hash = $args->{product}->as_hash({ json => 1 });
		$args->{product} = $prod_hash;
	}
	#$self->message( 3, "Data to be submitted to create a plan is: ", sub{ $self->dumper( $args ) });
	#exit;
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{plan} },
	id					=> {},
	active				=> {},
	aggregate_usage		=> {},
	amount				=> { required => 1 },
	amount_decimal		=> {},
	billing_scheme		=> {},
	currency			=> { required => 1 },
	interval			=> { requried => 1, re => qr/^(?:day|week|month|year)$/ },
	interval_count		=> {},
	metadata			=> { type => 'hash' },
	nickname			=> {},
	product				=> { required => 1 },
	tiers				=> { fields => [qw( up_to flat_amount flat_amount_decimal unit_amount unit_amount_decimal )] },
	tiers_mode			=> { re => qr/^(graduated|volume)$/ },
	transform_usage		=> { fields => [qw( divide_by round )] },
	trial_period_days	=> {},
	usage_type			=> { re => qr/^(?:metered|licensed)$/ },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'plans', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Plan', $hash ) );
}

## https://stripe.com/docs/api/customers/delete?lang=curl
## "Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer."
sub plan_delete
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to delete plan information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Plan', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{plan} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No plan id was provided to delete its information." ) );
	my $hash = $self->delete( "plans/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Plan', $hash ) );
}

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
	expandable			=> { allowed => $EXPANDABLES->{plan}, data_prefix_is_ok => 1 },
	# boolean
	'active'			=> {},
	'created' 			=> { re => qr/^\d+$/ },
	'created.gt'		=> { re => qr/^\d+$/ },
	'created.gte'		=> { re => qr/^\d+$/ },
	'created.lt'		=> { re => qr/^\d+$/ },
	'created.lte'		=> { re => qr/^\d+$/ },
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before'		=> {},
	'limit'				=> { re => qr/^\d+$/ },
	'product'			=> { re => qr/^\w+$/ },
	'starting_after'	=> {},
	};
	foreach my $bool ( qw( active ) )
	{
		next if( !CORE::length( $args->{ $bool } ) );
		$args->{ $bool } = ( $args->{ $bool } eq 'true' || ( $args->{ $bool } ne 'false' && $args->{ $bool } ) ) ? 'true' : 'false';
	}
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'plans', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub plan_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve plan information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Plan', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{plan} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No plan id was provided to retrieve its information." ) );
	my $hash = $self->get( "plans/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Plan', $hash ) );
}

## https://stripe.com/docs/api/customers/update?lang=curl
sub plan_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a plan" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Plan', @_ );
	if( $self->_is_object( $args->{product} ) && $args->{product}->isa( 'Net::API::Stripe::Product' ) )
	{
		$args->{product} = $args->{product}->id;
	}
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{plan} },
	id					=> { required => 1 },
	active				=> { re => qr/^(?:true|False)$/ },
	metadata			=> { type => 'hash' },
	nickname			=> {},
	product				=> { re => qr/^\w+$/ },
	trial_period_days	=> {},
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No plan id was provided to update plan's details" ) );
	my $hash = $self->post( "plans/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Plan', $hash ) );
}

sub post
{
	my $self = shift( @_ );
	my $path = shift( @_ ) || return( $self->error( "No api endpoint (path) was provided." ) );
	my $args = shift( @_ );
	return( $self->error( "http query parameters provided were not a hash reference." ) ) if( $args && ref( $args ) ne 'HASH' );
	my $ua   = $self->http_client;
	my $api  = $self->api_uri->clone;
	if( $self->_is_object( $path ) && $path->can( 'path' ) )
	{
		$self->message( 3, "$path is a URI object" );
		$api->path( undef() );
		$path = $path->path;
	}
	else
	{
		substr( $path, 0, 0 ) = '/' unless( substr( $path, 0, 1 ) eq '/' );
	}
# 	my $ref = $self->_encode_params( $args );
# 	$self->message( 3, "Redeem by ref is '", ref( $args->{redeem_by} ), "'." );
# 	$self->message( 3, $self->dump( $ref ) ); exit;
	my $h = [];
	if( exists( $args->{idempotency} ) )
	{
		$args->{idempotency} = $self->generate_uuid if( !length( $args->{idempotency} ) );
		$self->messagef( 3, "Using idempotency key %s", $args->{idempotency} );
		push( @$h, 'Idempotency-Key', CORE::delete( $args->{idempotency} ) );
	}
	my $req = HTTP::Request->new(
		'POST', $api . $path, 
		$h,
		( $args ? $self->_encode_params( $args ) : undef() )
	);
	$self->message( 3, "Post request is: ", $req->as_string );
	return( $self->_make_request( $req ) );
}

## Using rfc2388 rules
## https://tools.ietf.org/html/rfc2388
sub post_multipart
{
	my $self = shift( @_ );
	my $path = shift( @_ ) || return( $self->error( "No api endpoint (path) was provided." ) );
	my $args = shift( @_ );
	return( $self->error( "http query parameters provided were not a hash reference." ) ) if( $args && ref( $args ) ne 'HASH' );
	my $ua   = $self->http_client;
	my $api  = $self->api_uri->clone;
	if( $self->_is_object( $path ) && $path->can( 'path' ) )
	{
		$self->message( 3, "$path is a URI object" );
		$api->path( undef() );
		$path = $path->path;
	}
	else
	{
		substr( $path, 0, 0 ) = '/' unless( substr( $path, 0, 1 ) eq '/' );
	}
	my $h = HTTP::Headers->new(
		Content_Type => 'multipart/form-data',
	);
	if( exists( $args->{idempotency} ) )
	{
		$args->{idempotency} = $self->generate_uuid if( !length( $args->{idempotency} ) );
		$self->messagef( 3, "Using idempotency key %s", $args->{idempotency} );
		$h->header( 'Idempotency-Key' => CORE::delete( $args->{idempotency} ) );
	}
	my $req = HTTP::Request->new( POST => $api . $path, $h );
	my $data = $self->_encode_params_multipart( $args, { encoding => 'quoted-printable' } );
	foreach my $f ( keys( %$data ) )
	{
		foreach my $ref ( @{$data->{ $f }} )
		{
			if( $ref->{filename} )
			{
				my $fname = $ref->{filename};
				$req->add_part( HTTP::Message->new(
					HTTP::Headers->new(
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
				$req->add_part( HTTP::Message->new(
					HTTP::Headers->new(
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
	$self->message( 3, "Post request is: ", $req->as_string );
	return( $self->_make_request( $req ) );
}

sub prices
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve update list )];
	my $meth = $self->_get_method( 'price', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub price_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a price" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Price', @_ );
	my $obj = $args->{_object};
	if( $self->_is_object( $args->{product} ) && $args->{product}->isa( 'Net::API::Stripe::Product' ) )
	{
		my $prod_hash = $args->{product}->as_hash({ json => 1 });
		$args->{product} = $prod_hash;
	}
	#$self->message( 3, "Data to be submitted to create a plan is: ", sub{ $self->dumper( $args ) });
	#exit;
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{price} },
	id					=> {},
	active				=> {},
	billing_scheme      => {},
	currency            => { required => 1 },
	lookup_key          => {},
	metadata			=> { type => 'hash' },
	nickname			=> {},
	product				=> { required => 1 },
	product_data        => { fields => [qw( id name active metadata statement_descriptor unit_label )] },
	recurring           => { fields => [qw( interval aggregate_usage interval_count trial_period_days usage_type )] },
	transfer_lookup_key => {},
	transform_quantity  => { fields => [qw( divide_by round )] },
	tiers               => { fields => [qw( up_to flat_amount flat_amount_decimal unit_amount unit_amount_decimal )] },
	tiers_mode			=> { re => qr/^(graduated|volume)$/ },
	unit_amount         => { required => 1 },
	unit_amount_decimal => {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'prices', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Price', $hash ) );
}

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
	expandable			=> { allowed => $EXPANDABLES->{price}, data_prefix_is_ok => 1 },
	# boolean
	active			    => {},
	created 			=> { re => qr/^\d+$/ },
	'created.gt'		=> { re => qr/^\d+$/ },
	'created.gte'		=> { re => qr/^\d+$/ },
	'created.lt'		=> { re => qr/^\d+$/ },
	'created.lte'		=> { re => qr/^\d+$/ },
	currency            => {},
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	ending_before		=> {},
	limit				=> { re => qr/^\d+$/ },
	lookup_keys         => {},
	product			    => { re => qr/^\w+$/ },
	recurring           => { fields => [qw( interval usage_type )] },
	starting_after	    => {},
	type                => {},
	};
	foreach my $bool ( qw( active ) )
	{
		next if( !CORE::length( $args->{ $bool } ) );
		$args->{ $bool } = ( $args->{ $bool } eq 'true' || ( $args->{ $bool } ne 'false' && $args->{ $bool } ) ) ? 'true' : 'false';
	}
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'prices', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub price_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve price information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Price', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{price} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No price id was provided to retrieve its information." ) );
	my $hash = $self->get( "prices/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Price', $hash ) );
}

## https://stripe.com/docs/api/customers/update?lang=curl
sub price_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a price object" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Price', @_ );
	if( $self->_is_object( $args->{product} ) && $args->{product}->isa( 'Net::API::Stripe::Product' ) )
	{
		$args->{product} = $args->{product}->id;
	}
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{price} },
	id					=> { required => 1 },
	active				=> { re => qr/^(?:true|False)$/ },
	lookup_key          => {},
	metadata			=> { type => 'hash' },
	nickname			=> {},
	recurring           => { fields => [qw( interval aggregate_usage interval_count trial_period_days usage_type )] },
	transfer_lookup_key => {},
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No price id was provided to update price's details" ) );
	my $hash = $self->post( "prices/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Price', $hash ) );
}

sub product { return( shift->_response_to_object( 'Net::API::Stripe::Product', @_ ) ); }

sub products
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve update list delete )];
	my $meth = $self->_get_method( 'product', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub product_by_name
{
	my $self = shift( @_ );
	my $args = $self->_get_args( @_ );
	my $name = CORE::delete( $args->{name} );
	my $nicname = CORE::delete( $args->{nickname} );
	my $list = $self->products( list => $args ) || return;
	my $objects = [];
	while( my $this = $list->next )
	{
		if( ( $name && $this->name eq $name ) ||
			( $nickname && $this->nickname eq $nickname ) )
		{
			CORE::push( @$objects, $this );
		}
	}
	return( $objects );
}

sub product_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a product" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{product} },
	## Yes, an id may be provided
	id					=> {},
	name				=> { required => 1 },
	type				=> { re => qr/^(good|service)$/, required => 1 },
	active				=> {},
	## Used to exist, but then disappeaared from the api
	attributes			=> sub{ return( ref( $_[0] ) eq 'ARRAY' && scalar( @{$_[0]} ) <= 5 ? undef() : "An array reference of up to 5 items was expected." ) },
	caption				=> {},
	deactivate_on		=> { type => 'array' },
	description			=> {},
	images				=> sub{ return( ref( $_[0] ) eq 'ARRAY' && scalar( @{$_[0]} ) <= 8 ? undef() : "An array reference of up to 8 images was expected." ) },
	metadata 			=> { type => 'hash' },
	package_dimensions	=> {},
	shippable			=> {},
	statement_descriptor => {},
	unit_label			=> {},
	url					=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'products', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Product', $hash ) );
}

## https://stripe.com/docs/api/customers/delete?lang=curl
## "Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer."
sub product_delete
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to delete product information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product', @_ );
	my $okParams = 
	{
	expandable => { allowed => $EXPANDABLES->{product} },
	id => { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No product id was provided to delete its information." ) );
	my $hash = $self->delete( "products/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Product', $hash ) );
}

sub product_list
{
	my $self = shift( @_ );
	my $args = $self->_get_args( @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{product} },
	'created' 			=> { re => qr/^\d+$/ },
	'created.gt'		=> { re => qr/^\d+$/ },
	'created.gte'		=> { re => qr/^\d+$/ },
	'created.lt'		=> { re => qr/^\d+$/ },
	'created.lte'		=> { re => qr/^\d+$/ },
	# boolean
	'active'			=> { type => 'boolean' },
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before'		=> {},
	'ids'				=> { type => 'array' },
	'limit'				=> { re => qr/^\d+$/ },
	# boolean
	'shippable'			=> { type => 'boolean' },
	'starting_after'	=> {},
	'type'				=> {},
	'url'				=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'products', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub product_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve product information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product', @_ );
	my $okParams = 
	{
	expandable => { allowed => $EXPANDABLES->{product} },
	id => { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No product id was provided to retrieve its information." ) );
	my $hash = $self->get( "products/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Product', $hash ) );
}

## https://stripe.com/docs/api/customers/update?lang=curl
sub product_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a product" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Product', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{product} },
	id					=> { re => qr/^\w+$/, required => 1 },
	active				=> {},
	attributes			=> sub{ return( ref( $_[0] ) eq 'ARRAY' && scalar( @{$_[0]} ) <= 5 ? undef() : "An array reference of up to 5 items was expected." ) },
	caption				=> {},
	deactivate_on		=> { type => 'array' },
	description			=> {},
	images				=> sub{ return( ref( $_[0] ) eq 'ARRAY' && scalar( @{$_[0]} ) <= 8 ? undef() : "An array reference of up to 8 images was expected." ) },
	metadata 			=> { type => 'hash' },
	name				=> { required => 1 }.
	package_dimensions	=> {},
	shippable			=> {},
	statement_descriptor => {},
	type				=> { re => qr/^(good|service)$/, required => 1 },
	unit_label			=> {},
	url					=> {},
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No product id was provided to update product's details" ) );
	my $hash = $self->post( "products/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Product', $hash ) );
}

sub reader { return( shift->_response_to_object( 'Net::API::Stripe::Terminal::Reader' ) ) }

sub refund { return( shift->_response_to_object( 'Net::API::Stripe::Refund', @_ ) ); }

sub return { return( shift->_response_to_object( 'Net::API::Stripe::Order::Return' ) ) }

sub review { return( shift->_response_to_object( 'Net::API::Stripe::Fraud::Review', @_ ) ); }

sub schedule { return( shift->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ ) ); }

sub schedules
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve update list cancel release )];
	my $meth = $self->_get_method( 'schedule', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

## https://stripe.com/docs/api/subscription_schedules/cancel?lang=curl
## "Cancels a subscription schedule and its associated subscription immediately (if the subscription schedule has an active subscription). A subscription schedule can only be canceled if its status is not_started or active."
sub schedule_cancel
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to cancel subscription schedule information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{schedule} },
	id 			=> { re => qr/^\w+$/, required => 1 },
	## "If the subscription schedule is active, indicates whether or not to generate a final invoice that contains any un-invoiced metered usage and new/pending proration invoice items. Defaults to true."
	invoice_now => { type => 'boolean' },
	## "If the subscription schedule is active, indicates if the cancellation should be prorated. Defaults to true."
	prorate 	=> { type => 'boolean' },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No subscription schedule id was provided to cancel." ) );
	my $hash = $self->post( "subscription_schedules/${id}/cancel", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}

sub schedule_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a subscription schedule" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{schedule} },
	customer			=> {},
	default_settings	=> { fields => [qw( billing_thresholds.amount_gte billing_thresholds.reset_billing_cycle_anchor collection_method default_payment_method invoice_settings.days_until_due )] },
	end_behavior		=> { re => qr/^(release|cancel)$/ },
	from_subscription	=> {},
	metadata			=> {},
	phases				=> { type => 'array', fields => [qw( plans.plan plans.billing_thresholds.usage_gte plans.quantity plans.tax_rates application_fee_percent billing_thresholds.amount_gte billing_thresholds.reset_billing_cycle_anchor collection_method coupon default_payment_method default_tax_rates end_date invoice_settings.days_until_due iterations tax_percent trial trial_end )]},
	start_date			=> { type => 'datetime' },
	};
	
	my $obj = $args->{_object};
	if( $obj )
	{
		$args->{start_date} = $obj->current_phase->start_date->epoch;
	}
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'subscription_schedules', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}

sub schedule_list
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{schedule}, data_prefix_is_ok => 1 },
	'canceled_at'		=> { re => qr/^\d+$/ },
	'canceled_at.gt'	=> { re => qr/^\d+$/ },
	'canceled_at.gte'	=> { re => qr/^\d+$/ },
	'canceled_at.lt'	=> { re => qr/^\d+$/ },
	'canceled_at.lte'	=> { re => qr/^\d+$/ },
	'completed_at'		=> { re => qr/^\d+$/ },
	'completed_at.gt'	=> { re => qr/^\d+$/ },
	'completed_at.gte'	=> { re => qr/^\d+$/ },
	'completed_at.lt'	=> { re => qr/^\d+$/ },
	'completed_at.lte'	=> { re => qr/^\d+$/ },
	'created' 			=> { re => qr/^\d+$/ },
	'created.gt'		=> { re => qr/^\d+$/ },
	'created.gte'		=> { re => qr/^\d+$/ },
	'created.lt'		=> { re => qr/^\d+$/ },
	'created.lte'		=> { re => qr/^\d+$/ },
	'customer'			=> {},
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before'		=> {},
	'limit'				=> { re => qr/^\d+$/ },
	'released_at'		=> { re => qr/^\d+$/ },
	'released_at.gt'	=> { re => qr/^\d+$/ },
	'released_at.gte'	=> { re => qr/^\d+$/ },
	'released_at.lt'	=> { re => qr/^\d+$/ },
	'released_at.lte'	=> { re => qr/^\d+$/ },
	'scheduled'			=> { type => 'boolean' },
	'starting_after'	=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'subscription_schedules', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

## "Releases the subscription schedule immediately, which will stop scheduling of its phases, but leave any existing subscription in place. A schedule can only be released if its status is not_started or active. If the subscription schedule is currently associated with a subscription, releasing it will remove its subscription property and set the subscription’s ID to the released_subscription property."
## https://stripe.com/docs/api/subscription_schedules/release
sub schedule_release
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve subscription schedule information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
	my $okParams = 
	{
	expandable				=> { allowed => $EXPANDABLES->{schedule} },
	id						=> { re => qr/^\w+$/, required => 1 },
	preserve_cancel_date 	=> { type => 'boolean' },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No subscription schedule id was provided to retrieve its information." ) );
	my $hash = $self->post( "subscription_schedules/${id}/release", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}

sub schedule_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve subscription schedule information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{schedule} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No subscription schedule id was provided to retrieve its information." ) );
	my $hash = $self->get( "subscription_schedules/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}

## https://stripe.com/docs/api/customers/update?lang=curl
sub schedule_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a subscription schedule" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription::Schedule', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{schedule} },
	id 					=> { re => qr/^\w+$/, required => 1 },
	default_settings	=> { fields => [qw( billing_thresholds.amount_gte billing_thresholds.reset_billing_cycle_anchor collection_method default_payment_method invoice_settings.days_until_due )] },
	end_behavior		=> { re => qr/^(release|cancel)$/ },
	from_subscription	=> {},
	metadata			=> { type => 'hash' },
	phases				=> { type => 'array', fields => [qw( plans.plan plans.billing_thresholds.usage_gte plans.quantity plans.tax_rates application_fee_percent billing_thresholds.amount_gte billing_thresholds.reset_billing_cycle_anchor collection_method coupon default_payment_method default_tax_rates end_date invoice_settings.days_until_due iterations tax_percent trial trial_end )]},
	prorate			=> { type => 'boolean' },
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No subscription schedule id was provided to update subscription schedule's details" ) );
	my $hash = $self->post( "subscription_schedules/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Schedule', $hash ) );
}

# sub session { return( shift->_response_to_object( 'Net::API::Stripe::Session', @_ ) ); }

sub schedule_query { return( shift->_response_to_object( 'Net::API::Stripe::Sigma::ScheduledQueryRun' ) ) }

sub session { return( shift->_response_to_object( 'Net::API::Stripe::Checkout::Session', @_ ) ); }

sub sessions
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve list )];
	my $meth = $self->_get_method( 'subscription', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

## https://stripe.com/docs/api/checkout/sessions/create
## https://stripe.com/docs/payments/checkout/fulfillment#webhooks
## See webhook event checkout.session.completed
sub session_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a session" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Checkout::Session', @_ );
	my $okParams = 
	{
	expandable				=> { allowed => $EXPANDABLES->{session} },
	cancel_url				=> { required => 1 },
	payment_method_types	=> { required => 1, re => qr/^(card|ideal)$/ },
	success_url				=> { required => 1 },
	billing_address_collection	=> { re => qr/^(auto|required)$/ },
	client_reference_id		=> {},
	## ID of an existing customer, if one exists.
	customer				=> {},
	customer_email			=> {},
	## array of hash reference
	line_items				=> { type => 'array', fields => [qw( amount currency name quantity description images )] },
	locale					=> { re => qr/^(local|[a-z]{2})$/ },
	mode					=> { re => qr/^(setup|subscription)$/ },
	payment_intent_data		=> { fields => [qw( application_fee_amount capture_method description metadata on_behalf_of receipt_email setup_future_usage shipping.address.line1 shipping.address.line2 shipping.address.city shipping.address.country shipping.address.postal_code shipping.address.state shipping.name shipping.carrier shipping.phone shipping.tracking_number statement_descriptor transfer_data.destination )] },
	setup_intent_data		=> { fields => [qw( description metadata on_behalf_of )] },
	submit_type				=> { re => qr/^(auto|book|donate|pay)$/ },
	subscription_data		=> { fields => [qw( items.plan items.quantity application_fee_percent metadata trial_end trial_from_plan trial_period_days )] },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'checkout/sessions', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Checkout::Session', $hash ) );
}

sub session_list
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{schedule}, data_prefix_is_ok => 1 },
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before'		=> {},
	'limit'				=> { re => qr/^\d+$/ },
	'payment_intent'	=> { type => 'scalar' },
	'subscription'		=> { re => qr/^\w+$/ },
	'starting_after'	=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'checkout/sessions', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub session_retrieve
{
	my $self = shift( @_ );
	my $args = shift( @_ ) || return( $self->error( "No parameters were provided to retrieve a tax id" ) );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{session} },
	id			=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No tax id was provided to retrieve its details" ) );
	my $hash = $self->get( "checkout/sessions/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Checkout::Session', $hash ) );
}

sub setup_intent { return( shift->_response_to_object( 'Net::API::Stripe::Payment::Intent::Setup', @_ ) ); }

# sub sigma { return( shift->_instantiate( 'sigma', 'Net::API::Stripe::Sigma' ) ) }

sub shipping { return( shift->_response_to_object( 'Net::API::Stripe::Shipping', @_ ) ); }

sub sku { return( shift->_response_to_object( 'Net::API::Stripe::Order::SKU' ) ) }

sub source { return( shift->_response_to_object( 'Net::API::Stripe::Payment::Source', @_ ) ); }

sub sources
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve update detach attach )];
	my $meth = $self->_get_method( 'source', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub source_attach
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to attach a source." ) ) if( !scalar( @_ ) );
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
	expandable	=> { allowed => $EXPANDABLES->{session} },
	id			=> { re => qr/^\w+$/, required => 1 },
	source		=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No customer id was provided to attach the source to." ) );
	my $hash = $self->post( "customers/${id}/sources", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Source', $hash ) );
}

sub source_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a source" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Source', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{session} },
	type				=> { required => 1 },
	amount				=> {},
	currency			=> {},
	flow				=> {},
	mandate				=> { fields => [qw( acceptance acceptance.status acceptance.date acceptance.ip acceptance.offline.contact_email acceptance.online acceptance.type acceptance.user_agent amount currency interval notification_method )] },
	metadata			=> { type => 'hash' },
	owner				=> { fields => [qw( address.city address.country address.line1 address.line2 address.postal_code address.state email name phone )] },
	receiver			=> { fields => [qw( refund_attributes_method )] },
	redirect			=> { fields => [qw( return_url )] },
	source_order		=> { fields => [qw( items.amount items.currency items.description items.parent items.quantity items.type shipping.address.city shipping.address.country shipping.address.line1 shipping.address.line2 shipping.address.postal_code shipping.address.state shipping.carrier shipping.name shipping.phone shipping.tracking_number )] },
	statement_descriptor	=> {},
	token				=> {},
	usage				=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $hash = $self->post( 'sources', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Source', $hash ) );
}

## https://stripe.com/docs/api/customers/delete?lang=curl
## "Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer."
sub source_detach
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to detach a source." ) ) if( !scalar( @_ ) );
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
	expandable	=> { allowed => $EXPANDABLES->{session} },
	id			=> { re => qr/^\w+$/, required => 1 },
	source		=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No customer id was provided to detach the source from it." ) );
	my $src_id = CORE::delete( $args->{source} ) || return( $self->error( "No source id was provided to detach." ) );
	my $hash = $self->delete( "customers/${id}/sources/${src_id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Source', $hash ) );
}

sub source_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve source information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Source', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{session} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No source id was provided to retrieve its information." ) );
	my $hash = $self->get( "sources/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Source', $hash ) );
}

## https://stripe.com/docs/api/sources/update?lang=curl
sub source_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a source" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Payment::Source', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{session} },
	id					=> { re => qr/^\w+$/, required => 1 },
	amount				=> {},
	mandate				=> { fields => [qw( acceptance acceptance.status acceptance.date acceptance.ip acceptance.offline.contact_email acceptance.online acceptance.type acceptance.user_agent amount currency interval notification_method )] },
	metadata			=> { type => 'hash' },
	owner				=> { fields => [qw( address.city address.country address.line1 address.line2 address.postal_code address.state email name phone )] },
	source_order		=> { fields => [qw( items.amount items.currency items.description items.parent items.quantity items.type shipping.address.city shipping.address.country shipping.address.line1 shipping.address.line2 shipping.address.postal_code shipping.address.state shipping.carrier shipping.name shipping.phone shipping.tracking_number )] },
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No source id was provided to update source's details" ) );
	my $hash = $self->post( "sources/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Payment::Source', $hash ) );
}

sub subscription { return( shift->_response_to_object( 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub subscription_item { return( shift->_response_to_object( 'Net::API::Stripe::Billing::Subscription::Item', @_ ) ); }

sub subscriptions
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create delete_discount retrieve update list cancel )];
	my $meth = $self->_get_method( 'subscription', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

## https://stripe.com/docs/api/customers/delete?lang=curl
## "Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer."
sub subscription_cancel
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to cancel subscription information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription', @_ );
	my $okParams = 
	{
	expandable 	=> { allowed => $EXPANDABLES->{subscription} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No subscription id was provided to cancel." ) );
	my $hash = $self->delete( "subscriptions/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription', $hash ) );
}

sub subscription_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a subscription" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription', @_ );
	my $okParams = 
	{
	expandable 			=> { allowed => $EXPANDABLES->{subscription} },
	customer			=> { required => 1 },
	application_fee_percent => { re => qr/^[0-100]$/ },
	backdate_start_date	=> { type => 'datetime' },
	# billing_cycle_anchor => { re => qr/^\d+$/ },
	billing_cycle_anchor => { type => 'datetime' },
	billing_thresholds	=> { fields => [qw( amount_gte reset_billing_cycle_anchor )] },
	cancel_at			=> { type => 'datetime' },
	cancel_at_period_end	=> {},
	collection_method	=> { re => qr/^(?:charge_automatically|send_invoice)$/ },
	coupon				=> {},
	days_until_due		=> {},
	default_payment_method => {},
	default_source		=> {},
	default_tax_rates	=> { type => 'array' },
	items				=> { type => 'array', fields => [qw( plan billing_thresholds.usage_gte metadata quantity tax_rates )], required => 1 },
	metadata			=> { type => 'hash' },
	off_session			=> {},
	payment_behavior	=> { re => qr/^(?:allow_incomplete|error_if_incomplete)$/ },
	pending_invoice_item_interval => { fields => [qw( interval interval_count )] },
	prorate				=> {},
	proration_behavior	=> { type => 'string', re => qr/^(billing_cycle_anchor|create_prorations|none)$/ },
	tax_percent			=> { re => qr/^[0-100]$/ },
	trial_end			=> { re => qr/^(?:\d+|now)$/ },
	trial_from_plan		=> {},
	trial_period_days	=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	$self->message( 3, "Posting the following data: ", sub{ $self->dumper( $args ) } );
	my $hash = $self->post( 'subscriptions', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription', $hash ) );
}

sub subscription_delete_discount
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to delete subscription discount." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription', @_ );
	my $okParams = 
	{
	expandable => { allowed => $EXPANDABLES->{discount} },
	id => { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No subscription id was provided to delete its coupon." ) );
	my $hash = $self->delete( "subscriptions/${id}/discount", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Discount', $hash ) );
}

sub subscription_list
{
	my $self = shift( @_ );
	my $args = $self->_get_args( @_ );
	my $okParams = 
	{
	expandable 			=> { allowed => $EXPANDABLES->{subscription}, data_prefix_is_ok => 1 },
	# boolean
	active				=> { type => 'boolean' },
	'created' 			=> { re => qr/^\d+$/ },
	'created.gt'		=> { re => qr/^\d+$/ },
	'created.gte'		=> { re => qr/^\d+$/ },
	'created.lt'		=> { re => qr/^\d+$/ },
	'created.lte'		=> { re => qr/^\d+$/ },
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	'ending_before'		=> {},
	'ids'				=> { type => 'array' },
	'limit'				=> { re => qr/^\d+$/ },
	# boolean
	'shippable'			=> { type => 'boolean' },
	'starting_after'	=> {},
	# 'type'				=> {},
	# 'url'				=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( 'subscriptions', $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub subscription_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve subscription information." ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{subscription} },
	id 			=> { re => qr/^\w+$/, required => 1 }
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No subscription id was provided to retrieve its information." ) );
	my $hash = $self->get( "subscriptions/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription', $hash ) );
}

## https://stripe.com/docs/api/customers/update?lang=curl
sub subscription_update
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to update a subscription" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::Subscription', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{subscription} },
	id					=> { req => qr/^\w+$/, required => 1 },
	application_fee_percent => { re => qr/^[0-100]$/ },
	billing_cycle_anchor => { re => qr/^\d+$/ },
	billing_thresholds	=> { fields => [qw( amount_gte reset_billing_cycle_anchor )] },
	cancel_at			=> {},
	cancel_at_period_end => {},
	collection_method	=> { re => qr/^(?:charge_automatically|send_invoice)$/ },
	coupon				=> {},
	days_until_due		=> {},
	default_payment_method => { type => 'string', re => qr/^[\w\_]+$/ },
	default_source		=> {},
	default_tax_rates	=> {},
	items				=> { type => 'array', fields => [qw( id plan billing_thresholds.usage_gte clear_usage deleted metadata quantity tax_rates )] },
	metadata 			=> { type => 'hash' },
	off_session			=> {},
	pause_collection	=> { type => 'string', fields => [qw(behavior resumes_at)] },
	payment_behavior	=> { re => qr/^(?:allow_incomplete|error_if_incomplete)$/ },
	pending_invoice_item_interval => { fields => [qw( interval interval_count )] },
	prorate				=> {},
	proration_date		=> { type => 'datetime' },
	tax_percent			=> { re => qr/^[0-100]$/ },
	trial_end			=> { re => qr/^(?:\d+|now)$/ },
	trial_from_plan		=> {},
	};
	## We found some errors
	my $err = $self->_check_parameters( $okParams, $args );
	# $self->message( 3, "Data to be posted: ", $self->dumper( $args ) ); exit;
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No subscription id was provided to update subscription's details" ) );
	my $hash = $self->post( "subscriptions/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::Subscription', $hash ) );
}

sub tax_id { return( shift->_response_to_object( 'Net::API::Stripe::Billing::TaxID', @_ ) ); }

sub tax_ids
{
	my $self = shift( @_ );
	my $action = shift( @_ );
	my $allowed = [qw( create retrieve delete list )];
	my $meth = $self->_get_method( 'tax_id', $action, $allowed ) || return;
	return( $self->$meth( @_ ) );
}

sub tax_id_create
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to create a tax_id" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::TaxID', @_ );
	my $okParams = 
	{
	expandable			=> { allowed => $EXPANDABLES->{tax_id} },
	customer			=> { re => qr/^\w+$/, required => 1 },
	## au_abn, ch_vat, eu_vat, in_gst, mx_rfc, no_vat, nz_gst, or za_vat
	type				=> { re => qr/^[a-z]{2}_[a-z]+$/ },
	value				=> {},
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{customer} ) || return( $self->error( "No customer id was provided to create a tax_id for the customer" ) );
	my $hash = $self->post( "customers/$id/tax_ids", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::TaxID', $hash ) );
}

sub tax_id_delete
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to delete a tax_id" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::TaxID', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{tax_id} },
	id			=> { re => qr/^\w+$/, required => 1 },
	customer	=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No tax id was provided to delete." ) );
	my $cust_id = CORE::delete( $args->{customer} ) || return( $self->error( "No customer id was provided to delete his/her tax_id" ) );
	my $hash = $self->delete( "customers/${cust_id}/tax_ids/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::TaxID', $hash ) );
}

sub tax_id_list
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to list customer's tax ids" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Customer', @_ );
	my $okParams = 
	{
	expandable		=> { allowed => $EXPANDABLES->{tax_id}, data_prefix_is_ok => 1 },
	id				=> { re => qr/^\w+$/, required => 1 },
	## "A cursor for use in pagination. ending_before is an object ID that defines your place in the list."
	ending_before	=> qr/^\w+$/,
	limit			=> qr/^\d+$/,
	starting_after	=> qr/^\w+$/,
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No customer id was provided to list his/her tax ids" ) );
	if( $args->{expand} )
	{
		$self->_adjust_list_expandables( $args ) || return;
	}
	my $hash = $self->get( "customers/${id}/tax_ids", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::List', $hash ) );
}

sub tax_id_retrieve
{
	my $self = shift( @_ );
	return( $self->error( "No parameters were provided to retrieve tax_id" ) ) if( !scalar( @_ ) );
	my $args = $self->_get_args_from_object( 'Net::API::Stripe::Billing::TaxID', @_ );
	my $okParams = 
	{
	expandable	=> { allowed => $EXPANDABLES->{tax_id} },
	id			=> { re => qr/^\w+$/, required => 1 },
	customer	=> { re => qr/^\w+$/, required => 1 },
	};
	my $err = $self->_check_parameters( $okParams, $args );
	return( $self->error( join( ' ', @$err ) ) ) if( scalar( @$err ) );
	my $id = CORE::delete( $args->{id} ) || return( $self->error( "No tax id was provided to retrieve customer's tax_id" ) );
	my $cust_id = CORE::delete( $args->{customer} ) || return( $self->error( "No customer id was provided to retrieve his/her tax_id" ) );
	my $hash = $self->get( "customers/${cust_id}/tax_ids/${id}", $args ) || return;
	return( $self->_response_to_object( 'Net::API::Stripe::Billing::TaxID', $hash ) );
}

sub tax_rate { return( shift->_response_to_object( 'Net::API::Stripe::Tax::Rate', @_ ) ); }

# sub terminal { return( shift->_instantiate( 'terminal', 'Net::API::Stripe::Terminal' ) ) }

sub token { return( shift->_response_to_object( 'Net::API::Stripe::Token', @_ ) ); }

sub topup { return( shift->_response_to_object( 'Net::API::Stripe::Connect::TopUp', @_ ) ); }

sub transfer { return( shift->_response_to_object( 'Net::API::Stripe::Connect::Transfer', @_ ) ); }

sub transfer_reversal { return( shift->_response_to_object( 'Net::API::Stripe::Connect::Transfer::Reversal', @_ ) ); }

sub usage_record { return( shift->_response_to_object( 'Net::API::Stripe::Billing::UsageRecord', @_ ) ); }

sub value_list { return( shift->_response_to_object( 'Net::API::Stripe::Fraud::ValueList', @_ ) ); }

sub value_list_item { return( shift->_response_to_object( 'Net::API::Stripe::Fraud::ValueList::Item', @_ ) ); }

sub version { return( shift->_set_get_scalar( 'version', @_ ) ); }

sub webhook { return( shift->_response_to_object( 'Net::API::Stripe::WebHook::Object' ) ) }

sub webhook_validate_signature
{
	my $self = shift( @_ );
	my $opts = {};
	$opts = shift( @_ ) if( @_ && ref( $_[0] ) eq 'HASH' );
	return( $self->error( "No webhook secret was provided." ) ) if( !$opts->{secret} );
	return( $self->error( "No Stripe signature was provided." ) ) if( !$opts->{signature} );
	return( $self->error( "No payload was provided." ) ) if( !CORE::length( $opts->{payload} ) );
	## 5 minutes
	$opts->{time_tolerance} ||= ( 5 * 60 );
	my $sig = $opts->{signature};
	my $max_time_spread = $opts->{time_tolerance};
	my $signing_secret = $opts->{secret};
	my $payload = $opts->{payload};
	$payload = Encode::decode_utf8( $payload ) if( !Encode::is_utf8( $payload ) );
	
	## Example:
	# Stripe-Signature: t=1492774577,
	#     v1=5257a869e7ecebeda32affa62cdca3fa51cad7e77a0e56ff536d0ce8e108d8bd,
	#     v0=6ffbb59b2300aae63f272406069a9788598b792a944a07aba816edb039989a39
	return( $self->error({ code => 400, message => "Event data received from Stripe is empty" }) ) if( !CORE::length( $sig ) );
	my @parts = split( /\,[[:blank:]]*/, $sig );
	$self->message( 3, "Signature parts are: '", join( "', '", @parts ), "'." );
	my $q = {};
	for( @parts )
	{
		my( $n, $v ) = split( /[[:blank:]]*\=[[:blank:]]*/, $_, 2 );
		$q->{ $n } = $v;
	}
	$self->message( 3, "Hash parameters are: ", sub{ $self->dumper( $q ) } );
	return( $self->error({ code => 400, message => "No timestamp found in Stripe event data" }) ) if( !CORE::exists( $q->{t} ) );
	return( $self->error({ code => 400, message => "Timestamp is empty in Stripe event data received." }) ) if( !CORE::length( $q->{t} ) );
	return( $self->error({ code => 400, message => "No signature found in Stripe event data" }) ) if( !CORE::exists( $q->{v1} ) );
	return( $self->error({ code => 400, message => "Signature is empty in Stripe event data received." }) ) if( !CORE::length( $q->{v1} ) );
	## Must be a unix timestamp
	return( $self->error({ code => 400, message => "Invalid timestamp received in Stripe event data" }) ) if( $q->{t} !~ /^\d+$/ );
	## Must be a hash hmac with sha256, e.g. 5257a869e7ecebeda32affa62cdca3fa51cad7e77a0e56ff536d0ce8e108d8bd
	return( $self->error({ code => 400, message => "Invalid signature received in Stripe event data" }) ) if( $q->{v1} !~ /^[a-z0-9]{64}$/ );
	my $dt;
	try
	{
		$dt = DateTime->from_epoch( epoch => $q->{t}, time_zone => 'local' );
	}
	catch( $e )
	{
		return( $self->error({ code => 400, message => "Invalid timestamp ($q->{t}): $e" }) );
	}
	
	## This needs to be in real utf8, ie NOT perl internal utf8
	my $signed_payload = Encode::encode_utf8( join( '.', $q->{t}, $payload ) );
	my $expect_sign = Digest::SHA::hmac_sha256_hex( $signed_payload, $signing_secret );
	$self->message( 3, "Expected signature is: $expect_sign" );
	$self->message( 3, "Signature ", ( $expect_sign ne $q->{v1} ? 'does not match' : 'matches' ) );
	return( $self->error({ code => 401, message => "Invalid signature." }) ) if( $expect_sign ne $q->{v1} );
	my $time_diff = time() - $q->{t};
	return( $self->error({ code => 400, message => "Bad timestamp ($q->{t}). It is set in the future: $dt" }) ) if( $time_diff < 0 );
	return( $self->error({ code => 406, message => "Timestamp is too old." }) ) if( $time_diff >= $max_time_spread );
	return( 1 );
}

## https://stripe.com/docs/ips
sub webhook_validate_caller_ip
{
	my $self = shift( @_ );
	my $opts = {};
	$opts = shift( @_ ) if( @_ && ref( $_[0] ) eq 'HASH' );
	return( $self->error({ code => 500, message => "No ip address was provided to check." }) ) if( !$opts->{ip} );
	my $err = [];
	my $ips = STRIPE_WEBHOOK_SOURCE_IP;
	my $ip = Net::IP->new( $opts->{ip} ) || do
	{
		warn( "Warning only: IP '$raw' is not valid: ", Net::IP->Error, "\n" );
		push( @$err, sprintf( "IP '$raw' is not valid: %s", Net::IP->Error ) );
		return( '' );
	};
	$self->messagef( 3, "IP block provided has %d IP addresses, starts with %s and ends with %s", $ip->size, $ip->ip, $ip->last_ip );
	foreach my $stripe_ip ( @$ips )
	{
		my $stripe_ip_object = Net::IP->new( $stripe_ip );
		## We found an existing ip same as the one we are adding, so we skip
		## If we are given a block that has some overlapping elements, we go ahead and add it
		## because it would become complicated and risky to only take the ips that do not overalp in the given block
		if( !( $ip->overlaps( $stripe_ip_object ) == $Net::IP::IP_NO_OVERLAP ) )
		{
			return( $ip );
		}
	}
	if( $opts->{ignore_ip} )
	{
		$self->message( 3, "This ip \"$ip\" does not match any of Stripe source ip and normally, this would return an error." );
		return( $ip );
	}
	else
	{
		return( $self->error({ code => Apache2::Const::HTTP_FORBIDDEN, message => "IP address $opts->{ip} is not a valid Stripe ip and is not authorised to access this resource." }) );
	}
}

## This is to be called for methods used to make api calls to Stripe to get list of objects
## And for which the user wants to expand some object's embedded objects
## See: https://stripe.com/docs/api/expanding_objects
## This allows the user to do simply default_source for customers' list when in reality
## the api requires data.default_source
sub _adjust_list_expandables
{
	my $self = shift( @_ );
	my $args = shift( @_ );
	return( $self->error( "User parameters list provided is '$args' and I was expecting a hash reference." ) ) if( ref( $args ) ne 'HASH' );
	if( ref( $args->{expand} ) eq 'ARRAY' )
	{
		my $new = [];
		for( my $i = 0; $i < scalar( @{$args->{expand}} ); $i++ )
		{
			substr( $args->{expand}->[$i], 0, 0 ) = 'data.' if( substr( $args->{expand}->[$i], 0, 5 ) ne 'data.' );
			my $path = [split( /\./, $args->{expand}->[$i] )];
			## Make sure that with the new 'data' prefix, this does not exceed 4 level of depth
			push( @$new, $args->{expand}->[$i] ) if( scalar( @$path ) <= $EXPAND_MAX_DEPTH );
		}
		$args->{expand} = $new;
	}
	return( $self );
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
	## Recursively transform into hash
	elsif( ref( $this ) eq 'HASH' )
	{
		## Prevent recursion
		my $ref_addr = Scalar::Util::refaddr( $this );
		$self->message( 3, "Skipping this hash with address $ref_addr that is looping." ) if( $opts->{seen}->{ $ref_addr } );
		return( $opts->{seen}->{ $ref_addr } ) if( $opts->{seen}->{ $ref_addr } );
		$opts->{seen}->{ $ref_addr } = $this;
		# $ref = $hash;
		foreach my $k ( keys( %$this ) )
		{
			if( ref( $this->{ $k } ) eq 'HASH' || $self->_is_object( $this->{ $k } ) )
			{
				$self->message( 3, "Calling _as_hash for item $this->{$k}" );
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
			## For stringification
			elsif( CORE::length( "$this->{$k}" ) )
			{
				$ref->{ $k } = $this->{ $k };
			}
		}
	}
	else
	{
		return( $self->error( "Unknown data type $this to be converted into hash for api call." ) );
	}
	return( $ref );
}

sub _check_parameters
{
	my $self = shift( @_ );
	my $okParams = shift( @_ );
	my $args   = shift( @_ );
	my $err = [];
	
	my $seen = {};
	local $check_fields_recursive = sub
	{
		my( $hash, $mirror, $field, $required ) = @_;
		my $errors = [];
		#	push( @$err, "Unknown property $v for key $k." ) if( !scalar( grep( /^$v$/, @$this ) ) );
		foreach my $k ( sort( keys( %$hash ) ) )
		{
			if( !CORE::exists( $mirror->{ $k } ) )
			{
				push( @$errors, "Unknown property \"$k\" for key \"$field\"." );
				next;
			}
			my $addr;
			$addr = Scalar::Util::refaddr( $hash->{ $k } ) if( ref( $hash->{ $k } ) eq 'HASH' );
			## Found a hash, check recursively and avoid looping endlessly
			if( ref( $hash->{ $k } ) eq 'HASH' && 
				ref( $mirror->{ $k } ) eq 'HASH' &&
				# ++$hash->{ $k }->{__check_fields_recursive_looping} == 1 )
				++$seen->{ $addr } == 1 )
			{
				my $deep_errors = $check_fields_recursive->( $hash->{ $k }, $mirror->{ $k }, $k, CORE::exists( $required->{ $k } ) ? $required->{ $k } : {} );
				CORE::push( @$errors, @$deep_errors );
			}
		}
		
		## Check required fields
		foreach my $k ( sort( keys( %$required ) ) )
		{
			if( !CORE::exists( $hash->{ $k } ) ||
				!CORE::length( $hash->{ $k } ) )
			{
				CORE::push( @$errors, "Field \"$k\" is required but missing in hash provided." );
			}
		}
		return( $errors );
	};
	
	foreach my $k ( keys( %$args ) )
	{
		## Special case for expand and for private parameters starting with '_'
		next if( $k eq 'expand' || $k eq 'expandable' || substr( $k, 0, 1 ) eq '_' );
		if( !CORE::exists( $okParams->{ $k } ) )
		{
			## This is handy when an object was passed to one of the api method and 
			## the object contains a bunch of data not all relevant to the api call
			## It makes it easy to pass the object and let this interface take only what is relevant
			if( $okParams->{_cleanup} || $args->{_cleanup} || $self->ignore_unknown_parameters )
			{
				CORE::delete( $args->{ $k } );
			}
			else
			{
				push( @$err, "Unknown parameter \"$k\"." );
			}
			next;
		}
		## $dict is either a hash dictionary or a sub
		my $dict = $okParams->{ $k };
		if( ref( $dict ) eq 'HASH' )
		{
		    my $pkg;
			if( $dict->{fields} && ref( $dict->{fields} ) eq 'ARRAY' )
			{
				my $this = $dict->{fields};
				if( ref( $args->{ $k } ) eq 'ARRAY' && $dict->{type} eq 'array' )
				{
					## Just saying it's ok
				}
				elsif( ref( $args->{ $k } ) ne 'HASH' )
				{
					push( @$err, sprintf( "Parameter \"$k\" must be a dictionary definition with following possible hash keys: \"%s\". Did you forget type => 'array' ?", join( ', ', @$this ) ) );
					next;
				}
				
				## We build a test mirror hash structure against which we will check if actual data fields exist or not
				my $mirror = {};
				my $required = {};
				foreach my $f ( @$this )
				{
					my @path = CORE::split( /\./, $f );
					my $parent_hash = $mirror;
					my $parent_req = $required;
					for( my $i = 0; $i < scalar( @path ); $i++ )
					{
						my $p = $path[$i];
						if( substr( $p, -1, 1 ) eq '!' )
						{
							$p = substr( $p, 0, CORE::length( $p ) - 1 );
							$parent_req->{ $p } = 1;
						}
						
						if( $i == $#path )
						{
							$parent_hash->{ $p } = 1;
						}
						else
						{
							$parent_hash->{ $p } = {} unless( CORE::exists( $parent_hash->{ $p } ) && ref( $parent_hash->{ $p } ) eq 'HASH' );
							if( CORE::exists( $parent_req->{ $p } ) )
							{
								$parent_req->{ $p } = {} unless( ref( $parent_req->{ $p } ) eq 'HASH' );
								$parent_req = $parent_req->{ $p };
							}
							$parent_hash = $parent_hash->{ $p };
						}
					}
				}
				
				## Do we have dots in field names? If so, this is a multi dimensional hash we are potentially looking at
				if( ref( $args->{ $k } ) eq 'HASH' )
				{
					my $res = $check_fields_recursive->( $args->{ $k }, $mirror, $k );
					push( @$err, @$res ) if( scalar( @$res ) );
				}
				elsif( ref( $args->{ $k } ) eq 'ARRAY' && $dict->{type} eq 'array' )
				{
					my $arr = $args->{ $k };
					for( my $i = 0; $i < scalar( @$arr ); $i++ )
					{
						if( ref( $arr->[ $i ] ) ne 'HASH' )
						{
							push( @$err, sprintf( "Invalid data type at offset $i. Parameter \"$k\" must be a dictionary definition with following possible hash keys: \"%s\"", join( ', ', @$this ) ) );
							next;
						}
						my $res = $check_fields_recursive->( $arr->[ $i ], $mirror, $k );
						push( @$err, @$res ) if( scalar( @$res ) );
					}
				}
				# $clean_up_check_fields_recursive->( $args->{ $k } );
			}
			if( $dict->{required} && !CORE::exists( $args->{ $k } ) )
			{
				push( @$err, "Parameter \"$k\" is required, but missing" );
			}
			## _is_object is inherited from Module::Object
			elsif( ( $pkg = $self->_is_object( $args->{ $k } ) ) && $dict->{package} && $dict->{package} ne $pkg )
			{
				push( @$err, "Parameter \"$k\" value is a package \"$pkg\", but I was expecting \"$dict->{package}\"" );
			}
			elsif( $dict->{re} && ref( $dict->{re} ) eq 'Regexp' && $args->{ $k } !~ /$dict->{re}/ )
			{
				push( @$err, "Parameter \"$k\" with value \"$args->{$k}\" does not have a legitimate value." );
			}
			elsif( $dict->{type} && 
				   ( 
				       ( $dict->{type} eq 'scalar' && ref( $args->{ $k } ) ) ||
				       ( $dict->{type} ne 'scalar' && ref( $args->{ $k } ) && lc( ref( $args->{ $k } ) ) ne $dict->{type} )
				   )
				 )
			{
				push( @$err, "I was expecting a data of type $dict->{type}, but got " . lc( ref( $args->{ $k } ) ) );
			}
			elsif( $dict->{type} eq 'boolean' && CORE::length( $args->{ $k } ) )
			{
				$args->{ $k } = ( $args->{ $k } eq 'true' || ( $args->{ $k } ne 'false' && $args-->{ $k } ) ) ? 'true' : 'false';
			}
			elsif( $dict->{type} eq 'date' || $dict->{type} eq 'datetime' )
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
		elsif( ref( $this ) eq 'CODE' )
		{
			my $res = $this->( $args->{ $k } );
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
			$self->message( 3, "Requested to expand all possible properties." );
			if( exists( $okParams->{expandable} ) && exists( $okParams->{expandable}->{allowed} ) && ref( $okParams->{expandable}->{allowed} ) eq 'ARRAY' )
			{
				$args->{expand} = $okParams->{expandable}->{allowed};
				$self->message( 3, "epxand now contains: ", sub{ $self->dump( $args->{expand} ) } );
			}
			## There is no allowed expandable properties, but it was called anyway, so we do this to avoid an error below
			else
			{
				$self->message( 3, "No possible properties to expand were found." );
				$args->{expand} = [];
			}
		}
		push( @$err, sprintf( "expand property should be an array, but instead '%s' was provided", $args->{expand} ) ) if( ref( $args->{expand} ) ne 'ARRAY' );
		if( scalar( @{$args->{expand}} ) && exists( $okParams->{expandable} ) )
		{
			return( $self->error( "expandable parameter is not a hash (", ref( $okParams->{expandable} ), ")." ) ) if( ref( $okParams->{expandable} ) ne 'HASH' );
			return( $self->error( "No \"allowed\" attribute in the expandable parameter hash." ) ) if( !CORE::exists( $okParams->{expandable}->{allowed} ) );
			my $expandable = $okParams->{expandable}->{allowed};
			my $errExpandables = [];
			if( !$no_need_to_check )
			{
				if( scalar( @$expandable ) )
				{
					$self->message( 3, "Checking expanded properties '", join( "', '", @{$args->{expand}} ), "' against expandable properties: '", join( "', '", @$expandable ), "'." );
					return( $self->error( "List of expandable attributes needs to be an array reference, but found instead a ", ref( $expandable ) ) ) if( ref( $expandable ) ne 'ARRAY' );
					## Return a list with the dot prefixed with backslash
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
					## Count the number of dots. Make sure this does not exceed the $EXPAND_MAX_DEPTH which is 4 as of today (2020-02-23)
					# my $this_depth = scalar( () = $args->{expand}->[$i] =~ /\./g );
					my $path_parts = [split( /\./, $args->{expand}->[$i] )];
					if( scalar( @$path_parts ) > $max_depth )
					{
						my $old = [CORE::splice( @$path_parts, $max_depth - 1 )];
						$args->{expand}->[$i] = $path_parts;
					}
				}
			}
			push( @$err, sprintf( "The following properties are not allowed to expand: %s", join( ', ', @$err ) ) ) if( scalar( @$errExpandables ) );
		}
		elsif( !exists( $okParams->{expandable} ) )
		{
			push( @$err, sprintf( "Following elements were provided to be expanded, but no expansion is supported: '%s'.", CORE::join( "', '", @{$args->{expand}} ) ) ) if( scalar( @{$args->{expand}} ) );
		}
	}
	else
	{
		$self->message( 3, "No expansion requested." );
	}
	my @private_params = grep( /^_/, keys( %$args ) );
	CORE::delete( @$args{ @private_params } );
	return( $err );
}

sub _check_required
{
	my $self = shift( @_ );
	my $required = shift( @_ );
	return( $self->error( "I was expecting an array reference of required field." ) ) if( ref( $required ) ne 'ARRAY' );
	my $args = shift( @_ );
	return( $self->error( "I was expecting an hash reference of parameters." ) ) if( ref( $args ) ne 'HASH' );
	my $err = [];
	foreach my $f ( @$required )
	{
		push( @$err, "Parameter $f is missing, and is required." ) if( !CORE::exists( $args->{ $f } ) || !CORE::length( $args->{ $f } ) );
	}
	return( $args );
}

sub _convert_boolean_for_json
{
	my $self = shift( @_ );
	my $hash = shift( @_ ) || return;
	my $seen = {};
	local $crawl = sub
	{
		my $this = shift( @_ );
		foreach my $k ( keys( %$this ) )
		{
			$self->message( 3, "Checking field '$k'." );
			if( ref( $this->{ $k } ) eq 'HASH' )
			{
				my $addr = Scalar::Util::refaddr( $this->{ $k } );
				next if( ++$seen->{ $addr } > 1 );
				$crawl->( $this->{ $k } );
			}
			elsif( $self->_is_object( $this->{ $k } ) && $this->{ $k }->isa( 'Module::Generic::Boolean' ) )
			{
				$self->message( 3, "Field is a Boolean object. COnverting to true or false" );
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
    	return( $self->json->utf8->allow_blessed->encode( $args ) );
    }
	local $encode = sub
	{
		my( $pref, $data ) = @_;
		my $type = lc( ref( $data ) );
		$self->message( 3, "prefix is '$pref' and data type is '$type' (value = '$data')." );
		my $comp = [];
		if( $type eq 'hash' )
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
		elsif( $type eq 'array' )
		{
			## According to Stripe's response to my mail inquiry of 2019-11-04 on how to structure array of hash in url encoded form data
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
		elsif( ref( $data ) eq 'SCALAR' && ( $$data == 1 || $$daata == 0 ) )
		{
			push( @$comp, sprintf( '%s=%s', $pref, $$data ? 'true' : 'false' ) );
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
			push( @$comp, sprintf( '%s=%s', $pref, URI::Escape::uri_escape_utf8( $data ) ) );
		}
		return( $comp );
	};
	my $res = $encode->( '', $args );
	return( join( '&', @$res ) );
}

sub _encode_params_multipart
{
	my $self = shift( @_ );
    my $args = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( scalar( @_ ) && ref( $_[-1] ) eq 'HASH' );
    local $set_value = sub
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
    
	local $encode = sub
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
				## This is a file
				elsif( ref( $data->{ $k } ) eq 'HASH' && 
					   CORE::exists( $data->{ $k }->{_filepath} ) )
				{
					return( $self->error( "File path argument is actually empty" ) ) if( !CORE::length( $data->{ $k }->{_filepath} ) );
					my $this_file = Cwd::abs_path( $data->{ $k }->{_filepath} );
					my $fname = File::Basename::fileparse( $this_file );
					$self->message( 3, "File path ", $data->{ $k }->{_filepath}, " becomes '$this_file' with flie name '$fname'." );
					if( !-e( $this_file ) )
					{
						$self->error( "File \"$this_file\" does not exist." );
						next;
					}
					elsif( !-r( $this_file ) )
					{
						$self->error( "File \"$this_file\" is not reaable." );
						next;
					}
					my $io = IO::File->new( "<$this_file" ) || do
					{
						$self->error( "Cannot open file \"$this_file\": $!" );
						next;
					};
					# $io->binmode;
					## my $binary = join( '', $io->getlines );
					my $binary = '';
					1 while( $io->read( $binary, 1024, CORE::length( $binary ) ) );
					$io->close;
					if( !CORE::length( $binary ) )
					{
						$self->error( "File data after reading file \"$this_file\" is empty!" );
						next;
					}
					my $mime_type = LWP::MediaTypes::guess_media_type( $this_file );
					$fname =~ s/([\\\"])/\\$1/g;
					$self->messagef( 3, "%d bytes of data found in this file '$fname' with mime type '$mime_type'." );
					$set_value->( "${pref}${ke}", $binary, $hash, { encoding => base64, filename => $fname, type => $mime_type } );
					next;
				}
				$encode->( ( $pref ? sprintf( '%s[%s]', $pref, $ke ) : $ke ), $data->{ $k }, $hash );
			}
		}
		elsif( $type eq 'array' )
		{
			## According to Stripe's response to my mail inquiry of 2019-11-04 on how to structure array of hash in url encoded form data
			for( my $i = 0; $i < scalar( @$data ); $i++ )
			{
				$encode->( ( $pref ? sprintf( '%s[%d]', $pref, $i ) : sprintf( '[%d]', $i ) ), $data->[$i], $hash );
			}
		}
		elsif( ref( $data ) eq 'JSON::PP::Boolean' || ref( $data ) eq 'Module::Generic::Boolean' )
		{
			$set_value->( $pref, $data ? 'true' : 'false', $hash, { type => 'text/plain' } );
		}
		elsif( ref( $data ) eq 'SCALAR' && ( $$data == 1 || $$daata == 0 ) )
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
	return( $result );
}

sub _get_args
{
	my $self = shift( @_ );
	return( {} ) if( !scalar( @_ ) || ( scalar( @_ ) == 1 && !defined( $_[0] ) ) );
	## Arg is one unique object
	return( $_[0] ) if( $self->_is_object( $_[0] ) );
	my $args = ref( $_[0] ) eq 'HASH' ? $_[0] : { @_ == 1 ? ( id => $_[0] ) : @_ };
	return( $args );
}

sub _get_args_from_object
{
	my $self  = shift( @_ );
	my $class = shift( @_ ) || return( $self->error( "No class was provided to get its information as parameters." ) );
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
	return( $args );
}

sub _get_method
{
	my $self = shift( @_ );
	my( $type, $action, $allowed ) = @_;
	return( $self->error( "No action was provided to get the associated method." ) ) if( !CORE::length( $action ) );
	return( $self->error( "Allowed method list provided is not an array reference." ) ) if( ref( $allowed ) ne 'ARRAY' );
	return( $self->error( "Allowed method list provided is empty." ) ) if( !scalar( @$allowed ) );
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
		return( $self->error( "Method $action is not authorised for $type" ) );
	}
	my $meth = $self->can( "${type}_${action}" );
	return( $self->error( "Method ${type}_${action} is not implemented in class '", ref( $self ), "'" ) ) if( !$meth );
	return( $meth );
}

sub _instantiate
{
	my $self = shift( @_ );
	my $name = shift( @_ );
	return( $self->{ $name } ) if( exists( $self->{ $name } ) && Scalar::Util::blessed( $self->{ $name } ) );
	my $class = shift( @_ );
	my $this;
	try
	{
		## https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
		# require $class unless( defined( *{"${class}::"} ) );
		my $rc = eval{ $self->_load_class( $class ) };
		return( $self->error( "Unable to load class $class: $@" ) ) if( $@ );
		$this  = $class->new(
			'debug'		=> $self->debug,
			'verbose'	=> $self->verbose,
		) || return( $self->pass_error( $class->error ) );
		$this->{parent} = $self;
	}
	catch( $e ) 
	{
		return( $self->error({ code => 500, message => $e }) );
	}
	return( $this );
}

sub _make_error 
{
	my $self  = shift( @_ );
	my $args  = shift( @_ );
    return( $self->error( $args ) );
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

        $resp = $self->http_client->request( $req );
        $self->{http_request} = $req;
        $self->{http_response} = $resp;
        ## if( $resp->code == 200 ) 
        if( $resp->is_success || $resp->is_redirect )
        {
        	$self->message( 3, "Request successful, decoding its content" );
            my $hash = $self->json->utf8->decode( $resp->decoded_content );
            $self->message( 3, "Returning $hash" );
            ## $ret = data_object( $hash );
            return( $hash );
        }
        else 
        {
        	$self->messagef( 3, "Request failed with error %s", $resp->message );
            if( $resp->header( 'Content_Type' ) =~ m{text/html} ) 
            {
                return( $self->_make_error({
                    code    => $resp->code,
                    type    => $resp->message,
                    message => $resp->message
                }) );
            }
            else 
            {
                my $hash = $self->json->utf8->decode( $resp->decoded_content );
                $self->message( 3, "Error returned by Stripe is: ", sub{ $self->dumper( $hash ) } );
                $self->message( 3, "Creating error from Stripe error $hash->{error}" );
                return( $self->_make_error( $hash->{error} // $hash ) );
            }
        }
    };
    if( $@ ) 
    {
		$self->message( 3, "Returning error $@" );
        return( $self->_make_error({
			'type' => "Could not decode HTTP response: $@", 
			$resp
				? ( 'message' => $resp->status_line . ' - ' . $resp->content )
				: (),
        }) );
    }
    ## return( $ret ) if( $ret );
    $self->message( 3, "Returning the result value '$ret'" );
    return( $ret );
}

sub _object_class_to_type
{
	my $self = shift( @_ );
	my $class = shift( @_ ) || return( $self->error( "No class was provided to find its associated type." ) );
	$class = ref( $class ) if( $self->_is_object( $class ) );
	my $ref  = $Net::API::Stripe::TYPE2CLASS;
	foreach my $c ( keys( %$ref ) )
	{
		return( $c ) if( $ref->{ $c } eq $class );
	}
	return;
}

sub _object_type_to_class
{
	my $self = shift( @_ );
	my $type = shift( @_ ) || return( $self->error( "No object type was provided" ) );
	my $ref  = $Net::API::Stripe::TYPE2CLASS;
	# $self->messagef( 3, "\$TYPE2CLASS has %d elements", scalar( keys( %$ref ) ) );
	return( $self->error( "No object type '$type' known to get its related class for field $self->{_field}" ) ) if( !exists( $ref->{ $type } ) );
	return( $ref->{ $type } );
}

sub _process_array_objects
{
	my $self = shift( @_ );
	my $class = shift( @_ );
	my $ref  = shift( @_ ) || return;
	return if( !ref( $ref ) || ref( $ref ) ne 'ARRAY' );
	for( my $i = 0; $i < scalar( @$ref ); $i++ )
	{
		my $hash = $ref->[$i];
		next if( ref( $hash ) ne 'HASH' );
		my $o = $class->new( %$hash );
		$ref->[$i] = $o;
	}
	return( $ref );
}

sub _response_to_object
{
	my $self  = shift( @_ );
	my $class = shift( @_ );
	return( $self->error( "No hash was provided" ) ) if( !scalar( @_ ) );
	my $hash  = $self->_get_args( @_ );
	## my $callbacks = $CALLBACKS->{ $class };
	## $self->message( "Found callbacks for $class: ", sub{ Dumper( $CALLBACKS ) } );
	## $self->messagef( "%d callbacks found for class $class", scalar( keys( %$callbacks ) ) );
	# $self->message( 3, "Called for class $class with hash $hash" );
	my $o;
	try
	{
		## https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
		# eval( "require $class;" ) unless( defined( *{"${class}::"} ) );
		my $rc = eval{ $self->_load_class( $class ) };
		return( $self->error( "An error occured while trying to load the module $class: $@" ) ) if( $@ );
		# $self->messagef( 3, "Creating an object of claass $class with %d elements inside.", scalar( keys( %$hash ) ) );
		$o = $class->new({
			'_parent' => $self,
			'_debug' => $self->{debug},
			'_dbh' => $self->{_dbh},
		}, $hash );
	}
	catch( $e )
	{
		return( $self->error( $e ) );
	}
	return( $self->pass_error( $class->error ) ) if( !defined( $o ) );
	# $self->message( 3, "Returning object $o for class $class" );
	# $self->message( 3, "Object $o structure is: ", $self->dumper( $o ) );
	return( $o );
}

# https://stripe.com/docs/api#errors
package Net::API::Stripe::Error;
BEGIN
{
	use strict;
	use parent -norequire, qw( Module::Generic::Exception );
	our( $VERSION ) = '0.1';
};

1;

__END__

