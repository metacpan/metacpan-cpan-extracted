# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/Game.pm
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
package Net::API::Telegram::Game;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub animation { return( shift->_set_get_object( 'animation', 'Net::API::Telegram::Animation', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub photo { return( shift->_set_get_object_array( 'photo', 'Net::API::Telegram::PhotoSize', @_ ) ); }

sub text { return( shift->_set_get_scalar( 'text', @_ ) ); }

sub text_entities { return( shift->_set_get_object_array( 'text_entities', 'Net::API::Telegram::MessageEntity', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::Game - A game

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::Game->new( %data ) || 
	die( Net::API::Telegram::Game->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::Game> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#game>

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

=item B<animation>( L<Net::API::Telegram::Animation> )

Optional. Animation that will be displayed in the game message in chats. Upload via BotFather

=item B<description>( String )

Description of the game

=item B<photo>( Array of PhotoSize )

Photo that will be displayed in the game message in chats.

=item B<text>( String )

Optional. Brief description of the game or high scores included in the game message. Can be automatically edited to include current high scores for the game when the bot calls setGameScore, or manually edited using editMessageText. 0-4096 characters.

=item B<text_entities>( Array of MessageEntity )

Optional. Special entities that appear in text, such as usernames, URLs, bot commands, etc.

=item B<title>( String )

Title of the game

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

