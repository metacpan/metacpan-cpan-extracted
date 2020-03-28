##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/account/object
package Net::API::Stripe::Connect::Account;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

## Moved as of 2019-02-19
# sub business_logo { shift->_set_get_scalar_or_object( 'business_logo', 'Net::API::Stripe::File', @_ ); }
# Thanks to Module::Generic _set_get_object feature, even if settings is not set this will not crash
sub business_logo { return( shift->settings->branding->icon( @_ ) ); }

## Moved as of 2019-02-19
## sub business_logo_large { shift->_set_get_scalar( 'business_logo_large', @_ ); }
sub business_logo_large { return( shift->settings->branding->logo( @_ ) ); }

## Moved as of 2019-02-19
## sub business_name { shift->_set_get_scalar( 'business_name', @_ ); }
sub business_name { return( shift->business_profile->name( @_ ) ); }

## Moved as of 2019-02-19
## sub business_primary_color { shift->_set_get_scalar( 'business_primary_color', @_ ); }
sub business_primary_color { return( shift->settings->branding->primary_color( @_ ) ); }

sub business_profile { return( shift->_set_get_object( 'business_profile', 'Net::API::Stripe::Connect::Business::Profile', @_ ) ); }

sub business_type { return( shift->_set_get_scalar( 'business_type', @_ ) ); }

## Moved as of 2019-02-19
## sub business_url { shift->_set_get_uri( 'business_url', @_ ); }
sub business_url { return( shift->business_profile->url( @_ ) ); }

## This is a fake module (Net::API::Stripe::Connect::Account::Capabilities), but will allow the user to call the property as method of that module
sub capabilities { return( shift->_set_get_hash_as_object( 'capabilities', 'Net::API::Stripe::Connect::Account::Capabilities', @_ ) ); }

sub charges_enabled { shift->_set_get_boolean( 'charges_enabled', @_ ); }

sub company { return( shift->_set_get_object( 'company', 'Net::API::Stripe::Connect::Account::Company', @_ ) ); }

