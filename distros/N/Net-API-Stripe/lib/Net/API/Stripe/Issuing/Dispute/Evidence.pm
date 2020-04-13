##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Dispute/Evidence.pm
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
package Net::API::Stripe::Issuing::Dispute::Evidence;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub fraudulent { return( shift->_set_get_object( 'fraudulent', 'Net::API::Stripe::Issuing::Dispute::Evidence::Fraudulent', @_ ) ); }

sub other { return( shift->_set_get_object( 'other', 'Net::API::Stripe::Issuing::Dispute::Evidence::Other', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Dispute::Evidence - A Stripe Issued Card Dispute Evidence Object

=head1 SYNOPSIS

    my $ev = $stripe->issuing_dispute->evidence({
        fraudulent => 
        {
			dispute_explanation => 'Service not provided',
			uncategorized_file => $file_object,
        },
        other =>
        {
			dispute_explanation => 'Service was not provided',
			uncategorized_file => $file_object,
        },
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

Evidence related to the dispute. This hash will contain exactly one non-null value, containing an evidence object that matches its reason

This is instantiated by method B<evidence> in module L<Net::API::Stripe::Issuing::Dispute>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Issuing::Dispute::Evidence> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<fraudulent> hash

Evidence to support a fraudulent dispute. This will only be present if your dispute’s reason is fraudulent.

This is a L<Net::API::Stripe::Issuing::Dispute::Evidence::Fraudulent> object.

=item B<other> hash

Evidence to support an uncategorized dispute. This will only be present if your dispute’s reason is other.

This is a L<Net::API::Stripe::Issuing::Dispute::Evidence::Other> object.

=back

=head1 API SAMPLE

	{
	  "id": "idp_fake123456789",
	  "object": "issuing.dispute",
	  "amount": 100,
	  "created": 1571480456,
	  "currency": "usd",
	  "disputed_transaction": "ipi_fake123456789",
	  "evidence": {
		"fraudulent": {
		  "dispute_explanation": "Fraud; card reported lost on 10/19/2019",
		  "uncategorized_file": null
		},
		"other": null
	  },
	  "livemode": false,
	  "metadata": {},
	  "reason": "fraudulent",
	  "status": "under_review"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/disputes>, L<https://stripe.com/docs/issuing/disputes>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
