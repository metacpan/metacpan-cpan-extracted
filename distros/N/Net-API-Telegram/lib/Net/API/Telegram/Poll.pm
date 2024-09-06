# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/Poll.pm
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
package Net::API::Telegram::Poll;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub is_closed { return( shift->_set_get_scalar( 'is_closed', @_ ) ); }

sub options { return( shift->_set_get_object_array( 'options', 'Net::API::Telegram::PollOption', @_ ) ); }

sub question { return( shift->_set_get_scalar( 'question', @_ ) ); }

sub _is_boolean { return( grep( /^$_[1]$/, qw( is_closed ) ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::Poll - Information about a poll

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::Poll->new( %data ) || 
	die( Net::API::Telegram::Poll->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::Poll> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#poll>

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

=item B<id>( String )

Unique poll identifier

=item B<is_closed>( Boolean )

True, if the poll is closed

=item B<options>( Array of PollOption )

List of poll options

=item B<question>( String )

Poll question, 1-255 characters

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