sub country { shift->_set_get_scalar( 'country', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

## Moved as of 2019-02-19
# sub debit_negative_balances { shift->_set_get_scalar( 'debit_negative_balances', @_ ); }
sub debit_negative_balances { return( shift->settings->payouts->debit_negative_balances( @_ ) ); }

## Moved as of 2019-02-19
# sub decline_charge_on { shift->_set_get_object( 'decline_charge_on', 'Net::API::Stripe::Connect::Account::DeclineChargeOn', @_ ); }
sub decline_charge_on { return( shift->settings->card_payments->decline_on( @_ ) ); }

sub default_currency { shift->_set_get_scalar( 'default_currency', @_ ); }

sub details_submitted { shift->_set_get_boolean( 'details_submitted', @_ ); }

## Moved as of 2019-02-19
## sub display_name { shift->_set_get_scalar( 'display_name', @_ ); }
sub display_name { return( shift->settings->dashboard->display_name( @_ ) ); }

sub email { shift->_set_get_scalar( 'email', @_ ); }

sub external_accounts { shift->_set_get_object( 'external_accounts', 'Net::API::Stripe::Connect::Account::ExternalAccounts', @_ ); }

sub individual { return( shift->_set_get_object( 'individual', 'Net::API::Stripe::Connect::Person', @_ ) ); }

sub legal_entity { shift->_set_get_object( 'legal_entity', 'Net::API::Stripe::Connect::Account::LegalEntity', @_ ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub payouts_enabled { shift->_set_get_boolean( 'payouts_enabled', @_ ); }

## Moved as of 2019-02-19
## sub payout_schedule { shift->_set_get_object( 'payout_schedule', 'Net::API::Stripe::Connect::Account::PaymentSchedule', @_ ); }
sub payout_schedule { return( shift->settings->payouts->schedule( @_ ) ); }

## Moved as of 2019-02-19
## sub payout_statement_descriptor { shift->_set_get_scalar( 'payout_statement_descriptor', @_ ); }
sub payout_statement_descriptor { return( shift->settings->payouts->statement_descriptor( @_ ) ); }

## Moved as of 2019-02-19
## sub product_description { shift->_set_get_scalar( 'product_description', @_ ); }
sub product_description { return( shift->business_profile->product_description( @_ ) ); }

sub requirements { return( shift->_set_get_object( 'requirements', 'Net::API::Stripe::Connect::Account::Requirements', @_ ) ); }

sub settings { return( shift->_set_get_object( 'settings', 'Net::API::Stripe::Connect::Account::Settings', @_ ) ); }

## Moved as of 2019-02-19
## sub statement_descriptor { shift->_set_get_scalar( 'statement_descriptor', @_ ); }
sub statement_descriptor { return( shift->settings->payments->statement_descriptor( @_ ) ); }

## Moved as of 2019-02-19
## sub support_address { shift->_set_get_object( 'support_address', 'Net::API::Stripe::Address', @_ ); }
sub support_address { return( shift->business_profile->support_address( @_ ) ); }

## Moved as of 2019-02-19
## sub support_email { shift->_set_get_scalar( 'support_email', @_ ); }
sub support_email { return( shift->business_profile->support_email( @_ ) ); }

## Moved as of 2019-02-19
## sub support_phone { shift->_set_get_scalar( 'support_phone', @_ ); }
sub support_phone { return( shift->business_profile->support_phone( @_ ) ); }

## Moved as of 2019-02-19
## sub support_url { shift->_set_get_uri( 'support_url', @_ ); }
sub support_url { return( shift->business_profile->support_url( @_ ) ); }

## Moved as of 2019-02-19
## sub timezone { shift->_set_get_scalar( 'timezone', @_ ); }
sub timezone { return( shift->settings->dashboard->timezone( @_ ) ); }

sub tos_acceptance { shift->_set_get_object( 'tos_acceptance', 'Net::API::Stripe::Connect::Account::TosAcceptance', @_ ); }

## standard, express, or custom
sub type { shift->_set_get_scalar( 'type', @_ ); }

## Not used anymore as of 2019-02-19
sub verification { shift->_set_get_object( 'verification', 'Net::API::Stripe::Connect::Account::Verification', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account - A Stripe Account Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is an object representing a Stripe account. You can retrieve it to see properties on the account like its current e-mail address or if the account is enabled yet to make live charges.

Some properties, marked below, are available only to platforms that want to create and manage Express or Custom accounts (L<https://stripe.com/docs/connect/accounts>).

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new C<Net::API::Stripe> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<verbose>

Toggles verbose mode on/off

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "account"

String representing the object’s type. Objects of the same type share the same value.

=item B<business_logo>

This is outdated. It now points to B<business_profile>->B<icon>

=item B<business_logo_large>

This is outdated. It now points to B<business_profile>->B<logo>

=item B<business_name>

This is outdated. It now points to B<business_name>->B<name>

=item B<business_primary_color>

This is outdated. It now points to B<settings>->B<primary_color>

=item B<business_profile> hash

Optional information related to the business.

This is a C<Net::API::Stripe::Business::Profile> object.

=item B<business_type> string

The business type. Can be individual or company.

=item B<business_url>

This is outdated. It now points to B<business_profile>->B<url>

=item B<capabilities> hash

A hash containing the set of capabilities that was requested for this account and their associated states. Keys are names of capabilities. You can see the full list here (L<https://stripe.com/docs/api/capabilities/list>). Values may be active, inactive, or pending.

This is a C<Net::API::Stripe::Connect::Account::Capabilities> object, although there is no real C<Net::API::Stripe::Connect::Account::Capability> module. This is created on the fly by the B<_set_get_hash_as_object> method of C<Module::Generic>

=over 8

=item B<card_issuing> string

The status of the card issuing capability of the account, or whether you can use Issuing to distribute funds on cards

=item B<card_payments> string

The status of the card payments capability of the account, or whether the account can directly process credit and debit card charges.

=item B<legacy_payments> string

The status of the legacy payments capability of the account.

=item B<transfers> string

The status of the transfers capability of the account, or whether your platform can transfer funds to the account.

=back

=item B<charges_enabled> boolean

Whether the account can create live charges.

=item B<company> custom only hash

Information about the company or business. This field is null unless business_type is set to company.

This is a C<Net::API::Stripe::Connect::Account::Company> object.

=item B<country> string

The account’s country.

=item B<created> custom and express timestamp

Time at which the object was created. Measured in seconds since the Unix epoch. This is a C<DateTime> object.

=item B<debit_negative_balances>

This is outdated. It now points to B<settings>->B<payouts>->B<debit_negative_balances>

=item B<decline_charge_on>

This is outdated. It now points to B<settings>->B<card_payments>->B<decline_on>

=item B<default_currency> string

Three-letter ISO currency code representing the default currency for the account. This must be a currency that Stripe supports in the account’s country.

=item B<details_submitted> boolean

Whether account details have been submitted. Standard accounts cannot receive payouts before this is true.

=item B<display_name>

This is outdated. It now points to B<settings>->B<dashboard>->B<display_name>

=item B<email> string

The primary user’s email address.

=item B<external_accounts> custom and express list

External accounts (bank accounts and debit cards) currently attached to this account

This is a C<Net::API::Stripe::Connect::Account::ExternalAccounts> object.

=item B<individual> custom only hash

Information about the person represented by the account. This field is null unless business_type is set to individual.

This is a C<Net::API::Stripe::Connect::Person> object.

=item B<legal_entity>

This is outdated. Stripe now uses a C<Net::API::Stripe::Connect::Account::Company> object and a C<Net::API::Stripe::Connect::Person> object.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<payouts_enabled> boolean

Whether Stripe can send payouts to this account.

=item B<payout_schedule>

This is outdated. It now points to B<settings>->B<payouts>->B<schedule>

=item B<payout_statement_descriptor>

This is outdated. It now points to B<settings>->B<payouts>->B<statement_descriptor>

=item B<product_description>

This is outdated. It now points to B<business_profile>->B<product_description>

=item B<requirements> custom and express hash

Information about the requirements for the account, including what information needs to be collected, and by when.

This is a C<Net::API::Stripe::Connect::Account::Requirements> object.

=item B<settings> hash

Options for customizing how the account functions within Stripe.

This is a C<Net::API::Stripe::Connect::Account::Settings> object.

=item B<statement_descriptor>

This is outdated. It now points to B<settings>->B<payments>->B<statement_descriptor>

=item B<support_address>

This is outdated. It now points to B<business_profile>->B<support_address>

=item B<support_email>

This is outdated. It now points to B<business_profile>->B<support_email>

=item B<support_phone>

This is outdated. It now points to B<business_profile>->B<support_phone>

=item B<support_url>

This is outdated. It now points to B<business_profile>->B<support_url>

=item B<timezone>

This is outdated. It is a C<DateTime> object.

=item B<tos_acceptance> custom only hash

Details on the acceptance of the Stripe Services Agreement

This is a C<Net::API::Stripe::Connect::Account::TosAcceptance> object.

=item B<type> string

The Stripe account type. Can be standard, express, or custom.

=item B<verification>

This is outdated. It is a C<Net::API::Stripe::Connect::Account::Verification> object.

=back

=head1 API SAMPLE

=head2 Response Standard

	{
	  "id": "acct_19eGgRCeyNCl6xYZ",
	  "object": "account",
	  "business_profile": {
		"mcc": null,
		"name": "My Shop, Inc",
		"product_description": "Great products shipping all over the world",
		"support_address": {
		  "city": "Tokyo",
		  "country": "JP",
		  "line1": "1-2-3 Kudan-minami, Chiyoda-ku",
		  "line2": "",
		  "postal_code": "100-0012",
		  "state": ""
		},
		"support_email": "billing@example.com",
		"support_phone": "+81312345678",
		"support_url": "",
		"url": "https://www.example.com"
	  },
	  "business_type": "company",
	  "capabilities": {
		"card_payments": "active"
	  },
	  "charges_enabled": true,
	  "country": "JP",
	  "default_currency": "jpy",
	  "details_submitted": true,
	  "email": "tech@example.com",
	  "metadata": {},
	  "payouts_enabled": true,
	  "settings": {
		"branding": {
		  "icon": "file_1DLf5rCeyNCl6fY2kS4e5hMT",
		  "logo": null,
		  "primary_color": "#0e77ca"
		},
		"card_payments": {
		  "decline_on": {
			"avs_failure": false,
			"cvc_failure": false
		  },
		  "statement_descriptor_prefix": null
		},
		"dashboard": {
		  "display_name": "myshop-inc",
		  "timezone": "Asia/Tokyo"
		},
		"payments": {
		  "statement_descriptor": "MYSHOP, INC",
		  "statement_descriptor_kana": "ﾏｲｼｮｯﾌﾟｲﾝｸ",
		  "statement_descriptor_kanji": "マイショップインク"
		},
		"payouts": {
		  "debit_negative_balances": true,
		  "schedule": {
			"delay_days": 4,
			"interval": "weekly",
			"weekly_anchor": "thursday"
		  },
		  "statement_descriptor": null
		}
	  },
	  "type": "standard"
	}

=head2 Response Express

	{
	  "id": "acct_19eGgRCeyNCl6xYZ",
	  "object": "account",
	  "business_profile": {
		"mcc": null,
		"name": "MyShop, Inc",
		"product_description": "Great products shipping all over the world",
		"support_address": {
		  "city": "Tokyo",
		  "country": "JP",
		  "line1": "1-2-3 Kudan-minami, Chiyoda-ku",
		  "line2": "",
		  "postal_code": "100-0012",
		  "state": ""
		},
		"support_email": "billing@example.com",
		"support_phone": "+81312345678",
		"support_url": "",
		"url": "https://www.example.com"
	  },
	  "business_type": "company",
	  "capabilities": {
		"card_payments": "active"
	  },
	  "charges_enabled": true,
	  "country": "JP",
	  "created": 1484973659,
	  "default_currency": "jpy",
	  "details_submitted": true,
	  "email": "tech@example.com",
	  "external_accounts": {
		"object": "list",
		"data": [
		  {
			"id": "ba_19eGy1CeyNCl6fY2R3ACmqG4",
			"object": "bank_account",
			"account": "acct_19eGgRCeyNCl6xYZ",
			"account_holder_name": "カ）マイショップインク",
			"account_holder_type": null,
			"bank_name": "三井住友銀行",
			"country": "JP",
			"currency": "jpy",
			"default_for_currency": true,
			"fingerprint": "VWINqgzE0zu5x1ab",
			"last4": "1234",
			"metadata": {},
			"routing_number": "0009218",
			"status": "new"
		  }
		],
		"has_more": false,
		"url": "/v1/accounts/acct_19eGgRCeyNCl6xYZ/external_accounts"
	  },
	  "metadata": {},
	  "payouts_enabled": true,
	  "requirements": {
		"current_deadline": null,
		"currently_due": [],
		"disabled_reason": null,
		"eventually_due": [],
		"past_due": [],
		"pending_verification": []
	  },
	  "settings": {
		"branding": {
		  "icon": "file_1DLf5rCeyNCl6fY2kS4e1xyz",
		  "logo": null,
		  "primary_color": "#0e77ca"
		},
		"card_payments": {
		  "decline_on": {
			"avs_failure": false,
			"cvc_failure": false
		  },
		  "statement_descriptor_prefix": null
		},
		"dashboard": {
		  "display_name": "myshop-inc",
		  "timezone": "Asia/Tokyo"
		},
		"payments": {
		  "statement_descriptor": "MYSHOP, INC",
		  "statement_descriptor_kana": "ﾏｲｼｮｯﾌﾟｲﾝｸ",
		  "statement_descriptor_kanji": "マイショップインク"
		},
		"payouts": {
		  "debit_negative_balances": true,
		  "schedule": {
			"delay_days": 4,
			"interval": "weekly",
			"weekly_anchor": "thursday"
		  },
		  "statement_descriptor": null
		}
	  },
	  "type": "express"
	}

=head2 Response Custom

	{
	  "id": "acct_19eGgRCeyNCl6xYZ",
	  "object": "account",
	  "business_profile": {
		"mcc": null,
		"name": "MyShop, Inc",
		"product_description": "Great products shipping all over the world",
		"support_address": {
		  "city": "Tokyo",
		  "country": "JP",
		  "line1": "1-2-3 Kudan-minami, Chiyoda-ku",
		  "line2": "",
		  "postal_code": "100-0012",
		  "state": ""
		},
		"support_email": "billing@example.com",
		"support_phone": "+81312345678",
		"support_url": "",
		"url": "https://www.example.com"
	  },
	  "business_type": "company",
	  "capabilities": {
		"card_payments": "active"
	  },
	  "charges_enabled": true,
	  "company": {
		"address_kana": {
		  "city": "ﾁﾖﾀﾞｸ",
		  "country": "JP",
		  "line1": "2-3",
		  "line2": "ﾅｼ",
		  "postal_code": null,
		  "state": null,
		  "town": "ｸﾀﾞﾝﾐﾅﾐ1"
		},
		"address_kanji": {
		  "city": "千代田区",
		  "country": "JP",
		  "line1": "",
		  "line2": "",
		  "postal_code": null,
		  "state": null,
		  "town": "九段南1-2-3"
		},
		"directors_provided": false,
		"name": "MyShop, Inc",
		"name_kana": "ｶﾌﾞｼｷｶｲｼｬﾏｲｼｮｯﾌﾟｲﾝｸ",
		"name_kanji": "株式会社マイショップインク",
		"owners_provided": true,
		"phone": null,
		"tax_id_provided": true,
		"verification": {
		  "document": {
			"back": null,
			"details": null,
			"details_code": null,
			"front": null
		  }
		}
	  },
	  "country": "JP",
	  "created": 1484973659,
	  "default_currency": "jpy",
	  "details_submitted": true,
	  "email": "tech@example.com",
	  "external_accounts": {
		"object": "list",
		"data": [
		  {
			"id": "ba_19eGy1CeyNCl6fY2R3ACmqG4",
			"object": "bank_account",
			"account": "acct_19eGgRCeyNCl6xYZ",
			"account_holder_name": "カ）マイショップインク",
			"account_holder_type": null,
			"bank_name": "三井住友銀行",
			"country": "JP",
			"currency": "jpy",
			"default_for_currency": true,
			"fingerprint": "VkINqgzE0zu5x1xw",
			"last4": "2235",
			"metadata": {},
			"routing_number": "0009218",
			"status": "new"
		  }
		],
		"has_more": false,
		"url": "/v1/accounts/acct_19eGgRCeyNCl6xYZ/external_accounts"
	  },
	  "metadata": {},
	  "payouts_enabled": true,
	  "requirements": {
		"current_deadline": null,
		"currently_due": [],
		"disabled_reason": null,
		"eventually_due": [],
		"past_due": [],
		"pending_verification": []
	  },
	  "settings": {
		"branding": {
		  "icon": "file_1DLf5rCeyabl6fY2kS4e5xyz",
		  "logo": null,
		  "primary_color": "#0e77ca"
		},
		"card_payments": {
		  "decline_on": {
			"avs_failure": false,
			"cvc_failure": false
		  },
		  "statement_descriptor_prefix": null
		},
		"dashboard": {
		  "display_name": "myshop-inc",
		  "timezone": "Asia/Tokyo"
		},
		"payments": {
		  "statement_descriptor": "MYSHOP, IN",
		  "statement_descriptor_kana": "ﾏｲｼｮｯﾌﾟｲﾝｸ",
		  "statement_descriptor_kanji": "マイショップインク"
		},
		"payouts": {
		  "debit_negative_balances": true,
		  "schedule": {
			"delay_days": 4,
			"interval": "weekly",
			"weekly_anchor": "thursday"
		  },
		  "statement_descriptor": null
		}
	  },
	  "tos_acceptance": {
		"date": 1484979187,
		"ip": "114.17.230.189",
		"user_agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
	  },
	  "type": "custom"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2019-02-19

Statement descriptor behaviors for card payments created via /v1/charges have changed. See our statement descriptor guide for details.

=over 4

=item * Instead of using the platform's statement descriptor, charges created with on_behalf_of or destination will now use the descriptor of the connected account.

~item * The full statement descriptor for a card payment may no longer be provided at charge creation. Dynamic descriptors provided at charge time will now be prefixed by the descriptor prefix set in the dashboard or via the new settings[card_payments][statement_descriptor_prefix] parameter in the Accounts API.

=item * If an account has no statement_descriptor set, the account's business or legal name will be used as statement descriptor.

=item * Statement descriptors may no longer contain *, ', and ".

=head2 2019-02-19

Many properties on the Account API object have been reworked. To see a mapping of the old argument names to the new ones, see Accounts API Argument Changes.

=over 4

=item * The legal_entity property on the Account API resource has been replaced with individual, company, and business_type.

=item * The verification hash has been replaced with a requirements hash.

=over 8

=item * The verification[fields_needed] array has been replaced with three arrays to better represent when info is required: requirements[eventually_due], requirements[currently_due], and requirements[past_due].

=item * verification[due_by] has been renamed to requirements[current_deadline].

=item * The disabled_reason enum value of fields_needed has been renamed to requirements.past_due.

=back

=item * Properties on the Account API object that configure behavior within Stripe have been moved into the new settings hash.

=over 8

=item * The payout_schedule, payout_statement_descriptor and debit_negative_balances fields have been moved to settings[payouts] and renamed to schedule, statement_descriptor and debit_negative_balances.

=item * The statement_descriptor field has been moved to settings[payments][statement_descriptor].

=item * The decline_charge_on fields have been moved to settings[card_payments] and renamed to decline_on.

=item * The business_logo, business_logo_large and business_primary_color fields have been moved to settings[branding] and renamed to icon, logo and primary_color. The icon field additionally requires the uploaded image file to be square.

=item * The display_name and timezone fields have been moved to settings[dashboard].

=back

=item * business_name, business_url, product_description, support_address, support_email, support_phone and support_url have been moved to the business_profile subhash.

=item * The legal_entity[verification][document] property (now located at individual[verification] and at verification in the Person API object) has been changed to a hash.

=over 8

=item * The front and back fields support uploading both sides of documents.

=item * The details_code field has new error types: document_corrupt, document_failed_copy, document_failed_greyscale, document_failed_other, document_failed_test_mode, document_fraudulent, document_id_country_not_supported, document_id_type_not_supported, document_invalid, document_manipulated, document_missing_back, document_missing_front, document_not_readable, document_not_uploaded, document_photo_mismatch, and document_too_large.

=item * The keys property on Account creation has been removed. Platforms should now authenticate as their connected accounts with their own key via the Stripe-Account header.

=item * Starting with the 2019-02-19 API, the requested_capabilities property is now required at creation time for accounts in the U.S. See the Capabilities Overview for more information.

=back

=back

=head2 2017-05-25

Replaces the managed Boolean property on Account objects with type, whose possible values are: standard, express, and custom. A managed value is required when creating accounts.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
