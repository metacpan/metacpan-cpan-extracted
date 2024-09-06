# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/ForceReply.pm
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
package Net::API::Telegram::ForceReply;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub force_reply { return( shift->_set_get_scalar( 'force_reply', @_ ) ); }

sub selective { return( shift->_set_get_scalar( 'selective', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( force_reply selective ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::ForceReply - Upon receiving a message with this object, Telegram clients will display a reply interface to the user (act as if the user has selected the bot‘s message and tapped ’Reply')

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::ForceReply->new( %data ) || 
	die( Net::API::Telegram::ForceReply->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::ForceReply> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#forcereply>

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

=item B<force_reply>( True )

Shows reply interface to the user, as if they manually selected the bot‘s message and tapped ’Reply'

=item B<selective>( Boolean )

Optional. Use this parameter if you want to force reply from specific users only. Targets: 1) users that are @mentioned in the text of the Message object; 2) if the bot's message is a reply (has reply_to_message_id), sender of the original message.

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

