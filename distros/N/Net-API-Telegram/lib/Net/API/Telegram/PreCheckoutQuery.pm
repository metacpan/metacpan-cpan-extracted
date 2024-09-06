# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/PreCheckoutQuery.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2020/06/13
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::PreCheckoutQuery;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub from { return( shift->_set_get_object( 'from', 'Net::API::Telegram::User', @_ ) ); }

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub invoice_payload { return( shift->_set_get_scalar( 'invoice_payload', @_ ) ); }

sub order_info { return( shift->_set_get_object( 'order_info', 'Net::API::Telegram::OrderInfo', @_ ) ); }

sub shipping_option_id { return( shift->_set_get_scalar( 'shipping_option_id', @_ ) ); }

sub total_amount { return( shift->_set_get_number( 'total_amount', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::PreCheckoutQuery - Information about an incoming pre-checkout query

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::PreCheckoutQuery->new( %data ) || 
	die( Net::API::Telegram::PreCheckoutQuery->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::PreCheckoutQuery> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#precheckoutquery>

This module has been automatically generated from Telegram API documentation by the script scripts/telegram-doc2perl-methods.pl.

=head1 METHODS

=over 4

=item B<new>( {INIT HASH REF}, %PARAMETERS )

B<new>() will create a new object for the package, pass any argument it might receive
to the special standard routine B<init> that I<must> exist. 
Then it returns what returns B<init>().

The valid parameters are as follow. Methods available here are also parameters to the B<new> method.

=over 8

=item * I<verbose>

=item * I<debug>

=back

=item B<currency>( String )

Three-letter ISO 4217 currency code

=item B<from>( L<Net::API::Telegram::User> )

User who sent the query

=item B<id>( String )

Unique query identifier

=item B<invoice_payload>( String )

Bot specified invoice payload

=item B<order_info>( L<Net::API::Telegram::OrderInfo> )

Optional. Order info provided by the user

=item B<shipping_option_id>( String )

Optional. Identifier of the shipping option chosen by the user

=item B<total_amount>( Integer )

Total price in the smallest units of the currency (integer, not float/double). For example, for a price of US$ 1.45 pass amount = 145. See the exp parameter in currencies.json, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).

=back

=head1 COPYRIGHT

Copyright (c) 2000-2019 DEGUEST Pte. Ltd.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::Telegram>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

