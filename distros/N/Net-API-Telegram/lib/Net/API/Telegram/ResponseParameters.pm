# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/ResponseParameters.pm
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
package Net::API::Telegram::ResponseParameters;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub migrate_to_chat_id { return( shift->_set_get_number( 'migrate_to_chat_id', @_ ) ); }

sub retry_after { return( shift->_set_get_number( 'retry_after', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::ResponseParameters - Information about why a request was unsuccessful

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::ResponseParameters->new( %data ) || 
	die( Net::API::Telegram::ResponseParameters->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::ResponseParameters> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#responseparameters>

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

=item B<migrate_to_chat_id>( Integer )

Optional. The group has been migrated to a supergroup with the specified identifier. This number may be greater than 32 bits and some programming languages may have difficulty/silent defects in interpreting it. But it is smaller than 52 bits, so a signed 64 bit integer or double-precision float type are safe for storing this identifier.

=item B<retry_after>( Integer )

Optional. In case of exceeding flood control, the number of seconds left to wait before the request can be repeated

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

