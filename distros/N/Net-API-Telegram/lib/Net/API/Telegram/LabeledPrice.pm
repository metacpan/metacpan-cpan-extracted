# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/LabeledPrice.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2020/03/28
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::LabeledPrice;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub label { return( shift->_set_get_scalar( 'label', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::LabeledPrice - A portion of the price for goods or services

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::LabeledPrice->new( %data ) || 
	die( Net::API::Telegram::LabeledPrice->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::LabeledPrice> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#labeledprice>

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

=item B<amount>( Integer )

Price of the product in the smallest units of the currency (integer, not float/double). For example, for a price of US$ 1.45 pass amount = 145. See the exp parameter in currencies.json, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).

=item B<label>( String )

Portion label

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

