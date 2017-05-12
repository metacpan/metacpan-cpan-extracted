#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Test::Requires 'MooseX::Types::URI', 'MooseX::Types::Email',
                   'Locale::Language', 'Locale::Currency',
                   'Number::Phone::US';

use Moose::Util::TypeConstraints;
use MooseX::Types::URI 'Uri';
use MooseX::Types::Email 'EmailAddress';

use MooseX::Validation::Doctypes;

subtype 'CurrencyCode',
    as 'Str',
    where { Locale::Currency::code2currency( $_ ) };
subtype 'LocaleCode',
    as 'Str',
    where { Locale::Language::code2language( $_ ) };
subtype 'PhoneNumber',
    as 'Str',
    where { Number::Phone::US::is_valid_number( $_ ) };

doctype 'Location' => {
    id       => 'Str',
    name     => 'Str',
    location => {
        address => {
            address1    => 'Str',
            city        => 'Str',
            country     => 'Str',
            postal_code => 'Str',
            address2    => 'Maybe[Str]',
            address3    => 'Maybe[Str]',
            address4    => 'Maybe[Str]',
            address5    => 'Maybe[Str]',
            state       => 'Maybe[Str]',
        },
        coordinates => {
            lon => 'Num',
            lat => 'Num',
        }
    },
    contact => {
        phone   => 'PhoneNumber',
        fax     => 'Maybe[PhoneNumber]',
        support => 'Maybe[PhoneNumber | MooseX::Types::URI::Uri | MooseX::Types::Email::EmailAddress]',
        web     => 'Maybe[MooseX::Types::URI::Uri]',
        email   => 'Maybe[MooseX::Types::Email::EmailAddress]',
    },
    i18n => {
        default_currency     => 'CurrencyCode',
        default_locale       => 'LocaleCode',
        available_currencies => 'ArrayRef[CurrencyCode]',
        available_locales    => 'ArrayRef[LocaleCode]',
    }
};

{
    my $location = find_type_constraint('Location');
    is_deeply(
        $location->doctype,
        {
            id       => 'Str',
            name     => 'Str',
            location => {
                address => {
                    address1    => 'Str',
                    city        => 'Str',
                    country     => 'Str',
                    postal_code => 'Str',
                    address2    => 'Maybe[Str]',
                    address3    => 'Maybe[Str]',
                    address4    => 'Maybe[Str]',
                    address5    => 'Maybe[Str]',
                    state       => 'Maybe[Str]',
                },
                coordinates => {
                    lon => 'Num',
                    lat => 'Num',
                }
            },
            contact => {
                phone   => 'PhoneNumber',
                fax     => 'Maybe[PhoneNumber]',
                support => 'Maybe[PhoneNumber | MooseX::Types::URI::Uri | MooseX::Types::Email::EmailAddress]',
                web     => 'Maybe[MooseX::Types::URI::Uri]',
                email   => 'Maybe[MooseX::Types::Email::EmailAddress]',
            },
            i18n => {
                default_currency     => 'CurrencyCode',
                default_locale       => 'LocaleCode',
                available_currencies => 'ArrayRef[CurrencyCode]',
                available_locales    => 'ArrayRef[LocaleCode]',
            }
        },
        "got the right doctype"
    );

    {
        my $errors = $location->validate({
            id       => '14931-FL-53',
            name     => 'My House',
            location => {
                address => {
                    address1    => '123 Any St',
                    city        => 'Anytown',
                    country     => 'USA',
                    postal_code => '00100',
                    address2    => 'Apt Q',
                    address5    => 'knock on the back door',
                    state       => 'IL',
                },
                coordinates => {
                    lon => '38',
                    lat => '57',
                }
            },
            contact => {
                phone   => '867-5309',
                support => 'anelson@cpan.org',
                web     => URI->new('https://metacpan.org/author/ANELSON'),
                email   => 'anelson@cpan.org',
            },
            i18n => {
                default_currency     => 'USD',
                default_locale       => 'en',
                available_currencies => [ 'USD', 'CAD', 'EUR' ],
                available_locales    => [ 'en' ]
            }
        });
        is($errors, undef, "no errors");
    }

    {
        my $errors = $location->validate({
            id       => '14931-FL-53',
            name     => 'My House',
            location => {
                address => {
                    address1    => '123 Any St',
                    city        => 'Anytown',
                    country     => 'USA',
                    postal_code => '00100',
                    address2    => 'Apt Q',
                    address5    => 'knock on the back door',
                    state       => 'IL',
                },
                coordinates => {
                    lon => '38q',
                    lat => '57',
                }
            },
            contact => {
                phone   => '867-5309',
                support => 'anelson@cpan.org',
                web     => URI->new('https://metacpan.org/author/ANELSON'),
                email   => 'anelson at cpan.org',
            },
            i18n => {
                default_locale       => 'en',
                available_currencies => [ 'dolla dolla bill', 'CAD', 'EUR' ],
                available_locales    => [ 'en' ]
            }
        });
        is_deeply(
            $errors->errors,
            {
                contact => {
                    email => "invalid value \"anelson at cpan.org\" for 'contact.email'"
                },
                i18n => {
                    available_currencies => "invalid value [ \"dolla dolla bill\", \"CAD\", \"EUR\" ] for 'i18n.available_currencies'",
                    default_currency => "invalid value undef for 'i18n.default_currency'"
                },
                location => {
                    coordinates => {
                        lon => "invalid value \"38q\" for 'location.coordinates.lon'"
                    }
                }
            },
            "got the right errors"
        );
        ok(!$errors->has_extra_data, "no extra data");
    }

    {
        my $errors = $location->validate({
            id       => '14931-FL-53',
            name     => 'My House',
            contact => {
                phone   => '867-5309',
                support => 'anelson@cpan.org',
                web     => URI->new('https://metacpan.org/author/ANELSON'),
                email   => 'anelson@cpan.org',
            },
            i18n => {
                default_currency     => 'USD',
                default_locale       => 'en',
                available_currencies => [ 'CAD', 'EUR' ],
                available_locales    => [ 'en' ]
            }
        });
        is_deeply(
            $errors->errors,
            {
                location => "invalid value undef for 'location'",
            },
            "got the right errors"
        );
        ok(!$errors->has_extra_data, "no extra data");
    }
}

done_testing;
