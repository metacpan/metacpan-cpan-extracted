# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/InlineQueryResultGame.pm
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
package Net::API::Telegram::InlineQueryResultGame;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub game_short_name { return( shift->_set_get_scalar( 'game_short_name', @_ ) ); }

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub reply_markup { return( shift->_set_get_object( 'reply_markup', 'Net::API::Telegram::InlineKeyboardMarkup', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::InlineQueryResultGame - A Game

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InlineQueryResultGame->new( %data ) || 
	die( Net::API::Telegram::InlineQueryResultGame->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InlineQueryResultGame> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inlinequeryresultgame>

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

=item B<game_short_name>( String )

Short name of the game

=item B<id>( String )

Unique identifier for this result, 1-64 bytes

=item B<reply_markup>( L<Net::API::Telegram::InlineKeyboardMarkup> )

Optional. Inline keyboard attached to the message

=item B<type>( String )

Type of the result, must be game

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

