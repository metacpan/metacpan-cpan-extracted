##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Fraud/ValueList/Item.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Fraud::ValueList::Item;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub created_by { return( shift->_set_get_scalar( 'created_by', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub value { return( shift->_set_get_scalar( 'value', @_ ) ); }

sub value_list { return( shift->_set_get_scalar( 'value_list', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Fraud::ValueList::Item - A Stripe Value List Item Object

=head1 SYNOPSIS

    my $item = $stripe->value_list_item({
        created_by => 'john.doe@example.com',
        value => '1.2.3.4',
        value_list => 'rsl_1FVF3MCeyNCl6fY2Wg2IWniP',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Value list items allow you to add specific values to a given Radar value list, which can then be used in rules.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Fraud::ValueList::Item> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "radar.value_list_item"

String representing the object’s type. Objects of the same type share the same value.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

This is a C<DateTime> object.

=item B<created_by> string

The name or email address of the user who added this item to the value list.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<value> string

The value of the item.

=item B<value_list> string

The identifier of the value list this item belongs to.

=back

=head1 API SAMPLE

	{
	  "id": "rsli_fake123456789",
	  "object": "radar.value_list_item",
	  "created": 1571480456,
	  "created_by": "jenny@example.com",
	  "livemode": false,
	  "value": "1.2.3.4",
	  "value_list": "rsl_1FVF3MCeyNCl6fY2Wg2IWniP"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/radar/value_list_items>, L<https://stripe.com/docs/radar/lists#managing-list-items>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
