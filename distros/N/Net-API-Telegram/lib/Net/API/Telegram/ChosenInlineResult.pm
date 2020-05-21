# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/ChosenInlineResult.pm
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
package Net::API::Telegram::ChosenInlineResult;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub from { return( shift->_set_get_object( 'from', 'Net::API::Telegram::User', @_ ) ); }

sub inline_message_id { return( shift->_set_get_scalar( 'inline_message_id', @_ ) ); }

sub location { return( shift->_set_get_object( 'location', 'Net::API::Telegram::Location', @_ ) ); }

sub query { return( shift->_set_get_scalar( 'query', @_ ) ); }

sub result_id { return( shift->_set_get_scalar( 'result_id', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::ChosenInlineResult - A result of an inline query that was chosen by the user and sent to their chat partner

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::ChosenInlineResult->new( %data ) || 
	die( Net::API::Telegram::ChosenInlineResult->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::ChosenInlineResult> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#choseninlineresult>

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

=item B<from>( L<Net::API::Telegram::User> )

The user that chose the result

=item B<inline_message_id>( String )

Optional. Identifier of the sent inline message. Available only if there is an inline keyboard attached to the message. Will be also received in callback queries and can be used to edit the message.

=item B<location>( L<Net::API::Telegram::Location> )

Optional. Sender location, only for bots that require user location

=item B<query>( String )

The query that was used to obtain the result

=item B<result_id>( String )

The unique identifier for the result that was chosen

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

