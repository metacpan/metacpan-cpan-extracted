# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/StickerSet.pm
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
package Net::API::Telegram::StickerSet;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub contains_masks { return( shift->_set_get_scalar( 'contains_masks', @_ ) ); }

sub is_animated { return( shift->_set_get_scalar( 'is_animated', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub stickers { return( shift->_set_get_object_array( 'stickers', 'Net::API::Telegram::Sticker', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( contains_masks is_animated ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::StickerSet - A sticker set

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::StickerSet->new( %data ) || 
	die( Net::API::Telegram::StickerSet->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::StickerSet> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#stickerset>

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

=item B<contains_masks>( Boolean )

True, if the sticker set contains masks

=item B<is_animated>( Boolean )

True, if the sticker set contains animated stickers

=item B<name>( String )

Sticker set name

=item B<stickers>( Array of Sticker )

List of all set stickers

=item B<title>( String )

Sticker set title

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

