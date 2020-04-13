##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Event/Data.pm
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
## Object of the resources relevant to the event, e.g. balance, or invoice
## This must be processed by callbacks to set the right object
package Net::API::Stripe::Event::Data;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub object 
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $ref = shift( @_ );
		## This is not a type, there is an object property that contains a hash
		my $type = $ref->{object} || return( $self->error( "No object type could be found for field $self->{_field} in hash: ", sub{ $self->dumper( $ref ) } ) );
		my $class = $self->_object_type_to_class( $type ) ||
		return( $self->error( "No class found for object type $type" ) );
		return( $self->_set_get_object( 'object', $class, $ref ) );
	}
	return( $self->{object} );
}

sub previous_attributes { return( shift->_set_get_hash( 'previous_attributes', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Event::Data - A Stripe Event Data Object

=head1 SYNOPSIS

    my $event_data = $stripe->event->data({
        # The type of object is variable. In this example we use an invoice object
        object => $invoice_object,
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is a Stripe Event Data Object.

This is instantiated by the method B<data> in module L<Net::API::Stripe::Event>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Event::Data> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<object> hash

Object containing the API resource relevant to the event. For example, an invoice.created event will have a full invoice object as the value of the object key.

=item B<previous_attributes> hash

Object containing the names of the attributes that have changed, and their previous values (sent along only with *.updated events).

=back

=head1 API SAMPLE

	{
	  "id": "evt_fake123456789",
	  "object": "event",
	  "api_version": "2017-02-14",
	  "created": 1528914645,
	  "data": {
		"object": {
		  "object": "balance",
		  "available": [
			{
			  "currency": "jpy",
			  "amount": 1025751,
			  "source_types": {
				"card": 1025751
			  }
			}
		  ],
		  "connect_reserved": [
			{
			  "currency": "jpy",
			  "amount": 0
			}
		  ],
		  "livemode": false,
		  "pending": [
			{
			  "currency": "jpy",
			  "amount": 0,
			  "source_types": {
				"card": 0
			  }
			}
		  ]
		}
	  },
	  "livemode": false,
	  "pending_webhooks": 0,
	  "request": {
		"id": null,
		"idempotency_key": null
	  },
	  "type": "balance.available"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/events/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
