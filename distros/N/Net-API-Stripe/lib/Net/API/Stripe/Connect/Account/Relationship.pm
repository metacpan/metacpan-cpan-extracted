##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Relationship.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::Relationship;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

sub director { return( shift->_set_get_boolean( 'director', @_ ) ); }

sub executive { return( shift->_set_get_boolean( 'executive', @_ ) ); }

sub owner { return( shift->_set_get_boolean( 'owner', @_ ) ); }

sub percent_ownership { return( shift->_set_get_number( 'percent_ownership', @_ ) ); }

sub representative { return( shift->_set_get_boolean( 'representative', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::Relationship - A Stripe Account Relationship Object

=head1 SYNOPSIS

    my $rel = $stripe->person->relationship({
        director => $stripe->true,
        executive => $stripe->true,
        owner => $stripe->true,
        percent_ownership => 33,
        representative => $stripe->true,
        title => 'Representative Director',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Describes the person’s relationship to the account.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::Relationship> object.
It may also take an hash like arguments, that also are method of the same name.

This is instantiated from the method B<relationship> in module L<Net::API::Stripe::Connect::Person>

=back

=head1 METHODS

=over 4

=item B<director> boolean

Whether the person is a director of the account’s legal entity. Currently only required for accounts in the EU. Directors are typically members of the governing board of the company, or responsible for ensuring the company meets its regulatory obligations.

=item B<executive> boolean

Whether the person has significant responsibility to control, manage, or direct the organization.

=item B<owner> boolean

Whether the person is an owner of the account’s legal entity.

=item B<percent_ownership> decimal

The percent owned by the person of the account’s legal entity.

=item B<representative> boolean

Whether the person is authorized as the primary representative of the account. This is the person nominated by the business to provide information about themselves, and general information about the account. There can only be one representative at any given time. At the time the account is created, this person should be set to the person responsible for opening the account.

=item B<title> string

The person’s title (e.g., CEO, Support Engineer).

=back

=head1 API SAMPLE

	{
	  "id": "person_fake123456789",
	  "object": "person",
	  "account": "acct_fake123456789",
	  "created": 1571602397,
	  "dob": {
		"day": null,
		"month": null,
		"year": null
	  },
	  "first_name_kana": null,
	  "first_name_kanji": null,
	  "gender": null,
	  "last_name_kana": null,
	  "last_name_kanji": null,
	  "metadata": {},
	  "relationship": {
		"director": false,
		"executive": false,
		"owner": false,
		"percent_ownership": null,
		"representative": false,
		"title": null
	  },
	  "requirements": {
		"currently_due": [],
		"eventually_due": [],
		"past_due": [],
		"pending_verification": []
	  },
	  "verification": {
		"additional_document": {
		  "back": null,
		  "details": null,
		  "details_code": null,
		  "front": null
		},
		"details": null,
		"details_code": null,
		"document": {
		  "back": null,
		  "details": null,
		  "details_code": null,
		  "front": null
		},
		"status": "unverified"
	  }
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/persons/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
