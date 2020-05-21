# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/ShippingQuery.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2020/05/20
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::ShippingQuery;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub from { return( shift->_set_get_object( 'from', 'Net::API::Telegram::User', @_ ) ); }

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub invoice_payload { return( shift->_set_get_scalar( 'invoice_payload', @_ ) ); }

sub shipping_address { return( shift->_set_get_object( 'shipping_address', 'Net::API::Telegram::ShippingAddress', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::ShippingQuery - Information about an incoming shipping query

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::ShippingQuery->new( %data ) || 
	die( Net::API::Telegram::ShippingQuery->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::ShippingQuery> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#shippingquery>

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

=item B<from>( L<Net::API::Telegram::User> )

User who sent the query

=item B<id>( String )

Unique query identifier

=item B<invoice_payload>( String )

Bot specified invoice payload

=item B<shipping_address>( L<Net::API::Telegram::ShippingAddress> )

User specified shipping address

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

