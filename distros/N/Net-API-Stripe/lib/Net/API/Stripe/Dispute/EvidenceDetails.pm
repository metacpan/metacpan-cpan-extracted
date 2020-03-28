##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Dispute/EvidenceDetails.pm
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
package Net::API::Stripe::Dispute::EvidenceDetails;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub due_by { shift->_set_get_datetime( 'due_by', @_ ); }

sub has_evidence { shift->_set_get_boolean( 'has_evidence', @_ ); }

sub past_due { shift->_set_get_boolean( 'past_due', @_ ); }

sub submission_count { shift->_set_get_scalar( 'submission_count', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Dispute::EvidenceDetails - Dispute Evidence Details Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

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

=item B<due_by> timestamp

Date by which evidence must be submitted in order to successfully challenge dispute. Will be null if the customer’s bank or credit card company doesn’t allow a response for this particular dispute.

=item B<has_evidence> boolean

Whether evidence has been staged for this dispute.

=item B<past_due> boolean

Whether the last evidence submission was submitted past the due date. Defaults to false if no evidence submissions have occurred. If true, then delivery of the latest evidence is not guaranteed.

=item B<submission_count> integer

The number of times evidence has been submitted. Typically, you may only submit evidence once.

=back

=head1 API SAMPLE

	{
	  "object": "balance",
	  "available": [
		{
		  "amount": 0,
		  "currency": "jpy",
		  "source_types": {
			"card": 0
		  }
		}
	  ],
	  "connect_reserved": [
		{
		  "amount": 0,
		  "currency": "jpy"
		}
	  ],
	  "livemode": false,
	  "pending": [
		{
		  "amount": 7712,
		  "currency": "jpy",
		  "source_types": {
			"card": 7712
		  }
		}
	  ]
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/disputes/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

