# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/ShippingAddress.pm
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
package Net::API::Telegram::ShippingAddress;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub city { return( shift->_set_get_scalar( 'city', @_ ) ); }

sub country_code { return( shift->_set_get_scalar( 'country_code', @_ ) ); }

sub post_code { return( shift->_set_get_scalar( 'post_code', @_ ) ); }

sub state { return( shift->_set_get_scalar( 'state', @_ ) ); }

sub street_line1 { return( shift->_set_get_scalar( 'street_line1', @_ ) ); }

sub street_line2 { return( shift->_set_get_scalar( 'street_line2', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::ShippingAddress - A shipping address

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::ShippingAddress->new( %data ) || 
	die( Net::API::Telegram::ShippingAddress->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::ShippingAddress> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#shippingaddress>

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

=item B<city>( String )

City

=item B<country_code>( String )

ISO 3166-1 alpha-2 country code

=item B<post_code>( String )

Address post code

=item B<state>( String )

State, if applicable

=item B<street_line1>( String )

First line for the address

=item B<street_line2>( String )

Second line for the address

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

