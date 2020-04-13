##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Fraud/Review/Session.pm
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
package Net::API::Stripe::Fraud::Review::Session;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub browser { return( shift->_set_get_scalar( 'browser', @_ ) ); }

sub device { return( shift->_set_get_scalar( 'device', @_ ) ); }

sub platform { return( shift->_set_get_scalar( 'platform', @_ ) ); }

sub version { return( shift->_set_get_scalar( 'version', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Fraud::Review::Session - A Stripe Fraud Review Session Object

This is used in L<Net::API::Stripe::Fraud::Review>

=head1 SYNOPSIS

    my $session = $stripe->review->session({
        browser => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36',
        device => 'Desktop',
        platform => 'Linux',
        version => '55.0.2883.87',
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

Information related to the browsing session of the user who initiated the payment.

This is instantiated by method B<session> in module L<Net::API::Stripe::Fraud::Review>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Fraud::Review::Session> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<browser> string

The browser used in this browser session (e.g., Chrome).

=item B<device> string

Information about the device used for the browser session (e.g., Samsung SM-G930T).

=item B<platform> string

The platform for the browser session (e.g., Macintosh).

=item B<version> string

The version for the browser session (e.g., 61.0.3163.100).

=back

=head1 API SAMPLE

	{
	  "id": "prv_fake123456789",
	  "object": "review",
	  "billing_zip": null,
	  "charge": "ch_fake123456789",
	  "closed_reason": null,
	  "created": 1571480456,
	  "ip_address": null,
	  "ip_address_location": null,
	  "livemode": false,
	  "open": true,
	  "opened_reason": "rule",
	  "reason": "rule",
	  "session": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
