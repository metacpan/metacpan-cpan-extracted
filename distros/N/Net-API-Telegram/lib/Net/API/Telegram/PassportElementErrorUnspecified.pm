# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/PassportElementErrorUnspecified.pm
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
package Net::API::Telegram::PassportElementErrorUnspecified;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub element_hash { return( shift->_set_get_scalar( 'element_hash', @_ ) ); }

sub message { return( shift->_set_get_scalar( 'message', @_ ) ); }

sub source { return( shift->_set_get_scalar( 'source', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::PassportElementErrorUnspecified - An issue in an unspecified place

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::PassportElementErrorUnspecified->new( %data ) || 
	die( Net::API::Telegram::PassportElementErrorUnspecified->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::PassportElementErrorUnspecified> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#passportelementerrorunspecified>

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

=item B<element_hash>( String )

Base64-encoded element hash

=item B<message>( String )

Error message

=item B<source>( String )

Error source, must be unspecified

=item B<type>( String )

Type of element of the user's Telegram Passport which has the issue

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

