##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/CountrySpec/VerificationFields/Details.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::CountrySpec::VerificationFields::Details;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

sub additional { return( shift->_set_get_array( 'additional', @_ ) ); }

sub minimum { return( shift->_set_get_array( 'minimum', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::CountrySpec::VerificationFields::Details - A Stripe Verification Fields Details Object

=head1 SYNOPSIS

    my $details = $stripe->country_spec->verification_fields->company({
        additional => [qw( field1 field2 field3 )],
        minimum => [qw( field1 field2 field3 )]
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Lists the types of verification data needed to keep an account open.

This is instantiated by methods B<company> and B<individual> from module L<Net::API::Stripe::Connect::CountrySpec::VerificationFields>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::CountrySpec::VerificationFields::Details> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 additional array containing strings

Additional fields which are only required for some users.

=head2 minimum array containing strings

Fields which every account must eventually provide.

=head1 API SAMPLE

    {
      "id": "US",
      "object": "country_spec",
      "default_currency": "usd",
      "supported_bank_account_currencies": {
        "usd": [
          "US"
        ]
      },
      "supported_payment_currencies": [
        "usd",
        "aed",
        "afn",
        "..."
      ],
      "supported_payment_methods": [
        "ach",
        "card",
        "stripe"
      ],
      "supported_transfer_countries": [
        "US"
      ],
      "verification_fields": {
        "company": {
          "additional": [
            "relationship.representative"
          ],
          "minimum": [
            "business_profile.mcc",
            "business_profile.url",
            "business_type",
            "company.address.city",
            "company.address.line1",
            "company.address.postal_code",
            "company.address.state",
            "company.name",
            "company.phone",
            "company.tax_id",
            "external_account",
            "relationship.owner",
            "relationship.representative",
            "tos_acceptance.date",
            "tos_acceptance.ip"
          ]
        },
        "individual": {
          "additional": [
            "individual.id_number"
          ],
          "minimum": [
            "business_profile.mcc",
            "business_profile.url",
            "business_type",
            "external_account",
            "individual.address.city",
            "individual.address.line1",
            "individual.address.postal_code",
            "individual.address.state",
            "individual.dob.day",
            "individual.dob.month",
            "individual.dob.year",
            "individual.email",
            "individual.first_name",
            "individual.last_name",
            "individual.phone",
            "individual.ssn_last_4",
            "tos_acceptance.date",
            "tos_acceptance.ip"
          ]
        }
      }
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/country_specs/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
