##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Person.pm
## Version v0.201.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Person;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    use DateTime;
    use DateTime::Format::Strptime;
    use Nice::Try;
    our( $VERSION ) = 'v0.201.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub account { return( shift->_set_get_scalar_or_object( 'account', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub additional { return( shift->_set_get_array( 'additional', @_ ) ); }

sub address { return( shift->_set_get_object( 'address', 'Net::API::Stripe::Address', @_ ) ); }

sub address_kana { return( shift->_set_get_object( 'address_kana', 'Net::API::Stripe::Address', @_ ) ); }

sub address_kanji { return( shift->_set_get_object( 'address_kanji', 'Net::API::Stripe::Address', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub dob
{
    my $self = shift( @_ );
    if( @_ )
    {
        ## There may be a hash provided with undefined values for each of the properties, so we need to check that
        my $ref = shift( @_ );
        my $dt;
        if( $self->_is_object( $ref ) && $ref->isa( 'DateTime' ) )
        {
            $dt = $ref;
        }
        elsif( $self->_is_hash( $ref ) )
        {
            return if( !length( $ref->{year} ) && !length( $ref->{month} ) && !length( $ref->{day} ) );
        
            foreach my $k ( qw( year month day ) )
            {
                return( $self->error( "Hash provided for person date of birth is missing the $k property" ) ) if( !$ref->{ $k } );
            }
            @$ref{ qw( hour minute second ) } = ( 0, 0, 0 );
            try
            {
                $dt = DateTime->new( %$ref );
            }
            catch( $e )
            {
                return( $self->error( "An error occurred while trying to create a datetime object from this person's date of birth (year = '$ref->{year}', month = '$ref->{month}', day = '$ref->{day}'." ) );
            }
        }
        
        my $tz;
        try
        {
            $tz = DateTime::TimeZone->new( name => 'local' );
        }
        catch( $e )
        {
            $tz = DateTime::TimeZone->new( name => 'UTC' );
        }
        
        my $fmt = DateTime::Format::Strptime->new(
            pattern => '%Y-%m-%d',
            locale => 'en_GB',
            time_zone => $tz->name,
        );
        $dt->set_formatter( $fmt );
        $self->{dob} = $dt;
    }
    return( $self->{dob} );
}

sub email { return( shift->_set_get_scalar( 'email', @_ ) ); }

sub first_name { return( shift->_set_get_scalar( 'first_name', @_ ) ); }

sub first_name_kana { return( shift->_set_get_scalar( 'first_name_kana', @_ ) ); }

sub first_name_kanji { return( shift->_set_get_scalar( 'first_name_kanji', @_ ) ); }

sub full_name_aliases { return( shift->_set_get_array( 'full_name_aliases', @_ ) ); }

sub future_requirements { return( shift->_set_get_object( 'future_requirements', 'Net::API::Stripe::Connect::Account::Requirements', @_ ) ); }

sub gender { return( shift->_set_get_scalar( 'gender', @_ ) ); }

sub id_number_provided { return( shift->_set_get_boolean( 'id_number_provided', @_ ) ); }

sub id_number_secondary_provided { return( shift->_set_get_boolean( 'id_number_secondary_provided', @_ ) ); }

sub last_name { return( shift->_set_get_scalar( 'last_name', @_ ) ); }

sub last_name_kana { return( shift->_set_get_scalar( 'last_name_kana', @_ ) ); }

sub last_name_kanji { return( shift->_set_get_scalar( 'last_name_kanji', @_ ) ); }

sub maiden_name { return( shift->_set_get_scalar( 'maiden_name', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub minimum { return( shift->_set_get_array( 'minimum', @_ ) ); }

sub nationality { return( shift->_set_get_scalar( 'nationality', @_ ) ); }

sub phone { return( shift->_set_get_scalar( 'phone', @_ ) ); }

sub political_exposure { return( shift->_set_get_scalar( 'political_exposure', @_ ) ); }

sub registered_address { return( shift->_set_get_object( 'registered_address', 'Net::API::Stripe::Address', @_ ) ); }

sub relationship { return( shift->_set_get_object( 'relationship', 'Net::API::Stripe::Connect::Account::Relationship', @_ ) ); }

sub requirements { return( shift->_set_get_object( 'requirements', 'Net::API::Stripe::Connect::Account::Requirements', @_ ) ); }

sub ssn_last_4_provided { return( shift->_set_get_boolean( 'ssn_last_4_provided', @_ ) ); }

sub verification { return( shift->_set_get_object( 'verification', 'Net::API::Stripe::Connect::Account::Verification', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Person - A Stripe Person Object

=head1 SYNOPSIS

    my $pers = $stripe->person({
        account => $account_object,
        address => $address_object,
        address_kana => $address_kana_object,
        address_kanji => $address_kanji_object,
        # or:
        # dob => DateTime->new( year => 1985, month => 8, day => 15 )
        dob => 
        {
            day => 15
            month => 8,
            year => 1985,
        },
        email => 'nadeshiko.yamato@example.com',
        first_name => 'Nadeshiko',
        last_name => 'Yamato',
        first_name_kana => 'なでしこ',
        last_name_kana => 'やまと',
        first_name_kanji => '撫子',
        last_name_kanji => '大和',
        gender => 'female',
        metadata => { transaction_id => 123, customer_id => 456 },
        phone => '+81-(0)90-1234-5678',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.201.0

=head1 DESCRIPTION

This is an object representing a person associated with a Stripe account.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::Person> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "person"

String representing the object’s type. Objects of the same type share the same value.

=head2 account string

The account the person is associated with. If expanded (currently not implemented in Stripe API), this will be a L<Net::API::Stripe::Connect::Account> object.

=head2 additional string_array

Additional fields which are only required for some users.

=head2 address hash

The person’s address.

This is L<Net::API::Stripe::Address> object.

=head2 address_kana hash

The Kana variation of the person’s address (Japan only).

This is L<Net::API::Stripe::Address> object.

=head2 address_kanji hash

The Kanji variation of the person’s address (Japan only).

This is L<Net::API::Stripe::Address> object.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 dob L<DateTime> object or hash

The person’s date of birth.

This returns a C<DateTime> object. It can take either a L<DateTime> object or an hash with the following properties:

=over 4

=item I<day> positive integer

The day of birth, between 1 and 31.

=item I<month> positive integer

The month of birth, between 1 and 12.

=item I<year> positive integer

The four-digit year of birth.

=back

=head2 email string

The person’s email address.

=head2 first_name string

The person’s first name.

=head2 first_name_kana string

The Kana variation of the person’s first name (Japan only).

=head2 first_name_kanji string

The Kanji variation of the person’s first name (Japan only).

=head2 full_name_aliases string_array

A list of alternate names or aliases that the individual is known by.

=head2 future_requirements object

Information about future requirements for the individual, including what information needs to be collected, and by when.

This is a L<Net::API::Stripe::Connect::Account::Requirements> object.

=head2 gender string

The person’s gender (International regulations require either “male” or “female”).

=head2 id_number_provided boolean

Whether the person’s id_number was provided.

=head2 id_number_secondary_provided boolean

Whether the individual's personal secondary ID number was provided.

=head2 last_name string

The person’s last name.

=head2 last_name_kana string

The Kana variation of the person’s last name (Japan only).

=head2 last_name_kanji string

The Kanji variation of the person’s last name (Japan only).

=head2 maiden_name string

The person’s maiden name.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 minimum string_array

Fields which every account must eventually provide.

=head2 nationality string

The country where the person is a national.

=head2 phone string

The person’s phone number.

=head2 political_exposure string

Indicates if the person or any of their representatives, family members, or other closely related persons, declares that they hold or have held an important public job or function, in any jurisdiction.

=head2 registered_address object

The individual's registered address.

This is a L<Net::API::Stripe::Address> object.

=head2 relationship hash

Describes the person’s relationship to the account.

This is a L<Net::API::Stripe::Connect::Account::Relationship> object.

=head2 requirements hash

Information about the requirements for this person, including what information needs to be collected, and by when.

This is a L<Net::API::Stripe::Connect::Account::Requirements> object.

=head2 ssn_last_4_provided boolean

Whether the last 4 digits of this person’s SSN have been provided.

=head2 verification hash

The persons’s verification status.

This is a L<Net::API::Stripe::Connect::Account::Verification> object.

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

=head2 v0.2

Update the method B<dob> to accept L<DateTime> objects

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/persons/object>, L<https://stripe.com/docs/connect/identity-verification-api#person-information>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
