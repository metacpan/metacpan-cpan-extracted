# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/User.pm
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
package Net::API::Telegram::User;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub first_name { return( shift->_set_get_scalar( 'first_name', @_ ) ); }

sub id { return( shift->_set_get_number( 'id', @_ ) ); }

sub is_bot { return( shift->_set_get_scalar( 'is_bot', @_ ) ); }

sub language_code { return( shift->_set_get_scalar( 'language_code', @_ ) ); }

sub last_name { return( shift->_set_get_scalar( 'last_name', @_ ) ); }

sub username { return( shift->_set_get_scalar( 'username', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( is_bot ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::User - A Telegram user or bot

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::User->new( %data ) || 
	die( Net::API::Telegram::User->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::User> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#user>

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

=item B<first_name>( String )

User‘s or bot’s first name

=item B<id>( Integer )

Unique identifier for this user or bot

=item B<is_bot>( Boolean )

True, if this user is a bot

=item B<language_code>( String )

Optional. IETF language tag of the user's language

=item B<last_name>( String )

Optional. User‘s or bot’s last name

=item B<username>( String )

Optional. User‘s or bot’s username

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

