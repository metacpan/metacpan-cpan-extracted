##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Fraud/ValueList.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Fraud::ValueList;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub alias { return( shift->_set_get_scalar( 'alias', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub created_by { return( shift->_set_get_scalar( 'created_by', @_ ) ); }

sub item_type { return( shift->_set_get_scalar( 'item_type', @_ ) ); }

sub list_items { return( shift->_set_get_object( 'list_items', 'Net::API::Stripe::List', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Fraud::ValueList - A Stripe Value List Object

=head1 SYNOPSIS

    my $list = $stripe->value_list({
        alias => 'custom_ip_blocklist',
        created_by => 'john.doe@example.com',
        item_type => 'ip_address',
        list_items => $list_object,
        metadata => { transaction_id => 123 },
        name => 'Custom IP Blocklist',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    0.1

=head1 DESCRIPTION

Value lists allow you to group values together which can then be referenced in rules.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Fraud::ValueList> object.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "radar.value_list"

String representing the object’s type. Objects of the same type share the same value.

=item B<alias> string

The name of the value list for use in rules.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<created_by> string

The name or email address of the user who created this value list.

=item B<item_type> string

The type of items in the value list. One of card_fingerprint, card_bin, email, ip_address, country, string, or case_sensitive_string.

=item B<list_items> list

List of items contained within this value list.

This is a L<Net::API::Stripe::List> object with array of L<Net::API::Stripe::Fraud::List::Item> objects.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<name> string

The name of the value list.

=back

=head1 API SAMPLE

	{
	  "id": "rsl_fake123456789",
	  "object": "radar.value_list",
	  "alias": "custom_ip_blocklist",
	  "created": 1571480456,
	  "created_by": "jenny@example.com",
	  "item_type": "ip_address",
	  "list_items": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/radar/value_list_items?value_list=rsl_fake123456789"
	  },
	  "livemode": false,
	  "metadata": {},
	  "name": "Custom IP Blocklist"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/radar/value_lists>, L<https://stripe.com/docs/radar/lists#managing-list-items>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
