# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/MessageEntity.pm
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
package Net::API::Telegram::MessageEntity;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub length { return( shift->_set_get_number( 'length', @_ ) ); }

sub offset { return( shift->_set_get_number( 'offset', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub url { return( shift->_set_get_scalar( 'url', @_ ) ); }

sub user { return( shift->_set_get_object( 'user', 'Net::API::Telegram::User', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::MessageEntity - One special entity in a text message

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::MessageEntity->new( %data ) || 
	die( Net::API::Telegram::MessageEntity->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::MessageEntity> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#messageentity>

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

=item B<length>( Integer )

Length of the entity in UTF-16 code units

=item B<offset>( Integer )

Offset in UTF-16 code units to the start of the entity

=item B<type>( String )

Type of the entity. Can be mention (@username), hashtag, cashtag, bot_command, url, email, phone_number, bold (bold text), italic (italic text), code (monowidth string), pre (monowidth block), text_link (for clickable text URLs), text_mention (for users without usernames)

=item B<url>( String )

Optional. For I<text_link> only, url that will be opened after user taps on the text

=item B<user>( L<Net::API::Telegram::User> )

Optional. For I<text_mention> only, the mentioned user

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

