# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/Invoice.pm
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
package Net::API::Telegram::Invoice;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub start_parameter { return( shift->_set_get_scalar( 'start_parameter', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

sub total_amount { return( shift->_set_get_number( 'total_amount', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::Invoice - Basic information about an invoice

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::Invoice->new( %data ) || 
	die( Net::API::Telegram::Invoice->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::Invoice> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#invoice>

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

=item B<description>( String )

Product description

=item B<start_parameter>( String )

Unique bot deep-linking parameter that can be used to generate this invoice

=item B<title>( String )

Product name

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

